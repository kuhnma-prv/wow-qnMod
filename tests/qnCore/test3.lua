-- Scenario 3: before the layout is known after logging in. With a profile for the layout of the
-- last session that profile applies, otherwise a provisional table; changes made in the meantime
-- are kept in both cases.
qnCoreCharDB = { layout = "account:Raid" }
-- qnNumKeyPad: profile of the last session exists
qnNumKeyPadProfiles = { global = {}, profiles = { ["account:Raid"] = { scale = 0.7 } } }
-- qnThreatMeter: no profile yet
qnThreatMeterDB = { global = {}, profiles = {} }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnThreatMeter")
local nkp = LoadAddon("qnNumKeyPad")
FireEvent("PLAYER_LOGIN")
RunTimers()
Check(qnCore.Profiles.GetActiveKey() == nil, "layout not known yet")
Check(nkp.db == qnNumKeyPadProfiles.profiles["account:Raid"] and nkp.db.scale == 0.7, "qnNumKeyPad: profile of the last session")
Check(meter.db.scale == 1 and next(qnThreatMeterDB.profiles) == nil, "qnThreatMeter: provisional table with defaults, not stored yet")
-- change before the layout is detected
SETTINGS.QNNKP_ALPHA:SetValue(0.5)
SETTINGS.QNTHREATMETER_SCALE:SetValue(1.4)
local provisional = meter.db
SetEditModeLayout(3)
Check(nkp.db == qnNumKeyPadProfiles.profiles["account:Raid"] and nkp.db.scale == 0.7 and nkp.db.alpha == 0.5, "qnNumKeyPad: same profile, change kept")
Check(qnThreatMeterDB.profiles["account:Raid"] == provisional and meter.db == provisional and meter.db.scale == 1.4, "qnThreatMeter: provisional table became the profile")
SetEditModeLayout(4)
Check(meter.db.scale == 1.4 and meter.db ~= provisional, "another layout: copy of the active profile")
Check(nkp.db.alpha == 0.5 and nkp.db ~= qnNumKeyPadProfiles.profiles["account:Raid"], "qnNumKeyPad: copy of the active profile")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
