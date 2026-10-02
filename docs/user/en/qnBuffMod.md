# qnBuffMod – freely configurable buff and debuff windows

qnBuffMod replaces Blizzard's buff and debuff frames with up to 10 windows of your own. Each window
shows the auras of one unit (player, vehicle, pet, target or focus), as icons with a bar or as
plain icons, grouped and sorted the way you want. It can warn you in the chat before a buff
expires and offers a key to recast it.

## Features

- Up to 10 aura windows, each with its own unit, look, layout, grouping and sorting.
- Two button styles: icon with bar (name, time remaining, timer bar) or icon only.
- Groups: debuffs, cancelable buffs, uncancelable buffs, all buffs, weapon enchants (main hand and
  off hand).
- Separate own buffs and non-expiring buffs, hide them or show only them.
- Debuff colors by type (curse, disease, magic, poison, others) for border, bar and name.
- Visibility per window: always, simple conditions (combat, vehicle) or your own macro condition.
- Icons flash shortly before they expire; chat warning with optional sound.
- Key binding **Recast Buffs** to recast a buff that is about to expire.
- Right-click on one of your own buffs cancels it (out of combat).
- Hides Blizzard's buff and debuff frames (can be switched off).
- Settings per profile (Edit Mode layout).

## Getting started

Options: *Options → AddOns → qnBuffMod* with the subpages **Window**, **Appearance**, **Buttons**
and **Grouping**. `/qnbuff` opens the options.

After the first login there is one window (**Window 1**) in the middle of the screen showing your
buffs. Drag it with the left mouse button to where you want it.

- **Alt-click** on a window selects it in the options and opens the **Window** page.
- While one of the window pages is open, every window shows its name above it; the selected one
  is white, the others are gold.
- The four window pages always show the settings of the window selected under **Edit window** at
  the top of each page.

## Options

All settings of qnBuffMod – the general ones and all windows including their positions – are
stored **per profile**, i.e. per Edit Mode layout (see qnCore, page **Profiles**). A different
layout has its own set of windows.

### qnBuffMod

**Blizzard Frames**

- **Hide Blizzard's buff frames** – hides Blizzard's frames for buffs and debuffs. Default: on.

**Colors** (color swatch plus opacity slider each)

- **Window background** – background of all windows without a color of their own. Default:
  black, 25 % opacity.
- **Buffs** – bar color of buffs with a duration. Default: blue, 50 %.
- **Auras** – bar color of buffs without a duration. Default: green, 50 %.
- **Debuffs** – bar color of debuffs. Default: red, 85 %.
- **Weapon enchants** – bar color of weapon enchants. Default: purple, 75 %.

**Expiration**

- **Flash icon before expiry** – the icon flashes during the last seconds (0–60 s, 0 = Off).
  Default: 15 s.
- **Warn in chat** – reports in chat that a buff is about to expire. Default: on.
  - **Only buffs you can cast** – warn only for spells you can cast yourself. Default: off.
  - **Play sound** – a sound with every warning. Default: on.
  - **Warn for duration 2:00 – 10:00** – time before expiry for buffs lasting 2 to 10 minutes
    (0–60 s, 0 = Off). Default: 15 s.
  - **Warn for duration 10:01 – 30:00** – for buffs lasting 10 to 30 minutes (0–180 s).
    Default: 1 min.
  - **Warn for duration from 30:01** – for longer buffs (0–300 s). Default: 3 min.

Warnings cover the buffs of every unit shown in a window and your weapon enchants. Buffs
shorter than 2 minutes are never warned about. Each application warns only once.

### Window

**Window**

- **Edit window** – the window whose settings these pages show (**Window 1**, **Window 2** …).
- **New Window** (**Add**) – new window with default settings.
- **Copy window** (**Clone**) – new window with the settings of the selected window.
- **Delete window** (**Delete …**) – deletes the selected window together with its settings after
  a confirmation. If it was the last one, a new window is created.
- **Reset position** (**Reset**) – moves the window to the center of the screen.
- **Find window** (**Move into visible area**) – moves the window only as far as needed to be
  completely visible; the rest of its position is kept.

**General**

- **Disable window** – the window is not shown; its settings are kept. Default: off.
- **Disable icon tooltips** – no tooltips on the icons. Default: off.
- **Lock Frame** – prevents moving the window. Default: off.
- **Keep on screen** – the window cannot be moved off the screen. Default: on.

**Unit**

- **Show buffs for** – **Player**, **Vehicle**, **Pet**, **Target** or **Focus**. Default:
  **Player**.
- **Show vehicle buffs when in a vehicle** – (only with **Player**) while you are in a vehicle,
  the window shows the vehicle's auras. Default: on.

**Visibility**

- **Show** – **Always Show**, **Basic conditions** or **Custom condition**. Default: **Always
  Show**.
- With **Basic conditions**: **Hide in combat**, **Hide out of combat**, **Hide in vehicle**,
  **Hide out of vehicle** (all off by default).
- With **Custom condition**:
  - **Custom condition** (**Edit …**) – macro condition with the actions `show`/`hide`, e.g.
    `[vehicleui] hide; [combat] hide; show`. Line breaks count as `;`. Empty = always show.
  - **Test condition** (**Test**) – shows in chat what the saved condition currently does.

### Appearance

**Background**

- **Show Background** – background behind the window. Default: on.
- **Custom color for this window** – use its own color instead of **Window background** from the
  main page. Default: off.
  - **Background Color** and **Background opacity** – default: black, 25 %.

**Border**

- **Display Border** – frame around the window. Default: off.
- **Left border**, **Right border**, **Top border**, **Bottom border** – extra space between icons
  and the window edge (0–100). Default: 0.

**Layout**

- **Direction** – in which direction the entries line up and wrap: *Top to bottom, wrap right* /
  *wrap left*, *Bottom to top, wrap right* / *wrap left*, *Left to right, wrap down* / *wrap up*,
  *Right to left, wrap down* / *wrap up*. Top/bottom: entries in columns; left/right: entries in
  rows. Default: **Left to right, wrap down** (with 1 per row this is a single column growing
  downwards).
- **Buffs per row or column** – 1–50. Default: 1.
- **Number of rows or columns** – 0–50, **0 = auto-expand**; with a limit, surplus entries are not
  shown. Default: auto.
- **Buff spacing** – space between entries (0–200). Default: 0.
- **Row or column spacing** – 0–200. Default: 0.

**Font**

- **Font Size** – **Normal**, **Smaller** or **Larger**. Default: **Normal**.

### Buttons

- **Style** – **Style 1 (icon and bar)** or **Style 2 (icon only)**. Default: style 1. The
  settings of the other style are greyed out.

**Style 1 (icon and bar)**

- **Icon Size** – 15–45. Default: 20.
- **Icon position** – **Default** (on the side the window grows from), **Left** or **Right**.
- **Color code the border of debuff icons** – border (and a symbol) in the debuff type color.
  Default: off.
- **Default icon border** – shows the whole icon including its own border instead of trimming its
  edges. Default: off.
- **Bar width** – 0–400 (0 = no bar). Default: 245.
- **Color the bar background** – colored bar behind name and time (colors from the main page).
  Default: on.
- **Color code debuff bars** – debuff bars in the debuff type color. Default: off.
- **Show Name** – Default: on.
- **Color code debuff names** – debuff names in the debuff type color. Default: off.
- **Justify name (beside time)** / **Justify name (when alone)** – **Default**, **Left**,
  **Right**, **Center**.
- **Time remaining as text** – Default: on.
- **Time format** – *1 hour / 22 minutes*, *1 hour / 22 min*, *1h / 22m*, *1h 11m / 22m 22s*,
  *1:11h / 22:22*. Default: *1 hour / 22 minutes*.
- **Show days if >24 hours** – Default: on.
- **Time remaining location** – **Default**, **Left of the name**, **Right of the name**, **Above
  the name**, **Below the name**.
- **Justify time (when alone)** – **Default**, **Left**, **Right**, **Center**.
- **Time remaining as bar** – the bar shrinks with the time remaining. Default: on.
- **Bar background** – darker background behind the shrinking bar. Default: on.
- **Text offset (left side)** / **Text offset (right side)** – 0–50. Default: 0.

Debuff colors: purple = curse, brown = disease, blue = magic, green = poison, red = others
(e.g. physical).

**Style 2 (icon only)**

- **Icon Size** – 15–45. Default: 20.
- **Color code the border of debuff icons**, **Default icon border** – as in style 1. Default: off.
- **Time remaining as text** – Default: on.
- **Time format**, **Show days if >24 hours** – as in style 1.
- **Time remaining location** – **Left**, **Right**, **Above**, **Below** or **Center** (on the
  icon). Default: **Below**.
- **Offset from icon** – 0–50, no effect with **Center**. Default: 0.

### Grouping

**Grouping (before sorting)**

- **Grouping order** – order of precedence for grouping by filter (the groups below), own and
  non-expiring buffs, e.g. *Filters > Own > Non-expiring*. Default: *Filters > Own > Non-expiring*.
- **Buffs that you cast** – **Before other players**, **After other players** or **With other
  players**. Default: **With other players**.
- **Non-expiring buffs** – **Before other buffs**, **After other buffs**, **With other buffs**,
  **Hide** or **Shown only**. Default: **With other buffs**.
- **Group 1** … **Group 5** – which auras the window shows and in which order: **None**,
  **Debuffs**, **Cancelable buffs**, **Uncancelable buffs**, **All buffs**, **Weapon enchants**.
  Default: Debuffs, Weapon enchants, Cancelable buffs, Uncancelable buffs, None. Each type can be
  used only once; choosing it again sets the other group to **None**. An aura that fits several
  groups appears only in the first one.

**Sorting (after grouping)**

- **Sort By** – **Name**, **Time Left** or **Order** (order of the game). Default: **Name**.
- **Reverse order** – Default: off.

## Slash commands

| Command | Effect |
|---|---|
| `/qnbuff` | Opens the options |
| `/qnbuffmod` | Same as `/qnbuff` |
| `/qnaura` | Same as `/qnbuff` |

## Tips & notes

- **Recast Buffs**: assign a key under *Key Bindings → AddOns → qnBuffMod*. When a buff of yours
  that you can cast is warned about, the chat message names the key; pressing it recasts the most
  recently warned buff, otherwise your own buff with the shortest time remaining. Use it out of
  combat.
- In combat the client withholds aura data. The windows then show the last known state and
  update after combat; a chat message tells you once. Affected auras may appear without time
  remaining or with a question mark.
- Adding and deleting windows is not possible in combat. Visibility changes made in combat apply
  after combat.
- Right-click cancels only your own buffs, only in a window for the player and only out of
  combat.
- Weapon enchants appear only in windows for the player.
- Hovering an icon shows the aura tooltip with the caster in class color and the spell ID.
- After a profile switch (different Edit Mode layout) the windows of that profile appear.

[← Overview](README.md)
