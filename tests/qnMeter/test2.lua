-- Szenario 2: qnMeter – Erfassung und Anzeige im normalen und im Secret-Modus (Ränge), isMe im Raid,
-- TPS und Warnung, Entfernungsprüfung im Kampf, Menü-Umschalter über store:Set, Kopplung an den
-- eingebauten Damage Meter, Titel, Zurücksetzen, Diagnose.

-- Secret-Values: Tabellen, die bei Rechnen, Vergleichen und Verketten einen Fehler werfen.
-- issecretvalue muss vor qnCore stehen (qnCore merkt es sich beim Laden).
local function Forbidden() error("Rechnen/Vergleichen mit einem secret-Wert", 2) end
local SecretMT = { __add = Forbidden, __sub = Forbidden, __mul = Forbidden, __div = Forbidden, __unm = Forbidden,
	__lt = Forbidden, __le = Forbidden, __eq = Forbidden, __concat = Forbidden, __len = Forbidden }
local function Secret(v) return setmetatable({ v = v }, SecretMT) end
issecretvalue = function(v) return getmetatable(v) == SecretMT end
AbbreviateLargeNumbers = function(v)
	if issecretvalue(v) then return v end
	return tostring(math.floor(v))
end
Enum.StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 }
SOUNDKIT = SOUNDKIT or { RAID_WARNING = 8959 }

-- Eingebauter Damage Meter (Blizzard_DamageMeter, DamageMeterMixin)
QN_DM = { barHeight = 30, spacing = 4, style = 1, textScale = 1.2, bgAlpha = 0.7, windowAlpha = 0.9, icons = false, classColor = true }
DamageMeter = {}
function DamageMeter:GetBarHeight() return QN_DM.barHeight end
function DamageMeter:SetBarHeight(v) QN_DM.barHeight = v end
function DamageMeter:GetBarSpacing() return QN_DM.spacing end
function DamageMeter:SetBarSpacing(v) QN_DM.spacing = v end
function DamageMeter:GetStyle() return QN_DM.style end
function DamageMeter:SetStyle(v) QN_DM.style = v end
function DamageMeter:GetTextScale() return QN_DM.textScale end
function DamageMeter:SetTextScale(v) QN_DM.textScale = v end
function DamageMeter:GetBackgroundAlpha() return QN_DM.bgAlpha end
function DamageMeter:SetBackgroundAlpha(v) QN_DM.bgAlpha = v end
function DamageMeter:GetWindowAlpha() return QN_DM.windowAlpha end
function DamageMeter:SetWindowAlpha(v) QN_DM.windowAlpha = v end
function DamageMeter:ShouldShowBarIcons() return QN_DM.icons end
function DamageMeter:SetShowBarIcons(v) QN_DM.icons = v end
function DamageMeter:ShouldUseClassColor() return QN_DM.classColor end
function DamageMeter:SetUseClassColor(v) QN_DM.classColor = v end

-- Einheiten: Token -> { id, name, class, guid, player, hostile, secretGUID }
QN_UNITS = {}
QN_THREAT = {}      -- id -> { value, scaled, isTanking }
QN_SECRET = nil     -- nil | "all" (alle Werte secret) | "state" (nur isTanking/status secret)
QN_PARTY, QN_RAID = 0, 0
local function Party()
	QN_UNITS = {
		player = { id = "player", name = "Tester", class = "WARRIOR", guid = "Player-1", player = true },
		party1 = { id = "party1", name = "Tanko", class = "WARRIOR", guid = "Party-1", player = true },
		party2 = { id = "party2", name = "Magier", class = "MAGE", guid = "Party-2", player = true },
		target = { id = "mob", name = "Eber", guid = "Mob-1", hostile = true },
		targettarget = { id = "party1", name = "Tanko", class = "WARRIOR", guid = "Party-1", player = true },
	}
	QN_PARTY, QN_RAID = 2, 0
end
function UnitExists(u) return QN_UNITS[u] ~= nil end
function UnitName(u) local d = QN_UNITS[u] return d and d.name or "Tester" end
function UnitClass(u) local d = QN_UNITS[u] return "x", d and d.class or "WARRIOR" end
function UnitGUID(u)
	local d = QN_UNITS[u]
	if not d then return u == "player" and "Player-1" or nil end
	return d.secretGUID and Secret(d.guid) or d.guid
end
function UnitIsPlayer(u) local d = QN_UNITS[u] return d and d.player or false end
function UnitPlayerControlled(u) return UnitIsPlayer(u) end
function UnitCanAttack(_, u) local d = QN_UNITS[u] return d and d.hostile or false end
function UnitIsUnit(a, b)
	local da, db = QN_UNITS[a], QN_UNITS[b]
	return (da and da.id or a) == (db and db.id or b)
end
function IsInGroup() return QN_PARTY > 0 or QN_RAID > 0 end
function IsInRaid() return QN_RAID > 0 end
function GetNumSubgroupMembers() return QN_PARTY end
function GetNumGroupMembers() return QN_RAID end
function UnitDetailedThreatSituation(u, mob)
	local d = QN_UNITS[u]
	local t = d and QN_THREAT[d.id]
	if not t then return nil end
	local isTanking, status, scaled, raw, value = t.isTanking or false, t.isTanking and 3 or 0, t.scaled, t.scaled, t.value
	if QN_SECRET == "all" then
		return Secret(isTanking), Secret(status), Secret(scaled), Secret(raw), Secret(value)
	elseif QN_SECRET == "state" then
		return Secret(isTanking), Secret(status), scaled, raw, value
	end
	return isTanking, status, scaled, raw, value
end
QN_NOW = 1000
function GetTime() return QN_NOW end
QN_RANGE_CALLS = 0
QN_IN_RANGE = true
C_Item.IsItemInRange = function() QN_RANGE_CALLS = QN_RANGE_CALLS + 1 return QN_IN_RANGE end

Party()
QN_THREAT = {
	party1 = { value = 1000, scaled = 100, isTanking = true },
	party2 = { value = 950, scaled = 95 },
	player = { value = 800, scaled = 80 },
}

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local L = meter.L
local T = meter.Threat
local f = T.frame
local db = meter.db

-- Meldungen der Warnung und im Chat mitschreiben
local warn
rawset(RaidWarningFrame, "AddMessage", function(_, text) warn = text end)
local chat = {}
local oldAdd = DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage = function(self, msg) chat[#chat + 1] = tostring(msg) oldAdd(self, msg) end
local function ChatHas(text)
	for _, m in ipairs(chat) do
		if m:find(text, 1, true) then return true end
	end
	return false
end

local function Left(i) return f.bars[i] and f.bars[i]._shown and f.bars[i].left._text end
local function Right(i) return f.bars[i] and f.bars[i]._shown and f.bars[i].right._text end

---------------------------------------------------------------------------
-- Titel, Texturen, Damage-Meter-Werte
---------------------------------------------------------------------------
Check(f.titleText._text == L["Threat"], "Titel gesetzt")
Check(meter.GetTexturePath("Damage Meter") == "UI-HUD-CoolDownManager-Bar", "Textur als Atlas ohne Präfix")
Check(meter.textureLabels["Damage Meter"] == DAMAGE_METER_LABEL, "Texturname über DAMAGE_METER_LABEL")
Check(db.linkDamageMeter and f.eff.linked and f.eff.barHeight == 30 and f.eff.barSpacing == 4, "Werte vom Damage Meter übernommen")

---------------------------------------------------------------------------
-- Normaler Modus: Sortierung, Ränge, Aggro-Balken, eigener Balken in der letzten Zeile
---------------------------------------------------------------------------
T.Refresh()
Check(f.infoText._text == "Eber", "Ziel rechts im Titel: " .. tostring(f.infoText._text))
Check(f.titleText._text == L["Threat"], "Titel bleibt")
-- Kapazität 3 (Höhe 150, Balken 30 + 4): Aggro, Tank, dann der eigene statt Magier
Check(Left(1) == L["Pull Aggro"], "Zeile 1: Aggro ohne Rang: " .. tostring(Left(1)))
Check(Left(2) == "1. Tanko", "Zeile 2: Tank mit Rang: " .. tostring(Left(2)))
Check(Left(3) == "3. Tester", "Zeile 3: eigener Balken mit echtem Rang: " .. tostring(Left(3)))
Check(not Left(4), "nicht mehr als 3 Zeilen")
Check(Right(1) == "1100 (110%)", "in Reichweite: Nahkampf-Schwelle: " .. tostring(Right(1)))
Check(QN_RANGE_CALLS > 0, "Entfernung außerhalb des Kampfes geprüft")

-- Bezugswert: der Tank, auch wenn ein anderer mehr hat; ohne Tank der höchste Wert
QN_THREAT.party1.isTanking, QN_THREAT.party2.isTanking = nil, true
T.Refresh()
Check(Right(1) == "1045 (110%)" and Left(2) == "1. Tanko", "Bezug = Tank (Magier 950): " .. tostring(Right(1)))
QN_THREAT.party2.isTanking = nil
T.Refresh()
Check(Right(1) == "1100 (110%)", "ohne Tank: Bezug = höchster Wert: " .. tostring(Right(1)))
QN_THREAT.party1.isTanking = true
-- ohne Aggro-Balken drei Spieler; ohne "eigenen Balken immer zeigen" kein Nachziehen
meter.store:Set("showAggroBar", false)
T.Refresh()
Check(Left(1) == "1. Tanko" and Left(2) == "2. Magier" and Left(3) == "3. Tester", "ohne Aggro-Balken: " .. tostring(Left(1)))
meter.store:Set("showAggroBar", true)
meter.store:Set("alwaysShowSelf", false)
T.Refresh()
Check(Left(1) == L["Pull Aggro"] and Left(3) == "2. Magier", "eigener Balken nicht nachgezogen: " .. tostring(Left(3)))
meter.store:Set("alwaysShowSelf", true)
T.Refresh()
Check(Left(3) == "3. Tester", "eigener Balken wieder in der letzten Zeile")

-- Im Kampf keine Entfernungsprüfung, Rückfall auf die Klasse (Krieger = Nahkampf)
QN_COMBAT = true
QN_IN_RANGE = false
QN_RANGE_CALLS = 0
T.Refresh()
Check(QN_RANGE_CALLS == 0, "im Kampf keine Entfernungsprüfung")
Check(Right(1) == "1100 (110%)", "im Kampf: Nahkampf über Klasse: " .. tostring(Right(1)))
QN_COMBAT = nil

-- Außerhalb des Kampfes und nicht in Reichweite: Fernkampf (130 %)
T.Refresh()
Check(Right(1) == "1300 (130%)", "außer Reichweite: Fernkampf-Schwelle: " .. tostring(Right(1)))
QN_IN_RANGE = nil

---------------------------------------------------------------------------
-- TPS und Warnung
---------------------------------------------------------------------------
QN_NOW = 1005
QN_THREAT.player.value = 1300
warn = nil
T.Refresh()
Check(Left(1) == "1. Tester" and Left(2) == L["Pull Aggro"], "eigener Balken jetzt vorne: " .. tostring(Left(1)))
Check(Right(1) == "1300 (100) 130%", "TPS über 5 Sekunden: " .. tostring(Right(1)))
Check(warn == L["Threat: %d%%"]:format(130), "Warnung ausgelöst: " .. tostring(warn))
warn = nil
T.Refresh()
Check(warn == nil, "Warnung nicht wiederholt")
QN_THREAT.player.value = 700
T.Refresh()
QN_THREAT.player.value = 1300
T.Refresh()
Check(warn ~= nil, "nach Unterschreiten erneut scharf")

---------------------------------------------------------------------------
-- Secret-Modus: keine Ränge, eigener Balken zuerst, nichts wird gerechnet
---------------------------------------------------------------------------
QN_THREAT.player.value = 800
-- Blizzards Widgets nehmen secret-Werte an; die Attrappe setzt dafür den inneren Wert ein.
for i = 1, 3 do
	local fs = f.bars[i].right
	fs.SetFormattedText = function(self, fmt, ...)
		local args = { ... }
		for k = 1, select("#", ...) do
			if issecretvalue(args[k]) then args[k] = args[k].v end
		end
		self._text = fmt:format(table.unpack(args, 1, select("#", ...)))
	end
	fs.SetText = function(self, v) self._text = issecretvalue(v) and tostring(v.v) or v end
end
QN_SECRET = "all"
warn = nil
local ok, err = pcall(T.Refresh)
Check(ok, "Secret-Modus ohne Fehler: " .. tostring(err))
Check(Left(1) == "Tester" and Left(2) == "Tanko" and Left(3) == "Magier", "Secret-Modus: Gruppenreihenfolge ohne Ränge, eigener zuerst: "
	.. tostring(Left(1)) .. ", " .. tostring(Left(2)) .. ", " .. tostring(Left(3)))
Check(Right(2) == "1000 (100%)", "Secret-Modus: Werte durchgereicht: " .. tostring(Right(2)))
Check(tostring(f.infoText._text):find("|cffffaa00", 1, true) ~= nil, "Secret-Modus: Ziel orange")
Check(warn == nil, "Secret-Modus: keine Warnung")

chat = {}
ok, err = pcall(SlashCmdList.QNMETER, "check")
Check(ok and ChatHas(L["Own values: secret (display runs in restricted mode)."]), "Diagnose mit secret-Werten: " .. tostring(err))

-- Nur der Status secret (Werte lesbar): Anzeige und Diagnose rechnen nicht mit dem Status
QN_SECRET = "state"
ok, err = pcall(T.Refresh)
Check(ok and Left(1) == "Tester", "nur Status secret: eingeschränkter Modus: " .. tostring(err or Left(1)))
chat = {}
ok, err = pcall(SlashCmdList.QNMETER, "check")
Check(ok and ChatHas(L["Own values: secret (display runs in restricted mode)."]), "Diagnose: secret-Status erkannt: " .. tostring(err))
QN_SECRET = nil

---------------------------------------------------------------------------
-- Raid mit secret-GUIDs: sich selbst über UnitIsUnit erkennen
---------------------------------------------------------------------------
QN_UNITS = {
	player = { id = "player", name = "Tester", class = "WARRIOR", guid = "Player-1", player = true },
	raid1 = { id = "party1", name = "Tanko", class = "WARRIOR", guid = "Party-1", player = true, secretGUID = true },
	raid2 = { id = "player", name = "Tester", class = "WARRIOR", guid = "Player-1", player = true, secretGUID = true },
	raid3 = { id = "party2", name = "Magier", class = "MAGE", guid = "Party-2", player = true, secretGUID = true },
	target = { id = "mob", name = "Eber", guid = "Mob-1", hostile = true },
	targettarget = { id = "party1", name = "Tanko", class = "WARRIOR", guid = "Party-1", player = true, secretGUID = true },
}
QN_PARTY, QN_RAID = 0, 3
T.Refresh()
Check(Left(3) == "3. Tester", "Raid: eigener Balken über UnitIsUnit erkannt: " .. tostring(Left(3)))
Check(Left(2) == "1. Tanko", "Raid: Zusatzziel ohne lesbare GUID nicht doppelt: " .. tostring(Left(2)))
Party()

---------------------------------------------------------------------------
-- Kein Ziel, Testmodus
---------------------------------------------------------------------------
QN_UNITS.target = nil
T.Refresh()
Check(f.infoText._text == "" and not Left(1), "ohne Ziel: leer")
Check(f.titleText._text == L["Threat"], "ohne Ziel: Titel bleibt")
T.SetTestMode(true)
Check(f.infoText._text == L["Test enemy"], "Testmodus: Testgegner")
Check(Left(1) == L["Pull Aggro"] and Left(2) == "1. Tankrok", "Testmodus: Ränge: " .. tostring(Left(2)))
T.SetTestMode(false)
Party()

---------------------------------------------------------------------------
-- Kontextmenü: Umschalter laufen über store:Set (Einstellungsfenster bekommt den Wert mit)
---------------------------------------------------------------------------
local items = {}
MenuUtil.CreateContextMenu = function(owner, gen)
	items = {}
	local root = {}
	function root:CreateTitle() end
	function root:CreateDivider() end
	function root:CreateCheckbox(text, isSel, setSel) items[text] = { isSel = isSel, set = setSel } end
	function root:CreateButton(text, fn) items[text] = { set = fn } end
	gen(owner, root)
end
local notified = {}
for _, key in ipairs({ "LOCKED", "USEFOCUS", "SHOWN" }) do
	SETTINGS["QNMETER_" .. key]:SetValueChangedCallback(function(_, v) notified[key] = v end)
end
f.OnMenu(f, f)
Check(items[L["Use focus target"]] ~= nil, "Menü: gleicher Text wie in den Optionen (Fokusziel bevorzugen)")
Check(items[LOCK_FRAME] and items[HIDE], "Menü: Sperren und Ausblenden vorhanden")
items[LOCK_FRAME].set()
Check(db.locked == true and notified.LOCKED == true, "Menü: Sperren über store:Set")
Check(f.resizeButton._shown == false, "gesperrt: Größenanfasser aus")
items[LOCK_FRAME].set()
Check(db.locked == false and notified.LOCKED == false and f.resizeButton._shown == true, "Menü: Entsperren über store:Set")
items[L["Use focus target"]].set()
Check(db.useFocus == true and notified.USEFOCUS == true and items[L["Use focus target"]].isSel() == true, "Menü: Fokus über store:Set")
items[L["Use focus target"]].set()
items[HIDE].set()
Check(db.shown == false and notified.SHOWN == false and not f:IsShown(), "Menü: Ausblenden über store:Set")
T.Toggle()
Check(db.shown == true and notified.SHOWN == true and f:IsShown(), "Toggle über store:Set")

---------------------------------------------------------------------------
-- Zurücksetzen wendet die Einstellungen genau einmal an
---------------------------------------------------------------------------
local applied = 0
local origApply = T.ApplySettings
T.ApplySettings = function(...) applied = applied + 1 return origApply(...) end
db.scale = 1.5
SlashCmdList.QNMETER("reset")
Check(applied == 1 and meter.db.scale == 1, "Zurücksetzen: einmal angewendet (" .. applied .. ")")
T.ApplySettings = origApply
db = meter.db

---------------------------------------------------------------------------
-- Damage-Meter-Kopplung: Setter im Bearbeitungsmodus wirken sofort, ohne Kopplung nicht
---------------------------------------------------------------------------
DamageMeter:SetBarHeight(20)
DamageMeter:SetBarSpacing(1)
RunTimers()
Check(f.eff.barHeight == 20 and f.eff.barSpacing == 1 and f.bars[1]._h == 20, "Damage Meter geändert: übernommen")
meter.store:Set("linkDamageMeter", false)
Check(not f.eff.linked and f.eff.barHeight == db.barHeight, "ohne Kopplung: eigene Balkenhöhe")
DamageMeter:SetBarHeight(35)
RunTimers()
Check(f.eff.barHeight == db.barHeight, "ohne Kopplung: Damage Meter ignoriert")
meter.store:Set("linkDamageMeter", true)
Check(f.eff.barHeight == 35, "Kopplung wieder an: aktueller Wert")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
