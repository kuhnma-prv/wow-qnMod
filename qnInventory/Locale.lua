-- qnInventory: englische Texte (alle Clients außer deDE). Schlüssel = deutscher Text im Code.
-- Blizzard-Texte im Code: TOTAL (Gesamt), MAIL_LABEL (Post), CHARACTER (Charakter),
-- HUD_EDIT_MODE_BAGS_LABEL (Taschen), BANK, INBOX (Posteingang), COMBINED_BAG_TITLE, PAGE_NUMBER,
-- BAGSLOTTEXT_COLON, BANK_BAG, BANK_BAG_PURCHASE, FROM, MAIL_SUBJECT_LABEL, COD_AMOUNT,
-- ENCLOSED_MONEY, MAIL_MULTIPLE_ITEMS, PREV, NEXT, DAYS_ABBR, UNKNOWN, NONE, DELETE, OPTIONS, ALL,
-- FACTION_ALLIANCE, FACTION_HORDE, NARRATION_DELETE_CHARACTER_BUTTON (Charakter löschen),
-- ACCOUNT_BANK_PANEL_TITLE (Accountbank).
-- Titan.lua nimmt die Texte von TitanGold/TitanBag aus Titans Lokalisierung (TITAN_GOLD_*, TITAN_BAG_*).

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if qnCore.GERMAN then return end

-- Core.lua
L["Gold auf %s:"] = "Gold on %s:"
L["Aufruf: /qninv delete <Name>"] = "Usage: /qninv delete <name>"
L["Der eingeloggte Charakter kann nicht gelöscht werden."] = "The logged-in character cannot be deleted."
L["%s gelöscht."] = "%s deleted."
L["%s ist auf %s nicht gespeichert."] = "%s is not stored on %s."
L["Befehle: /qninv gold · /qninv bags|bank|mail [Name] · /qninv delete <Name>"] = "Commands: /qninv gold · /qninv bags|bank|mail [name] · /qninv delete <name>"

-- Tooltip.lua
L["(ich)"] = "(me)"
L["Taschen/Bank/Post"] = "Bags/Bank/Mail"

-- ViewBags.lua, ViewBank.lua, ViewMail.lua
L["Die Taschen dieses Charakters sind noch nicht erfasst. Einmal mit ihm einloggen genügt."] = "This character's bags have not been recorded yet. Logging in with it once is enough."
L["Die Bank dieses Charakters ist noch nicht erfasst. Einmal mit ihm die Bank öffnen genügt."] = "This character's bank has not been recorded yet. Opening the bank with it once is enough."
L["Sortieren geht nur beim Bankier."] = "Sorting is only possible at a banker."
L["Kaufen geht nur beim Bankier."] = "Purchasing is only possible at a banker."
L["Der Briefkasten dieses Charakters ist noch nicht erfasst. Einmal mit ihm den Briefkasten öffnen genügt."] = "This character's mailbox has not been recorded yet. Opening the mailbox with it once is enough."

-- Options.lua
L["Fraktionen"] = "Factions"
L["Tooltips: Allianz und Horde"] = "Tooltips: Alliance and Horde"
L["Die Tooltips der Titan-Plugins (Bank/Taschen und Gold) zeigen die Charaktere beider Fraktionen. Aus: nur die der Fraktion des eingeloggten Charakters. Die Fraktion eines Charakters ist bekannt, sobald er einmal mit dieser Version eingeloggt war; bis dahin erscheint er immer."] = "The tooltips of the Titan plugins (bank/bags and gold) show the characters of both factions. Off: only those of the logged-in character's faction. A character's faction is known once it has logged in with this version; until then it is always shown."
L["Taschen, Bank und Post: auch die andere Fraktion"] = "Bags, bank and mail: include the other faction"
L["Die Charakterauswahl der Ansichten Taschen, Bank und Post enthält auch die Charaktere der anderen Fraktion. Aus: nur die der Fraktion des eingeloggten Charakters."] = "The character selection of the bags, bank and mail views also contains the characters of the other faction. Off: only those of the logged-in character's faction."
L["Charakter, dessen gespeicherte Daten (Taschen, Bank, Post, Gold) gelöscht werden sollen. Der eingeloggte Charakter lässt sich nicht löschen."] = "Character whose stored data (bags, bank, mail, gold) should be deleted. The logged-in character cannot be deleted."
L["Gespeicherte Daten von %s löschen?"] = "Delete the stored data of %s?"
L["Ausgewählten Charakter löschen"] = "Delete selected character"
L["Löscht nach einer Rückfrage die gespeicherten Daten des oben gewählten Charakters."] = "Deletes the stored data of the character selected above after confirmation."

-- Titan.lua
L["Bank: "] = "Bank: "
L["Bank und Taschen"] = "Bank and Bags"
L["Belegte Plätze auf"] = "Used slots on"
L["Linksklick: Taschen, Umschalt-Linksklick: Bank"] = "Left-click: bags, Shift-left-click: bank"
L["Gold aller Charaktere"] = "Gold of all characters"
L["qnInventory Bank/Taschen"] = "qnInventory Bank/Bags"
L["qnInventory Gold"] = "qnInventory Gold"
L["Belegte Plätze in Bank und Taschen; im Tooltip alle Charaktere nach Fraktion."] = "Used bank and bag slots; the tooltip lists all characters by faction."
L["Gold aller Charaktere wie TitanGold, aus den Daten von qnInventory."] = "Gold of all characters like TitanGold, from the data of qnInventory."
