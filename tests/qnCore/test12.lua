-- Scenario 12: qnCore review – migrating old settings when a profile exists, profile page
-- in combat, tracking spells outside the menu, errors in OnChange callbacks, Keep after
-- combat, MergeDefaults with wrong type

local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
local P = qnCore.Profiles

-- collect errors in callbacks instead of aborting (only in this scenario)
local ERRS = {}
geterrorhandler = function() return function(e) ERRS[#ERRS + 1] = tostring(e) end end

-- test addon with template from an earlier SavedVariablesPerCharacter (like qnNumKeyPad)
local switches = {}
local function Register(name, legacy)
	local ns = qnCore.NewAddon({}, name)
	switches[name] = 0
	local store = P.Register({ ns = ns, sv = "QN_TEST32_SV", defaults = { scale = 1, color = { r = 1, g = 1 } }, legacy = legacy,
		onSwitch = function() switches[name] = switches[name] + 1 end })
	return store, ns
end

---------------------------------------------------------------------------
-- 1. old values do not overwrite an existing profile
---------------------------------------------------------------------------
local a = Register("qnTestA", { scale = 2 })
local b = Register("qnTestB", { scale = 3 })   -- second character, layout still unknown
SetEditModeLayout(3)
local raid = QN_TEST32_SV.profiles["account:Raid"]
Check(raid ~= nil and raid.scale == 2 and a.db == raid, "first migration becomes the profile: " .. tostring(raid and raid.scale))
Check(b.db == raid and b.db.scale == 2, "second migration does not overwrite the existing profile: " .. tostring(b.db.scale))
Check(switches.qnTestB == 1 and switches.qnTestA == 0, "discarded old values: switched normally (onSwitch)")
local c = Register("qnTestC", { scale = 9 })   -- layout already known
Check(c.db == raid and raid.scale == 2 and not c.migrating, "with known layout too: profile stays: " .. tostring(raid.scale))
Check(type(raid.color) == "table" and raid.color.r == 1, "defaults filled in")

---------------------------------------------------------------------------
-- 2. reset / copy in combat: only after combat
---------------------------------------------------------------------------
SetEditModeLayout(4)
local solo = "char:Tester-Realm:Solo"
a.db.scale = 5
SetEditModeLayout(3)
local before = switches.qnTestA
QN_COMBAT = true
local n, deferred = P.CopyToActive(solo, { a })
Check(n == 1 and deferred == true, "copy in combat: counted and reported as deferred")
Check(a.db.scale == 2 and switches.qnTestA == before, "nothing applied in combat")
Check(P.ResetActive({ a }) == true, "reset in combat deferred")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(a.db.scale == 1 and a.db == raid and switches.qnTestA == before + 1, "after combat: only the last job, applied once: " .. tostring(a.db.scale))

-- profile switch before catching up: pending replacement expires
raid.scale = 2
QN_COMBAT = true
P.CopyToActive(solo, { a })
QN_COMBAT = false
SetEditModeLayout(4)   -- switch (in the scenario without combat) before PLAYER_REGEN_ENABLED
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(raid.scale == 2 and a.db.scale == 5, "switch in between: job expires: " .. raid.scale .. "/" .. a.db.scale)

-- immediately outside of combat
SetEditModeLayout(3)
local n2, deferred2 = P.CopyToActive(solo, { a })
Check(n2 == 1 and deferred2 == false and a.db.scale == 5 and a.db == raid, "immediately outside of combat")

-- profile page: message in combat
LOG = {}
local printed = {}
local AddMessage = DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage = function(self, msg) printed[#printed + 1] = msg AddMessage(self, msg) end
QN_COMBAT = true
StaticPopupDialogs.QNCORE_PROFILE_RESET.OnAccept(nil, { stores = { a }, scope = "qnTestA" })
local want = core.L["In combat: will be applied after combat."]
Check(#printed == 2 and printed[2]:find(want, 1, true), "profile page reports the delay")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
DEFAULT_CHAT_FRAME.AddMessage = AddMessage
Check(a.db.scale == 1, "profile page reset caught up")

---------------------------------------------------------------------------
-- 4. an error in one OnChange callback does not stop the others
---------------------------------------------------------------------------
local called = false
local failOnce = true
P.OnChange(function()
	if failOnce then
		failOnce = false
		error("intentional")
	end
end)
P.OnChange(function() called = true end)
SetEditModeLayout(4)
Check(called and #ERRS == 1 and ERRS[1]:find("intentional"), "OnChange with pcall: " .. table.concat(ERRS, ";"))
ERRS = {}

---------------------------------------------------------------------------
-- 5. specialization: Blizzard calls UpdateLayoutInfo, the hook is enough
---------------------------------------------------------------------------
EditModeManagerFrame:UpdateLayoutInfo({ layouts = EDIT_LAYOUTS, activeLayout = 3 })
RunTimers()
Check(P.GetActiveKey() == "account:Raid", "switch via UpdateLayoutInfo hook detected")

---------------------------------------------------------------------------
-- 6. Keep: protected frame in combat is pulled in afterwards
---------------------------------------------------------------------------
local f = CreateFrame("Frame", nil, UIParent)
f._protected = true
function f:GetLeft() return -500 end
local moved = 0
local check = qnCore.Visible.Keep(f, function() return true end, function() moved = moved + 1 end)
QN_COMBAT = true
check() RunTimers()
Check(moved == 0, "Keep in combat: not moved")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(moved == 1, "Keep caught up after combat: " .. moved)

---------------------------------------------------------------------------
-- 7. MergeDefaults: default is a table, saved value is something else
---------------------------------------------------------------------------
local db = qnCore.MergeDefaults({ color = 5, list = "x", scale = 2 }, { color = { r = 1 }, list = { 1, 2 }, scale = 1 })
Check(type(db.color) == "table" and db.color.r == 1 and type(db.list) == "table" and db.list[2] == 2 and db.scale == 2,
	"wrong type replaced by default")

---------------------------------------------------------------------------
-- 3. tracking: spell from the action bar is remembered, not reverted
---------------------------------------------------------------------------
local saved = qnCoreCharDB.tracking or {}
qnCoreCharDB.tracking = saved
QN_TRACKING[1].active, QN_TRACKING[2].active, QN_TRACKING[3].active = true, false, false
saved["filter:12"], saved["spell:2383"], saved["spell:2580"] = true, false, false
AdvanceTime(60)   -- time window after login is over
LOG = {}
QN_TRACKING[3].active = true   -- Find Minerals from the spellbook
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(#LOG == 0 and saved["spell:2580"] == true, "spell outside the menu remembered, not reverted: " .. table.concat(LOG, ";"))
QN_TRACKING[2].active, QN_TRACKING[3].active = true, false   -- Find Herbs replaces Find Minerals
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(#LOG == 0 and saved["spell:2383"] == true and saved["spell:2580"] == false, "change of tracking spell remembered")

-- death: loss is not remembered, restored after resurrection (also a late notification)
QN_DEAD = true
QN_TRACKING[2].active = false
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(saved["spell:2383"] == true, "loss on death not remembered")
QN_DEAD = false
FireEvent("PLAYER_UNGHOST") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "restored after resurrection: " .. table.concat(LOG, ";"))
AdvanceTime(5)
LOG = {}
QN_TRACKING[2].active = false   -- WoW reports the loss only now
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "late notification within the time window: restored: " .. table.concat(LOG, ";"))

-- after the time window: deselecting via the spellbook is remembered
AdvanceTime(60)
LOG = {}
QN_TRACKING[2].active = false
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(#LOG == 0 and saved["spell:2383"] == false, "after the time window: deselection remembered: " .. table.concat(LOG, ";"))

-- restore pending in combat: do not remember notifications until then as a selection
QN_TRACKING[2].active = true
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
QN_TRACKING[2].active = false   -- /reload in combat: tracking lost
QN_COMBAT = true
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
AdvanceTime(60)
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(saved["spell:2383"] == true and #LOG == 0, "pending in combat: loss not remembered")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "restored after combat: " .. table.concat(LOG, ";"))

Check(#ERRS == 0, "no errors: " .. table.concat(ERRS, ";"))
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
