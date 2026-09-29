-- Scenario 3: qnInventory 0.2.0 - contents per slot (bags, bank tabs), individual letters
-- (mailbox and mail to own characters), character selection, bags of the logged-in
-- character via Blizzard's window.
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
-- Bags per slot
---------------------------------------------------------------------------
local c = me.containers
Check(c and c[0].size == 16 and c[0].items[1][1] == "|Hitem:100|h[A]|h" and c[0].items[1][2] == 5, "backpack slot 1 with link and count")
Check(c[1].items[3][1] == "item:200" and c[1].items[3][2] == 1, "without link: item:ID, count 1")
Check(c[1].link == "|Hitem:900|h[Tasche]|h" and c[0].link == nil, "link of the bag, backpack without")
Check(c[-1] and c[-1].size == 0, "keyring recorded")
Check(me.bags[100] == 5 and me.bags[200] == 1, "totals as before")

---------------------------------------------------------------------------
-- Bank tabs in the order of the bank window
---------------------------------------------------------------------------
Check(me.bankTabs == nil, "bank unknown without visit")
FireEvent("BANKFRAME_OPENED")
local tabs = me.bankTabs
Check(tabs and #tabs == 2 and tabs[1].id == 6 and tabs[2].id == 7, "tabs in order")
Check(tabs[1].items[2][1] == "|Hitem:300|h[C]|h" and tabs[2].items[1][2] == 1, "tab contents per slot")
Check(tabs[2].link == "|Hitem:901|h[Banktasche]|h" and me.bankMaxTabs == 4 and me.bankTabCost == 1000, "bank bag, tab count, price")
Check(me.bank[300] == 2 and me.bank[400] == 1, "bank totals")
FireEvent("BANKFRAME_CLOSED")

---------------------------------------------------------------------------
-- Mailbox: individual letters, COD attachments visible but not counted
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
Check(list and #list == 2, "two letters")
Check(list[1].sender == "Absender1" and list[1].icon == "Paket" and not list[1].read and list[1].items[1][1] == "|Hitem:500|h[E]|h" and list[1].items[1][2] == 3, "letter 1 with attachment")
local left = list[1].expires - time()
Check(left > 3.4 * 86400 and left <= 3.5 * 86400, "expiry from days left")
Check(list[2].cod == 500 and list[2].read and list[2].icon == "Brief" and list[2].items[1][1] == "item:600", "COD letter")
Check(me.mail[500] == 3 and me.mail[600] == nil, "COD not counted")
FireEvent("MAIL_CLOSED")

-- Mail to one of our own characters: newest letter on top
GetSendMailItem = function(i) if i == 1 then return "x", 700, 12345, 4 end end
GetSendMailItemLink = function(i) return i == 1 and "|Hitem:700|h[G]|h" or nil end
GetSendMailMoney = function() return 250 end
SendMail("Zwilling", "Für dich", "")
FireEvent("MAIL_SEND_SUCCESS")
local twin = qnInventoryDB.realms.Realm.Zwilling
Check(twin.mailList and #twin.mailList == 1, "letter at the recipient")
local sent = twin.mailList[1]
Check(sent.sender == "Tester" and sent.subject == "Für dich" and sent.money == 250 and sent.icon == 12345, "sender, subject, gold, icon")
Check(sent.items[1][1] == "|Hitem:700|h[G]|h" and sent.items[1][2] == 4, "attachment with link")
Check(sent.expires - time() > 29 * 86400, "30 days duration")
SendMail("Zwilling", "Zweiter", "")
FireEvent("MAIL_SEND_SUCCESS")
Check(#twin.mailList == 2 and twin.mailList[1].subject == "Zweiter", "newest letter on top")

---------------------------------------------------------------------------
-- Character selection and bags of the logged-in character
---------------------------------------------------------------------------
local entries = inv.CharEntries()
local keys = {}
for i, e in ipairs(entries) do keys[i] = e[1]:gsub("\t", "/") end
Check(table.concat(keys, ",") == "Realm/Tester,Realm/Zwilling,Nachbar Realm/Fernling", "selection: this realm, then connected ones: " .. table.concat(keys, ","))
Check(entries[3][2]:find("Fernling-Nachbar Realm", 1, true) ~= nil, "connected realm with Name-Realm")
local char, name, realm = inv.CharFromKey(entries[2][1])
Check(char == twin and name == "Zwilling" and realm == "Realm", "key resolved")

LOG = {}
inv.Toggle("bags")
Check(table.concat(LOG, ";") == "ToggleAllBags(nil)", "own bags: Blizzard's window: " .. table.concat(LOG, ";"))
LOG = {}
inv.Show("bags", inv.PlayerKey())
Check(table.concat(LOG, ";"):find("OpenAllBags", 1, true) ~= nil, "selecting the own character opens Blizzard's bags")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
