# qnViewPort – a smaller 3D world and multi-monitor support

qnViewPort shrinks the area in which the 3D world is rendered, so action bars, chat and other
windows can sit next to the game world instead of on top of it. The area outside the world gets a
color and an optional tiled pattern. If you stretch the game window across several monitors,
qnViewPort keeps the 3D world on the main monitor, can place bags, Zone Map, World Map, the clock
window and the talent window on a monitor of your choice, keeps tooltips on the monitor they belong to and, with
Titan Panel, puts the Titan bars on individual monitors.

## Features

- Free viewport: offsets for left, right, top and bottom in pixels, set in a preview with draggable
  edges or with number fields; new values must be confirmed within 20 seconds, otherwise they revert.
- Color (with opacity) and tiled background pattern for the area outside the world, including
  patterns from qnCore and – if installed – LibSharedMedia backgrounds.
- Dual/multi-monitor mode: 3D world only on the main monitor, using measured monitor data
  (PowerShell scripts) or manually entered values.
- Optional placement (opt-in) of bags, Zone Map (with size), maximized World Map, "Map & Quest Log"
  the clock window and the talent window on a chosen monitor.
- World Map extras: follow the current zone, open on login, do not fade while moving.
- Visibility check: lists interface elements that are fully or partly outside every monitor and
  moves them one at a time on request.
- Tooltips of bag slots, the minimap (tracking, zone text, mail, calendar, clock) and the tracking
  menu stay completely on their monitor.
- With Titan Panel: each full-width Titan bar on a chosen monitor, plugin tooltips on the plugin's
  monitor, scale factor per monitor.

## Getting started

Open *Options → AddOns → qnViewPort* or type `/qnvp`. The main page sets the viewport. Subpages:
**Monitors**, **Second Monitor**, **Placement** and – only if Titan Panel is loaded – **Titan Panel**.

All settings belong to the active profile, i.e. the active Edit Mode layout (see [qnCore](qnCore.md)).
Switching the layout switches the profile and applies its settings.

## Options

### qnViewPort (main page)

- **Preview**: the red frame is the game window, the yellow area labeled **Game world** is the 3D
  world. Drag its edges or corners to change the offsets.
- **Top**, **Bottom**, **Left**, **Right**: offsets in pixels; confirm with Enter (Tab moves to
  the next field). Default: 0 each. Opposite sides together may take at most half of the window
  (7/8 when the window spans several monitors).
- **Apply**: applies the values. A button **Keep Settings?** with a countdown appears; if you do
  not click it within 20 seconds, the previous viewport is restored.
- **Reset**: whole window for the game world again (same as `/qnvp 0 0 0 0`).
- Below the buttons: screen resolution and size of the custom viewport, each with aspect ratio.
- **Suppress the on-load message**: no chat hint after login that a custom viewport is active.
  Default: off.
- **Color of the area outside the world**: click the color swatch to open the color picker (with
  opacity). Default: black.
- **Background pattern**: tiled pattern over the color – Rock, Marble, Wood, Dialog, Dialog (dark),
  Tooltip, Parchment, Achievements, the qnCore patterns and LibSharedMedia backgrounds (marked
  "(LSM)"). Default: **No pattern (color only)**.
- **Pattern opacity**: 0–100 %, default 50 %. Only available while a pattern is selected.

In combat the game world cannot be resized; a change is then applied right after combat.

### Monitors

Shows the monitor data written by the scripts (see [Multi-monitor setup](#multi-monitor-setup)):
number, name, position and size of every monitor in the game window, the main monitor, and whether
the Blizzard interface currently covers the whole window or only the main monitor.

- **Use monitor data**: use `Monitors.lua`. Off: position and size of the second monitor come from
  the **Second Monitor** page. Default: on.
- **Apply**: applies the monitor layout again (with dual monitor mode on: also puts the 3D world on
  the main monitor).
- **Check visibility**: finds all shown interface elements that are fully or partly outside every
  monitor and lists them below the monitor list (name, how much is visible, origin, Edit Mode,
  protected). Nothing is moved by the check itself.
- **Move into visible area** (one button per listed element): moves only this element onto a
  monitor by the shortest path. Hovering the button marks the element's current area in red.
  Edit Mode elements moved this way only stay there until `/reload` or until the layout is
  reloaded – to keep the position, move them in Edit Mode. Protected elements cannot be moved in combat.
- **Interface to main monitor**: places the whole Blizzard interface (everything attached to
  UIParent: action bars, minimap, objective tracker, chat …) over the main monitor. Only in dual
  monitor mode with a window spanning several monitors, not in combat. Lasts until **Reset**,
  `/reload`, turning dual monitor mode off or switching to a profile without it.
- **Reset**: Blizzard interface across the whole game window again.

### Second Monitor

The game window must be stretched across several monitors (windowed mode, e.g. 5760 × 2160).

- **Dual monitor mode enabled (3D world on the main monitor only)**: turning it on puts the 3D
  world on the main monitor right away (no 20-second confirmation); turning it off resets the
  viewport to the whole window and releases **Interface to main monitor**. Default: off.
- **Position of the second monitor**: **Right of the main monitor** (default) or **Left of the main
  monitor**.
- **Width**, **Height**, **Distance from top**: size of the second monitor in pixels and the
  distance of its top edge from the top of the window. Defaults: 1920, 1200, 0.
- **Apply**: applies these values (and, with the mode on, the viewport).
- Info line: game window size, second monitor in the window, size of the world, and a warning if
  the window is too small for both monitors.

With active monitor data, position, size and distance are measured and cannot be changed here.

### Placement

Unless a box is checked, qnViewPort does not touch the respective window. Monitors are chosen in a
dropdown: **Main monitor** or one of the numbered monitors (numbers as on the **Monitors** page).
Offsets are counted in pixels inward from the edges of the chosen corner.

**Bags**

- **Place bags when opened**: each time bags open, they move to the chosen corner, stacked
  vertically, further columns towards the center of the monitor. Default: off.
- **Monitor** (default: main monitor), **Corner** (default: **Bottom right**),
  **Horizontal offset** / **vertical** (defaults: 130 / 330).

**Zone Map (Shift+M)**

- **Show Zone Map**: shows or hides Blizzard's Zone Map (Blizzard remembers the state itself).
- **Place Zone Map when shown**: moves the Zone Map and its tab to the chosen corner each time it
  is shown; dragging the tab then only lasts until it is shown again. Default: off.
- **Monitor** (default: main monitor), **Corner** (default: **Top right**),
  **Horizontal offset** / **vertical** (defaults: 20 / 300).
- **Size**: size of the Zone Map including its tab, 50–200 % in 5 % steps, default 100 %. Also
  works without placement.

**World Map**

- **Maximized World Map on** + monitor: the maximized map and its black background only on the
  chosen monitor instead of across the whole window. Default: off.
- **"Map & Quest Log" on** + monitor: the minimized map with the quest log at the left edge of the
  chosen monitor instead of the left edge of the window. Default: off.
- **Map follows the current zone**: while the map is open, it switches to the new zone when you
  enter it. Default: on.
- **Open the map on login**: only on login and after `/reload`, not after loading screens.
  Default: off.
- **Do not fade the map while moving**: sets Blizzard's option `mapFade` to 0; turning it off
  restores the previous value. Default: off.

**Clock**

- **Open below the clock**: the clock window (click on the clock at the minimap) opens below the
  clock on its monitor instead of at the top right edge of the game window. Default: off.

**Talents**

- **Talent window on** + monitor: Blizzard places the talent window relative to the whole game
  window, i.e. centered across all monitors. On: the same position relative to the chosen monitor;
  the size stays unchanged. Turning it off restores Blizzard's position. Default: off, main monitor.

**Buttons and display**

- **Show areas**: outlines the areas of the active placements – blue bags, yellow Zone Map, green
  World Map, purple "Map & Quest Log", red talent window. Default: off.
- **Apply**: places everything again.
- **Open map**: opens the World Map (not in combat).

### Titan Panel

Only present if Titan Panel is loaded. Settings are per profile.

- One dropdown per full-width Titan bar (two at the top, two at the bottom; names as in Titan):
  **As Titan (entire UI)** (default) or a monitor (numbers as on the **Monitors** page). The bar
  then lies on the top or bottom edge of that monitor. The bars are still turned on and off in Titan.
- **Apply**: places the bars on their monitors again, e.g. after the monitor arrangement changed.
- **Scale per monitor**: one slider per monitor, 50–200 % in 5 % steps, default 100 %. Size of
  Titan's bars, plugins and tooltips on this monitor in addition to Titan's own scale – useful for
  monitors with different pixel density (e.g. about 65 % for a monitor at 100 % Windows scaling next
  to a main monitor at 150 %).

Tooltips and control frames of Titan plugins are kept on the plugin's monitor automatically.

## Slash commands

| Command | Effect |
|---|---|
| `/qnvp`, `/qnviewport`, `/viewport` | Open the options |
| `/qnvp L R T B` | Set the offsets in pixels (left, right, top, bottom); with 20-second confirmation |
| `/qnvp 0 0 0 0` | Reset the viewport (whole window) |
| `/qnvp monitors` | Show the monitor data in chat |
| `/qnvp check` | List interface elements outside the monitors (moves nothing) |
| `/qnvp dual` | Open the **Second Monitor** page |
| `/qnvp dual on` / `off` | Turn dual monitor mode on/off |
| `/qnvp dual left` / `right` | Position of the second monitor |
| `/qnvp dual W H [Y]` | Size of the second monitor in pixels, Y = distance from the top (only used without monitor data) |
| `/qnvp dual guides` | Toggle the outlines of the placement areas |
| `/qnvp dual map` | Open the World Map |
| `/qnvp dual zonemap` | Show/hide the Zone Map |
| `/qnvp help`, `/qnvp dual help` | Show the command list |

## Multi-monitor setup

The monitor layout cannot be read from inside the game. Two PowerShell 7 scripts in
`qnViewPort\scripts` write it to `qnViewPort\Monitors.lua`; the game reads it after `/reload`.
Without this file qnViewPort works with the values from the **Second Monitor** page.

1. **Once:** `pwsh Initialize-WowMonitors.ps1`
   Lists all monitors (numbered left to right, with position, resolution and Windows scaling) and
   asks which monitors the WoW window should span and which one is the main monitor for the 3D
   world. Saves the selection to `monitors.json` in the WoW root folder (shared by all installed
   clients) and writes `Monitors.lua` for every installed client.
   - `-List` – only show the monitors, change nothing
   - `-Select 1,2 -Main 1` – choose without questions
   - `-WowRoot <path>`, `-ConfigPath <file>` – WoW folder / location of `monitors.json`
2. **After starting WoW:** `pwsh Set-WowWindow.ps1`
   Waits for the WoW window (up to 180 s), removes the window border, stretches the window over the
   selected monitors and updates `Monitors.lua` of the running client with the exact client area.
   Then `/reload` in the game.
   - `-ProcessName <name>` – process of the client (default `WowB`)
   - `-KeepBorder` – keep title bar and frame
   - `-Select 1,2 -Main 1` – a different selection for this run only
   - `-X -Y -Width -Height` – fixed window rectangle, no monitor logic (does not update `Monitors.lua`)
   - `-TimeoutSec <s>`, `-WowRoot <path>`, `-ConfigPath <file>`

The scripts find the WoW folder through the `QN_WOW_ROOT` environment variable, through their own
location inside the game's AddOns folder, or through a running WoW client. If a monitor changed
since the setup, `Set-WowWindow.ps1` warns and uses the current values – run
`Initialize-WowMonitors.ps1` again to confirm.

When qnViewPort sees a new monitor layout for the first time, it puts the 3D world on the main
monitor once and reports it in chat; your later viewport changes stay until the layout changes.
If the game window size does not match the data (different aspect ratio), the **Monitors** page
and `/qnvp monitors` say so – run `Set-WowWindow.ps1` again.

## Tips & notes

- qnViewPort only moves Blizzard windows when you ask for it: placement options are opt-in,
  **Interface to main monitor** and **Move into visible area** are buttons.
- Move interface elements with Blizzard's Edit Mode; use the **Monitors** page to find elements
  that ended up outside every monitor.
- In combat: the viewport and the World Map placement are applied after combat; protected
  elements and the Blizzard interface cannot be moved; the Zone Map cannot be loaded.
- The Zone Map is not available everywhere (e.g. not in every instance).
- Other qn addons use qnViewPort's monitor areas: qnSkins places its artwork on a monitor, and
  qnInventory's bag views keep their tooltips on the bag's monitor. qnThreatMeter, qnNumKeyPad and
  qnBuffMod use the monitor areas (through qnCore) to bring their windows into the visible area.
- Optional dependency: [Titan Panel](https://www.curseforge.com/wow/addons/titan-panel); background
  patterns from LibSharedMedia appear if another addon provides it.

[← Overview](README.md)
