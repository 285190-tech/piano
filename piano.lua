-- piano.lua
-- Universal Piano — Roblox piano player with MIDI streaming, local files,
-- text sheets, NanoMIDI / MuseScore / MidiShow sources and a global search.
--
-- UI library: Obsidian (https://github.com/deividcomsono/Obsidian)
-- Pure logic (MIDI parser, decoders, helpers) lives in core.lua, which this
-- script loads from the same GitHub repository. Both files must be hosted
-- together (see README.md).
--
-- Playback notes:
--   * MIDI noteOff events are honored: each note is released when its
--     noteOff arrives (or after a safety fallback if the file omits it).
--   * Timing uses tick() (wall clock), not os.clock() (CPU time).
--   * Replay closures capture only small source strings, never the MIDI
--     payload, so stopping a song frees its memory.

local QUICKPICKS_REPO_URL = "https://raw.githubusercontent.com/q-29/piano/refs/heads/main/songs.json"
local OBSIDIAN_LIBRARY_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"
local CORE_LIBRARY_URL = "https://raw.githubusercontent.com/q-29/piano/refs/heads/main/core.lua"

local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Safety net: if a MIDI file never sends a noteOff for a pressed key,
-- release it after this many seconds instead of leaving the key stuck.
local FALLBACK_HOLD_SECONDS = 6

-- Fetch a string over HTTP with executor fallbacks (HttpGet / syn.get / http.get).
local function httpGetString(url)
    if game and game.HttpGet then
        local ok, body = pcall(game.HttpGet, game, url)
        if ok and type(body) == "string" then return body end
    end
    if syn and syn.get then
        local ok, body = pcall(syn.get, url)
        if ok and type(body) == "string" then return body end
    end
    if http and http.get then
        local ok, body = pcall(http.get, url)
        if ok and type(body) == "string" then return body end
    end
    error("No supported HTTP GET function available in this executor")
end

-- ==========================================
-- Load UI library (Obsidian) & pure logic (core.lua)
-- Both are wrapped in pcall: a failed load must produce a clear message
-- instead of an opaque script error.
-- ==========================================
local Library = nil
local libraryLoadError = nil
local okLibrary, result = pcall(function()
    return loadstring(httpGetString(OBSIDIAN_LIBRARY_URL))()
end)
if okLibrary and type(result) == "table" then
    Library = result
else
    libraryLoadError = result
end

local Core = nil
local coreLoadError = nil
local okCore, coreResult = pcall(function()
    return loadstring(httpGetString(CORE_LIBRARY_URL))()
end)
if okCore and type(coreResult) == "table" then
    Core = coreResult
else
    coreLoadError = coreResult
end

local function fatalLoadError(name, err)
    warn(string.format("[Piano] Failed to load %s: %s", name, tostring(err)))
    error(string.format(
        "[Piano] Failed to load %s. Check your internet connection and that the "
        .. "executor supports HTTP requests (HttpGet / syn.get).\n%s",
        name, tostring(err)))
end

if not Library then fatalLoadError("Obsidian UI library", libraryLoadError) end
if not Core then fatalLoadError("core.lua", coreLoadError) end

-- ==========================================
-- Virtual Piano Key Mapping & Input
-- ==========================================
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

-- Two keyboard layouts. "full" maps 60 consecutive MIDI notes (36-95) to
-- the full key string; "compact" maps one octave (12 white keys) so it
-- fits a small screen, with octave transposition handled by Shift.
local layouts = {
    full = {
        keyString = "1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm",
        count = 60,
    },
    compact = {
        keyString = "1234qQwWeErtTyY",
        count = 12,
    },
}

local currentLayoutName = "full"
local MidiToChar = {}
local CharToKeyInfo = {}
-- keyNote[keyEnum] = MIDI note currently held (for legato / voice stealing)
local keyNote = {}
-- activeVoices: list of {note, keyEnum, pressId, held} for voice stealing.
local activeVoices = {}
local voiceOrder = 0

local function buildLayout(layoutName)
    local layout = layouts[layoutName] or layouts.full
    local keys = layout.keyString

    MidiToChar = {}
    CharToKeyInfo = {}

    for i = 1, layout.count do
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
            note = startNote + i - 1,
        }
    end

    -- Re-seed held state so stale mappings don't linger across layouts.
    for keyEnum, _ in pairs(keyNote) do
        keyNote[keyEnum] = nil
    end
    for i = #activeVoices, 1, -1 do
        local v = activeVoices[i]
        if v and v.keyEnum then
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, v.keyEnum, false, game)
            end)
        end
        activeVoices[i] = nil
    end
end

buildLayout("full")

local keyPressId = {}
local keyHeld = {}
-- activePress[keyEnum] = pressId of the press that is currently held,
-- so a noteOff only releases the key if it belongs to the active press.
local activePress = {}

-- Voice / velocity configuration.
local MAX_VOICES = 16
local legatoMode = false
local velocityMin = 0.2
local velocityMax = 1.0
local velocityCurve = 1.0 -- exponent applied to velocity before scaling

-- Map an incoming 0..1 velocity through the configured curve and range.
local function mapVelocity(velocity)
    local v = math.clamp(velocity or 0.5, 0, 1)
    -- Exponential curve: v^curve biases toward the low end when > 1.
    if velocityCurve ~= 1 then
        v = v ^ velocityCurve
    end
    return velocityMin + v * (velocityMax - velocityMin)
end

-- Steal the oldest active voice if we're at the voice ceiling.
local function enforceVoiceLimit()
    while #activeVoices >= MAX_VOICES do
        local oldest = activeVoices[1]
        if oldest and oldest.keyEnum then
            if keyHeld[oldest.keyEnum] and activePress[oldest.keyEnum] == oldest.pressId then
                VirtualInputManager:SendKeyEvent(false, oldest.keyEnum, false, game)
                keyHeld[oldest.keyEnum] = false
                activePress[oldest.keyEnum] = nil
            end
        end
        table.remove(activeVoices, 1)
    end
end

local function pressChar(char, velocity)
    local info = CharToKeyInfo[char]
    if not info or not info.keyEnum then return end

    local keyEnum = info.keyEnum
    local mappedVel = mapVelocity(velocity)

    local pressId = (keyPressId[keyEnum] or 0) + 1
    keyPressId[keyEnum] = pressId

    -- Re-triggering the same key: in legato mode the previous press
    -- sustains (overlap); otherwise release it first (re-articulation).
    if keyHeld[keyEnum] and not legatoMode then
        VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
        keyHeld[keyEnum] = false
    end

    enforceVoiceLimit()

    if info.needsShift then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
    end

    VirtualInputManager:SendKeyEvent(true, keyEnum, false, game)
    keyHeld[keyEnum] = true
    activePress[keyEnum] = pressId
    keyNote[keyEnum] = info.note

    -- Track this voice for stealing.
    voiceOrder = voiceOrder + 1
    table.insert(activeVoices, {
        note = info.note,
        keyEnum = keyEnum,
        pressId = pressId,
        order = voiceOrder,
    })

    if info.needsShift then
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end

    -- Safety net: if the file never sends a matching noteOff, release
    -- after FALLBACK_HOLD_SECONDS. A real noteOff bumps keyPressId first,
    -- which makes this delayed release a no-op.
    -- Mapped velocity => hold length, so louder notes ring a bit longer.
    local hold = FALLBACK_HOLD_SECONDS * (0.6 + 0.8 * math.clamp(mappedVel, 0, 1))
    task.delay(hold, function()
        if keyPressId[keyEnum] == pressId and keyHeld[keyEnum] then
            VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
            keyHeld[keyEnum] = false
            activePress[keyEnum] = nil
        end
    end)
end

local function releaseChar(char)
    local info = CharToKeyInfo[char]
    if not info or not info.keyEnum then return end

    local keyEnum = info.keyEnum
    if keyHeld[keyEnum] and activePress[keyEnum] == keyPressId[keyEnum] then
        VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
        keyHeld[keyEnum] = false
        activePress[keyEnum] = nil
        -- Drop the matching voice entry.
        for i = #activeVoices, 1, -1 do
            if activeVoices[i].keyEnum == keyEnum and activeVoices[i].pressId == keyPressId[keyEnum] then
                table.remove(activeVoices, i)
                break
            end
        end
    end
end

-- ==========================================
-- Playback State, Progress HUD State & Players
-- ==========================================
local currentPlaybackSpeed = 1
local playing = false
local playbackId = 0
local stopHooks = {}

local PlayerHudState = {
    enabled = true,
    title = "No song playing",
    subtitle = "Select a song to start",
    currentTime = 0,
    totalTime = 0,
    status = "idle", -- "idle" | "loading" | "playing" | "paused" | "stopped" | "finished"
    paused = false,
    seekTarget = nil,
    draggingBar = false,
    dragPreviewTime = 0,
    replayFn = nil,
    -- Next-note highlight: chars of the upcoming press event, or nil.
    highlightNext = false,
    nextNoteChars = nil,
}

local function formatDuration(seconds)
    return Core.formatDuration(seconds)
end

local function setHudLoading(title, subtitle)
    PlayerHudState.title = tostring(title or "Loading song...")
    PlayerHudState.subtitle = tostring(subtitle or "Loading...")
    PlayerHudState.currentTime = 0
    PlayerHudState.totalTime = 0
    PlayerHudState.status = "loading"
    PlayerHudState.paused = false
    PlayerHudState.seekTarget = nil
end

local function setHudFailed(reason)
    PlayerHudState.status = "idle"
    PlayerHudState.paused = false
    PlayerHudState.currentTime = 0
    PlayerHudState.totalTime = 0
    PlayerHudState.subtitle = tostring(reason or "Load failed")
    PlayerHudState.replayFn = nil
end

local function registerStopHook(fn)
    table.insert(stopHooks, fn)
end

local function releaseHeldKeys()
    for keyEnum, held in pairs(keyHeld) do
        if held then
            keyPressId[keyEnum] = (keyPressId[keyEnum] or 0) + 1
            keyHeld[keyEnum] = false
            activePress[keyEnum] = nil
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
            end)
        end
    end
end

local function stopPlayback()
    playbackId = playbackId + 1
    playing = false
    PlayerHudState.paused = false
    PlayerHudState.seekTarget = nil
    PlayerHudState.currentTime = 0
    PlayerHudState.nextNoteChars = nil
    if PlayerHudState.replayFn then
        PlayerHudState.status = "stopped"
    else
        PlayerHudState.status = "idle"
    end
    releaseHeldKeys()
    for _, hook in ipairs(stopHooks) do
        pcall(hook)
    end
end

local function togglePausePlayback()
    if playing then
        PlayerHudState.paused = not PlayerHudState.paused
        if PlayerHudState.paused then
            PlayerHudState.status = "paused"
            releaseHeldKeys()
        else
            PlayerHudState.status = "playing"
        end
    elseif PlayerHudState.replayFn then
        PlayerHudState.replayFn()
    end
end

local function findEventIndexAtTime(events, targetTime)
    local lo, hi = 1, #events
    local ans = #events + 1
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if events[mid].songTime >= targetTime - 0.0001 then
            ans = mid
            hi = mid - 1
        else
            lo = mid + 1
        end
    end
    return ans
end

-- ==========================================
-- Shared playback engine
-- ==========================================
-- events: sorted table of {songTime, kind = "press"|"release", chars = {...}}
-- press events may carry a "velocity" field.
local function runEventPlayer(events, myId, onStart, totalDuration, meta)
    if playbackId ~= myId then return false end

    local songTitle = (meta and meta.title) or (PlayerHudState.status == "loading" and PlayerHudState.title) or "Song"
    local songSubtitle = (meta and meta.subtitle) or (PlayerHudState.status == "loading" and PlayerHudState.subtitle) or "Player"

    PlayerHudState.title = songTitle
    PlayerHudState.subtitle = songSubtitle
    PlayerHudState.currentTime = 0
    PlayerHudState.totalTime = totalDuration
    PlayerHudState.paused = false
    PlayerHudState.seekTarget = nil
    PlayerHudState.status = "playing"

    playing = true
    if onStart then
        pcall(onStart)
    end

    local idx = 1
    local nEvents = #events
    local lastClock = tick()
    local lastYieldClock = lastClock

    while idx <= nEvents do
        if not playing or playbackId ~= myId then break end

        if PlayerHudState.seekTarget ~= nil then
            local target = math.clamp(PlayerHudState.seekTarget, 0, totalDuration)
            PlayerHudState.seekTarget = nil
            releaseHeldKeys()
            PlayerHudState.currentTime = target
            idx = findEventIndexAtTime(events, target)
            lastClock = tick()
            lastYieldClock = lastClock
        elseif PlayerHudState.paused then
            releaseHeldKeys()
            task.wait(0.04)
            lastClock = tick()
            lastYieldClock = lastClock
        else
            -- tick() is wall-clock time; it keeps advancing while the thread
            -- is suspended in task.wait(), unlike os.clock() (CPU time).
            local now = tick()
            local dtReal = math.min(now - lastClock, 0.5)
            lastClock = now
            local speed = math.max(currentPlaybackSpeed, 0.05)
            PlayerHudState.currentTime = math.min(totalDuration, PlayerHudState.currentTime + dtReal * speed)

            local ev = events[idx]
            if PlayerHudState.currentTime + 0.0005 >= ev.songTime then
                while idx <= nEvents and PlayerHudState.currentTime + 0.0005 >= events[idx].songTime do
                    if not playing or playbackId ~= myId or PlayerHudState.paused or PlayerHudState.seekTarget ~= nil then
                        break
                    end
                    local curEv = events[idx]
                    if curEv.kind == "press" then
                        for _, char in ipairs(curEv.chars) do
                            pressChar(char, curEv.velocity)
                        end
                    elseif curEv.kind == "release" then
                        for _, char in ipairs(curEv.chars) do
                            releaseChar(char)
                        end
                    end
                    idx = idx + 1
                    if tick() - lastYieldClock > 0.03 then
                        task.wait()
                        lastYieldClock = tick()
                        lastClock = tick()
                    end
                end
            else
                -- Next-note highlight: peek at the upcoming press event so the
                -- HUD can flash which keys are about to be played.
                if PlayerHudState.highlightNext then
                    local nextEv = nil
                    for j = idx, nEvents do
                        if events[j].kind == "press" then
                            nextEv = events[j]
                            break
                        end
                    end
                    if nextEv then
                        PlayerHudState.nextNoteChars = nextEv.chars
                    else
                        PlayerHudState.nextNoteChars = nil
                    end
                end

                local songGap = ev.songTime - PlayerHudState.currentTime
                local realWait = songGap / speed
                local slice = math.min(realWait, 0.04)
                if slice > 0.002 then
                    task.wait(slice)
                else
                    task.wait()
                end
                lastYieldClock = tick()
            end
        end
    end

    if playbackId == myId then
        playing = false
        PlayerHudState.paused = false
        if idx > nEvents then
            PlayerHudState.currentTime = totalDuration
            PlayerHudState.status = "finished"
        elseif PlayerHudState.status ~= "stopped" then
            PlayerHudState.status = "stopped"
        end
        releaseHeldKeys()
    end
    return true
end

-- ==========================================
-- MIDI parsing & playback
-- ==========================================
local function parseAndPlayMidi(midiString, myId, onStart, meta, replayFn)
    if playbackId ~= myId then return false end

    local mthdIdx = midiString:find("MThd", 1, true)
    if not mthdIdx then
        warn("[Piano] Missing MThd header")
        if playbackId == myId then
            playing = false
            setHudFailed("Invalid MIDI header")
        end
        return false
    end
    if mthdIdx > 1 then
        midiString = midiString:sub(mthdIdx)
    end

    local stream = Core.createStringStream(midiString)

    local division = 96
    local events = {}
    local currentTime = 0
    local order = 0

    local ok, err = pcall(Core.processMidi, stream, function(name, ...)
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
                local char = MidiToChar[key]
                if char then
                    table.insert(events, {time = currentTime, order = order, kind = "press", chars = {char}, velocity = velocity})
                end
            end
        elseif name == "noteOff" then
            local channel, key = ...
            if channel ~= 10 then
                local char = MidiToChar[key]
                if char then
                    order = order + 1
                    table.insert(events, {time = currentTime, order = order, kind = "release", chars = {char}})
                end
            end
        elseif name == "setTempo" then
            local rawTempo = ...
            -- Tempo events are kept in the timeline so the timestamp
            -- precompute below can apply tempo changes at the right tick.
            if type(rawTempo) == "number" and rawTempo > 0 then
                order = order + 1
                table.insert(events, {time = currentTime, order = order, type = "tempo", tempo = rawTempo})
            end
        end
    end)

    if not ok then
        warn("[Piano] MIDI parse error:", err)
        if playbackId == myId then
            playing = false
            setHudFailed("MIDI parse error")
        end
        return false
    end

    if playbackId ~= myId then return false end

    -- At equal time, noteOff events sort before noteOn events so a
    -- re-triggered key is released before it is pressed again.
    table.sort(events, function(a, b)
        if a.time == b.time then
            if a.kind ~= b.kind then
                return a.kind == "release"
            end
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

    -- Precompute real song timestamps (at 1.0x speed) for progress & seeking
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
    local totalDuration = songSec

    PlayerHudState.replayFn = replayFn
    return runEventPlayer(events, myId, onStart, totalDuration, meta)
end

-- ==========================================
-- Text sheets
-- ==========================================
local function playTextSheet(sheet, bpm, myId, meta, replayFn)
    if playbackId ~= myId then return false end

    local baseStep = 60 / math.max(tonumber(bpm) or 120, 1) / 2
    local events = {}
    local songSec = 0
    local i = 1
    local len = #sheet

    local function emitPress(chars)
        table.insert(events, {songTime = songSec, kind = "press", chars = chars, velocity = 0.7})
        -- Synthetic release shortly after the press (text sheets have no
        -- noteOff events; this gives a natural staccato feel).
        local hold = math.min(baseStep * 0.7, 0.2)
        table.insert(events, {songTime = songSec + hold, kind = "release", chars = chars})
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
                        if CharToKeyInfo[gc] then
                            table.insert(events, {songTime = songSec, kind = "press", chars = {gc}, velocity = 0.7})
                            local hold = math.min(baseStep * 0.35, 0.06)
                            table.insert(events, {songTime = songSec + hold, kind = "release", chars = {gc}})
                            songSec = songSec + hold
                        end
                    end
                    songSec = songSec + baseStep * 0.5
                else
                    -- Chord: all characters are pressed simultaneously.
                    local chord = {}
                    for j = 1, #group do
                        local gc = group:sub(j, j)
                        if CharToKeyInfo[gc] then
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
        elseif CharToKeyInfo[ch] then
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

    local totalDuration = songSec
    PlayerHudState.replayFn = replayFn
    return runEventPlayer(events, myId, nil, totalDuration, meta)
end

-- ==========================================
-- Rayfield -> Obsidian UI
-- ==========================================
local function notify(title, content, duration)
    pcall(function()
        Library:Notify({
            Title = tostring(title),
            Description = tostring(content),
            Time = duration or 3,
        })
    end)
end

-- ==========================================
-- HTTP, Search & Auto-Load Helpers
-- ==========================================
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local MAX_DROPDOWN_ITEMS = 200

-- Tunable network policy. Declared here (before the fetch helpers) so every
-- fetch path reads the live values; the Network Tuning UI sliders update it.
local NetworkConfig = {
    maxAttempts = 3,
    retryDelay = 1.5,
}

local function normalizeMidiUrl(url)
    return Core.normalizeMidiUrl(url)
end

local function buildRepoUrlCandidates(rawUrl)
    return Core.buildRepoUrlCandidates(rawUrl)
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
    -- Allow callers to omit the retry policy; fall back to the live tunable
    -- NetworkConfig so the UI sliders affect every fetch path.
    if maxAttempts == nil then maxAttempts = NetworkConfig.maxAttempts end
    if retryDelay == nil then retryDelay = NetworkConfig.retryDelay end
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
    local ok, res, err, status = requestWithRetry(url, customHeaders, nil, nil, shouldAbort)
    if not ok then
        return false, nil, err, status
    end
    local body = getResponseBody(res)
    if not body or not body:find("MThd", 1, true) then
        return false, nil, "Response is not a MIDI file (missing MThd)", status
    end
    return true, body, nil, status
end

-- ==========================================
-- Shared State Tables
-- (Declared before the fetch functions below so those functions capture
-- these as upvalues rather than resolving them as globals at call time.)
-- ==========================================
local QuickState = {
    map = {},
    order = {},
    filtered = {},
    totalMatches = 0,
    query = "",
    selected = nil,
    repoUrl = QUICKPICKS_REPO_URL,
    sourceLabel = "GitHub Repo",
    autoPlayOnSelect = false,
    suppressCallback = false,
    verifying = false,
    verifyAbort = false,
    verifyFailures = {},
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

-- Playback history: recent plays with a replay closure. Each entry keeps
-- only the small source strings (title, source, replayFn), never the MIDI
-- payload, so the list stays lightweight (item 14: memory hygiene).
local HistoryState = {
    entries = {}, -- newest first: {title, source, replayFn}
    maxSize = 25,
    suppressCallback = false,
}

local function recordHistory(title, source, replayFn)
    table.insert(HistoryState.entries, 1, {
        title = tostring(title or "Unknown"),
        source = tostring(source or "Unknown"),
        replayFn = replayFn,
    })
    while #HistoryState.entries > HistoryState.maxSize do
        table.remove(HistoryState.entries)
    end
end

local refreshGlobalSearchResults -- forward declaration
local runMuseSearch -- forward declaration
local runMidiShowSearch -- forward declaration

-- ==========================================
-- MuseScore & MidiShow fetching
-- NOTE: Both sites are scraped because they expose no public MIDI API.
-- The extraction logic below is reverse-engineered and inherently brittle:
-- if either site changes its markup/payloads, the relevant function must be
-- updated. Error strings always include the failing stage to make that
-- easier to diagnose.
-- ==========================================
local function fetchMuseScoreMidi(rawInput, shouldAbort)
    local scoreUrl = Core.normalizeMuseScoreInput(rawInput)
    if not scoreUrl or not Core.isMuseScoreUrl(scoreUrl) then
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

    -- The jmuse API requires a 4-hex-char auth prefix: md5(scoreId .. "midi0"
    -- .. suffix) truncated to 4 chars, where suffix identifies the MIDI
    -- build. The suffix is scraped from MuseScore's production JS bundles
    -- (their build hash changes over time), with a hardcoded fallback.
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

    -- Fallback suffix observed on MuseScore's current build.
    addSuffix("9654,4e")

    local lastErr = "MuseScore API rejected MIDI request"
    for _, suffix in ipairs(suffixCandidates) do
        if shouldAbort and shouldAbort() then
            return false, nil, "Aborted"
        end
        local auth = Core.md5Hex(tostring(scoreId) .. "midi0" .. suffix):sub(1, 4)
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

    local searchUrl = "https://musescore.com/sheetmusic?text=" .. Core.encodeQueryParam(cleanQuery)
    local ok, res, err = requestWithRetry(searchUrl, {
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.9",
        ["Referer"] = "https://musescore.com/",
    }, 2, 0.75)
    if not ok then
        return false, nil, "MuseScore search failed: " .. tostring(err)
    end

    local html = getResponseBody(res) or ""
    local decodedHtml = Core.decodeHtmlEntities(html)
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
        local cleanTitle = Core.stripHtmlTags(title)
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
    local pageUrl = Core.normalizeMidiShowInput(rawInput)
    if not pageUrl or not Core.isMidiShowUrl(pageUrl) then
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

    cookieHeader = Core.mergeCookieStrings(cookieHeader, getResponseHeader(pageRes, "set-cookie"))

    local csrfToken = html:match('<meta[^>]-name=["\']csrf%-token["\'][^>]-content=["\']([^"\']+)["\']')
        or html:match('<meta[^>]-content=["\']([^"\']+)["\'][^>]-name=["\']csrf%-token["\']')
    local midiId = html:match('data%-id=["\'](%d+)["\']')
        or pageUrl:match("/(%d+)%.html")
        or pageUrl:match("-(%d+)/?$")
        or pageUrl:match("[?&]id=(%d+)")
    local dataMid = html:match('data%-mid=["\']([^"\']+)["\']')
    if dataMid then
        dataMid = Core.decodeHtmlEntities(dataMid)
    end

    local lastErr = "Could not extract MidiShow MIDI data"

    if midiId and csrfToken and dataMid then
        -- MidiShow serves the MIDI in three obfuscated parts:
        --   1. body1 (new-file POST response): bytes 29..56 (28 chars) and 1..28 (28 chars)
        --   2. body2 (the .js chunk referenced by data-mid)
        --   3. a custom-base64 alphabet derived from the ETag header
        -- The offsets below are reverse-engineered from MidiShow's current
        -- payload layout; if they stop working, check the site's network tab
        -- and update these constants.
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

                    local chrSet = Core.hexToStr(etag) .. body1:sub(57)
                    if #chrSet >= 64 then
                        local part1 = Core.decodeCustomBase64(body1:sub(29, 56), chrSet)
                        local part2 = Core.decodeCustomBase64(jsChunk, chrSet)
                        local part3 = Core.decodeCustomBase64(body1:sub(1, 28), chrSet)
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

    local headers = {
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.9,zh-CN;q=0.8",
        ["Referer"] = "https://www.midishow.com/en",
    }
    if MidiShowState.cookie ~= "" then
        headers["Cookie"] = MidiShowState.cookie
    end

    local searchUrls = {
        "https://www.midishow.com/en/search/result?q=" .. Core.encodeQueryParam(cleanQuery),
        "https://www.midishow.com/search/result?q=" .. Core.encodeQueryParam(cleanQuery),
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
                    local id = cleanHref:match("/(%d+)%.html") or cleanHref:match("-(%d+)/?$")
                    if id and not seenIds[id] and not cleanHref:find("/midi/browse", 1, true) and not cleanHref:find("/midi/download", 1, true) then
                        local heading = inner:match("<h[1-6][^>]*>(.-)</h[1-6]>") or inner:match("<strong[^>]*>(.-)</strong>")
                        local rawTitle = heading or attrs:match('title=["\']([^"\']+)["\']') or inner
                        local cleanTitle = Core.stripHtmlTags(rawTitle)
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
    if Core.isMuseScoreUrl(url) then
        return fetchMuseScoreMidi(url, shouldAbort)
    elseif Core.isMidiShowUrl(url) then
        return fetchMidiShowMidi(url, shouldAbort)
    end
    return fetchMidiBytesWithRetry(url, nil, shouldAbort)
end

local function downloadAndPlayUrl(rawUrl, sourceName, silent, displayTitle)
    local url = normalizeMidiUrl(rawUrl)
    if not url or not url:match("^https?://") then
        if not silent then
            notify("Invalid URL", "Please enter a valid http:// or https:// .mid, MuseScore, or MidiShow URL.", 3)
        end
        return
    end

    local title = displayTitle or Core.deriveTitleFromUrl(url)
    stopPlayback()
    local myId = playbackId
    setHudLoading(title, sourceName or "URL")

    task.spawn(function()
        local ok, midiBody, err = resolveAndFetchMidiUrl(url, function()
            return playbackId ~= myId
        end)

        if playbackId ~= myId then return end

        if not ok then
            warn("[" .. sourceName .. "] Load failed:", err, "| URL:", url)
            setHudFailed("Load failed")
            if not silent then
                notify("Song Load Failed", tostring(err), 4)
            end
            return
        end

        -- Replay closure captures only the small source strings, never the
        -- downloaded MIDI payload, so stopping the song frees its memory.
        local replayFn = function()
            downloadAndPlayUrl(url, sourceName, silent, displayTitle)
        end
        recordHistory(title, sourceName, replayFn)
        local played = parseAndPlayMidi(midiBody, myId, nil, {title = title, subtitle = sourceName or "URL"}, replayFn)
        if not played and playbackId == myId and not silent then
            notify("Invalid MIDI", "Downloaded file could not be parsed as MIDI.", 4)
        end
    end)
end

-- ==========================================
-- Obsidian window & tabs
-- ==========================================
local Window = Library:CreateWindow({
    Title = "🎹 Universal Piano",
    Footer = "MIDI · Local · Sheets · NanoMIDI · MuseScore · MidiShow",
    ToggleKeybind = Enum.KeyCode.Quote,
    ShowCustomCursor = true,
})

local QuickTab = Window:AddTab("Quick Picks & URL", "music")
local LocalTab = Window:AddTab("Local & Sheets", "folder")
local NanoTab = Window:AddTab("NanoMIDI API", "radio")
local ExternalTab = Window:AddTab("MuseScore & MidiShow", "link")
local GlobalTab = Window:AddTab("🔍 Global Search", "search")

-- ==========================================
-- UI helpers
-- ==========================================
local function setDropdownOptions(dropdown, options, fallbackText, setSuppress)
    local display = options
    local hasItems = #options > 0
    if not hasItems then
        display = {fallbackText or "No matching songs"}
    end

    if setSuppress then setSuppress(true) end
    pcall(function()
        dropdown:SetValues(display)
        dropdown:SetValue(display[1])
    end)
    if setSuppress then setSuppress(false) end

    return hasItems and display[1] or nil
end

local function setLabelSafe(labelObj, text)
    if labelObj and labelObj.SetText then
        pcall(function()
            labelObj:SetText(text)
        end)
    end
end

-- ==========================================
-- Tab 1: Quick Picks (Auto-Sync + Search) & Direct URL
-- ==========================================
local QuickPicksBox = QuickTab:AddGroupbox({
    Side = "Left",
    Name = "Quick Picks (Search & Auto-Sync)",
})

local QuickStatusLabel = QuickPicksBox:AddLabel("QuickStatusLabel", { Text = "Quick Picks: Loading..." })
local QuickVerifyLabel = QuickPicksBox:AddLabel("QuickVerifyLabel", { Text = "" })
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
    local matches, totalMatches = Core.filterSongList(QuickState.order, QuickState.query, MAX_DROPDOWN_ITEMS)
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
    for k in pairs(QuickState.map) do QuickState.map[k] = nil end
    for k in pairs(QuickState.order) do QuickState.order[k] = nil end
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
    return Core.parseQuickPickFile(body, function(str)
        local ok, data = pcall(HttpService.JSONDecode, HttpService, str)
        return ok and data
    end)
end

local function playQuickPickSelection(label)
    local url = label and QuickState.map[label]
    if not url then
        notify("No Song Selected", "Pick a song from the dropdown first.", 3)
        return
    end
    downloadAndPlayUrl(url, "QuickPick", false, label)
end

local QuickSearchInput = QuickPicksBox:AddInput("QuickSearchInput", {
    Text = "🔍 Search Quick Picks",
    Default = "",
    Placeholder = "Type song/artist & press Enter (blank = all)",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        QuickState.query = tostring(Text or "")
        applyQuickPickFilter()
    end,
})

QuickPickDropdown = QuickPicksBox:AddDropdown("QuickPickSelect", {
    Text = "Select Quick Pick",
    Values = {"Loading..."},
    Default = "Loading...",
    Multi = false,
    Searchable = true,
    MaxVisibleDropdownItems = 12,
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        QuickState.selected = QuickState.map[chosen] and chosen or nil
        if not QuickState.suppressCallback and QuickState.autoPlayOnSelect and QuickState.selected then
            playQuickPickSelection(QuickState.selected)
        end
    end,
})

QuickPicksBox:AddToggle("QuickAutoPlayToggle", {
    Text = "⚡ Auto-Play Song on Select",
    Default = false,
    Callback = function(Value)
        QuickState.autoPlayOnSelect = Value
    end,
})

QuickPicksBox:AddButton({
    Text = "▶️ Play Quick Pick",
    Func = function()
        playQuickPickSelection(QuickState.selected)
    end,
})

QuickPicksBox:AddButton({
    Text = "⚡ Auto-Try Matching Quick Picks",
    Func = function()
        local candidates = {}
        for _, label in ipairs(QuickState.order) do
            if Core.matchesQuery(label, QuickState.query) and QuickState.map[label] then
                table.insert(candidates, {label = label, url = QuickState.map[label]})
            end
        end
        if #candidates == 0 then
            notify("No Matches", "No Quick Picks matched your search.", 3)
            return
        end

        stopPlayback()
        local myId = playbackId

        task.spawn(function()
            for idx, entry in ipairs(candidates) do
                if playbackId ~= myId then return end
                QuickState.statusActive = true
                setLabelSafe(QuickStatusLabel, string.format("Auto-trying (%d/%d): %s", idx, #candidates, entry.label))
                setHudLoading(entry.label, string.format("QuickPick (%d/%d)", idx, #candidates))
                local ok, midiBody = fetchMidiBytesWithRetry(entry.url, nil, function()
                    return playbackId ~= myId
                end)
                if playbackId ~= myId then return end
                if ok and midiBody then
                    local replayFn = function()
                        playQuickPickSelection(entry.label)
                    end
                    local played = parseAndPlayMidi(midiBody, myId, function()
                        QuickState.statusActive = true
                        setLabelSafe(QuickStatusLabel, "Playing: " .. entry.label)
                        notify("Loaded & Playing", entry.label, 3)
                    end, {title = entry.label, subtitle = "QuickPick"}, replayFn)
                    if playbackId ~= myId then return end
                    if played then
                        updateQuickStatusLabel()
                        return
                    end
                end
            end

            if playbackId == myId then
                setHudFailed("No working Quick Pick found")
                updateQuickStatusLabel()
                notify("Auto-Try Failed", "None of the matching Quick Picks returned valid MIDI data.", 4)
            end
        end)
    end,
})

QuickPicksBox:AddButton({
    Text = "🔄 Clear Search",
    Func = function()
        QuickState.query = ""
        pcall(function() QuickSearchInput:SetValue("") end)
        applyQuickPickFilter()
    end,
})

-- ==========================================
-- GitHub Repo Sync (Auto-Retry)
-- ==========================================
local RepoBox = QuickTab:AddGroupbox({
    Side = "Left",
    Name = "GitHub Repo Sync (Auto-Retry)",
})

local function fetchFromRepoUrl(urlToFetch, silent)
    local candidates = buildRepoUrlCandidates(urlToFetch)
    if #candidates == 0 then
        setQuickPickEntries({}, "Empty")
        if not silent then
            notify("Built-in Quick Picks", "No repo URL provided.", 3)
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
                            notify("Repo Songs Auto-Loaded", string.format("Loaded %d songs from GitHub!", #QuickState.order), 3)
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
        -- songs.json is the single source of truth: on failure we do not
        -- fall back to a stale built-in list. The dropdown keeps its last
        -- contents but the status reflects the failure.
        if QuickState.query ~= "" or #QuickState.order == 0 then
            applyQuickPickFilter()
        end
        setLabelSafe(QuickStatusLabel, "Quick Picks: Repo load failed (" .. tostring(lastErr) .. ")")
        if not silent then
            notify("Repo Load Failed", tostring(lastErr), 4)
        end
    end)
end

if QUICKPICKS_REPO_URL ~= "" then
    fetchFromRepoUrl(QUICKPICKS_REPO_URL, true)
end

RepoBox:AddInput("RepoFileUrl", {
    Text = "GitHub Repo File URL (Auto-Loads)",
    Default = QUICKPICKS_REPO_URL,
    Placeholder = "https://raw.githubusercontent.com/q-29/piano/refs/heads/main/songs.json",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        local cleaned = tostring(Text or ""):match("^%s*(.-)%s*$")
        if cleaned ~= QuickState.repoUrl then
            QuickState.repoUrl = cleaned
            fetchFromRepoUrl(cleaned, false)
        end
    end,
})

RepoBox:AddButton({
    Text = "🔄 Fetch Songs from Repo",
    Func = function()
        fetchFromRepoUrl(QuickState.repoUrl, false)
    end,
})

RepoBox:AddButton({
    Text = "🔍 Verify All Links (Progress Shown)",
    Func = function()
        if QuickState.verifying then
            QuickState.verifyAbort = true
            return
        end
        QuickState.verifying = true
        QuickState.verifyAbort = false
        QuickState.verifyFailures = {}
        setLabelSafe(QuickVerifyLabel, "")

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
        local lastProgressLabel = 0

        notify("Verifying Links...", string.format("Testing %d links. Click the button again to cancel.", total), 3)

        for _ = 1, 6 do
            task.spawn(function()
                while true do
                    if QuickState.verifyAbort then break end
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
                        table.insert(QuickState.verifyFailures, string.format("%s (%s)", item.label, reason))
                        warn(string.format("[Verify FAIL] %s | %s | %s", item.label, reason, item.url))
                    end
                    done = done + 1

                    -- Live progress feedback (at most every 5 links).
                    if done - lastProgressLabel >= 5 or done == total then
                        lastProgressLabel = done
                        setLabelSafe(QuickStatusLabel, string.format("Verifying links: %d/%d done", done, total))
                    end
                end
            end)
        end

        while done < total and not QuickState.verifyAbort do
            task.wait(0.1)
        end

        QuickState.verifying = false
        local summary = string.format("Passed: %d / %d | Failed: %d", passed, total, failedCount)
        if #QuickState.verifyFailures > 0 then
            local shown = table.concat(QuickState.verifyFailures, "\n")
            if #shown > 1500 then shown = shown:sub(1, 1500) .. " ..." end
            setLabelSafe(QuickVerifyLabel, summary .. "\n\nFailed:\n" .. shown)
        end
        setLabelSafe(QuickStatusLabel, "Link verification finished.")
        print(string.format("[QuickPicks Verify] %s", summary))
        notify("Link Verification Done", summary .. (QuickState.verifyAbort and " (cancelled)" or ""), 5)
    end,
})

-- ==========================================
-- Custom MIDI List (item 9: additional source)
-- Paste "Name | https://.../file.mid" lines (or bare URLs) and merge them
-- into the Quick Picks list as a third source alongside the GitHub repo.
-- ==========================================
local CustomListBox = QuickTab:AddGroupbox({
    Side = "Left",
    Name = "📋 Custom MIDI List",
})

local customListBody = ""

CustomListBox:AddInput("CustomListInput", {
    Text = "Custom MIDI List (Name | URL, one per line)",
    Default = "",
    Placeholder = "Beethoven - Fur Elise | https://.../fur-elise.mid\nhttps://.../other.mid",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        customListBody = Text or ""
    end,
})

CustomListBox:AddButton({
    Text = "➕ Merge Into Quick Picks",
    Func = function()
        if customListBody == "" then
            notify("Custom List", "Paste at least one song line first.", 3)
            return
        end
        local parsed = parseQuickPickFile(customListBody)
        if #parsed == 0 then
            notify("Custom List", "No valid \"Name | URL\" lines found.", 3)
            return
        end

        -- Merge: keep existing entries, append new ones (dedupe by URL).
        local existingUrls = {}
        for _, label in ipairs(QuickState.order) do
            existingUrls[QuickState.map[label]] = true
        end
        local added = 0
        for _, item in ipairs(parsed) do
            if not existingUrls[item.url] then
                local baseLabel = tostring(item.name or "Untitled")
                local label = baseLabel
                local suffix = 2
                while QuickState.map[label] do
                    label = baseLabel .. " (" .. tostring(suffix) .. ")"
                    suffix = suffix + 1
                end
                QuickState.map[label] = normalizeMidiUrl(item.url)
                table.insert(QuickState.order, label)
                existingUrls[item.url] = true
                added = added + 1
            end
        end
        applyQuickPickFilter()
        notify("Custom List Merged", string.format("Added %d song(s) to Quick Picks.", added), 3)
    end,
})

-- ==========================================
-- Network Tuning (item 12: retry / timeout)
-- ==========================================
local NetworkBox = QuickTab:AddGroupbox({
    Side = "Left",
    Name = "🌐 Network Tuning",
})

NetworkBox:AddSlider("MaxRetryAttempts", {
    Text = "Max Retry Attempts",
    Default = NetworkConfig.maxAttempts,
    Min = 1,
    Max = 8,
    Rounding = 0,
    Callback = function(Value)
        NetworkConfig.maxAttempts = Value
    end,
})

NetworkBox:AddSlider("RetryDelaySeconds", {
    Text = "Retry Delay (seconds)",
    Default = NetworkConfig.retryDelay,
    Min = 0.2,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        NetworkConfig.retryDelay = Value
    end,
})

NetworkBox:AddLabel("NetworkTuningLabel", {
    Text = "Applies to all song fetches (repo, direct URL, MuseScore, MidiShow, NanoMIDI).",
})

-- ==========================================
-- Direct .mid / MuseScore / MidiShow URL
-- ==========================================
local customMidiUrl = ""

local DirectBox = QuickTab:AddGroupbox({
    Side = "Left",
    Name = "Direct .mid / MuseScore / MidiShow URL",
})

DirectBox:AddInput("CustomMidiUrl", {
    Text = "Direct .mid / Score URL",
    Default = "",
    Placeholder = "https://.../song.mid, musescore.com/.../scores/..., or midishow.com/...",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        customMidiUrl = Text
    end,
})

DirectBox:AddButton({
    Text = "▶️ Download & Play URL",
    Func = function()
        downloadAndPlayUrl(customMidiUrl, "Direct URL", false)
    end,
})

-- ==========================================
-- Playback Controls
-- ==========================================
local PlaybackBox = QuickTab:AddGroupbox({
    Side = "Left",
    Name = "Playback Controls",
})

local ShowPlayerHudToggle = PlaybackBox:AddToggle("ShowPlayerHud", {
    Text = "📺 Show Onscreen Progress Bar",
    Default = true,
    Callback = function(Value)
        PlayerHudState.enabled = Value
    end,
})

PlaybackBox:AddSlider("QuickPlaybackSpeed", {
    Text = "Playback Speed",
    Default = 1,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Suffix = "x",
    Callback = function(Value)
        currentPlaybackSpeed = Value
    end,
})

PlaybackBox:AddButton({
    Text = "⏯️ Pause / Resume",
    Func = togglePausePlayback,
})

PlaybackBox:AddButton({
    Text = "⏹️ Stop",
    Func = stopPlayback,
})

-- ==========================================
-- Velocity, Layout & Articulation (items 1, 2, 5, 6)
-- ==========================================
PlaybackBox:AddSlider("VelocityMin", {
    Text = "Velocity Output Min",
    Default = velocityMin,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        velocityMin = Value
    end,
})

PlaybackBox:AddSlider("VelocityMax", {
    Text = "Velocity Output Max",
    Default = velocityMax,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        velocityMax = Value
    end,
})

PlaybackBox:AddSlider("VelocityCurve", {
    Text = "Velocity Curve (1=linear)",
    Default = 1,
    Min = 0.5,
    Max = 3,
    Rounding = 2,
    Callback = function(Value)
        velocityCurve = Value
    end,
})

PlaybackBox:AddToggle("LegatoToggle", {
    Text = "🎹 Legato (Sustain on Re-trigger)",
    Default = false,
    Tooltip = "When on, re-pressing a held key does not release it first (overlap). When off, re-articulation cuts the previous press.",
    Callback = function(Value)
        legatoMode = Value
    end,
})

PlaybackBox:AddToggle("HighlightNextToggle", {
    Text = "💡 Highlight Next Note",
    Default = false,
    Tooltip = "Flash the upcoming note(s) in the onscreen HUD as they approach.",
    Callback = function(Value)
        PlayerHudState.highlightNext = Value
        if not Value then
            PlayerHudState.nextNoteChars = nil
        end
    end,
})

PlaybackBox:AddDropdown("LayoutSelect", {
    Text = "Keyboard Layout",
    Values = { "Full (60 keys)", "Compact (12 keys)" },
    Default = 1,
    Multi = false,
    Callback = function(Option)
        local choice = type(Option) == "table" and Option[1] or Option
        local layoutName = choice == "Compact (12 keys)" and "compact" or "full"
        if layoutName ~= currentLayoutName then
            currentLayoutName = layoutName
            buildLayout(layoutName)
            notify("Layout Changed", "Keyboard layout: " .. choice, 2)
        end
    end,
})

-- ==========================================
-- Playback History (item 8)
-- ==========================================
local HistoryBox = QuickTab:AddGroupbox({
    Side = "Left",
    Name = "🕘 Playback History",
})

local HistoryDropdown -- forward declared
local HistoryStatusLabel = HistoryBox:AddLabel("HistoryStatusLabel", {
    Text = "History: No songs played yet",
})

local function refreshHistoryDropdown()
    local entries = HistoryState.entries
    local labels = {}
    for _, entry in ipairs(entries) do
        table.insert(labels, string.format("%s [%s]", entry.title, entry.source))
    end

    if #labels == 0 then
        setDropdownOptions(
            HistoryDropdown,
            {},
            "No history yet",
            function(v) HistoryState.suppressCallback = v end
        )
        setLabelSafe(HistoryStatusLabel, "History: No songs played yet")
        return
    end

    setDropdownOptions(
        HistoryDropdown,
        labels,
        labels[1],
        function(v) HistoryState.suppressCallback = v end
    )
    setLabelSafe(HistoryStatusLabel, string.format("History: %d entries (newest first)", #entries))
end

-- Keep history dropdown in sync when playback stops.
registerStopHook(function()
    refreshHistoryDropdown()
end)

HistoryDropdown = HistoryBox:AddDropdown("HistorySelect", {
    Text = "Select a past song",
    Values = {"No history yet"},
    Default = "No history yet",
    Multi = false,
    Searchable = true,
    MaxVisibleDropdownItems = 12,
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        local index = nil
        for i, entry in ipairs(HistoryState.entries) do
            if string.format("%s [%s]", entry.title, entry.source) == chosen then
                index = i
                break
            end
        end
        if index and not HistoryState.suppressCallback then
            local entry = HistoryState.entries[index]
            if entry and entry.replayFn then
                stopPlayback()
                entry.replayFn()
            else
                notify("History", "No replayable entry for this song.", 3)
            end
        end
    end,
})

HistoryBox:AddButton({
    Text = "🔄 Replay Selected",
    Func = function()
        local chosen = HistoryDropdown and HistoryDropdown.Value
        if not chosen or chosen == "No history yet" then
            notify("History", "Pick a song from the history list first.", 3)
            return
        end
        for _, entry in ipairs(HistoryState.entries) do
            if string.format("%s [%s]", entry.title, entry.source) == chosen then
                if entry.replayFn then
                    stopPlayback()
                    entry.replayFn()
                end
                return
            end
        end
    end,
})

HistoryBox:AddButton({
    Text = "🗑️ Clear History",
    Func = function()
        HistoryState.entries = {}
        refreshHistoryDropdown()
        notify("History", "Playback history cleared.", 2)
    end,
})

-- ==========================================
-- Tab 2: Local .mid Files & Text Sheets
-- ==========================================
local LocalBox = LocalTab:AddGroupbox({
    Side = "Left",
    Name = "Local .mid Files (Workspace)",
})

local LocalStatusLabel = LocalBox:AddLabel("LocalStatusLabel", { Text = "Local MIDI: Scanning..." })
local LocalDropdown -- forward declared

local function scanLocalMidiFiles()
    for k in pairs(LocalState.files) do LocalState.files[k] = nil end
    for k in pairs(LocalState.order) do LocalState.order[k] = nil end

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
    local matches, totalMatches = Core.filterSongList(LocalState.order, LocalState.query, MAX_DROPDOWN_ITEMS)
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
        notify("No Local File", "Select a valid .mid file first.", 3)
        return
    end

    local ok, content = pcall(readfile, path)
    if not ok or type(content) ~= "string" then
        warn("[Local MIDI] Failed to read file:", tostring(content))
        notify("Read Failed", tostring(content), 3)
        return
    end

    if not content:find("MThd", 1, true) then
        warn("[Local MIDI] Not a valid MIDI file (missing MThd):", path)
        notify("Invalid MIDI File", "Selected file is missing an MThd MIDI header.", 3)
        return
    end

    stopPlayback()
    local myId = playbackId
    local replayFn = function()
        playLocalSelection(label)
    end
    task.spawn(function()
        local played = parseAndPlayMidi(content, myId, nil, {title = label, subtitle = "Local .mid"}, replayFn)
        if not played and playbackId == myId then
            notify("MIDI Parse Error", "Could not parse the selected local MIDI file.", 4)
        end
    end)
end

LocalBox:AddInput("LocalSearchInput", {
    Text = "🔍 Search Local .mid Files",
    Default = "",
    Placeholder = "Type filename & press Enter (blank = all)",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        LocalState.query = tostring(Text or "")
        applyLocalFilter()
    end,
})

LocalDropdown = LocalBox:AddDropdown("LocalMidiSelect", {
    Text = "Select Local .mid",
    Values = {"Scanning..."},
    Default = "Scanning...",
    Multi = false,
    Searchable = true,
    MaxVisibleDropdownItems = 12,
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

LocalBox:AddToggle("LocalAutoPlayToggle", {
    Text = "⚡ Auto-Play File on Select",
    Default = false,
    Callback = function(Value)
        LocalState.autoPlayOnSelect = Value
    end,
})

LocalBox:AddButton({
    Text = "🔄 Refresh Local .mid Files",
    Func = function()
        scanLocalMidiFiles()
        applyLocalFilter()
        if refreshGlobalSearchResults then
            refreshGlobalSearchResults()
        end
    end,
})

LocalBox:AddButton({
    Text = "▶️ Play Local MIDI",
    Func = function()
        playLocalSelection(LocalState.selected)
    end,
})

-- ==========================================
-- Upload MIDI (item 10: file upload)
-- Try InsertString (executor paste-file API) first; fall back to pasting
-- base64-encoded MIDI data. Either way we get the raw bytes and play them.
-- ==========================================
local UploadBox = LocalTab:AddGroupbox({
    Side = "Left",
    Name = "⬆️ Upload MIDI File",
})

local uploadedMidi = ""

UploadBox:AddInput("UploadMidiInput", {
    Text = "Paste MIDI (base64) or use InsertString",
    Default = "",
    Placeholder = "Paste base64-encoded .mid data here, or click 'Insert File' if your executor supports it",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        uploadedMidi = Text or ""
    end,
})

UploadBox:AddButton({
    Text = "📎 Insert File (InsertString)",
    Tooltip = "Uses the executor's InsertString to grab a file from your clipboard. Falls back to the base64 input if unavailable.",
    Func = function()
        if InsertString then
            local ok, result = pcall(InsertString)
            if ok and type(result) == "string" and result ~= "" then
                uploadedMidi = result
                UploadBox.UploadMidiInput:SetText(result)
            end
        else
            notify("Upload", "InsertString not available in this executor. Paste base64 MIDI data instead.", 4)
        end
    end,
})

local function decodeUploadedMidi(data)
    if data:find("MThd", 1, true) then
        return data
    end
    local midiData = Core.decodeBase64(data)
    if not midiData or midiData == "" then
        return nil
    end
    if not midiData:find("MThd", 1, true) then
        return nil
    end
    return midiData
end

local function playUploadedMidi()
    local data = uploadedMidi
    if data == "" then
        notify("Upload", "No uploaded MIDI data to replay.", 3)
        return
    end
    local midiData = decodeUploadedMidi(data)
    if not midiData then
        notify("Upload", "Could not decode base64 MIDI data for replay.", 4)
        return
    end
    stopPlayback()
    local myId = playbackId
    task.spawn(function()
        parseAndPlayMidi(midiData, myId, nil, {title = "Uploaded MIDI", subtitle = "Upload"}, nil)
    end)
end

UploadBox:AddButton({
    Text = "▶️ Play Uploaded MIDI",
    Func = function()
        if uploadedMidi == "" then
            notify("Upload", "Paste MIDI data (base64) or insert a file first.", 3)
            return
        end
        local midiData = decodeUploadedMidi(uploadedMidi)
        if not midiData then
            notify("Upload", "Could not decode base64 MIDI data.", 4)
            return
        end
        stopPlayback()
        local myId = playbackId
        local title = "Uploaded MIDI"
        local replayFn = function()
            playUploadedMidi()
        end
        recordHistory(title, "Upload", replayFn)
        task.spawn(function()
            local played = parseAndPlayMidi(midiData, myId, nil, {title = title, subtitle = "Upload"}, replayFn)
            if not played and playbackId == myId then
                notify("MIDI Parse Error", "Could not parse the uploaded MIDI data.", 4)
            end
        end)
    end,
})

-- ==========================================
-- Text Sheets
-- ==========================================
local SheetBox = LocalTab:AddGroupbox({
    Side = "Left",
    Name = "Text Sheets",
})

local pastedSheet = ""
local sheetBpm = 120

SheetBox:AddInput("SheetInput", {
    Text = "Paste Text Sheet",
    Default = "",
    Placeholder = "e.g. [tu] y [ro] | a [sd]",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        pastedSheet = Text
    end,
})

SheetBox:AddSlider("SheetBPM", {
    Text = "Text Sheet BPM",
    Default = 120,
    Min = 40,
    Max = 300,
    Rounding = 0,
    Suffix = " BPM",
    Callback = function(Value)
        sheetBpm = Value
    end,
})

SheetBox:AddButton({
    Text = "▶️ Play Pasted Sheet",
    Func = function()
        if pastedSheet == "" then return end
        stopPlayback()
        local myId = playbackId
        local title = "Text Sheet (" .. tostring(sheetBpm) .. " BPM)"
        local replayFn = function()
            stopPlayback()
            local newId = playbackId
            task.spawn(playTextSheet, pastedSheet, sheetBpm, newId, {
                title = title,
                subtitle = "Text Sheet",
            }, replayFn)
        end
        task.spawn(playTextSheet, pastedSheet, sheetBpm, myId, {
            title = title,
            subtitle = "Text Sheet",
        }, replayFn)
    end,
})

SheetBox:AddButton({
    Text = "⏹️ Stop",
    Func = stopPlayback,
})

-- ==========================================
-- Tab 3: NanoMIDI API (Search + Auto-Retry)
-- ==========================================
local NanoBox = NanoTab:AddGroupbox({
    Side = "Left",
    Name = "NanoMIDI Library",
})

local NanoStatusLabel = NanoBox:AddLabel("NanoStatusLabel", { Text = "NanoMIDI: Auto-loading..." })
local NanoDropdown -- forward declared

local function applyNanoFilter()
    if not NanoState.loaded and #NanoState.order == 0 then
        return
    end
    local matches, totalMatches = Core.filterSongList(NanoState.order, NanoState.query, MAX_DROPDOWN_ITEMS)
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
            notify("No Song Selected", "Select a NanoMIDI song first.", 3)
        end
        return
    end

    stopPlayback()
    local myId = playbackId
    setHudLoading(label, "NanoMIDI")

    local replayFn = function()
        playNanoSelection(label, true)
    end

    task.spawn(function()
        local url = "https://api.nanomidi.net/api/midis/" .. Core.encodeUrlPath(tostring(song.midiFilename))
        local ok, midiBody, err = fetchMidiBytesWithRetry(url, NanoState.headers, function()
            return playbackId ~= myId
        end)

        if playbackId ~= myId then return end

        if ok and midiBody then
            local played = parseAndPlayMidi(midiBody, myId, nil, {title = label, subtitle = "NanoMIDI"}, replayFn)
            if not played and playbackId == myId and not silent then
                notify("NanoMIDI Invalid MIDI", "Downloaded file could not be parsed as MIDI.", 4)
            end
        else
            warn("[NanoMIDI] Download failed:", err)
            setHudFailed("Load failed")
            if not silent then
                notify("NanoMIDI Load Failed", tostring(err), 4)
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
                notify("NanoMIDI Load Failed", tostring(err), 4)
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

        for k in pairs(NanoState.apiData) do NanoState.apiData[k] = nil end
        for k in pairs(NanoState.order) do NanoState.order[k] = nil end

        for _, song in ipairs(items) do
            if type(song) == "table" then
                local baseLabel = tostring(song.name or "Untitled") .. " - " .. Core.formatArtists(song.artists)
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

local NanoSearchInput = NanoBox:AddInput("NanoSearchInput", {
    Text = "🔍 Search NanoMIDI",
    Default = "",
    Placeholder = "Search title/artist & press Enter",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        NanoState.query = tostring(Text or "")
        if not NanoState.loaded and not NanoState.loadingList then
            refreshNanoSongs(true)
        end
        applyNanoFilter()
    end,
})

NanoDropdown = NanoBox:AddDropdown("NanoSongSelect", {
    Text = "Select Song",
    Values = {"Fetching..."},
    Default = "Fetching...",
    Multi = false,
    Searchable = true,
    MaxVisibleDropdownItems = 12,
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        NanoState.selected = NanoState.apiData[chosen] and chosen or nil
        if not NanoState.suppressCallback and NanoState.autoPlayOnSelect and NanoState.selected then
            playNanoSelection(NanoState.selected, false)
        end
    end,
})

refreshNanoSongs(true)

NanoBox:AddToggle("NanoAutoPlayToggle", {
    Text = "⚡ Auto-Play Song on Select",
    Default = false,
    Callback = function(Value)
        NanoState.autoPlayOnSelect = Value
    end,
})

NanoBox:AddButton({
    Text = "🔄 Refresh Song List",
    Func = function()
        refreshNanoSongs(false)
    end,
})

NanoBox:AddButton({
    Text = "🔄 Clear Search",
    Func = function()
        NanoState.query = ""
        pcall(function() NanoSearchInput:SetValue("") end)
        applyNanoFilter()
    end,
})

NanoBox:AddButton({
    Text = "▶️ Download & Play",
    Func = function()
        playNanoSelection(NanoState.selected, false)
    end,
})

NanoBox:AddButton({
    Text = "⏹️ Stop",
    Func = stopPlayback,
})

-- ==========================================
-- Tab 4: MuseScore & MidiShow
-- ==========================================
local MuseBox = ExternalTab:AddGroupbox({
    Side = "Left",
    Name = "MuseScore (Search & Direct Score URL)",
})

local MuseStatusLabel = MuseBox:AddLabel("MuseStatusLabel", { Text = "MuseScore: Enter a search term or score URL" })
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
    local target = Core.normalizeMuseScoreInput(rawUrlOrId)
    if not target or not Core.isMuseScoreUrl(target) then
        if not silent then
            notify("Invalid MuseScore Input", "Enter a valid musescore.com URL or numeric score ID.", 3)
        end
        return
    end

    local titleText = tostring(displayName or target)
    stopPlayback()
    local myId = playbackId
    setHudLoading(titleText, "MuseScore")

    local replayFn = function()
        playMuseScoreEntry(target, displayName, silent)
    end

    task.spawn(function()
        MuseState.statusActive = true
        setLabelSafe(MuseStatusLabel, "MuseScore: Loading " .. titleText)
        local ok, midiBody, err = fetchMuseScoreMidi(target, function()
            return playbackId ~= myId
        end)
        if playbackId ~= myId then return end

        if ok and midiBody then
            local played = parseAndPlayMidi(midiBody, myId, function()
                MuseState.statusActive = true
                setLabelSafe(MuseStatusLabel, "MuseScore Playing: " .. titleText)
            end, {title = titleText, subtitle = "MuseScore"}, replayFn)
            if playbackId ~= myId then return end
            if played then
                updateMuseStatusLabel()
            else
                MuseState.statusActive = true
                setLabelSafe(MuseStatusLabel, "MuseScore: Invalid MIDI data")
                if not silent then
                    notify("MuseScore Parse Error", "Downloaded MIDI could not be parsed.", 4)
                end
            end
        else
            MuseState.statusActive = true
            setLabelSafe(MuseStatusLabel, "MuseScore Failed: " .. tostring(err))
            setHudFailed("Load failed")
            if not silent then
                notify("MuseScore Load Failed", tostring(err), 4)
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
        for k in pairs(MuseState.map) do MuseState.map[k] = nil end
        for k in pairs(MuseState.order) do MuseState.order[k] = nil end
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
                notify("MuseScore Search Failed", tostring(err), 4)
            end
            return
        end

        for k in pairs(MuseState.map) do MuseState.map[k] = nil end
        for k in pairs(MuseState.order) do MuseState.order[k] = nil end

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

local MuseSearchInput = MuseBox:AddInput("MuseSearchInput", {
    Text = "🔍 Search MuseScore",
    Default = "",
    Placeholder = "Search score title & press Enter",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        runMuseSearch(Text, false)
    end,
})

MuseBox:AddButton({
    Text = "🔄 Clear MuseScore Search",
    Func = function()
        pcall(function() MuseSearchInput:SetValue("") end)
        runMuseSearch("", false)
    end,
})

MuseDropdown = MuseBox:AddDropdown("MuseScoreSelect", {
    Text = "MuseScore Results",
    Values = {"Search MuseScore above"},
    Default = "Search MuseScore above",
    Multi = false,
    Searchable = true,
    MaxVisibleDropdownItems = 12,
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        MuseState.selected = MuseState.map[chosen] and chosen or nil
        if not MuseState.suppressCallback and MuseState.autoPlayOnSelect and MuseState.selected then
            playMuseScoreEntry(MuseState.map[MuseState.selected], MuseState.selected, false)
        end
    end,
})

MuseBox:AddToggle("MuseAutoPlayToggle", {
    Text = "⚡ Auto-Play MuseScore on Select",
    Default = false,
    Callback = function(Value)
        MuseState.autoPlayOnSelect = Value
    end,
})

MuseBox:AddButton({
    Text = "▶️ Play Selected MuseScore",
    Func = function()
        local url = MuseState.selected and MuseState.map[MuseState.selected]
        if not url then
            notify("No Score Selected", "Search and select a MuseScore result first.", 3)
            return
        end
        playMuseScoreEntry(url, MuseState.selected, false)
    end,
})

MuseBox:AddButton({
    Text = "⚡ Auto-Try MuseScore Results",
    Func = function()
        if #MuseState.order == 0 then
            notify("No Results", "Search MuseScore first.", 3)
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
                setHudLoading(entry.label, string.format("MuseScore (%d/%d)", idx, #candidates))
                local ok, midiBody = fetchMuseScoreMidi(entry.url, function()
                    return playbackId ~= myId
                end)
                if playbackId ~= myId then return end
                if ok and midiBody then
                    local replayFn = function()
                        playMuseScoreEntry(entry.url, entry.label, true)
                    end
                    local played = parseAndPlayMidi(midiBody, myId, function()
                        MuseState.statusActive = true
                        setLabelSafe(MuseStatusLabel, "MuseScore Playing: " .. entry.label)
                        notify("MuseScore Playing", entry.label, 3)
                    end, {title = entry.label, subtitle = "MuseScore"}, replayFn)
                    if playbackId ~= myId then return end
                    if played then
                        updateMuseStatusLabel()
                        return
                    end
                end
            end
            if playbackId == myId then
                setHudFailed("No playable MuseScore MIDI found")
                updateMuseStatusLabel()
                notify("MuseScore Auto-Try Failed", "No playable MIDI found in current results.", 4)
            end
        end)
    end,
})

local customMuseUrl = ""
MuseBox:AddInput("CustomMuseUrl", {
    Text = "MuseScore URL or Score ID",
    Default = "",
    Placeholder = "https://musescore.com/user/.../scores/5352121 or 5352121",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        customMuseUrl = Text
    end,
})

MuseBox:AddButton({
    Text = "▶️ Play MuseScore URL / ID",
    Func = function()
        playMuseScoreEntry(customMuseUrl, nil, false)
    end,
})

local MidiShowBox = ExternalTab:AddGroupbox({
    Side = "Left",
    Name = "MidiShow (Search & Direct MIDI URL)",
})

local MidiShowStatusLabel = MidiShowBox:AddLabel("MidiShowStatusLabel", { Text = "MidiShow: Enter a search term or midishow.com URL" })
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
    local target = Core.normalizeMidiShowInput(rawUrlOrId)
    if not target or not Core.isMidiShowUrl(target) then
        if not silent then
            notify("Invalid MidiShow Input", "Enter a valid midishow.com URL or numeric MIDI ID.", 3)
        end
        return
    end

    local titleText = tostring(displayName or target)
    stopPlayback()
    local myId = playbackId
    setHudLoading(titleText, "MidiShow")

    local replayFn = function()
        playMidiShowEntry(target, displayName, silent)
    end

    task.spawn(function()
        MidiShowState.statusActive = true
        setLabelSafe(MidiShowStatusLabel, "MidiShow: Loading " .. titleText)
        local ok, midiBody, err = fetchMidiShowMidi(target, function()
            return playbackId ~= myId
        end)
        if playbackId ~= myId then return end

        if ok and midiBody then
            local played = parseAndPlayMidi(midiBody, myId, function()
                MidiShowState.statusActive = true
                setLabelSafe(MidiShowStatusLabel, "MidiShow Playing: " .. titleText)
            end, {title = titleText, subtitle = "MidiShow"}, replayFn)
            if playbackId ~= myId then return end
            if played then
                updateMidiShowStatusLabel()
            else
                MidiShowState.statusActive = true
                setLabelSafe(MidiShowStatusLabel, "MidiShow: Invalid MIDI data")
                if not silent then
                    notify("MidiShow Parse Error", "Decoded MIDI could not be parsed.", 4)
                end
            end
        else
            MidiShowState.statusActive = true
            setLabelSafe(MidiShowStatusLabel, "MidiShow Failed: " .. tostring(err))
            setHudFailed("Load failed")
            if not silent then
                notify("MidiShow Load Failed", tostring(err), 5)
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
        for k in pairs(MidiShowState.map) do MidiShowState.map[k] = nil end
        for k in pairs(MidiShowState.order) do MidiShowState.order[k] = nil end
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
                notify("MidiShow Search Failed", tostring(err), 5)
            end
            return
        end

        for k in pairs(MidiShowState.map) do MidiShowState.map[k] = nil end
        for k in pairs(MidiShowState.order) do MidiShowState.order[k] = nil end

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

local MidiShowSearchInput = MidiShowBox:AddInput("MidiShowSearchInput", {
    Text = "🔍 Search MidiShow",
    Default = "",
    Placeholder = "Search midishow.com & press Enter",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        runMidiShowSearch(Text, false)
    end,
})

MidiShowBox:AddButton({
    Text = "🔄 Clear MidiShow Search",
    Func = function()
        pcall(function() MidiShowSearchInput:SetValue("") end)
        runMidiShowSearch("", false)
    end,
})

MidiShowDropdown = MidiShowBox:AddDropdown("MidiShowSelect", {
    Text = "MidiShow Results",
    Values = {"Search MidiShow above"},
    Default = "Search MidiShow above",
    Multi = false,
    Searchable = true,
    MaxVisibleDropdownItems = 12,
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        MidiShowState.selected = MidiShowState.map[chosen] and chosen or nil
        if not MidiShowState.suppressCallback and MidiShowState.autoPlayOnSelect and MidiShowState.selected then
            playMidiShowEntry(MidiShowState.map[MidiShowState.selected], MidiShowState.selected, false)
        end
    end,
})

MidiShowBox:AddToggle("MidiShowAutoPlayToggle", {
    Text = "⚡ Auto-Play MidiShow on Select",
    Default = false,
    Callback = function(Value)
        MidiShowState.autoPlayOnSelect = Value
    end,
})

MidiShowBox:AddButton({
    Text = "▶️ Play Selected MidiShow",
    Func = function()
        local url = MidiShowState.selected and MidiShowState.map[MidiShowState.selected]
        if not url then
            notify("No MIDI Selected", "Search and select a MidiShow result first.", 3)
            return
        end
        playMidiShowEntry(url, MidiShowState.selected, false)
    end,
})

MidiShowBox:AddButton({
    Text = "⚡ Auto-Try MidiShow Results",
    Func = function()
        if #MidiShowState.order == 0 then
            notify("No Results", "Search MidiShow first.", 3)
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
                setHudLoading(entry.label, string.format("MidiShow (%d/%d)", idx, #candidates))
                local ok, midiBody = fetchMidiShowMidi(entry.url, function()
                    return playbackId ~= myId
                end)
                if playbackId ~= myId then return end
                if ok and midiBody then
                    local replayFn = function()
                        playMidiShowEntry(entry.url, entry.label, true)
                    end
                    local played = parseAndPlayMidi(midiBody, myId, function()
                        MidiShowState.statusActive = true
                        setLabelSafe(MidiShowStatusLabel, "MidiShow Playing: " .. entry.label)
                        notify("MidiShow Playing", entry.label, 3)
                    end, {title = entry.label, subtitle = "MidiShow"}, replayFn)
                    if playbackId ~= myId then return end
                    if played then
                        updateMidiShowStatusLabel()
                        return
                    end
                end
            end
            if playbackId == myId then
                setHudFailed("No playable MidiShow MIDI found")
                updateMidiShowStatusLabel()
                notify("MidiShow Auto-Try Failed", "No playable MIDI found in current results.", 4)
            end
        end)
    end,
})

local customMidiShowUrl = ""
MidiShowBox:AddInput("CustomMidiShowUrl", {
    Text = "MidiShow URL or MIDI ID",
    Default = "",
    Placeholder = "https://www.midishow.com/en/midi/36409.html or 36409",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        customMidiShowUrl = Text
    end,
})

MidiShowBox:AddButton({
    Text = "▶️ Play MidiShow URL / ID",
    Func = function()
        playMidiShowEntry(customMidiShowUrl, nil, false)
    end,
})

MidiShowBox:AddInput("MidiShowCookieInput", {
    Text = "MidiShow Cookie (Optional, if 403/Cloudflare)",
    Default = "",
    Placeholder = "Paste midishow.com Cookie header if required",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(Text)
        MidiShowState.cookie = tostring(Text or ""):match("^%s*(.-)%s*$")
    end,
})

MidiShowBox:AddButton({
    Text = "⏹️ Stop",
    Func = stopPlayback,
})

-- ==========================================
-- Tab 5: Global Search & Auto-Try Across All Sources
-- ==========================================
local GlobalBox = GlobalTab:AddGroupbox({
    Side = "Left",
    Name = "Search All Sources (Local + Quick Picks + NanoMIDI + MuseScore + MidiShow)",
})

local GlobalStatusLabel = GlobalBox:AddLabel("GlobalStatusLabel", { Text = "Global Search: Enter a song name to search all sources" })
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
        if not Core.matchesQuery(label, query) then return end
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
        entry.source = sourceTag
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
                url = "https://api.nanomidi.net/api/midis/" .. Core.encodeUrlPath(tostring(song.midiFilename)),
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

local GlobalSearchInput = GlobalBox:AddInput("GlobalSearchInput", {
    Text = "🔍 Search All Songs",
    Default = "",
    Placeholder = "e.g. unravel, megalovania, chopin (press Enter)",
    ClearTextOnFocus = false,
    Finished = true,
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

GlobalBox:AddToggle("GlobalLiveExternalToggle", {
    Text = "🌐 Live Search MuseScore & MidiShow",
    Default = true,
    Callback = function(Value)
        GlobalState.liveExternalSearch = Value
    end,
})

GlobalDropdown = GlobalBox:AddDropdown("GlobalSongSelect", {
    Text = "Matching Songs",
    Values = {"Loading..."},
    Default = "Loading...",
    Multi = false,
    Searchable = true,
    MaxVisibleDropdownItems = 12,
    Callback = function(Option)
        local chosen = type(Option) == "table" and Option[1] or Option
        GlobalState.selected = GlobalState.resultsMap[chosen] and chosen or nil
    end,
})

refreshGlobalSearchResults()

local function globalPlayEntry(entry)
    stopPlayback()
    local myId = playbackId
    setHudLoading(entry.label or entry.display, entry.source or "Global Search")

    local replayFn
    if entry.kind == "local" then
        replayFn = function()
            playLocalSelection(entry.label)
        end
    else
        replayFn = function()
            globalPlayEntry(entry)
        end
    end

    task.spawn(function()
        GlobalState.statusActive = true
        setLabelSafe(GlobalStatusLabel, "Loading: " .. entry.display)
        local ok, midiBody = tryLoadGlobalEntry(entry, myId)
        if playbackId ~= myId then return end

        if ok and midiBody then
            local played = parseAndPlayMidi(midiBody, myId, function()
                GlobalState.statusActive = true
                setLabelSafe(GlobalStatusLabel, "Playing: " .. entry.display)
            end, {title = entry.label or entry.display, subtitle = entry.source or "Global Search"}, replayFn)
            if playbackId ~= myId then return end
            if played then
                updateGlobalStatusLabel()
            else
                GlobalState.statusActive = true
                setLabelSafe(GlobalStatusLabel, "Invalid MIDI: " .. entry.display)
                notify("MIDI Parse Error", "Try 'Auto-Try Matching Songs' to test other sources.", 4)
            end
        else
            GlobalState.statusActive = true
            setLabelSafe(GlobalStatusLabel, "Failed: " .. entry.display)
            setHudFailed("Load failed")
            notify("Song Load Failed", "Try 'Auto-Try Matching Songs' to test other sources.", 4)
        end
    end)
end

GlobalBox:AddButton({
    Text = "▶️ Play Selected Match",
    Func = function()
        local entry = GlobalState.selected and GlobalState.resultsMap[GlobalState.selected]
        if not entry then
            notify("No Song Selected", "Search and select a song first.", 3)
            return
        end
        globalPlayEntry(entry)
    end,
})

GlobalBox:AddButton({
    Text = "⚡ Auto-Try Matching Songs (Find Working)",
    Func = function()
        if #GlobalState.resultsOrder == 0 then
            notify("No Matches", "No songs matched your search.", 3)
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
                setHudLoading(entry.label or entry.display, string.format("%s (%d/%d)", entry.source or "Global", idx, #queue))
                local ok, midiBody = tryLoadGlobalEntry(entry, myId)
                if playbackId ~= myId then return end

                if ok and midiBody then
                    local replayFn = function()
                        globalPlayEntry(entry)
                    end
                    local played = parseAndPlayMidi(midiBody, myId, function()
                        GlobalState.statusActive = true
                        setLabelSafe(GlobalStatusLabel, "Playing: " .. entry.display)
                        notify("Auto-Loaded & Playing", entry.display, 3)
                    end, {title = entry.label or entry.display, subtitle = entry.source or "Global Search"}, replayFn)
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
                setHudFailed("No working MIDI found")
                notify("Auto-Try Failed", "None of the matching entries returned valid MIDI.", 4)
            end
        end)
    end,
})

GlobalBox:AddButton({
    Text = "🔄 Reload All Song Sources",
    Func = function()
        scanLocalMidiFiles()
        applyLocalFilter()
        fetchFromRepoUrl(QuickState.repoUrl, false)
        refreshNanoSongs(false)
        refreshGlobalSearchResults()
    end,
})

GlobalBox:AddButton({
    Text = "🔄 Clear Search",
    Func = function()
        GlobalState.query = ""
        pcall(function() GlobalSearchInput:SetValue("") end)
        refreshGlobalSearchResults()
    end,
})

GlobalBox:AddButton({
    Text = "⏹️ Stop",
    Func = stopPlayback,
})

-- ==========================================
-- Onscreen Spotify-Style Player Progress Bar HUD
-- ==========================================
local function getHudContainer()
    local ok, hiddenUi = pcall(function()
        return gethui and gethui()
    end)
    if ok and typeof(hiddenUi) == "Instance" then
        return hiddenUi
    end
    local cgOk = pcall(function()
        local _ = CoreGui.Name
    end)
    if cgOk then
        return CoreGui
    end
    local lp = Players.LocalPlayer
    if lp then
        return lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
    end
    return nil
end

local function createOnscreenPlayerHud()
    local parentContainer = getHudContainer()
    if not parentContainer then
        warn("[Piano] Could not find GUI container for onscreen player bar")
        return
    end

    local existing = parentContainer:FindFirstChild("UniversalPianoPlayerHUD")
    if existing then
        pcall(function() existing:Destroy() end)
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UniversalPianoPlayerHUD"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 50
    screenGui.Parent = parentContainer

    local hudFrame = Instance.new("Frame")
    hudFrame.Name = "PlayerBar"
    hudFrame.AnchorPoint = Vector2.new(0.5, 1)
    hudFrame.Position = UDim2.new(0.5, 0, 1, -18)
    hudFrame.Size = UDim2.new(0.62, 0, 0, 74)
    hudFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
    hudFrame.BackgroundTransparency = 0.05
    hudFrame.BorderSizePixel = 0
    hudFrame.Active = true
    hudFrame.Parent = screenGui

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(360, 70)
    sizeConstraint.MaxSize = Vector2.new(740, 78)
    sizeConstraint.Parent = hudFrame

    local hudCorner = Instance.new("UICorner")
    hudCorner.CornerRadius = UDim.new(0, 12)
    hudCorner.Parent = hudFrame

    local hudStroke = Instance.new("UIStroke")
    hudStroke.Color = Color3.fromRGB(48, 48, 56)
    hudStroke.Thickness = 1
    hudStroke.Parent = hudFrame

    local hudPad = Instance.new("UIPadding")
    hudPad.PaddingLeft = UDim.new(0, 12)
    hudPad.PaddingRight = UDim.new(0, 12)
    hudPad.PaddingTop = UDim.new(0, 7)
    hudPad.PaddingBottom = UDim.new(0, 7)
    hudPad.Parent = hudFrame

    -- Left Section: Album-style music icon + Title / Subtitle
    local leftSection = Instance.new("Frame")
    leftSection.Name = "TrackInfo"
    leftSection.Size = UDim2.new(0.30, -8, 1, 0)
    leftSection.BackgroundTransparency = 1
    leftSection.Parent = hudFrame

    local artBox = Instance.new("Frame")
    artBox.Name = "ArtBadge"
    artBox.AnchorPoint = Vector2.new(0, 0.5)
    artBox.Position = UDim2.new(0, 0, 0.5, 0)
    artBox.Size = UDim2.new(0, 40, 0, 40)
    artBox.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    artBox.BorderSizePixel = 0
    artBox.Parent = leftSection

    local artCorner = Instance.new("UICorner")
    artCorner.CornerRadius = UDim.new(0, 7)
    artCorner.Parent = artBox

    local artStroke = Instance.new("UIStroke")
    artStroke.Color = Color3.fromRGB(58, 58, 66)
    artStroke.Thickness = 1
    artStroke.Parent = artBox

    local artGlyph = Instance.new("TextLabel")
    artGlyph.Size = UDim2.new(1, 0, 1, 0)
    artGlyph.BackgroundTransparency = 1
    artGlyph.Text = "♫"
    artGlyph.Font = Enum.Font.GothamBold
    artGlyph.TextSize = 18
    artGlyph.TextColor3 = Color3.fromRGB(235, 235, 242)
    artGlyph.Parent = artBox

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Position = UDim2.new(0, 48, 0, 10)
    titleLabel.Size = UDim2.new(1, -48, 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "No song playing"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = Color3.fromRGB(248, 248, 250)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = leftSection

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Position = UDim2.new(0, 48, 0, 29)
    subtitleLabel.Size = UDim2.new(1, -48, 0, 16)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Select a song to start"
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextSize = 11
    subtitleLabel.TextColor3 = Color3.fromRGB(165, 165, 175)
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    subtitleLabel.Parent = leftSection

    -- Next-note highlight badge (shown when highlight-next is enabled).
    local nextNoteLabel = Instance.new("TextLabel")
    nextNoteLabel.Name = "NextNoteLabel"
    nextNoteLabel.Position = UDim2.new(0, 48, 0, 47)
    nextNoteLabel.Size = UDim2.new(1, -48, 0, 16)
    nextNoteLabel.BackgroundTransparency = 1
    nextNoteLabel.Text = ""
    nextNoteLabel.Font = Enum.Font.GothamBold
    nextNoteLabel.TextSize = 11
    nextNoteLabel.TextColor3 = Color3.fromRGB(86, 180, 255)
    nextNoteLabel.TextXAlignment = Enum.TextXAlignment.Left
    nextNoteLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nextNoteLabel.Visible = false
    nextNoteLabel.Parent = leftSection

    -- Center Section: Transport buttons + Elapsed / Progress Bar / Total Length
    local centerSection = Instance.new("Frame")
    centerSection.Name = "CenterControls"
    centerSection.Position = UDim2.new(0.30, 0, 0, 0)
    centerSection.Size = UDim2.new(0.54, 0, 1, 0)
    centerSection.BackgroundTransparency = 1
    centerSection.Parent = hudFrame

    local controlsRow = Instance.new("Frame")
    controlsRow.Name = "TransportRow"
    controlsRow.Size = UDim2.new(1, 0, 0, 32)
    controlsRow.BackgroundTransparency = 1
    controlsRow.Parent = centerSection

    local controlsLayout = Instance.new("UIListLayout")
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlsLayout.Padding = UDim.new(0, 14)
    controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    controlsLayout.Parent = controlsRow

    -- Restart Button (|<)
    local restartBtn = Instance.new("TextButton")
    restartBtn.Name = "RestartButton"
    restartBtn.LayoutOrder = 1
    restartBtn.Size = UDim2.new(0, 26, 0, 26)
    restartBtn.BackgroundTransparency = 1
    restartBtn.Text = ""
    restartBtn.AutoButtonColor = false
    restartBtn.Parent = controlsRow

    local restartBar = Instance.new("Frame")
    restartBar.AnchorPoint = Vector2.new(0, 0.5)
    restartBar.Position = UDim2.new(0, 5, 0.5, 0)
    restartBar.Size = UDim2.new(0, 2, 0, 10)
    restartBar.BackgroundColor3 = Color3.fromRGB(190, 190, 200)
    restartBar.BorderSizePixel = 0
    restartBar.Parent = restartBtn

    local restartArrow = Instance.new("TextLabel")
    restartArrow.AnchorPoint = Vector2.new(0, 0.5)
    restartArrow.Position = UDim2.new(0, 8, 0.5, 0)
    restartArrow.Size = UDim2.new(0, 14, 0, 14)
    restartArrow.BackgroundTransparency = 1
    restartArrow.Text = "◀"
    restartArrow.Font = Enum.Font.GothamBold
    restartArrow.TextSize = 11
    restartArrow.TextColor3 = Color3.fromRGB(190, 190, 200)
    restartArrow.Parent = restartBtn

    -- Play / Pause White Circle Button
    local playPauseBtn = Instance.new("TextButton")
    playPauseBtn.Name = "PlayPauseButton"
    playPauseBtn.LayoutOrder = 2
    playPauseBtn.Size = UDim2.new(0, 30, 0, 30)
    playPauseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    playPauseBtn.Text = ""
    playPauseBtn.AutoButtonColor = false
    playPauseBtn.Parent = controlsRow

    local ppCorner = Instance.new("UICorner")
    ppCorner.CornerRadius = UDim.new(1, 0)
    ppCorner.Parent = playPauseBtn

    local playGlyph = Instance.new("TextLabel")
    playGlyph.Name = "PlayGlyph"
    playGlyph.Size = UDim2.new(1, 0, 1, 0)
    playGlyph.Position = UDim2.new(0, 1, 0, 0)
    playGlyph.BackgroundTransparency = 1
    playGlyph.Text = "▶"
    playGlyph.Font = Enum.Font.GothamBold
    playGlyph.TextSize = 13
    playGlyph.TextColor3 = Color3.fromRGB(16, 16, 18)
    playGlyph.Parent = playPauseBtn

    local pauseGlyph = Instance.new("Frame")
    pauseGlyph.Name = "PauseGlyph"
    pauseGlyph.Size = UDim2.new(1, 0, 1, 0)
    pauseGlyph.BackgroundTransparency = 1
    pauseGlyph.Visible = false
    pauseGlyph.Parent = playPauseBtn

    local pBar1 = Instance.new("Frame")
    pBar1.AnchorPoint = Vector2.new(0.5, 0.5)
    pBar1.Position = UDim2.new(0.5, -3, 0.5, 0)
    pBar1.Size = UDim2.new(0, 3, 0, 11)
    pBar1.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
    pBar1.BorderSizePixel = 0
    pBar1.Parent = pauseGlyph

    local pBar2 = Instance.new("Frame")
    pBar2.AnchorPoint = Vector2.new(0.5, 0.5)
    pBar2.Position = UDim2.new(0.5, 3, 0.5, 0)
    pBar2.Size = UDim2.new(0, 3, 0, 11)
    pBar2.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
    pBar2.BorderSizePixel = 0
    pBar2.Parent = pauseGlyph

    -- Stop Button (square)
    local stopBtn = Instance.new("TextButton")
    stopBtn.Name = "StopButton"
    stopBtn.LayoutOrder = 3
    stopBtn.Size = UDim2.new(0, 26, 0, 26)
    stopBtn.BackgroundTransparency = 1
    stopBtn.Text = ""
    stopBtn.AutoButtonColor = false
    stopBtn.Parent = controlsRow

    local stopSquare = Instance.new("Frame")
    stopSquare.AnchorPoint = Vector2.new(0.5, 0.5)
    stopSquare.Position = UDim2.new(0.5, 0, 0.5, 0)
    stopSquare.Size = UDim2.new(0, 10, 0, 10)
    stopSquare.BackgroundColor3 = Color3.fromRGB(190, 190, 200)
    stopSquare.BorderSizePixel = 0
    stopSquare.Parent = stopBtn

    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0, 2)
    stopCorner.Parent = stopSquare

    -- Progress Bar Row
    local progressRow = Instance.new("Frame")
    progressRow.Name = "ProgressRow"
    progressRow.Position = UDim2.new(0, 0, 0, 34)
    progressRow.Size = UDim2.new(1, 0, 0, 24)
    progressRow.BackgroundTransparency = 1
    progressRow.Parent = centerSection

    local elapsedLabel = Instance.new("TextLabel")
    elapsedLabel.Name = "Elapsed"
    elapsedLabel.Size = UDim2.new(0, 42, 1, 0)
    elapsedLabel.BackgroundTransparency = 1
    elapsedLabel.Text = "0:00"
    elapsedLabel.Font = Enum.Font.GothamMedium
    elapsedLabel.TextSize = 11
    elapsedLabel.TextColor3 = Color3.fromRGB(175, 175, 185)
    elapsedLabel.TextXAlignment = Enum.TextXAlignment.Right
    elapsedLabel.Parent = progressRow

    local trackHitArea = Instance.new("TextButton")
    trackHitArea.Name = "TrackHitArea"
    trackHitArea.Position = UDim2.new(0, 48, 0, 0)
    trackHitArea.Size = UDim2.new(1, -96, 1, 0)
    trackHitArea.BackgroundTransparency = 1
    trackHitArea.Text = ""
    trackHitArea.AutoButtonColor = false
    trackHitArea.Parent = progressRow

    local trackBg = Instance.new("Frame")
    trackBg.Name = "TrackBg"
    trackBg.AnchorPoint = Vector2.new(0, 0.5)
    trackBg.Position = UDim2.new(0, 0, 0.5, 0)
    trackBg.Size = UDim2.new(1, 0, 0, 4)
    trackBg.BackgroundColor3 = Color3.fromRGB(68, 68, 76)
    trackBg.BorderSizePixel = 0
    trackBg.Parent = trackHitArea

    local trackBgCorner = Instance.new("UICorner")
    trackBgCorner.CornerRadius = UDim.new(1, 0)
    trackBgCorner.Parent = trackBg

    local trackFill = Instance.new("Frame")
    trackFill.Name = "TrackFill"
    trackFill.Size = UDim2.new(0, 0, 1, 0)
    trackFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    trackFill.BorderSizePixel = 0
    trackFill.Parent = trackBg

    local trackFillCorner = Instance.new("UICorner")
    trackFillCorner.CornerRadius = UDim.new(1, 0)
    trackFillCorner.Parent = trackFill

    local trackKnob = Instance.new("Frame")
    trackKnob.Name = "TrackKnob"
    trackKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    trackKnob.Position = UDim2.new(0, 0, 0.5, 0)
    trackKnob.Size = UDim2.new(0, 11, 0, 11)
    trackKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    trackKnob.BorderSizePixel = 0
    trackKnob.Visible = false
    trackKnob.ZIndex = 3
    trackKnob.Parent = trackBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = trackKnob

    local totalLabel = Instance.new("TextLabel")
    totalLabel.Name = "Total"
    totalLabel.AnchorPoint = Vector2.new(1, 0)
    totalLabel.Position = UDim2.new(1, 0, 0, 0)
    totalLabel.Size = UDim2.new(0, 42, 1, 0)
    totalLabel.BackgroundTransparency = 1
    totalLabel.Text = "0:00"
    totalLabel.Font = Enum.Font.GothamMedium
    totalLabel.TextSize = 11
    totalLabel.TextColor3 = Color3.fromRGB(175, 175, 185)
    totalLabel.TextXAlignment = Enum.TextXAlignment.Left
    totalLabel.Parent = progressRow

    -- Right Section: Speed badge & Hide button
    local rightSection = Instance.new("Frame")
    rightSection.Name = "RightUtility"
    rightSection.AnchorPoint = Vector2.new(1, 0)
    rightSection.Position = UDim2.new(1, 0, 0, 0)
    rightSection.Size = UDim2.new(0.16, -6, 1, 0)
    rightSection.BackgroundTransparency = 1
    rightSection.Parent = hudFrame

    local speedBadge = Instance.new("TextLabel")
    speedBadge.Name = "SpeedBadge"
    speedBadge.AnchorPoint = Vector2.new(0, 0.5)
    speedBadge.Position = UDim2.new(0, 2, 0.5, 0)
    speedBadge.Size = UDim2.new(1, -28, 0, 22)
    speedBadge.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    speedBadge.Text = "1.0x"
    speedBadge.Font = Enum.Font.GothamMedium
    speedBadge.TextSize = 11
    speedBadge.TextColor3 = Color3.fromRGB(205, 205, 215)
    speedBadge.Parent = rightSection

    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 6)
    speedCorner.Parent = speedBadge

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "HideHudButton"
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = rightSection

    -- Button Hover & Click Handlers
    local barHovered = false
    trackHitArea.MouseEnter:Connect(function()
        barHovered = true
        trackFill.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
    end)
    trackHitArea.MouseLeave:Connect(function()
        barHovered = false
        if not PlayerHudState.draggingBar then
            trackFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)

    restartBtn.MouseEnter:Connect(function()
        restartBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        restartArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    restartBtn.MouseLeave:Connect(function()
        restartBar.BackgroundColor3 = Color3.fromRGB(190, 190, 200)
        restartArrow.TextColor3 = Color3.fromRGB(190, 190, 200)
    end)
    restartBtn.MouseButton1Click:Connect(function()
        if PlayerHudState.replayFn then
            PlayerHudState.replayFn()
        end
    end)

    playPauseBtn.MouseEnter:Connect(function()
        playPauseBtn.Size = UDim2.new(0, 32, 0, 32)
    end)
    playPauseBtn.MouseLeave:Connect(function()
        playPauseBtn.Size = UDim2.new(0, 30, 0, 30)
    end)
    playPauseBtn.MouseButton1Click:Connect(function()
        togglePausePlayback()
    end)

    stopBtn.MouseEnter:Connect(function()
        stopSquare.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end)
    stopBtn.MouseLeave:Connect(function()
        stopSquare.BackgroundColor3 = Color3.fromRGB(190, 190, 200)
    end)
    stopBtn.MouseButton1Click:Connect(function()
        stopPlayback()
    end)

    closeBtn.MouseEnter:Connect(function()
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        PlayerHudState.enabled = false
        pcall(function()
            ShowPlayerHudToggle:SetValue(false)
        end)
    end)

    -- Progress Bar Seeking (Click & Drag)
    local function computeSeekTime(screenX)
        local width = trackBg.AbsoluteSize.X
        if width <= 0 or PlayerHudState.totalTime <= 0 then
            return 0
        end
        local frac = math.clamp((screenX - trackBg.AbsolutePosition.X) / width, 0, 1)
        return frac * PlayerHudState.totalTime
    end

    trackHitArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if PlayerHudState.totalTime > 0 and (PlayerHudState.status == "playing" or PlayerHudState.status == "paused") then
                PlayerHudState.draggingBar = true
                PlayerHudState.dragPreviewTime = computeSeekTime(input.Position.X)
                trackFill.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
            end
        end
    end)

    -- HUD Window Dragging (only when clicking non-control background area)
    local function isPointInGui(guiObj, x, y)
        local pos = guiObj.AbsolutePosition
        local size = guiObj.AbsoluteSize
        return x >= pos.X and x <= pos.X + size.X and y >= pos.Y and y <= pos.Y + size.Y
    end

    local draggingHud = false
    local dragStartPos = nil
    local hudStartPos = nil

    hudFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local px, py = input.Position.X, input.Position.Y
            if isPointInGui(trackHitArea, px, py)
                or isPointInGui(playPauseBtn, px, py)
                or isPointInGui(restartBtn, px, py)
                or isPointInGui(stopBtn, px, py)
                or isPointInGui(closeBtn, px, py) then
                return
            end
            draggingHud = true
            dragStartPos = input.Position
            hudStartPos = hudFrame.Position
        end
    end)

    local inputChangedConn
    local inputEndedConn
    local renderConn

    inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if not screenGui.Parent then
            if inputChangedConn then inputChangedConn:Disconnect() end
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if PlayerHudState.draggingBar then
                PlayerHudState.dragPreviewTime = computeSeekTime(input.Position.X)
            elseif draggingHud and dragStartPos and hudStartPos then
                local delta = input.Position - dragStartPos
                hudFrame.Position = UDim2.new(
                    hudStartPos.X.Scale,
                    hudStartPos.X.Offset + delta.X,
                    hudStartPos.Y.Scale,
                    hudStartPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if not screenGui.Parent then
            if inputEndedConn then inputEndedConn:Disconnect() end
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if PlayerHudState.draggingBar then
                PlayerHudState.draggingBar = false
                if not barHovered then
                    trackFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                end
                -- Seek commits while playing OR paused: the playback loop
                -- applies seekTarget in both states, so the preview should
                -- never snap back when the song is paused.
                if PlayerHudState.totalTime > 0
                    and (PlayerHudState.status == "playing" or PlayerHudState.status == "paused") then
                    PlayerHudState.seekTarget = PlayerHudState.dragPreviewTime
                end
            end
            draggingHud = false
        end
    end)

    -- 60fps HUD Render Loop
    renderConn = RunService.RenderStepped:Connect(function()
        if not screenGui.Parent then
            if renderConn then renderConn:Disconnect() end
            if inputChangedConn then inputChangedConn:Disconnect() end
            if inputEndedConn then inputEndedConn:Disconnect() end
            return
        end

        hudFrame.Visible = PlayerHudState.enabled == true
        if not hudFrame.Visible then
            return
        end

        titleLabel.Text = PlayerHudState.title

        local statusPrefix = ""
        if PlayerHudState.status == "paused" then
            statusPrefix = "Paused · "
        elseif PlayerHudState.status == "stopped" then
            statusPrefix = "Stopped · "
        elseif PlayerHudState.status == "finished" then
            statusPrefix = "Finished · "
        end
        subtitleLabel.Text = statusPrefix .. PlayerHudState.subtitle

        -- Next-note highlight badge.
        if PlayerHudState.highlightNext and PlayerHudState.nextNoteChars then
            nextNoteLabel.Visible = true
            nextNoteLabel.Text = "Next: " .. table.concat(PlayerHudState.nextNoteChars, " ")
        else
            nextNoteLabel.Visible = false
        end

        local isPlayingNow = (PlayerHudState.status == "playing")
        playGlyph.Visible = not isPlayingNow
        pauseGlyph.Visible = isPlayingNow

        local total = PlayerHudState.totalTime
        local shownCurrent = PlayerHudState.draggingBar and PlayerHudState.dragPreviewTime or PlayerHudState.currentTime
        if total > 0 then
            shownCurrent = math.clamp(shownCurrent, 0, total)
        else
            shownCurrent = 0
        end

        elapsedLabel.Text = formatDuration(shownCurrent)
        totalLabel.Text = formatDuration(total)

        local frac = total > 0 and math.clamp(shownCurrent / total, 0, 1) or 0
        trackFill.Size = UDim2.new(frac, 0, 1, 0)
        trackKnob.Position = UDim2.new(frac, 0, 0.5, 0)
        trackKnob.Visible = (total > 0) and (barHovered or PlayerHudState.draggingBar)

        speedBadge.Text = string.format("%.1fx", currentPlaybackSpeed)
    end)
end

createOnscreenPlayerHud()
