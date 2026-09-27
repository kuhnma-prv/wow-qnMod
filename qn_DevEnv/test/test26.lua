-- Szenario 26: qnBuffMod – Ablaufwarnungen und Taste "Stärkungszauber erneuern"
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local overrides, cleared = {}, 0
function SetOverrideBindingClick(owner, prio, key, name) overrides[#overrides + 1] = { owner, prio, key, name } end
function ClearOverrideBindings() cleared = cleared + 1 end
local sounds = {}
function PlaySoundFile(id) sounds[#sounds + 1] = id end
local boundKey
function GetBindingKey(action) if action == "QNBUFFMOD_RECASTBUFFS" then return boundKey end end

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
local function Msg(name, sec)
	return L["Der Zauber |cFFFFFFFF%s|r läuft in |cFFFFFFFF%s|r ab."]:format(name, bm.FormatTime(sec, 1, true))
end
local function MsgKey(name, sec, key)
	return L["Der Zauber |cFFFFFFFF%s|r läuft in |cFFFFFFFF%s|r ab. Außerhalb des Kampfes |cFFFFFFFF%s|r drücken zum Erneuern."]:format(name, bm.FormatTime(sec, 1, true), key)
end
local function Has(text)
	for _, m in ipairs(printed) do if m == text then return true end end
	return false
end

-- GetTime() = 1000
local function Buff(name, dur, exp, caster, extra)
	local a = { name = name, icon = 1, applications = 0, duration = dur, expirationTime = exp, sourceUnit = caster or "player", spellId = #name, cancelable = true }
	for k, v in pairs(extra or {}) do a[k] = v end
	return a
end
AURAS.player = {
	Buff("Arkane Intelligenz", 600, 1010),      -- 2:00–10:00, Schwelle 15 s: warnt
	Buff("Segen der Macht", 1200, 1050),        -- 10:01–30:00, Schwelle 60 s: warnt
	Buff("Seelenstärke", 3600, 1170),           -- ab 30:01, Schwelle 180 s: warnt
	Buff("Kurz", 100, 1005),                    -- unter 2:00: nie
	Buff("Krumm", 1800.002, 1100),              -- zählt abgerundet als 30:00 (Schwelle 60): noch nicht
	Buff("Lang", 600, 1020),                    -- noch über der Schwelle
	Buff("Fluch", 600, 1005, "target", { isHarmful = true }),   -- Schwächungszauber: nie
}
boundKey = "F5"
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

---------------------------------------------------------------------------
-- Tastenbelegung (Kriterium 41)
---------------------------------------------------------------------------
local button = _G.QNBUFFMOD_RECASTBUFFFRAME
Check(button and button._template == "SecureActionButtonTemplate" and button:GetAttribute("type") == "spell" and button:GetAttribute("unit") == "player", "sicherer Knopf QNBUFFMOD_RECASTBUFFFRAME")
Check(#overrides == 1 and overrides[1][1] == button and overrides[1][3] == "F5" and overrides[1][4] == "QNBUFFMOD_RECASTBUFFFRAME", "Taste per Override auf den Knopf gelegt")
FireEvent("UPDATE_BINDINGS")
Check(#overrides == 1, "gleiche Belegung: nichts wiederholt")
Check(BINDING_HEADER_QNBUFFMOD == "qnBuffMod" and BINDING_NAME_QNBUFFMOD_RECASTBUFFS == L["Stärkungszauber erneuern"], "Tastenbelegung benannt")
-- ohne Warnung: eigene Aura mit der kürzesten Restzeit, die der Spieler wirken kann (Entscheidung 10)
Check(button:GetAttribute("spell") == "Kurz", "ohne Warnung: kürzeste eigene Aura: " .. tostring(button:GetAttribute("spell")))

---------------------------------------------------------------------------
-- Schwellen (Kriterium 38)
---------------------------------------------------------------------------
RunTickers()
Check(Has(MsgKey("Arkane Intelligenz", 10, "F5")), "Warnung Dauer 2:00–10:00 mit Taste")
Check(Has(MsgKey("Segen der Macht", 50, "F5")) and Has(MsgKey("Seelenstärke", 170, "F5")), "Warnungen 10:01–30:00 und ab 30:01")
Check(Count("Kurz") == 0 and Count("Fluch") == 0 and Count("Lang") == 0, "keine Warnung unter 2:00, für Schwächungszauber, über der Schwelle")
Check(Count("Krumm") == 0, "Dauer 1800,002 zählt als 30:00")
Check(#sounds == 3 and sounds[1] == 569634, "Ton 569634 je Warnung")
Check(button:GetAttribute("spell") == "Seelenstärke", "Knopf trägt den zuletzt eingereihten Zauber")
SETTINGS.QNBUFFMOD_EXPIRATIONTIME1:SetValue(0)
AURAS.player[#AURAS.player + 1] = Buff("Null", 300, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Count("Null") == 0, "Schwelle 0: keine Warnung")
AURAS.player[#AURAS.player] = nil
FireEvent("UNIT_AURA", "player") RunTimers()
SETTINGS.QNBUFFMOD_EXPIRATIONTIME1:SetValue(15)

---------------------------------------------------------------------------
-- Eine Warnung je Anwendung (Kriterium 39)
---------------------------------------------------------------------------
RunTickers()
Check(Count("Arkane Intelligenz") == 1, "zweiter Takt: keine zweite Warnung")
AURAS.player[1].expirationTime = 1011   -- kleine Nachkorrektur (mehr als 60 s unter voller Dauer)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Count("Arkane Intelligenz") == 1, "kleine Ablaufkorrektur warnt nicht erneut")
AURAS.player[1].expirationTime = 1600   -- echte Erneuerung
FireEvent("UNIT_AURA", "player") RunTimers()
Check(button:GetAttribute("spell") == "Seelenstärke", "Erneuerung nimmt den Zauber aus der Liste")
SetTime(1590)
RunTickers()
Check(Count("Arkane Intelligenz") == 2, "nach echter Erneuerung wieder eine Warnung")
SetTime(1000)
AURAS.player[1].expirationTime = 1010

---------------------------------------------------------------------------
-- nur wirkbare Zauber, Meldung mit Taste nur bei neuer Einreihung (Kriterium 40)
---------------------------------------------------------------------------
C_Spell.IsSpellUsable = function(name) if name == "Unwirkbar" then return false, false end return true, false end
SETTINGS.QNBUFFMOD_EXPIRATIONCASTONLY:SetValue(true)
AURAS.player[#AURAS.player + 1] = Buff("Unwirkbar", 600, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
local nSounds = #sounds
RunTickers()
Check(Count("Unwirkbar") == 0 and #sounds == nSounds, "nur wirkbare Zauber: nicht wirkbarer übergangen, kein Ton")
SETTINGS.QNBUFFMOD_EXPIRATIONCASTONLY:SetValue(false)
SETTINGS.QNBUFFMOD_EXPIRATIONSOUND:SetValue(false)
-- zwei gleichnamige Auren im selben Takt: die zweite ist nicht neu eingereiht
AURAS.player[#AURAS.player + 1] = Buff("Doppel", 600, 1005, "player")
AURAS.player[#AURAS.player + 1] = Buff("Doppel", 600, 1006, "party1")
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Has(MsgKey("Doppel", 5, "F5")) and Has(Msg("Doppel", 6)), "neu eingereiht mit Taste, schon eingereiht ohne")
Check(#sounds == nSounds, "ohne Ton-Option kein Ton")
-- ohne belegte Taste: Meldung ohne Taste
boundKey = nil
AURAS.player[#AURAS.player + 1] = Buff("Ohne Taste", 600, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Has(Msg("Ohne Taste", 5)), "ohne Belegung: Meldung ohne Taste")
FireEvent("UPDATE_BINDINGS")
Check(cleared >= 2 and #overrides == 1, "ohne Belegung: Overrides entfernt")
boundKey = "F5"
FireEvent("UPDATE_BINDINGS")

---------------------------------------------------------------------------
-- Erneuern-Taste (Kriterium 41)
---------------------------------------------------------------------------
local list = bm.Recast.list
local top = list[#list]
Check(button:GetAttribute("spell") == top, "Knopf trägt den zuletzt eingereihten: " .. tostring(top))
button._scripts.PostClick(button, "LeftButton", true)   -- Drücken zählt nicht (ActionButtonUseKeyDown aus)
Check(list[#list] == top, "nur die auslösende Tastenhälfte zählt")
local n = #list
button._scripts.PostClick(button, "LeftButton", false)
Check(#list == n - 1 and button:GetAttribute("spell") == list[#list], "gewirkt: aus der Liste, nächster am Knopf")
QN_COMBAT = true
local spell = button:GetAttribute("spell")
button._scripts.PostClick(button, "LeftButton", false)
Check(#list == n - 1, "im Kampf ändert die Taste die Liste nicht")
AURAS.player[#AURAS.player + 1] = Buff("Im Kampf", 600, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(list[#list] == "Im Kampf" and button:GetAttribute("spell") == spell, "im Kampf kein Wechsel des Zaubers am Knopf")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(button:GetAttribute("spell") == "Im Kampf", "nach dem Kampf gewechselt")
-- neu erscheinende Aura verlässt die Liste (per Name)
local idx
for i, a in ipairs(AURAS.player) do if a.name == "Im Kampf" then idx = i end end
table.remove(AURAS.player, idx)
FireEvent("UNIT_AURA", "player") RunTimers()
AURAS.player[#AURAS.player + 1] = Buff("Im Kampf", 600, 1600)
FireEvent("UNIT_AURA", "player") RunTimers()
Check(list[#list] ~= "Im Kampf", "neu erschienene Aura nicht mehr in der Liste")

---------------------------------------------------------------------------
-- Warnungen für andere Einheiten und Fahrzeug (Entscheidung 5)
---------------------------------------------------------------------------
clicks[ADD]()
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
AURAS.target = { Buff("Zielsegen", 600, 1008, "player") }
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
n = #list
RunTickers()
Check(Has(L["Der Zauber |cFFFFFFFF%s|r auf |cFFFFFFFF%s|r läuft in |cFFFFFFFF%s|r ab."]:format("Zielsegen", "Tester", bm.FormatTime(8, 1, true))), "Warnung für das Ziel nennt die Einheit")
Check(#list == n, "Zielauren kommen nicht in die Erneuerungsliste")
AURAS.vehicle = { Buff("Fahrzeugschild", 300, 1007, "vehicle") }
FireEvent("UNIT_ENTERED_VEHICLE", "player")
RunTickers()
Check(Count("Fahrzeugschild") == 1, "Warnung für Fahrzeugauren")
FireEvent("UNIT_EXITED_VEHICLE", "player")

---------------------------------------------------------------------------
-- Hinweise auf gesperrte Aurendaten je Sitzung einmal (Kriterium 60)
---------------------------------------------------------------------------
QN_AURAS_SECRET = true
FireEvent("UNIT_AURA", "player") RunTimers()
FireEvent("UNIT_AURA", "player") RunTimers()
QN_AURAS_SECRET = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
QN_AURAS_SECRET = true
FireEvent("UNIT_AURA", "player") RunTimers()
QN_AURAS_SECRET = false
FireEvent("ADDON_RESTRICTION_STATE_CHANGED") RunTimers()
Check(Count(L["Im Kampf hält der Client Aurendaten zurück. Die Fenster zeigen bis danach den letzten bekannten Stand."]) == 1, "Hinweis auf die Sperre genau einmal")
AURAS.player[1].locked = true
FireEvent("UNIT_AURA", "player") RunTimers()
FireEvent("UNIT_AURA", "player") RunTimers()
Check(Count(L["Der Client hält gerade Aurendaten zurück (secret). Betroffene Zauber erscheinen ohne Restzeit bzw. mit Fragezeichen."]) == 1, "Hinweis auf secret-Felder genau einmal")
-- Warnung abgeschaltet
AURAS.player[1].locked = nil
SETTINGS.QNBUFFMOD_ENABLEEXPIRATION:SetValue(false)
AURAS.player[#AURAS.player + 1] = Buff("Still", 600, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Count("Still") == 0, "Warnung im Chat aus: keine Meldung")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
