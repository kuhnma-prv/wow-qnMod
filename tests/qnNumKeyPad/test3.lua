-- Szenario 3: qnNumKeyPad – Tastenbelegung im sicheren Umfeld: folgt dem Sichtbarkeitstreiber
-- auch im Kampf (Fahrzeug, eigene Bedingung), Ein/Aus, Umschalttaste, Zusatztasten;
-- Stellvertreter beachtet „Aktion beim Drücken“ (CVar ActionButtonUseKeyDown); Haltungswechsel.

EnableRestrictedEnvironment()
SpellFlyout = CreateFrame("Frame", "SpellFlyout")
SpellFlyout:Hide()

-- Tasten wie ActionBarButtonTemplate: geschützt, RegisterForClicks("AnyUp", "LeftButtonDown",
-- "RightButtonDown"); OnClick behandelt jeden Klick als Mausklick (TriggerSecureClick mit
-- isSecureAction) und handelt nur beim Loslassen (SecureActionButton_OnClick).
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
-- Belegung
---------------------------------------------------------------------------
Check(Count() == 30 and BINDINGS[bar].NUMPAD1 == "qnNumKeyPadKey1:LeftButton" and BINDINGS[bar]["SHIFT-NUMPAD1"] == "qnNumKeyPadKey1:LeftButton",
	"Windows: 15 Tasten, je mit Umschalttaste, auf die Stellvertreter: " .. Count())
Check(qnNumKeyPadKey1:GetAttribute("type") == "click" and qnNumKeyPadKey1:GetAttribute("clickbutton") == qnNumKeyPadButton1,
	"Stellvertreter klickt die Taste")
Check(not qnNumKeyPadKey1:IsMouseEnabled(), "Stellvertreter fängt keine Maus ab")
Set("bindShift", false)
Check(Count() == 15 and BINDINGS[bar]["SHIFT-NUMPAD1"] == nil, "ohne Umschalttaste")
Set("bindShift", true)
Set("showArrow", true)
Check(Count() == 38 and BINDINGS[bar].RIGHT == "qnNumKeyPadKey26:LeftButton", "Pfeiltasten belegt")
Set("showArrow", false)
Check(Count() == 30 and BINDINGS[bar].RIGHT == nil, "Pfeiltasten wieder frei")

---------------------------------------------------------------------------
-- Befund 2: Aktion beim Loslassen bzw. beim Drücken
---------------------------------------------------------------------------
local down, up, name = Press("NUMPAD5")
Check(down == 0 and up == 1 and name == "qnNumKeyPadButton5", "CVar aus: Aktion beim Loslassen, einmal")
C_CVar._v.ActionButtonUseKeyDown = "1"
down, up, name = Press("NUMPAD5")
Check(down == 1 and up == 0 and name == "qnNumKeyPadButton5", "CVar an: Aktion beim Drücken, einmal")
down, up = Press("SHIFT-NUMPAD5")
Check(down == 1 and up == 0, "Umschalt+Taste ebenso")
C_CVar._v.ActionButtonUseKeyDown = "0"

---------------------------------------------------------------------------
-- Befund 5: Belegung folgt der Sichtbarkeit, auch im Kampf
---------------------------------------------------------------------------
Set("locked", true)   -- Treiber mit Bedingungen (hideVehicle ist Vorgabe)
Check(bar:IsShown() and Count() == 30, "gesperrt, kein Fahrzeug: sichtbar und belegt")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
QN_CONDITIONS.vehicleui = true
UpdateStateDrivers()
Check(not bar:IsShown() and Count() == 0 and not PressBinding("NUMPAD1", false), "im Kampf ins Fahrzeug: verborgen, Belegung aufgehoben")
QN_CONDITIONS.vehicleui = nil
UpdateStateDrivers()
Check(bar:IsShown() and Count() == 30, "im Kampf aus dem Fahrzeug: wieder belegt")
down, up = Press("NUMPAD2")
Check(up == 1, "Taste wirkt wieder")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")

Set("useCustom", true)
Set("custom", "[combat] show; hide")
Check(not bar:IsShown() and Count() == 0, "eigene Bedingung außerhalb des Kampfes: verborgen, keine Belegung")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
QN_CONDITIONS.combat = true
UpdateStateDrivers()
Check(bar:IsShown() and Count() == 30, "eigene Bedingung im Kampf: gezeigt und belegt")
QN_CONDITIONS.combat = nil
UpdateStateDrivers()
Check(not bar:IsShown() and Count() == 0, "Kampfende laut Bedingung: wieder aufgehoben")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Set("useCustom", false)
Check(bar:IsShown() and Count() == 30, "zurück zu den Schaltern: belegt")

-- Änderung am Layout im Kampf: aufgeschoben, Belegung bleibt bis dahin
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
Set("showNav", true)
Check(Count() == 30, "im Kampf: Belegung unverändert (aufgeschoben)")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(Count() == 42 and BINDINGS[bar].HOME == "qnNumKeyPadKey18:LeftButton", "nach dem Kampf mit Navigationstasten")
Set("showNav", false)

-- Aus/Ein
Set("enabled", false)
Check(not bar:IsShown() and Count() == 0, "aus: verborgen, keine Belegung")
QN_CONDITIONS.vehicleui = true
UpdateStateDrivers()
QN_CONDITIONS.vehicleui = nil
UpdateStateDrivers()
Check(Count() == 0, "aus: Treiber belegt nicht neu")
Set("enabled", true)
Check(bar:IsShown() and Count() == 30, "ein: gezeigt und belegt")

---------------------------------------------------------------------------
-- Haltungswechsel über _onstate-page (unverändert, jetzt im Nachbau ausgeführt)
---------------------------------------------------------------------------
Check(qnNumKeyPadButton1:GetAttribute("action") == 145, "eigener Platz: " .. tostring(qnNumKeyPadButton1:GetAttribute("action")))
Set("stance", true)
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
QN_CONDITIONS["bonusbar:1"] = true
UpdateStateDrivers()
Check(qnNumKeyPadButton1:GetAttribute("action") == 73 and qnNumKeyPadButton13:GetAttribute("action") == 157,
	"Haltung 1 im Kampf: Tasten 1-12 auf Seite 7, 13-24 eigene Plätze")
QN_CONDITIONS["bonusbar:1"] = nil
UpdateStateDrivers()
Check(qnNumKeyPadButton1:GetAttribute("action") == 145, "ohne Haltung: eigener Platz")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
