# qnNumKeyPad – an action bar shaped like your numpad

qnNumKeyPad adds an action bar whose buttons are arranged like the numeric keypad of your keyboard (or the side buttons of a gaming mouse). Every button is bound to its numpad key, so pressing Num 1 … Num 9, Num 0, +, -, * or / triggers the action on the matching button. Optional extras: Enter key, navigation block, stance/form paging, a Ctrl set (a second set of actions while Ctrl is held) and support for a Logitech G502 whose buttons send numpad keys, including a page to put spells and macros directly onto the mouse buttons.

## Features

- Bar in the shape of a numpad with six keyboard layouts: Windows, Microsoft Office, Natural Multimedia, Natural Elite, Macintosh, Razer Naga
- Numpad keys are bound automatically while the bar is enabled and visible; optionally also Shift+key
- Optional Enter key and navigation keys (Insert, Home, Page Up/Down, Delete, End)
- Freely selectable action bar pages for the key groups, with warnings in chat when a page is used twice or also by a visible Blizzard action bar
- Stance switching: keys 1–12 follow the stance/form bar like the main action bar
- Ctrl set: while Ctrl is held, keys 1–12 show and trigger the actions of another page
- Protection against dragging actions out (always or only in combat)
- Appearance: scale, spacing, opacity, background, key labels, font size, icon zoom, flyout direction, click-through
- Visibility: fade out without mouseover, hide in combat/vehicle/stealth/form/with or without pet, or your own macro condition
- Position by dragging or by exact values, centering, reset, keeping the bar in the visible area (multi-monitor aware with qnViewPort)
- Gaming mouse support (Logitech G502): button → numpad key assignment, and a page to put spells and macros onto the mouse buttons

## Getting started

Open *Options → AddOns → qnNumKeyPad*, or type `/qnnkp`. The addon has these pages: **qnNumKeyPad** (general and keyboard), **Appearance**, **Position**, **Visibility**, **Action slots**, **Mouse** and **Mouse Buttons**.

After the first login the bar is unlocked: it shows a green area labelled "qnNumKeyPad". Drag it with the left mouse button, right-click it to open the options, and lock it with `/qnnkp lock` (or **Lock position**) when you are done. Then drag spells, macros or items onto the buttons like on any action bar.

Storage: all settings except the pages **Mouse** and **Mouse Buttons** belong to the active profile. A profile is the active Edit Mode layout (managed by qnCore, page *qnCore → Profiles*); switching the Edit Mode layout switches the settings. The page **Mouse** is account-wide. The actions on the buttons themselves are normal WoW action slots and are stored per character by WoW.

## Options

### qnNumKeyPad

**General**

- **Numpad enabled** – Off hides the bar and removes all numpad key bindings of the addon. Default: on.
- **Lock position** – Prevents accidental moving. When unlocked, the bar shows a green area for dragging (right-click on it opens the options); empty buttons are shown and the bar is always visible. Default: off.
- **Always lock actions** – Actions can only be dragged out of the bar while holding the "Pick Up Action" key (default: Shift). Works in addition to Blizzard's option "Lock Action Bars". Default: off.
- **Lock actions in combat** – The same protection, but only during combat. Default: on.

**Keyboard**

- **Keyboard layout** – Arrangement of the keys: Windows, Microsoft Office, Natural Multimedia, Natural Elite, Macintosh, Razer Naga. Macintosh adds the = and Clear keys of the Mac numpad; Razer Naga shows the 12 side buttons (1–12). Default: Windows.
- **Show Enter key** – Adds the Enter key. Warning: this binds Enter and thereby removes "Open Chat" from it while the numpad is active. Default: off.
- **Show navigation keys** – Adds Insert, Home, Page Up/Down, Delete and End (with Microsoft Office also Tab). Overrides their current bindings (chat scroll, camera). Default: off.
- **Show arrow keys** – Currently not available (the control is disabled): the arrow keys would need page 15, which the Ctrl set uses.
- **Also bind with Shift** – Shift+key triggers the same action. Prevents Shift+numpad from triggering the default bindings (e.g. action bar paging). Default: on.
- **Stance switching** – Keys 1–12 follow the stance/form bar like the main action bar (e.g. Battle Stance, Cat Form, Stealth). Without a stance the bar's own slots apply. Default: off.

### Appearance

**Size and spacing**

- **Scale** – 0.30 to 2.00. Default: 1.00.
- **Horizontal spacing** / **Vertical spacing** – Space between the keys, 0 to 30. Default: 1.
- **Gap to extra block** – Additional gap between the numpad and the navigation keys, 0 to 80. Default: 0.

**Display**

- **Opacity** – Opacity of the whole bar. Default: 100 %.
- **Background opacity** – Black background behind the bar. Default: 0 %.
- **Show empty buttons** – Off hides buttons without an action (they still appear while unlocked or while you drag an action). Default: on.
- **Key labels** – **Short (1, 2, +, …)**, **Key name (Num 1, …)** or **None**. Default: Short.
- **Label font size** – 0 to 24; 0 = **Default**. Default: Default.
- **Hide macro text** – Hides the macro name on the buttons. Default: off.
- **Hide equipped item border** – Hides the green border of equipped items. Default: off.
- **Zoom icons** – Crops the border of the icons. Default: off.
- **Flyout direction** – Direction of flyout menus: **Up**, **Down**, **Left**, **Right**. Default: Up.
- **Click-through** – Buttons ignore the mouse; only the keys trigger them. Default: off.

### Position

- **Lock position** – Same setting as on the main page.
- **Anchor** – Reference point on the screen and on the bar (Top left … Bottom right). The bar stays in place when you change it. Default: Center.
- **X offset** / **Y offset** – Position relative to the anchor, -3000 to 3000. Default: 300 / -100.
- **Center horizontally** / **Center vertically** – Button **Center** centers the bar in that direction.
- **Reset position** – Button **Reset** restores the default position.
- **Keep in visible area automatically** – Moves the bar back onto a monitor after dragging, on login and when the monitor arrangement changes. With qnViewPort and its monitor data, only areas that are really visible on a monitor count. Default: off.
- **Find bar** – Button **Move into visible area** moves the bar onto the nearest visible monitor now (same as `/qnnkp visible`).

### Visibility

**Fading**

- **Fade out without mouseover** – Fades the bar to the opacity below while the mouse is not over it (only while the position is locked). Default: off.
- **Faded opacity** – Default: 25 %. Only available with fading on.
- **Delay** – Time before fading, 0 to 3 s. Default: 0.2 s. Only available with fading on.

**Hiding**

- **Use custom condition** – Replaces all of the following switches with your own macro condition. Default: off.
- **Hide in vehicle / while possessing** – Default: on.
- **Hide in combat**, **Hide out of combat**, **Hide with pet**, **Hide without pet**, **Hide in stealth**, **Hide in stance/form** – Default: off.
- **Custom condition** – Button **Edit …** opens a text field for a macro condition with show/hide. Default: `[combat] show; [mod:alt] show; hide`.

While the bar is hidden, its key bindings are removed as well, so the keys keep their normal function. While the position is unlocked, the bar is always shown.

### Action slots

**Action slots**

The buttons use the slots of normal action bar pages (12 slots each). A Blizzard action bar that uses the same page shows the same actions – hide it in Edit Mode. The chat warns when a page is used by more than one key group or also by a visible Blizzard action bar (page 1 always belongs to the main action bar).

- **Keys 1–12** – Page for the first 12 keys of the layout (with Windows: Num 1–9, Num 0, decimal point and +). Default: Page 13 – Action Bar 6.
- **Keys 13–24** – Page for the remaining keys (with Windows: -, *, /, Enter and the navigation keys). Default: Page 14 – Action Bar 7.
- **Keys 25–28** – Only used for the arrow keys; currently not available (disabled).

Available pages: 1–6 (Action Bar 1 with its second page, Action Bars 2–5), 7–10 (Stance/Form 1–4) and 13–15 (Action Bars 6–8).

**Modifier sets**

- **Ctrl set** – While Ctrl is held, keys 1–12 show and trigger the actions of another page (keyboard and mouse). Keys 13 and higher do not switch. With Ctrl and Alt held together, the normal actions apply. Default: on.
- **Ctrl set: page** – Page of the Ctrl set. Default: Page 15 – Action Bar 8.
- **Alt set** / **Alt set: page** – Currently not available (disabled).

### Mouse

Account-wide: applies to all characters and profiles.

- **Mouse** – Gaming mouse whose buttons send numpad keys: **None** or **Logitech G502**. Default: None.
- **Button assignment – Logitech G502** – One dropdown per mouse button (G3 … G11) with the numpad key that your mouse software (e.g. Logitech G HUB) assigns to this button. G1 (Left click) and G2 (Right click) cannot be changed. Only editable when the G502 is selected. Each dropdown offers **None** and the numpad keys. Defaults: G3 = Num Pad 3, G4 = Num Pad 7, G5 = Num Pad 8, G6 = Num Pad 9, G7 = Num Pad 5, G8 = Num Pad 4, G9 = Num Pad 6, G10 = Num Pad 2, G11 = Num Pad 1.

The assignment here does not configure the mouse – it tells qnNumKeyPad which key each button sends. Set up the mouse itself in its own software.

### Mouse Buttons

Places a spell or macro into the action slot of the numpad key that a mouse button sends; the bar shows it right away. WoW stores these slots per character. Not possible in combat, and not while something is on the cursor.

- **Set:** – **Normal actions** or **Ctrl set** (actions for Ctrl + mouse button; only listed while the Ctrl set is on).
- One row per mouse button, e.g. "G3 (Num Pad 3)", with a dropdown for the kind of action: **Empty** (clears the slot), **Spell** or **Macro**; then **Choose spell …** (active spells from your spellbook) or **Choose macro …** (your account and character macros). **Other** appears if the slot holds something else (item, mount …).
- Notes in a row: no numpad key assigned (page **Mouse**), key not on the bar with the current layout, or keys 13 and higher do not switch with Ctrl.

Without a selected mouse the page asks you to choose one on the page **Mouse**. With stance switching, keys 1–12 use the stance bar's slots while in a stance – this page sets the bar's own slots.

## Slash commands

| Command | Effect |
|---|---|
| `/qnnkp` (also `/qnnumkeypad`, `/numpad`; `config`, `options`) | Open the options |
| `/qnnkp lock` | Lock the position |
| `/qnnkp unlock` | Unlock the position (green drag area) |
| `/qnnkp on` (or `show`) | Enable the numpad |
| `/qnnkp off` (or `hide`) | Disable the numpad (bar hidden, key bindings removed) |
| `/qnnkp reset` | Reset the position |
| `/qnnkp visible` | Move the bar into the visible area |
| any other text | Show the list of commands |

## Tips & notes

- **Combat:** changes of settings during combat are applied after combat (the chat says so). The bar cannot be dragged in combat, the drag area is hidden in combat, and the page **Mouse Buttons** cannot change slots in combat. Visibility, stance switching and the Ctrl set work in combat.
- **Pages:** hide Blizzard action bars that use the same page as the numpad (e.g. Action Bar 6–8 with the defaults) in Edit Mode, otherwise both show the same actions and the chat warns.
- **Key bindings:** the numpad keys (and Shift+, Ctrl+ for keys 1–12) are bound by the addon while the bar is enabled and visible; your own bindings for these keys do not apply during that time.
- **qnLoadout** uses qnNumKeyPad to load whole sets of numpad assignments and qn macros per class.
- **qnViewPort** (optional): with its monitor data, "Keep in visible area automatically" and "Move into visible area" use the monitors that are really visible.
- Profiles follow the Edit Mode layout (qnCore); a new layout starts as a copy of the previously active profile.

[← Overview](README.md)
