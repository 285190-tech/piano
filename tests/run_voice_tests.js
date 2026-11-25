// Exercise the real voice lifecycle with mocked virtual input and timers.
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const source = fs.readFileSync(path.join(__dirname, '..', 'piano.lua'), 'utf8');
const start = source.indexOf('local function enforceVoiceLimit()');
const end = source.indexOf('\n-- ==========================================\n-- Playback State', start);
if (start < 0 || end < 0) throw new Error('Cannot find voice lifecycle');
const script = `
local keyPressId, keyHeld, activePress, keyPressCount, activeNoteTokens, keyNote = {}, {}, {}, {}, {}, {}
local activeVoices, voiceOrder, legatoMode = {}, 0, false
local MAX_VOICES, FALLBACK_HOLD_SECONDS = 16, 6
local velocityMin, velocityMax, velocityCurve = 0.2, 1, 1
local CharToKeyInfo = {}
for index=1,17 do local c=string.char(64+index); CharToKeyInfo[c] = {keyEnum=c, needsShift=false, note=index} end
local Core = {}
function Core.mapVelocity(v) return v or 0.5 end
function Core.releaseActiveNoteToken(tokens, token)
    if not tokens or tokens[token] == nil then return false, 0 end
    tokens[token] = nil
    local count = 0; for _ in pairs(tokens) do count=count+1 end
    return true, count
end
local function removeVoicesForPress(key, token)
    for i=#activeVoices,1,-1 do if activeVoices[i].keyEnum == key and activeVoices[i].noteToken == token then table.remove(activeVoices,i) end end
end
local function removeVoicesForKey(key)
    for i=#activeVoices,1,-1 do if activeVoices[i].keyEnum == key then table.remove(activeVoices,i) end end
end
math.clamp = function(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local VirtualInputManager = {SendKeyEvent=function() end}
Enum = {KeyCode={LeftShift='SHIFT'}}
game = {}
local timers = {}
task = {delay=function(_, fn) timers[#timers+1] = fn end}
${source.slice(start, end)}
pressChar('A', 0.5, 1, false)
releaseChar('A', 1)
pressChar('A', 0.5, 1, false)
timers[1]()
assert(keyHeld.A and #activeVoices == 1, 'stale fallback must not release a newer press with the same note ID')
timers[2]()
assert(not keyHeld.A and #activeVoices == 0, 'current fallback must release its own note')
legatoMode, timers = true, {}
pressChar('A', 0.5, 2, false)
pressChar('A', 0.5, 3, false)
timers[1]()
assert(keyHeld.A and #activeVoices == 1, 'legato fallback must preserve another active note')
timers[2]()
assert(not keyHeld.A and #activeVoices == 0, 'last legato voice must release')
timers = {}
pressChar('A', 0.5, 4, true)
assert(#timers == 0, 'a matched note-off must not schedule a fallback')
releaseChar('A', 4)
legatoMode = false
for index=1,17 do pressChar(string.char(64+index), 0.5, index, true) end
assert(#activeVoices == 16, 'voice count must stay within the ceiling')
assert(not keyHeld.A and keyHeld.Q, 'voice stealing must release the oldest key')
print('Voice lifecycle tests passed')
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const rc = lauxlib.luaL_dostring(L, to_luastring(script));
if (rc !== lua.LUA_OK) {
    console.error(to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
}
