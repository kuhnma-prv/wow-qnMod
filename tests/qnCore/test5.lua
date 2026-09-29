-- Scenario 5: qnCoreDB from the version with profiles -> account-wide
qnCoreCharDB = { layout = "account:Raid" }
qnCoreDB = { version = 1, layouts = {}, global = {}, profiles = {
	["account:Raid"] = { chatTimestamps = "%H:%M ", bags = { merchantOpen = "backpack", enabled = true } },
	["preset:1"] = { chatTimestamps = "none", bags = { merchantOpen = "closed" } },
} }
local core = LoadAddon("qnCore")
Check(qnCoreDB.ownProfiles and next(qnCoreDB.profiles) == nil and qnCoreDB.version == nil, "old profiles removed from qnCoreDB, own profiles created")
Check(qnCoreDB.global.bags.merchantOpen == "backpack", "bags taken over from the last active profile")
Check(qnCoreDB.global.chatTimestamps == nil, "timestamps not taken over (option removed)")
Check(qnCoreDB.global.bags.auctionOpen == "all", "defaults filled in")
Check(qnCoreDB.layouts ~= nil, "layout descriptions stay")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")