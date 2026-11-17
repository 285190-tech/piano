local QUICKPICKS_REPO_URL = "https://raw.githubusercontent.com/q-29/piano/refs/heads/main/songs.json"

local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ==========================================
-- Built-in Fallback Quick Picks
-- ==========================================
local DEFAULT_QUICKPICKS = {
    {name = "Tokyo Ghoul - Unravel (Full)", url = "https://raw.githubusercontent.com/callmeyyzx/midi/main/%E3%80%90%E4%B8%9C%E4%BA%AC%E5%96%B0%E7%A7%8D%E4%B8%9C%E4%BA%AC%E9%A3%9F%E5%B0%B8%E9%AC%BC%E3%80%91OP-------Unravel.mid"},
    {name = "Tokyo Ghoul - Unravel (Simple)", url = "https://raw.githubusercontent.com/MAraragi/MusicalScoreRecognition/master/new_midi_file/unravel_after.mid"},
    {name = "Squid Game - Way Back Then", url = "https://drive.google.com/uc?export=download&id=1sKk0g3fmmXMEwrWgE239Bh_mnIC_5NeK"},
    {name = "Squid Game 2 - Mingle Game (Round and Round)", url = "https://drive.google.com/uc?export=download&id=1pDXaMuoX_7v5m_-O0hkxzcGie_txl9Au"},
    {name = "JoJo - Giorno's Theme (Golden Wind)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Golden%20Wind_JJBA_Giorno_Giovannas_Theme_SOLO.mid"},
    {name = "JoJo - Bloody Stream", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Bloody%20Stream%20%28JoJo%27s%20Bizarre%20Adventure%29.mid"},
    {name = "JoJo - Awaken (Pillar Men)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Jojo%27s%20Bizarre%20Adventure-%20Awaken%20%28Pillar%20Men%20theme%29.mid"},
    {name = "JoJo - Jonathan's Victory Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Jonathan%27s%20Victory%20Theme.mid"},
    {name = "Rush E", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/main/rush_e_real.mid"},
    {name = "Yiruma - River Flows in You", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/main/River-Flows-In-You.mid"},
    {name = "JVKE - Golden Hour", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/main/JVKE%20-%20golden%20hour.mid"},
    {name = "Canon Rock", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/main/Canon-Rock.mid"},
    {name = "The Stranglers - Golden Brown", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/main/The%20Stranglers%20-%20Golden%20Brown%20%28Updated%29.mid"},
    {name = "Beethoven - Fur Elise", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Fur%20Elise.mid"},
    {name = "Beethoven - Moonlight Sonata (1st Mvt)", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/main/Beethoven%20-%20Moonlight%20Sonata%20%281st%20Movement%29%20.mid"},
    {name = "Beethoven - Moonlight Sonata (3rd Mvt)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Beethoven-%20Moonlight%20Sonata%20%283rd%20mvt.%29.mid"},
    {name = "Beethoven - Ode To Joy", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Beethoven%20-%20Ode%20To%20Joy.mid"},
    {name = "Beethoven Virus", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Beethoven%20Virus%20%281%29.mid"},
    {name = "Pachelbel - Canon in D", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Canon%20in%20D.mid"},
    {name = "Erik Satie - Gymnopedie No. 1", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Erik%20Satie%20-%20Gymnopedie%20No.%201.mid"},
    {name = "Chopin - Revolutionary Etude", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Chopin%27s%20revolutionary%20etude.mid"},
    {name = "Chopin - Minute Waltz", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Chopin-Minute%20Waltz%20%28op%2064%20no%201%29.mid"},
    {name = "Vivaldi - Four Seasons Winter (Rousseau)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Antonio%20Vivaldi%20-%20The%20Four%20Seasons%20%5BWinter%20Mvt%201.%5D%20%28Rousseau%20Cover%29.mid"},
    {name = "Grieg - In the Hall of the Mountain King", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/In%20the%20hall%20of%20the%20Mountain%20King.mid"},
    {name = "Monti - Czardas", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Czardas.mid"},
    {name = "Scott Joplin - Maple Leaf Rag", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/JOPLIN.Maple%20leaf%20rag.mid"},
    {name = "Howl's Moving Castle - Merry-Go-Round of Life", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Joe%20Hisaishi%20-%20Merry%20Go%20Round%20Of%20Life%20%28Howl%27s%20Moving%20Castle%29.mid"},
    {name = "Naruto Shippuden - Blue Bird", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Blue%20Bird%20-%20Naruto%20Shippuden%20OP3.mid"},
    {name = "Your Lie in April - Hikaru Nara", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Hikaru%20Nara.mid"},
    {name = "Evangelion - Cruel Angel's Thesis", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Evangelion%20-%20Cruel%20Angel%27s%20Thesis.mid"},
    {name = "Death Note - L's Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Death%20Note%20-%20L%27s%20Theme.mid"},
    {name = "Attack on Titan - Jiyuu no Tsubasa", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Attack%20on%20Titan%20-%20Jiyuu%20no%20Tsubasa.mid"},
    {name = "Demon Slayer", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Demon%20Slayer.mid.mid"},
    {name = "Dragon Ball Z - CHA-LA HEAD-CHA-LA", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/CHA%20LA%20HEAD%20CHA%20LA%20%28Dragon%20Ball%20Z%29.mid"},
    {name = "Hatsune Miku - Senbonzakura", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Hatsune%20Miku%20-%20Senbonzakura.mid"},
    {name = "Touhou - Bad Apple", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Bad%20Apple.mid"},
    {name = "Undertale - Megalovania", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/main/Undertale%20-%20Megalovania%20%28Remaster%20coming%20no%20soon%29.mid"},
    {name = "Undertale - Hopes and Dreams", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Hopes%20and%20Dreams%20-%20Undertale%20%28WIP%29.mid"},
    {name = "Undertale - Bergentruckung (Asgore)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Bergentruckung%20asgore%20theme%20%28original%20transcription%2C%20full%29.mid"},
    {name = "OMORI - Duet", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/DUET%20%28OMORI%29.mid"},
    {name = "DMC5 - Bury The Light", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Bury%20The%20Light%20%28DMC5%29.mid"},
    {name = "Dark Souls - Gwyn, Lord of Cinder", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Gwyn%2C%20Lord%20of%20Cinder.mid.mid"},
    {name = "Skyrim - Dragonborn Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Elder%20Scrolls%20V%20-%20Skyrim%20-%20Dragonborn%20Theme.mid"},
    {name = "Hollow Knight - Mantis Lords", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Hollow%20Knight%20-%20Mantis%20Lords%20Theme.mid"},
    {name = "Hollow Knight - Hornet", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Hollow%20Knight_%20Hornet.mid"},
    {name = "Minecraft - Sweden", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/C418%20-%20Sweden.mid"},
    {name = "Minecraft - Mice on Venus", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Mice%20on%20Venus%20-%20Minecraft.mid"},
    {name = "Minecraft - Subwoofer Lullaby", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Subwoofer%20Lullaby-C418-%20Minecraft.mid"},
    {name = "Minecraft - Aria Math", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Aria%20Math%20-%20C418.mid"},
    {name = "Minecraft - Pigstep", url = "https://raw.githubusercontent.com/callmeyyzx/midi/main/Pigstep__Minecraft.mid"},
    {name = "FNAF 1 Song - The Living Tombstone", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/FNAF%201%20Song%20-%20The%20Living%20Tombstone.mid"},
    {name = "Geometry Dash - Stereo Madness", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Geometry%20Dash%20-%20Stereo%20Madness.mid"},
    {name = "Bad Piggies Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Bad%20Piggies%20Theme.mid"},
    {name = "Zelda OoT - Song of Storms", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/The%20Legend%20of%20Zelda%20Ocarina%20of%20Time%20-%20Song%20of%20Storms.mid"},
    {name = "Super Mario Bros Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Mario%20Bros.%20-%20Super%20Mario%20Bros.%20Theme.mid"},
    {name = "Super Mario 64 - Inside the Castle Walls", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Inside%20the%20Castle%20Walls%20-%20Super%20Mario%2064.mid"},
    {name = "Tetris - A Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Tetris%20-%20A%20Theme.mid"},
    {name = "Pokemon Center Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Pokemon%20-%20Pokemon%20Center%20Theme.mid"},
    {name = "Wii - Mii Channel Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Mii%20Channel%20Theme%20%28Pixel-Phil%29.mid"},
    {name = "Harry Potter - Hedwig's Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Harry%20Potter%20-%20Hedwig%27s%20Theme.mid"},
    {name = "Pirates of the Caribbean - He's a Pirate", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Pirates%20of%20the%20Caribbean%20-%20He%27s%20a%20Pirate.mid"},
    {name = "Interstellar - Main Theme (Hans Zimmer)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Interstellar%20Main%20Theme-%20Hans%20Zimmer.mid"},
    {name = "Inception - Time (Hans Zimmer)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Hans%20Zimmer%20-%20Time.mid"},
    {name = "How to Train Your Dragon - Test Drive", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/How%20to%20train%20your%20dragon%20-%20Test%20Drive.mid"},
    {name = "Star Wars - Duel of the Fates", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Duel%20of%20the%20Fates%20by%20John%20Williams.mid"},
    {name = "Adele - Skyfall", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Adele%20-%20Skyfall.mid"},
    {name = "Queen - Bohemian Rhapsody", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Bohemian-Rhapsody-1.mid"},
    {name = "Coldplay - Viva La Vida", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Coldplay%20-%20Viva%20La%20Vida.mid"},
    {name = "Coldplay - Clocks", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Coldplay%20-%20Clocks%20%28Full%20Song%29.mid"},
    {name = "Billy Joel - Piano Man", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Billy%20Joel%20-%20Piano%20Man.mid"},
    {name = "a-ha - Take On Me", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/A-ha%20-%20Take%20on%20me.mid"},
    {name = "ABBA - Dancing Queen", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/ABBA%20-%20Dancing%20Queen.mid"},
    {name = "Smash Mouth - All Star", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/All%20Star%20-%20Smash%20Mouth.mid"},
    {name = "George Michael - Careless Whisper", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Careless%20Whisper%20-%20George%20Michael.mid"},
    {name = "Astronomia (Coffin Dance)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Coffin%20Dance%20-%20Astronomia.mid"},
    {name = "Alan Walker - Faded", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Faded%20-%20Alan%20Walker.mid"},
    {name = "Avicii - Wake Me Up", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Avicii%20-%20Wake%20Me%20Up.mid"},
    {name = "It's Just a Burning Memory", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/It%27s%20just%20a%20burning%20memory%20-%20A1.mid"},
    {name = "Laufey - From The Start", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/From%20the%20start%20-%20Laufey.mid"},
    {name = "Arctic Monkeys - 505", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/505%20-%20Arctic%20Monkeys.mid"},
    {name = "Eminem - The Real Slim Shady", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Eminem%20-%20The%20Real%20Slim%20Shady.mid"},
    {name = "Rick Astley - Never Gonna Give You Up", url = "https://raw.githubusercontent.com/callmeyyzx/midi/main/Never%20gonna%20give%20you%20up.mid"},
}

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

local function read(stream, count)
    local result = ""
    while #result < count do
        local r = stream:read(count - #result)
        if not r or r == "" then error("missing value") end
        result = result .. r
    end
    return result
end

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
        if length > 4 then error("VLQ too long") end
    until byte < 0x80
    return value, length
end

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
        local b1, b2, b3 = string.byte(data, 1, 3)
        local rawTempo = bit32.bor(bit32.lshift(b1, 16), bit32.lshift(b2, 8), b3)
        callback("setTempo", rawTempo)
    end,
    [0x54] = makeForwarder("smpteOffset"),
    [0x58] = function(data, callback)
        local numerator, denominator, metronome, dotted = string.byte(data, 1, 4)
        callback("timeSignature", numerator, bit32.lshift(1, denominator), metronome, dotted)
    end,
    [0x59] = function(data, callback)
        local count, minor = string.byte(data, 1, 2)
        if count >= 128 then count = count - 256 end
        callback("keySignature", math.abs(count), count < 0 and "flat" or count > 0 and "sharp" or "C", minor == 0 and "major" or "minor")
    end,
    [0x7F] = makeForwarder("sequenceEvent")
}

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

local function readHeader(stream, callback, chunkLength)
    local header = read(stream, chunkLength)
    local format, tracks, division = string.unpack(">I2I2I2", header)
    callback("header", format, tracks, division)
    return format, tracks
end

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
        if status == 0xF0 or status == 0xF7 then
            local dataLen, vlqLen = readVLQ(stream)
            local data = read(stream, dataLen)
            callback("sysexEvent", data, status)
            return 1 + vlqLen + dataLen, runningStatus
        elseif status == 0xF2 then
            read(stream, 2)
            return 3, runningStatus
        elseif status == 0xF3 then
            read(stream, 1)
            return 2, runningStatus
        elseif status == 0xFF then
            local metaType = read(stream, 1)
            return 1 + metaEvent(stream, callback, metaType), runningStatus
        else
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
            stream:seek("cur", chunkLength)
        end
    end
    return tracks
end

-- ==========================================
-- Virtual Piano Key Mapping & Input
-- ==========================================
local keys = "1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm"
local startNote = 36

local digitKeyCodes = {
    ["1"] = Enum.KeyCode.One,   ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three, ["4"] = Enum.KeyCode.Four,
    ["5"] = Enum.KeyCode.Five,  ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven, ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,  ["0"] = Enum.KeyCode.Zero,
}

local shiftSymbolToDigit = {
    ["!"] = "1", ["@"] = "2", ["#"] = "3", ["$"] = "4", ["%"] = "5",
    ["^"] = "6", ["&"] = "7", ["*"] = "8", ["("] = "9", [")"] = "0",
}

local MidiToChar = {}
local CharToKeyInfo = {}

for i = 1, #keys do
    local ch = keys:sub(i, i)
    local isUpper = ch:upper() == ch and ch:lower() ~= ch
    local mappedDigit = shiftSymbolToDigit[ch]
    local needsShift = isUpper or (mappedDigit ~= nil)
    local baseChar = mappedDigit or ch:upper()
    local keyEnum = digitKeyCodes[baseChar] or Enum.KeyCode[baseChar]

    MidiToChar[startNote + i - 1] = ch
    CharToKeyInfo[ch] = {
        keyEnum = keyEnum,
        needsShift = needsShift,
    }
end

local keyPressId = {}
local keyHeld = {}

local function playChar(char)
    local info = CharToKeyInfo[char]
    if not info or not info.keyEnum then return end

    local keyEnum = info.keyEnum
    local pressId = (keyPressId[keyEnum] or 0) + 1
    keyPressId[keyEnum] = pressId

    if keyHeld[keyEnum] then
        VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
        keyHeld[keyEnum] = false
    end

    if info.needsShift then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
    end

    VirtualInputManager:SendKeyEvent(true, keyEnum, false, game)
    keyHeld[keyEnum] = true

    if info.needsShift then
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end

    task.delay(0.02, function()
        if keyPressId[keyEnum] == pressId and keyHeld[keyEnum] then
            VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
            keyHeld[keyEnum] = false
        end
    end)
end

-- ==========================================
-- Playback State & Players
-- ==========================================
local currentPlaybackSpeed = 1
local playing = false
local loading = false
local playbackId = 0

local function stopPlayback()
    playbackId = playbackId + 1
    playing = false
    loading = false
end

local function parseAndPlayMidi(midiString, myId)
    local mthdIdx = midiString:find("MThd", 1, true)
    if not mthdIdx then
        warn("[Piano] Missing MThd header")
        if playbackId == myId then playing = false end
        return
    end
    if mthdIdx > 1 then
        midiString = midiString:sub(mthdIdx)
    end

    playing = true
    local stream = createStringStream(midiString)

    local division = 96
    local events = {}
    local currentTime = 0
    local order = 0

    local ok, err = pcall(processMidi, stream, function(name, ...)
        if name == "header" then
            local _, _, div = ...
            division = div
        elseif name == "track" then
            currentTime = 0
        elseif name == "deltatime" then
            local ticks = ...
            currentTime = currentTime + ticks
        elseif name == "noteOn" then
            local _, key, velocity = ...
            if velocity > 0 then
                order = order + 1
                table.insert(events, {time = currentTime, order = order, type = "note", key = key})
            end
        elseif name == "setTempo" then
            local rawTempo = ...
            order = order + 1
            table.insert(events, {time = currentTime, order = order, type = "tempo", tempo = rawTempo})
        end
    end)

    if not ok then
        warn("[Piano] MIDI parse error:", err)
        if playbackId == myId then playing = false end
        return
    end

    table.sort(events, function(a, b)
        if a.time == b.time then
            return a.order < b.order
        end
        return a.time < b.time
    end)

    local isSmpte = bit32.btest(division, 0x8000)
    local smpteTicksPerSec = 0
    if isSmpte then
        local fpsRaw = bit32.rshift(division, 8)
        if fpsRaw >= 128 then fpsRaw = fpsRaw - 256 end
        local fps = math.abs(fpsRaw)
        if fps == 29 then fps = 29.97 end
        smpteTicksPerSec = fps * bit32.band(division, 0xFF)
    elseif division <= 0 then
        division = 96
    end

    local currentTempo = 500000
    local lastTime = 0
    local nextEventClock = os.clock()
    local lastYieldClock = nextEventClock

    for _, ev in ipairs(events) do
        if not playing or playbackId ~= myId then break end

        local deltaTicks = ev.time - lastTime
        if deltaTicks > 0 then
            local secondsPerTick = isSmpte and (1 / smpteTicksPerSec) or ((currentTempo / 1000000) / division)
            local waitTime = (deltaTicks * secondsPerTick) / currentPlaybackSpeed
            nextEventClock = nextEventClock + waitTime

            local remaining = nextEventClock - os.clock()
            if remaining > 0 then
                task.wait(remaining)
                lastYieldClock = os.clock()
            elseif remaining < -0.5 then
                nextEventClock = os.clock()
            end
            lastTime = ev.time
        end

        if not playing or playbackId ~= myId then break end

        if os.clock() - lastYieldClock > 0.03 then
            task.wait()
            lastYieldClock = os.clock()
        end

        if ev.type == "tempo" then
            currentTempo = ev.tempo
        elseif ev.type == "note" then
            local char = MidiToChar[ev.key]
            if char then
                playChar(char)
            end
        end
    end

    if playbackId == myId then
        playing = false
    end
end

local function playTextSheet(sheet, bpm, myId)
    playing = true
    local i = 1
    local len = #sheet

    while i <= len do
        if not playing or playbackId ~= myId then break end

        local step = (60 / bpm / 2) / currentPlaybackSpeed
        local ch = sheet:sub(i, i)

        if ch == "[" then
            local closeIdx = sheet:find("]", i + 1, true)
            if closeIdx then
                local group = sheet:sub(i + 1, closeIdx - 1)
                if group:find(" ") then
                    for j = 1, #group do
                        if not playing or playbackId ~= myId then break end
                        local gc = group:sub(j, j)
                        if CharToKeyInfo[gc] then
                            playChar(gc)
                            task.wait(math.min(step * 0.35, 0.06))
                        end
                    end
                    task.wait(step * 0.5)
                else
                    for j = 1, #group do
                        local gc = group:sub(j, j)
                        if CharToKeyInfo[gc] then
                            playChar(gc)
                        end
                    end
                    task.wait(step)
                end
                i = closeIdx + 1
            else
                i = i + 1
            end
        elseif ch == " " or ch == "-" or ch == "|" or ch == "\n" then
            task.wait(step)
            i = i + 1
        elseif CharToKeyInfo[ch] then
            playChar(ch)
            task.wait(step)
            i = i + 1
        else
            i = i + 1
        end
    end

    if playbackId == myId then
        playing = false
    end
end

-- ==========================================
-- Rayfield UI
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "🎹 Universal Piano",
    LoadingTitle = "Loading Notes...",
    LoadingSubtitle = "by Swazi",
    ToggleUIKeybind = Enum.KeyCode.Quote,
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local QuickTab = Window:CreateTab("Quick Picks & URL", 4483362458)
local LocalTab = Window:CreateTab("Local & Sheets", 4483362458)
local NanoTab = Window:CreateTab("NanoMIDI API", 4483362458)

-- ==========================================
-- HTTP & URL Helpers
-- ==========================================
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)

local function normalizeMidiUrl(url)
    local clean = tostring(url or ""):match("^%s*(.-)%s*$")
    clean = clean:gsub("^https?://github%.com/([^/]+)/([^/]+)/blob/(.+)$", "https://raw.githubusercontent.com/%1/%2/%3")
    clean = clean:gsub("^https?://github%.com/([^/]+)/([^/]+)/raw/(.+)$", "https://raw.githubusercontent.com/%1/%2/%3")
    clean = clean:gsub(" ", "%%20")
    return clean
end

local function safeRequest(url, customHeaders)
    local headers = {
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        ["Accept"] = "*/*",
    }
    if customHeaders then
        for k, v in pairs(customHeaders) do
            headers[k] = v
        end
    end

    if httpRequest then
        local ok, res = pcall(httpRequest, {
            Url = url,
            Method = "GET",
            Headers = headers,
        })
        if not ok then
            return false, nil, tostring(res)
        end
        if type(res) ~= "table" then
            return false, nil, "Unexpected response type: " .. type(res)
        end
        return true, res, nil
    end

    local getOk, body = pcall(game.HttpGet, game, url)
    if getOk and type(body) == "string" then
        return true, {StatusCode = 200, Body = body}, nil
    end
    return false, nil, "Executor does not support request() or HttpGet failed"
end

local function downloadAndPlayUrl(rawUrl, sourceName)
    if loading or playing then return end

    local url = normalizeMidiUrl(rawUrl)
    if not url or not url:match("^https?://") then
        Rayfield:Notify({
            Title = "Invalid URL",
            Content = "Please enter or select a valid http:// or https:// .mid URL.",
            Duration = 3,
        })
        return
    end

    loading = true
    playbackId = playbackId + 1
    local myId = playbackId

    task.spawn(function()
        local ok, res, err = safeRequest(url)
        loading = false

        if not ok then
            warn("[" .. sourceName .. "] Request error:", err)
            Rayfield:Notify({Title = "Download Failed", Content = tostring(err), Duration = 4})
            return
        end

        local status = res.StatusCode or res.status_code
        if status ~= 200 then
            warn("[" .. sourceName .. "] HTTP:", status, "| URL:", url)
            Rayfield:Notify({Title = "HTTP Error " .. tostring(status), Content = "Check F9 console for URL details.", Duration = 4})
            return
        end

        if type(res.Body) ~= "string" or not res.Body:find("MThd", 1, true) then
            warn("[" .. sourceName .. "] Not a MIDI file | URL:", url)
            Rayfield:Notify({
                Title = "Not a MIDI File",
                Content = "The link returned HTML/text instead of a .mid file. Use a direct raw download link.",
                Duration = 4,
            })
            return
        end

        if playbackId == myId then
            parseAndPlayMidi(res.Body, myId)
        end
    end)
end

-- ==========================================
-- Tab 1: Quick Picks (GitHub Repo Sync) & Direct URL
-- ==========================================
QuickTab:CreateSection("Quick Picks (q-29/piano Repo)")

local repoFileUrl = QUICKPICKS_REPO_URL
local quickPickMap = {}
local quickPickOrder = {}
local selectedQuickPick = nil

local function setQuickPickEntries(entries)
    table.clear(quickPickMap)
    table.clear(quickPickOrder)

    for _, item in ipairs(entries) do
        local label = tostring(item.name or "Untitled")
        if quickPickMap[label] then
            label = label .. " (" .. tostring(#quickPickOrder + 1) .. ")"
        end
        quickPickMap[label] = normalizeMidiUrl(item.url)
        table.insert(quickPickOrder, label)
    end

    if #quickPickOrder == 0 then
        table.insert(quickPickOrder, "No songs loaded")
        selectedQuickPick = nil
    else
        selectedQuickPick = quickPickOrder[1]
    end
end

local function parseQuickPickFile(body)
    local list = {}
    local trimmed = body:match("^%s*(.-)%s*$")

    if trimmed:sub(1, 1) == "[" or trimmed:sub(1, 1) == "{" then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, trimmed)
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
            return list
        end
    end

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

setQuickPickEntries(DEFAULT_QUICKPICKS)

local QuickPickDropdown = QuickTab:CreateDropdown({
    Name = "Select Quick Pick",
    Options = quickPickOrder,
    CurrentOption = {quickPickOrder[1]},
    MultipleOptions = false,
    Flag = "QuickPickSelect",
    Callback = function(Option)
        selectedQuickPick = type(Option) == "table" and Option[1] or Option
    end,
})

QuickTab:CreateButton({
    Name = "▶️ Play Quick Pick",
    Callback = function()
        local url = selectedQuickPick and quickPickMap[selectedQuickPick]
        if not url then
            Rayfield:Notify({Title = "No Song Selected", Content = "Pick a song from the dropdown first.", Duration = 3})
            return
        end
        downloadAndPlayUrl(url, "QuickPick")
    end,
})

local function fetchFromRepoUrl(urlToFetch, silent)
    local cleanUrl = normalizeMidiUrl(urlToFetch)
    if cleanUrl == "" then
        setQuickPickEntries(DEFAULT_QUICKPICKS)
        QuickPickDropdown:Refresh(quickPickOrder)
        if not silent then
            Rayfield:Notify({
                Title = "Built-in Quick Picks",
                Content = string.format("Loaded %d built-in songs.", #quickPickOrder),
                Duration = 3,
            })
        end
        return
    end

    task.spawn(function()
        local sep = cleanUrl:find("?", 1, true) and "&" or "?"
        local fetchUrl = cleanUrl .. sep .. "t=" .. tostring(os.time())

        local ok, res, err = safeRequest(fetchUrl)
        if not ok then
            warn("[Repo Fetch] Error:", err)
            if not silent then
                Rayfield:Notify({Title = "Repo Fetch Failed", Content = tostring(err), Duration = 4})
            end
            return
        end

        local status = res.StatusCode or res.status_code
        if status ~= 200 or type(res.Body) ~= "string" then
            warn("[Repo Fetch] HTTP:", status)
            if not silent then
                Rayfield:Notify({Title = "Repo Fetch Failed", Content = "HTTP " .. tostring(status), Duration = 4})
            end
            return
        end

        local parsed = parseQuickPickFile(res.Body)
        if #parsed == 0 then
            if not silent then
                Rayfield:Notify({
                    Title = "Empty / Invalid File",
                    Content = "Expected JSON ([{\"name\":...,\"url\":...}]) or 'Name | URL' lines.",
                    Duration = 4,
                })
            end
            return
        end

        setQuickPickEntries(parsed)
        QuickPickDropdown:Refresh(quickPickOrder)
        if not silent then
            Rayfield:Notify({
                Title = "Repo Songs Loaded",
                Content = string.format("Loaded %d songs from your GitHub file!", #quickPickOrder),
                Duration = 3,
            })
        end
    end)
end

if QUICKPICKS_REPO_URL ~= "" then
    fetchFromRepoUrl(QUICKPICKS_REPO_URL, true)
end

QuickTab:CreateInput({
    Name = "GitHub Repo File URL (songs.json / songs.txt)",
    CurrentValue = QUICKPICKS_REPO_URL,
    PlaceholderText = "https://raw.githubusercontent.com/q-29/piano/refs/heads/main/songs.json",
    RemoveTextAfterFocusLost = false,
    Flag = "RepoFileUrl",
    Callback = function(Text)
        repoFileUrl = Text
    end,
})

QuickTab:CreateButton({
    Name = "🔄 Fetch Songs from Repo",
    Callback = function()
        fetchFromRepoUrl(repoFileUrl, false)
    end,
})

local verifyingLinks = false
QuickTab:CreateButton({
    Name = "🔍 Verify All Links (Check in F9)",
    Callback = function()
        if verifyingLinks then return end
        verifyingLinks = true

        task.spawn(function()
            local total = #quickPickOrder
            local passed = 0
            local failedCount = 0
            local index = 0
            local done = 0

            Rayfield:Notify({
                Title = "Verifying Links...",
                Content = string.format("Testing %d links. Press F9 to view any failures.", total),
                Duration = 3,
            })

            for _ = 1, 6 do
                task.spawn(function()
                    while true do
                        index = index + 1
                        local i = index
                        if i > total then break end

                        local label = quickPickOrder[i]
                        local url = quickPickMap[label]
                        if url then
                            local ok, res, err = safeRequest(url)
                            local status = ok and res and (res.StatusCode or res.status_code) or nil
                            local isMidi = ok and res and status == 200 and type(res.Body) == "string" and res.Body:find("MThd", 1, true) ~= nil

                            if isMidi then
                                passed = passed + 1
                            else
                                failedCount = failedCount + 1
                                local reason = not ok and tostring(err) or ("HTTP " .. tostring(status) .. " / not MIDI")
                                warn(string.format("[Verify FAIL] %s | %s | %s", label, reason, url))
                            end
                        end
                        done = done + 1
                    end
                end)
            end

            while done < total do
                task.wait(0.1)
            end

            verifyingLinks = false
            print(string.format("[QuickPicks Verify] Passed: %d / %d | Failed: %d", passed, total, failedCount))
            Rayfield:Notify({
                Title = "Link Verification Done",
                Content = string.format("%d/%d working, %d failed (see F9).", passed, total, failedCount),
                Duration = 5,
            })
        end)
    end,
})

QuickTab:CreateSection("Direct .mid URL")

local customMidiUrl = ""

QuickTab:CreateInput({
    Name = "Direct .mid URL",
    CurrentValue = "",
    PlaceholderText = "https://raw.githubusercontent.com/.../song.mid",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomMidiUrl",
    Callback = function(Text)
        customMidiUrl = Text
    end,
})

QuickTab:CreateButton({
    Name = "▶️ Download & Play URL",
    Callback = function()
        downloadAndPlayUrl(customMidiUrl, "Direct URL")
    end,
})

QuickTab:CreateSection("Playback Controls")

QuickTab:CreateSlider({
    Name = "Playback Speed",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "QuickPlaybackSpeed",
    Callback = function(Value)
        currentPlaybackSpeed = Value
    end,
})

QuickTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})

-- ==========================================
-- Tab 2: Local .mid Files & Text Sheets
-- ==========================================
LocalTab:CreateSection("Local .mid Files (Workspace)")

local localFiles = {}
local selectedLocalFile = nil

local function scanLocalMidiFiles()
    table.clear(localFiles)
    if not listfiles or not readfile then
        return {"Executor lacks listfiles/readfile"}
    end

    local results = {}
    local seen = {}

    local function tryScan(folder)
        local ok, files = pcall(listfiles, folder)
        if not ok or type(files) ~= "table" then return end
        for _, path in ipairs(files) do
            if type(path) == "string" and path:lower():match("%.midi?$") then
                local name = path:match("([^/\\]+)$") or path
                if not seen[path] then
                    seen[path] = true
                    localFiles[name] = path
                    table.insert(results, name)
                end
            end
        end
    end

    if isfolder and pcall(isfolder, "midis") and isfolder("midis") then
        tryScan("midis")
    end
    tryScan("")

    if #results == 0 then
        return {"No .mid files in workspace"}
    end
    return results
end

local LocalDropdown = LocalTab:CreateDropdown({
    Name = "Select Local .mid",
    Options = scanLocalMidiFiles(),
    CurrentOption = {"Select a file"},
    MultipleOptions = false,
    Flag = "LocalMidiSelect",
    Callback = function(Option)
        selectedLocalFile = type(Option) == "table" and Option[1] or Option
    end,
})

LocalTab:CreateButton({
    Name = "🔄 Refresh Local .mid Files",
    Callback = function()
        LocalDropdown:Refresh(scanLocalMidiFiles())
    end,
})

LocalTab:CreateButton({
    Name = "▶️ Play Local MIDI",
    Callback = function()
        if loading or playing then return end
        local path = selectedLocalFile and localFiles[selectedLocalFile]
        if not path or not readfile then return end

        local ok, content = pcall(readfile, path)
        if not ok or type(content) ~= "string" then
            warn("[Local MIDI] Failed to read file:", tostring(content))
            return
        end

        playbackId = playbackId + 1
        local myId = playbackId
        task.spawn(parseAndPlayMidi, content, myId)
    end,
})

LocalTab:CreateSection("Text Sheets")

local pastedSheet = ""
local sheetBpm = 120

LocalTab:CreateInput({
    Name = "Paste Text Sheet",
    CurrentValue = "",
    PlaceholderText = "e.g. [tu] y [ro] | a [sd]",
    RemoveTextAfterFocusLost = false,
    Flag = "SheetInput",
    Callback = function(Text)
        pastedSheet = Text
    end,
})

LocalTab:CreateSlider({
    Name = "Text Sheet BPM",
    Range = {40, 300},
    Increment = 5,
    Suffix = " BPM",
    CurrentValue = 120,
    Flag = "SheetBPM",
    Callback = function(Value)
        sheetBpm = Value
    end,
})

LocalTab:CreateButton({
    Name = "▶️ Play Pasted Sheet",
    Callback = function()
        if loading or playing or pastedSheet == "" then return end
        playbackId = playbackId + 1
        local myId = playbackId
        task.spawn(playTextSheet, pastedSheet, sheetBpm, myId)
    end,
})

LocalTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})

-- ==========================================
-- Tab 3: NanoMIDI API
-- ==========================================
local nanoHeaders = {
    ["Accept"] = "application/json, */*",
    ["Origin"] = "https://nanomidi.net",
    ["Referer"] = "https://nanomidi.net/",
}

local apiData = {}
local songNames = {}

local function formatArtists(artists)
    if type(artists) == "table" then
        return table.concat(artists, ", ")
    elseif artists ~= nil then
        return tostring(artists)
    end
    return "Unknown"
end

local function encodeUrlPath(str)
    return (str:gsub("([^%w%-%._~/])", function(c)
        return string.format("%%%02X", c:byte())
    end))
end

local function loadMidiData()
    table.clear(apiData)
    table.clear(songNames)

    local ok, res, err = safeRequest("https://api.nanomidi.net/api/midiData", nanoHeaders)
    if not ok then
        warn("[NanoMIDI] Request error:", err)
        return {"Request Error: " .. tostring(err)}
    end

    local status = res.StatusCode or res.status_code
    if status ~= 200 then
        return {"Failed to load API (HTTP " .. tostring(status) .. ")"}
    end

    local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not decodeOk or type(data) ~= "table" then
        return {"Invalid API JSON response"}
    end

    for _, song in ipairs(data) do
        local label = tostring(song.name or "Untitled") .. " - " .. formatArtists(song.artists)
        if apiData[label] then
            label = label .. " (" .. tostring(song.midiFilename or #songNames + 1) .. ")"
        end
        table.insert(songNames, label)
        apiData[label] = song
    end

    if #songNames == 0 then
        return {"No songs found"}
    end
    return songNames
end

local selectedSong = nil
local NanoDropdown = NanoTab:CreateDropdown({
    Name = "Select Song",
    Options = {"Fetching..."},
    CurrentOption = {"Fetching..."},
    MultipleOptions = false,
    Flag = "NanoSongSelect",
    Callback = function(Option)
        selectedSong = type(Option) == "table" and Option[1] or Option
    end,
})

local function refreshSongs()
    task.spawn(function()
        local names = loadMidiData()
        NanoDropdown:Refresh(names)
    end)
end

refreshSongs()

NanoTab:CreateButton({
    Name = "🔄 Refresh Song List",
    Callback = refreshSongs,
})

NanoTab:CreateButton({
    Name = "▶️ Download & Play",
    Callback = function()
        if loading or playing then return end
        local song = selectedSong and apiData[selectedSong]
        if not song or not song.midiFilename then return end

        loading = true
        playbackId = playbackId + 1
        local myId = playbackId

        task.spawn(function()
            local url = "https://api.nanomidi.net/api/midis/" .. encodeUrlPath(tostring(song.midiFilename))
            local ok, res, err = safeRequest(url, nanoHeaders)
            loading = false

            if not ok then
                warn("[NanoMIDI] Download error:", err)
                return
            end

            local status = res.StatusCode or res.status_code
            if status == 200 and playbackId == myId then
                parseAndPlayMidi(res.Body, myId)
            else
                warn("[NanoMIDI] Download failed HTTP:", status)
            end
        end)
    end,
})

NanoTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})
