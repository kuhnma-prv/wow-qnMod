-- Scenario 3: qnNumKeyPad - key bindings in the restricted environment: follow the visibility driver
-- also in combat (vehicle, custom condition), on/off, Shift key, extra keys;
-- proxy respects "cast on key down" (CVar ActionButtonUseKeyDown); stance change.

EnableRestrictedEnvironment()
SpellFlyout = CreateFrame("Frame", "SpellFlyout")
SpellFlyout:Hide()

-- Keys like ActionBarButtonTemplate: protected, RegisterForClicks("AnyUp", "LeftButtonDown",
-- "RightButtonDown"); OnClick treats every click as a mouse click (TriggerSecureClick with
-- isSecureAction) and acts only on release (SecureActionButton_OnClick).
local used = {}
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
	local f = create(kind, name, parent, template, ...)
	if template == "ActionBarButtonTemplate" then
		f._protected = true
		f._clicks = { "AnyUp", "LeftButtonDown", "RightButtonDown" }
		f._scripts.OnClick = function(self, button, down)
			if not down then used[#used + 1] = self:GetName() end
		end
	end
	return f
end
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
local function Count()
	local n = 0
	for _ in pairs(BINDINGS[bar] or {}) do n = n + 1 end
	return n
end
local function Press(key)
	used = {}
	PressBinding(key, true)
	local down = #used
	PressBinding(key, false)
	return down, #used - down, used[1]
end

---------------------------------------------------------------------------
-- Bindings
---------------------------------------------------------------------------
Check(Count() == 30 and BINDINGS[bar].NUMPAD1 == "qnNumKeyPadKey1:LeftButton" and BINDINGS[bar]["SHIFT-NUMPAD1"] == "qnNumKeyPadKey1:LeftButton",
	"Windows: 15 keys, each with Shift, bound to the proxies: " .. Count())
Check(qnNumKeyPadKey1:GetAttribute("type") == "click" and qnNumKeyPadKey1:GetAttribute("clickbutton") == qnNumKeyPadButton1,
	"proxy clicks the key")
Check(not qnNumKeyPadKey1:IsMouseEnabled(), "proxy does not catch the mouse")
Set("bindShift", false)
Check(Count() == 15 and BINDINGS[bar]["SHIFT-NUMPAD1"] == nil, "without Shift")
Set("bindShift", true)
Set("showArrow", true)
Check(Count() == 38 and BINDINGS[bar].RIGHT == "qnNumKeyPadKey26:LeftButton", "arrow keys bound")
Set("showArrow", false)
Check(Count() == 30 and BINDINGS[bar].RIGHT == nil, "arrow keys free again")

---------------------------------------------------------------------------
-- Finding 2: action on release or on key down
---------------------------------------------------------------------------
local down, up, name = Press("NUMPAD5")
Check(down == 0 and up == 1 and name == "qnNumKeyPadButton5", "CVar off: action on release, once")
C_CVar._v.ActionButtonUseKeyDown = "1"
down, up, name = Press("NUMPAD5")
Check(down == 1 and up == 0 and name == "qnNumKeyPadButton5", "CVar on: action on key down, once")
down, up = Press("SHIFT-NUMPAD5")
Check(down == 1 and up == 0, "Shift+key likewise")
C_CVar._v.ActionButtonUseKeyDown = "0"

---------------------------------------------------------------------------
-- Finding 5: bindings follow visibility, also in combat
---------------------------------------------------------------------------
Set("locked", true)   -- driver with conditions (hideVehicle is default)
Check(bar:IsShown() and Count() == 30, "locked, no vehicle: visible and bound")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
QN_CONDITIONS.vehicleui = true
UpdateStateDrivers()
Check(not bar:IsShown() and Count() == 0 and not PressBinding("NUMPAD1", false), "into vehicle in combat: hidden, bindings cleared")
QN_CONDITIONS.vehicleui = nil
UpdateStateDrivers()
Check(bar:IsShown() and Count() == 30, "out of vehicle in combat: bound again")
down, up = Press("NUMPAD2")
Check(up == 1, "key works again")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")

Set("useCustom", true)
Set("custom", "[combat] show; hide")
Check(not bar:IsShown() and Count() == 0, "custom condition out of combat: hidden, no bindings")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
QN_CONDITIONS.combat = true
UpdateStateDrivers()
Check(bar:IsShown() and Count() == 30, "custom condition in combat: shown and bound")
QN_CONDITIONS.combat = nil
UpdateStateDrivers()
Check(not bar:IsShown() and Count() == 0, "end of combat per condition: cleared again")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Set("useCustom", false)
Check(bar:IsShown() and Count() == 30, "back to the switches: bound")

-- Layout change in combat: deferred, bindings stay until then
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
Set("showNav", true)
Check(Count() == 30, "in combat: bindings unchanged (deferred)")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(Count() == 42 and BINDINGS[bar].HOME == "qnNumKeyPadKey18:LeftButton", "after combat with navigation keys")
Set("showNav", false)

-- Off/on
Set("enabled", false)
Check(not bar:IsShown() and Count() == 0, "off: hidden, no bindings")
QN_CONDITIONS.vehicleui = true
UpdateStateDrivers()
QN_CONDITIONS.vehicleui = nil
UpdateStateDrivers()
Check(Count() == 0, "off: driver does not rebind")
Set("enabled", true)
Check(bar:IsShown() and Count() == 30, "on: shown and bound")

---------------------------------------------------------------------------
-- Stance change via _onstate-page (unchanged, now executed in the emulation)
---------------------------------------------------------------------------
Check(qnNumKeyPadButton1:GetAttribute("action") == 145, "own slot: " .. tostring(qnNumKeyPadButton1:GetAttribute("action")))
Set("stance", true)
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
QN_CONDITIONS["bonusbar:1"] = true
UpdateStateDrivers()
Check(qnNumKeyPadButton1:GetAttribute("action") == 73 and qnNumKeyPadButton13:GetAttribute("action") == 157,
	"stance 1 in combat: keys 1-12 on page 7, 13-24 own slots")
QN_CONDITIONS["bonusbar:1"] = nil
UpdateStateDrivers()
Check(qnNumKeyPadButton1:GetAttribute("action") == 145, "without stance: own slot")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
