-- Szenario 28: qnBuffMod – Waffenverzauberungen, Einheiten (Begleiter, Fokus, Fahrzeug), außer Reichweite,
-- Rechtsklick nur in Spielerfenstern
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, K, L = bm.enum, bm.kind, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
local reads = {}
local enchantReads = 0
local origEnchant = C_PaperDollInfo.GetTemporaryEnchantmentInfo
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function(slot) enchantReads = enchantReads + 1 return origEnchant(slot) end

AURAS.player = { { name = "Segen", icon = 1, applications = 0, duration = 600, expirationTime = 1500, sourceUnit = "player", spellId = 5, cancelable = true } }
ENCHANTS[16] = { remainingTimeMs = 1800000, chargesRemaining = 12 }
ENCHANTS[17] = { remainingTimeMs = 600000, chargesRemaining = 0 }
QN_TOOLTIP[16] = { "Klinge des Testers", "Haltbarkeit 50 / 50", "Sofortgift (30 Min)" }
QN_TOOLTIP[17] = { "Dolch" }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local origRead = bm.Auras.Read
bm.Auras.Read = function(unit) reads[unit] = (reads[unit] or 0) + 1 return origRead(unit) end
local function Names(id)
	local out = {}
	for _, e in ipairs(bm.GetEntries(id or 1)) do out[#out + 1] = e.name end
	return table.concat(out, ",")
end
local function Get(name, id)
	for _, e in ipairs(bm.GetEntries(id or 1)) do if e.name == name then return e end end
end

---------------------------------------------------------------------------
-- Waffen (Kriterium 43)
---------------------------------------------------------------------------
Check(Names() == "Sofortgift," .. UNKNOWN .. ",Segen", "Haupt- vor Nebenhand, Name aus der Tooltipzeile, sonst unbekannt: " .. Names())
local w = Get("Sofortgift")
Check(w.weapon and w.slot == 16 and w.countText == 12 and w.kind == K.ITEM and w.time == L["%d Minuten"]:format(30), "Aufladungen = Stapel, Restzeit")
-- unbekannter Name: jede Sekunde neu lesen; bekannter: alle 2 s
enchantReads = 0
RunTickers()
Check(enchantReads == 2, "unbekannter Name: jede Sekunde (" .. enchantReads .. ")")
QN_TOOLTIP[17] = { "Dolch", "Wundgift (10 Min)" }
RunTickers()
Check(Get("Wundgift") ~= nil, "Name nachgelesen")
enchantReads = 0
RunTickers() RunTickers()
Check(enchantReads == 2, "bekannter Name: alle 2 s (" .. enchantReads .. " Abfragen in 2 s)")
-- Restzeit unter 1 s ohne Tooltipzeile: zuletzt bekannter Name
ENCHANTS[17] = { remainingTimeMs = 500, chargesRemaining = 0 }
QN_TOOLTIP[17] = { "Dolch" }
FireEvent("WEAPON_ENCHANT_CHANGED")
Check(Get("Wundgift") ~= nil, "unter 1 s: zuletzt bekannter Name")
ENCHANTS[17] = nil
FireEvent("WEAPON_SLOT_CHANGED")
Check(Names() == "Sofortgift,Segen", "Nebenhand weg: " .. Names())
-- Dauer = größte gesehene Restzeit; gestiegene Restzeit = Erneuerung (Warnung zurückgesetzt)
ENCHANTS[16] = { remainingTimeMs = 50000, chargesRemaining = 12 }
FireEvent("WEAPON_ENCHANT_CHANGED")
w = Get("Sofortgift")
Check(w.rec.duration == 1800, "Dauer = größte gesehene Restzeit")
RunTickers()
local warned = 0
for _, m in ipairs(printed) do if m:find("Sofortgift", 1, true) then warned = warned + 1 end end
Check(warned == 1, "Warnung für die Waffenverzauberung")
ENCHANTS[16] = { remainingTimeMs = 1800000, chargesRemaining = 20 }
FireEvent("WEAPON_ENCHANT_CHANGED")
Check(not Get("Sofortgift").rec.state.warned, "gestiegene Restzeit: erneuert")
-- Waffen nur im Spielerfenster, nicht im Fahrzeug, nicht für andere Einheiten
clicks[ADD]()
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
AURAS.target = { { name = "Zielsegen", icon = 5, applications = 0, duration = 300, expirationTime = 1200, sourceUnit = "player", spellId = 9, cancelable = true } }
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
Check(Names(2) == "Zielsegen", "Zielfenster ohne Waffen: " .. Names(2))
AURAS.vehicle = { { name = "Panzerung", icon = 8, applications = 0, duration = 0, expirationTime = 0, spellId = 12 } }
FireEvent("UNIT_ENTERED_VEHICLE", "player")
Check(Names() == "Panzerung", "im Fahrzeug keine Waffen: " .. Names())

---------------------------------------------------------------------------
-- Rechtsklick nur in Spielerfenstern (Entscheidung 3)
---------------------------------------------------------------------------
local cancelled = 0
CancelUnitBuff = function() cancelled = cancelled + 1 end
C_CVar._v.ActionButtonUseKeyDown = "1"
local b = Get("Zielsegen", 2).entry
b._scripts.OnMouseDown(b, "RightButton")
b = Get("Panzerung").entry
b._scripts.OnMouseDown(b, "RightButton")
Check(cancelled == 0, "Ziel- und Fahrzeugfenster: Rechtsklick ohne Wirkung")
FireEvent("UNIT_EXITED_VEHICLE", "player")
b = Get("Segen").entry
b._scripts.OnMouseDown(b, "RightButton")
Check(cancelled == 1, "Spielerfenster: entfernt")
b = Get("Sofortgift").entry
b._scripts.OnMouseDown(b, "RightButton")
Check(cancelled == 1, "Waffenverzauberung nicht entfernbar")

---------------------------------------------------------------------------
-- Begleiter, Fokus, Fahrzeugausstieg (Kriterium 44)
---------------------------------------------------------------------------
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(2)
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.PET)
Check(not bm.Auras.IsWatched("target") and bm.Auras.IsWatched("pet"), "Ziel nicht mehr, Begleiter beobachtet")
AURAS.pet = { { name = "Knurren", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "pet", spellId = 2649 } }
FireEvent("UNIT_PET", "player") RunTimers()
Check(Names(2) == "Knurren", "UNIT_PET liest den Begleiter: " .. Names(2))
-- nach dem Verlassen eines Fahrzeugs: 20 s lang alle 2 s neu lesen
FireEvent("UNIT_ENTERED_VEHICLE", "player")
FireEvent("UNIT_EXITED_VEHICLE", "player")
reads.pet = 0
for _ = 1, 25 do RunTickers() end
Check(reads.pet == 10, "Begleiter nach Ausstieg 10 × neu gelesen (" .. tostring(reads.pet) .. ")")
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.FOCUS)
AURAS.focus = { { name = "Fokussegen", icon = 3, applications = 0, duration = 0, expirationTime = 0, spellId = 3 } }
FireEvent("PLAYER_FOCUS_CHANGED") RunTimers()
Check(Names(2) == "Fokussegen", "PLAYER_FOCUS_CHANGED liest den Fokus: " .. Names(2))
AURAS.focus = nil
FireEvent("PLAYER_FOCUS_CHANGED") RunTimers()
Check(Names(2) == "" and bm.GetWindow(2).frame:IsShown(), "kein Fokus: Fenster leer")

---------------------------------------------------------------------------
-- außer Reichweite (Kriterium 46)
---------------------------------------------------------------------------
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
SETTINGS.QNBUFFMOD_G_SORTMETHOD:SetValue(E.sort.TIME)
SETTINGS.QNBUFFMOD_FLASHTIME:SetValue(60)
AURAS.target = {
	{ name = "A-Segen", icon = 5, applications = 0, duration = 300, expirationTime = 1030, sourceUnit = "player", spellId = 9, cancelable = true },
	{ name = "B-Segen", icon = 6, applications = 0, duration = 300, expirationTime = 1200, sourceUnit = "player", spellId = 10, cancelable = true },
}
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
Check(Names(2) == "A-Segen,B-Segen" and Get("A-Segen", 2).flashing, "in Reichweite: nach Restzeit, blinkt")
AURAS.target[1].duration, AURAS.target[1].expirationTime = 0, 0
FireEvent("UNIT_AURA", "target") RunTimers()
local a = Get("A-Segen", 2)
Check(a.time == nil and not a.flashing and a.kind == K.BUFF, "außer Reichweite: kein Zeittext, kein Blinken, Typ bleibt")
Check(Names(2) == "B-Segen,A-Segen", "außer Reichweite: Sortierung sieht kein Ablauf: " .. Names(2))
AURAS.target[1].duration, AURAS.target[1].expirationTime = 300, 1030
FireEvent("UNIT_AURA", "target") RunTimers()
a = Get("A-Segen", 2)
Check(a.time ~= nil and a.kind == K.BUFF and a.rec.duration == 300 and Names(2) == "A-Segen,B-Segen", "zurück in Reichweite: Dauer und Typ neu")
-- Restzeit ≤ 0: blinkt nur in Reichweite
AURAS.target[1].expirationTime = 999
FireEvent("UNIT_AURA", "target") RunTimers()
Check(not Get("A-Segen", 2).flashing, "abgelaufen und außer Reichweite: kein Blinken")
UnitInRange = function() return true end
FireEvent("UNIT_AURA", "target") RunTimers()
Check(Get("A-Segen", 2).flashing, "abgelaufen in Reichweite: blinkt")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
