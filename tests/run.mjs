// Loads stub.lua + one test scenario in fengari (Lua VM in JS).
// Usage: node run.mjs [<Addon/scenario.lua>] [<AddOns folder>]
//   Defaults: qnCore/test1.lua, the AddOns folder next to tests (in the repository)
//   Client language: environment variable QN_LOCALE (deDE, enUS; default deDE)
// On German clients the run finally lists all texts that were shown without translation
// (qnCore.missing) and then exits with code 2.
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import path from 'path';
import { ensureGlobalStrings } from './globalstrings.mjs';
const require = createRequire(import.meta.url);
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const fs = require('fs');
const here = path.dirname(fileURLToPath(import.meta.url)).replace(/\\/g, '/') + '/';
// scenario relative to this folder, separated by / or \ (qnCore/test1.lua)
const scenario = (process.argv[2] || 'qnCore/test1.lua').replace(/\\/g, '/');
// tests and AddOns are next to each other in the repository
const addons = (process.argv[3] || path.resolve(here, '../AddOns')).replace(/\\/g, '/');
await ensureGlobalStrings([process.env.QN_LOCALE || 'deDE']);   // stub.lua loads those of the language
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
function setString(name, value) {
  lua.lua_pushstring(L, to_luastring(value));
  lua.lua_setglobal(L, to_luastring(name));
}
lua.lua_pushjsfunction(L, (L) => { const p = lua.lua_tojsstring(L, 1); let s; try { s = fs.readFileSync(p); } catch (e) { return 0; } lua.lua_pushstring(L, s); return 1; });
lua.lua_setglobal(L, to_luastring('READFILE'));
setString('ADDONS', addons);
setString('SCENARIO', scenario);
setString('TESTDIR', here);
setString('LOCALE', process.env.QN_LOCALE || 'deDE');
for (const f of ['stub.lua', scenario]) {
  if (lauxlib.luaL_dofile(L, to_luastring(here + f)) !== 0) {
    console.log('ERROR in ' + f + ': ' + lua.lua_tojsstring(L, -1));
    process.exit(1);
  }
}
const report = `
  local n = 0
  if qnCore and qnCore.GERMAN then
    local addons = {}
    for addon in pairs(qnCore.missing) do addons[#addons + 1] = addon end
    table.sort(addons)
    for _, addon in ipairs(addons) do
      local keys = {}
      for key in pairs(qnCore.missing[addon]) do keys[#keys + 1] = tostring(key) end
      table.sort(keys)
      for _, key in ipairs(keys) do
        print("NOT TRANSLATED " .. addon .. ": " .. key)
        n = n + 1
      end
    end
  end
  return n`;
if (lauxlib.luaL_dostring(L, to_luastring(report)) !== 0) {
  console.log('ERROR in the translation report: ' + lua.lua_tojsstring(L, -1));
  process.exit(1);
}
if (lua.lua_tointeger(L, -1) > 0) process.exit(2);
