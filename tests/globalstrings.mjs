// Download the Blizzard GlobalStrings of WoW Classic Forever (deDE, enUS) on demand.
// The files are not in the repo; run.mjs and gs.mjs fetch missing ones automatically.
// Source: https://github.com/Ketho/BlizzardInterfaceResources, branch forever, Resources/GlobalStrings.
// Usage: node globalstrings.mjs [--update]   (--update: reload existing files)
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
    console.error(`GlobalStrings ${loc}: loading from ${SOURCE}`);
    const res = await fetch(SOURCE + loc + '.lua');
    if (!res.ok) throw new Error(`GlobalStrings ${loc}: HTTP ${res.status}`);
    // load completely first, then write: no half-written file on abort
    fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await ensureGlobalStrings(LOCALES, process.argv.includes('--update'));
}
