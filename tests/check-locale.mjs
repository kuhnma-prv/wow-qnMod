// Static check of the localization of the qn addons.
// Usage: node check-locale.mjs [Addon ...]   (default: all qn* addons with a TOC in the AddOns folder)
// Reports per addon:
//   MISSING    L["…"] in the code, but no German translation in Locale.lua
//   UNUSED     translation in Locale.lua whose key no longer appears in the code
//   GERMAN?    text in the code that looks German and does not go through L[…]
//   TOC        missing ## Notes (English) / ## Notes-deDE (German)
// Exits with code 1 if MISSING, GERMAN? or TOC occur.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const ADDONS = path.resolve(here, '../AddOns');   // tests and AddOns are next to each other in the repository
const names = process.argv.slice(2).length ? process.argv.slice(2)
  : fs.readdirSync(ADDONS).filter(d => /^qn/.test(d) && fs.existsSync(path.join(ADDONS, d, d + '.toc')));

function unescape(s) {
  return s.replace(/\\(n|t|"|'|\\|\d{1,3})/g, (m, c) => c === 'n' ? '\n' : c === 't' ? '\t' : /\d/.test(c) ? String.fromCharCode(+c) : c);
}
// string literals with position; skip comments and long strings
function literals(src) {
  const out = [];
  let i = 0, line = 1;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    if (c === '\n') { line++; i++; continue; }
    if (c === '-' && src[i + 1] === '-') {
      const m = src.slice(i + 2, i + 12).match(/^\[(=*)\[/);
      if (m) {
        const end = src.indexOf(']' + m[1] + ']', i);
        line += (src.slice(i, end < 0 ? n : end).match(/\n/g) || []).length;
        i = end < 0 ? n : end + m[1].length + 2;
      } else {
        while (i < n && src[i] !== '\n') i++;
      }
      continue;
    }
    if (c === '[' && /^\[=*\[/.test(src.slice(i, i + 10))) {
      const m = src.slice(i).match(/^\[(=*)\[/);
      const end = src.indexOf(']' + m[1] + ']', i);
      line += (src.slice(i, end < 0 ? n : end).match(/\n/g) || []).length;
      i = end < 0 ? n : end + m[1].length + 2;
      continue;
    }
    if (c === '"' || c === "'") {
      let j = i + 1, s = '';
      const startLine = line;
      while (j < n && src[j] !== c) {
        if (src[j] === '\\') { s += src[j] + src[j + 1]; j += 2; continue; }
        if (src[j] === '\n') line++;
        s += src[j++];
      }
      out.push({ line: startLine, value: unescape(s), start: i, end: j + 1 });
      i = j + 1;
      continue;
    }
    i++;
  }
  return out;
}

// display text that looks German (forgotten while switching to English keys)?
const GERMAN_WORDS = /\b(der|die|das|den|dem|des|und|oder|nicht|kein|keine|nur|mit|für|beim|bei|auf|aus|wird|werden|ist|sind|alle|jede[rsn]?|wenn|sonst|nach|vor|über|unter|zum|zur|im|ein|eine|einen|Fenster|Einstellung(en)?|Profil|Taschen?|Leiste|Knopf|Schrift|Größe|Farbe|Anzeigen?|Zurücksetzen|Löschen|Aktiv|Ziel|Bedrohung|Zauber)\b/;
function looksGerman(v) {
  if (!/[A-Za-zÄÖÜäöüß]{3,}/.test(v)) return false;
  if (/[äöüÄÖÜß]/.test(v)) return true;
  return GERMAN_WORDS.test(v) && /\s/.test(v);
}

let bad = 0;
for (const a of names) {
  const dir = path.join(ADDONS, a);
  const report = [];
  // translations
  const locFile = path.join(dir, 'Locale.lua');
  const trans = new Map();
  if (fs.existsSync(locFile)) {
    const src = fs.readFileSync(locFile, 'utf8');
    const re = /^\s*L\[\s*("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')\s*\]\s*=\s*("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/;
    src.split('\n').forEach((l, i) => {
      const m = l.match(re);
      if (m) trans.set(unescape(m[1].slice(1, -1)), { line: i + 1, de: unescape(m[2].slice(1, -1)) });
    });
  } else {
    report.push('  MISSING    Locale.lua');
  }
  // code
  const used = new Map();
  for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.lua') && f !== 'Locale.lua' && f !== 'Monitors.lua')) {
    const src = fs.readFileSync(path.join(dir, f), 'utf8');
    for (const lit of literals(src)) {
      const after = src.slice(lit.end, lit.end + 2);
      const isKey = /L\[\s*$/.test(src.slice(Math.max(0, lit.start - 4), lit.start)) && /^\s*\]/.test(after);
      if (isKey) {
        if (!used.has(lit.value)) used.set(lit.value, `${f}:${lit.line}`);
        continue;
      }
      if (looksGerman(lit.value)) {
        // deliberately German (e.g. comparison values) with the comment "-- do not translate" at the end of the line
        const lineText = src.split('\n')[lit.line - 1] || '';
        if (/--\s*do not translate/i.test(lineText)) continue;
        report.push(`  GERMAN?    ${f}:${lit.line}  ${JSON.stringify(lit.value).slice(0, 110)}`);
      }
    }
  }
  for (const [k, where] of used) {
    if (!trans.has(k)) report.push(`  MISSING    ${where}  ${JSON.stringify(k).slice(0, 110)}`);
  }
  for (const [k, t] of trans) {
    if (!used.has(k)) report.push(`  UNUSED     Locale.lua:${t.line}  ${JSON.stringify(k).slice(0, 100)}`);
  }
  // TOC
  const toc = fs.readFileSync(path.join(dir, a + '.toc'), 'utf8');
  if (!/^## Notes:/m.test(toc)) report.push('  TOC        ## Notes: (English) missing');
  if (!/^## Notes-deDE:/m.test(toc)) report.push('  TOC        ## Notes-deDE: missing');
  const errors = report.filter(r => !/UNUSED/.test(r)).length;
  bad += errors;
  console.log(`${a}: ${used.size} keys, ${trans.size} translations, ${errors} findings`);
  for (const r of report) console.log(r);
}
process.exit(bad ? 1 : 0);
