-- Szenario 5: qnBuffMod – Blizzards Aurenfenster ausblenden, Sichtbarkeitsbedingungen, "Bedingung prüfen"
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
-- Blizzards Aurenfenster (Kriterium 35)
---------------------------------------------------------------------------
Check(not BuffFrame:IsShown() and not DebuffFrame:IsShown(), "Vorgabe: BuffFrame und DebuffFrame ausgeblendet")
BuffFrame:Show()
Check(not BuffFrame:IsShown(), "erneutes Einblenden sofort rückgängig")
BuffFrame.Hide = function() end   -- überschriebene Hide-Methode
BuffFrame:Show()
Check(not BuffFrame:IsShown(), "auch mit überschriebenem Hide ausgeblendet")
BuffFrame.Hide = nil
SETTINGS.QNBUFFMOD_HIDEBLIZZARDBUFFS:SetValue(false)
Check(BuffFrame:IsShown() and DebuffFrame:IsShown(), "aus: beide wieder eingeblendet")
DebuffFrame:Hide()   -- von jemand anderem ausgeblendet
SETTINGS.QNBUFFMOD_HIDEBLIZZARDBUFFS:SetValue(true)
Check(not BuffFrame:IsShown(), "an: BuffFrame ausgeblendet")
SETTINGS.QNBUFFMOD_HIDEBLIZZARDBUFFS:SetValue(false)
Check(BuffFrame:IsShown() and not DebuffFrame:IsShown(), "aus: nur selbst ausgeblendete wieder gezeigt")
Check(BuffFrame._points == nil and DebuffFrame._points == nil, "Blizzard-Rahmen nie verschoben")

---------------------------------------------------------------------------
-- Sichtbarkeit (Kriterium 36)
---------------------------------------------------------------------------
local win = bm.GetWindow(1)
local function Last() return drivers[#drivers] end
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.BASIC)
Check(Last()[1] == "reg" and Last()[2] == win.frame and Last()[3] == "visibility" and Last()[4] == "show", "Standardbedingungen ohne Schalter: show")
SETTINGS.QNBUFFMOD_W_VISHIDEINCOMBAT:SetValue(true)
SETTINGS.QNBUFFMOD_W_VISHIDENOTCOMBAT:SetValue(true)
SETTINGS.QNBUFFMOD_W_VISHIDEINVEHICLE:SetValue(true)
SETTINGS.QNBUFFMOD_W_VISHIDENOTVEHICLE:SetValue(true)
Check(Last()[4] == "[vehicleui]hide; [novehicleui]hide; [combat]hide; [nocombat]hide; show", "feste Reihenfolge: " .. tostring(Last()[4]))
SETTINGS.QNBUFFMOD_W_VISHIDENOTVEHICLE:SetValue(false)
SETTINGS.QNBUFFMOD_W_VISHIDENOTCOMBAT:SetValue(false)
Check(Last()[4] == "[vehicleui]hide; [combat]hide; show", "nur gesetzte Schalter: " .. tostring(Last()[4]))
win.frame:Hide()
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.ALWAYS)
Check(Last()[1] == "unreg" and Last()[2] == win.frame and win.frame:IsShown(), "Modus 1 entfernt den Treiber und zeigt das Fenster")

-- Erweiterte Bedingung über den Dialog
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.CUSTOM)
Check(Last()[4] == "show", "leere erweiterte Bedingung: show")
local text = ""
local editBox = { SetText = function(_, t) text = t end, GetText = function() return text end, SetFocus = function() end }
local dialog = { GetEditBox = function() return editBox end }
clicks[L["Bearbeiten …"]]()
Check(LAST_POPUP.which == "QNBUFFMOD_CONDITION" and LAST_POPUP.a1 == L["Fenster %d"]:format(1), "Dialog für Fenster 1")
StaticPopupDialogs.QNBUFFMOD_CONDITION.OnShow(dialog)
Check(text == "", "Dialog vorbelegt mit gespeichertem Text")
text = "[combat] hide\n\n[bonusbar:5] show;\n"
StaticPopupDialogs.QNBUFFMOD_CONDITION.OnAccept(dialog)
Check(bm.db.windows[1].visCondition == text, "Text gespeichert")
Check(Last()[1] == "reg" and Last()[4] == "[combat] hide;[possessbar] show", "Modus 3 nutzt den aufbereiteten Text: " .. tostring(Last()[4]))
StaticPopupDialogs.QNBUFFMOD_CONDITION.OnShow(dialog)
Check(text == bm.db.windows[1].visCondition, "Dialog zeigt den gespeicherten Text")

-- im Kampf erst danach (geschützter Zustandstreiber)
local n = #drivers
QN_COMBAT = true
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.BASIC)
Check(#drivers == n, "im Kampf kein neuer Treiber")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(#drivers == n + 1 and Last()[4] == "[vehicleui]hide; [combat]hide; show", "nach dem Kampf angewandt")

-- Einblenden liest die Auren neu
AURAS.player[2] = { name = "Neu", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "player", spellId = 6 }
win.frame:Hide()
win.frame:Show()
local names = {}
for _, e in ipairs(bm.GetEntries(1)) do names[#names + 1] = e.name end
Check(table.concat(names, ",") == "Segen,Neu", "Einblenden liest neu: " .. table.concat(names, ","))

---------------------------------------------------------------------------
-- Bedingung prüfen (Kriterium 37)
---------------------------------------------------------------------------
SETTINGS.QNBUFFMOD_W_VISWINDOW:SetValue(E.vis.CUSTOM)
local parsed
SecureCmdOptionParse = function(c) parsed = c return "hide", "target" end
printed = {}
clicks[L["Testen"]]()
Check(parsed == "[combat] hide;[possessbar] show", "geprüft wird die aufbereitete Bedingung")
Check(printed[1] == L["Bedingung: %s"]:format(parsed) and printed[2] == L["Ziel: %s"]:format("target")
	and printed[3] == L["Ergebnis: |cFF66FF66%s|r"]:format("hide"), "Bedingung, Ziel, Ergebnis ausgegeben")
SecureCmdOptionParse = function() return "blau", nil end
printed = {}
clicks[L["Testen"]]()
Check(#printed == 2 and printed[2] == L["Ungültiges Ergebnis: |cFFFF3333%s|r"]:format("blau"), "ungültiges Ergebnis, ohne Ziel")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
