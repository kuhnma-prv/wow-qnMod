-- Scenario 11: qnBuffMod – disabling windows in combat (visibility driver, frame pool) and
-- expiration warnings during the aura restriction (frozen lists)
-- The driver manager is protected: in combat Register-/UnregisterStateDriver fail.
local drivers = {}
function RegisterStateDriver(f, state, cond)
	if InCombatLockdown() then error("ADDON_ACTION_BLOCKED: RegisterStateDriver in combat") end
	drivers[f] = cond
end
function UnregisterStateDriver(f, state)
	if InCombatLockdown() then error("ADDON_ACTION_BLOCKED: UnregisterStateDriver in combat") end
	drivers[f] = nil
end

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, L = bm.enum, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
local function Count(pattern)
	local n = 0
	for _, m in ipairs(printed) do if m:find(pattern, 1, true) then n = n + 1 end end
	return n
end

-- GetTime() = 1000
local function Buff(name, dur, exp)
	return { name = name, icon = 1, applications = 0, duration = dur, expirationTime = exp, sourceUnit = "player", spellId = #name, cancelable = true }
end
AURAS.player = { Buff("Arkane Intelligenz", 600, 1100), Buff("Segen der Macht", 600, 1100) }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

---------------------------------------------------------------------------
-- finding 1: disabling in combat
---------------------------------------------------------------------------
local win = bm.GetWindow(1)
bm.db.windows[1].visWindow = E.vis.CUSTOM
bm.db.windows[1].visCondition = "[combat] hide;show"
win:Apply()
local f, bg = win.frame, win.bg
Check(drivers[f] == "[combat] hide;show", "visibility driver set: " .. tostring(drivers[f]))
Check(#bm.GetEntries(1) == 2, "two entries")
local entries = win.entries

QN_COMBAT = true
local ok, err = pcall(win.Disable, win)
Check(ok, "disabling in combat without a protected call: " .. tostring(err))
Check(win.frame == nil and drivers[f] ~= nil, "in combat: driver stays until after combat")
Check(f:GetAlpha() == 0 and bg._mouse == false, "until then invisible and without mouse")
f:Show()   -- the driver shows the frame again
local shown = 0
for _, e in ipairs(entries) do if e:IsShown() then shown = shown + 1 end end
Check(shown == 0 and f._scripts.OnShow == nil and f._scripts.OnUpdate == nil, "shown: no entries, no scripts")
-- re-enabling in combat: the frame set with driver does not come from the pool
ok, err = pcall(win.Enable, win)
Check(ok and win.frame ~= nil and win.frame ~= f and drivers[win.frame] == nil, "in combat: new frame set without the old driver: " .. tostring(err))
local f2 = win.frame
ok, err = pcall(win.Disable, win)
Check(ok, "new frame set without driver: released immediately: " .. tostring(err))
QN_COMBAT = false
ok, err = pcall(FireEvent, "PLAYER_REGEN_ENABLED")
RunTimers()
Check(ok, "no errors after combat: " .. tostring(err))
Check(drivers[f] == nil and not f:IsShown(), "after combat: driver removed, frame hidden")
-- re-enabling: frame set from the pool, visible, own new driver
win:Enable()
Check(win.frame == f or win.frame == f2, "frame set reused from the pool")
Check(win.frame:GetAlpha() == 1 and drivers[win.frame] == "[combat] hide;show" and #bm.GetEntries(1) == 2, "enabled again: visible, driver, entries")
win.bg._mouse = nil
win:ApplyMouse()
Check(win.bg._mouse == true, "mouse on the background enabled again")
-- outside of combat: driver removed immediately
local f3 = win.frame
win:Disable()
Check(drivers[f3] == nil, "outside of combat: driver removed immediately")
win:Enable()
bm.db.windows[1].visWindow = nil
bm.db.windows[1].visCondition = nil
win:Apply()

---------------------------------------------------------------------------
-- finding 3: aura restriction – frozen lists do not warn, weapons do
---------------------------------------------------------------------------
ENCHANTS[16] = { remainingTimeMs = 600000, chargesRemaining = 0 }
QN_TOOLTIP[16] = { "Klinge", "Sofortgift (10 Min)" }
FireEvent("WEAPON_ENCHANT_CHANGED")
QN_AURAS_SECRET = true
FireEvent("UNIT_AURA", "player") RunTimers()
-- dispelled during the restriction; times remaining drop below the threshold (15 s)
table.remove(AURAS.player, 1)
SetTime(1090)
ENCHANTS[16] = { remainingTimeMs = 10000, chargesRemaining = 0 }
FireEvent("WEAPON_ENCHANT_CHANGED")
printed = {}
RunTickers()
Check(Count("Arkane Intelligenz") == 0 and Count("Segen der Macht") == 0, "restriction: no warning from frozen lists")
Check(#bm.Recast.list == 0 or (#bm.Recast.list == 1 and bm.Recast.list[1] == "Sofortgift"), "restriction: no aura in the recast list")
Check(Count("Sofortgift") == 1, "restriction: weapon enchant keeps warning")
-- restriction over, but not re-read yet: still no aura warning
QN_AURAS_SECRET = false
RunTickers()
Check(Count("Segen der Macht") == 0, "after the restriction before re-reading: no warning")
FireEvent("ADDON_RESTRICTION_STATE_CHANGED") RunTimers()
RunTickers()
Check(Count("Arkane Intelligenz") == 0, "dispelled spell: never warned")
Check(Count("Segen der Macht") == 1, "still present spell: warned after re-reading")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
