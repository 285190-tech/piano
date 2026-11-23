-- tests/run_tests.lua
-- Unit tests for core.lua (pure Lua 5.3+, no Roblox required).
--
-- Run with any Lua 5.3+ interpreter from the repository root:
--   lua tests/run_tests.lua
--
-- Or without a Lua install (uses fengari, Lua 5.3 in JavaScript):
--   cd tests && npm ci && node run_tests.js

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

    -- In a Standard MIDI File, 0xF7 is followed by a VLQ length and payload.
    local payload = string.char(0x43, 0x12, 0x00)
    local f7Track = table.concat({
        vlq(0) .. string.char(0xF7) .. vlq(#payload) .. payload,
        vlq(1) .. string.char(0x90, 0x40, 0x7F),
        vlq(0) .. metaEvent(0x2F, ""),
    })
    local gotF7 = {}
    local okF7 = pcall(Core.processMidi, Core.createStringStream(buildMidi(f7Track)), function(name, ...)
        table.insert(gotF7, {name = name, args = {...}})
    end)
    check("0xF7 parse does not error", okF7)
    local f7NoteOn = false
    local f7Data
    for _, ev in ipairs(gotF7) do
        if ev.name == "noteOn" and ev.args[2] == 64 then f7NoteOn = true end
        if ev.name == "eox" then f7Data = ev.args[1] end
    end
    check("0xF7 consumed length and payload (noteOn still parsed)", f7NoteOn)
    eq("0xF7 payload", f7Data, payload)
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
    local alphabetWithCustomPad = alphabet .. "."
    eq("65-char alphabet custom padding", Core.decodeCustomBase64("GG..", alphabetWithCustomPad), "A")
    eq("custom base64 rejects short alphabet", Core.decodeCustomBase64("QQ==", alphabet:sub(1, 63)), "")
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
    eq("deriveTitleFromUrl ignores query", Core.deriveTitleFromUrl("https://x.com/dir/song.mid?token=abc"), "song")
    eq("deriveTitleFromUrl ignores fragment", Core.deriveTitleFromUrl("https://x.com/dir/song.mid#section"), "song")
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
-- buildTimeline
-- ==========================================
print("buildTimeline")
do
    local function approx(a, b) return math.abs(a - b) < 1e-9 end

    -- Constant tempo: 500000 us/quarter, 96 ticks/quarter => 0.5s per quarter.
    local events = {
        {time = 0, kind = "press"},
        {time = 96, kind = "press"},
        {time = 192, kind = "press"},
    }
    local total = Core.buildTimeline(events, 96, false, 0)
    check("timeline constant tempo total", approx(total, 1.0), total)
    check("timeline ev0 songTime", approx(events[1].songTime, 0), events[1].songTime)
    check("timeline ev1 songTime", approx(events[2].songTime, 0.5), events[2].songTime)
    check("timeline ev2 songTime", approx(events[3].songTime, 1.0), events[3].songTime)

    -- Tempo change at tick 96 halves the tempo (250000 us/quarter).
    local events2 = {
        {time = 0, kind = "press"},
        {time = 96, type = "tempo", tempo = 250000},
        {time = 192, kind = "press"},
    }
    local total2 = Core.buildTimeline(events2, 96, false, 0)
    check("timeline tempo change total", approx(total2, 0.75), total2)
    check("timeline tempo change ev2 songTime", approx(events2[3].songTime, 0.75), events2[3].songTime)

    -- SMPTE: 100 ticks/sec, event at tick 100 => 1.0s.
    local events3 = {
        {time = 0, kind = "press"},
        {time = 100, kind = "press"},
    }
    local total3 = Core.buildTimeline(events3, 0, true, 100)
    check("timeline smpte total", approx(total3, 1.0), total3)
    check("timeline smpte ev1 songTime", approx(events3[2].songTime, 1.0), events3[2].songTime)
end

-- ==========================================
-- buildTextSheetEvents
-- ==========================================
print("buildTextSheetEvents")
do
    local function approx(a, b) return math.abs(a - b) < 1e-9 end
    local function valid(c) return c == "a" or c == "b" end

    -- Single note at 120 BPM: baseStep = 60/120/2 = 0.25.
    local ev, total = Core.buildTextSheetEvents("a", 120, valid)
    check("sheet single total", approx(total, 0.25), total)
    eq("sheet single event count", #ev, 2)
    eq("sheet single first kind", ev[1].kind, "press")
    check("sheet single first songTime", approx(ev[1].songTime, 0), ev[1].songTime)
    eq("sheet single second kind", ev[2].kind, "release")
    eq("sheet press/release note id", ev[2].noteId, ev[1].noteId)

    -- Chord: both chars pressed together.
    local evc = Core.buildTextSheetEvents("[ab]", 120, valid)
    eq("sheet chord press chars", #evc[1].chars, 2)

    -- Arpeggio: notes are sequential, not simultaneous.
    local eva = Core.buildTextSheetEvents("[a b]", 120, valid)
    eq("sheet arpeggio event count", #eva, 4)
    check("sheet arpeggio sequential", eva[1].songTime == 0 and eva[3].songTime > eva[1].songTime)

    -- Separator advances one beat.
    local _, totals = Core.buildTextSheetEvents("a a", 120, valid)
    check("sheet separator total", approx(totals, 0.75), totals)

    -- Invalid characters are skipped.
    local evi = Core.buildTextSheetEvents("a!", 120, valid)
    eq("sheet invalid skipped count", #evi, 2)
end

-- ==========================================
-- mapVelocity
-- ==========================================
print("mapVelocity")
do
    local function approx(a, b) return math.abs(a - b) < 1e-9 end
    check("velocity linear mid", approx(Core.mapVelocity(0.5, 0.2, 1.0, 1), 0.6))
    check("velocity linear min", approx(Core.mapVelocity(0, 0.2, 1.0, 1), 0.2))
    check("velocity linear max", approx(Core.mapVelocity(1, 0.2, 1.0, 1), 1.0))
    check("velocity nil defaults to 0.5", approx(Core.mapVelocity(nil, 0.2, 1.0, 1), 0.6))
    check("velocity clamps high", approx(Core.mapVelocity(2, 0.2, 1.0, 1), 1.0))
    check("velocity clamps low", approx(Core.mapVelocity(-1, 0.2, 1.0, 1), 0.2))
    check("velocity curve squares", approx(Core.mapVelocity(0.5, 0, 1, 2), 0.25))
end

-- ==========================================
-- sortMidiEvents
-- ==========================================
print("sortMidiEvents")
do
    local events = {
        {time = 12, order = 1, kind = "press", id = "later"},
        {time = 5, order = 3, kind = "press", id = "press3"},
        {time = 5, order = 2, kind = "release", id = "release2"},
        {time = 5, order = 1, kind = "press", id = "press1"},
        {time = 5, order = 4, kind = "release", id = "release4"},
    }
    local sorted = Core.sortMidiEvents(events)
    eq("sort returns input list", sorted, events)
    eq("sort by time and original order", sorted[1].id, "press1")
    eq("mixed event order preserved", sorted[2].id, "release2")
    eq("next press order preserved", sorted[3].id, "press3")
    eq("next release order preserved", sorted[4].id, "release4")
    eq("later tick last", sorted[5].id, "later")
end

-- ==========================================
-- seek index / held-note restoration
-- ==========================================
print("seek index")
do
    local events = {
        {kind = "press", noteId = 10, chars = {"a"}, velocity = 0.4},
        {kind = "press", noteId = 11, chars = {"b"}, velocity = 0.8},
        {kind = "release", noteId = 10, chars = {"a"}},
        {kind = "release", noteId = 11, chars = {"b"}},
    }
    local index = Core.buildSeekIndex(events, 2)
    local held = Core.getHeldNotesAtIndex(events, 3, index)
    eq("seek active press count before releases", #held, 2)
    eq("seek active first note id", held[1].event.noteId, 10)
    eq("seek active second note id", held[2].event.noteId, 11)
    local afterOneRelease = Core.getHeldNotesAtIndex(events, 4, index)
    eq("seek removes released note", #afterOneRelease, 1)
    eq("seek retains still-held note", afterOneRelease[1].event.noteId, 11)
    eq("seek after all releases", #Core.getHeldNotesAtIndex(events, 5, index), 0)
    check("seek index uses sparse checkpoints", #index.checkpoints < #events + 1)

    local many = {{kind = "press", noteId = 10000, chars = {"z"}}}
    for i = 1, 700 do
        many[#many + 1] = {kind = "press", noteId = i, chars = {"x"}}
        many[#many + 1] = {kind = "release", noteId = i, chars = {"x"}}
    end
    local largeIndex = Core.buildSeekIndex(many, 64)
    local largeHeld = Core.getHeldNotesAtIndex(many, #many + 1, largeIndex)
    eq("large seek restores long-held note", #largeHeld, 1)
    eq("large seek restored note identity", largeHeld[1].event.noteId, 10000)
    check("large seek checkpoint count", #largeIndex.checkpoints > 1)

    -- Same-tick events must honor source order: a zero-duration note's release
    -- follows its press instead of being sorted ahead and lost.
    local zeroDuration = {
        {time = 4, order = 1, kind = "press", noteId = 501, chars = {"q"}},
        {time = 4, order = 2, kind = "release", noteId = 501, chars = {"q"}},
    }
    Core.sortMidiEvents(zeroDuration)
    eq("same-tick zero-duration press first", zeroDuration[1].kind, "press")
    eq("same-tick zero-duration release second", zeroDuration[2].kind, "release")
    local zeroIndex = Core.buildSeekIndex(zeroDuration, 1)
    eq("zero-duration note held after press", #Core.getHeldNotesAtIndex(zeroDuration, 2, zeroIndex), 1)
    eq("zero-duration note released after note-off", #Core.getHeldNotesAtIndex(zeroDuration, 3, zeroIndex), 0)
end

-- ==========================================
-- active-note and voice cleanup
-- ==========================================
print("active-note cleanup")
do
    local tokens = {a = true, b = true}
    local removed, remaining = Core.releaseActiveNoteToken(tokens, "a")
    check("release active token", removed)
    eq("active tokens remaining", remaining, 1)
    local removedAgain, stillRemaining = Core.releaseActiveNoteToken(tokens, "a")
    check("duplicate release is ignored", not removedAgain)
    eq("duplicate release preserves other token", stillRemaining, 1)
    local voices = {
        {keyEnum = "Q", noteToken = "a"},
        {keyEnum = "Q", noteToken = "b"},
        {keyEnum = "W", noteToken = "c"},
    }
    eq("remove timed-out voice entry", Core.removeVoiceEntries(voices, "Q", "a"), 1)
    eq("voice count after exact removal", #voices, 2)
    eq("remove all voices for stolen key", Core.removeVoiceEntries(voices, "Q"), 1)
    eq("unrelated voice retained", #voices, 1)
    eq("unrelated key retained", voices[1].keyEnum, "W")
end

-- ==========================================
-- readVLQ boundaries
-- ==========================================
print("readVLQ boundaries")
do
    local function v(bytes) return Core.readVLQ(Core.createStringStream(bytes)) end
    eq("VLQ max 4-byte value", v(string.char(0xFF, 0xFF, 0xFF, 0x7F)), 268435455)
    eq("VLQ 4-byte zero value", v(string.char(0x80, 0x80, 0x80, 0x00)), 0)
end

-- ==========================================
-- formatArtists
-- ==========================================
print("formatArtists")
do
    eq("formatArtists nil", Core.formatArtists(nil), "Unknown")
    eq("formatArtists table", Core.formatArtists({"A", "B"}), "A, B")
    eq("formatArtists string", Core.formatArtists("Solo"), "Solo")
    eq("formatArtists number", Core.formatArtists(42), "42")
end

-- ==========================================
-- mergeCookieStrings
-- ==========================================
print("mergeCookieStrings")
do
    eq("merge basic", Core.mergeCookieStrings("a=1; b=2", "c=3; Path=/"), "a=1; b=2; c=3")
    eq("merge overwrite", Core.mergeCookieStrings("a=1", "a=9"), "a=9")
    eq("merge expires with comma", Core.mergeCookieStrings("", "x=1; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Path=/"), "x=1")
    eq("merge empty", Core.mergeCookieStrings("", ""), "")
end

-- ==========================================
-- processMidi edge cases
-- ==========================================
print("processMidi edge cases")
do
    -- Unknown chunk is skipped; surrounding chunks still parse.
    local track = vlq(0) .. string.char(0x90, 0x40, 0x7F) .. vlq(0) .. metaEvent(0x2F, "")
    local midi = chunk("MThd", string.pack(">I2I2I2", 0, 1, 96))
        .. chunk("XFIH", "junkdata")
        .. chunk("MTrk", track)
    local names = {}
    Core.processMidi(Core.createStringStream(midi), function(name) table.insert(names, name) end)
    eq("unknown chunk: first event", names[1], "header")
    eq("unknown chunk: then track", names[2], "track")

    -- Truncated MTrk (declared length exceeds available data) errors.
    local trunc = chunk("MThd", string.pack(">I2I2I2", 0, 1, 96))
        .. "MTrk" .. string.pack(">I4", 100) .. vlq(0) .. string.char(0x90, 0x40)
    local okTrunc = pcall(Core.processMidi, Core.createStringStream(trunc), function() end)
    check("truncated MTrk errors", okTrunc == false)

    -- Format-1 multi-track: header reports 2 tracks, both chunks parse.
    local t1 = vlq(0) .. metaEvent(0x03, "Track1") .. vlq(0) .. metaEvent(0x2F, "")
    local t2 = vlq(0) .. string.char(0x90, 0x3C, 0x7F) .. vlq(0) .. metaEvent(0x2F, "")
    local midiFmt1 = chunk("MThd", string.pack(">I2I2I2", 1, 2, 96)) .. chunk("MTrk", t1) .. chunk("MTrk", t2)
    local trackCount = 0
    local fmt1Tracks = Core.processMidi(Core.createStringStream(midiFmt1), function(name)
        if name == "track" then trackCount = trackCount + 1 end
    end)
    eq("format-1 header track count", fmt1Tracks, 2)
    eq("format-1 parsed track chunks", trackCount, 2)

    -- Controller, pitch, timeSignature, keySignature, sysex events.
    local evTrack = table.concat({
        vlq(0) .. string.char(0xB0, 7, 100),
        vlq(0) .. string.char(0xE0, 0x00, 0x40),
        vlq(0) .. metaEvent(0x58, string.char(4, 2, 24, 8)),
        vlq(0) .. metaEvent(0x59, string.char(1, 0)),
        vlq(0) .. string.char(0xF0) .. vlq(3) .. "abc",
        vlq(0) .. metaEvent(0x2F, ""),
    })
    local got = {}
    Core.processMidi(Core.createStringStream(buildMidi(evTrack)), function(name, ...)
        table.insert(got, {name = name, args = {...}})
    end)
    local function find(n)
        for _, e in ipairs(got) do if e.name == n then return e end end
    end
    local ctrl = find("controller")
    check("controller event present", ctrl ~= nil)
    if ctrl then
        eq("controller number", ctrl.args[2], 7)
        eq("controller value", ctrl.args[3], 100)
    end
    local pitch = find("pitch")
    check("pitch event present", pitch ~= nil)
    if pitch then check("pitch center is 0", math.abs(pitch.args[2]) < 1e-9, pitch.args[2]) end
    local ts = find("timeSignature")
    check("timeSignature event present", ts ~= nil)
    if ts then
        eq("timeSig numerator", ts.args[1], 4)
        eq("timeSig denominator", ts.args[2], 4)
    end
    local ks = find("keySignature")
    check("keySignature event present", ks ~= nil)
    if ks then
        eq("keySig count", ks.args[1], 1)
        eq("keySig accidental", ks.args[2], "sharp")
    end
    local syx = find("sysexEvent")
    check("sysex event present", syx ~= nil)
    if syx then eq("sysex data", syx.args[1], "abc") end
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
        "buildTimeline", "buildTextSheetEvents", "mapVelocity", "sortMidiEvents",
        "buildSeekIndex", "getHeldNotesAtIndex", "releaseActiveNoteToken",
        "removeVoiceEntries",
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
