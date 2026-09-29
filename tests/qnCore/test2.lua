-- Scenario 2: /reload with saved profiles; layout of the last session known.
qnCoreCharDB = { layout = "account:Raid" }
qnCoreDB = { settingsVersion = "1.0", profiles = { ["account:Raid"] = {} }, global = {}, layouts = { ["account:Raid"] = { kind = "account", name = "Raid" } } }
qnThreatMeterDB = { version = 1, global = {}, profiles = {
	["account:Raid"] = { scale = 1.7 },
	["char:Tester-Realm:Solo"] = { scale = 0.6 },
} }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnThreatMeter")
local nkp = LoadAddon("qnNumKeyPad")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", false, true)
RunTimers()
local P = qnCore.Profiles
Check(meter.db == qnThreatMeterDB.profiles["account:Raid"] and meter.db.scale == 1.7, "provisional: profile of the last session")
Check(meter.db.showTPS == true, "defaults filled in")
Check(qnThreatMeterDB.settingsVersion == "1.0" and qnThreatMeterDB.version == nil, "settingsVersion written, old version number removed")
Check(core.db == qnCoreDB.profiles["account:Raid"] and core.db.questTextSize == 0, "qnCore: profile of the last session, defaults filled in")
Check(C_CVar._v.showTimestamps == "none", "CVar showTimestamps untouched")
local before = meter.db
SetEditModeLayout(3)
Check(P.GetActiveKey() == "account:Raid" and meter.db == before, "same layout: no switch")
SetEditModeLayout(4)
Check(meter.db.scale == 0.6, "existing char profile loaded")
Check(nkp.db.scale == 1, "qnNumKeyPad without saved data: defaults")
-- profile page: dropdown and list
local found
for _, key in ipairs(P.GetKnownKeys()) do if key == "char:Tester-Realm:Solo" then found = true end end
Check(found, "GetKnownKeys contains char profile")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
