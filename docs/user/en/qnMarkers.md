# qnMarkers – raid marker bar

qnMarkers adds a small, movable bar for marking: one button per raid marker places the world
marker on the ground (left-click) or sets the target marker on your current target (right-click).
Further buttons start a ready check or a pull timer, clear the markers or leave the group.

## Features

- Eight marker buttons (Skull, Moon, Circle, Star, Cross, Diamond, Triangle, Square).
  - **Left-click**: places the world marker of that symbol. Placed world markers glow on the bar,
    also those placed by other group members.
  - **Right-click**: sets the target marker on your current target.
  - Without world markers (the client reports them as not available) both clicks set the target marker.
- Utility buttons, each can be switched off: **Ready Check**, **pull timer 5 and 10 seconds**,
  **Clear world markers**, **Clear target marker**, **Leave Party** (asks first; off by default).
- The **grip** (first button, "-"/"+"): drag to move the bar, left-click to minimize/expand,
  right-click to clear all world markers and the marker of your target.
- Horizontal or vertical, floating (without background and border), scale, icon size, button
  spacing, border and background color.
- Visibility: always, in a group or in a raid – also switches in combat. Optionally only as group
  leader or raid assistant.
- Works with key bindings too: the buttons are named `qnMarkersBarMarker1` … `qnMarkersBarMarker8`
  (bar order), `qnMarkersBarClearWorld`, `qnMarkersBarClearTarget`, `qnMarkersBarGrip`, so a macro
  like `/click qnMarkersBarMarker1 RightButton` sets the skull on your target.

## Getting started

The bar appears after login in the upper half of the screen. Drag it by its grip to where you
want it. Open the options with `/qnmarkers` or *Options → AddOns → qnMarkers*.

Ready check, pull timer and markers in a group need group leader or assistant rights; the game
decides that, the bar only offers the buttons.

## Options

All settings are stored per profile (= per Edit Mode layout, see qnCore).

### qnMarkers

**Raid Marker Bar**

- **Show bar** – shows the bar. Default: on.
- **Visibility** – **Always**, **In a group** (party or raid) or **In a raid**. Also applies in
  combat. Default: Always.
- **Only as leader or assistant** – hides the bar unless you are the group leader or a raid
  assistant. Checked again after combat. Default: off.
- **Lock position** – prevents moving the bar by its grip. Default: off.
- **Show Tooltips** – tooltips on the buttons. Default: on.

**Buttons**

- **Ready Check**, **Pull timer: 5 seconds**, **Pull timer: 10 seconds**, **Clear world markers**,
  **Clear target marker** – default: on.
- **Leave Party** – asks for confirmation first. Default: off.

**Appearance**

- **Orientation** – **Horizontal** or **Vertical**. Default: Horizontal.
- **Floating** – without background and border: only the buttons are visible. Default: off.
- **Scale** – 50–200 %. Default: 100 %.
- **Icon Size** – size of the buttons, 20–42. Default: 28.
- **Button spacing** – 0–8. Default: 2 (the edge of the bar grows with it).
- **Border Color** – color of the border of the bar and the buttons. Not while floating.
- **Background Color** and **Background opacity** – background of the bar. Not while floating.

**Position**

- **Keep in visible area automatically** – moves the bar back onto a monitor after dragging, on
  login and when the monitor arrangement changes. With qnViewPort and monitor data, only areas
  actually visible on a monitor count. Default: off.
- **Find bar** – button **Move into visible area** moves the bar onto the nearest visible monitor
  now (same as `/qnmarkers visible`).
- **Reset position** – puts the bar back to its default position.

## Slash commands

| Command | Effect |
|---|---|
| `/qnmarkers` (or `/qnmk`, `/qnmarkers config`, `/qnmarkers options`) | Opens the options |
| `/qnmarkers show` / `hide` / `toggle` | Shows or hides the bar |
| `/qnmarkers lock` / `unlock` | Locks or unlocks the position |
| `/qnmarkers reset` | Resets the position |
| `/qnmarkers visible` | Moves the bar into the visible area |
| `/qnmarkers <anything else>` | Shows the command help in chat |

## Tips & notes

- Requires qnCore.
- In combat the game blocks changes to the bar: changed options, minimizing and the check
  "only as leader or assistant" are applied after combat. Visibility by group and raid also
  switches in combat.
- A world marker is placed only after you click on the ground; the glow follows shortly after.
- If the bar is gone, check **Visibility** and **Only as leader or assistant**, or type
  `/qnmarkers show`.

[← Overview](README.md)
