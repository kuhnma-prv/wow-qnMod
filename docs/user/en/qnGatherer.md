# qnGatherer

Gathering database for herbs, ore, fishing and treasure – **in development**.

Back to the [overview](README.md) · German: [Deutsch](../de/qnGatherer.md)

qnGatherer records the gathering nodes you find and shows them on the world map and the minimap.
It comes without data: the maps fill up as you gather (import from other gathering addons and an
exchange with your guild are planned).

## Recording

- **Nodes** when you gather them: herbs (Herbalism), ore (Mining) and chests (Opening, Pick Lock).
  The node's position is the place where you stand when you gather it. Nodes of the same resource
  close to each other (merge radius, 15 yards) count as one node.
- **Nodes you cannot gather yet**: if the game says "Requires Mining 175" or the chest is locked,
  the node is stored by its name together with the required skill. When you gather it later, it is
  stored as a normal node.
- **Fishing**: every item you fish up is counted per character and zone (junk included). Fish
  are stored as **fishing areas** around the place where you cast; casts close to each other add
  their fish to the same area (at most 30 learned areas per zone). Fishing in a **school** also
  stores the school about 15 yards in front of you.
- Skinning is not recorded (beasts have no fixed place).

## World map

- Every node is shown with the icon of its item. The tooltip shows the name, the required skill (if
  known) and where the node comes from ("Found by …", "Imported from …"); several nodes under the
  mouse are listed together.
- **Right-click** on a node: **Delete: <name>** (the node does not come back through the guild or an
  import later), **Set waypoint** (Blizzard's map pin) and, with TomTom, **Add TomTom waypoint**.
  Right-click on free map space still zooms out.
- Fishing areas can be shown as colored ellipses.

## Minimap

- Nodes around you are shown with their icon; within the **tracking distance** the icon becomes a
  **ring** in the color of the kind (herbs green, ore red, fish yellow, treasure purple).
- Nodes outside the view slide along the edge of the minimap and fade out with the distance.
- Works with the rotating minimap and with square or other minimap shapes of minimap addons.
- Mouse over a pin shows the tooltip; left-click pings the minimap at that place.

## Options

*Options → AddOns → qnGatherer*. All pages except **Data** and the minimap button belong to the
active profile (Edit Mode layout).

### qnGatherer

| Option | Default | Meaning |
|---|---|---|
| **Shown nodes**: Herbalism, Mining, Fishing, Treasure | With the profession (Treasure: Always) | **Always**, **With the profession** (only if this character has it), **While tracking** (only while Find Herbs, Find Minerals … is active), **Never** (hidden, still recorded) |
| Show nodes found by your guild | on | |
| Show imported nodes | on | |
| Show minimap button | on | account-wide |

### World Map

| Option | Default |
|---|---|
| Show icons on the world map | on |
| Icons clickable (tooltip and right-click menu) | on |
| Icon size | 100 % |
| Icon opacity | 100 % |
| Show fishing areas | off |

### Minimap

| Option | Default |
|---|---|
| Show icons on the minimap | on |
| Tooltips on the minimap | on |
| Show nodes on the edge | on |
| Icon size | 75 % |
| Icon opacity | 100 % |
| Show tracking ring | Always |
| Tracking distance (yards) | 100 |
| Color per kind | green, red, yellow, purple |

### Filter

One checkbox per known resource (gathered, imported or received from your guild), grouped by kind,
with **All** and **None**. Hidden resources are still recorded. "Defaults" shows everything again.

### Fishing

| Option | Default | Meaning |
|---|---|---|
| Sound boost while fishing | off | effect sound on and at full volume while you fish; your settings are restored when the cast ends (also after logging out or a crash) |

### Data (account-wide)

- **Merge radius (yards)** per kind (default 15) and **Clean up database**: merges nodes within the
  radius again, e.g. after changing it.
- **Database lock** per kind: nothing is added, deleted, cleaned up or imported for a locked kind.
- **Delete**: choose the kind, then **Delete in the current zone** (these nodes do not come back
  through the guild or an import) or **Delete all nodes of the kind**; **Remove guild data**,
  **Remove imported data**. Each asks for confirmation.

## Minimap button and Titan Panel

- **Minimap button**: left-click minimap icons on/off, Shift-left-click world map icons on/off,
  right-click options; drag it along the edge of the minimap.
- **Titan Panel** (optional): plugin **qnGatherer** with the number of shown nodes in the current
  zone; tooltip with nodes per kind (zone / total); same clicks as the minimap button, right-click
  menu with the toggles and the options.

## Slash commands and key bindings

| Command | Effect |
|---|---|
| `/qngatherer`, `/qng` | open the options |
| `/qngatherer minimap` | minimap icons on/off |
| `/qngatherer worldmap` | world map icons on/off |
| `/qngatherer sound` | sound boost while fishing on/off |
| `/qngatherer cleanup` | clean up the database |
| `/qngatherer help` | list of the commands |

Key bindings (*Options → Keybindings → AddOns → qnGatherer*): **Minimap icons on/off**,
**World map icons on/off**.

## Saved data

All gathered data is account-wide (shared by all characters); catches are stored per character.

Planned next: a journal window with fishing and gathering information, import from GatherMate2 and
GatherTogether, an optional data exchange with your guild.
