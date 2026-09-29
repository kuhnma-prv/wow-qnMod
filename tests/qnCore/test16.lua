-- Scenario 16: settings version and migrations (qnCore.Migrate, Profiles.Register)
--   * "<major>.<minor>"; a saved variable without settingsVersion counts as "1.0"
--   * migrations[major] run in order, only for new major versions, over all profiles
--   * stored major newer than the addon: nothing converted, warning, false
--   * missing migration: developer error
--   * Register: obsolete keys, sanitize before the defaults, leftovers of the old profile
--     migration (migrated, version) removed, removed options upgrade/legacy rejected

local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
SetEditModeLayout(3)   -- active layout: account "Raid"
local P = qnCore.Profiles
local CL = core.L

---------------------------------------------------------------------------
-- 1. ParseSettingsVersion
---------------------------------------------------------------------------
local major, minor = qnCore.ParseSettingsVersion("2.7")
Check(major == 2 and minor == 7, "parse 2.7")
Check(qnCore.ParseSettingsVersion("2") == nil and qnCore.ParseSettingsVersion(nil) == nil
	and qnCore.ParseSettingsVersion("x.1") == nil, "invalid versions give nil")

---------------------------------------------------------------------------
-- 2. qnCore.Migrate on plain tables
---------------------------------------------------------------------------
local calls = {}
local migrations = {
	[2] = function(sv) calls[#calls + 1] = 2 sv.b = sv.a sv.a = nil end,
	[3] = function(sv) calls[#calls + 1] = 3 sv.c = (sv.b or 0) * 10 end,
}

-- without version: counts as 1.0, no migration up to 1.x
local sv = { a = 1 }
Check(qnCore.Migrate(sv, { name = "qnTest", settingsVersion = "1.2", migrations = migrations }) == true
	and #calls == 0 and sv.settingsVersion == "1.2" and sv.a == 1, "no version: 1.0, minor change without migration")

-- 1.x -> 3.1: migrations 2 and 3 in this order
sv = { a = 4, settingsVersion = "1.5" }
Check(qnCore.Migrate(sv, { name = "qnTest", settingsVersion = "3.1", migrations = migrations })
	and table.concat(calls, ",") == "2,3" and sv.b == 4 and sv.c == 40 and sv.a == nil and sv.settingsVersion == "3.1",
	"migrations 2 and 3 in order: " .. table.concat(calls, ","))

-- same major, other minor: nothing to convert
calls = {}
sv = { b = 1, settingsVersion = "3.4" }
Check(qnCore.Migrate(sv, { name = "qnTest", settingsVersion = "3.1", migrations = migrations }) and #calls == 0
	and sv.settingsVersion == "3.1", "same major: no migration")

-- stored major newer than the addon (downgrade): unchanged, warning, false
local out = {}
sv = { b = 1, settingsVersion = "4.0" }
local ok = qnCore.Migrate(sv, { name = "qnTest", settingsVersion = "3.1", migrations = migrations,
	print = function(msg) out[#out + 1] = msg end })
Check(ok == false and #calls == 0 and sv.settingsVersion == "4.0" and sv.b == 1, "newer major: nothing converted")
Check(#out == 1 and out[1] == CL["Saved settings of %s have version %s, this addon version knows %s: nothing is converted."]:format("qnTest", "4.0", "3.1"),
	"newer major: warning " .. tostring(out[1]))

-- missing migration: developer error
local okMissing, err = pcall(qnCore.Migrate, { settingsVersion = "1.0" }, { name = "qnTest", settingsVersion = "2.0" })
Check(not okMissing and tostring(err):find("no migration to settings version 2", 1, true) ~= nil, "missing migration: error")

---------------------------------------------------------------------------
-- 3. Profiles.Register with migrations, obsolete keys and sanitize
---------------------------------------------------------------------------
QN_TEST16_SV = {
	settingsVersion = "1.3",
	migrated = { size = 9 },     -- leftover of the profile migration before 1.0
	version = 2,                 -- leftover as well
	profiles = {
		["account:Raid"] = { size = 5, oldColor = "red", mode = "bad", dropped = true },
		["preset:1"] = { size = 7, oldColor = "blue" },   -- not the active profile
	},
	global = { seen = true },
}
local order = {}
local ns = qnCore.NewAddon({}, "qnTest16")
local store = P.Register({
	ns = ns,
	sv = "QN_TEST16_SV",
	settingsVersion = "2.0",
	defaults = { size = 1, color = "white", mode = "normal" },
	migrations = {
		-- 2.0: oldColor -> color in every profile
		[2] = function(s)
			order[#order + 1] = "migrate"
			for _, db in pairs(s.profiles) do
				db.color, db.oldColor = db.oldColor, nil
			end
		end,
	},
	obsolete = { "dropped" },
	sanitize = function(db)
		order[#order + 1] = "sanitize:" .. tostring(db.color ~= nil)
		if db.mode ~= "normal" and db.mode ~= "compact" then
			db.mode = nil   -- the default comes back
		end
	end,
})
local raid, modern = QN_TEST16_SV.profiles["account:Raid"], QN_TEST16_SV.profiles["preset:1"]
Check(QN_TEST16_SV.settingsVersion == "2.0", "version written: " .. tostring(QN_TEST16_SV.settingsVersion))
Check(raid.color == "red" and modern.color == "blue" and raid.oldColor == nil and modern.oldColor == nil,
	"migration converted every profile, not only the active one")
Check(order[1] == "migrate", "migration before the profiles are prepared")
Check(raid.dropped == nil, "obsolete key removed")
Check(raid.mode == "normal", "sanitize set an invalid value to nil, the default came back: " .. tostring(raid.mode))
Check(QN_TEST16_SV.migrated == nil and QN_TEST16_SV.version == nil, "leftovers migrated/version removed")
Check(QN_TEST16_SV.global.seen == true and store.global == QN_TEST16_SV.global, "global kept")
Check(store.db == raid and raid.size == 5, "active profile = layout Raid")

-- new layout without profile: copy of the active profile, prepared the same way
SetEditModeLayout(4)
local solo = QN_TEST16_SV.profiles["char:Tester-Realm:Solo"]
Check(solo and solo ~= raid and solo.size == 5 and solo.color == "red" and solo.mode == "normal",
	"new layout: copy of the active profile")

-- removed options are rejected
local okOld = pcall(P.Register, { ns = qnCore.NewAddon({}, "qnTest16b"), sv = "QN_TEST16B_SV", upgrade = function() end })
Check(not okOld, "Register with upgrade: developer error")
local okLegacy = pcall(P.Register, { ns = qnCore.NewAddon({}, "qnTest16c"), sv = "QN_TEST16C_SV", legacy = {} })
Check(not okLegacy, "Register with legacy: developer error")

---------------------------------------------------------------------------
-- 4. all qn addons declare settings version 1.0
---------------------------------------------------------------------------
Check(qnCoreDB.settingsVersion == "1.0", "qnCore: settings version 1.0")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
