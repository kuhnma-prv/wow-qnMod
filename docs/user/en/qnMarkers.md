# qnMarkers – raid marker bar and nameplate markers

qnMarkers adds a small, movable bar for marking: one button per raid marker places the world
marker on the ground (left-click) or sets the target marker on your current target (right-click).
Further buttons start a ready check or a pull timer, clear the markers or leave the group.
Optionally it shows an icon above nameplates – class, role, friend or guild member at a glance.

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
- Optionally hides Blizzard's raid manager at the left edge of the screen (the raid frames stay).
- **Markers above nameplates** (off by default): an icon above the nameplates of friendly players,
  group members, enemy players, PvP-flagged players, NPCs or pets – you choose which.
  - Icon per unit: **class** icon, **role** icon (group members) or a **texture** (arrow, heart,
    shield, dot, skull, star or your own), with a second icon type as fallback.
  - Hearts for friends (friend list and Battle.net), shields for guild members, portraits for pets.
  - Size, offset, square or round, background, border in class color – separately for friendly and
    enemy units. Optionally glow around the marker of your target, fading with the nameplate, only
    in arenas.

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

**Blizzard's raid manager**

- **Hide raid manager** – makes Blizzard's raid manager at the left edge of the screen (panel and its
  tab) transparent and click-through. The raid frames themselves stay. Applied out of combat;
  switching it off restores the manager. Default: off.

### Nameplate Markers

- **Show markers above nameplates** – an icon above the nameplate of the units chosen below.
  Nameplates must be switched on in the game. Default: off. All other options of this page and of
  the pages **Friendly Markers** and **Enemy Markers** are only usable while this is on.

**Filters** – which units get a marker:

- **Friendly Players** – default: on.
- **Group members** – default: on.
- **Enemy Players** – values of enemies can be hidden by the game in combat; then they get no
  marker. Default: off.
- **Players flagged for PvP** – default: off.
- **NPCs** – default: off.
- **Pets** – pets of other players, smaller, with their portrait. Default: off.
- **Your pet** – also when the option for pets is off. Default: off.
- **Only in arenas** – default: off.

Totems and your own nameplate never get a marker.

**Roles** – **Tanks**, **Healers**, **Damage dealers** (default: on). Only group members with an
assigned role are filtered; all others are not affected.

**Special icons**

- **Friends** – a heart for your friends (friend list and Battle.net). Default: on.
- **Guild** – a shield for members of your guild. Default: on.

**Appearance**

- **Class Colors** – role and texture icons in the class color of the unit. Default: on.
- **Desaturate icons** – role and texture icons in gray before coloring them. Default: on.
- **Enemies in red** – role and texture icons of enemies in red. Default: on.
- **Fade with the nameplate** – the marker becomes as transparent as its nameplate (distance, not
  targeted). Default: off.
- **Glow on the target** – a glow around the marker of your current target, with **Color**.
  Default: off, white.
- **Texture** – icon of the icon type "Texture": **Arrow**, **Heart**, **Shield**, **Dot**,
  **Skull**, **Star** or **Custom texture**. Default: Arrow.
- **Custom texture** – button **Edit …** sets the file or atlas of "Custom texture"
  (e.g. `Interface\Icons\INV_Misc_QuestionMark`).
- **Rotation** – of the texture, 0–360°. Default: 0°.
- **Size of pets** – size of other players' pets, 25–100 %. Default: 50 %.

### Friendly Markers / Enemy Markers

The same options, once for friendly units (also neutral ones and all group members) and once for
enemy units:

- **Icon type** – **Class** (class icon of players), **Role** (role of group members) or
  **Texture** (the texture chosen on the page "Nameplate Markers"). Default: Class.
- **Otherwise** – icon type when the first one is not available (e.g. no role or not a player):
  **None**, **Class**, **Role** or **Texture**. Default: Texture.
- **Icon Size** – 16–100. Default: 40.
- **Horizontal offset**, **Vertical offset** – position above the nameplate, −100 to 100.
  Default: 0 and 10.
- **Shape** – **Square** or **Round**. Default: Square.
- **Background** – black background behind the icon, with **Padding** 0–10. Default: on, 1.
- **Border** – border in the class color of players. Default: on.

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
- Nameplate markers need the game's nameplates (key V or the interface options). Roles are only
  known for group members, so enemy players never get a role icon.
- Some values (class, role, PvP state) can be hidden by the game, mostly for enemies in combat. Then
  the rule that needs the value is skipped: for example the class icon falls back to the
  "Otherwise" icon, and the border is left out.

[← Overview](README.md)
