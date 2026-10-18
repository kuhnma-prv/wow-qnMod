# qnGatherer

Gathering database for herbs, ore, fishing and treasure – **in development**.

Back to the [overview](README.md) · German: [Deutsch](../de/qnGatherer.md)

## Current state (0.3.0)

qnGatherer records nodes while you play and shows them on the world map and the minimap. There is
no options page and no slash command yet; the settings below use their defaults.

## Recording

- **Nodes** when you gather them: herbs (Herbalism), ore (Mining) and chests (Opening, Pick Lock).
  The node's position is the place where you stand when you gather it. Nodes of the same kind close
  to each other (15 yards) count as one node.
- **Nodes you cannot gather yet**: if the game says "Requires Mining 175" or the chest is locked,
  the node is stored by its name together with the required skill. When you gather it later, it is
  stored as a normal node.
- **Fishing**: every item you fish up is counted per character and zone (junk included). Fish
  are stored as **fishing areas** around the place where you cast; casts close to each other add
  their fish to the same area (at most 30 learned areas per zone). Fishing in a **school** also
  stores the school about 15 yards in front of you.

## World map

- Every node is shown with the icon of its item. The tooltip shows the name, the required skill (if
  known) and where the node comes from ("Found by …", "Imported from …"); several nodes under the
  mouse are listed together.
- **Right-click** on a node: **Delete: <name>** (the node does not come back through the guild or an
  import later), **Set waypoint** (Blizzard's map pin) and, with TomTom, **Add TomTom waypoint**.
- Fishing areas can be shown as colored ellipses (off by default).

## Minimap

- Nodes around you are shown with their icon; within the **tracking distance** (100 yards) the icon
  becomes a **ring** in the color of the kind (herbs green, ore red, fish yellow, treasure purple).
- Nodes outside the view slide along the edge of the minimap and fade out with the distance.
- Works with the rotating minimap and with square or other minimap shapes of minimap addons.
- Mouse over a pin shows the tooltip; left-click pings the minimap at that place.

## What is shown (defaults)

| Kind | Shown |
|---|---|
| Herbs, ore, fish | only if your character has the profession |
| Treasure | always |

Further defaults: world map icons size 100 %, fully opaque, clickable; minimap icons size 75 %,
tooltips and edge on; nodes found by your guild and imported nodes are shown. These settings will
become adjustable on the options page in a later version.

## Sound boost while fishing

qnGatherer can turn the effect sound on and to full volume while you fish, so that the splash is
easy to hear, and restores your settings when the cast ends (also after logging out or a crash).
**Off by default**; the option will be on the options page.

Planned next: options page, a journal window with fishing and gathering information, import from
other gathering addons and an optional data exchange with your guild.

## Saved data

All gathered data is account-wide (shared by all characters); catches are stored per character.
Display settings belong to the active profile (Edit Mode layout) like in the other qn addons.
