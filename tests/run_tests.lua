-- tests/run_tests.lua
-- Unit tests for core.lua (pure Lua 5.3+, no Roblox required).
--
-- Run with any Lua 5.3+ interpreter from the repository root:
--   lua tests/run_tests.lua
--
-- Or without a Lua install (uses fengari, Lua 5.3 in JavaScript):
--   cd tests && npm install && node run_tests.js

local Core = CORE_MODULE
if not Core then
    local candidates = { "core.lua", "../core.lua", "tests/../core.lua" }
    local loaded = false
    for _, path in ipairs(candidates) do
        local f, err = loadfile(path)
        if f then
            Core = f()
            loaded = true
            break
        end
    end
    if not loaded then
        error("Could not locate core.lua (tried: " .. table.concat(candidates, ", ") .. ")")
    end
end

local passed = 0
local failed = 0
local failures = {}

local function check(name, cond, detail)
    if cond then
        passed = passed + 1
        print("  [PASS] " .. name)
    else
        failed = failed + 1
        local msg = name .. (detail and ("  -- " .. tostring(detail)) or "")
        table.insert(failures, msg)
        print("  [FAIL] " .. msg)
    end
end

local function eq(name, actual, expected)
    check(name, actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- ==========================================
-- MIDI byte construction helpers
-- ==========================================
local function vlq(n)
    local bytes = {}
    while true do
        local b = n % 0x80
        n = math.floor(n / 0x80)
        if n > 0 then
            table.insert(bytes, string.char(b + 0x80))
        else
            table.insert(bytes, string.char(b))
            break
        end
    end
    return table.concat(bytes)
end

local function chunk(magic, payload)
    return magic .. string.pack(">I4", #payload) .. payload
end

local function metaEvent(typeByte, data)
    return string.char(0xFF, typeByte) .. vlq(#data) .. data
end

local function buildMidi(trackPayload)
    return chunk("MThd", string.pack(">I2I2I2", 0, 1, 96)) .. chunk("MTrk", trackPayload)
end

-- ==========================================
-- readVLQ
-- ==========================================
print("readVLQ")
do
    local function v(bytes)
        return Core.readVLQ(Core.createStringStream(bytes))
    end
    local ok1, val1, len1 = pcall(v, string.char(0x00))
    eq("VLQ 0", val1, 0)
    eq("VLQ 0 length", len1, 1)

    local ok2, val2, len2 = pcall(v, string.char(0x7F))
    eq("VLQ 0x7F", val2, 127)
    eq("VLQ 0x7F length", len2, 1)

    local ok3, val3 = pcall(v, string.char(0x81, 0x00))
    eq("VLQ 0x81 0x00", val3, 128)

    local ok4, val4 = pcall(v, string.char(0x81, 0x7F))
    eq("VLQ 0x81 0x7F", val4, 255)
    local ok4b, val4b = pcall(v, string.char(0xFF, 0x7F))
    eq("VLQ 0xFF 0x7F", val4b, 16383)

    local ok5 = pcall(v, string.char(0x80, 0x80, 0x80, 0x80, 0x00))
    check("VLQ rejects >4 bytes", ok5 == false)
end

-- ==========================================
-- processMidi: header, notes, tempo, running status, endOfTrack
-- ==========================================
print("processMidi (basic parse)")
do
    local track = table.concat({
        vlq(0) .. metaEvent(0x51, string.pack(">I3", 500000)), -- setTempo 500000
        vlq(0) .. string.char(0x90, 0x40, 0x7F),               -- noteOn  ch1 key64 vel127
        vlq(96) .. string.char(0x80, 0x40, 0x00),              -- noteOff ch1 key64
        vlq(0) .. string.char(0x40, 0x00),                     -- running-status noteOff
        vlq(0) .. metaEvent(0x2F, ""),                         -- endOfTrack
    })
    local midi = buildMidi(track)

    local got = {}
    local tracks = Core.processMidi(Core.createStringStream(midi), function(name, ...)
        table.insert(got, {name = name, args = {...}})
    end)

    eq("track count returned", tracks, 1)

    local header = got[1]
    check("header event", header and header.name == "header")
    if header then
        eq("format", header.args[1], 0)
        eq("tracks", header.args[2], 1)
        eq("division", header.args[3], 96)
    end

    local noteOn, noteOff, tempo, eot = nil, nil, nil, nil
    for _, ev in ipairs(got) do
        if ev.name == "noteOn" then noteOn = ev
        elseif ev.name == "noteOff" then noteOff = ev
        elseif ev.name == "setTempo" then tempo = ev
        elseif ev.name == "endOfTrack" then eot = ev end
    end
    check("noteOn present", noteOn ~= nil)
    if noteOn then
        eq("noteOn channel", noteOn.args[1], 1)
        eq("noteOn key", noteOn.args[2], 64)
        eq("noteOn velocity", noteOn.args[3], 1.0)
    end
    check("noteOff present", noteOff ~= nil)
    if noteOff then
        eq("noteOff channel", noteOff.args[1], 1)
        eq("noteOff key", noteOff.args[2], 64)
    end
    check("setTempo present", tempo ~= nil)
    if tempo then eq("setTempo value", tempo.args[1], 500000) end
    check("endOfTrack present", eot ~= nil)

    -- Second noteOff fired via running status (no status byte).
    local count = 0
    for _, ev in ipairs(got) do
        if ev.name == "noteOff" then count = count + 1 end
    end
    eq("running-status noteOff count", count, 2)
end

-- ==========================================
-- processMidi: system-message stream integrity (0xF1, 0xF7)
-- ==========================================
print("processMidi (system message integrity)")
do
    -- 0xF1 (MTC quarter frame) carries ONE data byte; it must be consumed.
    local f1Track = table.concat({
        vlq(0) .. string.char(0xF1, 0x42),
        vlq(0) .. string.char(0x90, 0x40, 0x7F),
        vlq(0) .. metaEvent(0x2F, ""),
    })
    local gotF1 = {}
    local okF1, tracksF1 = pcall(Core.processMidi, Core.createStringStream(buildMidi(f1Track)), function(name, ...)
        table.insert(gotF1, {name = name, args = {...}})
    end)
    check("0xF1 parse does not error", okF1)
    local f1NoteOn = false
    for _, ev in ipairs(gotF1) do
        if ev.name == "noteOn" and ev.args[2] == 64 then f1NoteOn = true end
    end
    check("0xF1 consumed its data byte (noteOn still parsed)", f1NoteOn)

    -- 0xF7 (EOX) carries NO data bytes; a following note must still parse.
    local f7Track = table.concat({
        vlq(0) .. string.char(0xF7),
        vlq(1) .. string.char(0x90, 0x40, 0x7F),
        vlq(0) .. metaEvent(0x2F, ""),
    })
    local gotF7 = {}
    local okF7 = pcall(Core.processMidi, Core.createStringStream(buildMidi(f7Track)), function(name, ...)
        table.insert(gotF7, {name = name, args = {...}})
    end)
    check("0xF7 parse does not error", okF7)
    local f7NoteOn = false
    for _, ev in ipairs(gotF7) do
        if ev.name == "noteOn" and ev.args[2] == 64 then f7NoteOn = true end
    end
    check("0xF7 consumed no data (noteOn still parsed)", f7NoteOn)
end

-- ==========================================
-- MD5
-- ==========================================
print("md5Hex")
do
    eq("md5 empty", Core.md5Hex(""), "d41d8cd98f00b204e9800998ecf8427e")
    eq("md5 abc", Core.md5Hex("abc"), "900150983cd24fb0d6963f7d28e17f72")
    eq("md5 fox", Core.md5Hex("The quick brown fox jumps over the lazy dog"), "9e107d9d372bb6826bd81d3542a419d6")
    eq("md5 long (56 bytes)", Core.md5Hex(string.rep("a", 56)), "3b0c8ac703f828b04c6c197006d17218")
end

-- ==========================================
-- Custom base64 round-trip
-- ==========================================
print("decodeCustomBase64")
do
    local alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"

    local function b64Encode(data)
        local out = {}
        for i = 1, #data, 3 do
            local b1 = string.byte(data, i)
            local b2 = string.byte(data, i + 1)
            local b3 = string.byte(data, i + 2)
            table.insert(out, alphabet:sub(bit32.rshift(b1, 2) + 1, bit32.rshift(b1, 2) + 1))
            local c2 = bit32.bor(bit32.lshift(bit32.band(b1, 0x03), 4), bit32.rshift(b2 or 0, 4))
            table.insert(out, alphabet:sub(c2 + 1, c2 + 1))
            if b2 then
                local c3 = bit32.bor(bit32.lshift(bit32.band(b2, 0x0F), 2), bit32.rshift(b3 or 0, 6))
                table.insert(out, alphabet:sub(c3 + 1, c3 + 1))
                if b3 then
                    table.insert(out, alphabet:sub(bit32.band(b3, 0x3F) + 1, bit32.band(b3, 0x3F) + 1))
                else
                    table.insert(out, "=")
                end
            else
                table.insert(out, "=")
                table.insert(out, "=")
            end
        end
        return table.concat(out)
    end

    local samples = { "Hello, Midi!", "A", "AB", "ABC", "ABCD", "1234567890" }
    local allOk = true
    for _, s in ipairs(samples) do
        local encoded = b64Encode(s)
        local decoded = Core.decodeCustomBase64(encoded, alphabet)
        if decoded ~= s then
            allOk = false
            check("base64 round-trip " .. s, false, "encoded=" .. encoded .. " decoded=" .. decoded)
        end
    end
    if allOk then
        check("base64 round-trip (all samples)", true)
    end
end

-- Standard base64 decoding
print("decodeBase64")
do
    eq("base64 decode empty", Core.decodeBase64(""), "")
    eq("base64 decode SGVsbG8=", Core.decodeBase64("SGVsbG8="), "Hello")
    eq("base64 decode aGVsbG8=", Core.decodeBase64("aGVsbG8="), "hello")
    eq("base64 decode no padding", Core.decodeBase64("SGVsbG8"), "Hello")
    eq("base64 decode ignores whitespace", Core.decodeBase64("SGVs bG8="), "Hello")
    eq("base64 decode MThd", Core.decodeBase64("TVRoZA=="), "MThd")
end

-- ==========================================
-- hexToStr
-- ==========================================
print("hexToStr")
do
    eq("hexToStr basic", Core.hexToStr("414243"), "ABC")
    eq("hexToStr W/ prefix + NUL stop", Core.hexToStr("W/41424300"), "ABC")
    eq("hexToStr empty", Core.hexToStr(""), "")
end

-- ==========================================
-- HTML helpers
-- ==========================================
print("HTML helpers")
do
    eq("stripHtmlTags", Core.stripHtmlTags("<b>Hello</b> <i>world</i>"), "Hello world")
    eq("decodeHtmlEntities", Core.decodeHtmlEntities("a &amp; b &lt;c&gt; &quot;q&quot;"), 'a & b <c> "q"')
    eq("stripHtmlTags entities", Core.stripHtmlTags("Tom &amp; Jerry&#39;s"), "Tom & Jerry's")
end

-- ==========================================
-- URL helpers
-- ==========================================
print("URL helpers")
do
    eq("normalizeMidiUrl github blob",
        Core.normalizeMidiUrl("https://github.com/me/repo/blob/main/songs.mid"),
        "https://raw.githubusercontent.com/me/repo/main/songs.mid")
    eq("normalizeMidiUrl github raw",
        Core.normalizeMidiUrl("https://github.com/me/repo/raw/main/songs.mid"),
        "https://raw.githubusercontent.com/me/repo/main/songs.mid")
    eq("normalizeMidiUrl spaces",
        Core.normalizeMidiUrl("https://example.com/my song.mid"),
        "https://example.com/my%20song.mid")

    local cands = Core.buildRepoUrlCandidates("https://raw.githubusercontent.com/me/repo/refs/heads/main/songs.json")
    eq("repo candidates count", #cands, 2)
    eq("repo candidates first", cands[1], "https://raw.githubusercontent.com/me/repo/refs/heads/main/songs.json")
    eq("repo candidates second", cands[2], "https://raw.githubusercontent.com/me/repo/main/songs.json")

    eq("encodeUrlPath", Core.encodeUrlPath("a b/c d.mid"), "a%20b/c%20d.mid")
    eq("encodeQueryParam", Core.encodeQueryParam("unravel op"), "unravel%20op")
    eq("deriveTitleFromUrl", Core.deriveTitleFromUrl("https://x.com/dir/My%20Song.mid"), "My Song")
end

-- ==========================================
-- Search / filter
-- ==========================================
print("matchesQuery / filterSongList")
do
    check("matchesQuery empty query", Core.matchesQuery("anything", "") == true)
    check("matchesQuery token", Core.matchesQuery("Tokyo Ghoul - Unravel", "unravel") == true)
    check("matchesQuery no match", Core.matchesQuery("Beethoven", "chopin") == false)
    check("matchesQuery multi-token", Core.matchesQuery("JoJo - Bloody Stream", "jojo stream") == true)

    local list = { "Alpha", "Beta one", "Gamma two", "Delta" }
    local matches, total = Core.filterSongList(list, "a", 2)
    eq("filterSongList total", total, 4)
    eq("filterSongList limit", #matches, 2)
    eq("filterSongList first", matches[1], "Alpha")
end

-- ==========================================
-- parseQuickPickFile
-- ==========================================
print("parseQuickPickFile")
do
    local lines = table.concat({
        "Fur Elise | https://example.com/fur-elise.mid",
        "https://example.com/bare.mid",
        "# comment line",
        "",
    }, "\n")
    local parsed = Core.parseQuickPickFile(lines)
    eq("line format name", parsed[1].name, "Fur Elise")
    eq("line format url", parsed[1].url, "https://example.com/fur-elise.mid")
    eq("bare url entry", parsed[2].name, "bare")

    local stubDecoder = function(str)
        -- Minimal decoder for the test's single JSON array of {name,url}.
        local items = {}
        for name, url in str:gmatch('"name"%s*:%s*"([^"]+)"%s*,%s*"url"%s*:%s*"([^"]+)"') do
            table.insert(items, { name = name, url = url })
        end
        return items
    end
    local json = '[{"name": "Song One", "url": "https://a/one.mid"}, {"name": "Song Two", "url": "https://a/two.mid"}]'
    local parsedJson = Core.parseQuickPickFile(json, stubDecoder)
    eq("json entry count", #parsedJson, 2)
    eq("json entry name", parsedJson[1].name, "Song One")
    eq("json entry url", parsedJson[1].url, "https://a/one.mid")
end

-- ==========================================
-- mergeCookieStrings
-- ==========================================
print("mergeCookieStrings")
do
    local merged = Core.mergeCookieStrings("", "session=abc123; Expires=Wed, 21 Oct 2026 07:28:00 GMT; Path=/; uid=42")
    eq("cookie merge filters attributes", merged, "session=abc123; uid=42")

    local merged2 = Core.mergeCookieStrings("old=1; keep=yes", "new=2; Path=/")
    eq("cookie merge keeps existing", merged2, "old=1; keep=yes; new=2")
end

-- ==========================================
-- formatDuration
-- ==========================================
print("formatDuration")
do
    eq("duration 0", Core.formatDuration(0), "0:00")
    eq("duration 65", Core.formatDuration(65), "1:05")
    eq("duration 3661", Core.formatDuration(3661), "1:01:01")
    eq("duration nil", Core.formatDuration(nil), "0:00")
end

-- ==========================================
-- MuseScore / MidiShow input normalization
-- ==========================================
print("MuseScore / MidiShow normalization")
do
    eq("musescore id", Core.normalizeMuseScoreInput("5352121"), "https://musescore.com/scores/5352121")
    eq("musescore bare domain", Core.normalizeMuseScoreInput("musescore.com/user/x/scores/9"), "https://musescore.com/user/x/scores/9")
    eq("midishow id", Core.normalizeMidiShowInput("36409"), "https://www.midishow.com/en/midi/36409.html")
    eq("midishow download link", Core.normalizeMidiShowInput("https://www.midishow.com/midi/download?id=777"), "https://www.midishow.com/en/midi/777.html")
    check("isMuseScoreUrl", Core.isMuseScoreUrl("https://musescore.com/scores/1") == true)
    check("isMidiShowUrl", Core.isMidiShowUrl("https://www.midishow.com/en/midi/1.html") == true)
end

-- ==========================================
-- Module integrity
-- ==========================================
print("core.lua exports")
do
    local expected = {
        "createStringStream", "read", "readVLQ", "processMidi", "processEvent",
        "md5Hex", "decodeCustomBase64", "decodeBase64", "hexToStr", "mergeCookieStrings",
        "normalizeMidiUrl", "buildRepoUrlCandidates", "matchesQuery",
        "filterSongList", "parseQuickPickFile", "formatDuration",
        "stripHtmlTags", "decodeHtmlEntities", "encodeUrlPath", "encodeQueryParam",
        "deriveTitleFromUrl", "formatArtists", "isMuseScoreUrl", "isMidiShowUrl",
        "normalizeMuseScoreInput", "normalizeMidiShowInput",
    }
    local missing = {}
    for _, key in ipairs(expected) do
        if Core[key] == nil then table.insert(missing, key) end
    end
    check("all expected exports present", #missing == 0, "missing: " .. table.concat(missing, ", "))
end

-- ==========================================
-- Summary
-- ==========================================
__TEST_SUMMARY = { passed = passed, failed = failed, failures = failures }
print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
    for _, f in ipairs(failures) do
        print("  FAILED: " .. f)
    end
    error(string.format("%d test(s) failed", failed))
end
