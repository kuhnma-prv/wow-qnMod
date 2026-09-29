-- Scenario 4: second character after the migration, first login, layout without profile
-- -> gets the saved template (previous settings), not the default values.
qnMeterDB = { version = 1, global = {}, profiles = { ["account:Raid"] = { scale = 1.4 } }, migrated = { scale = 1.4 } }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
FireEvent("PLAYER_LOGIN")
RunTimers()
SetEditModeLayout(4)
Check(meter.db.scale == 1.4, "char layout without profile: template from the migration")
Check(qnMeterDB.profiles["char:Tester-Realm:Solo"] == meter.db, "saved as profile")
Check(qnMeterDB.version == nil, "old version number removed")

-- registration only after the layout is detected (addon loads later)
local P = qnCore.Profiles
local key = P.GetActiveKey()
local function Late(name, sv, defaults)
	local lns = {}
	qnCore.NewAddon(lns, name)
	return P.Register({ ns = lns, sv = sv, defaults = defaults }), lns
end
-- old flat format: becomes the active profile immediately, copy as template
qnLateOldDB = { a = 5 }
local s1, ns1 = Late("qnLateOld", "qnLateOldDB", { a = 1, b = 2 })
Check(s1.key == key and not s1.migrating and qnLateOldDB.profiles[key] == ns1.db and ns1.db.a == 5 and ns1.db.b == 2
	and qnLateOldDB.migrated.a == 5 and qnLateOldDB.migrated ~= ns1.db, "late, old format: active profile, template copied")
-- new format without profile for the layout: copy of the template from the migration
qnLateNewDB = { profiles = { ["account:Raid"] = { a = 3 } }, global = {}, migrated = { a = 7 } }
local s2, ns2 = Late("qnLateNew", "qnLateNewDB", { a = 1, b = 2 })
Check(s2.key == key and qnLateNewDB.profiles[key] == ns2.db and ns2.db.a == 7 and ns2.db.b == 2, "late, without profile: template")
-- new format with profile for the layout
qnLateHasDB = { profiles = { [key] = { a = 9 } }, global = { g = 1 } }
local s3, ns3 = Late("qnLateHas", "qnLateHasDB", { a = 1 })
Check(s3.key == key and ns3.db == qnLateHasDB.profiles[key] and ns3.db.a == 9 and s3.global.g == 1, "late, with profile: this profile")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
