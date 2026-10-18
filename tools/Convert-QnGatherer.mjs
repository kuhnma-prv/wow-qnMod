// Offline import for qnGatherer (called by Convert-QnGatherer.ps1).
// Runs qnGatherer's own import adapters (AddOns\qnGatherer\Import*.lua) in fengari (Lua VM in JS)
// on the data of GatherMate2 / GatherTogether read from the user's files, and writes the records into
// qnGathererDB.global.pendingImport of the SavedVariables file qnGatherer.lua. qnGatherer takes them
// over on the next login. Nothing of the other addons becomes part of qnGatherer.
//
// Usage: node Convert-QnGatherer.mjs <json options>
//   { savedVariables, gatherMate2, gatherTogether, locale, repo }
//     savedVariables  folder WTF\Account\<account>\SavedVariables (GatherMate2.lua, GatherTogether.lua, qnGatherer.lua)
//     gatherMate2     addon folder of GatherMate2 (optional; node names from Constants.lua and Locales)
//     gatherTogether  addon folder of GatherTogether (optional; its data files)
//     locale          client language, e.g. deDE
//     repo            repository root (AddOns\qnGatherer, tests\node_modules)
import { createRequire } from 'module';
import path from 'path';
import fs from 'fs';

const opts = JSON.parse(process.argv[2] || '{}');
const repo = opts.repo;
const require = createRequire(path.join(repo, 'tests', 'package.json'));
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

function fail(msg) {
  console.error('ERROR: ' + msg);
  process.exit(1);
}
function run(code, name) {
  if (lauxlib.luaL_loadbuffer(L, to_luastring(code), null, to_luastring(name)) !== 0 || lua.lua_pcall(L, 0, 0, 0) !== 0) {
    fail(name + ': ' + lua.lua_tojsstring(L, -1));
  }
}
function runFile(file) {
  const bytes = fs.readFileSync(file);
  if (lauxlib.luaL_loadbuffer(L, bytes, null, to_luastring('@' + file)) !== 0 || lua.lua_pcall(L, 0, 0, 0) !== 0) {
    fail(file + ': ' + lua.lua_tojsstring(L, -1));
  }
}
const quote = (s) => JSON.stringify(s);   // valid Lua string literal for plain texts

// Version of an addon from its TOC
function tocVersion(folder, name) {
  try {
    const toc = fs.readFileSync(path.join(folder, name + '.toc'), 'utf8');
    const m = toc.match(/^## Version:\s*(.+)$/m);
    return m ? m[1].trim() : null;
  } catch { return null; }
}

// GatherMate2 node names: node_ids in Constants.lua (English), translated with NL[...] of the locale file
function gatherMate2Names(folder, locale) {
  const constants = fs.readFileSync(path.join(folder, 'Constants.lua'), 'utf8');
  const start = constants.indexOf('local node_ids = {');
  if (start < 0) return null;
  const names = {};
  let type = null, depth = 0;
  for (const raw of constants.slice(start).split('\n')) {
    const line = raw.replace(/--.*$/, '');
    const section = line.match(/^\s*\["([^"]+)"\]\s*=\s*\{/);
    if (depth === 1 && section) { type = section[1]; names[type] = {}; }
    const node = line.match(/^\s*\["([^"]+)"\]\s*=\s*(\d+)/);
    if (depth === 2 && type && node) names[type][Number(node[2])] = node[1];
    depth += (line.match(/\{/g) || []).length - (line.match(/\}/g) || []).length;
    if (depth <= 0 && line.includes('}')) break;
  }
  const translations = {};
  const file = path.join(folder, 'Locales', `GatherMate2-${locale}.lua`);
  if (locale !== 'enUS' && fs.existsSync(file)) {
    for (const m of fs.readFileSync(file, 'utf8').matchAll(/^\s*NL\["([^"]+)"\]\s*=\s*"([^"]*)"/gm)) {
      translations[m[1]] = m[2];
    }
  }
  let lua = 'QNGATHERER_GM2_NAMES = {\n';
  for (const [t, nodes] of Object.entries(names)) {
    lua += `  [${quote(t)}] = {\n`;
    for (const [id, en] of Object.entries(nodes)) {
      lua += `    [${id}] = ${quote(translations[en] || en)},\n`;
    }
    lua += '  },\n';
  }
  return lua + '}\n';
}

// Environment of the adapters
const versions = {
  GatherMate2: opts.gatherMate2 ? tocVersion(opts.gatherMate2, 'GatherMate2') : null,
  GatherTogether: opts.gatherTogether ? tocVersion(opts.gatherTogether, 'GatherTogether') : null,
};
run(`
  LOCALE = ${quote(opts.locale || 'enUS')}
  function GetLocale() return LOCALE end
  local versions = { GatherMate2 = ${quote(versions.GatherMate2 || 'offline')}, GatherTogether = ${quote(versions.GatherTogether || 'offline')} }
  C_AddOns = { GetAddOnMetadata = function(name, field) if field == "Version" then return versions[name] end end }
`, 'environment');

// Saved variables
const sv = opts.savedVariables;
for (const name of ['GatherMate2.lua', 'GatherTogether.lua', 'qnGatherer.lua']) {
  const file = path.join(sv, name);
  if (fs.existsSync(file)) runFile(file);
}

// Data files of GatherTogether (plain tables)
if (opts.gatherTogether) {
  for (const name of ['Data.lua', 'FishData.lua', 'FishingAreas.lua', 'ReportedAreas.lua', 'GatheringData.lua', 'SkinningData.lua', 'MapOverlays.lua']) {
    const file = path.join(opts.gatherTogether, name);
    if (fs.existsSync(file)) runFile(file);
  }
}

// Node names of GatherMate2
if (opts.gatherMate2) {
  const names = gatherMate2Names(opts.gatherMate2, opts.locale || 'enUS');
  if (names) run(names, 'GatherMate2 names');
}

// The adapters with a small namespace: catalog of qnGatherer for names that are already known
run(`
  ADAPTERS = {}
  NS = {
    Import = { Register = function(a) ADAPTERS[#ADAPTERS + 1] = a end },
    DB = {
      FindRes = function(kind, name, locale)
        local g = qnGathererDB and qnGathererDB.global
        for res, e in pairs(g and g.catalog or {}) do
          if e.kind == kind and e.names and e.names[locale] == name then return res end
        end
      end,
    },
  }
`, 'namespace');
for (const name of ['ImportGatherMate2.lua', 'ImportGatherTogether.lua']) {
  const file = path.join(repo, 'AddOns', 'qnGatherer', name);
  const bytes = fs.readFileSync(file);
  if (lauxlib.luaL_loadbuffer(L, bytes, null, to_luastring('@' + file)) !== 0) fail(name + ': ' + lua.lua_tojsstring(L, -1));
  lua.lua_pushstring(L, to_luastring('qnGatherer'));
  lua.lua_getglobal(L, to_luastring('NS'));
  if (lua.lua_pcall(L, 2, 0, 0) !== 0) fail(name + ': ' + lua.lua_tojsstring(L, -1));
}

// Run the adapters, append to pendingImport, write qnGathererDB back
run(`
  qnGathererDB = type(qnGathererDB) == "table" and qnGathererDB or {}
  qnGathererDB.global = type(qnGathererDB.global) == "table" and qnGathererDB.global or {}
  local g = qnGathererDB.global
  g.pendingImport = type(g.pendingImport) == "table" and g.pendingImport or {}
  SUMMARY = {}
  for _, a in ipairs(ADAPTERS) do
    if a.Available() then
      local records = {}
      a.Read(function(rec) records[#records + 1] = rec end)
      g.pendingImport[#g.pendingImport + 1] = { adapter = a.key, version = a.Version(), records = records }
      SUMMARY[#SUMMARY + 1] = a.name .. ": " .. #records
    end
  end

  -- serializer in the style of WoW's saved variables (sorted keys)
  local function key(k)
    if type(k) == "string" then return ("[%q]"):format(k) end
    return "[" .. (math.type(k) == "integer" and ("%d"):format(k) or ("%.17g"):format(k)) .. "]"
  end
  local function value(v, indent, out)
    local t = type(v)
    if t == "string" then out[#out + 1] = ("%q"):format(v)
    elseif t == "number" then out[#out + 1] = math.type(v) == "integer" and ("%d"):format(v) or ("%.17g"):format(v)
    elseif t == "boolean" then out[#out + 1] = tostring(v)
    elseif t == "table" then
      out[#out + 1] = "{\\n"
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == "number"
      end)
      for _, k in ipairs(keys) do
        out[#out + 1] = indent .. "\\t" .. key(k) .. " = "
        value(v[k], indent .. "\\t", out)
        out[#out + 1] = ",\\n"
      end
      out[#out + 1] = indent .. "}"
    else out[#out + 1] = "nil" end
  end
  local out = { "\\nqnGathererDB = " }
  value(qnGathererDB, "", out)
  out[#out + 1] = "\\n"
  RESULT = table.concat(out)
`, 'convert');

lua.lua_getglobal(L, to_luastring('SUMMARY'));
const summary = [];
for (let i = 1; ; i++) {
  lua.lua_rawgeti(L, -1, i);
  if (lua.lua_isnil(L, -1)) { lua.lua_pop(L, 1); break; }
  summary.push(lua.lua_tojsstring(L, -1));
  lua.lua_pop(L, 1);
}
lua.lua_pop(L, 1);
if (summary.length === 0) fail('no data of GatherMate2 or GatherTogether found');

lua.lua_getglobal(L, to_luastring('RESULT'));
const result = lua.lua_tostring(L, -1);   // bytes (UTF-8 as in the source files)
const target = path.join(sv, 'qnGatherer.lua');
if (fs.existsSync(target)) fs.copyFileSync(target, target + '.bak');
fs.writeFileSync(target, Buffer.from(result));
console.log('Records written to ' + target + ':');
for (const s of summary) console.log('  ' + s);
