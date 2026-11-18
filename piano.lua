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
local playbackId = 0
local stopHooks = {}

local function registerStopHook(fn)
    table.insert(stopHooks, fn)
end

local function releaseHeldKeys()
    for keyEnum, held in pairs(keyHeld) do
        if held then
            keyPressId[keyEnum] = (keyPressId[keyEnum] or 0) + 1
            keyHeld[keyEnum] = false
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
            end)
        end
    end
end

local function stopPlayback()
    playbackId = playbackId + 1
    playing = false
    releaseHeldKeys()
    for _, hook in ipairs(stopHooks) do
        pcall(hook)
    end
end

local function parseAndPlayMidi(midiString, myId, onStart)
    if playbackId ~= myId then return false end

    local mthdIdx = midiString:find("MThd", 1, true)
    if not mthdIdx then
        warn("[Piano] Missing MThd header")
        if playbackId == myId then playing = false end
        return false
    end
    if mthdIdx > 1 then
        midiString = midiString:sub(mthdIdx)
    end

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
            local channel, key, velocity = ...
            -- Channel 10 (1-indexed) is General MIDI percussion; skip drum hits on piano
            if channel ~= 10 and velocity > 0 then
                order = order + 1
                table.insert(events, {time = currentTime, order = order, type = "note", key = key})
            end
        elseif name == "setTempo" then
            local rawTempo = ...
            if type(rawTempo) == "number" and rawTempo > 0 then
                order = order + 1
                table.insert(events, {time = currentTime, order = order, type = "tempo", tempo = rawTempo})
            end
        end
    end)

    if not ok then
        warn("[Piano] MIDI parse error:", err)
        if playbackId == myId then playing = false end
        return false
    end

    if playbackId ~= myId then return false end

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
        local subframes = bit32.band(division, 0xFF)
        if fps > 0 and subframes > 0 then
            smpteTicksPerSec = fps * subframes
        else
            isSmpte = false
            division = 96
        end
    elseif division <= 0 then
        division = 96
    end

    playing = true
    if onStart then
        pcall(onStart)
    end

    local currentTempo = 500000
    local lastTime = 0
    local nextEventClock = os.clock()
    local lastYieldClock = nextEventClock

    for _, ev in ipairs(events) do
        if not playing or playbackId ~= myId then break end

        local deltaTicks = ev.time - lastTime
        if deltaTicks > 0 then
            local speed = math.max(currentPlaybackSpeed, 0.05)
            local secondsPerTick = isSmpte and (1 / smpteTicksPerSec) or ((currentTempo / 1000000) / division)
            local waitTime = (deltaTicks * secondsPerTick) / speed
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
            if ev.tempo > 0 then
                currentTempo = ev.tempo
            end
        elseif ev.type == "note" then
            local char = MidiToChar[ev.key]
            if char then
                playChar(char)
            end
        end
    end

    if playbackId == myId then
        playing = false
        releaseHeldKeys()
    end
    return true
end

local function playTextSheet(sheet, bpm, myId)
    if playbackId ~= myId then return end
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
local ExternalTab = Window:CreateTab("MuseScore & MidiShow", 4483362458)
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

local function safeRequest(url, customHeaders, method, requestBody)
    method = method or "GET"
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
        local reqOpts = {
            Url = url,
            Method = method,
            Headers = headers,
        }
        if requestBody ~= nil then
            reqOpts.Body = requestBody
        end
        local ok, res = pcall(httpRequest, reqOpts)
        if not ok then
            return false, nil, tostring(res)
        end
        if type(res) ~= "table" then
            return false, nil, "Unexpected response type: " .. type(res)
        end
        return true, res, nil
    end

    if method ~= "GET" then
        return false, nil, "Executor does not support request() for " .. tostring(method)
    end

    local getOk, body = pcall(game.HttpGet, game, url)
    if getOk and type(body) == "string" then
        return true, {StatusCode = 200, Body = body}, nil
    end
    return false, nil, "Executor does not support request() or HttpGet failed"
end

local function getResponseBody(res)
    if type(res) ~= "table" then return nil end
    if type(res.Body) == "string" then return res.Body end
    if type(res.body) == "string" then return res.body end
    return nil
end

local function getResponseHeader(res, name)
    if type(res) ~= "table" then return nil end
    local headers = res.Headers or res.headers
    if type(headers) ~= "table" then return nil end
    local target = name:lower()
    for k, v in pairs(headers) do
        if type(k) == "string" and k:lower() == target then
            if type(v) == "table" then
                return table.concat(v, "; ")
            end
            return tostring(v)
        end
    end
    return nil
end

local function requestWithRetry(url, customHeaders, maxAttempts, retryDelay, shouldAbort, method, requestBody)
    maxAttempts = maxAttempts or 3
    retryDelay = retryDelay or 1.0
    local lastErr = "Unknown error"
    local lastStatus = nil

    for attempt = 1, maxAttempts do
        if shouldAbort and shouldAbort() then
            return false, nil, "Aborted", nil
        end

        local ok, res, err = safeRequest(url, customHeaders, method, requestBody)
        if ok and res then
            local status = res.StatusCode or res.status_code
            local body = getResponseBody(res)
            lastStatus = status
            if status == 200 and body then
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
    local body = getResponseBody(res)
    if not body or not body:find("MThd", 1, true) then
        return false, nil, "Response is not a MIDI file (missing MThd)", status
    end
    return true, body, nil, status
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

local function encodeQueryParam(str)
    return (tostring(str or ""):gsub("([^%w%-%._~])", function(c)
        return string.format("%%%02X", c:byte())
    end))
end

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

local function stripHtmlTags(str)
    return decodeHtmlEntities(tostring(str or ""):gsub("<[^>]->", " ")):gsub("%s+", " "):match("^%s*(.-)%s*$")
end

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
    local loLen = origBitLen % 4294967296
    local hiLen = math.floor(origBitLen / 4294967296) % 4294967296
    msg = msg .. string.pack("<I4I4", loLen, hiLen)

    local a0, b0, c0, d0 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
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

    local raw = string.pack("<I4I4I4I4", a0, b0, c0, d0)
    return (raw:gsub(".", function(c)
        return string.format("%02x", c:byte())
    end))
end

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
        for chunk in setCookieHeader:gmatch("[^,\r\n]+") do
            local firstPart = chunk:match("^%s*([^;]+)")
            if firstPart then
                local k, v = firstPart:match("^([^=]+)=(.*)$")
                local lowerK = k and k:lower() or ""
                if k and lowerK ~= "expires" and lowerK ~= "path" and lowerK ~= "domain" and lowerK ~= "max-age" and lowerK ~= "samesite" then
                    addPair(k, v)
                end
            end
        end
    end

    local out = {}
    for _, k in ipairs(order) do
        table.insert(out, k .. "=" .. jar[k])
    end
    return table.concat(out, "; ")
end

local function formatArtists(artists)
    if type(artists) == "table" then
        return table.concat(artists, ", ")
    elseif artists ~= nil then
        return tostring(artists)
    end
    return "Unknown"
end

local MuseState = {
    map = {},
    order = {},
    query = "",
    selected = nil,
    autoPlayOnSelect = false,
    suppressCallback = false,
    searching = false,
    searchGeneration = 0,
    statusActive = false,
    cachedSuffix = nil,
}

local MidiShowState = {
    map = {},
    order = {},
    query = "",
    selected = nil,
    cookie = "",
    autoPlayOnSelect = false,
    suppressCallback = false,
    searching = false,
    searchGeneration = 0,
    statusActive = false,
}

local runMuseSearch -- forward declaration
local runMidiShowSearch -- forward declaration

local function isMuseScoreUrl(url)
    local clean = tostring(url or ""):lower()
    return clean:find("musescore.com/", 1, true) ~= nil
end

local function isMidiShowUrl(url)
    local clean = tostring(url or ""):lower()
    return clean:find("midishow.com/", 1, true) ~= nil or clean:find("midishow.net/", 1, true) ~= nil
end

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

local function fetchMuseScoreMidi(rawInput, shouldAbort)
    local scoreUrl = normalizeMuseScoreInput(rawInput)
    if not scoreUrl or not isMuseScoreUrl(scoreUrl) then
        return false, nil, "Invalid MuseScore URL or ID"
    end

    local htmlHeaders = {
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.9",
        ["Referer"] = "https://musescore.com/",
    }

    local ok, pageRes, err = requestWithRetry(scoreUrl, htmlHeaders, 2, 0.75, shouldAbort)
    if not ok then
        return false, nil, "MuseScore page error: " .. tostring(err)
    end

    local html = getResponseBody(pageRes) or ""
    if html:find("This score is no longer available", 1, true) or html:find("Oops! This score is unavailable", 1, true) then
        return false, nil, "MuseScore score is unavailable / removed"
    end

    local scoreId = scoreUrl:match("/scores/(%d+)")
        or html:match("musescore://score/(%d+)")
        or html:match('"score_id"%s*:%s*(%d+)')
        or html:match('id=(%d+)&amp;type=')
    if not scoreId then
        return false, nil, "Could not find MuseScore score ID"
    end

    local suffixCandidates = {}
    local seenSuffix = {}
    local function addSuffix(s)
        if s and s ~= "" and not seenSuffix[s] then
            seenSuffix[s] = true
            table.insert(suffixCandidates, s)
        end
    end

    if MuseState.cachedSuffix then
        addSuffix(MuseState.cachedSuffix)
    end

    local jsUrls = {}
    local seenJs = {}
    local function addJsUrl(u)
        if not u or u == "" then return end
        if u:sub(1, 2) == "//" then
            u = "https:" .. u
        elseif u:sub(1, 1) == "/" then
            u = "https://musescore.com" .. u
        end
        if not seenJs[u] then
            seenJs[u] = true
            table.insert(jsUrls, u)
        end
    end

    for jsUrl in html:gmatch('https://musescore%.com/static/public/build/musescore[^"\']*?/20[^"\']+%.js') do
        addJsUrl(jsUrl)
    end
    for jsUrl in html:gmatch('"/static/public/build/musescore[^"\']*?/20[^"\']+%.js"') do
        addJsUrl(jsUrl:sub(2, -2))
    end
    if #jsUrls == 0 then
        for jsUrl in html:gmatch('https://musescore%.com/static/public/build/musescore[^"\']+%.js') do
            addJsUrl(jsUrl)
            if #jsUrls >= 4 then break end
        end
    end

    for i = 1, math.min(#jsUrls, 3) do
        if shouldAbort and shouldAbort() then
            return false, nil, "Aborted"
        end
        local jsOk, jsRes = requestWithRetry(jsUrls[i], {["Referer"] = scoreUrl}, 1, 0.5, shouldAbort)
        if jsOk then
            local jsBody = getResponseBody(jsRes) or ""
            local extracted = jsBody:match('"([^"]+)"%)%.substr%(0,4%)') or jsBody:match('"([^"]+)"%)%.slice%(0,4%)')
            if extracted then
                MuseState.cachedSuffix = extracted
                addSuffix(extracted)
                break
            end
        end
    end

    addSuffix("9654,4e")

    local lastErr = "MuseScore API rejected MIDI request"
    for _, suffix in ipairs(suffixCandidates) do
        if shouldAbort and shouldAbort() then
            return false, nil, "Aborted"
        end
        local auth = md5Hex(tostring(scoreId) .. "midi0" .. suffix):sub(1, 4)
        local apiUrl = "https://musescore.com/api/jmuse?id=" .. tostring(scoreId) .. "&type=midi&index=0"
        local apiOk, apiRes, apiErr, status = requestWithRetry(apiUrl, {
            ["Accept"] = "application/json, */*",
            ["Authorization"] = auth,
            ["Origin"] = "https://musescore.com",
            ["Referer"] = scoreUrl,
        }, 2, 0.5, shouldAbort)

        if apiOk then
            local body = getResponseBody(apiRes) or ""
            local decOk, data = pcall(HttpService.JSONDecode, HttpService, body)
            local midiUrl = decOk and type(data) == "table" and ((type(data.info) == "table" and data.info.url) or data.url)
            if type(midiUrl) == "string" and midiUrl ~= "" then
                local mOk, midiBody, mErr = fetchMidiBytesWithRetry(midiUrl, {
                    ["Referer"] = "https://musescore.com/",
                }, shouldAbort)
                if mOk and midiBody then
                    return true, midiBody, nil
                end
                lastErr = "MuseScore MIDI download failed: " .. tostring(mErr)
            else
                lastErr = "MuseScore API returned no MIDI URL"
            end
        else
            lastErr = "MuseScore API (" .. tostring(status or apiErr) .. ")"
        end
    end

    return false, nil, lastErr .. " (score may require MuseScore PRO or have MIDI disabled)"
end

local function searchMuseScore(query)
    local cleanQuery = tostring(query or ""):match("^%s*(.-)%s*$")
    if cleanQuery == "" then
        return false, nil, "Enter a search query"
    end

    local searchUrl = "https://musescore.com/sheetmusic?text=" .. encodeQueryParam(cleanQuery)
    local ok, res, err = requestWithRetry(searchUrl, {
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.9",
        ["Referer"] = "https://musescore.com/",
    }, 2, 0.75)
    if not ok then
        return false, nil, "MuseScore search failed: " .. tostring(err)
    end

    local html = getResponseBody(res) or ""
    local decodedHtml = decodeHtmlEntities(html)
    local results = {}
    local seenIds = {}

    local function addResult(title, url)
        if type(url) ~= "string" then return end
        local cleanUrl = url:gsub("\\/", "/"):gsub("#.*$", ""):gsub("%?.*$", "")
        if cleanUrl:sub(1, 1) == "/" then
            cleanUrl = "https://musescore.com" .. cleanUrl
        end
        local scoreId = cleanUrl:match("/scores/(%d+)")
        if not scoreId or seenIds[scoreId] then return end
        seenIds[scoreId] = true
        local cleanTitle = stripHtmlTags(title)
        if cleanTitle == "" then
            cleanTitle = "Score #" .. scoreId
        end
        if #cleanTitle > 90 then
            cleanTitle = cleanTitle:sub(1, 87) .. "..."
        end
        table.insert(results, {
            title = cleanTitle,
            url = cleanUrl,
            id = scoreId,
        })
    end

    -- JSON / data-content embedded store entries (decoded from &quot;)
    for title, url in decodedHtml:gmatch('"title"%s*:%s*"([^"]-)"[^}]-"url"%s*:%s*"(https?://musescore%.com/[^"]-/scores/%d+[^"]*)"') do
        addResult(title, url)
        if #results >= 50 then break end
    end

    if #results < 50 then
        for url, title in decodedHtml:gmatch('"url"%s*:%s*"(https?://musescore%.com/[^"]-/scores/%d+[^"]*)"[^}]-"title"%s*:%s*"([^"]-)"') do
            addResult(title, url)
            if #results >= 50 then break end
        end
    end

    if #results < 50 then
        for attrs, inner in html:gmatch('<a%s+([^>]-href=["\'][^"\']-/scores/%d+[^"\']*["\'][^>]*)>(.-)</a>') do
            local url = attrs:match('href=["\']([^"\']-/scores/%d+[^"\']*)["\']')
            local imgAlt = inner:match('alt=["\']([^"\']+)["\']')
            local title = attrs:match('aria%-label=["\']([^"\']+)["\']') or attrs:match('title=["\']([^"\']+)["\']') or imgAlt or inner
            addResult(title, url)
            if #results >= 50 then break end
        end
    end

    return true, results, nil
end

local function fetchMidiShowMidi(rawInput, shouldAbort)
    local pageUrl = normalizeMidiShowInput(rawInput)
    if not pageUrl or not isMidiShowUrl(pageUrl) then
        return false, nil, "Invalid MidiShow URL or ID"
    end

    local cookieHeader = MidiShowState.cookie ~= "" and MidiShowState.cookie or nil

    -- Direct .mid file URL attempt if passed directly
    if pageUrl:lower():match("%.mid$") or pageUrl:lower():match("%.mid%?") then
        local directOk, directBody = fetchMidiBytesWithRetry(pageUrl, {
            ["Referer"] = "https://www.midishow.com/",
            ["Cookie"] = cookieHeader,
        }, shouldAbort)
        if directOk and directBody then
            return true, directBody, nil
        end
        local directId = pageUrl:match("/(%d+)%.mid")
        if directId then
            pageUrl = "https://www.midishow.com/en/midi/" .. directId .. ".html"
        end
    end

    local pageHeaders = {
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.9,zh-CN;q=0.8",
        ["Referer"] = "https://www.midishow.com/",
    }
    if cookieHeader then
        pageHeaders["Cookie"] = cookieHeader
    end

    local ok, pageRes, err, status = requestWithRetry(pageUrl, pageHeaders, 2, 0.75, shouldAbort)
    if not ok then
        if status == 403 then
            return false, nil, "MidiShow returned HTTP 403 (Cloudflare/login required; paste your midishow.com Cookie)"
        end
        return false, nil, "MidiShow page error: " .. tostring(err)
    end

    local html = getResponseBody(pageRes) or ""
    if html:find("cf-browser-verification", 1, true) or html:find("challenge-platform", 1, true) or html:find("Just a moment", 1, true) then
        return false, nil, "MidiShow blocked by Cloudflare challenge (paste browser Cookie in MuseScore & MidiShow tab)"
    end

    local setCookie = getResponseHeader(pageRes, "set-cookie")
    cookieHeader = mergeCookieStrings(cookieHeader, setCookie)

    local csrfToken = html:match('<meta[^>]-name=["\']csrf%-token["\'][^>]-content=["\']([^"\']+)["\']')
        or html:match('<meta[^>]-content=["\']([^"\']+)["\'][^>]-name=["\']csrf%-token["\']')
    local midiId = html:match('data%-id=["\'](%d+)["\']')
        or pageUrl:match("/(%d+)%.html")
        or pageUrl:match("%-(%d+)/?$")
        or pageUrl:match("[?&]id=(%d+)")
    local dataMid = html:match('data%-mid=["\']([^"\']+)["\']')
    if dataMid then
        dataMid = decodeHtmlEntities(dataMid)
    end

    local lastErr = "Could not extract MidiShow MIDI data"

    if midiId and csrfToken and dataMid then
        local postUrl = "https://www.midishow.com/midi/new-file?id=" .. tostring(midiId)
        local postHeaders = {
            ["Accept"] = "*/*",
            ["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8",
            ["Origin"] = "https://www.midishow.com",
            ["Referer"] = pageUrl,
            ["X-Csrf-Token"] = csrfToken,
            ["X-Requested-With"] = "XMLHttpRequest",
        }
        if cookieHeader ~= "" then
            postHeaders["Cookie"] = cookieHeader
        end

        local postOk, postRes, postErr, postStatus = requestWithRetry(postUrl, postHeaders, 2, 0.5, shouldAbort, "POST", "id=" .. tostring(midiId))
        if postOk then
            local body1 = getResponseBody(postRes) or ""
            if #body1 >= 57 then
                local etag = getResponseHeader(postRes, "etag") or ""
                local jsUrl = dataMid
                    :gsub("^https?://www%.midishow%.com", "https://s.midishow.net")
                    :gsub("^https?://midishow%.com", "https://s.midishow.net")
                    :gsub("%.mid%?", ".js?")
                    :gsub("%.mid$", ".js")

                local jsOk, jsRes, jsErr = requestWithRetry(jsUrl, {
                    ["Accept"] = "*/*",
                    ["Referer"] = "https://www.midishow.com/",
                }, 2, 0.5, shouldAbort)

                if jsOk then
                    local body2 = getResponseBody(jsRes) or ""
                    local jsChunk = body2:match('^[^(]+%("([^"]*)"%)')
                        or body2:match("^[^(]+%('([^']*)'%)")
                        or (#body2 >= 7 and body2:sub(4, -4) or "")

                    local chrSet = hexToStr(etag) .. body1:sub(57)
                    if #chrSet >= 64 then
                        local part1 = decodeCustomBase64(body1:sub(29, 56), chrSet)
                        local part2 = decodeCustomBase64(jsChunk, chrSet)
                        local part3 = decodeCustomBase64(body1:sub(1, 28), chrSet)
                        local midiBytes = part1 .. part2 .. part3
                        if midiBytes:find("MThd", 1, true) then
                            return true, midiBytes, nil
                        end
                        lastErr = "MidiShow decoded bytes were not valid MIDI"
                    else
                        lastErr = "MidiShow charset/ETag missing"
                    end
                else
                    lastErr = "MidiShow JS chunk error: " .. tostring(jsErr)
                end
            else
                lastErr = "MidiShow new-file returned unexpected payload"
            end
        else
            if postStatus == 403 then
                lastErr = "MidiShow denied playback token (HTTP 403; login Cookie in MuseScore & MidiShow tab may be required)"
            else
                lastErr = "MidiShow new-file error: " .. tostring(postErr)
            end
        end
    end

    -- Fallback: try legacy direct /midi/file/<id>.mid endpoint
    if midiId then
        local legacyUrl = "https://www.midishow.com/midi/file/" .. tostring(midiId) .. ".mid"
        local legOk, legBody = fetchMidiBytesWithRetry(legacyUrl, {
            ["Referer"] = pageUrl,
            ["Cookie"] = cookieHeader ~= "" and cookieHeader or nil,
        }, shouldAbort)
        if legOk and legBody then
            return true, legBody, nil
        end
    end

    return false, nil, lastErr
end

local function searchMidiShow(query)
    local cleanQuery = tostring(query or ""):match("^%s*(.-)%s*$")
    if cleanQuery == "" then
        return false, nil, "Enter a search query"
    end

    local searchUrl = "https://www.midishow.com/en/search/result?q=" .. encodeQueryParam(cleanQuery)
    local headers = {
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.9,zh-CN;q=0.8",
        ["Referer"] = "https://www.midishow.com/en",
    }
    if MidiShowState.cookie ~= "" then
        headers["Cookie"] = MidiShowState.cookie
    end

    local searchUrls = {
        "https://www.midishow.com/en/search/result?q=" .. encodeQueryParam(cleanQuery),
        "https://www.midishow.com/search/result?q=" .. encodeQueryParam(cleanQuery),
    }

    local results = {}
    local seenIds = {}
    local lastErr = "MidiShow search failed"

    for _, searchUrl in ipairs(searchUrls) do
        local ok, res, err, status = requestWithRetry(searchUrl, headers, 2, 0.75)
        if not ok then
            if status == 403 then
                return false, nil, "MidiShow search blocked (HTTP 403 / Cloudflare; try setting Cookie)"
            end
            lastErr = "MidiShow search failed: " .. tostring(err)
        else
            local html = getResponseBody(res) or ""
            if html:find("cf-browser-verification", 1, true) or html:find("challenge-platform", 1, true) or html:find("Just a moment", 1, true) then
                return false, nil, "MidiShow blocked by Cloudflare challenge (set Cookie)"
            end

            for attrs, inner in html:gmatch('<a%s+([^>]-href=["\'][^"\']-/midi/[^"\']+["\'][^>]*)>(.-)</a>') do
                local rawHref = attrs:match('href=["\']([^"\']+)["\']')
                if rawHref then
                    local cleanHref = rawHref:gsub("#.*$", ""):gsub("%?.*$", "")
                    local id = cleanHref:match("/(%d+)%.html") or cleanHref:match("%-(%d+)/?$")
                    if id and not seenIds[id] and not cleanHref:find("/midi/browse", 1, true) and not cleanHref:find("/midi/download", 1, true) then
                        local heading = inner:match("<h[1-6][^>]*>(.-)</h[1-6]>") or inner:match("<strong[^>]*>(.-)</strong>")
                        local rawTitle = heading or attrs:match('title=["\']([^"\']+)["\']') or inner
                        local cleanTitle = stripHtmlTags(rawTitle)
                        if cleanTitle ~= "" and not cleanTitle:lower():match("^download") then
                            if #cleanTitle > 90 then
                                cleanTitle = cleanTitle:sub(1, 87) .. "..."
                            end
                            seenIds[id] = true
                            local fullUrl = cleanHref:match("^https?://") and cleanHref or ("https://www.midishow.com" .. (cleanHref:sub(1, 1) == "/" and "" or "/") .. cleanHref)
                            table.insert(results, {
                                title = cleanTitle,
                                url = fullUrl,
                                id = id,
                            })
                            if #results >= 50 then break end
                        end
                    end
                end
            end

            if #results > 0 then
                return true, results, nil
            end
        end
    end

    if #results == 0 and lastErr ~= "MidiShow search failed" then
        return false, nil, lastErr
    end
    return true, results, nil
end

local function resolveAndFetchMidiUrl(rawUrl, shouldAbort)
    local url = normalizeMidiUrl(rawUrl)
    if isMuseScoreUrl(url) then
        return fetchMuseScoreMidi(url, shouldAbort)
    elseif isMidiShowUrl(url) then
        return fetchMidiShowMidi(url, shouldAbort)
    end
    return fetchMidiBytesWithRetry(url, nil, shouldAbort)
end

local function downloadAndPlayUrl(rawUrl, sourceName, silent)
    local url = normalizeMidiUrl(rawUrl)
    if not url or not url:match("^https?://") then
        if not silent then
            Rayfield:Notify({
                Title = "Invalid URL",
                Content = "Please enter a valid http:// or https:// .mid, MuseScore, or MidiShow URL.",
                Duration = 3,
            })
        end
        return
    end

    stopPlayback()
    local myId = playbackId

    task.spawn(function()
        local ok, midiBody, err = resolveAndFetchMidiUrl(url, function()
            return playbackId ~= myId
        end)

        if playbackId ~= myId then return end

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

        local played = parseAndPlayMidi(midiBody, myId)
        if not played and playbackId == myId and not silent then
            Rayfield:Notify({
                Title = "Invalid MIDI",
                Content = "Downloaded file could not be parsed as MIDI.",
                Duration = 4,
            })
        end
    end)
end

-- Shared State Tables
local QuickState = {
    map = {},
    order = {},
    filtered = {},
    totalMatches = 0,
    query = "",
    selected = nil,
    repoUrl = QUICKPICKS_REPO_URL,
    sourceLabel = "Built-in",
    autoPlayOnSelect = false,
    suppressCallback = false,
    verifying = false,
    fetchGeneration = 0,
    statusActive = false,
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
    totalMatches = 0,
    query = "",
    selected = nil,
    suppressCallback = false,
    statusActive = false,
    liveExternalSearch = true,
}

local refreshGlobalSearchResults -- forward declaration

-- ==========================================
-- Tab 1: Quick Picks (Auto-Sync + Search) & Direct URL
-- ==========================================
QuickTab:CreateSection("Quick Picks (Search & Auto-Sync)")

local QuickStatusLabel = QuickTab:CreateLabel("Quick Picks: Loading...")
local QuickPickDropdown -- forward declared

local function updateQuickStatusLabel()
    QuickState.statusActive = false
    if QuickState.query ~= "" then
        setLabelSafe(QuickStatusLabel, string.format("Quick Picks (%s): %d matches (%d total)", QuickState.sourceLabel, QuickState.totalMatches, #QuickState.order))
    else
        setLabelSafe(QuickStatusLabel, string.format("Quick Picks (%s): %d songs ready", QuickState.sourceLabel, #QuickState.order))
    end
end

registerStopHook(function()
    if QuickState.statusActive then
        updateQuickStatusLabel()
    end
end)

local function applyQuickPickFilter()
    local matches, totalMatches = filterSongList(QuickState.order, QuickState.query, MAX_DROPDOWN_ITEMS)
    QuickState.filtered = matches
    QuickState.totalMatches = totalMatches
    QuickState.selected = setDropdownOptions(
        QuickPickDropdown,
        matches,
        QuickState.query ~= "" and "No matching Quick Picks" or "No songs loaded",
        function(v) QuickState.suppressCallback = v end
    )

    updateQuickStatusLabel()
end

local function setQuickPickEntries(entries, sourceLabel)
    table.clear(QuickState.map)
    table.clear(QuickState.order)
    QuickState.sourceLabel = sourceLabel or "Built-in"

    for _, item in ipairs(entries) do
        local baseLabel = tostring(item.name or "Untitled")
        local label = baseLabel
        local suffix = 2
        while QuickState.map[label] do
            label = baseLabel .. " (" .. tostring(suffix) .. ")"
            suffix = suffix + 1
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
    local trimmed = body:gsub("^\239\187\191", ""):match("^%s*(.-)%s*$")

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
        local myId = playbackId

        task.spawn(function()
            for idx, entry in ipairs(candidates) do
                if playbackId ~= myId then return end
                QuickState.statusActive = true
                setLabelSafe(QuickStatusLabel, string.format("Auto-trying (%d/%d): %s", idx, #candidates, entry.label))
                local ok, midiBody = fetchMidiBytesWithRetry(entry.url, nil, function()
                    return playbackId ~= myId
                end)
                if playbackId ~= myId then return end
                if ok and midiBody then
                    local played = parseAndPlayMidi(midiBody, myId, function()
                        QuickState.statusActive = true
                        setLabelSafe(QuickStatusLabel, "Playing: " .. entry.label)
                        Rayfield:Notify({Title = "Loaded & Playing", Content = entry.label, Duration = 3})
                    end)
                    if playbackId ~= myId then return end
                    if played then
                        updateQuickStatusLabel()
                        return
                    end
                end
            end

            if playbackId == myId then
                updateQuickStatusLabel()
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
                    local body = getResponseBody(res)
                    if status == 200 and body then
                        local parsed = parseQuickPickFile(body)
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
            local snapshot = {}
            for _, label in ipairs(QuickState.order) do
                local url = QuickState.map[label]
                if url then
                    table.insert(snapshot, {label = label, url = url})
                end
            end

            local total = #snapshot
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

                        local item = snapshot[i]
                        local ok, res, err = safeRequest(item.url)
                        local status = ok and res and (res.StatusCode or res.status_code) or nil
                        local body = getResponseBody(res)
                        local isMidi = ok and res and status == 200 and body ~= nil and body:find("MThd", 1, true) ~= nil

                        if isMidi then
                            passed = passed + 1
                        else
                            failedCount = failedCount + 1
                            local reason = not ok and tostring(err) or ("HTTP " .. tostring(status) .. " / not MIDI")
                            warn(string.format("[Verify FAIL] %s | %s | %s", item.label, reason, item.url))
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

QuickTab:CreateSection("Direct .mid / MuseScore / MidiShow URL")

local customMidiUrl = ""

QuickTab:CreateInput({
    Name = "Direct .mid / Score URL",
    CurrentValue = "",
    PlaceholderText = "https://.../song.mid, musescore.com/.../scores/..., or midishow.com/...",
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
                    local suffix = 2
                    while LocalState.files[label] do
                        label = name .. " (" .. tostring(suffix) .. ")"
                        suffix = suffix + 1
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

    if not content:find("MThd", 1, true) then
        warn("[Local MIDI] Not a valid MIDI file (missing MThd):", path)
        Rayfield:Notify({Title = "Invalid MIDI File", Content = "Selected file is missing an MThd MIDI header.", Duration = 3})
        return
    end

    stopPlayback()
    local myId = playbackId
    task.spawn(function()
        local played = parseAndPlayMidi(content, myId)
        if not played and playbackId == myId then
            Rayfield:Notify({Title = "MIDI Parse Error", Content = "Could not parse the selected local MIDI file.", Duration = 4})
        end
    end)
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
    local myId = playbackId

    task.spawn(function()
        local url = "https://api.nanomidi.net/api/midis/" .. encodeUrlPath(tostring(song.midiFilename))
        local ok, midiBody, err = fetchMidiBytesWithRetry(url, NanoState.headers, function()
            return playbackId ~= myId
        end)

        if playbackId ~= myId then return end

        if ok and midiBody then
            local played = parseAndPlayMidi(midiBody, myId)
            if not played and playbackId == myId and not silent then
                Rayfield:Notify({Title = "NanoMIDI Invalid MIDI", Content = "Downloaded file could not be parsed as MIDI.", Duration = 4})
            end
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

        local body = getResponseBody(res)
        local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, body or "")
        if not decodeOk or type(data) ~= "table" then
            NanoState.loadingList = false
            setLabelSafe(NanoStatusLabel, "NanoMIDI: Invalid API JSON")
            return
        end

        local items = data.data or data.midis or data.songs or data
        if type(items) ~= "table" then
            NanoState.loadingList = false
            setLabelSafe(NanoStatusLabel, "NanoMIDI: Invalid API JSON")
            return
        end

        table.clear(NanoState.apiData)
        table.clear(NanoState.order)

        for _, song in ipairs(items) do
            if type(song) == "table" then
                local baseLabel = tostring(song.name or "Untitled") .. " - " .. formatArtists(song.artists)
                local label = baseLabel
                if NanoState.apiData[label] then
                    local withFile = baseLabel .. " (" .. tostring(song.midiFilename or #NanoState.order + 1) .. ")"
                    label = withFile
                    local suffix = 2
                    while NanoState.apiData[label] do
                        label = withFile .. " #" .. tostring(suffix)
                        suffix = suffix + 1
                    end
                end
                table.insert(NanoState.order, label)
                NanoState.apiData[label] = song
            end
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
-- Tab 4: MuseScore & MidiShow
-- ==========================================
ExternalTab:CreateSection("MuseScore (Search & Direct Score URL)")

local MuseStatusLabel = ExternalTab:CreateLabel("MuseScore: Enter a search term or score URL")
local MuseDropdown -- forward declared

local function updateMuseStatusLabel()
    MuseState.statusActive = false
    if #MuseState.order > 0 then
        setLabelSafe(MuseStatusLabel, string.format("MuseScore: %d results for '%s'", #MuseState.order, MuseState.query))
    elseif MuseState.query ~= "" then
        setLabelSafe(MuseStatusLabel, string.format("MuseScore: 0 results for '%s'", MuseState.query))
    else
        setLabelSafe(MuseStatusLabel, "MuseScore: Enter a search term or score URL")
    end
end

registerStopHook(function()
    if MuseState.statusActive then
        updateMuseStatusLabel()
    end
end)

local function playMuseScoreEntry(rawUrlOrId, displayName, silent)
    local target = normalizeMuseScoreInput(rawUrlOrId)
    if not target or not isMuseScoreUrl(target) then
        if not silent then
            Rayfield:Notify({Title = "Invalid MuseScore Input", Content = "Enter a valid musescore.com URL or numeric score ID.", Duration = 3})
        end
        return
    end

    stopPlayback()
    local myId = playbackId

    task.spawn(function()
        MuseState.statusActive = true
        setLabelSafe(MuseStatusLabel, "MuseScore: Loading " .. tostring(displayName or target))
        local ok, midiBody, err = fetchMuseScoreMidi(target, function()
            return playbackId ~= myId
        end)
        if playbackId ~= myId then return end

        if ok and midiBody then
            local played = parseAndPlayMidi(midiBody, myId, function()
                MuseState.statusActive = true
                setLabelSafe(MuseStatusLabel, "MuseScore Playing: " .. tostring(displayName or target))
            end)
            if playbackId ~= myId then return end
            if played then
                updateMuseStatusLabel()
            else
                MuseState.statusActive = true
                setLabelSafe(MuseStatusLabel, "MuseScore: Invalid MIDI data")
                if not silent then
                    Rayfield:Notify({Title = "MuseScore Parse Error", Content = "Downloaded MIDI could not be parsed.", Duration = 4})
                end
            end
        else
            MuseState.statusActive = true
            setLabelSafe(MuseStatusLabel, "MuseScore Failed: " .. tostring(err))
            if not silent then
                Rayfield:Notify({Title = "MuseScore Load Failed", Content = tostring(err), Duration = 4})
            end
        end
    end)
end

runMuseSearch = function(query, silent)
    local clean = tostring(query or ""):match("^%s*(.-)%s*$")
    MuseState.query = clean
    MuseState.searchGeneration = MuseState.searchGeneration + 1
    local myGen = MuseState.searchGeneration

    if clean == "" then
        MuseState.searching = false
        table.clear(MuseState.map)
        table.clear(MuseState.order)
        MuseState.selected = setDropdownOptions(MuseDropdown, {}, "Enter search text above", function(v)
            MuseState.suppressCallback = v
        end)
        updateMuseStatusLabel()
        if refreshGlobalSearchResults then refreshGlobalSearchResults() end
        return
    end

    MuseState.searching = true
    MuseState.statusActive = true
    setLabelSafe(MuseStatusLabel, "MuseScore: Searching '" .. clean .. "'...")

    task.spawn(function()
        local ok, results, err = searchMuseScore(clean)
        if MuseState.searchGeneration ~= myGen then return end
        MuseState.searching = false
        if not ok then
            MuseState.statusActive = true
            setLabelSafe(MuseStatusLabel, "MuseScore Error: " .. tostring(err))
            if not silent then
                Rayfield:Notify({Title = "MuseScore Search Failed", Content = tostring(err), Duration = 4})
            end
            return
        end

        table.clear(MuseState.map)
        table.clear(MuseState.order)

        for _, item in ipairs(results) do
            local baseLabel = string.format("%s (#%s)", item.title, item.id)
            local label = baseLabel
            local suffix = 2
            while MuseState.map[label] do
                label = baseLabel .. " [" .. tostring(suffix) .. "]"
                suffix = suffix + 1
            end
            MuseState.map[label] = item.url
            table.insert(MuseState.order, label)
        end

        MuseState.selected = setDropdownOptions(
            MuseDropdown,
            MuseState.order,
            "No MuseScore results found",
            function(v) MuseState.suppressCallback = v end
        )
        updateMuseStatusLabel()
        if refreshGlobalSearchResults then refreshGlobalSearchResults() end
    end)
end

local MuseSearchInput = ExternalTab:CreateInput({
    Name = "🔍 Search MuseScore",
    CurrentValue = "",
    PlaceholderText = "Search score title & press Enter",
    RemoveTextAfterFocusLost = false,
    Flag = "MuseSearchInput",
    Callback = function(Text)
        runMuseSearch(Text, false)
    end,
})

ExternalTab:CreateButton({
    Name = "🔄 Clear MuseScore Search",
    Callback = function()
        pcall(function() MuseSearchInput:Set("") end)
        runMuseSearch("", false)
    end,
})

MuseDropdown = ExternalTab:CreateDropdown({
    Name = "MuseScore Results",
    Options = {"Search MuseScore above"},
    CurrentOption = {"Search MuseScore above"},
    MultipleOptions = false,
    Flag = "MuseScoreSelect",
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        MuseState.selected = MuseState.map[chosen] and chosen or nil
        if not MuseState.suppressCallback and MuseState.autoPlayOnSelect and MuseState.selected then
            playMuseScoreEntry(MuseState.map[MuseState.selected], MuseState.selected, false)
        end
    end,
})

ExternalTab:CreateToggle({
    Name = "⚡ Auto-Play MuseScore on Select",
    CurrentValue = false,
    Flag = "MuseAutoPlayToggle",
    Callback = function(Value)
        MuseState.autoPlayOnSelect = Value
    end,
})

ExternalTab:CreateButton({
    Name = "▶️ Play Selected MuseScore",
    Callback = function()
        local url = MuseState.selected and MuseState.map[MuseState.selected]
        if not url then
            Rayfield:Notify({Title = "No Score Selected", Content = "Search and select a MuseScore result first.", Duration = 3})
            return
        end
        playMuseScoreEntry(url, MuseState.selected, false)
    end,
})

ExternalTab:CreateButton({
    Name = "⚡ Auto-Try MuseScore Results",
    Callback = function()
        if #MuseState.order == 0 then
            Rayfield:Notify({Title = "No Results", Content = "Search MuseScore first.", Duration = 3})
            return
        end
        local candidates = {}
        for _, label in ipairs(MuseState.order) do
            if MuseState.map[label] then
                table.insert(candidates, {label = label, url = MuseState.map[label]})
            end
        end

        stopPlayback()
        local myId = playbackId

        task.spawn(function()
            for idx, entry in ipairs(candidates) do
                if playbackId ~= myId then return end
                MuseState.statusActive = true
                setLabelSafe(MuseStatusLabel, string.format("MuseScore auto-trying (%d/%d): %s", idx, #candidates, entry.label))
                local ok, midiBody = fetchMuseScoreMidi(entry.url, function()
                    return playbackId ~= myId
                end)
                if playbackId ~= myId then return end
                if ok and midiBody then
                    local played = parseAndPlayMidi(midiBody, myId, function()
                        MuseState.statusActive = true
                        setLabelSafe(MuseStatusLabel, "MuseScore Playing: " .. entry.label)
                        Rayfield:Notify({Title = "MuseScore Playing", Content = entry.label, Duration = 3})
                    end)
                    if playbackId ~= myId then return end
                    if played then
                        updateMuseStatusLabel()
                        return
                    end
                end
            end
            if playbackId == myId then
                updateMuseStatusLabel()
                Rayfield:Notify({Title = "MuseScore Auto-Try Failed", Content = "No playable MIDI found in current results.", Duration = 4})
            end
        end)
    end,
})

local customMuseUrl = ""
ExternalTab:CreateInput({
    Name = "MuseScore URL or Score ID",
    CurrentValue = "",
    PlaceholderText = "https://musescore.com/user/.../scores/5352121 or 5352121",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomMuseUrl",
    Callback = function(Text)
        customMuseUrl = Text
    end,
})

ExternalTab:CreateButton({
    Name = "▶️ Play MuseScore URL / ID",
    Callback = function()
        playMuseScoreEntry(customMuseUrl, nil, false)
    end,
})

ExternalTab:CreateSection("MidiShow (Search & Direct MIDI URL)")

local MidiShowStatusLabel = ExternalTab:CreateLabel("MidiShow: Enter a search term or midishow.com URL")
local MidiShowDropdown -- forward declared

local function updateMidiShowStatusLabel()
    MidiShowState.statusActive = false
    if #MidiShowState.order > 0 then
        setLabelSafe(MidiShowStatusLabel, string.format("MidiShow: %d results for '%s'", #MidiShowState.order, MidiShowState.query))
    elseif MidiShowState.query ~= "" then
        setLabelSafe(MidiShowStatusLabel, string.format("MidiShow: 0 results for '%s'", MidiShowState.query))
    else
        setLabelSafe(MidiShowStatusLabel, "MidiShow: Enter a search term or midishow.com URL")
    end
end

registerStopHook(function()
    if MidiShowState.statusActive then
        updateMidiShowStatusLabel()
    end
end)

local function playMidiShowEntry(rawUrlOrId, displayName, silent)
    local target = normalizeMidiShowInput(rawUrlOrId)
    if not target or not isMidiShowUrl(target) then
        if not silent then
            Rayfield:Notify({Title = "Invalid MidiShow Input", Content = "Enter a valid midishow.com URL or numeric MIDI ID.", Duration = 3})
        end
        return
    end

    stopPlayback()
    local myId = playbackId

    task.spawn(function()
        MidiShowState.statusActive = true
        setLabelSafe(MidiShowStatusLabel, "MidiShow: Loading " .. tostring(displayName or target))
        local ok, midiBody, err = fetchMidiShowMidi(target, function()
            return playbackId ~= myId
        end)
        if playbackId ~= myId then return end

        if ok and midiBody then
            local played = parseAndPlayMidi(midiBody, myId, function()
                MidiShowState.statusActive = true
                setLabelSafe(MidiShowStatusLabel, "MidiShow Playing: " .. tostring(displayName or target))
            end)
            if playbackId ~= myId then return end
            if played then
                updateMidiShowStatusLabel()
            else
                MidiShowState.statusActive = true
                setLabelSafe(MidiShowStatusLabel, "MidiShow: Invalid MIDI data")
                if not silent then
                    Rayfield:Notify({Title = "MidiShow Parse Error", Content = "Decoded MIDI could not be parsed.", Duration = 4})
                end
            end
        else
            MidiShowState.statusActive = true
            setLabelSafe(MidiShowStatusLabel, "MidiShow Failed: " .. tostring(err))
            if not silent then
                Rayfield:Notify({Title = "MidiShow Load Failed", Content = tostring(err), Duration = 5})
            end
        end
    end)
end

runMidiShowSearch = function(query, silent)
    local clean = tostring(query or ""):match("^%s*(.-)%s*$")
    MidiShowState.query = clean
    MidiShowState.searchGeneration = MidiShowState.searchGeneration + 1
    local myGen = MidiShowState.searchGeneration

    if clean == "" then
        MidiShowState.searching = false
        table.clear(MidiShowState.map)
        table.clear(MidiShowState.order)
        MidiShowState.selected = setDropdownOptions(MidiShowDropdown, {}, "Enter search text above", function(v)
            MidiShowState.suppressCallback = v
        end)
        updateMidiShowStatusLabel()
        if refreshGlobalSearchResults then refreshGlobalSearchResults() end
        return
    end

    MidiShowState.searching = true
    MidiShowState.statusActive = true
    setLabelSafe(MidiShowStatusLabel, "MidiShow: Searching '" .. clean .. "'...")

    task.spawn(function()
        local ok, results, err = searchMidiShow(clean)
        if MidiShowState.searchGeneration ~= myGen then return end
        MidiShowState.searching = false
        if not ok then
            MidiShowState.statusActive = true
            setLabelSafe(MidiShowStatusLabel, "MidiShow Error: " .. tostring(err))
            if not silent then
                Rayfield:Notify({Title = "MidiShow Search Failed", Content = tostring(err), Duration = 5})
            end
            return
        end

        table.clear(MidiShowState.map)
        table.clear(MidiShowState.order)

        for _, item in ipairs(results) do
            local baseLabel = string.format("%s (#%s)", item.title, item.id)
            local label = baseLabel
            local suffix = 2
            while MidiShowState.map[label] do
                label = baseLabel .. " [" .. tostring(suffix) .. "]"
                suffix = suffix + 1
            end
            MidiShowState.map[label] = item.url
            table.insert(MidiShowState.order, label)
        end

        MidiShowState.selected = setDropdownOptions(
            MidiShowDropdown,
            MidiShowState.order,
            "No MidiShow results found",
            function(v) MidiShowState.suppressCallback = v end
        )
        updateMidiShowStatusLabel()
        if refreshGlobalSearchResults then refreshGlobalSearchResults() end
    end)
end

local MidiShowSearchInput = ExternalTab:CreateInput({
    Name = "🔍 Search MidiShow",
    CurrentValue = "",
    PlaceholderText = "Search midishow.com & press Enter",
    RemoveTextAfterFocusLost = false,
    Flag = "MidiShowSearchInput",
    Callback = function(Text)
        runMidiShowSearch(Text, false)
    end,
})

ExternalTab:CreateButton({
    Name = "🔄 Clear MidiShow Search",
    Callback = function()
        pcall(function() MidiShowSearchInput:Set("") end)
        runMidiShowSearch("", false)
    end,
})

MidiShowDropdown = ExternalTab:CreateDropdown({
    Name = "MidiShow Results",
    Options = {"Search MidiShow above"},
    CurrentOption = {"Search MidiShow above"},
    MultipleOptions = false,
    Flag = "MidiShowSelect",
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        MidiShowState.selected = MidiShowState.map[chosen] and chosen or nil
        if not MidiShowState.suppressCallback and MidiShowState.autoPlayOnSelect and MidiShowState.selected then
            playMidiShowEntry(MidiShowState.map[MidiShowState.selected], MidiShowState.selected, false)
        end
    end,
})

ExternalTab:CreateToggle({
    Name = "⚡ Auto-Play MidiShow on Select",
    CurrentValue = false,
    Flag = "MidiShowAutoPlayToggle",
    Callback = function(Value)
        MidiShowState.autoPlayOnSelect = Value
    end,
})

ExternalTab:CreateButton({
    Name = "▶️ Play Selected MidiShow",
    Callback = function()
        local url = MidiShowState.selected and MidiShowState.map[MidiShowState.selected]
        if not url then
            Rayfield:Notify({Title = "No MIDI Selected", Content = "Search and select a MidiShow result first.", Duration = 3})
            return
        end
        playMidiShowEntry(url, MidiShowState.selected, false)
    end,
})

ExternalTab:CreateButton({
    Name = "⚡ Auto-Try MidiShow Results",
    Callback = function()
        if #MidiShowState.order == 0 then
            Rayfield:Notify({Title = "No Results", Content = "Search MidiShow first.", Duration = 3})
            return
        end
        local candidates = {}
        for _, label in ipairs(MidiShowState.order) do
            if MidiShowState.map[label] then
                table.insert(candidates, {label = label, url = MidiShowState.map[label]})
            end
        end

        stopPlayback()
        local myId = playbackId

        task.spawn(function()
            for idx, entry in ipairs(candidates) do
                if playbackId ~= myId then return end
                MidiShowState.statusActive = true
                setLabelSafe(MidiShowStatusLabel, string.format("MidiShow auto-trying (%d/%d): %s", idx, #candidates, entry.label))
                local ok, midiBody = fetchMidiShowMidi(entry.url, function()
                    return playbackId ~= myId
                end)
                if playbackId ~= myId then return end
                if ok and midiBody then
                    local played = parseAndPlayMidi(midiBody, myId, function()
                        MidiShowState.statusActive = true
                        setLabelSafe(MidiShowStatusLabel, "MidiShow Playing: " .. entry.label)
                        Rayfield:Notify({Title = "MidiShow Playing", Content = entry.label, Duration = 3})
                    end)
                    if playbackId ~= myId then return end
                    if played then
                        updateMidiShowStatusLabel()
                        return
                    end
                end
            end
            if playbackId == myId then
                updateMidiShowStatusLabel()
                Rayfield:Notify({Title = "MidiShow Auto-Try Failed", Content = "No playable MIDI found in current results.", Duration = 4})
            end
        end)
    end,
})

local customMidiShowUrl = ""
ExternalTab:CreateInput({
    Name = "MidiShow URL or MIDI ID",
    CurrentValue = "",
    PlaceholderText = "https://www.midishow.com/en/midi/36409.html or 36409",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomMidiShowUrl",
    Callback = function(Text)
        customMidiShowUrl = Text
    end,
})

ExternalTab:CreateButton({
    Name = "▶️ Play MidiShow URL / ID",
    Callback = function()
        playMidiShowEntry(customMidiShowUrl, nil, false)
    end,
})

ExternalTab:CreateInput({
    Name = "MidiShow Cookie (Optional, if 403/Cloudflare)",
    CurrentValue = "",
    PlaceholderText = "Paste midishow.com Cookie header if required",
    RemoveTextAfterFocusLost = false,
    Flag = "MidiShowCookieInput",
    Callback = function(Text)
        MidiShowState.cookie = tostring(Text or ""):match("^%s*(.-)%s*$")
    end,
})

ExternalTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})

-- ==========================================
-- Tab 5: Global Search & Auto-Try Across All Sources
-- ==========================================
GlobalTab:CreateSection("Search All Sources (Local + Quick Picks + NanoMIDI + MuseScore + MidiShow)")

local GlobalStatusLabel = GlobalTab:CreateLabel("Global Search: Enter a song name to search all sources")
local GlobalDropdown -- forward declared

local function updateGlobalStatusLabel()
    GlobalState.statusActive = false
    local shown = #GlobalState.resultsOrder
    local total = GlobalState.totalMatches
    if GlobalState.query ~= "" then
        if total > shown then
            setLabelSafe(GlobalStatusLabel, string.format("Global Search: showing %d of %d matches", shown, total))
        else
            setLabelSafe(GlobalStatusLabel, string.format("Global Search: %d matches found", total))
        end
    else
        setLabelSafe(GlobalStatusLabel, string.format(
            "Global Search: Showing %d songs (Local %d | Quick %d | Nano %d | Muse %d | MidiShow %d)",
            shown, #LocalState.order, #QuickState.order, #NanoState.order, #MuseState.order, #MidiShowState.order
        ))
    end
end

registerStopHook(function()
    if GlobalState.statusActive then
        updateGlobalStatusLabel()
    end
end)

local function buildGlobalMatches(query)
    local allEntries = {}
    local displayNames = {}
    local seenKeys = {}
    local totalMatches = 0

    local function addEntry(sourceTag, label, entry)
        if not matchesQuery(label, query) then return end
        totalMatches = totalMatches + 1
        if #displayNames >= MAX_DROPDOWN_ITEMS then return end

        local baseDisplay = "[" .. sourceTag .. "] " .. label
        local display = baseDisplay
        local suffix = 2
        while seenKeys[display] do
            display = baseDisplay .. " #" .. tostring(suffix)
            suffix = suffix + 1
        end
        seenKeys[display] = true
        entry.display = display
        allEntries[display] = entry
        table.insert(displayNames, display)
    end

    for _, label in ipairs(LocalState.order) do
        addEntry("Local", label, {kind = "local", label = label, path = LocalState.files[label]})
    end

    for _, label in ipairs(QuickState.order) do
        addEntry("QuickPick", label, {kind = "url", label = label, url = QuickState.map[label]})
    end

    for _, label in ipairs(MuseState.order) do
        if MuseState.map[label] then
            addEntry("MuseScore", label, {kind = "musescore", label = label, url = MuseState.map[label]})
        end
    end

    for _, label in ipairs(MidiShowState.order) do
        if MidiShowState.map[label] then
            addEntry("MidiShow", label, {kind = "midishow", label = label, url = MidiShowState.map[label]})
        end
    end

    for _, label in ipairs(NanoState.order) do
        local song = NanoState.apiData[label]
        if song and song.midiFilename then
            addEntry("NanoMIDI", label, {
                kind = "nano",
                label = label,
                url = "https://api.nanomidi.net/api/midis/" .. encodeUrlPath(tostring(song.midiFilename)),
            })
        end
    end

    return allEntries, displayNames, totalMatches
end

refreshGlobalSearchResults = function()
    local map, names, totalMatches = buildGlobalMatches(GlobalState.query)
    GlobalState.resultsMap = map
    GlobalState.resultsOrder = names
    GlobalState.totalMatches = totalMatches
    GlobalState.selected = setDropdownOptions(
        GlobalDropdown,
        names,
        GlobalState.query ~= "" and "No matches across sources" or "No songs loaded yet",
        function(v) GlobalState.suppressCallback = v end
    )

    updateGlobalStatusLabel()
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
    elseif entry.kind == "musescore" then
        local ok, midiBody = fetchMuseScoreMidi(entry.url, function()
            return playbackId ~= myId
        end)
        return ok, midiBody
    elseif entry.kind == "midishow" then
        local ok, midiBody = fetchMidiShowMidi(entry.url, function()
            return playbackId ~= myId
        end)
        return ok, midiBody
    else
        local ok, midiBody = resolveAndFetchMidiUrl(entry.url, function()
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
        if GlobalState.liveExternalSearch then
            local clean = GlobalState.query:match("^%s*(.-)%s*$")
            if clean ~= "" then
                if MuseState.query ~= clean then
                    runMuseSearch(clean, true)
                end
                if MidiShowState.query ~= clean then
                    runMidiShowSearch(clean, true)
                end
            end
        end
    end,
})

GlobalTab:CreateToggle({
    Name = "🌐 Live Search MuseScore & MidiShow",
    CurrentValue = true,
    Flag = "GlobalLiveExternalToggle",
    Callback = function(Value)
        GlobalState.liveExternalSearch = Value
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
        local myId = playbackId

        task.spawn(function()
            GlobalState.statusActive = true
            setLabelSafe(GlobalStatusLabel, "Loading: " .. entry.display)
            local ok, midiBody = tryLoadGlobalEntry(entry, myId)
            if playbackId ~= myId then return end

            if ok and midiBody then
                local played = parseAndPlayMidi(midiBody, myId, function()
                    GlobalState.statusActive = true
                    setLabelSafe(GlobalStatusLabel, "Playing: " .. entry.display)
                end)
                if playbackId ~= myId then return end
                if played then
                    updateGlobalStatusLabel()
                else
                    GlobalState.statusActive = true
                    setLabelSafe(GlobalStatusLabel, "Invalid MIDI: " .. entry.display)
                    Rayfield:Notify({Title = "MIDI Parse Error", Content = "Try 'Auto-Try Matching Songs' to test other sources.", Duration = 4})
                end
            else
                GlobalState.statusActive = true
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
        local myId = playbackId

        task.spawn(function()
            for idx, entry in ipairs(queue) do
                if playbackId ~= myId then return end
                GlobalState.statusActive = true
                setLabelSafe(GlobalStatusLabel, string.format("Auto-trying (%d/%d): %s", idx, #queue, entry.display))
                local ok, midiBody = tryLoadGlobalEntry(entry, myId)
                if playbackId ~= myId then return end

                if ok and midiBody then
                    local played = parseAndPlayMidi(midiBody, myId, function()
                        GlobalState.statusActive = true
                        setLabelSafe(GlobalStatusLabel, "Playing: " .. entry.display)
                        Rayfield:Notify({Title = "Auto-Loaded & Playing", Content = entry.display, Duration = 3})
                    end)
                    if playbackId ~= myId then return end
                    if played then
                        updateGlobalStatusLabel()
                        return
                    end
                end
            end

            if playbackId == myId then
                GlobalState.statusActive = true
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
