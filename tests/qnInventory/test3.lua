-- Szenario 3: qnInventory 0.2.0 – Inhalt je Platz (Taschen, Bankfächer), Briefe einzeln
-- (Briefkasten und Post an eigene Charaktere), Charakterauswahl, Taschen des eingeloggten
-- Charakters über Blizzards Fenster.
local CONTENT = {
	[0] = { [1] = { itemID = 100, stackCount = 5, hyperlink = "|Hitem:100|h[A]|h" } },
	[1] = { [3] = { itemID = 200 } },
	[6] = { [2] = { itemID = 300, stackCount = 2, hyperlink = "|Hitem:300|h[C]|h" } },
	[7] = { [1] = { itemID = 400, stackCount = 1, hyperlink = "|Hitem:400|h[D]|h" } },
}
C_Container.GetContainerItemInfo = function(bag, slot) return CONTENT[bag] and CONTENT[bag][slot] end
C_Container.GetContainerNumSlots = function(bag) return bag == 0 and 16 or bag == 1 and 8 or (bag == 6 or bag == 7) and 4 or 0 end
C_Bank.FetchPurchasedBankTabData = function() return { { ID = 6 }, { ID = 7 } } end
C_Bank.FetchMaxNumBankTabs = function() return 4 end
C_Bank.FetchNextPurchasableBankTabData = function() return { tabCost = 1000 } end
GetInventoryItemLink = function(unit, inv) return inv == 31 and "|Hitem:900|h[Tasche]|h" or inv == 37 and "|Hitem:901|h[Banktasche]|h" or nil end
QN_CONNECTED_REALMS = { "Realm", "NachbarRealm" }

LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")
qnInventoryDB = { realms = {
	Realm = { Zwilling = { class = "MAGE" } },
	["Nachbar Realm"] = { Fernling = { class = "PRIEST" } },
} }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local me = qnInventoryDB.realms.Realm.Tester

---------------------------------------------------------------------------
-- Taschen je Platz
---------------------------------------------------------------------------
local c = me.containers
Check(c and c[0].size == 16 and c[0].items[1][1] == "|Hitem:100|h[A]|h" and c[0].items[1][2] == 5, "Rucksack Platz 1 mit Link und Anzahl")
Check(c[1].items[3][1] == "item:200" and c[1].items[3][2] == 1, "ohne Link: item:ID, Anzahl 1")
Check(c[1].link == "|Hitem:900|h[Tasche]|h" and c[0].link == nil, "Link der Tasche, Rucksack ohne")
Check(c[-1] and c[-1].size == 0, "Schlüsselbund erfasst")
Check(me.bags[100] == 5 and me.bags[200] == 1, "Summen wie bisher")

---------------------------------------------------------------------------
-- Bankfächer in der Reihenfolge des Bankfensters
---------------------------------------------------------------------------
Check(me.bankTabs == nil, "Bank ohne Besuch unbekannt")
FireEvent("BANKFRAME_OPENED")
local tabs = me.bankTabs
Check(tabs and #tabs == 2 and tabs[1].id == 6 and tabs[2].id == 7, "Fächer in Reihenfolge")
Check(tabs[1].items[2][1] == "|Hitem:300|h[C]|h" and tabs[2].items[1][2] == 1, "Fachinhalt je Platz")
Check(tabs[2].link == "|Hitem:901|h[Banktasche]|h" and me.bankMaxTabs == 4 and me.bankTabCost == 1000, "Banktasche, Fachzahl, Preis")
Check(me.bank[300] == 2 and me.bank[400] == 1, "Banksummen")
FireEvent("BANKFRAME_CLOSED")

---------------------------------------------------------------------------
-- Briefkasten: Briefe einzeln, Nachnahme-Anhänge sichtbar, aber nicht gezählt
---------------------------------------------------------------------------
local MAILS = {
	{ "Paket", "Brief", "Absender1", "Hallo", 0, 0, 3.5, 1, false, nil, nil, nil, false },
	{ nil, "Brief", "Absender2", "Nachnahme", 0, 500, 0.5, 1, true, nil, nil, nil, false },
}
GetInboxNumItems = function() return #MAILS, #MAILS end
GetInboxHeaderInfo = function(i) return unpack(MAILS[i], 1, 13) end
GetInboxItem = function(i, a) if a == 1 then return "x", i == 1 and 500 or 600, nil, i == 1 and 3 or 1, nil, nil, false end end
GetInboxItemLink = function(i, a) return i == 1 and "|Hitem:500|h[E]|h" or nil end
FireEvent("MAIL_SHOW")
FireEvent("MAIL_INBOX_UPDATE")
local list = me.mailList
Check(list and #list == 2, "zwei Briefe")
Check(list[1].sender == "Absender1" and list[1].icon == "Paket" and not list[1].read and list[1].items[1][1] == "|Hitem:500|h[E]|h" and list[1].items[1][2] == 3, "Brief 1 mit Anhang")
local left = list[1].expires - time()
Check(left > 3.4 * 86400 and left <= 3.5 * 86400, "Ablauf aus Resttagen")
Check(list[2].cod == 500 and list[2].read and list[2].icon == "Brief" and list[2].items[1][1] == "item:600", "Nachnahmebrief")
Check(me.mail[500] == 3 and me.mail[600] == nil, "Nachnahme nicht gezählt")
FireEvent("MAIL_CLOSED")

-- Post an einen eigenen Charakter: neuester Brief oben
GetSendMailItem = function(i) if i == 1 then return "x", 700, 12345, 4 end end
GetSendMailItemLink = function(i) return i == 1 and "|Hitem:700|h[G]|h" or nil end
GetSendMailMoney = function() return 250 end
SendMail("Zwilling", "Für dich", "")
FireEvent("MAIL_SEND_SUCCESS")
local twin = qnInventoryDB.realms.Realm.Zwilling
Check(twin.mailList and #twin.mailList == 1, "Brief beim Empfänger")
local sent = twin.mailList[1]
Check(sent.sender == "Tester" and sent.subject == "Für dich" and sent.money == 250 and sent.icon == 12345, "Absender, Betreff, Gold, Symbol")
Check(sent.items[1][1] == "|Hitem:700|h[G]|h" and sent.items[1][2] == 4, "Anhang mit Link")
Check(sent.expires - time() > 29 * 86400, "30 Tage Laufzeit")
SendMail("Zwilling", "Zweiter", "")
FireEvent("MAIL_SEND_SUCCESS")
Check(#twin.mailList == 2 and twin.mailList[1].subject == "Zweiter", "neuester Brief oben")

---------------------------------------------------------------------------
-- Charakterauswahl und Taschen des eingeloggten Charakters
---------------------------------------------------------------------------
local entries = inv.CharEntries()
local keys = {}
for i, e in ipairs(entries) do keys[i] = e[1]:gsub("\t", "/") end
Check(table.concat(keys, ",") == "Realm/Tester,Realm/Zwilling,Nachbar Realm/Fernling", "Auswahl: dieser Realm, dann verbundene: " .. table.concat(keys, ","))
Check(entries[3][2]:find("Fernling-Nachbar Realm", 1, true) ~= nil, "verbundener Realm mit Name-Realm")
local char, name, realm = inv.CharFromKey(entries[2][1])
Check(char == twin and name == "Zwilling" and realm == "Realm", "Schlüssel aufgelöst")

LOG = {}
inv.Toggle("bags")
Check(table.concat(LOG, ";") == "ToggleAllBags(nil)", "eigene Taschen: Blizzards Fenster: " .. table.concat(LOG, ";"))
LOG = {}
inv.Show("bags", inv.PlayerKey())
Check(table.concat(LOG, ";"):find("OpenAllBags", 1, true) ~= nil, "Auswahl des eigenen Charakters öffnet Blizzards Taschen")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
