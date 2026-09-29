// Look up the Blizzard GlobalStrings of Forever (GlobalStrings/deDE.lua, enUS.lua).
//   node gs.mjs "Bank" "Händler"     GlobalStrings whose German text is exactly this
//   node gs.mjs -k DELETE CANCEL     German and English text for keys
//   node gs.mjs -s "Zeitstempel"     German text contains the search text (at most 25 hits)
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { ensureGlobalStrings } from './globalstrings.mjs';

await ensureGlobalStrings();
const here = path.dirname(fileURLToPath(import.meta.url));
function unescape(s) {
  return s.replace(/\\(n|t|"|\\)/g, (m, c) => c === 'n' ? '\n' : c === 't' ? '\t' : c);
}
function read(loc) {
  const map = new Map();
  const re = /^(?:_G\["([^"]+)"\]|([A-Za-z_][A-Za-z0-9_]*)) = "((?:[^"\\]|\\.)*)";/;
  for (const l of fs.readFileSync(path.join(here, 'GlobalStrings', loc + '.lua'), 'utf8').split('\n')) {
    const m = l.match(re);
    if (m) map.set(m[1] || m[2], unescape(m[3]));
  }
  return map;
}
const de = read('deDE'), en = read('enUS');
const args = process.argv.slice(2);
const show = k => console.log(`  ${k}\n      de: ${JSON.stringify(de.get(k))}\n      en: ${JSON.stringify(en.get(k))}`);
if (args[0] === '-k') {
  for (const k of args.slice(1)) show(k);
} else if (args[0] === '-s') {
  const q = args[1].toLowerCase();
  let n = 0;
  for (const [k, v] of de) if (v.toLowerCase().includes(q) && en.has(k) && n++ < 25) show(k);
} else {
  for (const q of args) {
    const hits = [...de].filter(([k, v]) => v === q && en.has(k)).map(([k]) => k)
      .sort((a, b) => a.length - b.length);
    console.log(`${JSON.stringify(q)}: ${hits.length ? '' : 'no GlobalString'}`);
    for (const k of hits.slice(0, 8)) show(k);
  }
}
