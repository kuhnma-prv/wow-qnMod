-- Scenario 2: qnNumKeyPad - drag lock securely wrapped (no SetScript on Blizzard's OnDragStart,
-- lock also in combat), anchor change in combat (bar does not jump after combat), fading
-- sets the opacity only on change, no own UpdateFlyout call.

EnableRestrictedEnvironment()
SpellFlyout = CreateFrame("Frame", "SpellFlyout")
SpellFlyout:Hide()

-- Keys like ActionBarButtonTemplate: protected (inherits SecureActionButtonTemplate), Blizzard's
-- OnDragStart picks up the action; record own SetScript calls and UpdateFlyout
local picked, setScripts, flyoutUpdates = {}, {}, 0
local created = {}
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
	local f = create(kind, name, parent, template, ...)
	created[#created + 1] = f
	if template == "ActionBarButtonTemplate" then
		f._protected = true
		f._scripts.OnDragStart = function(self) picked[#picked + 1] = self:GetName() end
		f.UpdateFlyout = function() flyoutUpdates = flyoutUpdates + 1 end
		local setScript = f.SetScript
		f.SetScript = function(self, s, fn)
			setScripts[#setScripts + 1] = s
			setScript(self, s, fn)
		end
	end
	return f
end
QN_MODIFIED = false
function IsModifiedClick(what) return what == "PICKUPACTION" and QN_MODIFIED end
function UnitAffectingCombat(unit) return unit == "player" and QN_COMBAT or false end

local core = LoadAddon("qnCore")
local nkp = LoadAddon("qnNumKeyPad")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local bar = nkp.bar
local function Set(key, value)
	SETTINGS["QNNKP_" .. key:upper()]:SetValue(value)
end
local function Combat(on)
	QN_COMBAT = on
	FireEvent(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
end

---------------------------------------------------------------------------
-- Finding 1: drag lock
---------------------------------------------------------------------------
local b1 = qnNumKeyPadButton1
local function Drag()
	picked = {}
	b1:GetScript("OnDragStart")(b1, "LeftButton")
	return #picked == 1
end
local hasSetScript = false
for _, s in ipairs(setScripts) do
	if s == "OnDragStart" then hasSetScript = true end
end
Check(not hasSetScript, "no SetScript(\"OnDragStart\") on the keys")
Check(WRAPPED[b1] and WRAPPED[b1].OnDragStart and WRAPPED[b1].OnDragStart.header == bar, "OnDragStart securely wrapped, header = bar")
Check(nkp.db.lockActions == false and nkp.db.lockInCombat == true, "defaults: locked only in combat")
Check(Drag(), "out of combat: Blizzard's handler picks up")
Combat(true)
Check(not Drag(), "in combat: locked")
QN_MODIFIED = true
Check(Drag(), "in combat with the 'pick up action' key: Blizzard's handler picks up")
QN_MODIFIED = false
Set("lockInCombat", false)   -- deferred in combat (attribute of the bar)
Check(not Drag(), "change in combat takes effect only after combat")
Combat(false)
Combat(true)
Check(Drag(), "lockInCombat off: free in combat")
Combat(false)
Set("lockActions", true)
Check(not Drag(), "lockActions: locked out of combat")
QN_MODIFIED = true
Check(Drag(), "lockActions with the 'pick up action' key: free")
QN_MODIFIED = false
Set("lockActions", false)
Set("lockInCombat", true)
Check(Drag(), "reset: free out of combat")

---------------------------------------------------------------------------
-- Finding 3: anchor change in combat
---------------------------------------------------------------------------
bar.GetLeft = function() return 100 end
bar.GetBottom = function() return 200 end
Set("point", "TOPLEFT")
Check(nkp.db.x == 100 and nkp.db.y == -643, ("converted immediately out of combat (%s, %s)"):format(nkp.db.x, nkp.db.y))
local placed = {}
local setPoint = bar.SetPoint
bar.SetPoint = function(self, p, rel, rp, x, y)
	placed[#placed + 1] = { p, x, y }
	return setPoint(self, p, rel, rp, x, y)
end
Combat(true)
Set("scale", 1.1)            -- waits before the anchor change (ns.Apply)
Set("point", "BOTTOMRIGHT")
Check(#placed == 0 and nkp.db.x == 100 and nkp.db.y == -643, "in combat: bar untouched, offsets still old")
Combat(false)
local jumped = false
for _, p in ipairs(placed) do
	if p[1] == "BOTTOMRIGHT" and p[2] == 100 then jumped = true end
end
local last = placed[#placed]
Check(not jumped, "not set with new anchor and old offsets after combat")
-- SetPoint in bar units (scale 1.1): offsets divided by the scale
Check(nkp.db.x == -1629 and nkp.db.y == 200 and last and last[1] == "BOTTOMRIGHT"
	and math.abs(last[2] - -1629 / 1.1) < 1e-6 and math.abs(last[3] - 200 / 1.1) < 1e-6,
	("converted and set after combat (%s, %s)"):format(nkp.db.x, nkp.db.y))
Set("scale", 1)
nkp.ResetPosition()

---------------------------------------------------------------------------
-- Finding 6: fading, UpdateFlyout
---------------------------------------------------------------------------
local fader
for _, f in ipairs(created) do
	if f:GetScript("OnUpdate") and f:GetParent() == nil and f:GetScript("OnShow") then
		fader = f
	end
end
Check(fader ~= nil, "fade frame found")
local alphas = {}
local setAlpha = bar.SetAlpha
bar.SetAlpha = function(self, a)
	alphas[#alphas + 1] = a
	setAlpha(self, a)
end
Set("locked", true)
Set("fadeAlpha", 0.25)
Set("fade", true)
alphas = {}
local tick = fader:GetScript("OnUpdate")
for _ = 1, 5 do
	AdvanceTime(0.1)
	tick(fader, 0.1)
end
Check(#alphas == 1 and alphas[1] == 0.25, "opacity set only once: " .. #alphas)
Set("fadeAlpha", 0.5)
alphas = {}
tick(fader, 0.1)
tick(fader, 0.1)
Check(#alphas == 1 and alphas[1] == 0.5, "new value: set once")
Set("fade", false)
Check(bar:GetAlpha() == 1, "full opacity without fading")
Set("fade", true)
alphas = {}
tick(fader, 0.1)
Check(#alphas == 1 and alphas[1] == 0.5, "set again after switching on again")

flyoutUpdates = 0
Set("flyout", "DOWN")
nkp.ApplyAll()
Check(flyoutUpdates == 0 and b1:GetAttribute("flyoutDirection") == "DOWN", "no own UpdateFlyout call, direction as attribute")
Check(b1.Border:IsShown() == false, "UpdateLook without action check")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
