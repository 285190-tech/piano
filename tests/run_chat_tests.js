// Test the actual opt-in chat listener's authorization and cleanup with mocks.
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const source = fs.readFileSync(path.join(__dirname, '..', 'piano.lua'), 'utf8');
const start = source.indexOf('-- Chat requests are opt-in.');
const end = source.indexOf('\nGlobalBox:AddButton({', start);
if (start < 0 || end < 0) throw new Error('Cannot find chat listener');
const script = `
local toggles, inputs, signal, disconnected = {}, {}, nil, false
local box = {}
function box:AddLabel() return {} end
function box:AddToggle(id, opts) toggles[id] = opts.Callback end
function box:AddInput(id, opts) inputs[id] = opts.Callback end
local GlobalTab = {AddGroupbox=function() return box end}
local function setLabelSafe() end
local function notify() end
local Players = {LocalPlayer={UserId=123}}
Enum = {ChatVersion={TextChatService='modern'}}
local chat = {ChatVersion='modern', MessageReceived={Connect=function(_, callback)
    signal = callback
    return {Disconnect=function() disconnected = true end}
end}}
game = {GetService=function(_, name) return chat end}
local now = 10
function tick() return now end
local Core = {
    parseSongRequest=function(message)
        local command, query = message:match('^!(%a+)%s+(.+)$')
        if command ~= 'play' and command ~= 'request' then return nil end
        return command, query
    end,
    parseUserIdSet=function(text) return {[text]=true} end,
    matchesQuery=function(title, query) return title:lower():find(query:lower(), 1, true) ~= nil end,
}
local QuickState = {order={'Fur Elise'}, map={['Fur Elise']='https://example.com/song.mid'}}
local played, queued = 0, 0
local function downloadAndPlayUrl() played = played + 1 end
local function enqueueRequestedSong() queued = queued + 1 end
${source.slice(start, end)}
assert(signal == nil, 'listener must be off by default')
toggles.ChatRequestsEnabled(true)
assert(signal ~= nil, 'enabling should connect listener')
signal({TextSource={UserId=999}, Text='!play Fur'})
assert(played == 0, 'unlisted players must not be allowed')
signal({TextSource={UserId=123}, Text='!play Fur'})
assert(played == 1, 'local player should be allowed')
signal({TextSource={UserId=123}, Text='!request Fur'})
assert(queued == 0, 'cooldown should block immediate repeat')
now = 16; inputs.ChatWhitelist('999'); toggles.ChatAllowWhitelist(true)
signal({TextSource={UserId=999}, Text='!request Fur'})
assert(queued == 1, 'explicitly whitelisted user may request')
toggles.ChatRequestsEnabled(false)
assert(disconnected, 'disabling must disconnect')
now = 22; signal({TextSource={UserId=123}, Text='!play Fur'})
assert(played == 1, 'disabled listener must ignore events')
print('Chat authorization tests passed')
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const rc = lauxlib.luaL_dostring(L, to_luastring(script));
if (rc !== lua.LUA_OK) {
    console.error(to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
}
