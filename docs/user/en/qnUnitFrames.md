# qnUnitFrames – click casting and range icon

qnUnitFrames adds click casting to Blizzard's own party and raid frames, similar to HealBot:
a click with a mouse button and an optional modifier key casts a spell or a macro on the clicked
group member. The bindings are set per class and stored in the active profile (Edit Mode layout).
In addition, qnUnitFrames can show a small range icon next to the target and focus frame.

## Features

- Click casting on Blizzard's raid-style party and raid frames, the classic party frames and
  the pet frames.
- 5 mouse buttons × 8 modifier combinations (none, SHIFT, CTRL, ALT and their combinations).
- Actions: spell (from the spellbook or entered by name/spell ID), macro text, target, menu,
  set focus, assist – or leave Blizzard's default behavior.
- Optional list of the bindings below the tooltip of a bound frame.
- Bindings per class and per profile; another Edit Mode layout can have different bindings.
- Range icon to the right of the target frame and/or focus frame: shows the icon of your farthest
  usable ranged attack while the unit is in its range, and the auto attack icon in melee range.
- Changes made in combat are applied automatically after combat.

## Getting started

Open *Options → AddOns → qnUnitFrames*, or type `/qnuf`. The page **Click Bindings** below it holds
the actual bindings (`/qnuf clicks`).

All settings belong to the active profile, i.e. the active Edit Mode layout (profiles are managed
on qnCore's **Profiles** page). The click bindings are additionally stored per class inside the
profile.

## Options

### qnUnitFrames

**General**

- **Click casting enabled** – turns click casting on or off. Off removes all qnUnitFrames
  bindings; the frames behave as without the addon. Default: on.
- **Click Bindings** – button **Edit …** opens the Click Bindings page.
- **Show bindings in tooltip** – shows below the tooltip of a bound frame which click does what
  (e.g. "SHIFT+Left Mouse Button – Flash Heal"). Default: on.

**Frames** – which frames get the bindings:

- **Raid-style frames** – Blizzard's raid frames and the party frames with the option
  "Use Raid-Style Party Frames". Default: on.
- **Classic party frames** – the party frames without that option. Default: on.
- **Pet frames** – also bind the frames of party members' pets. Default: on.

**Range Icon** – one block for each frame:

- **At the target frame** / **At the focus frame** – shows the range icon to the right of the
  frame. Default: off.
- **Icon Size** – 12 to 64, default 24.
- **Horizontal offset** – distance from the right edge of the frame (−200 to 200, default 0);
  negative values move the icon to the left.
- **Vertical offset** – distance from the vertical center of the frame (−200 to 200, default 0);
  positive values move the icon up.

The size and offset sliders can only be changed while the icon of that frame is turned on.

How the range icon decides what to show (checked about five times per second):

- **Melee range:** the icon of the auto attack appears if none of your checkable melee spells
  reports "out of range". If you have no checkable melee spell (e.g. a druid in caster form), the
  duel distance (about 10 yards) decides.
- **Otherwise:** the icon of your farthest harmful ranged spell from the spellbook that can be
  used right now appears, as soon as the unit is within its range. Missing mana, rage or energy
  does not hide it.
- No icon if the unit is out of range of all these spells or the range cannot be checked
  (harmful spells cannot be checked against friendly units).

### Click Bindings

At the top you see for which class and profile the bindings apply
("Bindings for Priest in profile …").

- **Mouse button:** – selects the mouse button you are editing (Left Mouse Button, Right Mouse
  Button, Middle Mouse, Mouse Button 4, Mouse Button 5). Default: Left Mouse Button.
- **Delete all** – deletes all click bindings of your class in the active profile (all mouse
  buttons), after a confirmation.
- One row per modifier (**No modifier**, **SHIFT**, **CTRL**, **ALT**, **CTRL+SHIFT**,
  **ALT+SHIFT**, **ALT+CTRL**, **ALT+CTRL+SHIFT**), each with an action dropdown:
  - **Blizzard default** – nothing is changed (left click: select target, right click: menu).
    This is the default for every row.
  - **Spell** – a second dropdown **Choose spell …** lists the active spells of your spellbook.
    **Other spell …** opens an input field for a spell name or spell ID (e.g. for spells not yet
    learned).
  - **Macro** – **Edit …** opens the macro editor at the bottom of the page; the row shows the
    start of the macro text. The macro is not cast on the clicked unit automatically: use
    `[@mouseover]`, e.g. `/cast [@mouseover] Heal`. Up to 255 characters; blank lines are
    removed. **Accept** saves, **Cancel** discards.
  - **Target**, **Menu**, **Set Focus**, **Assist** – the corresponding action on the clicked
    unit.

Note: if you bind a spell to the left click without modifier, that click no longer selects the
target.

## Slash commands

| Command | Effect |
|---|---|
| `/qnuf`, `/qnunitframes` (also `config`, `options`) | Open the options |
| `/qnuf clicks` | Open the Click Bindings page |
| `/qnuf on` | Turn click casting on |
| `/qnuf off` | Turn click casting off |
| `/qnuf` + anything else | Show the list of commands |

## Tips & notes

- Blizzard does not allow changing the bindings of the frames in combat. Changes you make in
  combat (including a profile switch) take effect automatically after combat; a chat message tells
  you so.
- The bindings apply per class: a priest and a druid in the same profile have their own bindings.
  Switching the Edit Mode layout switches the profile and therefore the bindings.
- Only Blizzard's party and raid frames are bound, not nameplates, the target frame or frames
  of other addons.
- The range icon only uses harmful spells from your spellbook; healing spells are not considered.
- Requires qnCore.

[← Overview](README.md)
