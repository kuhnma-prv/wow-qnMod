# qn-Addons für WoW Classic Forever

Dieser Ordner ist `_classic_beta_\Interface\AddOns` = **WoW Classic Forever** (Flavor wow_classic_beta,
Build 1.60.1, `## Interface: 16001`, Spieltyp **camelot**, Midnight-Engine).
Gilt für die qn*-Addons. **Auctionator ist ein Fremd-Addon: nicht anfassen, nicht einbeziehen.**

Addons in `_retail_`, `_classic_`, `_anniversary_`, `_classic_era_` gehören nicht zu diesem Projekt:
nicht anfassen, nicht als Vorlage oder Quelle verwenden, im Code nicht erwähnen.

## Addons

| Addon | Zweck | SavedVariables |
|---|---|---|
| qnCore | Haupt-Addon + Bibliothek (global `qnCore`): Profile, Settings-Builder, Widgets, Taschen-Automatik, Minikarten-Verfolgung merken, Schrift der Questzielverfolgung unter 12 (je Profil, `QuestTracker.lua`), Seite „Profile“ | qnCoreDB (samt eigener `profiles`), qnCoreCharDB |
| qnMeter | Bedrohungsanzeige | qnMeterDB |
| qnNumKeyPad | Ziffernblock-Aktionsleiste | qnNumKeyPadProfiles (alt: qnNumKeyPadDB) |
| qnViewPort | verkleinerter 3D-Bereich, Randfarbe/-muster, Zwei-Monitor-Betrieb; mit Titan (OptionalDeps) Titan-Leisten je Monitor und Tooltips am Monitorrand (`Titan.lua`) | qnViewPortDB |
| qnInventory | Bestand/Gold je Charakter, Tooltip-Zeilen | qnInventoryDB |
| qnBuffMod | frei gestaltbare Aurenfenster | qnBuffModDB |
| qnUnitFrames | Klickzauber (wie HealBot) auf Blizzards Gruppen-/Schlachtzugsrahmen über sichere Attribute; Belegung je Profil und Klasse | qnUnitFramesDB |
| qnTooltip | Tooltips: Aussehen (eigener Backdrop statt NineSlice), Position nur auf Wunsch, Einheiten-Kopfzeilen aus Bausteinen (Seiten „Zeilen“), Lebensbalken, Ziel, Gegenstandsstufe, IDs | qnTooltipDB |

Alle außer qnCore: `## Dependencies: qnCore`, `## IconTexture: Interface\AddOns\qnCore\Media\qnIcon`,
`## Category-<Sprache>:` wie Titan (Benutzerinterface/User Interface), `## Title: qnMod [|cffeda55f<Kurzname>|r] |cff00aa00<Version>|r` (wie Titan; Version bei jeder Änderung von
`## Version` im Titel mitziehen). Beim Laden `qnCore.NewAddon(ns, ADDON)` (setzt version, Print, IsSecret, Plain, AnySecret,
`ns.events` = Ereignisverteiler, `ns.OnLoad(fn)` für das eigene ADDON_LOADED).

**Gemeinsamer Code gehört nach qnCore**, sobald er in mindestens 3 Addons vorkommt; die Addons nutzen dann die
Bibliothek statt eigener Kopien. Vorhanden u. a.: `qnCore.RegisterSlash`, `qnCore.Settings.NewCategory`/`SetIn`,
`store:Set`/`SetValues`, `qnCore.DeferInCombat`, `qnCore.Debounce`, `qnCore.ClassColor(classFile)`,
`qnCore.Popup.Confirm`/`EditText`, `qnCore.AnchorFactors`/`PointOffset`/`NearestCorner`, `qnCore.Visible`
(Rahmen in den sichtbaren Bereich holen; qnViewPort liefert die Monitore), `qnCore.UI.*` (Canvas-Bausteine),
`qnCore.Patterns` (eigene Kachelmuster `{ Schlüssel, Name, Datei, LSM-Name }` in `qnCore\Media\Patterns`,
erzeugt mit `qn_DevEnv\New-QnPatterns.ps1`, zusätzlich bei LibSharedMedia als „qn …“ angemeldet).

## Vorgaben des Nutzers

- **Keine Kompatibilitätsschichten** für andere WoW-Versionen. Nur Forever-APIs direkt nutzen, vorher im
  Forever-Quelltext prüfen. Guards nur für unprüfbare C-/Widget-Funktionen.
- **Auswahl aus mehreren Möglichkeiten immer als Dropdown-Knopf**, der die aktive Auswahl anzeigt
  (`qnCore.UI.Dropdown` auf Canvas-Seiten, `Settings.CreateDropdown` auf Proxy-Seiten). Keine Cycle-Knöpfe.
- **Optionen im Blizzard-Einstellungsfenster** (Settings-API), nicht als eigene Optionsfenster.
- **Profile:** aktives Profil = aktives Edit-Mode-Layout (`preset:<n>`, `account:<Name>`,
  `char:<Name-Realm>:<Name>`), charakterspezifische Layouts berücksichtigen. Neues Layout = Kopie des
  bisher aktiven Profils. Registrierung über `qnCore.Profiles.Register{ ns, sv, defaults, upgrade, obsolete,
  legacy, onSwitch }` (name kommt aus NewAddon, `obsolete` = veraltete Schlüssel); `ns.db` ist immer das aktive Profil.
- **Taschen- und Verfolgungs-Optionen von qnCore immer kontoweit** (`qnCoreDB.global`), nie je Profil/Charakter (die gemerkte Verfolgungsauswahl selbst liegt je Charakter).
- **Blizzard-Rahmen nie automatisch verschieben** (nicht an Ereignisse/Hooks hängen), nur über eine
  ausdrückliche Aktion im Optionsmenü. Ausnahmen nur als Opt-in (Taschen, Zonenkarte in qnViewPort).
- Beim Umbau von Einstellungen: bisherige Werte migrieren (Upgrade-Funktion bzw. `legacy`).
- Kommentare auf Deutsch. Anzeigetexte werden auf Deutsch geschrieben und **immer lokalisiert**
  (Deutsch + Englisch, siehe „Lokalisierung“).

## Lokalisierung

- **Deutsch ist die Quellsprache, Englisch gilt für alle anderen Clients.** Mechanismus in qnCore
  (`Library.lua`): Schlüssel = deutscher Text; `ns.L["Deutscher Text"]` liefert auf deDE den Schlüssel
  selbst, sonst die englische Übersetzung. Fehlt sie, erscheint Deutsch und `/qncore locale` listet sie.
- Jedes Addon hat eine `Locale.lua` (in der TOC vor allen Dateien mit Texten; bei qnCore direkt nach
  `Library.lua`):
  `local ADDON, ns = ...` / `local L = qnCore.NewLocale(ns, ADDON)` / `if qnCore.GERMAN then return end` /
  `L["Deutscher Text"] = "English text"`. In den übrigen Dateien `local L = ns.L`.
- **Reihenfolge bei der Wahl des englischen Textes:**
  1. **Blizzard-GlobalString**, wenn es einen gibt, dessen **deutscher Text genau dem bisherigen deutschen
     Text entspricht** und dessen Bedeutung passt: dann direkt die Blizzard-Variable im Code
     (`BANK`, `DELETE`, `CANCEL`, `DEFAULT`, `GENERAL` …), kein eigener Schlüssel. Nachschlagen:
     `node qn_DevEnv\test\gs.mjs "Text"` (Forever-GlobalStrings deDE/enUS in
     `qn_DevEnv\test\GlobalStrings`).
  2. Sonst eigene englische Übersetzung (Blizzard-Begriffe verwenden: Edit Mode, Action Bar, Bags …).
- Keine Texte zusammenstückeln: ganze Sätze als ein Schlüssel, Werte über `%s`/`%d`
  (`L["%s: beim Öffnen"]:format(name)`). Mehrzeilige Hilfetexte als ein Schlüssel.
- Nicht übersetzt werden: Slash-Befehle, Addon-Namen, Einstellungs-Schlüssel, Ereignisnamen, reine
  Entwicklerhinweise (mit `-- nicht übersetzen` am Zeilenende kennzeichnen).
- TOC: `## Notes:` Englisch, `## Notes-deDE:` Deutsch.
- Prüfen: `node qn_DevEnv\test\check-locale.mjs [Addon]` (fehlende/unbenutzte Übersetzungen, vergessene
  deutsche Texte, TOC) und `Invoke-QnTests.ps1` (läuft auf deDE **und** enUS; auf enUS scheitert ein
  Szenario, wenn ein Text ohne Übersetzung angezeigt wurde). Tests nie auf deutsche Anzeigetexte
  festlegen, sondern `ns.L[...]`/`qnCore.GERMAN` verwenden.

## Forever-Besonderheiten (im Quelltext geprüft)

- **Secret-Values:** API-Rückgaben können secret sein (`issecretvalue`). Damit nicht rechnen, vergleichen
  oder auf Wahrheit prüfen; nur an SetText/SetFormattedText/StatusBar:SetValue/AbbreviateLargeNumbers
  geben. Hilfen: `qnCore.IsSecret`, `qnCore.Plain(v, fallback)`. Aura-Daten
  (`SecretWhenUnitAuraRestricted`), Bedrohung und Damage-Meter-Werte im Kampf können secret sein.
- Combat Log für Addons gesperrt. Eingebauter Damage Meter (`C_DamageMeter`) vorhanden.
- **Ladebedingungen beachten:** Forever lädt Blizzard-Dateien nur gemäß `[AllowLoadGameType …]` in den
  Blizzard-TOCs. Beispiel: `SecureAuraHeaderTemplate` gibt es nicht (nur Spieltyp classic) → qnBuffMod
  nutzt nur unsichere Fenster. Bei Vorlagen/Dateien immer die TOC-Bedingung prüfen, nicht nur ob die
  Datei existiert.
- **Nachnamen:** `UnitName` liefert Vor- und **Nachname** (nicht den Realm; `NameUtil.GetUnitFirstName`),
  `UnitPVPName` „Vorname Nachname“. Realm über `GetPlayerInfoByGUID` (7. Rückgabe, "" = eigener).
- Spieler-Tooltip: Stufenzeile („Stufe %s …“, `TOOLTIP_UNIT_LEVEL`) ohne Zeilentyp `UnitLevel`, Klasse und
  Fraktion in eigenen Zeilen danach (im Spiel gesehen).
- Aura-Filter: `NOT_CANCELABLE` gibt es nicht mehr → `!CANCELABLE` (Negation mit `!`).
- Aktionsleisten wie Mainline: 180 Plätze, Seiten 13–15 = Leisten 6–8.
- Addon-Icons erscheinen nur in der Addon-Liste (20×20), kein Addon-Fach an der Minikarte.
- Bank: Camelot-BankFrame mit Fächern ab `CharacterBankTab_1` (6); Schlüsselbund = -1.

## Quellen und Werkzeuge

- Blizzard-Quelltext: `git clone --depth 1 --branch forever https://github.com/Gethe/wow-ui-source`
  (Zweig `classic_beta` ist veraltet). Statische Prüfung liefert nur Kandidaten: GlobalStrings,
  C-Funktionen und Widget-Methoden stehen nicht im Quellbaum.
- Entwicklungsumgebung: `qn_DevEnv` (im AddOns-Ordner, im Repo; ohne TOC, WoW lädt ihn nicht).
  `qn_DevEnv\test` – fengari (Lua-VM in Node, lokal in `node_modules`, nicht im Repo; wird von
  `Invoke-QnTests.ps1` bei Bedarf per `npm install` geholt) mit WoW-Attrappe `stub.lua` und Szenarien
  je getestetem Addon in einem Ordner, dort durchnummeriert (`qn_DevEnv\test\qnBuffMod\test3.lua`);
  Szenarien für die gemeinsame Bibliothek (Profile, Migration, Visible …) liegen unter `qnCore`.
  Alle ausführen: `pwsh qn_DevEnv\test\Invoke-QnTests.ps1` (`-Filter qnBuffMod` oder `-Filter qnCore/test3`,
  `-Locale enUS`, `-Detail`); einzeln: `node run.mjs qnBuffMod/test3.lua` (AddOns-Ordner = Elternordner
  von `qn_DevEnv`, Sprache über
  `$env:QN_LOCALE`). Die Attrappe lädt die echten Forever-GlobalStrings der Sprache (nicht im Repo;
  `run.mjs`/`gs.mjs` laden fehlende über `globalstrings.mjs`, aktualisieren mit
  `node qn_DevEnv\test\globalstrings.mjs --update`); Testvariablen
  deshalb nie wie GlobalStrings benennen (`COMBAT` war einer → heißt jetzt `QN_COMBAT`).
  Nach jeder Änderung alle Szenarien laufen lassen; neue Funktionen bekommen ein eigenes Szenario
  (nächste freie Nummer im Ordner des Addons).
  XML wird nicht geladen. Testfehler zuerst gegen Blizzards Quelltext prüfen – meist sind es Lücken der
  Attrappe; die dann in der Attrappe schließen, nicht im Addon.
- Mehrmonitor-Skripte: `qnViewPort\scripts` (`Initialize-WowMonitors.ps1`, `Set-WowWindow.ps1`,
  gemeinsam `qnMonitors.ps1`) schreiben `qnViewPort\Monitors.lua` (global `qnViewPortMonitors`);
  die Monitorauswahl liegt in `monitors.json` im WoW-Hauptordner (für alle Clients gemeinsam,
  außerhalb des Repos). WoW lädt nur Dateien aus der TOC.
- Hilfen in `qn_DevEnv`: `Get-WowWindow.ps1` (Lage/Rahmen des WoW-Fensters, nur lesen),
  `Get-Screen.ps1` (Bildschirmfoto aller Monitore nach `screen.png`, nicht im Repo).
- Gemeinsames Icon: `qnCore\Media\qnIcon.tga` (64×64 TGA).

## Arbeitsweise

- Shell: PowerShell 7. **Deutsche Anführungszeichen („ “ ‘ ’) nie in doppelt quotierten
  PowerShell-Strings ersetzen**; PowerShell hält sie für Anführungszeichen. Für Einzelstellen das
  Edit-Werkzeug nutzen.
- PowerShell: eine Liste mit nur **einem** Paar (`@(@('alt','neu'))`) wird flachgeklopft – eine
  Ersetzungsschleife ersetzt dann einzelne Zeichen (hat `SettingsBuilder.lua` zerstört). Paare mit
  `,@(...)` anlegen und die Paarlänge prüfen, oder das Edit-Werkzeug nutzen.
- Zeilenenden der vorhandenen Datei beibehalten.
- Stil der Umgebung übernehmen: Tabs, deutsche Kommentare, `local ADDON, ns = ...`, Abschnitts-Trenner
  mit `-----`.
- Im Bericht klar trennen: im Test geprüft / im Spiel bestätigt / nicht prüfbar („Ich weiß es nicht!“).
