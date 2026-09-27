// Statische Prüfung der Lokalisierung der qn-Addons.
// Aufruf: node check-locale.mjs [Addon ...]   (Vorgabe: alle qn*-Addons mit TOC im AddOns-Ordner)
// Meldet je Addon:
//   FEHLT      L["…"] im Code, aber ohne englische Übersetzung in Locale.lua
//   UNBENUTZT  Übersetzung in Locale.lua, deren Schlüssel im Code nicht (mehr) vorkommt
//   DEUTSCH?   Text im Code, der deutsch aussieht, aber nicht über L[…] läuft
//   TOC        fehlendes ## Notes (Englisch) / ## Notes-deDE (Deutsch)
// Endet mit Code 1, wenn FEHLT, DEUTSCH? oder TOC vorkommen.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const ADDONS = path.resolve(here, '../..');   // qn_DevEnv/test liegt im AddOns-Ordner
const names = process.argv.slice(2).length ? process.argv.slice(2)
  : fs.readdirSync(ADDONS).filter(d => /^qn/.test(d) && fs.existsSync(path.join(ADDONS, d, d + '.toc')));

function unescape(s) {
  return s.replace(/\\(n|t|"|'|\\|\d{1,3})/g, (m, c) => c === 'n' ? '\n' : c === 't' ? '\t' : /\d/.test(c) ? String.fromCharCode(+c) : c);
}
// String-Literale mit Position; Kommentare und lange Strings überspringen
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

// deutsch aussehender Anzeigetext?
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
  // Übersetzungen
  const locFile = path.join(dir, 'Locale.lua');
  const trans = new Map();
  if (fs.existsSync(locFile)) {
    const src = fs.readFileSync(locFile, 'utf8');
    const re = /^\s*L\[\s*("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')\s*\]\s*=\s*("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/;
    src.split('\n').forEach((l, i) => {
      const m = l.match(re);
      if (m) trans.set(unescape(m[1].slice(1, -1)), { line: i + 1, en: unescape(m[2].slice(1, -1)) });
    });
  } else {
    report.push('  FEHLT      Locale.lua');
  }
  // Code
  const used = new Map();
  for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.lua') && f !== 'Locale.lua' && f !== 'Monitors.lua')) {
    const src = fs.readFileSync(path.join(dir, f), 'utf8');
    for (const lit of literals(src)) {
      const before = src.slice(Math.max(0, lit.start - 3), lit.start);
      const after = src.slice(lit.end, lit.end + 2);
      const isKey = /L\[\s*$/.test(src.slice(Math.max(0, lit.start - 4), lit.start)) && /^\s*\]/.test(after);
      if (isKey) {
        if (!used.has(lit.value)) used.set(lit.value, `${f}:${lit.line}`);
        continue;
      }
      if (looksGerman(lit.value)) {
        // bewusst deutsch (z. B. Vergleichswerte) mit Kommentar "-- nicht übersetzen" am Zeilenende
        const lineText = src.split('\n')[lit.line - 1] || '';
        if (/--\s*nicht übersetzen/i.test(lineText)) continue;
        report.push(`  DEUTSCH?   ${f}:${lit.line}  ${JSON.stringify(lit.value).slice(0, 110)}`);
      }
    }
  }
  for (const [k, where] of used) {
    if (!trans.has(k)) report.push(`  FEHLT      ${where}  ${JSON.stringify(k).slice(0, 110)}`);
  }
  for (const [k, t] of trans) {
    if (!used.has(k)) report.push(`  UNBENUTZT  Locale.lua:${t.line}  ${JSON.stringify(k).slice(0, 100)}`);
  }
  // TOC
  const toc = fs.readFileSync(path.join(dir, a + '.toc'), 'utf8');
  if (!/^## Notes:/m.test(toc)) report.push('  TOC        ## Notes: (Englisch) fehlt');
  if (!/^## Notes-deDE:/m.test(toc)) report.push('  TOC        ## Notes-deDE: fehlt');
  const errors = report.filter(r => !/UNBENUTZT/.test(r)).length;
  bad += errors;
  console.log(`${a}: ${used.size} Schlüssel, ${trans.size} Übersetzungen, ${errors} Befunde`);
  for (const r of report) console.log(r);
}
process.exit(bad ? 1 : 0);
