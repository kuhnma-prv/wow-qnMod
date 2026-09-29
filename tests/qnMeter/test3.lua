-- Szenario 3: qnMeter – Warnung bei verborgenem Fenster (Taktgeber unabhängig vom Fenster, kein
-- Sammeln ohne Bedarf), keine Warnung ohne echten Tank-Eintrag, TPS-Verlauf je Gegner (Zielwechsel,
-- Obergrenze, Leeren nach dem Kampf), Überblenden des Größenanfassers nur nach Betreten/Verlassen.

SOUNDKIT = SOUNDKIT or { RAID_WARNING = 8959 }

-- Einheiten: Token -> { id, name, class, guid, player, hostile }
QN_UNITS = {}
QN_THREAT = {}      -- Gegner-GUID -> id -> { value, isTanking }
QN_PARTY = 0
QN_THREAT_CALLS = 0
local function Units(mobGUID)
	QN_UNITS = {
		player = { id = "player", name = "Tester", class = "WARRIOR", guid = "Player-1", player = true },
		party1 = { id = "party1", name = "Tanko", class = "WARRIOR", guid = "Party-1", player = true },
		target = { id = "mob", name = "Eber", guid = mobGUID, hostile = true },
	}
end
function UnitExists(u) return QN_UNITS[u] ~= nil end
function UnitName(u) local d = QN_UNITS[u] return d and d.name or "Tester" end
function UnitClass(u) local d = QN_UNITS[u] return "x", d and d.class or "WARRIOR" end
function UnitGUID(u) local d = QN_UNITS[u] return d and d.guid or (u == "player" and "Player-1" or nil) end
function UnitIsPlayer(u) local d = QN_UNITS[u] return d and d.player or false end
function UnitPlayerControlled(u) return UnitIsPlayer(u) end
function UnitCanAttack(_, u) local d = QN_UNITS[u] return d and d.hostile or false end
function UnitIsUnit(a, b) return a == b end
function IsInGroup() return QN_PARTY > 0 end
function IsInRaid() return false end
function GetNumSubgroupMembers() return QN_PARTY end
function UnitDetailedThreatSituation(u, mob)
	QN_THREAT_CALLS = QN_THREAT_CALLS + 1
	local d, m = QN_UNITS[u], QN_UNITS[mob]
	local list = m and QN_THREAT[m.guid]
	local t = d and list and list[d.id]
	if not t then return nil end
	return t.isTanking or false, t.isTanking and 3 or 0, t.value / 10, t.value / 10, t.value
end
C_Item.IsItemInRange = function() return true end

Units("Mob-A")
QN_PARTY = 1
QN_THREAT = { ["Mob-A"] = { party1 = { value = 1000, isTanking = true }, player = { value = 500 } } }

LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local L = meter.L
local T = meter.Threat
local f = T.frame
local db = meter.db

local warn
rawset(RaidWarningFrame, "AddMessage", function(_, text) warn = text end)
local function Tick() T.driver._scripts.OnUpdate(T.driver, 1) end
local function Right(i) return f.bars[i] and f.bars[i]._shown and f.bars[i].right._text end
local function Left(i) return f.bars[i] and f.bars[i]._shown and f.bars[i].left._text end
local function MyRow()
	for i = 1, #f.bars do
		local text = Left(i)
		if text and text:find("Tester", 1, true) then return i end
	end
end

---------------------------------------------------------------------------
-- Befund 1: Warnung auch bei verborgenem Fenster
---------------------------------------------------------------------------
Check(f:IsShown() and T.driver:IsShown(), "sichtbares Fenster: Taktgeber läuft")

-- Sichtbarkeit "nur in Gruppe", allein, Warnung auch allein
QN_PARTY = 0
meter.store:Set("warnSolo", true)
meter.store:Set("showMode", 3)
Check(not f:IsShown(), "allein mit 'nur in Gruppe': Fenster verborgen")
Check(not T.driver:IsShown(), "verborgen außerhalb des Kampfes: Taktgeber aus")
QN_THREAT_CALLS = 0
T.Refresh()
Check(QN_THREAT_CALLS == 0, "verborgen ohne Bedarf: nichts gesammelt")

-- Kampf: Taktgeber an, Warnung trotz verborgenem Fenster (Tank = NPC als Ziel des Gegners)
QN_UNITS.targettarget = { id = "party1", name = "Tanko", class = "WARRIOR", guid = "Party-1", player = true }
QN_UNITS.party1 = nil
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
Check(not f:IsShown() and T.driver:IsShown(), "im Kampf, Fenster verborgen: Taktgeber läuft")
QN_THREAT["Mob-A"].player.value = 950
warn = nil
Tick()
Check(warn == L["Bedrohung: %d%%"]:format(95), "verborgenes Fenster: Warnung ausgelöst: " .. tostring(warn))

-- Neu scharf schalten (Kampfende) mit niedrigem Wert, damit erst der Takt warnt
local function Rearm()
	QN_THREAT["Mob-A"].player.value = 500
	FireEvent("PLAYER_REGEN_ENABLED")
	QN_COMBAT = true
	FireEvent("PLAYER_REGEN_DISABLED")
end

-- Fenster über "shown" ausgeschaltet, in Gruppe
QN_PARTY = 1
Units("Mob-A")
meter.store:Set("showMode", 1)
meter.store:Set("warnSolo", false)
meter.store:Set("shown", false)
Check(not f:IsShown() and T.driver:IsShown(), "shown=false im Kampf: Taktgeber läuft")
Rearm()
QN_THREAT["Mob-A"].player.value = 950
warn = nil
Tick()
Check(warn ~= nil, "shown=false: Warnung trotzdem: " .. tostring(warn))

-- Warnung aus und Fenster aus: nichts sammeln
meter.store:Set("warnEnabled", false)
Check(not T.driver:IsShown(), "Warnung aus, Fenster aus: Taktgeber aus")
QN_THREAT_CALLS = 0
T.Refresh()
Check(QN_THREAT_CALLS == 0, "Warnung aus, Fenster aus: nichts gesammelt")
meter.store:Set("warnEnabled", true)
meter.store:Set("shown", true)
Check(f:IsShown(), "Fenster wieder da")

---------------------------------------------------------------------------
-- Befund 2: ohne echten Tank-Eintrag keine Warnung
---------------------------------------------------------------------------
Rearm()
QN_THREAT["Mob-A"].party1.isTanking = nil
QN_THREAT["Mob-A"].party1.value = 400
QN_THREAT["Mob-A"].player.value = 950
warn = nil
T.Refresh()
Check(warn == nil, "kein Tank-Eintrag, eigener Wert am höchsten: keine Warnung: " .. tostring(warn))
Check(Right(MyRow()) ~= nil and Right(MyRow()):find("100%", 1, true), "Anzeige bleibt: Bezug = höchster Wert: " .. tostring(Right(MyRow())))
QN_THREAT["Mob-A"].party1.isTanking = true
QN_THREAT["Mob-A"].party1.value = 1000
T.Refresh()
Check(warn == L["Bedrohung: %d%%"]:format(95), "mit Tank-Eintrag: Warnung: " .. tostring(warn))

---------------------------------------------------------------------------
-- Befund 4: TPS-Verlauf je Gegner
---------------------------------------------------------------------------
SetTime(2000)
meter.store:Set("warnEnabled", false)
QN_THREAT["Mob-A"].player.value = 1000
FireEvent("PLAYER_REGEN_ENABLED")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
T.Refresh()
SetTime(2005)
QN_THREAT["Mob-A"].player.value = 1500
T.Refresh()
Check(Right(MyRow()):find("(100)", 1, true), "TPS auf A: " .. tostring(Right(MyRow())))

-- kurz auf Gegner B
QN_THREAT["Mob-B"] = { party1 = { value = 300, isTanking = true }, player = { value = 200 } }
QN_UNITS.target.guid = "Mob-B"
SetTime(2006)
T.Refresh()
Check(Right(MyRow()):find("(0)", 1, true), "B: eigener Verlauf beginnt neu: " .. tostring(Right(MyRow())))

-- zurück auf A: Verlauf von A noch da (10 s: 1000 -> 2000)
QN_UNITS.target.guid = "Mob-A"
SetTime(2010)
QN_THREAT["Mob-A"].player.value = 2000
T.Refresh()
Check(Right(MyRow()):find("(100)", 1, true), "zurück auf A: Verlauf erhalten: " .. tostring(Right(MyRow())))

-- Obergrenze: fünf weitere Gegner verdrängen A
for i = 1, 5 do
	local guid = "Mob-X" .. i
	QN_THREAT[guid] = { party1 = { value = 300, isTanking = true }, player = { value = 100 } }
	QN_UNITS.target.guid = guid
	T.Refresh()
end
QN_UNITS.target.guid = "Mob-A"
SetTime(2011)
QN_THREAT["Mob-A"].player.value = 2100
T.Refresh()
Check(Right(MyRow()):find("(0)", 1, true), "mehr als 5 Gegner: ältester Verlauf verworfen: " .. tostring(Right(MyRow())))

-- nach dem Kampf geleert
SetTime(2015)
QN_THREAT["Mob-A"].player.value = 2500
T.Refresh()
Check(Right(MyRow()):find("(100)", 1, true), "A wieder mit Verlauf: " .. tostring(Right(MyRow())))
QN_COMBAT = nil
FireEvent("PLAYER_REGEN_ENABLED")
SetTime(2015.5)   -- weniger als 1 s nach dem neuen Anfang: TPS 0
QN_THREAT["Mob-A"].player.value = 2600
T.Refresh()
Check(Right(MyRow()):find("(0)", 1, true), "nach dem Kampf: Verlauf geleert: " .. tostring(Right(MyRow())))

---------------------------------------------------------------------------
-- Befund 7: Größenanfasser nur nach Betreten/Verlassen überblenden
---------------------------------------------------------------------------
local fade = f.hoverFade
for _, region in ipairs({ f, f.settingsButton, f.resizeButton }) do
	Check(region._scripts.OnEnter and region._scripts.OnLeave, "Betreten/Verlassen angemeldet")
end
Check(not fade:IsShown(), "ohne Mausbewegung: kein Überblenden je Frame")
local mouseOver = false
f.IsMouseOver = function() return mouseOver end
f.resizeButton:SetAlpha(0)
mouseOver = true
f._scripts.OnEnter(f)
Check(fade:IsShown(), "Betreten: Überblender läuft")
fade._scripts.OnUpdate(fade, 0.1)
Check(f.resizeButton:GetAlpha() > 0 and f.resizeButton:GetAlpha() < 1 and fade:IsShown(), "blendet weich ein")
fade._scripts.OnUpdate(fade, 0.3)
Check(f.resizeButton:GetAlpha() == 1 and not fade:IsShown(), "eingeblendet, Überblender hält an")
-- Maus auf den Knopf (Fenster meldet Verlassen, liegt aber noch darüber): bleibt sichtbar
f._scripts.OnLeave(f)
fade._scripts.OnUpdate(fade, 0.1)
Check(f.resizeButton:GetAlpha() == 1 and not fade:IsShown(), "auf dem Knopf: bleibt eingeblendet")
-- vom Knopf nach draußen
mouseOver = false
f.settingsButton._scripts.OnLeave(f.settingsButton)
Check(fade:IsShown(), "Verlassen über den Knopf: Überblender läuft")
fade._scripts.OnUpdate(fade, 0.3)
Check(f.resizeButton:GetAlpha() == 0 and not fade:IsShown(), "ausgeblendet, Überblender hält an")
-- Größe ändern und außerhalb loslassen
f.resizeButton._scripts.OnMouseDown(f.resizeButton)
f.resizeButton._scripts.OnMouseUp(f.resizeButton)
Check(fade:IsShown(), "nach dem Ziehen: Überblender prüft erneut")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
