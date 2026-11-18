local QUICKPICKS_REPO_URL = "https://raw.githubusercontent.com/q-29/piano/refs/heads/main/songs.json"

local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ==========================================
-- Built-in Fallback Quick Picks (Validated)
-- ==========================================
local DEFAULT_QUICKPICKS = {
    {name = "Tokyo Ghoul - Unravel (Full)", url = "https://raw.githubusercontent.com/callmeyyzx/midi/main/%E3%80%90%E4%B8%9C%E4%BA%AC%E5%96%B0%E7%A7%8D%E4%B8%9C%E4%BA%AC%E9%A3%9F%E5%B0%B8%E9%AC%BC%E3%80%91OP-------Unravel.mid"},
    {name = "Tokyo Ghoul - Unravel (Simple)", url = "https://raw.githubusercontent.com/MAraragi/MusicalScoreRecognition/master/new_midi_file/unravel_after.mid"},
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
    {name = "FNAF 1 Song - The Living Tombstone", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Five%20Nights%20At%20Freddy%27s%20-%20Living%20Tombstone.mid"},
    {name = "Geometry Dash - Back on Track", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Back%20on%20Track%20Geometry%20dash.mid"},
    {name = "Bad Piggies Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Bad%20Piggies%20-%20Main%20Theme%20by%20Funkfan.mid"},
    {name = "Zelda OoT - Song of Storms", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/The%20Legend%20of%20Zelda%20Ocarina%20of%20Time%20-%20Song%20of%20Storms.mid"},
    {name = "Super Mario Bros Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Mario%20Bros.%20-%20Super%20Mario%20Bros.%20Theme.mid"},
    {name = "Super Mario 64 - Inside the Castle Walls", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Inside%20the%20Castle%20Walls%20-%20Super%20Mario%2064.mid"},
    {name = "Tetris - A Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Tetris%20-%20A%20Theme.mid"},
    {name = "Pokemon Center Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Pokemon%20-%20Pokemon%20Center%20Theme.mid"},
    {name = "Wii - Mii Channel Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Mii%20Channel%20Theme%20%28Pixel-Phil%29.mid"},
    {name = "Harry Potter - Hedwig's Theme", url = "https://raw.githubusercontent.com/reality3d/3d-piano-player/master/midi/hedwigs_theme.mid"},
    {name = "Pirates of the Caribbean - He's a Pirate", url = "https://raw.githubusercontent.com/reality3d/3d-piano-player/master/midi/hes_a_pirate.mid"},
    {name = "Interstellar - Main Theme (Hans Zimmer)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Interstellar%20Main%20Theme-%20Hans%20Zimmer.mid"},
    {name = "Inception - Time (Hans Zimmer)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Hans%20Zimmer%20-%20Time.mid"},
    {name = "How to Train Your Dragon - Test Drive", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/How%20to%20train%20your%20dragon%20-%20Test%20Drive.mid"},
    {name = "Star Wars - Duel of the Fates", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Duel%20of%20the%20Fates%20by%20John%20Williams.mid"},
    {name = "Adele - Skyfall", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Adele%20-%20Skyfall.mid"},
    {name = "Queen - Bohemian Rhapsody", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Bohemian-Rhapsody-1.mid"},
    {name = "Coldplay - Viva La Vida", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Coldplay%20-%20Viva%20La%20Vida.mid"},
    {name = "Coldplay - Clocks", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Coldplay%20-%20Clocks%20%28Full%20Song%29.mid"},
    {name = "Billy Joel - Piano Man", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Billy%20Joel%20-%20Piano%20Man.mid"},
    {name = "a-ha - Take On Me", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/A%20HA.Take%20on%20me%20K.mid"},
    {name = "ABBA - Dancing Queen", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/ABBA%20-%20Dancing%20Queen.mid"},
    {name = "Smash Mouth - All Star", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/All%20Star.mid"},
    {name = "George Michael - Careless Whisper", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Careless-Whisper.mid"},
    {name = "Astronomia (Coffin Dance)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/main/Coffin%20dance%20-%20Theme%20and%20variations.mid"},
    {name = "Alan Walker - The Spectre", url = "https://raw.githubusercontent.com/callmeyyzx/midi/main/The_Spectre__Alan_Walker.mid"},
    {name = "Avicii - Wake Me Up", url = "https://raw.githubusercontent.com/callmeyyzx/midi/main/wakemeup.mid"},
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
        return false
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
        return false
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
    return true
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
local GlobalTab = Window:CreateTab("🔍 Global Search", 4483362458)

-- ==========================================
-- HTTP, Search & Auto-Load Helpers
-- ==========================================
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local MAX_DROPDOWN_ITEMS = 200

local function normalizeMidiUrl(url)
    local clean = tostring(url or ""):match("^%s*(.-)%s*$")
    clean = clean:gsub("^https?://github%.com/([^/]+)/([^/]+)/blob/(.+)$", "https://raw.githubusercontent.com/%1/%2/%3")
    clean = clean:gsub("^https?://github%.com/([^/]+)/([^/]+)/raw/(.+)$", "https://raw.githubusercontent.com/%1/%2/%3")
    clean = clean:gsub(" ", "%%20")
    return clean
end

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

local function requestWithRetry(url, customHeaders, maxAttempts, retryDelay, shouldAbort)
    maxAttempts = maxAttempts or 3
    retryDelay = retryDelay or 1.0
    local lastErr = "Unknown error"
    local lastStatus = nil

    for attempt = 1, maxAttempts do
        if shouldAbort and shouldAbort() then
            return false, nil, "Aborted", nil
        end

        local ok, res, err = safeRequest(url, customHeaders)
        if ok and res then
            local status = res.StatusCode or res.status_code
            lastStatus = status
            if status == 200 and type(res.Body) == "string" then
                return true, res, nil, status
            end
            lastErr = "HTTP " .. tostring(status)
        else
            lastErr = tostring(err)
        end

        if attempt < maxAttempts then
            task.wait(retryDelay * attempt)
        end
    end

    return false, nil, lastErr, lastStatus
end

local function fetchMidiBytesWithRetry(url, customHeaders, shouldAbort)
    local ok, res, err, status = requestWithRetry(url, customHeaders, 3, 0.75, shouldAbort)
    if not ok then
        return false, nil, err, status
    end
    if type(res.Body) ~= "string" or not res.Body:find("MThd", 1, true) then
        return false, nil, "Response is not a MIDI file (missing MThd)", status
    end
    return true, res.Body, nil, status
end

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

local function setDropdownOptions(dropdown, options, fallbackText, setSuppress)
    local display = options
    local hasItems = #options > 0
    if not hasItems then
        display = {fallbackText or "No matching songs"}
    end

    if setSuppress then setSuppress(true) end
    pcall(function()
        dropdown:Refresh(display)
        dropdown:Set({display[1]})
    end)
    if setSuppress then setSuppress(false) end

    return hasItems and display[1] or nil
end

local function setLabelSafe(labelObj, text)
    if labelObj and labelObj.Set then
        pcall(function()
            labelObj:Set(text)
        end)
    end
end

local function encodeUrlPath(str)
    return (str:gsub("([^%w%-%._~/])", function(c)
        return string.format("%%%02X", c:byte())
    end))
end

local function formatArtists(artists)
    if type(artists) == "table" then
        return table.concat(artists, ", ")
    elseif artists ~= nil then
        return tostring(artists)
    end
    return "Unknown"
end

local function downloadAndPlayUrl(rawUrl, sourceName, silent)
    local url = normalizeMidiUrl(rawUrl)
    if not url or not url:match("^https?://") then
        if not silent then
            Rayfield:Notify({
                Title = "Invalid URL",
                Content = "Please enter or select a valid http:// or https:// .mid URL.",
                Duration = 3,
            })
        end
        return
    end

    stopPlayback()
    loading = true
    local myId = playbackId

    task.spawn(function()
        local ok, midiBody, err = fetchMidiBytesWithRetry(url, nil, function()
            return playbackId ~= myId
        end)

        if playbackId ~= myId then return end
        loading = false

        if not ok then
            warn("[" .. sourceName .. "] Load failed:", err, "| URL:", url)
            if not silent then
                Rayfield:Notify({
                    Title = "Song Load Failed",
                    Content = tostring(err),
                    Duration = 4,
                })
            end
            return
        end

        parseAndPlayMidi(midiBody, myId)
    end)
end

-- Shared State Tables
local QuickState = {
    map = {},
    order = {},
    filtered = {},
    query = "",
    selected = nil,
    repoUrl = QUICKPICKS_REPO_URL,
    sourceLabel = "Built-in",
    autoPlayOnSelect = false,
    suppressCallback = false,
    verifying = false,
    fetchGeneration = 0,
}

local LocalState = {
    files = {},
    order = {},
    query = "",
    selected = nil,
    autoPlayOnSelect = false,
    suppressCallback = false,
}

local NanoState = {
    headers = {
        ["Accept"] = "application/json, */*",
        ["Origin"] = "https://nanomidi.net",
        ["Referer"] = "https://nanomidi.net/",
    },
    apiData = {},
    order = {},
    query = "",
    selected = nil,
    loaded = false,
    loadingList = false,
    autoPlayOnSelect = false,
    suppressCallback = false,
}

local GlobalState = {
    resultsMap = {},
    resultsOrder = {},
    query = "",
    selected = nil,
    suppressCallback = false,
}

local refreshGlobalSearchResults -- forward declaration

-- ==========================================
-- Tab 1: Quick Picks (Auto-Sync + Search) & Direct URL
-- ==========================================
QuickTab:CreateSection("Quick Picks (Search & Auto-Sync)")

local QuickStatusLabel = QuickTab:CreateLabel("Quick Picks: Loading...")
local QuickPickDropdown -- forward declared

local function applyQuickPickFilter()
    local matches, totalMatches = filterSongList(QuickState.order, QuickState.query, MAX_DROPDOWN_ITEMS)
    QuickState.filtered = matches
    QuickState.selected = setDropdownOptions(
        QuickPickDropdown,
        matches,
        QuickState.query ~= "" and "No matching Quick Picks" or "No songs loaded",
        function(v) QuickState.suppressCallback = v end
    )

    if QuickState.query ~= "" then
        setLabelSafe(QuickStatusLabel, string.format("Quick Picks (%s): %d matches (%d total)", QuickState.sourceLabel, totalMatches, #QuickState.order))
    else
        setLabelSafe(QuickStatusLabel, string.format("Quick Picks (%s): %d songs ready", QuickState.sourceLabel, #QuickState.order))
    end
end

local function setQuickPickEntries(entries, sourceLabel)
    table.clear(QuickState.map)
    table.clear(QuickState.order)
    QuickState.sourceLabel = sourceLabel or "Built-in"

    for _, item in ipairs(entries) do
        local label = tostring(item.name or "Untitled")
        if QuickState.map[label] then
            label = label .. " (" .. tostring(#QuickState.order + 1) .. ")"
        end
        QuickState.map[label] = normalizeMidiUrl(item.url)
        table.insert(QuickState.order, label)
    end

    applyQuickPickFilter()
    if refreshGlobalSearchResults then
        refreshGlobalSearchResults()
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

local function playQuickPickSelection(label)
    local url = label and QuickState.map[label]
    if not url then
        Rayfield:Notify({Title = "No Song Selected", Content = "Pick a song from the dropdown first.", Duration = 3})
        return
    end
    downloadAndPlayUrl(url, "QuickPick", false)
end

local QuickSearchInput = QuickTab:CreateInput({
    Name = "🔍 Search Quick Picks",
    CurrentValue = "",
    PlaceholderText = "Type song/artist & press Enter (blank = all)",
    RemoveTextAfterFocusLost = false,
    Flag = "QuickSearchInput",
    Callback = function(Text)
        QuickState.query = tostring(Text or "")
        applyQuickPickFilter()
    end,
})

QuickPickDropdown = QuickTab:CreateDropdown({
    Name = "Select Quick Pick",
    Options = {"Loading..."},
    CurrentOption = {"Loading..."},
    MultipleOptions = false,
    Flag = "QuickPickSelect",
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        QuickState.selected = QuickState.map[chosen] and chosen or nil
        if not QuickState.suppressCallback and QuickState.autoPlayOnSelect and QuickState.selected then
            playQuickPickSelection(QuickState.selected)
        end
    end,
})

setQuickPickEntries(DEFAULT_QUICKPICKS, "Built-in")

QuickTab:CreateToggle({
    Name = "⚡ Auto-Play Song on Select",
    CurrentValue = false,
    Flag = "QuickAutoPlayToggle",
    Callback = function(Value)
        QuickState.autoPlayOnSelect = Value
    end,
})

QuickTab:CreateButton({
    Name = "▶️ Play Quick Pick",
    Callback = function()
        playQuickPickSelection(QuickState.selected)
    end,
})

QuickTab:CreateButton({
    Name = "⚡ Auto-Try Matching Quick Picks",
    Callback = function()
        local candidates = {}
        for _, label in ipairs(QuickState.order) do
            if matchesQuery(label, QuickState.query) and QuickState.map[label] then
                table.insert(candidates, {label = label, url = QuickState.map[label]})
            end
        end
        if #candidates == 0 then
            Rayfield:Notify({Title = "No Matches", Content = "No Quick Picks matched your search.", Duration = 3})
            return
        end

        stopPlayback()
        loading = true
        local myId = playbackId

        task.spawn(function()
            for idx, entry in ipairs(candidates) do
                if playbackId ~= myId then return end
                setLabelSafe(QuickStatusLabel, string.format("Auto-trying (%d/%d): %s", idx, #candidates, entry.label))
                local ok, midiBody = fetchMidiBytesWithRetry(entry.url, nil, function()
                    return playbackId ~= myId
                end)
                if playbackId ~= myId then return end
                if ok and midiBody then
                    loading = false
                    setLabelSafe(QuickStatusLabel, "Playing: " .. entry.label)
                    Rayfield:Notify({Title = "Loaded & Playing", Content = entry.label, Duration = 3})
                    parseAndPlayMidi(midiBody, myId)
                    return
                end
            end

            if playbackId == myId then
                loading = false
                applyQuickPickFilter()
                Rayfield:Notify({Title = "Auto-Try Failed", Content = "None of the matching Quick Picks returned valid MIDI data.", Duration = 4})
            end
        end)
    end,
})

QuickTab:CreateButton({
    Name = "🔄 Clear Search",
    Callback = function()
        QuickState.query = ""
        pcall(function() QuickSearchInput:Set("") end)
        applyQuickPickFilter()
    end,
})

QuickTab:CreateSection("GitHub Repo Sync (Auto-Retry)")

local function fetchFromRepoUrl(urlToFetch, silent)
    local candidates = buildRepoUrlCandidates(urlToFetch)
    if #candidates == 0 then
        setQuickPickEntries(DEFAULT_QUICKPICKS, "Built-in")
        if not silent then
            Rayfield:Notify({
                Title = "Built-in Quick Picks",
                Content = string.format("Loaded %d built-in songs.", #QuickState.order),
                Duration = 3,
            })
        end
        return
    end

    QuickState.fetchGeneration = QuickState.fetchGeneration + 1
    local myGen = QuickState.fetchGeneration
    setLabelSafe(QuickStatusLabel, "Quick Picks: Auto-loading repo...")

    task.spawn(function()
        local lastErr = "Failed to fetch repo"
        for round = 1, 3 do
            if QuickState.fetchGeneration ~= myGen then return end

            for _, candidate in ipairs(candidates) do
                if QuickState.fetchGeneration ~= myGen then return end
                local sep = candidate:find("?", 1, true) and "&" or "?"
                local fetchUrl = candidate .. sep .. "t=" .. tostring(os.time())

                local ok, res, err = safeRequest(fetchUrl)
                if ok and res then
                    local status = res.StatusCode or res.status_code
                    if status == 200 and type(res.Body) == "string" then
                        local parsed = parseQuickPickFile(res.Body)
                        if #parsed > 0 then
                            if QuickState.fetchGeneration ~= myGen then return end
                            setQuickPickEntries(parsed, "GitHub Repo")
                            Rayfield:Notify({
                                Title = "Repo Songs Auto-Loaded",
                                Content = string.format("Loaded %d songs from GitHub!", #QuickState.order),
                                Duration = 3,
                            })
                            return
                        else
                            lastErr = "Empty or invalid song JSON/list"
                        end
                    else
                        lastErr = "HTTP " .. tostring(status)
                    end
                else
                    lastErr = tostring(err)
                end
            end

            if round < 3 then
                setLabelSafe(QuickStatusLabel, string.format("Quick Picks: Retrying repo (%d/3)...", round + 1))
                task.wait(1.5 * round)
            end
        end

        if QuickState.fetchGeneration ~= myGen then return end
        warn("[Repo Auto-Load] Failed after retries:", lastErr)
        applyQuickPickFilter()
        if not silent then
            Rayfield:Notify({
                Title = "Repo Load Failed (Using Fallback)",
                Content = tostring(lastErr),
                Duration = 4,
            })
        end
    end)
end

if QUICKPICKS_REPO_URL ~= "" then
    fetchFromRepoUrl(QUICKPICKS_REPO_URL, true)
end

QuickTab:CreateInput({
    Name = "GitHub Repo File URL (Auto-Loads)",
    CurrentValue = QUICKPICKS_REPO_URL,
    PlaceholderText = "https://raw.githubusercontent.com/q-29/piano/refs/heads/main/songs.json",
    RemoveTextAfterFocusLost = false,
    Flag = "RepoFileUrl",
    Callback = function(Text)
        local cleaned = tostring(Text or ""):match("^%s*(.-)%s*$")
        if cleaned ~= QuickState.repoUrl then
            QuickState.repoUrl = cleaned
            fetchFromRepoUrl(cleaned, false)
        end
    end,
})

QuickTab:CreateButton({
    Name = "🔄 Fetch Songs from Repo",
    Callback = function()
        fetchFromRepoUrl(QuickState.repoUrl, false)
    end,
})

QuickTab:CreateButton({
    Name = "🔍 Verify All Links (Check in F9)",
    Callback = function()
        if QuickState.verifying then return end
        QuickState.verifying = true

        task.spawn(function()
            local total = #QuickState.order
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

                        local label = QuickState.order[i]
                        local url = QuickState.map[label]
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

            QuickState.verifying = false
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
        downloadAndPlayUrl(customMidiUrl, "Direct URL", false)
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

local LocalStatusLabel = LocalTab:CreateLabel("Local MIDI: Scanning...")
local LocalDropdown -- forward declared

local function scanLocalMidiFiles()
    table.clear(LocalState.files)
    table.clear(LocalState.order)

    if not listfiles or not readfile then
        setLabelSafe(LocalStatusLabel, "Local MIDI: Executor lacks listfiles/readfile")
        return
    end

    local seen = {}
    local function tryScan(folder)
        local ok, files = pcall(listfiles, folder)
        if not ok or type(files) ~= "table" then return end
        for _, path in ipairs(files) do
            if type(path) == "string" and path:lower():match("%.midi?$") then
                local name = path:match("([^/\\]+)$") or path
                if not seen[path] then
                    seen[path] = true
                    local label = name
                    if LocalState.files[label] then
                        label = label .. " (" .. tostring(#LocalState.order + 1) .. ")"
                    end
                    LocalState.files[label] = path
                    table.insert(LocalState.order, label)
                end
            end
        end
    end

    if isfolder and pcall(isfolder, "midis") and isfolder("midis") then
        tryScan("midis")
    end
    tryScan("")

    table.sort(LocalState.order)
end

local function applyLocalFilter()
    local matches, totalMatches = filterSongList(LocalState.order, LocalState.query, MAX_DROPDOWN_ITEMS)
    local fallback = #LocalState.order == 0 and "No .mid files in workspace" or "No matching local files"
    LocalState.selected = setDropdownOptions(
        LocalDropdown,
        matches,
        fallback,
        function(v) LocalState.suppressCallback = v end
    )

    if LocalState.query ~= "" then
        setLabelSafe(LocalStatusLabel, string.format("Local MIDI: %d matches (%d total)", totalMatches, #LocalState.order))
    else
        setLabelSafe(LocalStatusLabel, string.format("Local MIDI: %d files found", #LocalState.order))
    end
end

local function playLocalSelection(label)
    local path = label and LocalState.files[label]
    if not path or not readfile then
        Rayfield:Notify({Title = "No Local File", Content = "Select a valid .mid file first.", Duration = 3})
        return
    end

    local ok, content = pcall(readfile, path)
    if not ok or type(content) ~= "string" then
        warn("[Local MIDI] Failed to read file:", tostring(content))
        Rayfield:Notify({Title = "Read Failed", Content = tostring(content), Duration = 3})
        return
    end

    stopPlayback()
    local myId = playbackId
    task.spawn(parseAndPlayMidi, content, myId)
end

LocalTab:CreateInput({
    Name = "🔍 Search Local .mid Files",
    CurrentValue = "",
    PlaceholderText = "Type filename & press Enter (blank = all)",
    RemoveTextAfterFocusLost = false,
    Flag = "LocalSearchInput",
    Callback = function(Text)
        LocalState.query = tostring(Text or "")
        applyLocalFilter()
    end,
})

LocalDropdown = LocalTab:CreateDropdown({
    Name = "Select Local .mid",
    Options = {"Scanning..."},
    CurrentOption = {"Scanning..."},
    MultipleOptions = false,
    Flag = "LocalMidiSelect",
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        LocalState.selected = LocalState.files[chosen] and chosen or nil
        if not LocalState.suppressCallback and LocalState.autoPlayOnSelect and LocalState.selected then
            playLocalSelection(LocalState.selected)
        end
    end,
})

scanLocalMidiFiles()
applyLocalFilter()

LocalTab:CreateToggle({
    Name = "⚡ Auto-Play File on Select",
    CurrentValue = false,
    Flag = "LocalAutoPlayToggle",
    Callback = function(Value)
        LocalState.autoPlayOnSelect = Value
    end,
})

LocalTab:CreateButton({
    Name = "🔄 Refresh Local .mid Files",
    Callback = function()
        scanLocalMidiFiles()
        applyLocalFilter()
        if refreshGlobalSearchResults then
            refreshGlobalSearchResults()
        end
    end,
})

LocalTab:CreateButton({
    Name = "▶️ Play Local MIDI",
    Callback = function()
        playLocalSelection(LocalState.selected)
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
        if pastedSheet == "" then return end
        stopPlayback()
        local myId = playbackId
        task.spawn(playTextSheet, pastedSheet, sheetBpm, myId)
    end,
})

LocalTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})

-- ==========================================
-- Tab 3: NanoMIDI API (Search + Auto-Retry)
-- ==========================================
NanoTab:CreateSection("NanoMIDI Library")

local NanoStatusLabel = NanoTab:CreateLabel("NanoMIDI: Auto-loading...")
local NanoDropdown -- forward declared

local function applyNanoFilter()
    if not NanoState.loaded and #NanoState.order == 0 then
        return
    end
    local matches, totalMatches = filterSongList(NanoState.order, NanoState.query, MAX_DROPDOWN_ITEMS)
    NanoState.selected = setDropdownOptions(
        NanoDropdown,
        matches,
        NanoState.query ~= "" and "No matching NanoMIDI songs" or "No songs found",
        function(v) NanoState.suppressCallback = v end
    )

    if NanoState.query ~= "" then
        local shownText = totalMatches > #matches and string.format("showing %d of %d matches", #matches, totalMatches) or string.format("%d matches", totalMatches)
        setLabelSafe(NanoStatusLabel, string.format("NanoMIDI: %s (%d total)", shownText, #NanoState.order))
    else
        local shownText = #NanoState.order > #matches and string.format("showing top %d of %d (use search)", #matches, #NanoState.order) or string.format("%d songs ready", #NanoState.order)
        setLabelSafe(NanoStatusLabel, "NanoMIDI: " .. shownText)
    end
end

local function playNanoSelection(label, silent)
    local song = label and NanoState.apiData[label]
    if not song or not song.midiFilename then
        if not silent then
            Rayfield:Notify({Title = "No Song Selected", Content = "Select a NanoMIDI song first.", Duration = 3})
        end
        return
    end

    stopPlayback()
    loading = true
    local myId = playbackId

    task.spawn(function()
        local url = "https://api.nanomidi.net/api/midis/" .. encodeUrlPath(tostring(song.midiFilename))
        local ok, midiBody, err = fetchMidiBytesWithRetry(url, NanoState.headers, function()
            return playbackId ~= myId
        end)

        if playbackId ~= myId then return end
        loading = false

        if ok and midiBody then
            parseAndPlayMidi(midiBody, myId)
        else
            warn("[NanoMIDI] Download failed:", err)
            if not silent then
                Rayfield:Notify({Title = "NanoMIDI Load Failed", Content = tostring(err), Duration = 4})
            end
        end
    end)
end

local function refreshNanoSongs(silent)
    if NanoState.loadingList then return end
    NanoState.loadingList = true
    setLabelSafe(NanoStatusLabel, "NanoMIDI: Auto-loading songs...")

    task.spawn(function()
        local ok, res, err = requestWithRetry("https://api.nanomidi.net/api/midiData", NanoState.headers, 3, 1.2)
        if not ok then
            NanoState.loadingList = false
            warn("[NanoMIDI] Auto-load failed:", err)
            setLabelSafe(NanoStatusLabel, "NanoMIDI: Load failed (click Refresh)")
            if #NanoState.order == 0 then
                setDropdownOptions(NanoDropdown, {}, "Failed to load NanoMIDI (" .. tostring(err) .. ")", function(v)
                    NanoState.suppressCallback = v
                end)
            end
            if not silent then
                Rayfield:Notify({Title = "NanoMIDI Load Failed", Content = tostring(err), Duration = 4})
            end
            return
        end

        local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
        if not decodeOk or type(data) ~= "table" then
            NanoState.loadingList = false
            setLabelSafe(NanoStatusLabel, "NanoMIDI: Invalid API JSON")
            return
        end

        table.clear(NanoState.apiData)
        table.clear(NanoState.order)

        for _, song in ipairs(data) do
            local label = tostring(song.name or "Untitled") .. " - " .. formatArtists(song.artists)
            if NanoState.apiData[label] then
                label = label .. " (" .. tostring(song.midiFilename or #NanoState.order + 1) .. ")"
            end
            table.insert(NanoState.order, label)
            NanoState.apiData[label] = song
        end

        NanoState.loaded = true
        NanoState.loadingList = false
        applyNanoFilter()
        if refreshGlobalSearchResults then
            refreshGlobalSearchResults()
        end
    end)
end

local NanoSearchInput = NanoTab:CreateInput({
    Name = "🔍 Search NanoMIDI",
    CurrentValue = "",
    PlaceholderText = "Search title/artist & press Enter",
    RemoveTextAfterFocusLost = false,
    Flag = "NanoSearchInput",
    Callback = function(Text)
        NanoState.query = tostring(Text or "")
        if not NanoState.loaded and not NanoState.loadingList then
            refreshNanoSongs(true)
        end
        applyNanoFilter()
    end,
})

NanoDropdown = NanoTab:CreateDropdown({
    Name = "Select Song",
    Options = {"Fetching..."},
    CurrentOption = {"Fetching..."},
    MultipleOptions = false,
    Flag = "NanoSongSelect",
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        NanoState.selected = NanoState.apiData[chosen] and chosen or nil
        if not NanoState.suppressCallback and NanoState.autoPlayOnSelect and NanoState.selected then
            playNanoSelection(NanoState.selected, false)
        end
    end,
})

refreshNanoSongs(true)

NanoTab:CreateToggle({
    Name = "⚡ Auto-Play Song on Select",
    CurrentValue = false,
    Flag = "NanoAutoPlayToggle",
    Callback = function(Value)
        NanoState.autoPlayOnSelect = Value
    end,
})

NanoTab:CreateButton({
    Name = "🔄 Refresh Song List",
    Callback = function()
        refreshNanoSongs(false)
    end,
})

NanoTab:CreateButton({
    Name = "🔄 Clear Search",
    Callback = function()
        NanoState.query = ""
        pcall(function() NanoSearchInput:Set("") end)
        applyNanoFilter()
    end,
})

NanoTab:CreateButton({
    Name = "▶️ Download & Play",
    Callback = function()
        playNanoSelection(NanoState.selected, false)
    end,
})

NanoTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})

-- ==========================================
-- Tab 4: Global Search & Auto-Try Across All Sources
-- ==========================================
GlobalTab:CreateSection("Search All Sources (Local + Quick Picks + NanoMIDI)")

local GlobalStatusLabel = GlobalTab:CreateLabel("Global Search: Enter a song name to search all sources")
local GlobalDropdown -- forward declared

local function buildGlobalMatches(query)
    local allEntries = {}
    local displayNames = {}
    local seenKeys = {}

    local function addEntry(sourceTag, label, entry)
        if not matchesQuery(label, query) then return end
        local display = "[" .. sourceTag .. "] " .. label
        if seenKeys[display] then
            display = display .. " #" .. tostring(#displayNames + 1)
        end
        seenKeys[display] = true
        entry.display = display
        allEntries[display] = entry
        table.insert(displayNames, display)
    end

    for _, label in ipairs(LocalState.order) do
        addEntry("Local", label, {kind = "local", label = label, path = LocalState.files[label]})
        if #displayNames >= MAX_DROPDOWN_ITEMS then break end
    end

    if #displayNames < MAX_DROPDOWN_ITEMS then
        for _, label in ipairs(QuickState.order) do
            addEntry("QuickPick", label, {kind = "url", label = label, url = QuickState.map[label]})
            if #displayNames >= MAX_DROPDOWN_ITEMS then break end
        end
    end

    if #displayNames < MAX_DROPDOWN_ITEMS then
        for _, label in ipairs(NanoState.order) do
            local song = NanoState.apiData[label]
            if song and song.midiFilename then
                addEntry("NanoMIDI", label, {
                    kind = "nano",
                    label = label,
                    url = "https://api.nanomidi.net/api/midis/" .. encodeUrlPath(tostring(song.midiFilename)),
                })
            end
            if #displayNames >= MAX_DROPDOWN_ITEMS then break end
        end
    end

    return allEntries, displayNames
end

refreshGlobalSearchResults = function()
    local map, names = buildGlobalMatches(GlobalState.query)
    GlobalState.resultsMap = map
    GlobalState.resultsOrder = names
    GlobalState.selected = setDropdownOptions(
        GlobalDropdown,
        names,
        GlobalState.query ~= "" and "No matches across sources" or "No songs loaded yet",
        function(v) GlobalState.suppressCallback = v end
    )

    if GlobalState.query ~= "" then
        setLabelSafe(GlobalStatusLabel, string.format("Global Search: %d matches found", #names))
    else
        setLabelSafe(GlobalStatusLabel, string.format("Global Search: Showing %d songs (Local %d | Quick %d | Nano %d)", #names, #LocalState.order, #QuickState.order, #NanoState.order))
    end
end

local function tryLoadGlobalEntry(entry, myId)
    if entry.kind == "local" then
        if not entry.path or not readfile then return false, nil end
        local ok, content = pcall(readfile, entry.path)
        if ok and type(content) == "string" and content:find("MThd", 1, true) then
            return true, content
        end
        return false, nil
    elseif entry.kind == "nano" then
        local ok, midiBody = fetchMidiBytesWithRetry(entry.url, NanoState.headers, function()
            return playbackId ~= myId
        end)
        return ok, midiBody
    else
        local ok, midiBody = fetchMidiBytesWithRetry(entry.url, nil, function()
            return playbackId ~= myId
        end)
        return ok, midiBody
    end
end

local GlobalSearchInput = GlobalTab:CreateInput({
    Name = "🔍 Search All Songs",
    CurrentValue = "",
    PlaceholderText = "e.g. unravel, megalovania, chopin (press Enter)",
    RemoveTextAfterFocusLost = false,
    Flag = "GlobalSearchInput",
    Callback = function(Text)
        GlobalState.query = tostring(Text or "")
        if not NanoState.loaded and not NanoState.loadingList then
            refreshNanoSongs(true)
        end
        refreshGlobalSearchResults()
    end,
})

GlobalDropdown = GlobalTab:CreateDropdown({
    Name = "Matching Songs",
    Options = {"Loading..."},
    CurrentOption = {"Loading..."},
    MultipleOptions = false,
    Flag = "GlobalSongSelect",
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        GlobalState.selected = GlobalState.resultsMap[chosen] and chosen or nil
    end,
})

refreshGlobalSearchResults()

GlobalTab:CreateButton({
    Name = "▶️ Play Selected Match",
    Callback = function()
        local entry = GlobalState.selected and GlobalState.resultsMap[GlobalState.selected]
        if not entry then
            Rayfield:Notify({Title = "No Song Selected", Content = "Search and select a song first.", Duration = 3})
            return
        end

        stopPlayback()
        loading = true
        local myId = playbackId

        task.spawn(function()
            setLabelSafe(GlobalStatusLabel, "Loading: " .. entry.display)
            local ok, midiBody = tryLoadGlobalEntry(entry, myId)
            if playbackId ~= myId then return end
            loading = false

            if ok and midiBody then
                setLabelSafe(GlobalStatusLabel, "Playing: " .. entry.display)
                parseAndPlayMidi(midiBody, myId)
            else
                setLabelSafe(GlobalStatusLabel, "Failed: " .. entry.display)
                Rayfield:Notify({Title = "Song Load Failed", Content = "Try 'Auto-Try Matching Songs' to test other sources.", Duration = 4})
            end
        end)
    end,
})

GlobalTab:CreateButton({
    Name = "⚡ Auto-Try Matching Songs (Find Working)",
    Callback = function()
        if #GlobalState.resultsOrder == 0 then
            Rayfield:Notify({Title = "No Matches", Content = "No songs matched your search.", Duration = 3})
            return
        end

        local queue = {}
        for _, display in ipairs(GlobalState.resultsOrder) do
            local entry = GlobalState.resultsMap[display]
            if entry then
                table.insert(queue, entry)
            end
        end

        stopPlayback()
        loading = true
        local myId = playbackId

        task.spawn(function()
            for idx, entry in ipairs(queue) do
                if playbackId ~= myId then return end
                setLabelSafe(GlobalStatusLabel, string.format("Auto-trying (%d/%d): %s", idx, #queue, entry.display))
                local ok, midiBody = tryLoadGlobalEntry(entry, myId)
                if playbackId ~= myId then return end

                if ok and midiBody then
                    loading = false
                    setLabelSafe(GlobalStatusLabel, "Playing: " .. entry.display)
                    Rayfield:Notify({Title = "Auto-Loaded & Playing", Content = entry.display, Duration = 3})
                    parseAndPlayMidi(midiBody, myId)
                    return
                end
            end

            if playbackId == myId then
                loading = false
                setLabelSafe(GlobalStatusLabel, "Auto-try finished: no working MIDI found")
                Rayfield:Notify({Title = "Auto-Try Failed", Content = "None of the matching entries returned valid MIDI.", Duration = 4})
            end
        end)
    end,
})

GlobalTab:CreateButton({
    Name = "🔄 Reload All Song Sources",
    Callback = function()
        scanLocalMidiFiles()
        applyLocalFilter()
        fetchFromRepoUrl(QuickState.repoUrl, false)
        refreshNanoSongs(false)
        refreshGlobalSearchResults()
    end,
})

GlobalTab:CreateButton({
    Name = "🔄 Clear Search",
    Callback = function()
        GlobalState.query = ""
        pcall(function() GlobalSearchInput:Set("") end)
        refreshGlobalSearchResults()
    end,
})

GlobalTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})
