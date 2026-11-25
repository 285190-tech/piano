// Exercise the actual link-verifier callback with synchronous mocked workers.
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const source = fs.readFileSync(path.join(__dirname, '..', 'piano.lua'), 'utf8');
const start = source.indexOf('RepoBox:AddButton({\n    Text = "🔍 Verify All Links');
const end = source.indexOf('\n-- ==========================================\n-- Custom MIDI List', start);
if (start < 0 || end < 0) throw new Error('Cannot find link verifier');
const script = `
local verify, statusText, summaryText, waits, throwRequest, cancelRequest
local RepoBox = {AddButton=function(_, opts) verify = opts.Func end}
local QuickState = {verifying=false, verifyAbort=false, verifyFailures={}, order={'one','two'}, map={one='u1',two='u2'}}
local QuickStatusLabel, QuickVerifyLabel = {}, {}
local function setLabelSafe(label, text)
    if label == QuickStatusLabel then statusText = text else summaryText = text end
end
local function notify() end
function warn() end
local function safeRequest(url)
    if throwRequest then error('simulated worker error') end
    if cancelRequest then cancelRequest = false; verify() end
    return true, {StatusCode=200, Body='MThd'}, nil
end
local function getResponseBody(res) return res and res.Body end
task = {spawn=function(fn) fn() end, wait=function()
    waits = (waits or 0) + 1
    assert(waits < 20, 'verification did not finish')
end}
${source.slice(start, end)}
waits = 0; verify()
assert(not QuickState.verifying and statusText == 'Link verification finished.', 'normal verification must finish')
assert(summaryText:find('Checked: 2 / 2', 1, true), 'normal summary should report both links')
waits, cancelRequest = 0, true; verify()
assert(not QuickState.verifying and statusText == 'Link verification cancelled.', 'cancellation must finish')
assert(summaryText:find('Checked: 1 / 2', 1, true), 'cancel summary should report completed work')
waits, throwRequest = 0, true; verify()
assert(not QuickState.verifying and QuickState.verifyAbort, 'worker errors must unlock verifier')
assert(summaryText:find('Verifier error:', 1, true), 'worker errors must be reported')
print('Link verification tests passed')
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const rc = lauxlib.luaL_dostring(L, to_luastring(script));
if (rc !== lua.LUA_OK) {
    console.error(to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
}
