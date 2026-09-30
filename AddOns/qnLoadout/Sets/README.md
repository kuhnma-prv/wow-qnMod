# qnLoadout sets

One JSON file per set. After every change run

```
pwsh tools\Convert-QnLoadout.ps1
```

(converts all files into `AddOns\qnLoadout\Data.lua`, WoW cannot read JSON) and `/reload` in the game.
Exports from the game (options page qnLoadout → Export) are written here with
`pwsh tools\Convert-QnLoadout.ps1 -Import` (after logging out or `/reload`).

## Format

```json
{
  "name": "Priest Shadow",
  "class": "PRIEST",
  "desc": "Shadow levelling, G502",
  "macros": [
    { "name": "qnShield", "scope": "char", "icon": 134400,
      "body": "#showtooltip Power Word: Shield\n/cast [@player] Power Word: Shield" }
  ],
  "numpad": [
    { "key": "NUMPAD7", "spell": "Fade" },
    { "key": "NUMPAD6", "macro": "qnShield" },
    { "key": "NUMPAD6", "set": "ctrl", "empty": true }
  ]
}
```

| Field | Meaning |
|---|---|
| `name` | name of the set (shown in the game) |
| `class` | class file in capitals: `WARRIOR`, `PALADIN`, `HUNTER`, `ROGUE`, `PRIEST`, `SHAMAN`, `MAGE`, `WARLOCK`, `DRUID` |
| `desc` | optional description |
| `macros[].name` | must start with `qn` – only such macros are created or changed; other macros are never touched |
| `macros[].scope` | `char` (this character) or `account` (all characters – also changes it for your other classes) |
| `macros[].icon` | optional: icon file ID (as `GetMacroInfo` returns it; the export saves it); default 134400 = question mark (in Retail only with it `#showtooltip` shows the icon of the current spell; not checked for Forever) |
| `macros[].body` | macro text with **English** spell names, at most 255 characters, lines separated by `\n` |
| `numpad[].key` | binding name of the numpad key: `NUMPAD0`–`NUMPAD9`, `NUMPADDECIMAL`, `NUMPADPLUS`, `NUMPADMINUS`, `NUMPADMULTIPLY`, `NUMPADDIVIDE`, … |
| `numpad[].set` | optional: `ctrl` or `alt` = modifier set of qnNumKeyPad (keys 1–12 only) |
| `numpad[].spell` | **English** spell name from `Spells.json` (recommended) or spell ID |
| `numpad[].macro` | macro name (qn macro of the set or an existing macro) |
| `numpad[].empty` | `true` = clear the key |
| `numpad[].name` | optional, only for reading (the export writes the client name here when the spell is missing in `Spells.json`) |

Each numpad entry has exactly one of `spell`, `macro` or `empty`. Keys that are not listed stay
unchanged when loading; an export lists every key of the bar.

## Spell and item names: English in the files, client language in the game

`Spells.json` maps every English spell name to a spell ID (any rank), `Items.json` every English item
name to an item ID (IDs checked against Wowhead Classic): `{ "Power Word: Shield": 17, ... }`,
`{ "Healthstone": 5509, ... }`. A name must not be in both files. WoW only knows the names of the client
language, so when loading qnLoadout takes the client names from the IDs (`C_Spell.GetSpellName`,
`C_Item.GetItemNameByID`) and

- replaces the English spell and item names in the macro texts (whole names, longest first; `Heal` does not change
  `Greater Heal` or `Healing`),
- places numpad spells given by English name under their client name.

The export goes the other way: client names in macro texts and on the bar become English names. A spell
missing in `Spells.json` is exported by ID with the client name in `name` (the chat lists them) – add it
to `Spells.json` to get the English name.

Item names are often not in the client's cache yet: qnLoadout requests them after logging in and, if
needed, before loading or exporting, and waits up to 5 seconds. A name that is still missing then stays
English in the macro and is reported in the chat.