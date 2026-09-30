# qn addons for WoW Classic Forever

Repository `D:\Games\dev\wow-qnMod` for **WoW Classic Forever** (flavor wow_classic_beta,
build 1.60.1, `## Interface: 16001`, game type **camelot**, Midnight engine).
Applies to the qn* addons. **Auctionator and Titan* are third-party addons: do not touch, do not include**
(read Titan only as the interface for qnViewPort/qnInventory).

Development language is **English** (code, comments, commit messages, keys of the localization).
Replies to the user are in German.

## Layout

```
AddOns\        all addons of the client; only qn* are in the repository (the rest is excluded via .gitignore)
tests\         test environment (fengari, stub.lua, scenarios per addon)
tools\         developer tools (Get-Screen, Get-WowWindow, New-QnPatterns)
docs\plans\    plans and working notes – always put plans here; content is not in the repository
.github\       Actions: test.yml (tests + translations), release.yml (ZIP on tag v*)
```

WoW loads the addons through a junction: `…\World of Warcraft\_classic_beta_\Interface\AddOns` →
`D:\Games\dev\wow-qnMod\AddOns`. Paths inside addons (TOC, textures) stay `Interface\AddOns\…`.

Addons in `_retail_`, `_classic_`, `_anniversary_`, `_classic_era_` do not belong to this project:
do not touch them, do not use them as template or source, do not mention them in code.

## Addons

| Addon | Purpose | SavedVariables |
|---|---|---|
| qnCore | main addon + library (global `qnCore`): profiles, settings builder, widgets, automatic bag handling, remembering minimap tracking, objective tracker font below 12 (per profile, `QuestTracker.lua`), page "Profiles" | qnCoreDB (with its own `profiles`), qnCoreCharDB |
| qnThreatMeter | threat meter | qnThreatMeterDB |
| qnNumKeyPad | numpad action bar; gaming mouse (Logitech G502) with button → numpad key assignment, account-wide in `global` (`Mice.lua`, page "Mouse"); page "Mouse Buttons" places spells/macros into the bar's own action slot of each button's numpad key (`MouseActions.lua`, PlaceAction, not in combat); modifier sets: while Ctrl/Alt is held keys 1–12 page to `ctrlPage` (15) / `altPage` (2) via the "page" state driver, CTRL-/ALT- bindings only for keys 1–12; arrow keys and Alt set switched off for now (Sanitize, disabled controls; code stays) | qnNumKeyPadProfiles |
| qnLoadout | sets of qn macros + qnNumKeyPad assignments per class: JSON in `qnLoadout\Sets` (English spell/item names, `Spells.json`/`Items.json` = English name → ID, translated into the client language via `Translate.lua`; item names loaded asynchronously) → `tools\Convert-QnLoadout.ps1` → `Data.lua`; loading only creates/edits macros with prefix `qn` (`EditMacro` keeps bar places, nothing deleted) and places via the global API `qnNumKeyPad` (= its ns); export on the options page + `qnLoadoutDB.exports`, `Convert-QnLoadout.ps1 -Import` writes JSON | qnLoadoutDB |
| qnViewPort | smaller 3D area, border color/pattern, dual-monitor mode; with Titan (OptionalDeps) Titan bars per monitor and tooltips at the monitor edge (`Titan.lua`); bag slot tooltips entirely on the bag's monitor (`Layout.FitToMonitor`, for other bag views `qnViewPort.BagTooltip(tip, owner)`, used by qnInventory); Minimap tooltips (tracking, zone text, mail, calendar, clock) and the tracking menu entirely on the minimap's monitor; opt-in clock window (TimeManagerFrame) below the clock (`SecondScreen.lua`) | qnViewPortDB |
| qnInventory | items/gold per character, tooltip lines; bags/bank/mail views of every character (replicas of Blizzard's windows with character selection, `View*.lua`); with Titan (OptionalDeps) plugins `qnInvBank`/`qnInvGold` (`Titan.lua`, texts from Titan's localization); account bank in `qnInventoryDB.account` (gold always, content at the banker); account-wide options (`qnInventoryDB.options`: other faction in tooltips/views, opt-in), delete character | qnInventoryDB |
| qnBuffMod | freely configurable aura windows | qnBuffModDB |
| qnUnitFrames | click casting (like HealBot) on Blizzard's party/raid frames via secure attributes; bindings per profile and class | qnUnitFramesDB |
| qnTooltip | tooltips: appearance (own backdrop instead of NineSlice), position only on request, unit header lines built from elements (pages "Lines"), health bar, target, item level, IDs | qnTooltipDB |

All except qnCore: `## Dependencies: qnCore`, `## IconTexture: Interface\AddOns\qnCore\Media\qnIcon`,
`## Category-<language>:` like Titan (Benutzerinterface/User Interface), `## Title: qnMod [|cffeda55f<short name>|r] |cff00aa00<version>|r` (like Titan; update the version in the title with every change of
`## Version`). On load `qnCore.NewAddon(ns, ADDON)` (sets version, Print, IsSecret, Plain, AnySecret,
`ns.events` = event hub, `ns.OnLoad(fn)` for the addon's own ADDON_LOADED).

**Shared code belongs in qnCore** as soon as it occurs in at least 3 addons; the addons then use the
library instead of own copies. Available among others: `qnCore.RegisterSlash`, `qnCore.Settings.NewCategory`/`SetIn`,
`store:Set`/`SetValues`, `qnCore.DeferInCombat`, `qnCore.Debounce`, `qnCore.ClassColor(classFile)`,
`qnCore.Popup.Confirm`/`EditText`, `qnCore.AnchorFactors`/`PointOffset`/`NearestCorner`, `qnCore.PointEntries(cornersOnly)` (anchor points for a dropdown), `qnCore.Visible`
(bring frames into the visible area; qnViewPort provides the monitors), `qnCore.UI.*` (canvas building blocks, `UI.Page` for every canvas page),
`qnCore.Patterns` (own tile patterns `{ key, name, file, LSM name }` in `qnCore\Media\Patterns`,
generated with `tools\New-QnPatterns.ps1`, additionally registered with LibSharedMedia as "qn …").

## User requirements

- **No compatibility layers** for other WoW versions. Use Forever APIs directly, check them in the
  Forever source first. Guards only for C/widget functions that cannot be verified.
- **A choice among several options is always a dropdown button** that shows the active selection
  (`qnCore.UI.Dropdown` on canvas pages, `Settings.CreateDropdown` on proxy pages). No cycle buttons.
- **Options in Blizzard's settings window** (Settings API), not in own option windows.
- **Uniform look of all options pages** like Blizzard's vertical pages: at the top the title
  = name of the page (as in the list on the left, without addon prefix), optionally the "Defaults" button to the right,
  below it the divider, below that the content with a scroll bar (only visible if it does not fit).
  - Where possible, vertical pages (`Settings.RegisterVerticalLayout…`, `qnCore.Settings`) – they provide this.
  - Free-form pages (canvas) **always via `qnCore.UI.Page(title, { desc, descWidth, defaults })`**
    (`Widgets.lua`, replica of Blizzard's `SettingsListTemplate`): returns `panel` (register, OnShow etc.),
    `content` (parent of all controls), `top` (anchor for the first element: the description),
    `Fit()` (call after showing/hiding elements), `padLeft`/`padTop`. Do not build own titles,
    dividers or scroll areas.
  - Page description via `desc` (below the divider), not in the title.
  - "Defaults" (`defaults`) only if there is a real reset to this page's defaults; then
    no own reset button in the content.
  - Lists (rows) live directly in the content and scroll with the page – no second, inner list with
    its own mouse wheel scrolling.
- **Profiles:** active profile = active Edit Mode layout (`preset:<n>`, `account:<name>`,
  `char:<name-realm>:<name>`), take character-specific layouts into account. New layout = copy of the
  previously active profile. Register via `qnCore.Profiles.Register{ ns, sv, defaults, settingsVersion,
  migrations, obsolete, sanitize, onSwitch }` (name comes from NewAddon); `ns.db` is always the active profile.
- **Settings version per addon** (`settingsVersion`, stored in the saved variable, independent of the
  addon version, started with `"1.0"`):
  - **minor** (`1.0` → `1.1`): something new (the defaults fill it in) or something dropped without
    replacement (key into `obsolete`).
  - **major** (`1.x` → `2.0`): only if stored data has to be converted; then add exactly one
    `migrations[2] = function(sv) … end` that converts every profile (`sv.profiles`) and `sv.global`.
  - Saved variables without profiles (e.g. `qnInventoryDB`) use `qnCore.Migrate(sv, { name, settingsVersion,
    migrations, print })` directly. A stored major newer than the code is left untouched (warning in chat).
  - `sanitize(db)` repairs invalid values on every load (setting a value to nil brings back its default);
    it is not a migration. Old conversions from before 1.0 do not exist anymore – the addons only run on
    the user's PC and the saved data there is current.
  - Every migration gets a test scenario.
- **qnCore's bag and tracking options are always account-wide** (`qnCoreDB.global`), never per profile/character (the remembered tracking selection itself is per character).
- **Never move Blizzard frames automatically** (do not hook into events/hooks), only through an
  explicit action in the options. Exceptions only as opt-in (bags, zone map in qnViewPort).
- When restructuring settings: keep previous values via the settings version (see above).
- Comments in English. Display texts are written in English and **always localized**
  (English + German, see "Localization").

## Localization

- **English is the source language; German clients get the German translation.** Behavior in the
  game: German client → German texts, every other client → English texts. Mechanism in qnCore
  (`Library.lua`): key = English text; `ns.L["English text"]` returns the key itself on non-German
  clients and the German translation on deDE. If it is missing, English appears on deDE and
  `/qncore locale` lists it there.
- Every addon has a `Locale.lua` (in the TOC before all files with texts; for qnCore directly after
  `Library.lua`):
  `local ADDON, ns = ...` / `local L = qnCore.NewLocale(ns, ADDON)` / `if not qnCore.GERMAN then return end` /
  `L["English text"] = "Deutscher Text"`. In all other files `local L = ns.L`.
- **Order when choosing a text:**
  1. **Blizzard GlobalString** if there is one whose **English text exactly matches** the intended
     English text and whose meaning fits: then use the Blizzard variable directly in the code
     (`BANK`, `DELETE`, `CANCEL`, `DEFAULT`, `GENERAL` …), no own key; the German text then comes from
     Blizzard. Look it up: `node tests\gs.mjs "Text"` (Forever GlobalStrings deDE/enUS in `tests\GlobalStrings`).
  2. Otherwise an own English key with German translation (use Blizzard terms: Edit Mode, Action Bar,
     Bags … and their German Blizzard equivalents: Bearbeitungsmodus, Aktionsleiste, Taschen …).
- Do not piece texts together: whole sentences as one key, values via `%s`/`%d`
  (`L["%s: on open"]:format(name)`). Multi-line help texts as one key.
- Not translated: slash commands, addon names, setting keys, event names, pure developer hints
  (mark with `-- do not translate` at the end of the line). Slash commands and their subcommands are
  English only – no German aliases.
- TOC: `## Notes:` English, `## Notes-deDE:` German.
- Check: `node tests\check-locale.mjs [Addon]` (missing/unused translations, leftover German texts
  outside `L[…]`, TOC) and `Invoke-QnTests.ps1` (runs on deDE **and** enUS; on deDE a scenario fails
  if a text was shown without translation). Never pin tests to displayed texts of one language, use
  `ns.L[...]`/`qnCore.GERMAN` instead.

## Forever specifics (verified in the source)

- **Secret values:** API results can be secret (`issecretvalue`). Do not compute with them, compare them
  or test them for truth; only pass them to SetText/SetFormattedText/StatusBar:SetValue/AbbreviateLargeNumbers.
  Helpers: `qnCore.IsSecret`, `qnCore.Plain(v, fallback)`. Aura data
  (`SecretWhenUnitAuraRestricted`), threat and damage meter values can be secret in combat.
- **Taint + secret values:** Blizzard code that reads auras fails as soon as its execution is tainted
  ("Auras cannot be accessed when secret while tainted"). Therefore never trigger Blizzard's updates
  from addon code (e.g. `ObjectiveTrackerManager:UpdateAll` – the scenario module reads auras
  via `ShouldShowMawBuffs`) and never write fields into Blizzard's tables; only `hooksecurefunc`.
- Combat log is blocked for addons. Built-in damage meter (`C_DamageMeter`) is available.
- **Mind the load conditions:** Forever loads Blizzard files only according to `[AllowLoadGameType …]` in the
  Blizzard TOCs. Example: `SecureAuraHeaderTemplate` does not exist (only game type classic) → qnBuffMod
  uses insecure windows only. For templates/files always check the TOC condition, not only whether the
  file exists.
- **Last names:** `UnitName` returns first and **last name** (not the realm; `NameUtil.GetUnitFirstName`),
  `UnitPVPName` "First Last". Realm via `GetPlayerInfoByGUID` (7th return, "" = own realm).
- Player tooltip: level line ("Level %s …", `TOOLTIP_UNIT_LEVEL`) without line type `UnitLevel`, class and
  faction in their own lines afterwards (seen in the game).
- Aura filter: `NOT_CANCELABLE` no longer exists → `!CANCELABLE` (negation with `!`).
- Action bars like Mainline: 180 slots, pages 13–15 = bars 6–8.
- Addon icons only appear in the addon list (20×20), there is no addon compartment at the minimap.
- Bank: Camelot BankFrame with tabs from `CharacterBankTab_1` (6); keyring = -1.

## Sources and tools

- Blizzard source: `git clone --depth 1 --branch forever https://github.com/Gethe/wow-ui-source`
  (branch `classic_beta` is outdated). Static checks only give candidates: GlobalStrings,
  C functions and widget methods are not in the source tree.
- Test environment `tests`: fengari (Lua VM in Node, locally in `node_modules`, not in the repository; fetched by
  `Invoke-QnTests.ps1` via `npm install` when needed) with the WoW stub `stub.lua` and scenarios
  in one folder per tested addon, numbered there (`tests\qnBuffMod\test3.lua`);
  scenarios for the shared library (profiles, migration, Visible …) live under `qnCore`.
  Run all: `pwsh tests\Invoke-QnTests.ps1` (`-Filter qnBuffMod` or `-Filter qnCore/test3`,
  `-Locale enUS`, `-Detail`); single: `node tests\run.mjs qnBuffMod/test3.lua` (addons from `AddOns`
  next to `tests`, language via `$env:QN_LOCALE`). The stub loads the real Forever GlobalStrings of the
  language (not in the repository; `run.mjs`/`gs.mjs` fetch missing ones via `globalstrings.mjs`, update with
  `node tests\globalstrings.mjs --update`); therefore never name test variables like GlobalStrings
  (`COMBAT` was one → now `QN_COMBAT`).
  Run all scenarios after every change; new features get their own scenario
  (next free number in the addon's folder).
  XML is not loaded. Check test failures against Blizzard's source first – mostly they are gaps in the
  stub; close them in the stub, not in the addon.
- Multi-monitor scripts: `qnViewPort\scripts` (`Initialize-WowMonitors.ps1`, `Set-WowWindow.ps1`,
  shared `qnMonitors.ps1`) write `qnViewPort\Monitors.lua` (global `qnViewPortMonitors`;
  depends on the machine, optional, not in the repository; the stub never loads it, scenarios set the data themselves);
  the monitor selection is stored in `monitors.json` in the WoW root folder (shared by all clients,
  outside the repository). WoW only loads files listed in the TOC. The scripts find the WoW root folder via
  `Get-QnWowRoot` (`-WowRoot`, `$env:QN_WOW_ROOT`, five levels above the scripts – only when called through
  the junction –, otherwise via a running client).
- Tools in `tools`: `Get-WowWindow.ps1` (position/frame of the WoW window, read only),
  `Get-Screen.ps1` (screenshot of all monitors to `tools\screen.png`, not in the repository),
  `New-QnPatterns.ps1` (tile patterns of qnCore), `Convert-QnLoadout.ps1` (qnLoadout sets JSON → `Data.lua`, `-Import` exports from the SavedVariables).
- Shared icon: `qnCore\Media\qnIcon.tga` (64×64 TGA).

## Way of working

- Shell: PowerShell 7. **Never replace German quotation marks („ “ ‘ ’) inside double-quoted
  PowerShell strings**; PowerShell treats them as quote characters. Use the Edit tool for single
  changes (German translations in `Locale.lua` still contain such quotes).
- PowerShell: a list with only **one** pair (`@(@('old','new'))`) gets flattened – a
  replacement loop then replaces single characters (this destroyed `SettingsBuilder.lua`). Create pairs with
  `,@(...)` and check the pair length, or use the Edit tool.
- Keep the line endings of the existing file.
- Follow the surrounding style: tabs, English comments, `local ADDON, ns = ...`, section separators
  with `-----`.
- Commit messages in English.
- In reports clearly separate: verified in tests / confirmed in the game / not verifiable ("Ich weiß es nicht!").
