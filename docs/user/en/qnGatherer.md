# qnGatherer

Gathering database for herbs, ore, fishing and treasure – **in development**.

Back to the [overview](README.md) · German: [Deutsch](../de/qnGatherer.md)

## Current state (0.2.0)

qnGatherer records while you play, but does **not show anything yet**: no map icons, no window, no
options page and no slash command.

What is recorded:

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

### Sound boost while fishing

qnGatherer can turn the effect sound on and to full volume while you fish, so that the splash is
easy to hear, and restores your settings when the cast ends (also after logging out or a crash).
**Off by default**; the option will be on the options page that comes in a later version.

Planned next: icons on the world map and the minimap, a journal window with fishing and gathering
information, options, import from other gathering addons and an optional data exchange with your
guild.

## Saved data

All gathered data is account-wide (shared by all characters); catches are stored per character.
Display settings will belong to the active profile (Edit Mode layout) like in the other qn addons.
