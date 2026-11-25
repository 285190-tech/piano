// Test the real practice wait with a mocked keyboard signal and clock.
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const source = fs.readFileSync(path.join(__dirname, '..', 'piano.lua'), 'utf8');
const start = source.indexOf('local function waitForPracticeChord(');
const end = source.indexOf('\n-- ==========================================\n-- Shared playback engine', start);
if (start < 0 || end < 0) throw new Error('Cannot find practice wait');
const script = `
local playing, playbackId = true, 1
local PlayerHudState = {practiceMode = true, paused = false}
local midiMapping = {version = 0}
local CharToKeyInfo = {a={keyEnum='A',needsShift=false}, B={keyEnum='B',needsShift=true}}
local Core = {practiceChord = function(events, index) return events[index].chars end}
Enum = {KeyCode={LeftShift='LEFT', RightShift='RIGHT'}}
local signal, disconnected, shifted, step, cancel, replacePrompt = nil, false, false, 0, false, false
UserInputService = {
    InputBegan = {Connect = function(_, callback)
        signal = callback
        return {Disconnect = function() disconnected = true end}
    end},
    GetFocusedTextBox = function() return nil end,
    IsKeyDown = function(_, key) return shifted and key == 'LEFT' end,
}
function warn() end
task = {wait = function()
    step = step + 1
    if cancel then
        playing = false
        if replacePrompt then PlayerHudState.waitingForNotes = {'new'} end
        return
    end
    if step == 1 then signal({KeyCode='WRONG'}) end
    if step == 2 then shifted = true; signal({KeyCode='A'}) end
    if step == 3 then shifted = false; signal({KeyCode='A'}) end
    if step == 4 then shifted = true; signal({KeyCode='B'}) end
    assert(step < 10, 'practice failed to complete')
end}
${source.slice(start, end)}
local completed = waitForPracticeChord({{kind='press',songTime=0,chars={'a','B'}}}, 1, 1, 0)
assert(completed and step == 4, 'practice must wait for both correctly shifted keys')
assert(disconnected and PlayerHudState.waitingForNotes == nil, 'practice must disconnect and clear state')
playing, cancel, disconnected, step = true, true, false, 0
assert(not waitForPracticeChord({{kind='press',songTime=0,chars={'a'}}}, 1, 1, 0), 'stopping cancels practice')
assert(disconnected, 'cancellation must disconnect')
playing, cancel, disconnected, step, replacePrompt = true, true, false, 0, true
assert(not waitForPracticeChord({{kind='press',songTime=0,chars={'a'}}}, 1, 1, 0), 'old practice should stop')
assert(PlayerHudState.waitingForNotes[1] == 'new', 'old cleanup must not erase a newer prompt')
print('Practice keyboard tests passed')
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const rc = lauxlib.luaL_dostring(L, to_luastring(script));
if (rc !== lua.LUA_OK) {
    console.error(to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
}
