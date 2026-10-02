# qnLoadout – ready-made macro and numpad sets per class

qnLoadout loads a prepared set for your class with one click: it creates or updates the set's macros (only macros whose name starts with "qn") and puts spells and macros onto the keys of the qnNumKeyPad bar, including its Ctrl set. It can also export the current numpad assignment and qn macros of your character as a new set. Spell and item names in the sets are English; qnLoadout translates them into your client language when loading.

## Features

- Sets per class, selectable on one options page, with a short summary (description, number of macros and numpad keys)
- Loading with confirmation: creates or changes qn macros, assigns or clears the numpad keys listed in the set (normal actions and Ctrl set)
- Safe by design: other macros are never touched, nothing is deleted, numpad keys not listed in the set stay unchanged
- Existing qn macros are changed in place, so they keep their places on your action bars
- Works in German and English clients: spell and item names are translated automatically
- Detailed report in chat: created, changed, set, cleared and skipped entries with the reason
- Export of the current state of your character as a set (JSON text for copying)
- Included sets (all made for the Logitech G502 setup of qnNumKeyPad): Druid, Hunter, Mage, Priest, Warrior

## Getting started

qnLoadout requires qnCore and qnNumKeyPad. Open *Options → AddOns → qnLoadout*, or type `/qnloadout`. There is one page, **qnLoadout**.

1. Pick a set in **Set:** (only sets of your current class are listed).
2. Read the summary below the dropdown.
3. Click **Load set** and confirm with **Load**.

Storage: qnLoadout has no profiles. The set chosen last is remembered per class, and exports are stored account-wide. The loaded macros and action slots are stored by WoW (character macros and action slots per character, account macros for all characters).

## Options

### qnLoadout

**Loading**

- Info line "Sets for <class>:" – or a note if there is no set for your class.
- **Set:** – Choice among the sets of your class. Default: the set chosen last for this class, otherwise the first one.
- Summary – The set's description (if any) and "<n> macros, <n> numpad keys".
- **Load set** – Asks for confirmation ("qn macros are created or changed and the numpad keys of the set are assigned for this character"), then loads the set:
  - **Macros:** a qn macro of the same name and kind (account or character) is changed; otherwise it is created. Skipped if the name does not start with "qn", if a macro of that name exists as the other kind, or if there is no free macro place.
  - **Numpad keys:** every key listed in the set gets its spell or macro, or is cleared. Skipped if the key is not on the bar with the current keyboard layout, if the Ctrl set is switched off in qnNumKeyPad, for keys 13 and higher in the Ctrl set, or if the spell is not known by your character or the macro is not found.
  - The result appears in chat, every skipped entry on its own line.

**Export**

Saves the numpad assignments of this character (normal actions and the switched-on Ctrl set) and its qn macros as a set: spells by name or ID, macros by name. The exported macros are all qn character macros and the qn account macros used on the bar. Items, mounts and other content on the bar are left out.

- **Name:** – Name of the export. Default: "<class> <character name>".
- **Export** – Creates the export (also with Enter in the name field). The set appears as JSON text in a field below, already selected for copying (Ctrl+C). The chat lists spells that were exported by ID, item names that could not be translated and how many slots with other content were left out.

## Slash commands

| Command | Effect |
|---|---|
| `/qnloadout` (also `config`, `options`) | Open the options |
| `/qnloadout list` | List the sets for your class in chat |
| any other text | Show the list of commands |

## Tips & notes

- **Not in combat:** sets cannot be loaded in combat. Loading also refuses while something is on the cursor – place or drop it first.
- **Account macros:** if a set contains account macros, loading changes them for all your characters.
- **Placeholders:** some macros of the included sets contain placeholders such as `<your healing potion>`. Edit these macros afterwards in the macro window and enter your own item.
- **Spells you have not learned yet** are skipped and reported in chat; load the set again later (already set keys and macros are simply updated).
- **Ctrl set:** entries for Ctrl + key are only loaded when the Ctrl set is switched on in qnNumKeyPad (page *Action slots*).
- **Keyboard layout:** the key names in a set refer to numpad keys; if a key is not on the bar with your current qnNumKeyPad layout, it is skipped.
- **Item names** are loaded in the background after login; if a name is still missing, it stays English in the macro and the chat says so.
- Set names and descriptions are shown as they are written in the set (English).
- Advanced: exports are stored in the saved variables; after logging out or `/reload`, the developer tool `tools\Convert-QnLoadout.ps1 -Import` from the repository turns them into set files, which then appear in the game after a conversion and `/reload`.

[← Overview](README.md)
