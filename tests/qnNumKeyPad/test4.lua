-- Scenario 4: qnNumKeyPad - "Mouse" page: mouse selection and button assignment of the
-- Logitech G502 (account-wide in global, defaults, G1/G2 fixed and disabled, sanitize on load,
-- independent of profile switches).

-- saved data of settings 1.0 with invalid leftovers in global
qnNumKeyPadProfiles = { settingsVersion = "1.0", global = {
	mice = { G502 = { G3 = "NUMPAD0", G4 = "", G1 = "NUMPAD1", G5 = "ENTER" }, Unknown = { G3 = "NUMPAD1" } },
}, profiles = { ["account:Raid"] = {} } }

local core = LoadAddon("qnCore")
local nkp = LoadAddon("qnNumKeyPad")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)

local global = qnNumKeyPadProfiles.global
Check(qnNumKeyPadProfiles.settingsVersion == "1.2", "settingsVersion 1.2: " .. tostring(qnNumKeyPadProfiles.settingsVersion))
Check(global.mouse == "NONE", "no mouse selected by default: " .. tostring(global.mouse))

---------------------------------------------------------------------------
-- Sanitize on load
---------------------------------------------------------------------------
local stored = global.mice.G502
Check(global.mice.Unknown == nil, "unknown mouse removed")
Check(stored.G3 == "NUMPAD0" and stored.G4 == "", "valid assignments kept (also \"no key\")")
Check(stored.G1 == nil, "fixed button G1 not stored")
Check(stored.G5 == nil, "non-numpad key dropped, default applies again")

---------------------------------------------------------------------------
-- Defaults (screenshot of Logitech G HUB)
---------------------------------------------------------------------------
local g502 = nkp.GetMouse("G502")
Check(g502 and g502.name == "Logitech G502" and #g502.buttons == 11, "G502 with buttons G1-G11")
local expected = { G3 = "NUMPAD3", G4 = "NUMPAD7", G5 = "NUMPAD8", G6 = "NUMPAD9", G7 = "NUMPAD5",
	G8 = "NUMPAD4", G9 = "NUMPAD6", G10 = "NUMPAD2", G11 = "NUMPAD1" }
local defaults = nkp.MouseDefaults(g502)
local same = true
for button, key in pairs(expected) do
	if defaults[button] ~= key then same = false end
end
for button in pairs(defaults) do
	if not expected[button] then same = false end
end
Check(same, "default assignment G3-G11 as in G HUB")
Check(nkp.MouseBinding(g502, "G5") == "NUMPAD8", "G5: default after sanitize")
Check(nkp.MouseBinding(g502, "G3") == "NUMPAD0", "G3: stored assignment")
Check(nkp.MouseBinding(g502, "G4") == nil, "G4: no key")
Check(nkp.MouseBinding(g502, "G1") == nil and nkp.MouseBinding(g502, "G2") == nil, "G1/G2 send no numpad key")

---------------------------------------------------------------------------
-- Options page
---------------------------------------------------------------------------
local device = SETTINGS.QNNKP_MOUSE
Check(device and device:GetValue() == "NONE", "mouse dropdown shows no mouse")
local g1, g3 = SETTINGS.QNNKP_G502_G1, SETTINGS.QNNKP_G502_G3
Check(g1 and SETTINGS.QNNKP_G502_G2 and SETTINGS.QNNKP_G502_G11, "controls for G1-G11")
Check(g3:GetValue() == "NUMPAD0" and SETTINGS.QNNKP_G502_G6:GetValue() == "NUMPAD9", "controls show stored value or default")

local initG1, initG3 = INITIALIZERS.QNNKP_G502_G1, INITIALIZERS.QNNKP_G502_G3
Check(initG1 and initG3, "initializers of G1 and G3 on the page")
Check(initG1.pred and not initG1.pred(), "G1 always disabled (no mouse)")
Check(initG3.pred and not initG3.pred(), "G3 disabled without mouse")
device:SetValue("G502")
Check(global.mouse == "G502", "mouse stored account-wide")
Check(not initG1.pred() and initG3.pred(), "G502 selected: G3 enabled, G1 stays disabled")
Check(#initG1.getOptions() == 1, "G1 offers only its fixed function")
Check(#initG3.getOptions() == 1 + #nkp.NUMPAD_KEYS, "G3 offers \"none\" plus all numpad keys")

g3:SetValue("NUMPADPLUS")
Check(stored.G3 == "NUMPADPLUS" and nkp.MouseBinding(g502, "G3") == "NUMPADPLUS", "G3 reassigned")
SETTINGS.QNNKP_G502_G7:SetValue("")
Check(stored.G7 == "" and nkp.MouseBinding(g502, "G7") == nil, "G7 without key")
g1:SetValue("fixed")
Check(stored.G1 == nil, "G1 stores nothing")

-- profile switch changes nothing about the mouse
SetEditModeLayout(4)
Check(global.mouse == "G502" and device:GetValue() == "G502" and g3:GetValue() == "NUMPADPLUS",
	"mouse settings independent of the profile")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
