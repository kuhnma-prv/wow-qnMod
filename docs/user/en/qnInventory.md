# qnInventory – bags, bank, mail and gold of all your characters

qnInventory remembers the bags, bank, mailbox and gold of every character you log in with. Item
tooltips show how many of an item each character owns, and you can open the bags, bank and mailbox
of any of your characters anywhere – in windows that look like Blizzard's, with a character
selection on top. With Titan Panel it adds two plugins for used bank/bag slots and for gold.

## Features

- Records bags, bank (character bank tabs), mailbox and gold of every character, plus the account
  bank (gold at any time, content when you visit a banker).
- Item tooltip: count per character as **Bags/Bank/Mail**, the account bank and a total.
- Covers your realm and its connected realms (shown as "Name-Realm").
- Views of the bags, bank and mailbox of any stored character, also away from the bank and
  mailbox.
- Bar above Blizzard's combined bags, bank window and mailbox: character selection and buttons
  for the other two views.
- Mail you send to your own characters is credited to their mailbox right away.
- `/qninv gold`: gold of all characters on the realm in the chat.
- Titan Panel (optional): plugins **qnInventory Bank/Bags** and **qnInventory Gold**.
- Delete the stored data of characters you no longer play.

### Item tooltip

Below the item tooltip (also for item links in the chat) qnInventory adds:

- a header line **Character – Bags/Bank/Mail**,
- one line per character that owns the item, e.g. `3/10/0`; your current character is marked
  **(me)**,
- **Account Bank** with its count,
- **Total** if more than one line is shown.

`?` means the bank or the mailbox of this character has never been opened. `+` after the mail
count means the mailbox is only partially known (more than 50 letters, or only mails you sent to a
character whose mailbox was never opened). Items attached with C.O.D. are not counted.

### Views

A bar hangs above Blizzard's combined bags, the bank window and the mailbox, and above
qnInventory's own windows. It holds a character dropdown and buttons for the other two views
(**Bags**, **Bank**, **Mail**).

- **Bags** – your own bags open in Blizzard's window; other characters' bags open in a replica of
  the **Combined Backpack** with their gold at the bottom. Reagent bag and keyring are not shown
  (Blizzard's combined backpack does not show them either).
- **Bank** – the last stored state of the bank of any character, also of the logged-in one away
  from the bank: all tabs, page tabs on the right, bag slots and the price of the next tab.
  Sorting and purchasing are disabled here (only possible at a banker).
- **Mail** – the stored **Inbox**, 7 letters per page, remaining time, C.O.D. marker. Clicking a
  letter opens a window with sender, subject, attachments and gold or C.O.D. amount. The letter
  text is not shown (reading it would mark the letter as read).

Bags and bank views have a search box that dims items that do not match. Item tooltips work as
usual, Shift/Ctrl-click inserts a chat link or opens the dressing room. The windows can be moved
by dragging and closed with Escape. A notice in the window tells you if nothing has been recorded
yet for the character.

### Titan Panel plugins

Only available if Titan Panel is installed. Both plugins are in Titan's "Information" category
and support Titan's usual options (icon, label text, colored text, right side).

**qnInventory Bank/Bags**

- Button: **Bank:** used/total slots and **Bags:** used/total slots of the logged-in character
  (`?` = not recorded yet). With *Show Colored Text* the numbers turn white, yellow, orange or red
  as the slots fill up (below 50 %, 75 %, 90 %, above). Bags count the backpack, bags 1–4 and the
  reagent bag, not the keyring.
- Tooltip: **Bank and Bags**, one block per faction (**Used slots on** <faction>) with every
  character and a total, then the account bank.
- Left-click: bags view, Shift-left-click: bank view.
- Right-click menu: **Bags**, **Bank**, **Options**.

**qnInventory Gold**

- Button: **Gold:** gold of all characters including the account bank, or only of the current
  character (right-click menu: **Gold of all characters** / **Display Player Gold**; default: all
  characters).
- Tooltip like TitanGold: one block per faction with each character and **Total Gold**, then the
  account bank and the grand total, and the session statistics (starting gold, earned or lost,
  per hour).
- Right-click menu: **Reset Current Session**, **Options**.

## Getting started

Log in once with each character. The bank and mailbox of a character are known after you have
opened them with that character once.

Options: *Options → AddOns → qnInventory*, or the **Options** entry in the right-click menu of
one of the Titan plugins. There is no slash command to open the options: `/qninv` alone shows the
gold list in the chat.

## Options

All options of qnInventory are **account-wide**. They do not change with the Edit Mode layout
(profile).

### qnInventory

**Factions**

- **Tooltips: Alliance and Horde** – the tooltips of the Titan plugins (bank/bags and gold) show
  the characters of both factions. Off: only those of the logged-in character's faction.
  Default: off.
- **Bags, bank and mail: include the other faction** – the character selection of the bags, bank
  and mail views also lists the characters of the other faction. Off: only those of the
  logged-in character's faction. Default: off.

A character's faction becomes known when you log in with it once with the current version; until
then it is always shown. The item tooltip always lists all characters.

**Delete Character**

- **Character** – the character whose stored data (bags, bank, mail, gold) should be deleted.
  Lists all stored characters of both factions (your realm and connected realms) except the
  logged-in one. Default: **None**.
- **Delete selected character** (button **Delete**) – deletes the stored data of the selected
  character after a confirmation.

## Slash commands

| Command | Effect |
|---|---|
| `/qninv` or `/qninv gold` | Lists the gold of all characters on this realm (with gold in the mailbox) and the total |
| `/qninv bags [name]` | Opens/closes the bags view (of the named character on this realm, otherwise of the last selected one) |
| `/qninv bank [name]` | Opens/closes the bank view |
| `/qninv mail [name]` | Opens/closes the mail view |
| `/qninv delete <name>` | Deletes the stored data of a character on this realm (not the logged-in one) |

`/qninventory` works the same as `/qninv`. Names are not case-sensitive.

## Tips & notes

- The bank is only readable while the bank window is open, the mailbox only while the mailbox is
  open. Otherwise the last stored state is shown.
- The account bank content is recorded only at a banker and only if your character may view it.
- The bar of the bags view sits above Blizzard's **combined** bags.
- Mail sent to your own characters counts once it was sent successfully. Items in C.O.D. mail
  only count after payment.
- `/qninv gold` and `/qninv delete` only cover the current realm; the options page and the views
  also include connected realms.
- Gold in the mailbox appears in `/qninv gold`, not in the Titan gold plugin.
- With qnViewPort, the item tooltips of the views stay on the monitor of the window.
- Titan Panel is optional; without it there are simply no plugins.

[← Overview](README.md)
