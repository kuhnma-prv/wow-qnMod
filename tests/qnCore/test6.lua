-- Scenario 6: profession bags when opening all bags
local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN") RunTimers()
LOG = {}
OpenAllBags()
Check(table.concat(LOG, ";") == "OpenAllBags(nil)", "default: profession bags stay open: " .. table.concat(LOG, ";"))
SETTINGS.QNCORE_BAGS_OPENPROFESSIONBAGS:SetValue(false)
Check(qnCoreDB.global.bags.openProfessionBags == false, "saved account-wide")
LOG = {}
OpenAllBags()
Check(table.concat(LOG, ";") == "OpenAllBags(nil);CloseBag(3);CloseBag(5)", "deselected: slot 3 (profession) and 5 (reagents) closed: " .. table.concat(LOG, ";"))
Check(OPEN[1] and OPEN[2] and OPEN[4] and OPEN[0], "normal bags stay open")
LOG = {}
FireEvent("MERCHANT_SHOW") RunTimers()
Check(table.concat(LOG, ";") == "CloseAllBags(nil);OpenAllBags(nil);CloseBag(3);CloseBag(5)", "also with automation: " .. table.concat(LOG, ";"))
-- combined bags: slot 3 is in the shared window, close only the reagent bag
C_CVar._v.combinedBags = "1"
LOG = {}
OpenAllBags()
Check(table.concat(LOG, ";") == "OpenAllBags(nil);CloseBag(5)", "combined: only reagent bag closed: " .. table.concat(LOG, ";"))
C_CVar._v.combinedBags = "0"
SETTINGS.QNCORE_BAGS_ENABLED:SetValue(false)
LOG = {}
OpenAllBags()
Check(table.concat(LOG, ";") == "OpenAllBags(nil)", "automation off: qnCore touches no bag")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")