// Exercise queue callbacks and delayed autoplay using a mocked Obsidian UI.
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const source = fs.readFileSync(path.join(__dirname, '..', 'piano.lua'), 'utf8');
const start = source.indexOf('-- Queue items keep only source descriptors;');
const end = source.indexOf('\n-- Chat requests are opt-in.', start);
if (start < 0 || end < 0) throw new Error('Cannot find queue implementation');
const script = `
local buttons, toggles, sliders = {}, {}, {}
local box = {}
function box:AddLabel() return {} end
function box:AddDropdown(_, opts) return {SetValue=function() end} end
function box:AddButton(opts) buttons[opts.Text] = opts.Func end
function box:AddToggle(id, opts) toggles[id] = opts.Callback end
function box:AddSlider(id, opts) sliders[id] = opts.Callback end
local GlobalTab = {AddGroupbox=function() return box end}
local function setDropdownOptions(_, labels, _, suppress)
    suppress(true); suppress(false); return labels[1]
end
local function setLabelSafe() end
local function notify() end
local function normalizeMidiUrl(url) return url or '' end
local Core = {deriveTitleFromUrl=function(url) return url end, sanitizeSongEntries=function(entries) return entries end}
math.clamp = function(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local QuickState = {selected='First', map={First='https://a.mid', Second='https://b.mid'}}
local GlobalState = {selected='Match', resultsMap={Match={kind='url', label='Match', url='https://c.mid', display='Match'}}}
local customMidiUrl = 'https://d.mid'
local played, deferred = {}, nil
local function downloadAndPlayUrl(url) played[#played+1] = url end
local function globalPlayEntry(entry) played[#played+1] = entry.url end
local onPlaybackFinished, enqueueRequestedSong, enqueuePlaylist
local playbackId, playing = 1, false
task = {delay=function(_, callback) deferred = callback end}
${source.slice(start, end)}
buttons['➕ Queue selected Quick Pick']()
QuickState.selected = 'Second'
buttons['➕ Queue selected Quick Pick']()
buttons['⬇️ Move selected down']()
buttons['▶️ Play next queued song']()
assert(played[1] == 'https://b.mid', 'queue should reorder entries')
toggles.QueueAutoplay(true)
onPlaybackFinished(1)
assert(deferred ~= nil, 'autoplay should schedule next')
playbackId = 2; deferred()
assert(#played == 1, 'stop or new playback must cancel delayed autoplay')
onPlaybackFinished(2); deferred()
assert(played[2] == 'https://a.mid', 'autoplay should start next queued song')
buttons['➕ Queue selected search result']()
buttons['➕ Queue direct URL']()
buttons['▶️ Play next queued song']()
buttons['▶️ Play next queued song']()
assert(played[3] == 'https://c.mid' and played[4] == 'https://d.mid', 'queue should support search and direct URLs')
assert(enqueuePlaylist({{title='p',url='https://p.mid'}}) == 1, 'playlist should enqueue')
buttons['🗑️ Clear queue']()
buttons['▶️ Play next queued song']()
assert(#played == 4, 'cleared queue must not play')
print('Queue automation tests passed')
`;
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const rc = lauxlib.luaL_dostring(L, to_luastring(script));
if (rc !== lua.LUA_OK) {
    console.error(to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
}
