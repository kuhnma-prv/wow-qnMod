# qnSkins – artwork around your action bars

qnSkins draws decorative artwork – backgrounds, framed boxes, a glowing cord and 3D figures – around
the action bars, status bars and micro menu at the bottom of the screen. By default the artwork
follows the elements wherever you placed them. Optionally qnSkins also gives these elements a
predefined position and scale, on the monitor of your choice.

## Features

- Two skins:
  - **Dragon's Lair** – a dark rock band across the full width of the monitor, topped by a red and
    gold cord just above all elements at the bottom; boxes with a thin border around the bar
    group, qnThreatMeter and qnNumKeyPad; a standing 3D warrior (a city guard of your faction) at
    the right end of the status bars.
  - **Stone Frame** – a marble panel around the bar group.
- The artwork lies below the elements and never blocks the mouse.
- Opt-in **Position elements**: moves and scales the elements to the skin's layout and keeps them
  there, also after Edit Mode.
- Scale and offset of the whole skin, choice of monitor (with qnViewPort).
- Every 3D figure adjustable: zoom, sideways, height, rotation, animation and size of its area.
- Figures can stand still in combat.

## Getting started

Open *Options → AddOns → qnSkins* or type `/qnskins`. Choose a skin in **Skin**. The subpage
**Figures** adjusts the 3D figures.

All settings belong to the active profile, i.e. the active Edit Mode layout (see [qnCore](qnCore.md)).

## Options

### qnSkins (main page)

Section **Skin**:

- **Skin**: **None** (default), **Dragon's Lair** or **Stone Frame**. Artwork around the action
  bars, status bars and micro menu.
- **Position elements**: moves and scales the elements to the skin's positions and keeps them
  there, also after Edit Mode. Without this option the artwork follows the elements wherever they
  are. Switching it off keeps the current positions until `/reload`. Default: off.
- **Monitor**: the monitor the skin is placed on – **Automatic (monitor with the 3D view)**
  (default; with qnViewPort the monitor with the 3D world, otherwise the largest) or **Monitor 1**,
  **Monitor 2** … counted from the left. Only with **Position elements**.
- **Horizontal offset**: shifts the whole skin, −800 to 800 UI units, default 0. Only with
  **Position elements**.
- **Vertical offset**: −400 to 400, default 0. Only with **Position elements**.
- **Scale**: 0.5–2, default 1. Scale of the artwork and – with **Position elements** – of the elements.
- **Pause figures in combat**: the 3D figures stand still while you are in combat. Default: on.
- **Apply again** – **Apply**: places the elements and the artwork again now (same as `/qnskins apply`).

With **Position elements**, both skins arrange the elements at the bottom of the monitor: status
bar 1 at the bottom center, status bar 2 above it, the micro menu above that, action bar 2 to the
right of the micro menu, action bar 1 above action bar 2, the pet bar above action bar 1 (right
aligned) and the vehicle button above action bar 1 (left aligned). qnThreatMeter is placed left of
qnNumKeyPad and keeps its own scale. The right action bars (4 and 5) are left alone.

### Figures

One section per 3D figure of every skin, titled "skin – figure" (currently **Dragon's Lair –
Warrior**). The values act at once.

- **Zoom**: distance of the camera; larger values show the figure smaller. 0.2–4, default 1.
- **Sideways**: −10 to 10, default 0.
- **Height**: moves the figure up or down within its area; parts outside the area are cut off.
  −10 to 10, default 0.
- **Rotation**: −3.15 to 3.15, default −0.4 for the warrior.
- **Animation**: number of the animation, 0 = standing (default). Which number lets a figure lie
  or sleep depends on the model – try it out. 0–250.
- **Area below** / **Area above**: extends the area of the figure downwards/upwards (UI units,
  −100 to 400, default 0). The figure is cut off at its area; a larger area usually shows it larger
  – correct with **Zoom**.

## Slash commands

| Command | Effect |
|---|---|
| `/qnskins`, `/qnskins config`, `/qnskins options` | Open the options |
| `/qnskins apply` | Apply the skin again |
| `/qnskins list` | List the skins (the active one is marked with `>`) |
| `/qnskins frames` | List the elements (Edit Mode name, shown/hidden, size, position) and the artwork pieces of the active skin |
| `/qnskins model <artwork> <creature ID \| d:display ID> [animation] [rotation]` | Try out another model for a figure until the next reload; animation and rotation are saved |
| `/qnskins camera <artwork> <zoom> [sideways] [height]` | Set zoom and position of a figure (saved like on the **Figures** page) |
| `/qnskins help` | Show the command list |

`<artwork>` is the key of a figure of the active skin, e.g. `warrior` for Dragon's Lair (see
`/qnskins frames`).

## Tips & notes

- The artwork lies below the elements, so bars shown later (pet bar, vehicle button) cover it.
- Hidden elements count where they would appear, if that is in the lower part of the screen – so
  the band also leaves room for bars that are only shown sometimes.
- **Position elements** does not act while Edit Mode is open; afterwards the skin positions are
  applied again. If Blizzard or another addon moves an element, qnSkins puts it back.
- In combat, protected elements cannot be moved; positioning is then done right after combat.
- In Dragon's Lair the cord runs just above the highest of the bottom elements: action bars 1 and 2,
  pet bar, vehicle button, micro menu, status bars, Possess Bar, Extra Abilities, Zone Map,
  qnThreatMeter and qnNumKeyPad. Keep these at the bottom of the screen, otherwise the band rises
  up to them. qnThreatMeter and qnNumKeyPad get their own boxes when they are loaded.
- Optional dependency qnViewPort: with several monitors the skin uses its monitor areas;
  without it the whole window counts as one monitor.

[← Overview](README.md)
