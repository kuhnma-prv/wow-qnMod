-- Szenario 6: Berufstaschen beim Öffnen aller Taschen
local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN") RunTimers()
LOG = {}
OpenAllBags()
Check(table.concat(LOG, ";") == "OpenAllBags(nil)", "Standard: Berufstaschen bleiben offen: " .. table.concat(LOG, ";"))
SETTINGS.QNCORE_BAGS_OPENPROFESSIONBAGS:SetValue(false)
Check(qnCoreDB.global.bags.openProfessionBags == false, "kontoweit gespeichert")
LOG = {}
OpenAllBags()
Check(table.concat(LOG, ";") == "OpenAllBags(nil);CloseBag(3);CloseBag(5)", "abgewählt: Platz 3 (Beruf) und 5 (Reagenzien) zu: " .. table.concat(LOG, ";"))
Check(OPEN[1] and OPEN[2] and OPEN[4] and OPEN[0], "normale Taschen bleiben offen")
LOG = {}
FireEvent("MERCHANT_SHOW") RunTimers()
Check(table.concat(LOG, ";") == "CloseAllBags(nil);OpenAllBags(nil);CloseBag(3);CloseBag(5)", "auch bei Automatik: " .. table.concat(LOG, ";"))
-- Zusammengefasste Taschen: Platz 3 steckt im gemeinsamen Fenster, nur die Reagenzientasche schließen
C_CVar._v.combinedBags = "1"
LOG = {}
OpenAllBags()
Check(table.concat(LOG, ";") == "OpenAllBags(nil);CloseBag(5)", "zusammengefasst: nur Reagenzientasche zu: " .. table.concat(LOG, ";"))
C_CVar._v.combinedBags = "0"
SETTINGS.QNCORE_BAGS_ENABLED:SetValue(false)
LOG = {}
OpenAllBags()
Check(table.concat(LOG, ";") == "OpenAllBags(nil)", "Automatik aus: qnCore fasst keine Tasche an")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")