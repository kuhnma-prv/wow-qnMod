-- Scenario 5: qnCoreDB with leftovers from before settings 1.0 (ownProfiles, version, migrated):
-- they are removed, profiles and account-wide values stay.
qnCoreCharDB = { layout = "account:Raid" }
qnCoreDB = { ownProfiles = true, version = 1, migrated = {}, layouts = {}, global = { bags = { merchantOpen = "backpack" } }, profiles = {
	["account:Raid"] = { questTextSize = 10 },
	["preset:1"] = {},
} }
local core = LoadAddon("qnCore")
Check(qnCoreDB.ownProfiles == nil and qnCoreDB.version == nil and qnCoreDB.migrated == nil, "leftovers removed from qnCoreDB")
Check(qnCoreDB.settingsVersion == "1.0", "settingsVersion written")
Check(qnCoreDB.profiles["account:Raid"].questTextSize == 10 and qnCoreDB.profiles["preset:1"].questTextSize == 0, "own profiles kept, defaults filled in")
Check(core.db == qnCoreDB.profiles["account:Raid"], "profile of the last session active")
Check(qnCoreDB.global.bags.merchantOpen == "backpack", "account-wide bags kept")
Check(qnCoreDB.global.bags.auctionOpen == "all", "defaults filled in")
Check(qnCoreDB.layouts ~= nil, "layout descriptions stay")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")