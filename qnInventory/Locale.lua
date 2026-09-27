-- qnInventory: englische Texte (alle Clients außer deDE). Schlüssel = deutscher Text im Code.
-- Blizzard-Texte im Code: TOTAL (Gesamt), MAIL_LABEL (Post), CHARACTER (Charakter).

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if qnCore.GERMAN then return end

-- Core.lua
L["Gold auf %s:"] = "Gold on %s:"
L["Aufruf: /qninv delete <Name>"] = "Usage: /qninv delete <name>"
L["Der eingeloggte Charakter kann nicht gelöscht werden."] = "The logged-in character cannot be deleted."
L["%s gelöscht."] = "%s deleted."
L["%s ist auf %s nicht gespeichert."] = "%s is not stored on %s."
L["Befehle: /qninv gold · /qninv delete <Name>"] = "Commands: /qninv gold · /qninv delete <name>"

-- Tooltip.lua
L["(ich)"] = "(me)"
L["Taschen/Bank/Post"] = "Bags/Bank/Mail"
