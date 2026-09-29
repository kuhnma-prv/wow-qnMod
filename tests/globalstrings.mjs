// Blizzard-GlobalStrings von WoW Classic Forever (deDE, enUS) bei Bedarf herunterladen.
// Die Dateien liegen nicht im Repo; run.mjs und gs.mjs holen fehlende automatisch.
// Quelle: https://github.com/Ketho/BlizzardInterfaceResources, Zweig forever, Resources/GlobalStrings.
// Aufruf: node globalstrings.mjs [--update]   (--update: vorhandene Dateien neu laden)
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
export const DIR = path.join(here, 'GlobalStrings');
export const LOCALES = ['deDE', 'enUS'];
const SOURCE = 'https://raw.githubusercontent.com/Ketho/BlizzardInterfaceResources/forever/Resources/GlobalStrings/';

export async function ensureGlobalStrings(locales = LOCALES, update = false) {
  fs.mkdirSync(DIR, { recursive: true });
  for (const loc of locales) {
    const file = path.join(DIR, loc + '.lua');
    if (!update && fs.existsSync(file)) continue;
    console.error(`GlobalStrings ${loc}: lade von ${SOURCE}`);
    const res = await fetch(SOURCE + loc + '.lua');
    if (!res.ok) throw new Error(`GlobalStrings ${loc}: HTTP ${res.status}`);
    // erst vollständig laden, dann schreiben: kein halber Stand bei Abbruch
    fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await ensureGlobalStrings(LOCALES, process.argv.includes('--update'));
}
