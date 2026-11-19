// tests/run_tests.js
// Runs tests/run_tests.lua with fengari (Lua 5.3 implemented in JavaScript),
// for environments without a Lua interpreter installed.
//
//   cd tests && npm install && node run_tests.js

const fs = require("fs");
const path = require("path");
const fengari = require("fengari");
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = fengari;

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

function run(source, label) {
    if (lauxlib.luaL_loadstring(L, to_luastring(source)) !== 0) {
        const msg = lua.lua_tolstring(L, -1, null);
        throw new Error(`Failed to compile ${label}: ${to_jsstring(msg)}`);
    }
    const status = lua.lua_pcall(L, 0, 0, 0);
    if (status !== 0) {
        const msg = lua.lua_tolstring(L, -1, null);
        throw new Error(`Error running ${label}: ${to_jsstring(msg)}`);
    }
}

function runFile(file, argCount, resultCount) {
    const src = fs.readFileSync(file, "utf8");
    if (lauxlib.luaL_loadstring(L, to_luastring(src)) !== 0) {
        const msg = lua.lua_tolstring(L, -1, null);
        throw new Error(`Failed to compile ${file}: ${to_jsstring(msg)}`);
    }
    const status = lua.lua_pcall(L, argCount, resultCount, 0);
    if (status !== 0) {
        const msg = lua.lua_tolstring(L, -1, null);
        throw new Error(`Error running ${file}: ${to_jsstring(msg)}`);
    }
}

// fengari 0.1.5 does not open the bit32 library and emulates Lua 5.3
// integers with JS int32, so bitwise operands must stay in int32 range.
// The shim converts uint32 values to signed int32 for the operation and
// converts results back to uint32 — all with exact double arithmetic.
// (Real Lua 5.3+ interpreters already ship bit32, so this is a no-op there.)
const BIT32_SHIM = `
if bit32 == nil then
    local BIG = tonumber("4294967296")
    local SPLIT = tonumber("2147483648")
    local function toint32(v)
        v = tonumber(v)
        if v == nil then return 0 end
        v = v % BIG
        if v >= SPLIT then v = v - BIG end
        return math.tointeger(v)
    end
    local function touint32(v)
        if v < 0 then v = v + BIG end
        return v
    end
    bit32 = {}
    function bit32.band(...)
        local r = toint32(select(1, ...))
        for i = 2, select('#', ...) do r = r & toint32(select(i, ...)) end
        return touint32(r)
    end
    function bit32.bor(...)
        local r = toint32(select(1, ...))
        for i = 2, select('#', ...) do r = r | toint32(select(i, ...)) end
        return touint32(r)
    end
    function bit32.bxor(a, b)
        return touint32(toint32(a) ~ toint32(b))
    end
    function bit32.bnot(a)
        return touint32(~toint32(a))
    end
    function bit32.lshift(a, b)
        return touint32(toint32(a) << toint32(b))
    end
    function bit32.rshift(a, b)
        return touint32(toint32(a) >> toint32(b))
    end
end
`;
run(BIT32_SHIM, "bit32 shim");

try {
    // Load core.lua and expose the returned module as a global so the
    // test file picks it up without needing io/loadfile.
    runFile(path.join(__dirname, "..", "core.lua"), 0, 1);
    lua.lua_setglobal(L, to_luastring("CORE_MODULE"), -1);

    runFile(path.join(__dirname, "run_tests.lua"), 0, 0);

    const summary = lua.lua_getglobal(L, to_luastring("__TEST_SUMMARY"));
    if (summary !== lua.LUA_TNIL) {
        lua.lua_getfield(L, -1, to_luastring("passed"));
        const passed = lua.lua_tointeger(L, -1);
        lua.lua_pop(L, 1);
        lua.lua_getfield(L, -1, to_luastring("failed"));
        const failed = lua.lua_tointeger(L, -1);
        console.log(`\nSummary: ${passed} passed, ${failed} failed`);
        process.exit(failed === 0 ? 0 : 1);
    }
    console.log("Tests ran (no summary captured)");
    process.exit(1);
} catch (err) {
    console.error(err.message);
    process.exit(1);
}
