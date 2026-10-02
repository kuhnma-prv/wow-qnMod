# qnTooltip – customizable tooltips

qnTooltip changes the look of the game's tooltips and adds information: own background and
border, fonts and scale, an optional different position, unit header lines built from freely
arrangeable elements, a styled health bar with values, the unit's target, "Targeted by", a 3D
model, item level of players and IDs of items, spells and quests. All settings are stored in the
active profile (Edit Mode layout).

## Features

- Own background (Blizzard textures, qnCore patterns, LibSharedMedia backgrounds), background and
  border color, border style, scale, light gradient over the header, fonts for header and text.
- Also styles link, comparison and friend tooltips (optional).
- Position only on request: at the cursor, right of the cursor or at a fixed point; separately
  for players and NPCs; optionally back at Blizzard's spot in combat or over unit frames.
- Hide tooltips in combat, show them anyway with a modifier key.
- Health bar: placement, height, texture, color mode, health points and percent.
- Unit tooltips: header lines of players and NPCs built from elements (name, title, guild, level,
  class, icons …) with line, order, color, format and filter per element.
- Border/background color per unit kind (class, reaction, level …), gray for dead units,
  large faction emblem.
- Target of the unit (">>YOU<<" if it targets you), group members targeting the unit, 3D model.
- Item level of other players (via inspect) and of yourself.
- Items, spells, quests: border in quality/difficulty color, icon before the name, item/spell/
  quest/icon IDs, stack size.
- Tooltips when hovering links in chat.

## Getting started

Open *Options → AddOns → qnTooltip*, or type `/qntt`. Below the main page there are the pages
**Appearance**, **Position**, **Health Bar**, **Player**, **NPC**, **Items & Spells**,
**Lines: Player** and **Lines: NPC**.

All settings belong to the active profile, i.e. the active Edit Mode layout (profiles are managed
on qnCore's **Profiles** page).

## Options

### qnTooltip

**General**

- **Also style link, comparison and friend tooltips** – applies the look also to the tooltips of
  chat links, the item comparison tooltips and the friends list tooltip. When turned off, these
  tooltips keep their look until the next `/reload`. Default: on.
- **Remove the right-click hint on unit frames** – removes the line
  "<Right click for Frame Settings>" from unit frame tooltips. Default: on.
- **Tooltip when hovering chat links** – shows the tooltip of item, spell, enchant, quest,
  talent, achievement and currency links in chat at the cursor while you hover them.
  Default: on.
- **Show all elements while holding Alt or Ctrl** – while Alt or Ctrl is held, unit tooltips also
  show disabled and filtered elements. Default: on.

### Appearance

**Display**

- **Scale** – size of the tooltips, 0.50 to 2.00. Default: 1.00.
- **Background** – Rock, Marble, Dark, Translucent, Flat, plus qnCore's patterns and the
  backgrounds of LibSharedMedia (if installed). Default: Rock.
- **Background color** / **Background opacity** – default black, 70 %.
- **Border** – Default (Blizzard's tooltip border), Angular (thin solid line) or None.
  Default: Default.
- **Border width (angular)** – 1 to 8, only for "Angular". Default: 1.
- **Border color** / **Border opacity** – default gray, 80 %.
- **Light gradient over the header** – default on.

**Fonts** – for **Header** (first line) and **Text lines** each:

- **Font: …** – Default or a font from LibSharedMedia. Default: Default.
- **Font size: …** – 0 to 24; 0 (shown as "Default") = Blizzard's size. Default: 0.
- **Outline: …** – Default, No Outline, Thin Outline, Outline, Thick Outline. Default: Default.

### Position

qnTooltip only moves tooltips that Blizzard places at its default spot (units in the world, unit
frames, action bars …), and only if something other than "Blizzard default" is selected.

**Position**

- **Position** – Blizzard default (Edit Mode), At the cursor, Right of the cursor, Fixed point.
  Default: Blizzard default (Edit Mode).
- **Fixed point: anchor** – screen point for "Fixed point" (top left … bottom right).
  Default: Bottom right.
- **Fixed point: X offset** / **Fixed point: Y offset** – −1000 to 1000. Default: −60 / 120.
- **Position for players** / **Position for NPCs** – own position for unit tooltips of players or
  NPCs, or "As set in general". Default: As set in general.
- **At Blizzard's position in combat** – in combat the tooltip stays at Blizzard's spot.
  Default: on.
- **At Blizzard's position over unit frames** – over unit frames the tooltip stays at Blizzard's
  spot. Default: off.

**Combat**

- **Hide tooltip in combat** – hides tooltips at Blizzard's default position in combat.
  Default: off.
- **Show anyway with this key** – None, ALT key, CTRL key, SHIFT key. While the key is held in
  combat, the tooltip is shown anyway; pressing it over a unit shows its tooltip. Default: None.

### Health Bar

**Health Bar**

- **Hide health bar** – default off.
- **Height** – 1 to 20. Default: 4.
- **Placement** – On the bottom edge, On the top edge, Below the tooltip (Blizzard).
  Default: On the bottom edge.
- **Side inset** – 0 to 30; 0 (shown as "Default") = matching the border. Default: 0.
- **Texture** – Blizzard, Flat, Raid, plus the status bar textures of LibSharedMedia.
  Default: Blizzard.
- **Color** – Blizzard (green), Class or selection color (players in class color, others in the
  selection color), By health (green – yellow – red). Default: Class or selection color.

**Text**

- **Show health points** – "current / maximum". Default: on.
- **Show percent** – default on. Dead units show "<Dead>".
- **Font: Health Bar**, **Font size: Health Bar**, **Outline: Health Bar** – as on the
  Appearance page. Default: Default, 10, Thin Outline.

### Player and NPC

Same controls on both pages; they apply to the unit tooltips of players or NPCs.

- **Border color** – Default, Class Color, Level Color, Reaction Color, Faction Color,
  Selection Color. Default: Class Color (players), Reaction Color (NPCs).
- **Background color** – same choices; "Default" uses the general background color.
  Default: Class Color (players), Default (NPCs).
- **Background opacity** – default 90 %.
- **Show target** – adds a line "Target: …" with the unit's target, updated continuously;
  ">>YOU<<" if it targets you. Default: on.
- **Show 'Targeted by'** – group and raid members targeting the unit. For NPCs in a raid only
  their number is shown. Default: on.
- **Show 3D model** – model of the unit above the tooltip; it rotates while Ctrl or Alt is held.
  Default: on.
- **Show dead units in gray** – default off.
- **Large faction emblem** – Alliance/Horde emblem in the top right corner of the tooltip.
  Default: on (players), off (NPCs).
- **Lines** – button **Edit lines …** opens the page Lines: Player or Lines: NPC.

### Lines: Player and Lines: NPC

The header lines of a unit tooltip are built from these elements. The list shows them in the order
in which they appear in the tooltip. Per row:

- checkbox – element on/off,
- **Line** – tooltip line 1 to 8 (the element is put at the end of that line),
- **Order** – arrows to move the element within its line,
- **Preview** – sample value in its color and format (your own character, or the targeted NPC on
  the NPC page),
- pencil (**Edit**) – opens the dialog **Element: …**:
  - **Color** – Default, Class Color, Level Color, Reaction Color, Faction Color, Selection Color
    or **Custom color …** (color picker).
  - **Filter** – None, or "only …"/"not …" in a group, in a raid, in combat, in an instance, in a
    battleground, in an arena, from your realm, from your guild, reputation friendly or better,
    reputation honored or better.
  - **Format** – text around the value with exactly one `%s` (for numbers also `%d`); write a
    percent sign as `%%`. Color codes like `|cffff0000red|r` color a part. Shows a preview;
    the examples below can be clicked to use them.
  - **Okay** applies, **Cancel** (or closing) restores the previous values.

  Icons have neither color nor format – only the filter applies to them.

At the top, **Preview** shows the real tooltip of your own character (Player) or of the targeted
NPC. **Defaults** resets all elements of this page after a confirmation.

Elements and their default state:

| Player element | Default |
|---|---|
| Friend Icon, Raid Target Icon, Role Icon, PvP Icon (free-for-all PvP), Faction Icon, Class Icon, Title, Name, Surname, Realm, Away, Busy, Offline | line 1, on |
| Guild, Rank, Guild Realm | line 2, on |
| Guild Rank Number | line 2, off |
| Level, Faction, Race, Class | line 3, on |
| Gender, Player, Role, Movement Speed | line 3, off |
| Item Level | line 4, on |
| Zone (raid members only) | line 5, off |

| NPC element | Default |
|---|---|
| Raid Target Icon, Quest Icon, Name | line 1, on |
| Class Icon | line 1, off |
| Title (always in Blizzard's title line, e.g. "<Innkeeper>"; color and format only) | on |
| Level, Boss, Elite, Rare, Creature Type | line 2, on |
| Reputation (filter: only reputation honored or better) | line 2, on |
| Movement Speed | line 2, off |

The item level of your own character comes from your equipped gear; for other players it is
requested via inspect out of combat and shows "??" until it is known.

### Items & Spells

**Items**

- **Border in the quality color** – default on.
- **Icon before the name** – default on.
- **Item ID**, **Icon ID**, **Stack Size** (only for stackable items) – default on.

**Spells**

- **Icon before the name**, **Spell ID**, **Icon ID** – default on. Spell ID and icon ID also
  appear on buff/debuff tooltips.
- **Background color** / **Background opacity** – for spell tooltips. Default black, 80 %.
- **Border color** / **Border opacity** – for spell tooltips. Default gray, 80 %.

**Quests**

- **Border in the difficulty color** – default on.
- **Quest ID** – default on.

**IDs**

- **IDs only while Shift, Ctrl or Alt is held** – default off.

## Slash commands

| Command | Effect |
|---|---|
| `/qntt`, `/qntooltip` (also `config`, `options`) | Open the options |
| `/qntt reset` | Reset all settings of the active profile |
| `/qntt` + anything else | Show the list of commands |

## Tips & notes

- Optional: [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) adds
  more backgrounds, fonts and status bar textures to the dropdowns.
- Many unit values can be hidden by the game in some situations (e.g. in instances or combat).
  qnTooltip then shows them without class/level coloring or leaves out elements whose value or
  filter cannot be read.
- The item level of other players is only requested out of combat and not while Blizzard's
  inspect window is open; known values are remembered for 10 minutes.
- "Show all elements while holding Alt or Ctrl" applies when the tooltip is built: hold the key
  before hovering the unit.
- Requires qnCore.

[← Overview](README.md)
