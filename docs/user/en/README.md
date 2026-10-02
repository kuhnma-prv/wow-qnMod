# qnMod – user guide

qnMod is a set of small, focused addons for **World of Warcraft Classic Forever**. All of them
build on **qnCore** and are configured in Blizzard's own settings window: *Options → AddOns →
<addon>*. Most settings belong to a **profile**, and the active profile is the active **Edit Mode
layout**: switch the layout and the settings of all qn addons switch with it (manage profiles on
qnCore's page **Profiles**).

German version: [Deutsch](../de/README.md) · Changes: [CHANGELOG](../../../CHANGELOG.md)

## Installation

1. Download `qnMod-<version>.zip` from the
   [latest release](https://github.com/kuhnma-prv/wow-qnMod/releases/latest).
2. Extract the `qn*` folders you want into `World of Warcraft\_classic_beta_\Interface\AddOns\`.
   **qnCore is always required**; qnLoadout also needs qnNumKeyPad.
3. Start the game or type `/reload`.

Language: German clients show German texts, all other clients English.

## Addons

| Addon | What it does | Slash commands |
|---|---|---|
| [qnCore](qnCore.md) | Core of all qn addons (required): one settings profile per Edit Mode layout (copy, delete, reset), opens and closes bags automatically at auction house, bank, merchant and similar places, remembers minimap tracking, objective tracker font below 12. | `/qncore`, `/qnc` |
| [qnThreatMeter](qnThreatMeter.md) | Threat meter for your group against the current target, styled like the built-in Damage Meter: value, TPS, percent, "Pull Aggro" bar, warning on high threat. | `/qnm`, `/qnthreatmeter` |
| [qnNumKeyPad](qnNumKeyPad.md) | Action bar shaped like a numpad (6 keyboard layouts) with automatic key bindings, Ctrl set, stance switching and Logitech G502 support (mouse button → numpad key, spells and macros on mouse buttons). | `/qnnkp`, `/qnnumkeypad`, `/numpad` |
| [qnLoadout](qnLoadout.md) | Loads ready-made sets per class: creates or updates `qn` macros and assigns the qnNumKeyPad keys (including the Ctrl set); exports the current state as a set. | `/qnloadout` |
| [qnViewPort](qnViewPort.md) | Smaller 3D area with border color and pattern; multi-monitor mode (3D world on the main monitor, bags, maps and clock on a chosen monitor, tooltips kept on their monitor); Titan Panel bars per monitor. | `/qnvp`, `/qnviewport`, `/viewport` |
| [qnInventory](qnInventory.md) | Remembers bags, bank, mail and gold of all characters (also the account bank), item counts per character in tooltips, bags/bank/mail views of any character anywhere, Titan Panel plugins for slots and gold. | `/qninv`, `/qninventory` |
| [qnBuffMod](qnBuffMod.md) | Up to 10 freely configurable buff and debuff windows for player, vehicle, pet, target or focus: icon with bar or icon only, grouping, sorting, visibility conditions, expiry warnings, "Recast Buffs" key. | `/qnbuff`, `/qnbuffmod`, `/qnaura` |
| [qnUnitFrames](qnUnitFrames.md) | Click casting on Blizzard's party, raid and pet frames (like HealBot), per class and profile; optional range icon next to the target and focus frame. | `/qnuf`, `/qnunitframes` |
| [qnTooltip](qnTooltip.md) | Customizable tooltips: background, border, fonts, scale, optional position, health bar, unit lines built from elements, target and "Targeted by", 3D model, item level, IDs. | `/qntt`, `/qntooltip` |
| [qnSkins](qnSkins.md) | Decorative artwork (band with cord, boxes, 3D figure) around action bars, status bars and micro menu; optionally gives these elements a predefined position and scale on a chosen monitor. | `/qnskins` |

## Optional addons

- [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0): more fonts,
  textures and borders for qnThreatMeter and qnTooltip.
- [Titan Panel](https://www.curseforge.com/wow/addons/titan-panel): bars per monitor (qnViewPort),
  bank and gold plugins (qnInventory).

## General notes

- Blizzard blocks some changes in combat (key bindings, click casting, moving secure frames). The qn
  addons apply such changes automatically after combat.
- Combat information that the game hides from addons (secret values) is shown as far as the game
  allows; some displays work in a restricted mode then.
