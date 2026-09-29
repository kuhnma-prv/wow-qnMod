-- Scenario 3: migration only into a still missing profile; an existing one is kept.
-- qnNumKeyPad: another character has already migrated (profile account:Raid exists),
-- this character still has its own old values.
qnNumKeyPadProfiles = { version = 1, global = {}, profiles = { ["account:Raid"] = { scale = 0.7 } }, migrated = { scale = 0.7 } }
qnNumKeyPadDB = { scale = 1.9, locked = true }
-- qnMeter: old flat format
qnMeterDB = { scale = 1.4, styleVersion = 2 }
-- qnCoreCharDB with layout of the last session must not prevent the migration
qnCoreCharDB = { layout = "account:Raid" }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
local nkp = LoadAddon("qnNumKeyPad")
FireEvent("PLAYER_LOGIN")
RunTimers()
Check(nkp.db.scale == 1.9, "before the layout: previous values active")
SETTINGS.QNNKP_ALPHA:SetValue(0.5)   -- change before the layout is detected
SetEditModeLayout(3)
Check(qnNumKeyPadProfiles.profiles["account:Raid"].scale == 0.7, "existing profile is kept")
Check(nkp.db == qnNumKeyPadProfiles.profiles["account:Raid"] and nkp.db.scale == 0.7, "existing profile active")
Check(qnMeterDB.profiles["account:Raid"].scale == 1.4 and qnMeterDB.migrated.scale == 1.4, "qnMeter migrated, template saved")
Check(qnNumKeyPadDB == nil, "old char table deleted")
SetEditModeLayout(4)
Check(meter.db.scale == 1.4, "another layout: copy of the active profile")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
