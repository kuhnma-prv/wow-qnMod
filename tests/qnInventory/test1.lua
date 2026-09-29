-- Scenario 1: qnInventory: bags, bank, mail, tooltip, deletion
local tooltipCall
TooltipDataProcessor.AddTooltipPostCall = function(_, fn) tooltipCall = fn end
-- Bags: backpack slot 1 = 5x item 100, bag 1 slot 2 = item 200; bank tab 6: 3x item 100
local CONTENT = { [0] = { [1] = { itemID = 100, stackCount = 5 } }, [1] = { [2] = { itemID = 200 } }, [6] = { [1] = { itemID = 100, stackCount = 3 } } }
C_Container.GetContainerItemInfo = function(bag, slot) return CONTENT[bag] and CONTENT[bag][slot] end
local core = LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")

C_Bank.FetchPurchasedBankTabData = function() return { { ID = 6 } } end
qnInventoryDB = { realms = { Realm = { ["Ärger"] = { class = "MAGE", bags = { [100] = 2 } } } } }

FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local me = qnInventoryDB.realms.Realm.Tester
Check(me and me.bags[100] == 5 and me.bags[200] == 1, "bags counted")
Check(me.money == 12345 and me.class == "WARRIOR", "gold and class")
Check(me.bank == nil, "bank unknown as long as never opened")
FireEvent("BANKFRAME_OPENED")
Check(me.bank and me.bank[100] == 3, "bank counted")
FireEvent("BANKFRAME_CLOSED")
CONTENT[6][1].stackCount = 99
FireEvent("BAG_UPDATE_DELAYED")
Check(me.bank[100] == 3, "closed bank keeps the old state")

-- Mail to one of our own characters (name lowercase and with realm)
GetSendMailItem = function(i) if i == 1 then return "x", 200, nil, 4 end end
GetSendMailMoney = function() return 500 end
SendMail("ärger-Realm", "Betreff", "")
FireEvent("MAIL_SEND_SUCCESS")
local other = qnInventoryDB.realms.Realm["Ärger"]
Check(other.mail and other.mail[200] == 4 and other.mailMoney == 500, "mail credited")
Check(other.mailIncomplete == true, "mailbox never seen: incomplete")
SendMail("Fremder", "x", "")
FireEvent("MAIL_SEND_SUCCESS")
Check(qnInventoryDB.realms.Realm.Fremder == nil, "foreign recipient ignored")

-- Own mailbox
GetInboxNumItems = function() return 1, 1 end
GetInboxHeaderInfo = function() return nil, nil, nil, nil, 70, nil, nil, 1 end
GetInboxItem = function(i, a) if a == 1 then return "y", 300, nil, 2, nil, nil, false end end
FireEvent("MAIL_SHOW")
FireEvent("MAIL_INBOX_UPDATE")
Check(me.mail[300] == 2 and me.mailMoney == 70 and not me.mailIncomplete, "mailbox read")

-- Tooltip
local lines = {}
local tip = { AddLine = function(_, t) lines[#lines + 1] = t end, AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. "|" .. tostring(b) end }
GameTooltip.AddLine, GameTooltip.AddDoubleLine = tip.AddLine, tip.AddDoubleLine
tooltipCall(GameTooltip, { id = 100 })
local text = table.concat(lines, ";")
Check(text:find(CHARACTER .. "|" .. inv.L["Bags/Bank/Mail"], 1, true) ~= nil, "tooltip header localized: " .. text)
Check(text:find("5/3/0", 1, true) and text:find("2/?/0+", 1, true) and text:find(TOTAL .. "|10", 1, true), "tooltip lines: " .. text)

-- Deletion (case-insensitive)
SlashCmdList.QNINVENTORY("delete ärger")
Check(qnInventoryDB.realms.Realm["Ärger"] == nil, "character deleted")
SlashCmdList.QNINVENTORY("delete tester")
Check(qnInventoryDB.realms.Realm.Tester ~= nil, "logged-in character stays")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
