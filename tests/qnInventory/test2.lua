-- Szenario 2: qnInventory – Gutschrift erst bei MAIL_SEND_SUCCESS (auch nach der Nachfrage der
-- sicheren Überweisung), Verwerfen bei MAIL_FAILED/SECURE_TRANSFER_CANCEL, Nachnahme zählt nicht
-- (Versand und Briefkasten), Post an Charaktere verbundener Realms samt Tooltip, gebündelte
-- Bankplätze, secret-Klasse.
local tooltipCall
TooltipDataProcessor.AddTooltipPostCall = function(_, fn) tooltipCall = fn end
local CONTENT = { [6] = { [1] = { itemID = 100, stackCount = 3 } } }
local bankReads = 0
C_Container.GetContainerItemInfo = function(bag, slot)
	if bag == 6 then bankReads = bankReads + 1 end
	return CONTENT[bag] and CONTENT[bag][slot]
end
C_Container.GetContainerNumSlots = function(bag) return bag == 6 and 4 or 0 end
C_Bank.FetchPurchasedBankTabData = function() return { { ID = 6 } } end
QN_CONNECTED_REALMS = { "Realm", "NachbarRealm" }

LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")
qnInventoryDB = { realms = {
	Realm = { Zwilling = { class = "MAGE" } },
	["Nachbar Realm"] = { Fernling = { class = "PRIEST", bags = { [100] = 7 } } },
	["Fremder Realm"] = { Unverbunden = { class = "ROGUE", bags = { [100] = 1 } } },
} }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local realms = qnInventoryDB.realms
local twin = realms.Realm.Zwilling

---------------------------------------------------------------------------
-- Befund 9: Gold-Post mit Nachfrage der sicheren Überweisung
---------------------------------------------------------------------------
local cod = 0
GetSendMailCOD = function() return cod end
GetSendMailItem = function(i) if i == 1 then return "x", 200, nil, 4 end end
GetSendMailMoney = function() return 500 end

SendMail("Zwilling", "Gold", "")
Check(twin.mail == nil and twin.mailMoney == nil, "SendMail allein: noch keine Gutschrift")
-- Nachfrage (SECURE_TRANSFER_CONFIRM_SEND_MAIL) läuft, dann Abbruch durch den Server
FireEvent("SECURE_TRANSFER_CANCEL")
FireEvent("MAIL_SEND_SUCCESS")
Check(twin.mail == nil, "SECURE_TRANSFER_CANCEL: verworfen")

SendMail("Zwilling", "Gold", "")
FireEvent("MAIL_FAILED")
FireEvent("MAIL_SEND_SUCCESS")
Check(twin.mail == nil, "MAIL_FAILED: verworfen")

-- bestätigt (C_SecureTransfer.SendMail): Gutschrift erst mit MAIL_SEND_SUCCESS
SendMail("Zwilling", "Gold", "")
FireEvent("MAIL_SEND_SUCCESS")
Check(twin.mail and twin.mail[200] == 4 and twin.mailMoney == 500, "MAIL_SEND_SUCCESS: gutgeschrieben")
FireEvent("MAIL_SEND_SUCCESS")
Check(twin.mail[200] == 4 and twin.mailMoney == 500, "zweites MAIL_SEND_SUCCESS ohne Versand: nichts doppelt")

---------------------------------------------------------------------------
-- Befund 10: Nachnahme
---------------------------------------------------------------------------
cod = 1000
GetSendMailMoney = function() return 0 end
SendMail("Zwilling", "Nachnahme", "")
FireEvent("MAIL_SEND_SUCCESS")
Check(twin.mail[200] == 4, "Versand per Nachnahme: Anhänge nicht gutgeschrieben")
cod = 0

-- eigener Briefkasten: Brief 1 normal, Brief 2 per Nachnahme
GetInboxNumItems = function() return 2, 2 end
GetInboxHeaderInfo = function(i)
	if i == 1 then return nil, nil, nil, nil, 70, 0, nil, 1 end
	return nil, nil, nil, nil, 0, 2500, nil, 1
end
GetInboxItem = function(i, a)
	if a ~= 1 then return nil end
	if i == 1 then return "y", 300, nil, 2, nil, nil, false end
	return "z", 400, nil, 5, nil, nil, false
end
FireEvent("MAIL_SHOW")
FireEvent("MAIL_INBOX_UPDATE")
local me = realms.Realm.Tester
Check(me.mail[300] == 2 and me.mail[400] == nil and me.mailMoney == 70, "Briefkasten: Nachnahme zählt nicht")
FireEvent("MAIL_CLOSED")

---------------------------------------------------------------------------
-- Befund 11: verbundene Realms
---------------------------------------------------------------------------
GetSendMailMoney = function() return 900 end
local far = realms["Nachbar Realm"].Fernling
SendMail("fernling-NachbarRealm", "x", "")
FireEvent("MAIL_SEND_SUCCESS")
Check(far.mail and far.mail[200] == 4 and far.mailMoney == 900 and far.mailIncomplete, "verbundener Realm: gutgeschrieben")
SendMail("Unverbunden-FremderRealm", "x", "")
FireEvent("MAIL_SEND_SUCCESS")
Check(realms["Fremder Realm"].Unverbunden.mail == nil, "nicht verbundener Realm: ignoriert")
SendMail("Tester-Realm", "x", "")
FireEvent("MAIL_SEND_SUCCESS")
Check(me.mail[200] == nil, "an sich selbst: ignoriert")

local lines = {}
GameTooltip.AddLine = function(_, t) lines[#lines + 1] = t end
GameTooltip.AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. "|" .. tostring(b) end
tooltipCall(GameTooltip, { id = 100 })
local text = table.concat(lines, ";")
Check(text:find("Fernling-Nachbar Realm", 1, true) and text:find("7/?/0", 1, true), "Tooltip: verbundener Realm mit Name-Realm: " .. text)
Check(not text:find("Unverbunden", 1, true), "Tooltip: nicht verbundener Realm fehlt")

---------------------------------------------------------------------------
-- Befund 8: Bankplätze gebündelt
---------------------------------------------------------------------------
FireEvent("BANKFRAME_OPENED")
bankReads = 0
for _ = 1, 4 do FireEvent("PLAYERBANKSLOTS_CHANGED", 1) end
Check(bankReads == 0, "PLAYERBANKSLOTS_CHANGED: noch nicht gezählt")
RunTimers()
Check(bankReads == 4 and me.bank[100] == 3, "vier Plätze: Bank einmal gezählt (" .. bankReads .. " Lesezugriffe)")
FireEvent("BANKFRAME_CLOSED")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
