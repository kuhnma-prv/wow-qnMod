-- qnInventory: englische Texte (alle Clients außer deDE). Schlüssel = deutscher Text im Code.
-- Blizzard-Texte im Code: TOTAL (Gesamt), MAIL_LABEL (Post), CHARACTER (Charakter),
-- HUD_EDIT_MODE_BAGS_LABEL (Taschen), BANK, INBOX (Posteingang), COMBINED_BAG_TITLE, PAGE_NUMBER,
-- BAGSLOTTEXT_COLON, BANK_BAG, BANK_BAG_PURCHASE, FROM, MAIL_SUBJECT_LABEL, COD_AMOUNT,
-- ENCLOSED_MONEY, MAIL_MULTIPLE_ITEMS, PREV, NEXT, DAYS_ABBR, UNKNOWN.

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
