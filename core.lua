-- core.lua
-- Pure, Roblox-independent logic for the Universal Piano script.
--
-- This module deliberately uses ONLY standard Lua 5.3+ APIs (string, table,
-- math, bit32) so it can be unit-tested outside of Roblox (see tests/).
-- piano.lua loads it from the repository and unpacks the returned table.
--
-- Included here: MIDI byte-stream parser, MD5, custom-base64 / hex decoders,
-- HTML / URL / query helpers, song-list parsing, cookie merging and the
-- shared formatting helpers.

local Core = {}

-- ==========================================
-- MIDI Stream & Parser
-- ==========================================
local function createStringStream(str)
    return {
        data = str,
        pos = 1,
        read = function(self, bytes)
            if bytes == 0 then return "" end
            if self.pos > #self.data then return nil end
            local res = self.data:sub(self.pos, self.pos + bytes - 1)
            self.pos = self.pos + bytes
            return res
        end,
        seek = function(self, whence, offset)
            if whence == "cur" then
                self.pos = self.pos + offset
            elseif whence == "set" then
                self.pos = offset + 1
            elseif whence == "end" then
                self.pos = #self.data + offset + 1
            end
            return self.pos - 1
        end
    }
end
Core.createStringStream = createStringStream

local function read(stream, count)
    local result = ""
    while #result < count do
        local r = stream:read(count - #result)
        if not r or r == "" then error("missing value") end
        result = result .. r
    end
    return result
end
Core.read = read

local function readVLQ(stream)
    local value = 0
    local length = 0
    repeat
        local b = stream:read(1)
        if not b then error("incomplete variable length quantity") end
        local byte = b:byte()
        value = bit32.lshift(value, 7)
        value = bit32.bor(value, bit32.band(byte, 0x7F))
        length = length + 1
        -- MIDI spec: a variable-length quantity may use at most 4 bytes.
        -- Reject a 4th byte that still has the continuation bit set.
        if length >= 4 and byte >= 0x80 then error("VLQ too long") end
    until byte < 0x80
    return value, length
end
Core.readVLQ = readVLQ

local midiEvent = {
    [0x80] = function(stream, callback, channel, fb)
        local key = fb:byte()
        local velocity = read(stream, 1):byte()
        callback("noteOff", channel, key, velocity / 0x7F)
        return 2
    end,
    [0x90] = function(stream, callback, channel, fb)
        local key = fb:byte()
        local velocity = read(stream, 1):byte()
        callback("noteOn", channel, key, velocity / 0x7F)
        return 2
    end,
    [0xA0] = function(stream, callback, channel, fb)
        local key = fb:byte()
        local pressure = read(stream, 1):byte()
        callback("keyPressure", channel, key, pressure / 0x7F)
        return 2
    end,
    [0xB0] = function(stream, callback, channel, fb)
        local number = fb:byte()
        local value = read(stream, 1):byte()
        if number < 120 then
            callback("controller", channel, number, value)
        else
            callback("modeMessage", channel, number, value)
        end
        return 2
    end,
    [0xC0] = function(_, callback, channel, fb)
        local program = fb:byte()
        callback("program", channel, program)
        return 1
    end,
    [0xD0] = function(_, callback, channel, fb)
        local pressure = fb:byte()
        callback("channelPressure", channel, pressure / 0x7F)
        return 1
    end,
    [0xE0] = function(stream, callback, channel, fb)
        local lsb = fb:byte()
        local msb = read(stream, 1):byte()
        callback("pitch", channel, (bit32.bor(lsb, bit32.lshift(msb, 7))) / 0x2000 - 1)
        return 2
    end
}
Core.midiEvent = midiEvent

local function makeForwarder(name)
    return function(data, callback)
        callback(name, data)
    end
end

local metaEvents = {
    [0x00] = makeForwarder("sequenceNumber"),
    [0x01] = makeForwarder("text"),
    [0x02] = makeForwarder("copyright"),
    [0x03] = makeForwarder("sequencerOrTrackName"),
    [0x04] = makeForwarder("instrumentName"),
    [0x05] = makeForwarder("lyric"),
    [0x06] = makeForwarder("marker"),
    [0x07] = makeForwarder("cuePoint"),
    [0x20] = makeForwarder("channelPrefix"),
    [0x2F] = makeForwarder("endOfTrack"),
    [0x51] = function(data, callback)
        if #data < 3 then return end
        local b1, b2, b3 = string.byte(data, 1, 3)
        local rawTempo = bit32.bor(bit32.lshift(b1, 16), bit32.lshift(b2, 8), b3)
        callback("setTempo", rawTempo)
    end,
    [0x54] = makeForwarder("smpteOffset"),
    [0x58] = function(data, callback)
        if #data < 4 then return end
        local numerator, denominator, metronome, dotted = string.byte(data, 1, 4)
        callback("timeSignature", numerator, bit32.lshift(1, denominator), metronome, dotted)
    end,
    [0x59] = function(data, callback)
        if #data < 2 then return end
        local count, minor = string.byte(data, 1, 2)
        if count >= 128 then count = count - 256 end
        callback("keySignature", math.abs(count), count < 0 and "flat" or count > 0 and "sharp" or "C", minor == 0 and "major" or "minor")
    end,
    [0x7F] = makeForwarder("sequenceEvent")
}
Core.metaEvents = metaEvents

local function metaEvent(stream, callback, fb)
    local event = fb:byte()
    local length, vlqLength = readVLQ(stream)
    local data = read(stream, length)
    local handler = metaEvents[event]
    if handler then
        handler(data, callback)
    end
    return 1 + vlqLength + length
end

local function readChunkInfo(stream)
    local chunkInfo = stream:read(8)
    if not chunkInfo or #chunkInfo < 8 then return false end
    local magic = chunkInfo:sub(1, 4)
    local len = string.unpack(">I4", chunkInfo:sub(5, 8))
    return magic, len
end
Core.readChunkInfo = readChunkInfo

local function readHeader(stream, callback, chunkLength)
    local header = read(stream, chunkLength)
    local format, tracks, division = string.unpack(">I2I2I2", header)
    callback("header", format, tracks, division)
    return format, tracks
end
Core.readHeader = readHeader

local function processEvent(stream, callback, runningStatus)
    local firstByte = stream:read(1)
    if not firstByte then error("missing event") end
    local status = firstByte:byte()
    local length = 0

    if status < 0x80 then
        status = runningStatus
        if not status then error("no running status") end
    elseif status < 0xF0 then
        firstByte = read(stream, 1)
        length = 1
        runningStatus = status
    else
        runningStatus = nil
        if status == 0xF0 then
            -- SysEx: <VLQ length><payload bytes>
            local dataLen, vlqLen = readVLQ(stream)
            local data = read(stream, dataLen)
            callback("sysexEvent", data, status)
            return 1 + vlqLen + dataLen, runningStatus
        elseif status == 0xF1 then
            -- MIDI Time Code quarter frame: exactly ONE data byte.
            -- (Consuming it is required; skipping it desyncs the stream.)
            read(stream, 1)
            return 2, runningStatus
        elseif status == 0xF2 then
            -- MIDI Time Code full frame: two data bytes.
            read(stream, 2)
            return 3, runningStatus
        elseif status == 0xF3 then
            -- Song position pointer: one data byte.
            read(stream, 1)
            return 2, runningStatus
        elseif status == 0xF7 then
            -- In a Standard MIDI File, F7 introduces an escaped event whose
            -- payload is preceded by a variable-length byte count.
            local dataLen, vlqLen = readVLQ(stream)
            local data = read(stream, dataLen)
            callback("eox", data, status)
            return 1 + vlqLen + dataLen, runningStatus
        elseif status == 0xFF then
            local metaType = read(stream, 1)
            return 1 + metaEvent(stream, callback, metaType), runningStatus
        else
            -- 0xF4, 0xF5, 0xF6, 0xF8..0xFE: system real-time / undefined,
            -- none of which carry data bytes.
            callback("ignore", status)
            return 1, runningStatus
        end
    end

    local handler = midiEvent[bit32.band(status, 0xF0)]
    if handler then
        length = length + handler(stream, callback, bit32.band(status, 0x0F) + 1, firstByte)
    end
    return length, runningStatus
end
Core.processEvent = processEvent

local function readTrack(stream, callback, chunkLength, track)
    callback("track", track)
    local chunkEnd = stream:seek("cur", 0) + chunkLength
    local runningStatus
    local ended = false

    local function trackCallback(name, ...)
        if name == "endOfTrack" then
            ended = true
        end
        callback(name, ...)
    end

    while not ended and stream:seek("cur", 0) < chunkEnd do
        local ticks = readVLQ(stream)
        if ticks > 0 then trackCallback("deltatime", ticks) end
        local _, nextRunningStatus = processEvent(stream, trackCallback, runningStatus)
        runningStatus = nextRunningStatus
    end
    stream:seek("set", chunkEnd)
end

local function processMidi(stream, callback)
    local tracks
    local track = 0
    while true do
        local chunkType, chunkLength = readChunkInfo(stream)
        if not chunkType then break end
        if chunkType == "MThd" then
            _, tracks = readHeader(stream, callback, chunkLength)
        elseif chunkType == "MTrk" then
            track = track + 1
            readTrack(stream, callback, chunkLength, track)
        else
            -- Unknown chunk: skip its payload and continue.
            stream:seek("cur", chunkLength)
        end
    end
    return tracks
end
Core.processMidi = processMidi

-- ==========================================
-- URL helpers
-- ==========================================
local function normalizeMidiUrl(url)
    local clean = tostring(url or ""):match("^%s*(.-)%s*$")
    clean = clean:gsub("^https?://github%.com/([^/]+)/([^/]+)/blob/(.+)$", "https://raw.githubusercontent.com/%1/%2/%3")
    clean = clean:gsub("^https?://github%.com/([^/]+)/([^/]+)/raw/(.+)$", "https://raw.githubusercontent.com/%1/%2/%3")
    clean = clean:gsub(" ", "%%20")
    return clean
end
Core.normalizeMidiUrl = normalizeMidiUrl

local function buildRepoUrlCandidates(rawUrl)
    local clean = normalizeMidiUrl(rawUrl)
    local candidates = {}
    local seen = {}
    local function add(u)
        if u and u ~= "" and not seen[u] then
            seen[u] = true
            table.insert(candidates, u)
        end
    end

    add(clean)
    if clean:find("raw%.githubusercontent%.com/[^/]+/[^/]+/refs/heads/") then
        add((clean:gsub("(raw%.githubusercontent%.com/[^/]+/[^/]+)/refs/heads/", "%1/")))
    elseif clean:find("raw%.githubusercontent%.com/[^/]+/[^/]+/main/") then
        add((clean:gsub("(raw%.githubusercontent%.com/[^/]+/[^/]+)/main/", "%1/refs/heads/main/")))
    elseif clean:find("raw%.githubusercontent%.com/[^/]+/[^/]+/master/") then
        add((clean:gsub("(raw%.githubusercontent%.com/[^/]+/[^/]+)/master/", "%1/refs/heads/master/")))
    end
    return candidates
end
Core.buildRepoUrlCandidates = buildRepoUrlCandidates

local function encodeUrlPath(str)
    return (str:gsub("([^%w%-%._~/])", function(c)
        return string.format("%%%02X", c:byte())
    end))
end
Core.encodeUrlPath = encodeUrlPath

local function encodeQueryParam(str)
    return (tostring(str or ""):gsub("([^%w%-%._~])", function(c)
        return string.format("%%%02X", c:byte())
    end))
end
Core.encodeQueryParam = encodeQueryParam

local function deriveTitleFromUrl(url)
    local cleanUrl = tostring(url or ""):match("^([^?#]*)") or ""
    local lastSeg = cleanUrl:match("([^/]+)%s*$") or "Direct URL"
    lastSeg = lastSeg:gsub("%.midi?$", ""):gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    if lastSeg == "" then return "Direct URL" end
    return lastSeg
end
Core.deriveTitleFromUrl = deriveTitleFromUrl

-- ==========================================
-- Search / filter helpers
-- ==========================================
local function matchesQuery(label, query)
    local clean = tostring(query or ""):lower():match("^%s*(.-)%s*$")
    if clean == "" then
        return true
    end
    local lowerLabel = tostring(label or ""):lower()
    for token in clean:gmatch("%S+") do
        if not lowerLabel:find(token, 1, true) then
            return false
        end
    end
    return true
end
Core.matchesQuery = matchesQuery

local function filterSongList(sourceList, query, limit)
    local matches = {}
    local totalMatches = 0
    for _, item in ipairs(sourceList) do
        if matchesQuery(item, query) then
            totalMatches = totalMatches + 1
            if not limit or #matches < limit then
                table.insert(matches, item)
            end
        end
    end
    return matches, totalMatches
end
Core.filterSongList = filterSongList

-- ==========================================
-- HTML helpers
-- ==========================================
local function decodeHtmlEntities(str)
    local s = tostring(str or "")
    s = s:gsub("&amp;", "&")
    s = s:gsub("&quot;", '"')
    s = s:gsub("&#0?39;", "'")
    s = s:gsub("&#x27;", "'")
    s = s:gsub("&apos;", "'")
    s = s:gsub("&lt;", "<")
    s = s:gsub("&gt;", ">")
    s = s:gsub("&nbsp;", " ")
    return s
end
Core.decodeHtmlEntities = decodeHtmlEntities

local function stripHtmlTags(str)
    return decodeHtmlEntities(tostring(str or ""):gsub("<[^>]->", " ")):gsub("%s+", " "):match("^%s*(.-)%s*$")
end
Core.stripHtmlTags = stripHtmlTags

-- ==========================================
-- MD5 (pure Lua implementation)
-- ==========================================
local MD5_K = {
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
    0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
    0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
    0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
    0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
}

local MD5_S = {
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
}

local function md5Hex(msg)
    msg = tostring(msg or "")
    local origBitLen = #msg * 8
    msg = msg .. "\128"
    local padLen = (56 - (#msg % 64)) % 64
    if padLen > 0 then
        msg = msg .. string.rep("\0", padLen)
    end
    -- Coerce to integer: plain Lua 5.3 parses 32-bit hex literals as floats
    -- while Luau/Roblox parses them as integers; math.floor is a no-op there.
    local i32 = function(v) return math.floor(v % 4294967296) end
    local loLen = i32(origBitLen)
    local hiLen = i32(math.floor(origBitLen / 4294967296))
    -- Assemble the 64-bit little-endian length manually: some Lua
    -- implementations (e.g. fengari) reject uint32 values in string.pack.
    local lenBytes = {}
    for _, v in ipairs({ loLen, hiLen }) do
        for b = 0, 3 do
            table.insert(lenBytes, string.char(v % 256))
            v = math.floor(v / 256)
        end
    end
    msg = msg .. table.concat(lenBytes)

    local a0, b0, c0, d0 = i32(0x67452301), i32(0xefcdab89), i32(0x98badcfe), i32(0x10325476)
    local band, bor, bxor, bnot = bit32.band, bit32.bor, bit32.bxor, bit32.bnot
    local lshift, rshift = bit32.lshift, bit32.rshift

    for offset = 1, #msg, 64 do
        local M = {}
        for j = 0, 15 do
            local idx = offset + j * 4
            M[j] = string.unpack("<I4", msg, idx)
        end

        local A, B, C, D = a0, b0, c0, d0
        for i = 1, 64 do
            local F, g
            if i <= 16 then
                F = bor(band(B, C), band(bnot(B), D))
                g = i - 1
            elseif i <= 32 then
                F = bor(band(D, B), band(bnot(D), C))
                g = (5 * (i - 1) + 1) % 16
            elseif i <= 48 then
                F = bxor(B, bxor(C, D))
                g = (3 * (i - 1) + 5) % 16
            else
                F = bxor(C, bor(B, bnot(D)))
                g = (7 * (i - 1)) % 16
            end

            local sum = (F + A + MD5_K[i] + M[g]) % 4294967296
            local s = MD5_S[i]
            local rot = bor(lshift(sum, s), rshift(sum, 32 - s))
            A = D
            D = C
            C = B
            B = (B + rot) % 4294967296
        end

        a0 = (a0 + A) % 4294967296
        b0 = (b0 + B) % 4294967296
        c0 = (c0 + C) % 4294967296
        d0 = (d0 + D) % 4294967296
    end

    -- Assemble the digest words manually (see length-packing note above).
    local raw = {}
    for _, v in ipairs({ a0, b0, c0, d0 }) do
        for b = 0, 3 do
            table.insert(raw, string.char(v % 256))
            v = math.floor(v / 256)
        end
    end
    raw = table.concat(raw)
    return (raw:gsub(".", function(c)
        return string.format("%02x", c:byte())
    end))
end
Core.md5Hex = md5Hex

-- ==========================================
-- Hex / custom-base64 decoders (MidiShow payload decoding)
-- ==========================================
local function hexToStr(hexStr)
    local clean = tostring(hexStr or ""):gsub("^W/", ""):gsub('"', ""):gsub("%s+", "")
    local out = {}
    for i = 1, #clean - 1, 2 do
        local pair = clean:sub(i, i + 1)
        if pair == "00" then break end
        local b = tonumber(pair, 16)
        if not b then break end
        table.insert(out, string.char(b))
    end
    return table.concat(out)
end
Core.hexToStr = hexToStr

local function decodeCustomBase64(encoded, alphabet)
    if type(encoded) ~= "string" or type(alphabet) ~= "string" or #alphabet < 64 then
        return ""
    end
    local clean = encoded:gsub("%s+", "")
    local map = {}
    for i = 1, 64 do
        map[alphabet:sub(i, i)] = i - 1
    end
    local padChar = #alphabet >= 65 and alphabet:sub(65, 65) or "="
    map[padChar] = 64

    local bor, band, lshift, rshift = bit32.bor, bit32.band, bit32.lshift, bit32.rshift
    local out = {}
    for i = 1, #clean, 4 do
        local c1 = map[clean:sub(i, i)]
        local c2 = map[clean:sub(i + 1, i + 1)]
        local c3 = map[clean:sub(i + 2, i + 2)] or 64
        local c4 = map[clean:sub(i + 3, i + 3)] or 64
        if c1 ~= nil and c2 ~= nil and c1 < 64 and c2 < 64 then
            local b1 = bor(lshift(c1, 2), rshift(c2, 4))
            table.insert(out, string.char(band(b1, 0xFF)))
            if c3 < 64 then
                local b2 = bor(lshift(band(c2, 0x0F), 4), rshift(c3, 2))
                table.insert(out, string.char(band(b2, 0xFF)))
                if c4 < 64 then
                    local b3 = bor(lshift(band(c3, 0x03), 6), c4)
                    table.insert(out, string.char(band(b3, 0xFF)))
                end
            end
        end
    end
    return table.concat(out)
end
Core.decodeCustomBase64 = decodeCustomBase64

-- ==========================================
-- Standard base64 decoding (file upload / clipboard MIDI)
-- ==========================================
local function decodeBase64(encoded)
    if type(encoded) ~= "string" then return "" end
    local clean = encoded:gsub("%s+", "")
    local map = {}
    for i = 1, #clean do
        local c = clean:sub(i, i)
        if c == "=" then
            map[c] = -1
        elseif not map[c] then
            local v = string.find("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", c, 1, true)
            if v then map[c] = v - 1 end
        end
    end

    local out = {}
    for i = 1, #clean, 4 do
        local c1 = map[clean:sub(i, i)]
        local c2 = map[clean:sub(i + 1, i + 1)]
        local c3 = map[clean:sub(i + 2, i + 2)]
        local c4 = map[clean:sub(i + 3, i + 3)]
        if c1 ~= nil and c1 >= 0 and c2 ~= nil and c2 >= 0 then
            table.insert(out, string.char(bit32.band(bit32.bor(bit32.lshift(c1, 2), bit32.rshift(c2, 4)), 0xFF)))
            if c3 ~= nil and c3 >= 0 then
                table.insert(out, string.char(bit32.band(bit32.bor(bit32.lshift(bit32.band(c2, 0x0F), 4), bit32.rshift(c3, 2)), 0xFF)))
                if c4 ~= nil and c4 >= 0 then
                    table.insert(out, string.char(bit32.band(bit32.bor(bit32.lshift(bit32.band(c3, 0x03), 6), c4), 0xFF)))
                end
            end
        end
    end
    return table.concat(out)
end
Core.decodeBase64 = decodeBase64

-- ==========================================
-- Cookie merging
-- ==========================================
-- Merges an existing cookie jar string with a Set-Cookie response header.
-- Attribute names (expires/path/domain/max-age/samesite) are dropped.
-- Values containing commas (e.g. "Expires=Wed, 21 Oct 2026 07:28:00 GMT")
-- are handled by splitting each comma-chunk on ';' and ignoring continuation
-- fragments that carry no key=value pair.
local function mergeCookieStrings(existing, setCookieHeader)
    local jar = {}
    local order = {}
    local function addPair(name, val)
        if name ~= "" and val ~= nil then
            if jar[name] == nil then
                table.insert(order, name)
            end
            jar[name] = val
        end
    end

    if type(existing) == "string" and existing ~= "" then
        for part in existing:gmatch("[^;]+") do
            local k, v = part:match("^%s*([^=]+)=(.-)%s*$")
            if k then addPair(k, v) end
        end
    end

    if type(setCookieHeader) == "string" and setCookieHeader ~= "" then
        for chunk in setCookieHeader:gmatch("[^,]+") do
            for part in chunk:gmatch("[^;]+") do
                local k, v = part:match("^%s*([^=]+)=([^;]*)%s*$")
                if k then
                    local lowerK = k:lower()
                    if lowerK ~= "expires" and lowerK ~= "path" and lowerK ~= "domain"
                        and lowerK ~= "max-age" and lowerK ~= "samesite" then
                        addPair(k, v)
                    end
                end
                -- Parts without a key (e.g. date fragments of an Expires
                -- attribute) are continuations and are intentionally dropped.
            end
        end
    end

    local out = {}
    for _, k in ipairs(order) do
        table.insert(out, k .. "=" .. jar[k])
    end
    return table.concat(out, "; ")
end
Core.mergeCookieStrings = mergeCookieStrings

-- ==========================================
-- Artist / song-list helpers
-- ==========================================
local function formatArtists(artists)
    if type(artists) == "table" then
        return table.concat(artists, ", ")
    elseif artists ~= nil then
        return tostring(artists)
    end
    return "Unknown"
end
Core.formatArtists = formatArtists

local function parseQuickPickFile(body, jsonDecode)
    local list = {}
    local trimmed = body:gsub("^\239\187\191", ""):match("^%s*(.-)%s*$")

    if trimmed:sub(1, 1) == "[" or trimmed:sub(1, 1) == "{" then
        if jsonDecode then
            local ok, data = pcall(jsonDecode, trimmed)
            if ok and type(data) == "table" then
                local items = data.songs or data
                for _, item in ipairs(items) do
                    if type(item) == "table" and item.url then
                        table.insert(list, {
                            name = tostring(item.name or "Untitled"),
                            url = tostring(item.url),
                        })
                    end
                end
                if #list > 0 then return list end
            end
        end
    end

    -- Plain-text fallback: one "Name | https://.../file.mid" per line,
    -- or a bare URL per line (title derived from the filename).
    for line in body:gmatch("[^\r\n]+") do
        local clean = line:match("^%s*(.-)%s*$")
        if clean ~= "" and not clean:match("^#") and not clean:match("^//") then
            local name, url = clean:match("^(.-)%s*|%s*(https?://.+)$")
            if name and url then
                table.insert(list, {name = name, url = url})
            elseif clean:match("^https?://") then
                local fallbackName = clean:match("([^/]+)%.midi?$") or clean
                table.insert(list, {name = fallbackName, url = clean})
            end
        end
    end

    return list
end
Core.parseQuickPickFile = parseQuickPickFile

-- ==========================================
-- Duration formatting
-- ==========================================
local function formatDuration(seconds)
    local sec = math.max(0, math.floor((tonumber(seconds) or 0) + 0.0001))
    if sec >= 3600 then
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        local s = sec % 60
        return string.format("%d:%02d:%02d", h, m, s)
    end
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%d:%02d", m, s)
end
Core.formatDuration = formatDuration

-- ==========================================
-- MuseScore / MidiShow input normalization
-- ==========================================
local function isMuseScoreUrl(url)
    local clean = tostring(url or ""):lower()
    return clean:find("musescore.com/", 1, true) ~= nil
end
Core.isMuseScoreUrl = isMuseScoreUrl

local function isMidiShowUrl(url)
    local clean = tostring(url or ""):lower()
    return clean:find("midishow.com/", 1, true) ~= nil or clean:find("midishow.net/", 1, true) ~= nil
end
Core.isMidiShowUrl = isMidiShowUrl

local function normalizeMuseScoreInput(input)
    local clean = tostring(input or ""):match("^%s*(.-)%s*$")
    if clean == "" then return nil end
    if clean:match("^%d+$") then
        return "https://musescore.com/scores/" .. clean
    end
    clean = clean:gsub("#.*$", "")
    if not clean:match("^https?://") and clean:lower():find("musescore%.com") then
        clean = "https://" .. clean
    end
    return clean
end
Core.normalizeMuseScoreInput = normalizeMuseScoreInput

local function normalizeMidiShowInput(input)
    local clean = tostring(input or ""):match("^%s*(.-)%s*$")
    if clean == "" then return nil end
    if clean:match("^%d+$") then
        return "https://www.midishow.com/en/midi/" .. clean .. ".html"
    end
    clean = clean:gsub("#.*$", "")
    if not clean:match("^https?://") and clean:lower():find("midishow%.com") then
        clean = "https://" .. clean
    end
    local dlId = clean:match("midishow%.com/[^/]-/?midi/download%?id=(%d+)") or clean:match("midishow%.com/midi/download%?id=(%d+)")
    if dlId then
        return "https://www.midishow.com/en/midi/" .. dlId .. ".html"
    end
    return clean
end
Core.normalizeMidiShowInput = normalizeMidiShowInput

-- Compute real-valued song timestamps (seconds at 1.0x speed) for each event
-- in a MIDI timeline. Events carry `time` (in ticks); tempo events carry
-- `type == "tempo"` and `tempo` (microseconds per quarter note). Annotates
-- each event with `songTime` and returns the total duration in seconds.
-- `division` is ticks per quarter note (or SMPTE-encoded), `isSmpte` flags
-- SMPTE division, and `smpteTicksPerSec` is ticks per second for SMPTE.
local function buildTimeline(events, division, isSmpte, smpteTicksPerSec)
    local preTempo = 500000
    local prevTick = 0
    local songSec = 0
    for _, ev in ipairs(events) do
        local dt = ev.time - prevTick
        if dt > 0 then
            local spt = isSmpte and (1 / smpteTicksPerSec) or ((preTempo / 1000000) / division)
            songSec = songSec + dt * spt
            prevTick = ev.time
        end
        ev.songTime = songSec
        -- A tempo event applies from its own tick onward: events at the same
        -- tick already got their delta computed with the previous tempo.
        if ev.type == "tempo" and ev.tempo > 0 then
            preTempo = ev.tempo
        end
    end
    return songSec
end
Core.buildTimeline = buildTimeline

-- Parse a text sheet into a sorted event list. `isValidChar(c)` reports
-- whether a character maps to a playable key. Returns the events and the
-- total duration in seconds. Chords are `[abc]`, arpeggios `[a b c]`, and
-- each space/`-`/`|`/newline advances one beat.
local function buildTextSheetEvents(sheet, bpm, isValidChar)
    local baseStep = 60 / math.max(tonumber(bpm) or 120, 1) / 2
    local events = {}
    local songSec = 0
    local nextNoteId = 0
    local i = 1
    local len = #sheet

    local function emitPress(chars)
        nextNoteId = nextNoteId + 1
        local noteId = nextNoteId
        table.insert(events, {songTime = songSec, kind = "press", chars = chars, velocity = 0.7, noteId = noteId})
        -- Synthetic release shortly after the press (text sheets have no
        -- noteOff events; this gives a natural staccato feel).
        local hold = math.min(baseStep * 0.7, 0.2)
        table.insert(events, {songTime = songSec + hold, kind = "release", chars = chars, noteId = noteId})
    end

    while i <= len do
        local ch = sheet:sub(i, i)
        if ch == "[" then
            local closeIdx = sheet:find("]", i + 1, true)
            if closeIdx then
                local group = sheet:sub(i + 1, closeIdx - 1)
                if group:find(" ") then
                    -- Arpeggio: each character is played in sequence.
                    for j = 1, #group do
                        local gc = group:sub(j, j)
                        if isValidChar(gc) then
                            nextNoteId = nextNoteId + 1
                            local noteId = nextNoteId
                            table.insert(events, {songTime = songSec, kind = "press", chars = {gc}, velocity = 0.7, noteId = noteId})
                            local hold = math.min(baseStep * 0.35, 0.06)
                            table.insert(events, {songTime = songSec + hold, kind = "release", chars = {gc}, noteId = noteId})
                            songSec = songSec + hold
                        end
                    end
                    songSec = songSec + baseStep * 0.5
                else
                    -- Chord: all characters are pressed simultaneously.
                    local chord = {}
                    for j = 1, #group do
                        local gc = group:sub(j, j)
                        if isValidChar(gc) then
                            table.insert(chord, gc)
                        end
                    end
                    if #chord > 0 then
                        emitPress(chord)
                    end
                    songSec = songSec + baseStep
                end
                i = closeIdx + 1
            else
                i = i + 1
            end
        elseif ch == " " or ch == "-" or ch == "|" or ch == "\n" then
            songSec = songSec + baseStep
            i = i + 1
        elseif isValidChar(ch) then
            emitPress({ch})
            songSec = songSec + baseStep
            i = i + 1
        else
            i = i + 1
        end
    end

    table.sort(events, function(a, b)
        if a.songTime == b.songTime then
            if a.kind ~= b.kind then
                return a.kind == "release"
            end
            return false
        end
        return a.songTime < b.songTime
    end)

    return events, songSec
end
Core.buildTextSheetEvents = buildTextSheetEvents

-- Map an incoming 0..1 velocity through a curve and output range.
-- `curve` is an exponent (1 = linear); values > 1 bias toward the low end.
local function mapVelocity(velocity, min, max, curve)
    local v = velocity or 0.5
    if v < 0 then v = 0 end
    if v > 1 then v = 1 end
    -- Exponential curve: v^curve biases toward the low end when > 1.
    if curve ~= 1 then
        v = v ^ curve
    end
    return min + v * (max - min)
end
Core.mapVelocity = mapVelocity

-- Sort decoded MIDI playback events by tick, preserving the parser's event
-- order at equal ticks. This is required for zero-duration notes and keeps
-- same-tick note-on/note-off ordering faithful to the MIDI stream.
local function sortMidiEvents(events)
    table.sort(events, function(a, b)
        if a.time == b.time then
            return a.order < b.order
        end
        return a.time < b.time
    end)
    return events
end
Core.sortMidiEvents = sortMidiEvents

-- Build sparse snapshots of active note presses for efficient seek restore.
-- Snapshots represent state immediately before `nextIndex`; seeking starts at
-- the nearest prior checkpoint and replays only a bounded event suffix.
local function buildSeekIndex(events, checkpointInterval)
    checkpointInterval = math.max(1, math.floor(tonumber(checkpointInterval) or 256))
    local active = {}
    local checkpoints = {{nextIndex = 1, active = {}}}
    for i, ev in ipairs(events) do
        if ev.noteId ~= nil then
            if ev.kind == "press" then
                active[ev.noteId] = {event = ev, index = i}
            elseif ev.kind == "release" then
                active[ev.noteId] = nil
            end
        end
        if i % checkpointInterval == 0 then
            local snapshot = {}
            for noteId, entry in pairs(active) do
                snapshot[noteId] = entry
            end
            checkpoints[#checkpoints + 1] = {nextIndex = i + 1, active = snapshot}
        end
    end
    return {interval = checkpointInterval, checkpoints = checkpoints}
end
Core.buildSeekIndex = buildSeekIndex

local function getHeldNotesAtIndex(events, nextIndex, seekIndex)
    nextIndex = math.max(1, math.min(#events + 1, math.floor(tonumber(nextIndex) or 1)))
    local checkpoints = seekIndex and seekIndex.checkpoints or {{nextIndex = 1, active = {}}}
    local lo, hi, chosen = 1, #checkpoints, 1
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if checkpoints[mid].nextIndex <= nextIndex then
            chosen = mid
            lo = mid + 1
        else
            hi = mid - 1
        end
    end

    local checkpoint = checkpoints[chosen]
    local active = {}
    for noteId, entry in pairs(checkpoint.active) do
        active[noteId] = entry
    end
    for i = checkpoint.nextIndex, nextIndex - 1 do
        local ev = events[i]
        if ev and ev.noteId ~= nil then
            if ev.kind == "press" then
                active[ev.noteId] = {event = ev, index = i}
            elseif ev.kind == "release" then
                active[ev.noteId] = nil
            end
        end
    end

    local result = {}
    for _, entry in pairs(active) do
        result[#result + 1] = entry
    end
    table.sort(result, function(a, b) return a.index < b.index end)
    return result
end
Core.getHeldNotesAtIndex = getHeldNotesAtIndex

-- Pure note-state helpers shared by playback and tests.
local function releaseActiveNoteToken(tokens, noteToken)
    if type(tokens) ~= "table" then return false, 0 end
    local removed = tokens[noteToken] ~= nil
    if removed then tokens[noteToken] = nil end
    local count = 0
    for _ in pairs(tokens) do count = count + 1 end
    return removed, count
end
Core.releaseActiveNoteToken = releaseActiveNoteToken

local function removeVoiceEntries(voices, keyEnum, noteToken)
    local removed = 0
    for i = #voices, 1, -1 do
        local voice = voices[i]
        if voice.keyEnum == keyEnum and (noteToken == nil or voice.noteToken == noteToken) then
            table.remove(voices, i)
            removed = removed + 1
        end
    end
    return removed
end
Core.removeVoiceEntries = removeVoiceEntries

return Core
