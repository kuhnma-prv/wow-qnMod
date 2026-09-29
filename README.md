# qnMod – addons for WoW Classic Forever

[![Tests](https://github.com/kuhnma-prv/wow-qnMod/actions/workflows/test.yml/badge.svg)](https://github.com/kuhnma-prv/wow-qnMod/actions/workflows/test.yml)
[![Release](https://img.shields.io/github/v/release/kuhnma-prv/wow-qnMod)](https://github.com/kuhnma-prv/wow-qnMod/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A set of small, focused addons for **World of Warcraft Classic Forever**
(client flavor `wow_classic_beta`, build 1.60.1, `## Interface: 16001`).
All of them share one core library, **qnCore**, and are configured in Blizzard's own
settings window (*Options → AddOns*). Settings follow the active **Edit Mode layout**, so each
layout (including character-specific ones) has its own profile.

> These addons are written for Classic Forever only. They use its APIs directly and are
> not tested on Retail, Classic Era, Cataclysm/MoP Classic or other clients.

## Addons

| Addon | What it does | Slash commands |
|---|---|---|
| **qnCore** | Core and library (required by all others): profiles per Edit Mode layout, settings builder, widgets, bag automation, remembers minimap tracking, quest tracker font size, "Profiles" page | `/qncore`, `/qnc` |
| **qnMeter** | Threat meter for your group against the current target (works with secret values) | `/qnmeter`, `/qnm` |
| **qnNumKeyPad** | Action bar in the shape of a numpad | `/qnnumkeypad`, `/qnnkp`, `/numpad` |
| **qnViewPort** | Shrinks the area in which the 3D world is rendered, border color/pattern, multi-monitor support; with Titan Panel: bars and tooltips per monitor | `/qnviewport`, `/qnvp`, `/viewport` |
| **qnInventory** | Remembers bags, bank, mail and gold of all characters, shows item counts in the tooltip and shows bags, bank and mailbox of any character anywhere (windows like Blizzard's, with character selection) | `/qninventory`, `/qninv` |
| **qnBuffMod** | Freely customizable buff and debuff windows | `/qnbuffmod`, `/qnbuff`, `/qnaura` |
| **qnUnitFrames** | Click casting on Blizzard's party and raid frames (like HealBot), per profile and class | `/qnunitframes`, `/qnuf` |
| **qnTooltip** | Customizable tooltips: look, optional position, unit lines built from elements, health bar, target, item level, IDs | `/qntooltip`, `/qntt` |

Optional dependencies: [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0)
(qnMeter, qnTooltip; qnCore registers its background patterns there as "qn …") and
[Titan Panel](https://www.curseforge.com/wow/addons/titan-panel) (qnViewPort).

## Installation

1. Download `qnMod-<version>.zip` from the
   [latest release](https://github.com/kuhnma-prv/wow-qnMod/releases/latest).
2. Extract the `qn*` addon folders you want into
   `World of Warcraft\_classic_beta_\Interface\AddOns\`. **qnCore is always required.**

3. Start the game or `/reload`, then open *Options → AddOns*.

When working from a clone of the repository instead, the addons are in the `AddOns` folder of the
repository. Link the game's `AddOns` folder to it (move other addons you use into the repository's
`AddOns` folder first; everything except `qn*` there is ignored by git):

```powershell
New-Item -ItemType Junction -Path '<WoW>\_classic_beta_\Interface\AddOns' -Target '<repo>\AddOns'
```

Language: German and English. German clients get German texts, all other clients get English.

## Multi-monitor setup (qnViewPort, optional)

qnViewPort can spread the WoW window over several monitors and keep the 3D world and the UI on
the main monitor. The monitor layout cannot be read from inside the game, so it is written by
PowerShell 7 scripts into `qnViewPort\Monitors.lua`. This file depends on your machine and is
**not part of the repository**. Without it qnViewPort works with manually entered values.

```powershell
# once: select the monitors and the main monitor
pwsh qnViewPort\scripts\Initialize-WowMonitors.ps1
# put the (running) WoW window over the selected monitors and update Monitors.lua
pwsh qnViewPort\scripts\Set-WowWindow.ps1
```

The selection is stored in `monitors.json` in the WoW root folder. `/reload` after a change.
The scripts find the WoW root folder from their own location inside the game folder. When you run
them from a repository clone, pass `-WowRoot <WoW>`, set `QN_WOW_ROOT` or start WoW first.

## Development

The tests run the addons in [fengari](https://github.com/fengari-lua/fengari) (a Lua VM for
Node.js) against a stub of the WoW API (`tests\stub.lua`). Requirements: PowerShell 7
and Node.js. `node_modules` and Blizzard's GlobalStrings are downloaded on first run.

```powershell
pwsh tests\Invoke-QnTests.ps1                     # all scenarios, deDE and enUS
pwsh tests\Invoke-QnTests.ps1 -Filter qnBuffMod   # one addon
node tests\check-locale.mjs                       # missing/unused translations
```

Repository layout: `AddOns` (the addons), `tests` (test environment), `tools` (developer scripts),
`docs\plans` (local notes, not in the repository).

The same checks run on GitHub Actions for every push and pull request. Pushing a tag `v*`
builds the release ZIP (all addon folders, each with the license).

Scenarios live in `tests\<Addon>\testN.lua`. Blizzard's UI source for Classic Forever:
branch `forever` of [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source).

Conventions: code and comments are English; every displayed text is localized (English is the
source language, `Locale.lua` in each addon holds the German translations). Code shared by three or
more addons belongs in qnCore. `CLAUDE.md` contains the detailed project rules.

## License

[MIT](LICENSE)

World of Warcraft is a trademark of Blizzard Entertainment, Inc. This project is not affiliated
with or endorsed by Blizzard Entertainment.
