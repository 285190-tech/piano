local MidiToChar = layoutTools.default.map
local function near(actual, expected)
    assert(math.abs(actual - expected) < 0.00001, string.format("%f != %f", actual, expected))
end
local function midi(division, ...)
    local chunks = {...}
    local result = "MThd" .. string.pack(">I4I2I2I2", 6, #chunks == 1 and 0 or 1, #chunks, division)
    for _, chunk in ipairs(chunks) do result ..= "MTrk" .. string.pack(">I4", #chunk) .. chunk end
    return result
end
local function note(delta, pitch) return string.char(delta, 0x90, pitch, 80) end
local function tempo(delta, micros) return string.char(delta, 0xFF, 0x51, 3) .. string.pack(">I3", micros) end
local function eot(delta) return string.char(delta, 0xFF, 0x2F, 0) end

local mid = midi(100, tempo(100, 1000000) .. eot(0), note(0, 60) .. note(0, 60) .. note(0, 64) .. note(100, 24) .. note(100, 60) .. eot(50))
local events, length = buildMidiTimeline(mid, {})
assert(#events == 3)
near(events[1].time, 0); near(events[2].time, 0); near(events[3].time, 1.5); near(length, 2)
events = buildMidiTimeline(mid, {foldOctaves = true})
assert(#events == 4 and events[3].char == "1")
near(events[3].time, 0.5)
assert(getMidiChar(120, true) == getMidiChar(96, false))
local smpteEvents = buildMidiTimeline(midi(0xE728, tempo(0, 1000000) .. note(100, 60) .. eot(0)), {})
near(smpteEvents[1].time, 0.1)
assert(not pcall(buildMidiTimeline, midi(0, eot(0)), {}))

local sheet, sheetLength = buildSheetTimeline("[tt u][yyi] |", 120)
assert(#sheet == 5)
near(sheet[2].time, 0.06); near(sheet[3].time, 0.12); near(sheet[4].time, 0.305)
near(sheet[5].time, sheet[4].time); near(sheetLength, 1.055)

local quick = tabs["Quick Picks & URL"]
local playback = tabs["Playback"]
local localTab = tabs["Local & Sheets"]
local dropdown = quick.controls["Select Quick Pick"]
local search = quick.controls["Search Quick Picks"]
advance(0)
assert(#dropdown.Options == quickBrowser.pageSize)
search:Set("  MINECRAFT  ")
assert(#dropdown.Options >= 5 and selectedQuickPick == "Minecraft - Sweden")
dropdown:Set({"Minecraft - Pigstep"})
search:Set("minecraft")
assert(selectedQuickPick == "Minecraft - Pigstep")
search:Set("%[") -- Literal text, not a Lua pattern.
assert(dropdown.Options[1] == "No matching songs" and not selectedQuickPick)
quick.controls["Clear Quick Picks Search"].Callback()
assert(#dropdown.Options == quickBrowser.pageSize and selectedQuickPick == dropdown.Options[1])

local function press(tab, name) tab.controls[name].Callback() end
local function downCount()
    local count = 0
    for _, event in ipairs(keyEvents) do if event[1] then count += 1 end end
    return count
end
assert(playback.controls["Hold Keys for Note Length"].CurrentValue == true)
assert(playback.controls["Auto-Fit MIDI to Keyboard (Octaves)"].CurrentValue == true)
playback.controls["Auto-Fit MIDI to Keyboard (Octaves)"].Callback(false)
assert(playback.controls["Follow MIDI Pedal (Hold Mode)"].CurrentValue == true)
assert(playback.controls["Skip MIDI Drums (Channel 10)"].CurrentValue == true)
playback.controls["Hold Keys for Note Length"].Callback(false)
localTab.controls["Paste Text Sheet"]:Set("t--u")
press(localTab, "▶️ Play Pasted Sheet")
advance(0.1)
assert(state == "Playing" and downCount() == 1)
press(playback, "⏯️ Pause / Resume")
local frozen = position
advance(0.9)
assert(state == "Paused" and downCount() == 1)
near(position, frozen)
playback.controls["Playback Speed"].Callback(2)
press(playback, "⏯️ Pause / Resume")
advance(1.22)
assert(downCount() == 1)
advance(1.37)
assert(downCount() == 2 and state == "Finished")
assert(playback.labels.Ready.Value:find("100%%"))

playback.controls["Loop Current Song"].Callback(true)
localTab.controls["Paste Text Sheet"]:Set("z")
press(localTab, "▶️ Play Pasted Sheet")
advance(2.0)
assert(downCount() >= 4 and state == "Playing")
press(playback, "⏹️ Stop")
local afterStop = downCount()
advance(3)
assert(state == "Ready" and downCount() == afterStop)
playback.controls["Loop Current Song"].Callback(false)

fixtures['https://example.com/slow.mid'] = {delay = 0.4, body = mid}
fixtures['https://example.com/next.mid'] = {delay = 0.9, body = mid}
local url = quick.controls["Direct .mid URL"]
url:Set('https://example.com/slow.mid')
press(quick, "▶️ Download & Play URL")
advance(3.1)
press(playback, "⏹️ Stop")
url:Set('https://example.com/next.mid')
press(quick, "▶️ Download & Play URL")
advance(3.5)
assert(state == "Loading" and downCount() == afterStop)
advance(4.1)
assert(state == "Playing" and downCount() > afterStop)
press(playback, "⏹️ Stop")
advance(5)
assert(state == "Ready" and #notifications == 0)
local function off(delta, pitch, channel)
    return string.char(delta, 0x80 + (channel or 0), pitch, 0)
end
local function isKeyHeld(char) return keyHeld[CharToKeyInfo[char].keyEnum] == true end
local heldMid = midi(100, note(0, 36) .. note(10, 24) .. off(10, 36, 1) .. off(20, 36) .. string.char(60, 0x90, 24, 0) .. eot(100))
local heldTimeline, heldLength = buildMidiTimeline(heldMid, {foldOctaves = true}, true)
assert(#heldTimeline == 4 and heldTimeline[1].char == "1" and heldTimeline[2].char == "1")
assert(heldTimeline[1].change == 1 and heldTimeline[2].change == 1)
assert(heldTimeline[3].change == -1 and heldTimeline[4].change == -1)
near(heldTimeline[3].time, 0.2); near(heldTimeline[4].time, 0.5); near(heldLength, 1)
local tied, tiedLength = buildSheetTimeline("[tu]~~-n~", 120, true)
assert(#tied == 6 and tied[1].change == 1 and tied[3].change == -1)
near(tied[3].time, 0.75); near(tied[4].time, 0.75); near(tied[5].time, 1); near(tiedLength, 1.5)

playback.controls["Playback Speed"].Callback(1)
playback.controls["Hold Keys for Note Length"].Callback(true)
playback.controls["Fold Out-of-Range Notes into Piano Range"].Callback(true)
fixtures['https://example.com/hold.mid'] = {body = heldMid}
url:Set('https://example.com/hold.mid')
press(quick, "▶️ Download & Play URL")
advance(5.25)
assert(isKeyHeld("1"), 'overlapping folded notes release only after both original voices end')
press(playback, "⏯️ Pause / Resume")
assert(not isKeyHeld("1"))
advance(5.6)
press(playback, "⏯️ Pause / Resume")
advance(5.65)
assert(isKeyHeld("1"))
playback.controls["Playback Speed"].Callback(2)
advance(5.8)
assert(not isKeyHeld("1"))
press(playback, "⏹️ Stop")
assert(next(keyHeld) == nil and next(heldNotes) == nil)

localTab.controls["Paste Text Sheet"]:Set("[tT]~~")
local beforeChord = downCount()
press(localTab, "▶️ Play Pasted Sheet")
advance(6.0)
assert(isKeyHeld("t") and downCount() == beforeChord + 1)
advance(6.3)
assert(state == "Finished" and not isKeyHeld("t") and downCount() == beforeChord + 1, 'no ghost note in same-key chord')

fixtures['https://example.com/unclosed.mid'] = {body = midi(100, note(0, 36) .. eot(100))}
url:Set('https://example.com/unclosed.mid')
playback.controls["Loop Current Song"].Callback(true)
press(quick, "▶️ Download & Play URL")
advance(6.5)
assert(isKeyHeld("1"))
advance(6.6)
assert(not isKeyHeld("1"), 'a missing note-off must release before the loop gap')
advance(6.75)
assert(isKeyHeld("1"))
press(playback, "⏹️ Stop")
assert(next(keyHeld) == nil and next(heldNotes) == nil)

local function cc64(delta, channel, value) return string.char(delta, 0xB0 + channel, 64, value) end
local pedalMid = midi(100, cc64(0, 0, 127) .. note(0, 60) .. string.char(0, 0x91, 64, 80)
    .. string.char(0, 0x99, 42, 80) .. off(20, 60) .. off(0, 64, 1) .. off(0, 42, 9)
    .. note(20, 60) .. off(20, 60) .. cc64(20, 0, 0) .. eot(40))
local pedalNotes, pedalLength = buildMidiTimeline(pedalMid, {followPedal = true, skipDrums = true, transpose = 2}, true)
assert(#pedalNotes == 6 and pedalNotes[1].char == MidiToChar[62] and pedalNotes[2].char == MidiToChar[66])
near(pedalNotes[3].time, 0.1) -- Channel 2 is not affected by channel 1's pedal.
near(pedalNotes[4].time, 0.2); near(pedalNotes[5].time, 0.2)
assert(pedalNotes[4].change == -1 and pedalNotes[5].change == 1)
near(pedalNotes[6].time, 0.4); near(pedalLength, 0.6)
local noPedal = buildMidiTimeline(pedalMid, {skipDrums = true}, true)
near(noPedal[3].time, 0.1); near(noPedal[6].time, 0.3)
local drumTaps = buildMidiTimeline(pedalMid, {followPedal = true}, false)
assert(#drumTaps == 4 and drumTaps[3].char == MidiToChar[42])

playback.controls["Loop Current Song"].Callback(false)
playback.controls["Playback Speed"].Callback(1)
playback.controls["MIDI Transpose"].Callback(2)
fixtures['https://example.com/pedal.mid'] = {body = pedalMid}
url:Set('https://example.com/pedal.mid')
press(quick, "▶️ Download & Play URL")
advance(6.9)
assert(isKeyHeld(MidiToChar[62]) and not isKeyHeld(MidiToChar[66]) and not isKeyHeld(MidiToChar[44]))
local n = #keyEvents
advance(7.0)
assert(isKeyHeld(MidiToChar[62]) and #keyEvents == n + 2) -- Reattack under pedal.
advance(7.18)
assert(not isKeyHeld(MidiToChar[62]))
advance(7.4)
assert(state == "Finished" and next(keyHeld) == nil)
local highMidi = midi(100, note(0, 100) .. off(20, 100) .. note(10, 104) .. off(20, 104) .. eot(40))
local normalHigh = buildMidiTimeline(highMidi, {}, true)
assert(#normalHigh == 0)
local fitted, _, fittingReport = buildMidiTimeline(highMidi, {autoFit = true}, true)
assert(#fitted == 4 and fitted[1].char == MidiToChar[88] and fitted[3].char == MidiToChar[92])
assert(fittingReport == 'Pitch shift: -12 st · 2/2 notes in range · MIDI ch: 1')
assert(chooseOctaveShift({[60] = 1, [64] = 5}, 0) == 0)
assert(chooseOctaveShift({[18] = 10, [111] = 1}, 0) == 24)
assert(chooseOctaveShift({}, 5) == 0)

localTab.controls["Paste Text Sheet"]:Set("t~~~~~~~~u~~~~~~~~y~~~~~~~~")
press(localTab, "▶️ Play Pasted Sheet")
advance(7.5)
press(playback, "⏯️ Pause / Resume")
playback.controls["Jump to Time"].Callback("0:01")
advance(7.55)
assert(state == "Paused" and next(keyHeld) == nil)
near(position, 1)
press(playback, "Set A · Loop Start")
playback.controls["Jump to Time"].Callback("3")
advance(7.6)
press(playback, "Set B · Loop End")
press(playback, "⏯️ Pause / Resume")
advance(7.65)
assert(practiceStart == 1 and practiceEnd == 3 and isKeyHeld("t") and not isKeyHeld("u"))
advance(9.0)
assert(isKeyHeld("u") and not isKeyHeld("t"))
advance(9.8)
assert(isKeyHeld("t") and not isKeyHeld("u") and position < 1.3)
advance(11.75)
assert(isKeyHeld("t") and position < 1.3)
press(playback, "⏯️ Pause / Resume")
local beforeSeek = #keyEvents
playback.controls["Jump to Time"].Callback("5.5")
advance(11.8)
assert(practiceEnd == nil and #keyEvents == beforeSeek)
press(playback, "⏯️ Pause / Resume")
advance(11.9)
assert(isKeyHeld("y") and not isKeyHeld("t") and not isKeyHeld("u"))
press(playback, "Back 5 Seconds")
advance(12)
assert(isKeyHeld("t") and not isKeyHeld("y"))
press(playback, "⏹️ Stop")
assert(next(keyHeld) == nil and practiceEnd == nil)

-- Stage: preload stays silent, reuses the download, and recompiles for changed options.
local stage = tabs.Stage
local queueDropdown = stage.controls["Queued Songs"]
local queuedUrl = 'https://example.com/Queued.mid?take=2'
fixtures[queuedUrl] = {delay = 0.2, body = midi(100, note(0, 60) .. off(100, 60) .. eot(0))}
url:Set(queuedUrl)
press(quick, "Queue Direct URL")
localTab.controls["Paste Text Sheet"]:Set("u~~~~")
press(localTab, "Queue Pasted Sheet")
assert(#setlist == 2 and setlist[1].name == "Queued")
local baseline = #keyEvents
press(stage, "Preload Next")
advance(12.3)
assert(state == "Ready" and stageSlot.status == "Ready" and #keyEvents == baseline and requests[queuedUrl] == 1)
playback.controls["MIDI Transpose"].Callback(0)
press(stage, "Play Next")
advance(12.35)
assert(#setlist == 1 and setlist[1].kind == "sheet" and requests[queuedUrl] == 1)
assert(isKeyHeld(MidiToChar[60]) and not isKeyHeld(MidiToChar[62]))
advance(13)
assert(state == "Finished" and #setlist == 1 and not isKeyHeld("u"), "no automatic next song")
press(stage, "Play Next")
advance(13.05)
assert(isKeyHeld("u") and #setlist == 0)
press(stage, "Stop")
assert(next(keyHeld) == nil)

-- Cancel a pending cue while retaining its independently staged song.
local slowUrl = 'https://example.com/slow-stage.mid'
fixtures[slowUrl] = {delay = 0.5, body = mid}
url:Set(slowUrl)
press(quick, "Queue Direct URL")
press(stage, "Play Next")
advance(13.15)
press(stage, "Stop")
local cancelled = #keyEvents
advance(13.7)
assert(state == "Ready" and #setlist == 1 and stageSlot.status == "Ready" and #keyEvents == cancelled)

-- A removed or reordered head must not play when its request comes back.
press(stage, "Clear Setlist")
press(quick, "Queue Direct URL")
press(stage, "Play Next")
advance(13.74)
press(quick, "Queue Quick Pick")
queueDropdown:Set({queueDropdown.Options[2]})
press(stage, "Move Selected Up")
advance(14.3)
assert(state == "Ready" and #setlist == 2 and stageSlot == nil and #keyEvents == cancelled)
assert(setlist[1].name == selectedQuickPick)
press(stage, "Remove Selected")
assert(#setlist == 1 and setlist[1].source == slowUrl)
press(stage, "Clear Setlist")
assert(#setlist == 0 and queueDropdown.Options[1] == emptySetlist)

-- Bad downloads stay queued for manual retry or removal.
local badUrl = 'https://example.com/bad.mid'
fixtures[badUrl] = {body = 'Not MIDI'}
url:Set(badUrl)
press(quick, "Queue Direct URL")
press(stage, "Play Next")
advance(14.4)
assert(state == "Playback failed" and #setlist == 1 and stageSlot.status == "Failed" and #keyEvents == cancelled)
assert(notifications[#notifications].Content:find("Missing MIDI header", 1, true))
fixtures[badUrl] = {body = mid}
press(stage, "Preload Next")
advance(14.41)
assert(requests[badUrl] == 2 and stageSlot.status == "Ready" and #keyEvents == cancelled)
press(stage, "Clear Setlist")

-- Local and NanoMIDI share the queue. A true local load makes no HTTP request.
localMidiData = midi(100, note(0, 64) .. off(100, 64) .. eot(0))
localTab.controls['Select Local .mid']:Set({"fixture.mid"})
press(localTab, "Queue Local MIDI")
local nano = tabs["NanoMIDI API"]
nano.controls["Select Song"]:Set({"Test Song - An Artist"})
press(nano, "Queue NanoMIDI Song")
assert(#setlist == 2 and setlist[1].kind == "file" and setlist[2].headers == nanoHeaders)
assert(setlist[2].source == "https://api.nanomidi.net/api/midis/test%20file.mid")
press(stage, "Play Next")
advance(14.45)
assert(isKeyHeld(MidiToChar[64]) and #setlist == 1)
press(stage, "Stop")
press(stage, "Clear Setlist")

-- Soundcheck has a lead-in, uses shifted and held keys, then finishes even if loop is on.
playback.controls["Loop Current Song"].Callback(true)
local soundcheckStart = #keyEvents
press(stage, "Soundcheck · Active Keyboard Layout")
advance(15)
assert(#keyEvents == soundcheckStart)
advance(19.2)
assert(state == "Finished" and next(keyHeld) == nil)
local sawShift = false
for i = soundcheckStart + 1, #keyEvents do
    if keyEvents[i][1] and keyEvents[i][2] == "LeftShift" then sawShift = true end
end
assert(sawShift)

-- Unsupported synthetic input fails cleanly rather than breaking the UI transport.
rejectInput = true
press(stage, "Soundcheck · Active Keyboard Layout")
advance(20.4)
assert(state == "Playback failed" and next(keyHeld) == nil)
assert(notifications[#notifications].Content:find("Virtual input unavailable", 1, true))
rejectInput = false

local function checkSavedSets()
    local input = stage.controls["New Setlist Name"]
    local saved = stage.controls["Saved Setlists"]
    local file = "piano-setlists-v1.json"
    local before = #keyEvents
    press(stage, "Clear Setlist")
    press(localTab, "Queue Local MIDI")
    press(nano, "Queue NanoMIDI Song")
    localTab.controls["Paste Text Sheet"]:Set("[tu]~~")
    localTab.controls["Text Sheet BPM"].Callback(145)
    press(localTab, "Queue Pasted Sheet")
    input:Set("../unsafe")
    press(stage, "Save Queue by Name")
    assert(not isfile(file))
    input:Set("  Friday Set  ")
    press(stage, "Save Queue by Name")
    local first = encodedDocuments[workspaceFiles[file]]
    assert(first.version == 1 and #first.sets["Friday Set"] == 3)
    assert(first.sets["Friday Set"][2].headers == nil and first.sets["Friday Set"][2].id == nil)
    assert(first.sets["Friday Set"][3].bpm == 145)
    assert(saved.CurrentOption[1] == "Friday Set")

    local originalHead = setlist[1]
    queueDropdown:Set({queueDropdown.Options[1]})
    press(stage, "Move Selected Down")
    assert(setlist[2] == originalHead)
    press(stage, "Shuffle Queue")
    assert(#setlist == 3 and table.find(setlist, originalHead) and #keyEvents == before)
    input:Set("Second Set")
    press(stage, "Save Queue by Name")
    assert(#saved.Options == 2)
    press(stage, "Clear Setlist")
    saved:Set({"Friday Set"})
    press(stage, "Load Saved Setlist (Replace Queue)")
    assert(#setlist == 3 and setlist[1].kind == "file" and setlist[1].id ~= originalHead.id)
    assert(setlist[2].headers == nanoHeaders and setlist[3].bpm == 145 and stageSlot == nil and #keyEvents == before)

    local goodFile = workspaceFiles[file]
    workspaceFiles[file] = "corrupt"
    press(stage, "Save Queue by Name")
    press(stage, "Load Saved Setlist (Replace Queue)")
    assert(workspaceFiles[file] == "corrupt" and #setlist == 3)
    workspaceFiles[file] = goodFile
    failFileWrites = true
    press(stage, "Delete Saved Setlist")
    assert(workspaceFiles[file] == goodFile)
    failFileWrites = false
    press(stage, "Delete Saved Setlist")
    assert(#saved.Options == 1 and saved.Options[1] == "Second Set" and #setlist == 3)
end
checkSavedSets()

local function checkPerformanceControls()
    local cue = "https://example.com/cue.mid"
    fixtures[cue] = {body = midi(100, note(0, 60) .. string.char(0x83, 0x10, 0x80, 60, 0) .. eot(0))}
    press(stage, "Clear Setlist")
    playback.controls["Loop Current Song"].Callback(false)
    url:Set(cue)
    press(quick, "Queue Direct URL")
    stage.controls["Cue Countdown"].Callback(2)
    local hotkeys = stage.controls["Stage Hotkeys · F6 Next / F7 Pause / F8 Stop"]
    local beganAt, before = clock, #keyEvents
    local function tick(offset) advance(beganAt + offset) end

    pressHotkey("F6")
    assert(state == "Playback failed" and requests[cue] == nil, "hotkeys should be off initially")
    hotkeys.Callback(true)
    pressHotkey("F6", true)
    focusedTextBox = {}
    pressHotkey("F6")
    assert(requests[cue] == nil and #setlist == 1)
    focusedTextBox = nil
    pressHotkey("F6")
    tick(0.1)
    assert(state == "Cueing" and #keyEvents == before and #setlist == 1 and requests[cue] == 1)
    focusedTextBox = {}
    pressHotkey("F8", true)
    focusedTextBox = nil
    tick(2.3)
    assert(state == "Ready" and #keyEvents == before and #setlist == 1)

    pressHotkey("F6")
    tick(3.4)
    assert(state == "Cueing" and #keyEvents == before and requests[cue] == 1 and cueSecondsLeft == 1)
    tick(4.4)
    assert(state == "Playing" and #setlist == 0 and isKeyHeld(MidiToChar[60]))
    focusedTextBox = {}
    tick(4.45)
    assert(state == "Paused" and next(keyHeld) == nil)
    local pausedAt, pausedEvents = position, #keyEvents
    pressHotkey("F7")
    press(stage, "Pause / Resume")
    tick(4.55)
    focusedTextBox = nil
    tick(4.65)
    near(position, pausedAt)
    assert(state == "Paused" and #keyEvents == pausedEvents, "closing chat never resumes automatically")
    pressHotkey("F7")
    tick(4.7)
    assert(state == "Playing" and isKeyHeld(MidiToChar[60]))
    pressHotkey("F8")
    assert(state == "Ready" and next(keyHeld) == nil)

    url:Set("https://example.com/later.mid")
    press(quick, "Queue Direct URL")
    stage.controls["Cue Countdown"].Callback(0)
    playback.controls["MIDI Transpose"].Callback(2)
    press(stage, "Encore · Replay Last Stage Song")
    tick(4.8)
    assert(requests[cue] == 1 and #setlist == 1 and isKeyHeld(MidiToChar[62]))
    assert(not isKeyHeld(MidiToChar[60]) and requests["https://example.com/later.mid"] == nil)
    press(stage, "Stop")
    playback.controls["MIDI Transpose"].Callback(0)

    press(stage, "Clear Setlist")
    url:Set(cue)
    press(quick, "Queue Direct URL")
    stage.controls["Cue Countdown"].Callback(1)
    press(stage, "Play Next")
    tick(4.9)
    assert(state == "Cueing")
    press(stage, "Remove Selected")
    local afterRemoval = #keyEvents
    tick(6)
    assert(state == "Ready" and #keyEvents == afterRemoval and #setlist == 0)
end
checkPerformanceControls()

local function checkLayoutsAndChannels()
    local layout = assert(layoutTools.parse("  60 : a. s.df "))
    assert(layout.count == 4 and layout.map[62] == "s" and layout.map[61] == nil)
    assert(not layoutTools.parse("60:a.a") and not layoutTools.parse("127:ab"))
    assert(not layoutTools.parse("60:...") and not layoutTools.parse("60:=s"))
    local sparse = assert(layoutTools.parse("60:a" .. string.rep(".", 12) .. "s"))
    assert(getMidiChar(61, false, sparse) == nil and getMidiChar(61, true, sparse) == "s")
    assert(getMidiChar(62, true, sparse) == nil)
    assert(chooseOctaveShift({[48] = 10}, 0, layout) == 12)

    local track = note(0, 60) .. string.char(0, 0x91, 62, 90)
        .. string.char(0, 0x99, 64, 90) .. off(100, 60) .. off(0, 62, 1) .. off(0, 64, 9) .. eot(0)
    local song = midi(100, track)
    local drumOnly = buildMidiTimeline(song, {channel = 10, skipDrums = true, layout = layout}, false)
    assert(#drumOnly == 1 and drumOnly[1].char == "d", "explicit channel overrides the general drum filter")
    local solo, _, report = buildMidiTimeline(song, {channel = 2, layout = layout}, true)
    assert(#solo == 2 and solo[1].char == "s" and solo[2].char == "s" and solo[2].change == -1)
    near(solo[2].time, 0.5)
    assert(report:find("MIDI ch: 1, 2, 10", 1, true))

    local setup = tabs["Keyboard Setup"]
    local mapping = setup.controls["Keyboard Mapping"]
    mapping:Set("60:a.a")
    press(setup, "Apply Mapping")
    assert(midiSettings.layout == layoutTools.default)
    mapping:Set(layout.spec)
    press(setup, "Apply Mapping")
    press(setup, "Save Active Mapping for This Experience")
    assert(workspaceFiles["piano-layout-u321.txt"] == layout.spec)
    press(setup, "Use Standard Mapping")
    assert(midiSettings.layout == layoutTools.default)
    press(setup, "Reload Saved Mapping")
    assert(midiSettings.layout.spec == layout.spec and mapping.CurrentValue == layout.spec)

    local source = "https://example.com/channels.mid"
    fixtures[source] = {body = song}
    press(stage, "Clear Setlist")
    url:Set(source)
    press(quick, "Queue Direct URL")
    stage.controls["Cue Countdown"].Callback(0)
    local startedAt, baseline = clock, #keyEvents
    press(stage, "Preload Next")
    advance(startedAt + 0.05)
    assert(#keyEvents == baseline and requests[source] == 1)
    assert(stageAnalysis.Value:find("MIDI ch: 1, 2, 10", 1, true))
    playback.controls["MIDI Channel (0 = All)"].Callback(2)
    press(stage, "Preload Next")
    advance(startedAt + 0.1)
    assert(requests[source] == 1 and #stageSlot.prepared.events == 2 and #keyEvents == baseline)
    press(stage, "Play Next")
    advance(startedAt + 0.15)
    assert(isKeyHeld("s") and not isKeyHeld("a") and not isKeyHeld("d"))
    press(stage, "Stop")

    local keyStart = #keyEvents
    press(stage, "Soundcheck · Active Keyboard Layout")
    advance(startedAt + 4.5)
    assert(state == "Finished" and next(keyHeld) == nil and #keyEvents > keyStart)
    for index = keyStart + 1, #keyEvents do
        local key = keyEvents[index][2]
        assert(key == "A" or key == "S" or key == "D", "soundcheck must use the active layout")
    end
end
checkLayoutsAndChannels()

local function checkPerSongSettings()
    local fixtureUrl = "https://example.com/arrangement.mid"
    local track = note(0, 60) .. string.char(0, 0x91, 64, 90) .. off(100, 60) .. off(0, 64, 1) .. eot(0)
    fixtures[fixtureUrl] = {body = midi(100, track)}
    press(stage, "Clear Setlist")
    url:Set(fixtureUrl)
    press(quick, "Queue Direct URL")
    stage.controls["Cue Countdown"].Callback(0)
    local transpose = playback.controls["MIDI Transpose"]
    local channel = playback.controls["MIDI Channel (0 = All)"]
    transpose.Callback(2)
    channel.Callback(1)
    press(stage, "Pin Current MIDI Settings to Selected Song")
    assert(setlist[1].mix.transpose == 2 and setlist[1].mix.channel == 1 and setlist[1].mix.layout == nil)

    stage.controls["New Setlist Name"]:Set("Pinned Mix")
    press(stage, "Save Queue by Name")
    press(stage, "Clear Setlist")
    press(stage, "Load Saved Setlist (Replace Queue)")
    assert(setlist[1].mix.channel == 1 and setlist[1].mix.holds)
    transpose.Callback(0)
    channel.Callback(2)
    press(stage, "Preload Next")
    advance(clock + 0.01)
    assert(stageSlot.options.channel == 1 and stageSlot.options.transpose == 2)
    assert(stageSlot.options.layout == midiSettings.layout)
    press(stage, "Play Next")
    advance(clock + 0.02)
    assert(isKeyHeld("s") and not isKeyHeld("d") and requests[fixtureUrl] == 1)
    press(stage, "Stop")

    press(stage, "Load Saved Setlist (Replace Queue)")
    press(stage, "Clear Selected Song Settings")
    assert(setlist[1].mix == nil)
    press(stage, "Play Next")
    advance(clock + 0.02)
    assert(isKeyHeld("d") and not isKeyHeld("s"))
    press(stage, "Stop")
end
checkPerSongSettings()

local function checkLagRecovery()
    local function sawDown(key, after)
        for index = after + 1, #keyEvents do
            if keyEvents[index][1] and keyEvents[index][2] == key then return true end
        end
        return false
    end
    localTab.controls["Text Sheet BPM"].Callback(300)
    local input = localTab.controls["Paste Text Sheet"]
    input:Set("asdz~~~~")
    press(localTab, "▶️ Play Pasted Sheet")
    advance(clock + 0.05)
    assert(isKeyHeld("a"))
    local before = #keyEvents
    stallFrames(0.35)
    assert(not isKeyHeld("a") and isKeyHeld("z"))
    assert(not sawDown("S", before) and not sawDown("D", before), "elapsed held notes must not burst")
    stallFrames(1)
    assert(state == "Finished" and next(keyHeld) == nil)

    playback.controls["Hold Keys for Note Length"].Callback(false)
    input:Set("asd f")
    press(localTab, "▶️ Play Pasted Sheet")
    advance(clock + 0.02)
    before = #keyEvents
    stallFrames(0.4)
    assert(not sawDown("S", before) and not sawDown("D", before) and sawDown("F", before),
        "skip stale taps but keep recent ones")
    press(stage, "Stop")
    assert(next(keyHeld) == nil)
end
checkLagRecovery()

local function checkQuickPickBrowser()
    local category = quick.controls["Quick Picks Category"]
    local favoritesOnly = quick.controls["Favorites Only"]
    local previous = "Previous Results Page"
    local nextPage = "Next Results Page"
    assert(quickBrowser.page == 1 and #dropdown.Options == quickBrowser.pageSize)
    press(quick, previous)
    assert(quickBrowser.page == 1)
    local firstLabel = dropdown.Options[1]
    local reached = {}
    for page = 1, quickBrowser.lastPage do
        for _, label in ipairs(dropdown.Options) do
            assert(not reached[label], "pagination repeated an entry")
            reached[label] = true
        end
        if page < quickBrowser.lastPage then press(quick, nextPage) end
    end
    for _, song in ipairs(DEFAULT_QUICKPICKS) do assert(reached[song.name], "pagination missed " .. song.name) end
    press(quick, nextPage)
    assert(quickBrowser.page == quickBrowser.lastPage)

    category:Set({"Games"})
    search:Set("  kyurem POKEMON  ")
    local favorite = "Pokémon Black 2 and White 2 - Battle! Kyurem"
    assert(quickBrowser.page == 1 and #dropdown.Options == 1 and selectedQuickPick == favorite)
    search:Set("poke" .. utf8.char(0x301) .. "mon kyurem")
    assert(#dropdown.Options == 1 and dropdown.Options[1] == favorite)
    press(quick, "Favorite / Unfavorite Selected Song")
    assert(quickBrowser.favorites[favorite] and quickBrowser.selectionLabel.Value:find("Favorite", 1, true))
    assert(workspaceFiles[quickBrowser.favoriteFile])
    table.clear(quickBrowser.favorites)
    quickBrowser.loadFavorites()
    assert(quickBrowser.favorites[favorite])
    favoritesOnly.Callback(true)
    press(quick, "Clear Quick Picks Search")
    assert(#dropdown.Options == 1 and selectedQuickPick == favorite)
    local oldLen = #setlist
    press(quick, "Queue Quick Pick")
    assert(#setlist == oldLen + 1 and setlist[#setlist].name == favorite)
    category:Set({"Classical"})
    assert(not selectedQuickPick and dropdown.Options[1] == "No matching songs")
    category:Set({"Games"})
    press(quick, "Favorite / Unfavorite Selected Song")
    assert(not quickBrowser.favorites[favorite] and not selectedQuickPick)
    favoritesOnly.Callback(false)
    category:Set({"Anime"})
    search:Set("VOGEL KAFIG")
    assert(#dropdown.Options == 1 and selectedQuickPick == "Attack on Titan - Vogel im Käfig")

    local fixtureUrl = "https://example.com/legacy-catalog.json"
    local legacy = '{"fixture":"legacy catalog"}'
    encodedDocuments[legacy] = {songs = {
        {name = "Minecraft - Sweden", url = "https://example.com/sweden.mid"},
        {name = "A New Song", url = "https://example.com/custom.mid"},
    }}
    fixtures[fixtureUrl .. "?t=0"] = {body = legacy}
    fetchFromRepoUrl(fixtureUrl, true)
    advance(clock + 0.01)
    assert(#quickPickOrder == #DEFAULT_QUICKPICKS, "old upstream catalog should not erase the newer fallback")
    fetchFromRepoUrl(fixtureUrl, false)
    advance(clock + 0.01)
    assert(#quickPickOrder == 2 and quickBrowser.entries["Minecraft - Sweden"].category == "Games")
    assert(quickBrowser.entries["A New Song"].category == "Other")
    fetchFromRepoUrl("", true)
    category:Set({"All categories"})
    press(quick, "Clear Quick Picks Search")
    assert(dropdown.Options[1] == firstLabel and #dropdown.Options == quickBrowser.pageSize)
end
checkQuickPickBrowser()

print("Piano smoke tests passed: performance, catalog filters, accent-insensitive search, favorites, and pagination")
