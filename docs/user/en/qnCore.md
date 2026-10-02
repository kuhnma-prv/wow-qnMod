# qnCore – core of the qn addons: profiles, bag automation, tracking

qnCore is required by every other qn addon. It manages the settings profiles of all qn addons
(one profile per Edit Mode layout), opens and closes your bags automatically at the auction house,
bank, merchant and other places, remembers your minimap tracking selection across logins, deaths and
reloads, and lets you shrink the Objective Tracker font below Blizzard's minimum of 12.

## Features

- **Profiles per Edit Mode layout** for all qn addons: switching the layout in Edit Mode switches the
  settings of every qn addon. Character-specific layouts get their own profiles.
- A new layout starts with a copy of the previously active profile.
- **Profiles page**: copy a saved profile into the active one, delete profiles, reset the active
  profile – for all qn addons at once or for a single addon.
- **Bag automation**: what happens to your bags when the auction house, bank, guild bank, merchant,
  trade window or mailbox opens and closes – one setting for all locations or one per location.
- Optionally keep profession bags (herb, enchanting … bags, reagent bag) closed when all bags open.
- **Remember tracking**: restores the minimap tracking selection (e.g. Find Herbs, Find Minerals)
  after logging in, /reload, changing zones and resurrection.
- **Objective Tracker text size** 8–11 (below Blizzard's minimum), per profile.

## Getting started

Open *Options → AddOns → qnCore* (Esc → Options → AddOns tab). qnCore has three pages:

- **qnCore** – profile button, Minimap, Objective Tracker
- **Bag Automation**
- **Profiles**

`/qncore` (or `/qnc`) opens the main page, `/qncore profile` the Profiles page.

## Options

### qnCore

**Profile**

- **Settings profiles** – button **Profiles …** opens the Profiles page.

**Minimap**

- **Remember tracking** – remembers per character what is checked or unchecked in the minimap
  tracking menu and restores it after logging in, /reload, changing zones and resurrection. Changes
  you make yourself (menu, tracking spell from the action bar or spellbook) are remembered; the losses
  WoW causes (death, reload) are undone. Turning the option on takes the current selection as the one
  to remember. Default: on. The switch applies account-wide; the remembered selection is stored per
  character.

**Objective Tracker**

- **Text Size** – font size of the Objective Tracker below Blizzard's minimum: **As in Edit Mode**,
  8, 9, 10 or 11 (headers are 2 points larger). "As in Edit Mode" leaves Blizzard's slider in charge.
  Default: As in Edit Mode. Stored per profile (= per Edit Mode layout).

### Bag Automation

All bag settings apply account-wide (for all characters and all profiles).

**General**

- **Bag automation enabled** – turns the whole bag automation on or off. Turn it off if another bag
  addon handles opening and closing. Default: on.
- **Also open profession bags** – when all your bags open (B key, merchant, bank …), profession bags
  such as herb or enchanting bags and the reagent bag open as well. Off: they stay closed; clicking
  one still opens it. With combined bags this only affects the reagent bag. Default: on.
- **Same at every location** – on: one setting applies to every location. Off: each location is set
  up separately. Default: off.
- **Everywhere: on open** – what happens to your bags when one of the locations opens (only usable
  with "Same at every location"). Choices: **Do nothing**, **Open All Bags**, **Backpack only**,
  **Close all bags**. Default: Open All Bags.
- **Everywhere: close all bags on close** – closes all bags when the location closes (only usable
  with "Same at every location"). Default: on.

**Auction House, Bank, Guild Bank, Merchant, Player Trading Frame, Mailbox**

One section per location (only usable while "Same at every location" is off):

- **<Location>: on open** – same choices as above. Default: Open All Bags.
- **<Location>: close all bags on close** – Default: on.

### Profiles

Shows the active profile and all saved profiles. Profile names show the layout and its kind:
"(Blizzard preset)", "(account)" or "(character-specific, <character>)".

- **Active profile:** – the profile currently in use (= active Edit Mode layout).
- **Applies to:** – dropdown: **All qn addons** or a single qn addon. The list and all buttons on this
  page only affect the selected addons.
- **Reset active profile** – resets the settings of the active profile to default values (after
  confirmation).
- **Saved profiles** – one row per profile; hovering a row shows which addons have this profile
  ("Used by: …").
  - **Copy into active profile** – replaces the settings of the active profile with the ones of this
    profile (after confirmation). Not available for the active profile itself.
  - **Delete** – deletes this profile (after confirmation). The active profile cannot be deleted.

In combat, copying and resetting are applied after combat (a chat message says so).

## Slash commands

| Command | Effect |
|---|---|
| `/qncore`, `/qnc` (or `/qncore config`) | Opens the qnCore options |
| `/qncore profile` | Opens the Profiles page |
| `/qncore status` | Shows the qnCore version, the active profile and the number of profiles per qn addon in chat |
| `/qncore locale` | German client: lists texts that were shown without translation in this session |
| `/qncore <anything else>` | Shows a short help in chat |

## Tips & notes

- qnCore must be installed and enabled for every other qn addon.
- To use different settings, create or switch layouts in Edit Mode (Esc → Edit Mode). A chat message
  "Profile changed: …" appears when the profile switches. Until the layout is known after logging in,
  the profile of this character's last session applies.
- Copying a profile into the active profile overwrites the current settings of the active profile.
- Bag automation reacts one frame after Blizzard has opened its own windows, so it has the last word.
  If you use another bag addon, turn **Bag automation enabled** off.
- Tracking restore uses tracking spells one after another (with a short pause for the global
  cooldown) and waits until combat ends or you are alive again.
- After changing the Objective Tracker text size, Blizzard adjusts the line spacing with its next own
  rebuild of the tracker (quest progress, zone change, at the latest /reload).
- With LibSharedMedia installed, qnCore registers its background patterns there as "qn …"
  (e.g. "qn Stripes"), so other addons can use them.

[← Overview](README.md)
