-- Scenario 7: qnCore remembers minimap tracking (Find Herbs etc.)
-- and restores it after death, /reload and combat.
local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
Check(#LOG == 0, "nothing remembered: no SetTracking at login: " .. table.concat(LOG, ";"))
Check(qnCoreDB.global.tracking == true, "option on by default, account-wide")

-- selection in the minimap menu
C_Minimap.SetTracking(2, true)      -- Find Herbs on
C_Minimap.SetTracking(1, false)     -- mailbox off
local saved = qnCoreCharDB.tracking
Check(saved["spell:2383"] == true and saved["filter:12"] == false and saved["spell:2580"] == nil,
	"remembered per character: only touched entries")

-- death: WoW loses the tracking spell (without SetTracking)
QN_DEAD = true
QN_TRACKING[2].active = false
LOG = {}
FireEvent("PLAYER_ALIVE") RunTimers()   -- spirit released
Check(#LOG == 0, "cast nothing as a ghost")
Check(saved["spell:2383"] == true, "loss on death is not remembered")
QN_DEAD = false
FireEvent("PLAYER_UNGHOST") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "restored after resurrection: " .. table.concat(LOG, ";"))
Check(QN_TRACKING[2].active and saved["spell:2383"] == true, "state correct, selection unchanged")

-- /reload or restart: the game has forgotten everything
QN_TRACKING[1].active, QN_TRACKING[2].active = true, false
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD", false, true) RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(1,false);SetTracking(2,true)", "restored individually after /reload: " .. table.concat(LOG, ";"))

-- not in combat, catch up afterwards
QN_TRACKING[2].active = false
QN_COMBAT = true
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(#LOG == 0, "nothing in combat")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "caught up after combat: " .. table.concat(LOG, ";"))

-- spell fails: at most 3 attempts per run
QN_TRACKING[2].active = false
QN_TRACKING_BLOCKED = true
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(#LOG == 3, "3 attempts, then stop: " .. table.concat(LOG, ";"))
QN_TRACKING_BLOCKED = false

-- unknown spell (other profession unlearned) is ignored and kept
saved["spell:9999"] = true
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)" and saved["spell:9999"] == true, "unknown entry stays remembered: " .. table.concat(LOG, ";"))

-- "Deselect all" in the menu
C_Minimap.ClearAllTracking()
Check(saved["spell:2383"] == false and saved["spell:2580"] == false and saved["filter:12"] == false, "deselect all remembered")

-- option off: restore nothing, remember nothing
SETTINGS.QNCORE_TRACKING:SetValue(false)
Check(qnCoreDB.global.tracking == false and type(qnCoreCharDB.tracking) == "table", "switch account-wide, selection per character")
QN_TRACKING[3].active = true
C_Minimap.SetTracking(2, true)
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(#LOG == 0 and saved["spell:2383"] == false, "off: neither remember nor restore")
-- on again: current state is taken over
SETTINGS.QNCORE_TRACKING:SetValue(true)
Check(saved["spell:2383"] == true and saved["spell:2580"] == true and saved["filter:12"] == false, "current state taken over when switching on")
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(#LOG == 0, "nothing to do afterwards")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
