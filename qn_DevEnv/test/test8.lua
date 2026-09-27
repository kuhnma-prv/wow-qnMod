-- Szenario 8: Secret-Values in Aurendaten. Secret-Werte sind Tabellen, bei denen jede
-- Rechnung, jeder Vergleich und jedes Verketten einen Fehler wirft (wie im Client).
local SecretMT = {}
local function boom() error("Operation mit Secret-Value", 2) end
for _, m in ipairs({ "__add", "__sub", "__mul", "__div", "__unm", "__lt", "__le", "__concat", "__len", "__index", "__call" }) do SecretMT[m] = boom end
local function Secret() return setmetatable({}, SecretMT) end
issecretvalue = function(v) return type(v) == "table" and getmetatable(v) == SecretMT end

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
local function Count(key)
	local n = 0
	for _, m in ipairs(printed) do if m == bm.L[key] then n = n + 1 end end
	return n
end

AURAS.player = {
	{ name = "Offen", icon = 1, applications = 0, duration = 600, expirationTime = 1500, sourceUnit = "player", spellId = 111, auraInstanceID = 1 },
	{ name = Secret(), icon = Secret(), applications = Secret(), duration = Secret(), expirationTime = Secret(), sourceUnit = Secret(), spellId = Secret(), auraInstanceID = 2 },
}
ENCHANTS[16] = { remainingTimeMs = Secret(), chargesRemaining = Secret(), enchantID = 5 }
QN_TOOLTIP[16] = { Secret() }
UnitName = function() return Secret() end
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(true, "Einloggen mit secret-Auren ohne Fehler")
local function Names()
	local out = {}
	for _, e in ipairs(bm.GetEntries(1)) do out[#out + 1] = e.weapon and ("W" .. e.slot) or e.name end
	return table.concat(out, ",")
end
Check(Names():find("Offen", 1, true) and Names():find("?", 1, true), "lesbare Aura und Platzhalter: " .. Names())
local entries = bm.GetEntries(1)
local ph
for _, e in ipairs(entries) do if e.name == "?" then ph = e end end
Check(ph and ph.rec.icon == bm.QUESTION_MARK and ph.time == nil and ph.countText == "", "Platzhalter: Fragezeichen, keine Restzeit, keine Stapel")
-- Waffe mit secret-Restzeit: verzaubert, Restzeit 0, Name unbekannt
local weapon
for _, e in ipairs(entries) do if e.weapon then weapon = e end end
Check(weapon and weapon.name == UNKNOWN and weapon.time == nil, "Waffe mit secret-Werten: Restzeit 0, Name unbekannt")
FireEvent("UNIT_AURA", "player") RunTimers()
Check(true, "UNIT_AURA mit secret-Auren ohne Fehler")
-- Tooltip und Warnprüfung mit secret-Namen
entries = bm.GetEntries(1)
for _, e in ipairs(entries) do
	e.entry._scripts.OnEnter(e.entry)
	e.entry._scripts.OnLeave(e.entry)
end
RunTickers()
Check(true, "Tooltips und Warnprüfung mit secret-Werten ohne Fehler")
-- ganze Rückgabe secret: Aura gilt als nicht vorhanden
local old = C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex = function() return Secret() end
FireEvent("UNIT_AURA", "player") RunTimers()
Check(#bm.GetEntries(1) == 1 and bm.GetEntries(1)[1].weapon, "komplett secret: keine Auren, keine Fehler")
C_UnitAuras.GetAuraDataByIndex = old
-- Waffenverzauberungsinfo komplett secret: unverzaubert
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function() return Secret() end
FireEvent("WEAPON_ENCHANT_CHANGED")
Check(#bm.GetEntries(1) == 0, "Waffeninfo secret: unverzaubert")
AURAS.player[2] = nil
FireEvent("UNIT_AURA", "player") RunTimers()
Check(Names() == "Offen", "zurück zu lesbaren Werten: " .. Names())
Check(Count("Der Client hält gerade Aurendaten zurück (secret). Betroffene Zauber erscheinen ohne Restzeit bzw. mit Fragezeichen.") == 1, "Hinweis auf secret-Felder genau einmal")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
