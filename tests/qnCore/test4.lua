-- Scenario 4: second character, first login, layout without profile -> defaults (nothing active
-- before that could be copied); late registration after the layout is detected.
qnThreatMeterDB = { version = 1, global = {}, profiles = { ["account:Raid"] = { scale = 1.4 } }, migrated = { scale = 1.4 } }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnThreatMeter")
FireEvent("PLAYER_LOGIN")
RunTimers()
SetEditModeLayout(4)
Check(meter.db.scale == 1, "char layout without profile: defaults")
Check(qnThreatMeterDB.profiles["char:Tester-Realm:Solo"] == meter.db, "saved as profile")
Check(qnThreatMeterDB.profiles["account:Raid"].scale == 1.4, "other profile unchanged")
Check(qnThreatMeterDB.version == nil and qnThreatMeterDB.migrated == nil and qnThreatMeterDB.settingsVersion == "1.0", "version/migrated removed, settingsVersion written")

-- registration only after the layout is detected (addon loads later)
local P = qnCore.Profiles
local key = P.GetActiveKey()
local function Late(name, sv, defaults)
	local lns = {}
	qnCore.NewAddon(lns, name)
	return P.Register({ ns = lns, sv = sv, defaults = defaults }), lns
end
-- no saved variable yet: active profile with defaults
local s1, ns1 = Late("qnLateNone", "qnLateNoneDB", { a = 1, b = 2 })
Check(s1.key == key and qnLateNoneDB.profiles[key] == ns1.db and ns1.db.a == 1 and ns1.db.b == 2
	and type(qnLateNoneDB.global) == "table" and qnLateNoneDB.settingsVersion == "1.0", "late, without saved variable: active profile with defaults")
-- saved variable without profile for the layout: defaults, not another profile
qnLateNewDB = { profiles = { ["account:Raid"] = { a = 3 } }, global = {}, migrated = { a = 7 } }
local s2, ns2 = Late("qnLateNew", "qnLateNewDB", { a = 1, b = 2 })
Check(s2.key == key and qnLateNewDB.profiles[key] == ns2.db and ns2.db.a == 1 and ns2.db.b == 2, "late, without profile: defaults")
Check(qnLateNewDB.migrated == nil and qnLateNewDB.profiles["account:Raid"].a == 3, "late: migrated removed, other profile kept")
-- saved variable with profile for the layout
qnLateHasDB = { profiles = { [key] = { a = 9 } }, global = { g = 1 } }
local s3, ns3 = Late("qnLateHas", "qnLateHasDB", { a = 1 })
Check(s3.key == key and ns3.db == qnLateHasDB.profiles[key] and ns3.db.a == 9 and s3.global.g == 1, "late, with profile: this profile")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
