// Laedt stub.lua + ein Testszenario in fengari (Lua-VM in JS).
// Aufruf: node run.mjs [<Szenario.lua>] [<AddOns-Ordner>]
//   Vorgaben: test.lua, der AddOns-Ordner von WoW Classic Forever (_classic_beta_)
//   Sprache des Clients: Umgebungsvariable QN_LOCALE (deDE, enUS; Vorgabe deDE)
// Auf nicht-deutschen Clients listet der Lauf zum Schluss alle Texte, die ohne Übersetzung
// angezeigt wurden (qnCore.missing), und endet dann mit Code 2.
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import path from 'path';
import { ensureGlobalStrings } from './globalstrings.mjs';
const require = createRequire(import.meta.url);
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const fs = require('fs');
const here = path.dirname(fileURLToPath(import.meta.url)).replace(/\\/g, '/') + '/';
const scenario = process.argv[2] || 'test.lua';
// qn_DevEnv/test liegt im AddOns-Ordner selbst
const addons = (process.argv[3] || path.resolve(here, '../..')).replace(/\\/g, '/');
await ensureGlobalStrings([process.env.QN_LOCALE || 'deDE']);   // stub.lua lädt die der Sprache
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
    console.log('FEHLER in ' + f + ': ' + lua.lua_tojsstring(L, -1));
    process.exit(1);
  }
}
const report = `
  local n = 0
  if qnCore and not qnCore.GERMAN then
    local addons = {}
    for addon in pairs(qnCore.missing) do addons[#addons + 1] = addon end
    table.sort(addons)
    for _, addon in ipairs(addons) do
      local keys = {}
      for key in pairs(qnCore.missing[addon]) do keys[#keys + 1] = tostring(key) end
      table.sort(keys)
      for _, key in ipairs(keys) do
        print("OHNE ÜBERSETZUNG " .. addon .. ": " .. key)
        n = n + 1
      end
    end
  end
  return n`;
if (lauxlib.luaL_dostring(L, to_luastring(report)) !== 0) {
  console.log('FEHLER im Übersetzungsbericht: ' + lua.lua_tojsstring(L, -1));
  process.exit(1);
}
if (lua.lua_tointeger(L, -1) > 0) process.exit(2);
