-- qnBuffMod: Aurenfenster für Stärkungs-, Schwächungszauber und Waffenverzauberungen.
-- Data: Namensraum, Werte der Auswahllisten, Vorgaben, Prüfung gespeicherter Werte, Umrechnung
-- älterer Profile.
--
-- Profil (qnCore.Profiles, ns.db):
--   { <allgemeine Einstellungen>, windows = { [Fenster-ID] = { <Fenster-Einstellungen, dünn>, position } } }

local ADDON, ns = ...
_G.qnBuffMod = ns

local lib = qnCore
lib.NewAddon(ns, ADDON)

ns.WINDOW_LIMIT = 10
ns.QUESTION_MARK = 134400   -- INV_Misc_QuestionMark
ns.WARN_SOUND = 569634      -- misdirection_impact_head

---------------------------------------------------------------------------
-- Werte der Auswahllisten (festgelegt durch die gespeicherten Einstellungen)
---------------------------------------------------------------------------

ns.enum = {
	unit = { PLAYER = 1, VEHICLE = 2, PET = 3, TARGET = 4, FOCUS = 5 },
	vis = { ALWAYS = 1, BASIC = 2, CUSTOM = 3 },
	font = { NORMAL = 1, SMALL = 2, LARGE = 3 },
	style = { BAR = 1, ICON = 2 },
	side = { DEFAULT = 1, LEFT = 2, RIGHT = 3 },
	justify = { DEFAULT = 1, LEFT = 2, RIGHT = 3, CENTER = 4 },
	timeAt = { DEFAULT = 1, LEFT = 2, RIGHT = 3, ABOVE = 4, BELOW = 5 },
	dataSide = { LEFT = 1, RIGHT = 2, ABOVE = 3, BELOW = 4, CENTER = 5 },
	group = { NONE = 1, DEBUFF = 2, CANCELABLE = 3, UNCANCELABLE = 4, ALLBUFFS = 5, WEAPONS = 6 },
	own = { FIRST = 1, LAST = 2, WITH = 3 },
	zero = { FIRST = 1, LAST = 2, WITH = 3, HIDE = 4, ONLY = 5 },
	sort = { NAME = 1, TIME = 2, INDEX = 3 },
}
local E = ns.enum

-- Einheit je unitType
ns.UNITS = { "player", "vehicle", "pet", "target", "focus" }

-- Aura-Filter je Zauberart (Gruppe); NOT_CANCELABLE gibt es in Forever nicht mehr
ns.FILTERS = {
	[E.group.DEBUFF] = "HARMFUL",
	[E.group.CANCELABLE] = "HELPFUL|CANCELABLE",
	[E.group.UNCANCELABLE] = "HELPFUL|!CANCELABLE",
	[E.group.ALLBUFFS] = "HELPFUL",
}

-- Aurentypen (Farben, Verhalten)
ns.kind = { BUFF = "BUFF", AURA = "AURA", DEBUFF = "DEBUFF", ITEM = "ITEM" }

-- Reihenfolge der Gruppierungen je groupByPriority: F = Filter, E = eigene, N = nicht ablaufende
ns.GROUP_ORDER = {
	{ "F", "E", "N" }, { "F", "N", "E" }, { "E", "F", "N" },
	{ "E", "N", "F" }, { "N", "F", "E" }, { "N", "E", "F" },
}

---------------------------------------------------------------------------
-- Vorgaben
---------------------------------------------------------------------------

-- Allgemein (oberste Ebene des Profils)
ns.defaults = {
	hideBlizzardBuffs = true,
	backgroundColor = { 0, 0, 0, 0.25 },
	bgColorBUFF = { 0.1, 0.4, 0.85, 0.5 },
	bgColorAURA = { 0.35, 0.8, 0.15, 0.5 },
	bgColorDEBUFF = { 1, 0, 0, 0.85 },
	bgColorITEM = { 0.75, 0.25, 1, 0.75 },
	flashTime = 15,
	enableExpiration = true,
	expirationCastOnly = false,
	expirationSound = true,
	expirationTime1 = 15,
	expirationTime2 = 60,
	expirationTime3 = 180,
	windows = {},
}

-- Je Fenster; gespeichert werden nur abweichende Werte
ns.windowDefaults = {
	-- Seite "Fenster"
	disableWindow = false,
	disableTooltips = false,
	lockWindow = false,
	clampWindow = true,
	unitType = E.unit.PLAYER,
	vehicleBuffs = true,
	visWindow = E.vis.ALWAYS,
	visHideInCombat = false,
	visHideNotCombat = false,
	visHideInVehicle = false,
	visHideNotVehicle = false,
	visCondition = "",
	-- Seite "Darstellung"
	showBackground = true,
	useCustomBackgroundColor = false,
	windowBackgroundColor = { 0, 0, 0, 0.25 },
	showBorder = false,
	userEdgeLeft = 0,
	userEdgeRight = 0,
	userEdgeTop = 0,
	userEdgeBottom = 0,
	layoutType = 5,
	wrapAfter = 1,
	maxWraps = 0,
	buffSpacing = 0,
	wrapSpacing = 0,
	fontSize = E.font.NORMAL,
	-- Seite "Knöpfe"
	buttonStyle = E.style.BAR,
	buffSize1 = 20,
	rightAlign1 = E.side.DEFAULT,
	colorCodeIcons1 = false,
	normalIconBorder1 = false,
	detailWidth1 = 245,
	colorBuffs1 = true,
	colorCodeBackground1 = false,
	showNames1 = true,
	colorCodeDebuffs1 = false,
	nameJustifyWithTime1 = E.justify.DEFAULT,
	nameJustifyNoTime1 = E.justify.DEFAULT,
	showTimers1 = true,
	durationFormat1 = 1,
	showDays1 = true,
	durationLocation1 = E.timeAt.DEFAULT,
	timeJustifyNoName1 = E.justify.DEFAULT,
	showBuffTimer1 = true,
	showTimerBackground1 = true,
	spacingOnLeft1 = 0,
	spacingOnRight1 = 0,
	buffSize2 = 20,
	colorCodeIcons2 = false,
	normalIconBorder2 = false,
	showTimers2 = true,
	durationFormat2 = 1,
	showDays2 = true,
	dataSide2 = E.dataSide.BELOW,
	spacingFromIcon2 = 0,
	-- Seite "Gruppierung"
	groupByPriority = 1,
	separateOwn = E.own.WITH,
	separateZero = E.zero.WITH,
	sortSeq1 = E.group.DEBUFF,
	sortSeq2 = E.group.WEAPONS,
	sortSeq3 = E.group.CANCELABLE,
	sortSeq4 = E.group.UNCANCELABLE,
	sortSeq5 = E.group.NONE,
	sortMethod = E.sort.NAME,
	sortDirection = false,
}

---------------------------------------------------------------------------
-- Gültige Werte
---------------------------------------------------------------------------

-- Auswahllisten: unbekannte Werte gelten als Vorgabe
local CHOICES = {
	unitType = 5, visWindow = 3, layoutType = 8, fontSize = 3, buttonStyle = 2, rightAlign1 = 3,
	nameJustifyWithTime1 = 4, nameJustifyNoTime1 = 4, timeJustifyNoName1 = 4, durationFormat1 = 5,
	durationFormat2 = 5, durationLocation1 = 5, dataSide2 = 5, groupByPriority = 6, separateOwn = 3,
	separateZero = 5, sortSeq1 = 6, sortSeq2 = 6, sortSeq3 = 6, sortSeq4 = 6, sortSeq5 = 6, sortMethod = 3,
}

-- Regler: Werte außerhalb werden auf den Bereich begrenzt
ns.RANGES = {
	userEdgeLeft = { 0, 100 }, userEdgeRight = { 0, 100 }, userEdgeTop = { 0, 100 }, userEdgeBottom = { 0, 100 },
	wrapAfter = { 1, 50 }, maxWraps = { 0, 50 }, buffSpacing = { 0, 200 }, wrapSpacing = { 0, 200 },
	buffSize1 = { 15, 45 }, buffSize2 = { 15, 45 }, detailWidth1 = { 0, 400 },
	spacingOnLeft1 = { 0, 50 }, spacingOnRight1 = { 0, 50 }, spacingFromIcon2 = { 0, 50 },
	-- allgemein
	flashTime = { 0, 60 }, expirationTime1 = { 0, 60 }, expirationTime2 = { 0, 180 }, expirationTime3 = { 0, 300 },
}
local RANGES = ns.RANGES

local function ValidColor(c)
	if type(c) ~= "table" then
		return false
	end
	for i = 1, 4 do
		if type(c[i]) ~= "number" then
			return false
		end
	end
	return true
end
ns.ValidColor = ValidColor

-- Ein gespeicherter Wert als gültiger Wert oder nil (= Vorgabe)
local function Checked(key, v, default)
	if v == nil then
		return nil
	end
	local kind = type(default)
	if kind == "boolean" then
		-- ältere Daten: 1 bzw. 0 statt true/false
		if v == 1 then
			return true
		elseif v == 0 then
			return false
		end
		if type(v) == "boolean" then
			return v
		end
		return nil
	elseif kind == "number" then
		if type(v) ~= "number" then
			return nil
		end
		if CHOICES[key] then
			if v ~= math.floor(v) or v < 1 or v > CHOICES[key] then
				return nil
			end
			return v
		end
		local r = RANGES[key]
		if r then
			return math.max(r[1], math.min(r[2], v))
		end
		return v
	elseif kind == "string" then
		return type(v) == "string" and v or nil
	elseif kind == "table" then
		return ValidColor(v) and v or nil
	end
	return v
end

-- Wirksamer Wert eines Fensters (gespeichert oder Vorgabe)
function ns.WindowValue(t, key)
	local default = ns.windowDefaults[key]
	local v = Checked(key, t and t[key], default)
	if v == nil then
		return default
	end
	return v
end

-- Alle wirksamen Einstellungen eines Fensters als neue Tabelle
function ns.ResolveOptions(t)
	local o = {}
	for key in pairs(ns.windowDefaults) do
		o[key] = ns.WindowValue(t, key)
	end
	return o
end

-- Eine Zauberart steht nur in einem Gruppenplatz: spätere Doppel werden "keine".
-- Liefert true, wenn etwas geändert wurde.
local function DedupeGroups(t)
	local seen, changed = {}, false
	for i = 1, 5 do
		local key = "sortSeq" .. i
		local v = ns.WindowValue(t, key)
		if v ~= E.group.NONE then
			if seen[v] then
				t[key] = E.group.NONE
				changed = true
			end
			seen[v] = true
		end
	end
	return changed
end
ns.DedupeGroups = DedupeGroups

-- Gespeicherte Fenstertabelle bereinigen (beim Laden): ungültige Werte entfernen, Booleans
-- vereinheitlichen, Bereiche begrenzen, doppelte Gruppen auflösen.
local function SanitizeWindow(t)
	for key, default in pairs(ns.windowDefaults) do
		if t[key] ~= nil then
			t[key] = Checked(key, t[key], default)
		end
	end
	local p = t.position
	if p ~= nil and not (type(p) == "table" and type(p[1]) == "string" and type(p[3]) == "string"
		and type(p[4]) == "number" and type(p[5]) == "number") then
		t.position = nil
	end
	DedupeGroups(t)
end

-- Allgemeine Werte bereinigen (fehlende ergänzt qnCore danach aus den Vorgaben)
local function SanitizeGeneral(db)
	for key, default in pairs(ns.defaults) do
		if key ~= "windows" and db[key] ~= nil then
			db[key] = Checked(key, db[key], default)
		end
	end
	if db.windows ~= nil and type(db.windows) ~= "table" then
		db.windows = nil
	end
end

---------------------------------------------------------------------------
-- Umrechnung älterer Profile
-- Ältere Profile hatten die Fenster verschachtelt unter einem alten Schlüssel; sie werden einmalig in
-- das flache Format übernommen, danach löscht qnCore den alten Schlüssel (obsolete).
---------------------------------------------------------------------------

local Upgrade, OBSOLETE
do
	local OLD = "windowOptionsList"
	OBSOLETE = { OLD }

	function Upgrade(db)
		local old = db[OLD]
		if db.windows == nil and type(old) == "table" then
			local windows = {}
			for id, entry in pairs(old) do
				if type(id) == "number" and id >= 1 and id == math.floor(id) then
					local list = type(entry) == "table" and entry.primaryOptionsList
					local src = type(list) == "table" and list[1]
					windows[id] = type(src) == "table" and CopyTable(src) or {}
				end
			end
			db.windows = windows
		end
		SanitizeGeneral(db)
		if type(db.windows) == "table" then
			for id, t in pairs(db.windows) do
				if type(id) ~= "number" then
					db.windows[id] = nil
				elseif type(t) ~= "table" then
					db.windows[id] = {}
				else
					SanitizeWindow(t)
				end
			end
		end
	end
end

-- Anmeldung beim Profilsystem (aus Core.lua im ADDON_LOADED)
function ns.RegisterStore(onSwitch)
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnBuffModDB",
		defaults = ns.defaults,
		upgrade = Upgrade,
		obsolete = OBSOLETE,
		onSwitch = onSwitch,
	})
	return ns.store
end
