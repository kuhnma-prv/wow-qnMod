-- qnInventory: German texts (deDE clients only). Key = English text in the code.
-- Blizzard-Texte im Code: TOTAL (Gesamt), MAIL_LABEL (Post), CHARACTER (Charakter),
-- HUD_EDIT_MODE_BAGS_LABEL (Taschen), BANK, INBOX (Posteingang), COMBINED_BAG_TITLE, PAGE_NUMBER,
-- BAGSLOTTEXT_COLON, BANK_BAG, BANK_BAG_PURCHASE, FROM, MAIL_SUBJECT_LABEL, COD_AMOUNT,
-- ENCLOSED_MONEY, MAIL_MULTIPLE_ITEMS, PREV, NEXT, DAYS_ABBR, UNKNOWN, NONE, DELETE, OPTIONS, ALL,
-- FACTION_ALLIANCE, FACTION_HORDE, NARRATION_DELETE_CHARACTER_BUTTON (Charakter löschen),
-- ACCOUNT_BANK_PANEL_TITLE (Accountbank).
-- Titan.lua nimmt die Texte von TitanGold/TitanBag aus Titans Lokalisierung (TITAN_GOLD_*, TITAN_BAG_*).

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if not qnCore.GERMAN then return end

-- Core.lua
L["Gold on %s:"] = "Gold auf %s:"
L["Usage: /qninv delete <name>"] = "Aufruf: /qninv delete <Name>"
L["The logged-in character cannot be deleted."] = "Der eingeloggte Charakter kann nicht gelöscht werden."
L["%s deleted."] = "%s gelöscht."
L["%s is not stored on %s."] = "%s ist auf %s nicht gespeichert."
L["Commands: /qninv gold · /qninv bags|bank|mail [name] · /qninv delete <name>"] = "Befehle: /qninv gold · /qninv bags|bank|mail [Name] · /qninv delete <Name>"

-- Tooltip.lua
L["(me)"] = "(ich)"
L["Bags/Bank/Mail"] = "Taschen/Bank/Post"

-- ViewBags.lua, ViewBank.lua, ViewMail.lua
L["This character's bags have not been recorded yet. Logging in with it once is enough."] = "Die Taschen dieses Charakters sind noch nicht erfasst. Einmal mit ihm einloggen genügt."
L["This character's bank has not been recorded yet. Opening the bank with it once is enough."] = "Die Bank dieses Charakters ist noch nicht erfasst. Einmal mit ihm die Bank öffnen genügt."
L["Sorting is only possible at a banker."] = "Sortieren geht nur beim Bankier."
L["Purchasing is only possible at a banker."] = "Kaufen geht nur beim Bankier."
L["This character's mailbox has not been recorded yet. Opening the mailbox with it once is enough."] = "Der Briefkasten dieses Charakters ist noch nicht erfasst. Einmal mit ihm den Briefkasten öffnen genügt."

-- Options.lua
L["Factions"] = "Fraktionen"
L["Tooltips: Alliance and Horde"] = "Tooltips: Allianz und Horde"
L["The tooltips of the Titan plugins (bank/bags and gold) show the characters of both factions. Off: only those of the logged-in character's faction. A character's faction is known once it has logged in with this version; until then it is always shown."] = "Die Tooltips der Titan-Plugins (Bank/Taschen und Gold) zeigen die Charaktere beider Fraktionen. Aus: nur die der Fraktion des eingeloggten Charakters. Die Fraktion eines Charakters ist bekannt, sobald er einmal mit dieser Version eingeloggt war; bis dahin erscheint er immer."
L["Bags, bank and mail: include the other faction"] = "Taschen, Bank und Post: auch die andere Fraktion"
L["The character selection of the bags, bank and mail views also contains the characters of the other faction. Off: only those of the logged-in character's faction."] = "Die Charakterauswahl der Ansichten Taschen, Bank und Post enthält auch die Charaktere der anderen Fraktion. Aus: nur die der Fraktion des eingeloggten Charakters."
L["Character whose stored data (bags, bank, mail, gold) should be deleted. The logged-in character cannot be deleted."] = "Charakter, dessen gespeicherte Daten (Taschen, Bank, Post, Gold) gelöscht werden sollen. Der eingeloggte Charakter lässt sich nicht löschen."
L["Delete the stored data of %s?"] = "Gespeicherte Daten von %s löschen?"
L["Delete selected character"] = "Ausgewählten Charakter löschen"
L["Deletes the stored data of the character selected above after confirmation."] = "Löscht nach einer Rückfrage die gespeicherten Daten des oben gewählten Charakters."

-- Titan.lua
L["Bank: "] = "Bank: "
L["Bank and Bags"] = "Bank und Taschen"
L["Used slots on"] = "Belegte Plätze auf"
L["Left-click: bags, Shift-left-click: bank"] = "Linksklick: Taschen, Umschalt-Linksklick: Bank"
L["Gold of all characters"] = "Gold aller Charaktere"
L["qnInventory Bank/Bags"] = "qnInventory Bank/Taschen"
L["qnInventory Gold"] = "qnInventory Gold"
L["Used bank and bag slots; the tooltip lists all characters by faction."] = "Belegte Plätze in Bank und Taschen; im Tooltip alle Charaktere nach Fraktion."
L["Gold of all characters like TitanGold, from the data of qnInventory."] = "Gold aller Charaktere wie TitanGold, aus den Daten von qnInventory."
