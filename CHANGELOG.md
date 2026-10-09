# Changelog

All notable changes to the qnMod addons are documented in this file: new features, changes and
bug fixes, per release. The addons are versioned individually; each entry names the addon and, where
it changed, its new version (`## Version` in the TOC). Releases are the `v*` tags of the repository
(ZIP with all addons).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Categories: **Added** (new features), **Changed** (changes to existing behavior), **Removed**,
**Fixed** (bug fixes).

## [Unreleased]

### Added

- **qnViewPort 0.1.6:** optional "Talent window on" (page "Placement"): the talent window keeps
  Blizzard's position, but relative to a chosen monitor instead of centered across all monitors.
- User documentation in English and German (`docs/user/en`, `docs/user/de`): overview and one page
  per addon.
- **qnUnitFrames 0.2.0:** optional range icon to the right of the target and the focus frame. It
  shows the icon of your farthest ranged action that can be used right now while the unit is in its
  range, and the auto attack icon in melee range. Size and position per frame, stored in the profile.
- **qnSkins 0.1.0:** new addon. Artwork around UI elements: a band across the monitor with a cord
  line, boxes around the action bars, threat meter and numpad, and a 3D figure (city guard of your
  faction). Optional "Position elements" gives these elements a predefined position and scale. Page
  "Figures" to tune the figures.
- **qnLoadout 0.1.0:** new addon. Sets of `qn` macros and numpad assignments per class (G502 sets for
  Priest, Druid, Hunter, Warrior and Mage). Loading only creates or edits macros with the prefix `qn`
  and never deletes anything; the current state can be exported.
- **qnNumKeyPad 0.2.0:** page "Mouse" (Logitech G502: which mouse button triggers which numpad
  key), page "Mouse Buttons" (spell or macro per mouse button), Ctrl set (while Ctrl is held, keys
  1–12 use action bar page 15).
- **qnViewPort 0.1.5:** minimap tooltips (tracking, zone text, mail, calendar, clock) and the tracking
  menu stay on the minimap's monitor; optional "Open below the clock" for the clock window.

### Changed

- **qnMeter is now qnThreatMeter (0.2.0)**, slash commands `/qnm` and `/qnthreatmeter`. Settings of
  qnMeter are not taken over automatically: copy `SavedVariables\qnMeter.lua` to
  `SavedVariables\qnThreatMeter.lua` and rename `qnMeterDB` to `qnThreatMeterDB` inside it.
- Slash commands accept English subcommands only (German aliases such as `/qncore profil`,
  `/qnvp monitore`, `/qnuf klicks` and `optionen` were removed).
- **qnCore 0.2.0:** every addon stores a settings version and repairs invalid saved values on load.

### Removed

- Conversions of saved settings from old pre-release formats (all addons).

### Fixed

- **qnViewPort 0.1.7:** with Titan Panel 9.3 the "Titan Panel" options page was missing and the bars
  spanned all monitors again, because Titan renamed the functions and values qnViewPort uses.
- **qnUnitFrames 0.2.1:** the range icon showed the auto attack icon for a friendly target within
  about 10 yards (e.g. as a druid in caster form); units you cannot attack now get no icon.

## [0.2.0] - 2026-09-28

### Added

- **qnInventory 0.2.0:** bags, bank and mailbox of every character as windows like Blizzard's, with
  character selection, anywhere (also `/qninv bags|bank|mail [name]`).
- **qnInventory 0.3.0:** Titan Panel plugins for bank/bag slots and gold, account bank (gold at any
  time, content at the banker), options page with faction options and deleting characters.
- **qnViewPort:** zone map size (50–200 %) on the "Placement" page.
- **qnTooltip 0.1.2:** line editor on the "Lines" pages (on/off, order, preview, edit dialog with
  color, filter and format).

### Changed

- All options pages share the look of Blizzard's pages (title, "Defaults", divider, scrolling
  content); lists scroll with the page.

### Fixed

- **qnViewPort:** bag slot tooltips (including comparison tooltips) no longer reach onto the
  neighboring monitor.
- **qnTooltip:** Cancel in the color picker restores the previous color.
- **qnCore:** errors in the objective tracker ("Auras cannot be accessed when secret while tainted")
  after changing the font size; qnCore no longer rebuilds the tracker itself.

## [0.1.0] - 2026-09-28

### Added

- First release: **qnCore** (profiles per Edit Mode layout, bag automation, minimap tracking,
  objective tracker font), **qnMeter** (threat meter), **qnNumKeyPad** (numpad action bar),
  **qnViewPort** (smaller 3D area, multi-monitor support, Titan Panel per monitor), **qnInventory**
  (items and gold per character), **qnBuffMod** (aura windows), **qnUnitFrames** (click casting on
  party and raid frames), **qnTooltip** (customizable tooltips).

[Unreleased]: https://github.com/kuhnma-prv/wow-qnMod/compare/v0.2.0...develop
[0.2.0]: https://github.com/kuhnma-prv/wow-qnMod/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/kuhnma-prv/wow-qnMod/releases/tag/v0.1.0
