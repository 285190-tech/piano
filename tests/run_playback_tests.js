// Exercise the actual event-player function with a deterministic fake clock.
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const source = fs.readFileSync(path.join(__dirname, '..', 'piano.lua'), 'utf8');
const start = source.indexOf('local function runEventPlayer(');
const end = source.indexOf('\n-- ==========================================\n-- MIDI parsing & playback', start);
if (start < 0 || end < 0) throw new Error('Cannot find event player');
const seekStart = source.indexOf('local function requestSeek(');
const seekEnd = source.indexOf('local function findEventIndexAtTime(', seekStart);
if (seekStart < 0 || seekEnd < 0) throw new Error('Cannot find seek helpers');
const script = `
local playbackId, playing, currentPlaybackSpeed = 1, false, 1
local onPlaybackFinished, finishedCount = function() end, 0
onPlaybackFinished = function() finishedCount = finishedCount + 1 end
local PlayerHudState = {loopSong = false}
local currentLayoutName, compactStartNote, startNote = "full", 36, 36
local midiMapping = {transpose = 0, octave = 0, fold = false, version = 0, mutedTracks = {}, mutedChannels = {}, soloTrack = nil}
local MidiToChar = {[60]="a", [61]="b", [62]="c", [63]="d"}
local playedChars, doTranspose, doMute, practiceWaits = {}, false, false, 0
local now, presses, releases, stopAfter = 0, 0, 0, 999
function tick() now = now + 0.05; return now end
task = {wait = function() now = now + 0.05 end}
math.clamp = function(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local Core = { isMidiNoteEnabled = function(track, channel, mt, mc, solo) return not mt[track or 0] and not mc[channel or 0] and (not solo or track == solo) end, mapMidiNote = function(note, transpose) return note + transpose end, buildSeekIndex = function() return {} end,
    isValidLoopRange = function(a, b, duration)
        return type(a) == "number" and type(b) == "number" and a >= 0 and b <= duration and b-a >= 0.1
    end }
local function restoreHeldNotesAtIndex() end
local function waitForPracticeChord() practiceWaits = practiceWaits + 1; return true end
local function releaseHeldKeys() releases = releases + 1 end
local function pressChar(char)
    presses = presses + 1; playedChars[#playedChars + 1] = char
    if doTranspose then doTranspose = false; midiMapping.transpose = 1; midiMapping.version = midiMapping.version + 1 end
    if doMute then doMute = false; midiMapping.mutedChannels[2] = true; midiMapping.version = midiMapping.version + 1 end
    if presses >= stopAfter then playing = false end
end
local function releaseChar() end
local function findEventIndexAtTime(events, target)
    for i, event in ipairs(events) do if event.songTime >= target - 0.0001 then return i end end
    return #events + 1
end
${source.slice(seekStart, seekEnd)}
${source.slice(start, end)}
PlayerHudState.replayFn = function() end
local events = {{songTime=0, kind='press', chars={'a'}}, {songTime=0.2, kind='release', chars={'a'}}}
runEventPlayer(events, 1, nil, 0.2, {})
assert(presses == 1 and PlayerHudState.status == 'finished' and finishedCount == 1, 'normal playback should finish once')
presses, releases, stopAfter = 0, 0, 3
PlayerHudState.loopSong = true
runEventPlayer(events, 1, nil, 0.2, {})
assert(presses == 3 and PlayerHudState.status == 'stopped' and finishedCount == 1, 'loop should repeat and stop without autoplay')
assert(releases >= 3, 'loop should release held keys between repeats and on stop')
presses, releases, stopAfter = 0, 0, 3
PlayerHudState.loopSong = false
runEventPlayer(events, 1, function() PlayerHudState.loopA = 0; PlayerHudState.loopB = 0.15 end, 0.2, {})
assert(presses == 3 and releases >= 3, 'A-B repeat should seek back and release keys')
presses, releases, stopAfter, playedChars = 0, 0, 4, {}
runEventPlayer({{songTime=0,kind='press',chars={'a'}}, {songTime=0.12,kind='press',chars={'b'}}, {songTime=0.4,kind='release',chars={'b'}}}, 1,
    function() PlayerHudState.loopA = 0; PlayerHudState.loopB = 0.18 end, 0.4, {})
assert(table.concat(playedChars) == 'abab', 'A-B repeat must not skip notes when a frame crosses B')
presses, stopAfter = 0, 999
runEventPlayer({{songTime=0, kind='press', chars={'a'}}}, 1, nil, 0, {})
assert(presses == 1 and PlayerHudState.status == 'finished', 'zero-duration song must not loop forever')
presses, stopAfter, playedChars, doTranspose = 0, 999, {}, true
midiMapping.transpose, midiMapping.version = 0, 0
PlayerHudState.loopSong = false
runEventPlayer({{songTime=0, kind='press', midiNote=60, chars={}}, {songTime=0.4, kind='press', midiNote=62, chars={}}}, 1, nil, 0.4, {})
assert(playedChars[1] == 'a' and playedChars[2] == 'd', 'transpose should update during playback')
presses, playedChars, doMute = 0, {}, true
midiMapping.transpose, midiMapping.version, midiMapping.mutedChannels = 0, 0, {}
runEventPlayer({{songTime=0, kind='press', midiNote=60, track=1, channel=1, chars={}}, {songTime=0.4, kind='press', midiNote=62, track=1, channel=2, chars={}}}, 1, nil, 0.4, {})
assert(presses == 1 and playedChars[1] == 'a', 'channel mute should take effect during playback')
presses, practiceWaits = 0, 0
PlayerHudState.practiceMode = true
runEventPlayer({{songTime=0, kind='press', chars={'a'}}, {songTime=0, kind='press', chars={'b'}}, {songTime=0.2, kind='release', chars={'a'}}, {songTime=0.4, kind='press', chars={'c'}}}, 1, nil, 0.4, {})
assert(presses == 0 and practiceWaits == 2, 'practice waits once per chord without automated presses')
PlayerHudState.practiceMode = false
playing = true
PlayerHudState.totalTime, PlayerHudState.currentTime, PlayerHudState.seekTarget = 100, 50, nil
PlayerHudState.paused = true
assert(seekRelative(-10) and PlayerHudState.seekTarget == 40, 'seek back while paused')
assert(seekRelative(10) and PlayerHudState.seekTarget == 50, 'pending seeks should stack')
assert(requestSeek(250) and PlayerHudState.seekTarget == 100, 'seek clamps to end')
assert(requestSeek(-10) and PlayerHudState.seekTarget == 0, 'seek clamps to start')
assert(not requestSeek(0/0), 'seek rejects NaN')
playing = false
assert(not requestSeek(0), 'seek should reject inactive player')
playing = true
PlayerHudState.totalTime = 0
assert(not requestSeek(0), 'seek should reject zero-duration songs')
print('Playback loop and seek tests passed')
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const rc = lauxlib.luaL_dostring(L, to_luastring(script));
if (rc !== lua.LUA_OK) {
    console.error(to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
}
