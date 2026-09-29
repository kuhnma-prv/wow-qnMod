-- Scenario 5: qnBuffMod – hide Blizzard's aura frames, visibility conditions, "Test condition"
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local drivers = {}
function RegisterStateDriver(f, state, cond) drivers[#drivers + 1] = { "reg", f, state, cond } end
function UnregisterStateDriver(f, state) drivers[#drivers + 1] = { "unreg", f, state } end

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, L = bm.enum, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end

AURAS.player = { { name = "Segen", icon = 1, applications = 0, duration = 600, expirationTime = 1500, sourceUnit = "player", spellId = 5, cancelable = true } }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

---------------------------------------------------------------------------
-- Blizzard's aura frames (criterion 35)
---------------------------------------------------------------------------
Check(not BuffFrame:IsShown() and not DebuffFrame:IsShown(), "default: BuffFrame and DebuffFrame hidden")
BuffFrame:Show()
Check(not BuffFrame:IsShown(), "showing again is undone immediately")
BuffFrame.Hide = function() end   -- overridden Hide method
BuffFrame:Show()
Check(not BuffFrame:IsShown(), "hidden even with overridden Hide")
BuffFrame.Hide = nil
SETTINGS.QNBUFFMOD_HIDEBLIZZARDBUFFS:SetValue(false)
Check(BuffFrame:IsShown() and DebuffFrame:IsShown(), "off: both shown again")
DebuffFrame:Hide()   -- hidden by someone else
SETTINGS.QNBUFFMOD_HIDEBLIZZARDBUFFS:SetValue(true)
Check(not BuffFrame:IsShown(), "on: BuffFrame hidden")
SETTINGS.QNBUFFMOD_HIDEBLIZZARDBUFFS:SetValue(false)
Check(BuffFrame:IsShown() and not DebuffFrame:IsShown(), "off: only self-hidden ones shown again")
Check(BuffFrame._points == nil and DebuffFrame._points == nil, "Blizzard frames never moved")

---------------------------------------------------------------------------
-- visibility (criterion 36)
---------------------------------------------------------------------------
local win = bm.GetWindow(1)
local function Last() return drivers[#drivers] end
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.BASIC)
Check(Last()[1] == "reg" and Last()[2] == win.frame and Last()[3] == "visibility" and Last()[4] == "show", "standard conditions without switches: show")
SETTINGS.QNBUFFMOD_W_VISHIDEINCOMBAT:SetValue(true)
SETTINGS.QNBUFFMOD_W_VISHIDENOTCOMBAT:SetValue(true)
SETTINGS.QNBUFFMOD_W_VISHIDEINVEHICLE:SetValue(true)
SETTINGS.QNBUFFMOD_W_VISHIDENOTVEHICLE:SetValue(true)
Check(Last()[4] == "[vehicleui]hide; [novehicleui]hide; [combat]hide; [nocombat]hide; show", "fixed order: " .. tostring(Last()[4]))
SETTINGS.QNBUFFMOD_W_VISHIDENOTVEHICLE:SetValue(false)
SETTINGS.QNBUFFMOD_W_VISHIDENOTCOMBAT:SetValue(false)
Check(Last()[4] == "[vehicleui]hide; [combat]hide; show", "only set switches: " .. tostring(Last()[4]))
win.frame:Hide()
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.ALWAYS)
Check(Last()[1] == "unreg" and Last()[2] == win.frame and win.frame:IsShown(), "mode 1 removes the driver and shows the window")

-- advanced condition via the dialog
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.CUSTOM)
Check(Last()[4] == "show", "empty advanced condition: show")
local text = ""
local editBox = { SetText = function(_, t) text = t end, GetText = function() return text end, SetFocus = function() end }
local dialog = { GetEditBox = function() return editBox end }
clicks[L["Edit …"]]()
Check(LAST_POPUP.which == "QNBUFFMOD_CONDITION" and LAST_POPUP.a1 == L["Window %d"]:format(1), "dialog for window 1")
StaticPopupDialogs.QNBUFFMOD_CONDITION.OnShow(dialog)
Check(text == "", "dialog prefilled with saved text")
text = "[combat] hide\n\n[bonusbar:5] show;\n"
StaticPopupDialogs.QNBUFFMOD_CONDITION.OnAccept(dialog)
Check(bm.db.windows[1].visCondition == text, "text saved")
Check(Last()[1] == "reg" and Last()[4] == "[combat] hide;[possessbar] show", "mode 3 uses the prepared text: " .. tostring(Last()[4]))
StaticPopupDialogs.QNBUFFMOD_CONDITION.OnShow(dialog)
Check(text == bm.db.windows[1].visCondition, "dialog shows the saved text")

-- in combat only afterwards (protected state driver)
local n = #drivers
QN_COMBAT = true
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.BASIC)
Check(#drivers == n, "no new driver in combat")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(#drivers == n + 1 and Last()[4] == "[vehicleui]hide; [combat]hide; show", "applied after combat")

-- showing re-reads the auras
AURAS.player[2] = { name = "Neu", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "player", spellId = 6 }
win.frame:Hide()
win.frame:Show()
local names = {}
for _, e in ipairs(bm.GetEntries(1)) do names[#names + 1] = e.name end
Check(table.concat(names, ",") == "Segen,Neu", "showing re-reads: " .. table.concat(names, ","))

---------------------------------------------------------------------------
-- test condition (criterion 37)
---------------------------------------------------------------------------
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.CUSTOM)
local parsed
SecureCmdOptionParse = function(c) parsed = c return "hide", "target" end
printed = {}
clicks[L["Test"]]()
Check(parsed == "[combat] hide;[possessbar] show", "the prepared condition is tested")
Check(printed[1] == L["Condition: %s"]:format(parsed) and printed[2] == L["Target: %s"]:format("target")
	and printed[3] == L["Result: |cFF66FF66%s|r"]:format("hide"), "condition, target, result printed")
SecureCmdOptionParse = function() return "blau", nil end
printed = {}
clicks[L["Test"]]()
Check(#printed == 2 and printed[2] == L["Invalid result: |cFFFF3333%s|r"]:format("blau"), "invalid result, without target")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
