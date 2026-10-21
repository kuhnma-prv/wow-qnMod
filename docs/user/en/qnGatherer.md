# qnGatherer

Gathering database for herbs, ore, fishing and treasure – **in development**.

Back to the [overview](README.md) · German: [Deutsch](../de/qnGatherer.md)

qnGatherer records the gathering nodes you find and shows them on the world map and the minimap.
It comes without data: the maps fill up as you gather, by importing from GatherMate2 or
GatherTogether, from another qnGatherer user or through the exchange with your guild.

## Recording

- **Nodes** when you gather them: herbs (Herbalism), ore (Mining) and chests (Opening, Pick Lock).
  The node's position is the place where you stand when you gather it. Nodes of the same resource
  close to each other (merge radius, 15 yards) count as one node.
- **Nodes you cannot gather yet**: if the game says "Requires Mining 175" or the chest is locked,
  the node is stored by its name together with the required skill. This also works on characters
  without the profession: click the herb or the vein, and the error message ("Requires Herbalism")
  records it at your position with the name from its tooltip. When you gather it later, it is
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

## Journal

`/qngatherer` or left-click on the minimap button opens the journal:

- At the top the **kind** (dropdown); the title shows your skill with bonus, e.g. "Fishing 150 (+25)".
- On the left the **zones** with data of this kind, with their skill range (if known) or the number
  of nodes. The **search** finds zones by zone name or by resource name; **Current zone** jumps to
  the zone you are in.
- On the right a **preview of the zone map** (fully explored areas of your account) with the nodes
  and areas; mouse over shows the tooltip.
- Below it the **resources** of the zone: icon, name, required skill, number of nodes, your catches.
  Mouse over shows the item tooltip; clicking a resource shows only its nodes and areas on the
  preview, clicking it again shows all.

The journal only contains what is recorded, imported or received from your guild.

## Info window

A small window that opens when you **fish** (and optionally when you gather): your skill, the zone
with its skill range and the resources of the zone with required skill and your catches; while
fishing it shows "Listen for the splash …". It closes a few seconds after the cast. **Keep open**
(or `/qngatherer mini`) pins it; closing it with the X unpins it. **Journal** opens the journal on
this zone.

## Options

*Options → AddOns → qnGatherer*. All pages except **Data**, **Import**, **Guild** and the minimap button belong to the
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
| **Info window**: Open while fishing | on | |
| Open while gathering | off | herbs, ore, chests |
| Close after (seconds) | 8 | unless "Keep open" is checked |

### Data (account-wide)

- **Merge radius (yards)** per kind (default 15) and **Clean up database**: merges nodes within the
  radius again, e.g. after changing it.
- **Database lock** per kind: nothing is added, deleted, cleaned up or imported for a locked kind.
- **Delete**: choose the kind, then **Delete in the current zone** (these nodes do not come back
  through the guild or an import) or **Delete all nodes of the kind**; **Remove guild data**,
  **Remove imported data**. Each asks for confirmation.

### Import (account-wide)

- **Import mode**: **Merge** (adds what is new; nodes you deleted stay deleted) or **Replace**
  (first removes everything imported from this addon before).
- **GatherMate2**, **GatherTogether**: imports the data of the addon while it is loaded. GatherMate2:
  its nodes (matched by name with the resources you know; others appear by name until you gather
  them). GatherTogether: herb and ore areas, fishing areas (reported, schools, its learned spots),
  zone skill ranges and fish lists, its catches, the map overlays (the journal then shows whole
  zones) and the skinning level bands (journal entry **Skinning**).
- **Import automatically** (off): on login, imports again from a loaded addon whose version changed.
- **Export your nodes** / **Import an export text**: your own nodes and fishing areas as text for
  another qnGatherer user (copy with Ctrl+C, paste with Ctrl+V).

Imported data is marked "Imported from …" and can be hidden (page qnGatherer) or removed (page Data).

### Offline import

For an addon that does not load on Forever (e.g. GatherMate2) or is not installed, close the game and
run in the repository:

```
pwsh tools\Convert-QnGatherer.ps1 -SavedVariables '<WoW>\_classic_beta_\WTF\Account\<ACCOUNT>\SavedVariables' -GatherMate2 '<folder of GatherMate2>' -GatherTogether '<folder of GatherTogether>'
```

It reads the saved data and files of those addons and stores the records in qnGatherer's saved
variables (backup `qnGatherer.lua.bak`); qnGatherer imports them on the next login and reports the
result in the chat. `-Locale` (default deDE) sets the language of GatherMate2's node names.

### Guild (account-wide)

| Option | Default | Meaning |
|---|---|---|
| Exchange nodes with your guild | on | your nodes go to the guild members who use qnGatherer, theirs come to you ("Found by …") |
| Pass on nodes found by your guild | off | members who come online later also get the nodes you received from others |
| Share imported data | off | also send the nodes imported from other addons |
| Report received nodes in the chat | on | one chat line per member and zone, e.g. "Guild: 3 new nodes (Mining) in Elwynn Forest from Bob." |
| Ignored members | – | nothing is taken over from these members (Name-Realm, separated by commas) |
| Status | – | members with qnGatherer, messages sent, nodes received/rejected (also `/qngatherer sync`) |

How it works: new nodes you find are sent to the guild a few seconds later. After logging in, each
qnGatherer announces a short checksum of its data; members whose data differs exchange only the
zones that changed (by whisper). Nothing is deleted through the exchange, and nodes you deleted
yourself are not taken over again. Messages are sent slowly and not in combat, so they do not
disturb the chat; a member can send at most 5000 nodes per hour. A request that is repeated while
its answer is still waiting is answered only once, and requests wait while many messages are queued.

## Minimap button and Titan Panel

- **Minimap button**: left-click journal, Shift-left-click minimap icons on/off, Ctrl-left-click
  world map icons on/off, right-click options; drag it along the edge of the minimap.
- **Titan Panel** (optional): plugin **qnGatherer** with the number of shown nodes in the current
  zone; tooltip with nodes per kind (zone / total); same clicks as the minimap button, right-click
  menu with the journal, the toggles and the options.

## Slash commands and key bindings

| Command | Effect |
|---|---|
| `/qngatherer`, `/qng` | open/close the journal |
| `/qngatherer options` | open the options |
| `/qngatherer mini` | info window: keep open on/off |
| `/qngatherer minimap` | minimap icons on/off |
| `/qngatherer worldmap` | world map icons on/off |
| `/qngatherer sound` | sound boost while fishing on/off |
| `/qngatherer sync` | status of the guild exchange |
| `/qngatherer cleanup` | clean up the database |
| `/qngatherer help` | list of the commands |

Key bindings (*Options → Keybindings → AddOns → qnGatherer*): **Open/close the journal**,
**Minimap icons on/off**, **World map icons on/off**.

## Saved data

All gathered data is account-wide (shared by all characters); catches are stored per character.
