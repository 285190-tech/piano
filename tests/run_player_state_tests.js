// Test loading/error state transitions without Roblox globals.
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const source = fs.readFileSync(path.join(__dirname, '..', 'piano.lua'), 'utf8');
const start = source.indexOf('local function setHudLoading(');
const end = source.indexOf('local function registerStopHook(', start);
if (start < 0 || end < 0) throw new Error('Cannot find player state helpers');
const script = `
local PlayerHudState = {replayFn=function() end}
local currentMidiEvents = {{kind='press'}}
${source.slice(start, end)}
setHudLoading('New song', 'URL')
assert(currentMidiEvents == nil, 'loading must clear the old MIDI export timeline')
assert(PlayerHudState.status == 'loading' and PlayerHudState.title == 'New song', 'loading metadata should update')
currentMidiEvents = {{kind='press'}}
setHudFailed('Invalid MIDI')
assert(currentMidiEvents == nil and PlayerHudState.replayFn == nil, 'failure must not leave an old MIDI export or replay')
assert(PlayerHudState.status == 'idle' and PlayerHudState.subtitle == 'Invalid MIDI', 'failure state should be visible')
print('Player state tests passed')
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const rc = lauxlib.luaL_dostring(L, to_luastring(script));
if (rc !== lua.LUA_OK) {
    console.error(to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
}
