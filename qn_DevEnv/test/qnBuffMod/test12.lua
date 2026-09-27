-- Szenario 12: qnBuffMod – Tooltip-Mindestbreite, Waffenname nachgelesen (Warnung bleibt),
-- höchstens eine Warnung je Anwendung über einen Zielwechsel hinweg
local guids = { player = "Player-1", target = "Creature-A" }
function UnitGUID(unit) return guids[unit] end

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
local function Buff(name, dur, exp, extra)
	local a = { name = name, icon = 1, applications = 0, duration = dur, expirationTime = exp, sourceUnit = "player", spellId = #name, cancelable = true }
	for k, v in pairs(extra or {}) do a[k] = v end
	return a
end
AURAS.player = { Buff("Arkane Intelligenz", 1800, 2800) }
ENCHANTS[16] = { remainingTimeMs = 600000, chargesRemaining = 0 }
QN_TOOLTIP[16] = { "Klinge" }   -- Name der Verzauberung (noch) nicht lesbar
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

---------------------------------------------------------------------------
-- Befund 5: Mindestbreite zurücksetzen, wenn der Tooltip einem anderen gehört
---------------------------------------------------------------------------
local e
for _, it in ipairs(bm.GetEntries(1)) do if it.name == "Arkane Intelligenz" then e = it.entry end end
e._scripts.OnEnter(e)
Check(TOOLTIP.owner == e and TOOLTIP.minWidth == 180 and e._scripts.OnUpdate ~= nil, "Tooltip am Eintrag mit Mindestbreite")
GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
TOOLTIP.minWidth = 180   -- das Spiel behält die Mindestbreite über SetOwner hinweg
e._scripts.OnUpdate(e, 0.6)
Check(TOOLTIP.minWidth == 0 and e._scripts.OnUpdate == nil, "anderer Besitzer: Mindestbreite 0, Takt beendet")

---------------------------------------------------------------------------
-- Befund 4: Name der Waffenverzauberung nachgelesen – Zustand und Warnung bleiben
---------------------------------------------------------------------------
local st = bm.Weapons.slots[16].state
Check(bm.Weapons.slots[16].name == UNKNOWN and not st.known, "Name unbekannt")
SetTime(1590)   -- Restzeit 10 s, Schwelle 15 s
ENCHANTS[16] = { remainingTimeMs = 10000, chargesRemaining = 0 }
FireEvent("WEAPON_ENCHANT_CHANGED")
printed = {}
RunTickers()
Check(Count(UNKNOWN) == 1 and st.warned, "Warnung unter unbekanntem Namen")
QN_TOOLTIP[16] = { "Klinge", "Sofortgift (1 Min)" }
ENCHANTS[16] = { remainingTimeMs = 9000, chargesRemaining = 0 }
RunTickers()
local rec = bm.Weapons.slots[16]
Check(rec.name == "Sofortgift" and rec.state == st and st.warned and st.known, "Name nachgelesen: derselbe Zustand, weiterhin gewarnt")
Check(Count("Sofortgift") == 0 and Count(UNKNOWN) == 1, "keine zweite Warnung für dieselbe Verzauberung")
-- echte Erneuerung: Warnung zurückgesetzt
ENCHANTS[16] = { remainingTimeMs = 600000, chargesRemaining = 0 }
FireEvent("WEAPON_ENCHANT_CHANGED")
Check(not bm.Weapons.slots[16].state.warned, "Erneuerung setzt die Warnung zurück")
ENCHANTS[16] = nil
FireEvent("WEAPON_SLOT_CHANGED")

---------------------------------------------------------------------------
-- Befund 2: Zielwechsel und zurück – dieselbe Anwendung warnt nicht erneut
---------------------------------------------------------------------------
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
Check(bm.Auras.IsWatched("target"), "Ziel beobachtet")
local function Target(guid, auras)
	guids.target = guid
	AURAS.target = auras
	FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
end
SetTime(2000)
Target("Creature-A", { Buff("Zielsegen", 600, 2100, { auraInstanceID = 77 }) })
printed = {}
RunTickers()
Check(Count("Zielsegen") == 0, "über der Schwelle: keine Warnung")
SetTime(2090)
RunTickers()
Check(Count("Zielsegen") == 1, "unter der Schwelle: eine Warnung")
Target("Creature-B", {})
RunTickers()
Target("Creature-A", { Buff("Zielsegen", 600, 2100, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 1, "Zielwechsel und zurück: keine zweite Warnung")
-- ohne Aureninstanz (Schlüssel aus Name, Zauber-ID, Wirker) ebenso
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2100) })
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2100) })
RunTickers()
Check(Count("Zielsegen") == 2, "ohne Instanz: erste Warnung dieser Anwendung, dann keine weitere (" .. Count("Zielsegen") .. ")")
-- kleine Nachkorrektur des Ablaufs ist keine neue Anwendung
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2101, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 2, "Nachkorrektur nach Zielwechsel: keine neue Warnung")
-- andere Einheit mit derselben Aura: eigene Warnung
Target("Creature-C", { Buff("Zielsegen", 600, 2100, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 3, "andere Einheit: eigene Warnung")
-- während der Abwesenheit erneuert: neue Anwendung, warnt wieder unter der Schwelle
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2690, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 3, "erneuert: über der Schwelle keine Warnung")
SetTime(2680)
RunTickers()
Check(Count("Zielsegen") == 4, "erneuerte Anwendung: wieder eine Warnung")
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2690, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 4, "und nach Zielwechsel keine weitere")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
