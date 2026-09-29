-- Scenario 8: qnCore tracking after death when events arrive in an unfavorable order
local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
C_Minimap.SetTracking(2, true)      -- Find Herbs on (remembered)

-- 1. at the resurrection event the character still counts as dead
QN_DEAD = true
QN_TRACKING[2].active = false
LOG = {}
FireEvent("PLAYER_UNGHOST")
QN_DEAD = false                      -- shortly afterwards he is alive
RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "dead at the event: caught up later: " .. table.concat(LOG, ";"))

-- 2. the minimap reports the loss only after the resurrection
FireEvent("PLAYER_UNGHOST") RunTimers()   -- nothing to do, tracking still active
QN_TRACKING[2].active = false
LOG = {}
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "late notification: restored: " .. table.concat(LOG, ";"))

-- 3. spell fails: notifications do not cause an endless loop
QN_TRACKING[2].active = false
QN_TRACKING_BLOCKED = true
FireEvent("PLAYER_UNGHOST") RunTimers()
LOG = {}
for _ = 1, 5 do FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers() end
Check(#LOG == 0, "quiet after 3 attempts: " .. table.concat(LOG, ";"))
QN_TRACKING_BLOCKED = false

-- 4. own selection in the menu is not reverted
LOG = {}
C_Minimap.SetTracking(2, false)
RunTimers()
Check(qnCoreCharDB.tracking["spell:2383"] == false and not table.concat(LOG, ";"):find("true"), "deselection stays: " .. table.concat(LOG, ";"))
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
