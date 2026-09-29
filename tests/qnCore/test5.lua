-- Szenario 5: qnCoreDB aus der Fassung mit Profilen -> kontoweit
qnCoreCharDB = { layout = "account:Raid" }
qnCoreDB = { version = 1, layouts = {}, global = {}, profiles = {
	["account:Raid"] = { chatTimestamps = "%H:%M ", bags = { merchantOpen = "backpack", enabled = true } },
	["preset:1"] = { chatTimestamps = "none", bags = { merchantOpen = "closed" } },
} }
local core = LoadAddon("qnCore")
Check(qnCoreDB.ownProfiles and next(qnCoreDB.profiles) == nil and qnCoreDB.version == nil, "alte Profile aus qnCoreDB entfernt, eigene Profile angelegt")
Check(qnCoreDB.global.bags.merchantOpen == "backpack", "Taschen aus zuletzt aktivem Profil übernommen")
Check(qnCoreDB.global.chatTimestamps == nil, "Zeitstempel nicht übernommen (Option entfernt)")
Check(qnCoreDB.global.bags.auctionOpen == "all", "Vorgaben ergänzt")
Check(qnCoreDB.layouts ~= nil, "Layout-Beschreibungen bleiben")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")