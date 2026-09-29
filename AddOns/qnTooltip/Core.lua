-- qnTooltip: anpassbare Tooltips (Aussehen, Position, Einheiten-Zeilen aus Bausteinen,
-- Lebensbalken, Ziel, Gegenstandsstufe, IDs).
-- Core: Namensraum, Vorgaben, Bausteine der Einheiten-Zeilen, Medien, Zeilenhilfen, Laden, Slash.

local ADDON, ns = ...
_G.qnTooltip = ns

local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L
local IsSecret = ns.IsSecret

---------------------------------------------------------------------------
-- Bausteine der Einheiten-Zeilen
-- Je Einheitenart eine Liste { Schlüssel, Anzeigename, Art, Vorgabe }. Art:
--   "icon"    Symbol: an/aus, Zeile, Reihenfolge, Filter
--   "text"    Text: dazu Farbe und Format (genau ein %s)
--   "number"  Zahl: Format mit %d oder %s
--   "fixed"   ohne eigene Zeile (NSC-Titel steht immer in Blizzards Titelzeile)
-- Farbe: Name einer Farbfunktion (ns.UnitData.COLORS) oder sechsstelliger Hexwert.
---------------------------------------------------------------------------

local function Icon(line, order, enable)
	return { enable = enable, line = line, order = order, filter = "none" }
end

local function Text(line, order, enable, color, format, filter)
	return { enable = enable, line = line, order = order, color = color, format = format, filter = filter or "none" }
end

ns.ELEMENTS = {
	player = {
		{ "friendIcon", L["Freundes-Symbol"], "icon", Icon(1, 1, true) },
		{ "raidIcon", L["Zielmarkierung"], "icon", Icon(1, 2, true) },
		{ "roleIcon", L["Rollen-Symbol"], "icon", Icon(1, 3, true) },
		{ "pvpIcon", L["PvP-Symbol"], "icon", Icon(1, 4, true) },
		{ "factionIcon", L["Fraktions-Symbol"], "icon", Icon(1, 5, true) },
		{ "classIcon", L["Klassen-Symbol"], "icon", Icon(1, 6, true) },
		{ "title", HONOR_REWARD_TITLE_TOOLTIP, "text", Text(1, 7, true, "ccffff", "%s") },
		{ "name", NAME, "text", Text(1, 8, true, "class", "%s") },
		{ "surname", L["Nachname"], "text", Text(1, 9, true, "class", "%s") },
		{ "realm", L["Realm"], "text", Text(1, 9, true, "00eeee", "%s") },
		{ "statusAFK", AFK, "text", Text(1, 10, true, "ffd200", "(%s)") },
		{ "statusDND", DND, "text", Text(1, 11, true, "ffd200", "(%s)") },
		{ "statusDC", PLAYER_OFFLINE, "text", Text(1, 12, true, "999999", "(%s)") },
		{ "guildName", GUILD, "text", Text(2, 1, true, "ff00ff", "<%s>") },
		{ "guildIndex", L["Gildenrang-Nummer"], "text", Text(2, 2, false, "cc88ff", "%s") },
		{ "guildRank", RANK, "text", Text(2, 3, true, "cc88ff", "(%s)") },
		{ "guildRealm", L["Realm der Gilde"], "text", Text(2, 4, true, "00cccc", "%s") },
		{ "levelValue", L["Stufe"], "text", Text(3, 1, true, "level", "%s") },
		{ "factionName", FACTION, "text", Text(3, 2, true, "faction", "%s") },
		{ "gender", L["Geschlecht"], "text", Text(3, 3, false, "999999", "%s") },
		{ "raceName", RACE, "text", Text(3, 4, true, "cccccc", "%s") },
		{ "className", CLASS, "text", Text(3, 5, true, "class", "%s") },
		{ "isPlayer", PLAYER, "text", Text(3, 6, false, "ffffff", "(%s)") },
		{ "role", ROLE, "text", Text(3, 7, false, "ffffff", "(%s)") },
		{ "moveSpeed", L["Bewegungstempo"], "number", Text(3, 8, false, "e8e7a8", "%d%%") },
		{ "itemLevel", STAT_AVERAGE_ITEM_LEVEL, "text", Text(4, 1, true, "ffffff", "%s") },
		{ "zone", ZONE, "text", Text(5, 1, false, "ffffff", "%s") },
	},
	npc = {
		{ "raidIcon", L["Zielmarkierung"], "icon", Icon(1, 1, true) },
		{ "classIcon", L["Klassen-Symbol"], "icon", Icon(1, 2, false) },
		{ "questIcon", L["Quest-Symbol"], "icon", Icon(1, 3, true) },
		{ "name", NAME, "text", Text(1, 4, true, "default", "%s") },
		{ "npcTitle", HONOR_REWARD_TITLE_TOOLTIP, "fixed", Text(0, 0, true, "99e8e8", "<%s>") },
		{ "levelValue", L["Stufe"], "text", Text(2, 1, true, "level", "%s") },
		{ "classifBoss", BOSS, "text", Text(2, 2, true, "ff0000", "(%s)") },
		{ "classifElite", ELITE, "text", Text(2, 3, true, "ffff33", "(%s)") },
		{ "classifRare", MAP_LEGEND_RARE, "text", Text(2, 4, true, "ffaaff", "(%s)") },
		{ "creature", L["Kreaturtyp"], "text", Text(2, 5, true, "selection", "%s") },
		{ "reactionName", REPUTATION, "text", Text(2, 6, true, "33ffff", "<%s>", "reaction6") },
		{ "moveSpeed", L["Bewegungstempo"], "number", Text(2, 7, false, "e8e7a8", "%d%%") },
	},
}

-- Vorgaben der Bausteine: { Schlüssel = Vorgabe }
local function ElementDefaults(list)
	local t = {}
	for _, e in ipairs(list) do
		t[e[1]] = e[4]
	end
	return t
end

-- Eintrag der Liste zu einem Schlüssel
function ns.Element(kind, key)
	for _, e in ipairs(ns.ELEMENTS[kind]) do
		if e[1] == key then
			return e
		end
	end
end

---------------------------------------------------------------------------
-- Vorgaben
-- Die Einstellungen der Einheitenarten liegen in player/npc (je eigene Seite).
---------------------------------------------------------------------------

ns.defaults = {
	-- Aussehen
	scale = 1,
	bgFile = "rock",
	bgColor = { 0, 0, 0, 0.7 },
	borderStyle = "default",     -- default | angular | none
	borderSize = 1,              -- nur "angular"
	borderColor = { 0.6, 0.6, 0.6, 0.8 },
	mask = true,                 -- heller Verlauf über der Kopfzeile
	headerFont = "default",
	headerSize = 0,              -- 0 = Blizzard-Größe
	headerFlag = "default",
	bodyFont = "default",
	bodySize = 0,
	bodyFlag = "default",
	moreTooltips = true,         -- auch ItemRef-, Vergleichs- und Freundes-Tooltip
	hideUnitFrameHint = true,    -- "Mit Rechtsklick die Rahmen-Einstellungen aufrufen" entfernen
	chatHover = true,            -- Tooltip beim Überfahren von Chat-Links
	modifierShowsAll = true,     -- Alt oder Strg: alle Bausteine zeigen

	-- Position (nur auf Wunsch: "blizzard" lässt Blizzard bzw. den Bearbeitungsmodus bestimmen)
	anchorMode = "blizzard",     -- blizzard | cursor | cursorRight | static
	anchorPoint = "BOTTOMRIGHT",
	anchorX = -60,
	anchorY = 120,
	returnInCombat = true,       -- im Kampf an Blizzards Stelle
	returnOnUnitFrame = false,   -- über Einheitenrahmen an Blizzards Stelle
	hideInCombat = false,
	combatModifier = "none",     -- none | alt | ctrl | shift: zeigt ausgeblendete Tooltips

	-- Lebensbalken
	barHide = false,
	barHeight = 4,
	barPosition = "bottom",      -- default | bottom | top
	barOffsetX = 0,              -- 0 = passend zum Rahmen
	barTexture = "Blizzard",
	barText = true,
	barPercent = true,
	barColor = "auto",           -- default | auto | smooth
	barFont = "default",
	barSize = 10,
	barFlag = "THINOUTLINE",

	-- Einheiten
	player = {
		borderColor = "class",
		bgColor = "class",
		bgAlpha = 0.9,
		anchorMode = "inherit",
		showTarget = true,
		showTargetBy = true,
		showModel = true,
		grayDead = false,
		bigFaction = true,
		elements = ElementDefaults(ns.ELEMENTS.player),
	},
	npc = {
		borderColor = "reaction",
		bgColor = "default",
		bgAlpha = 0.9,
		anchorMode = "inherit",
		showTarget = true,
		showTargetBy = true,
		showModel = true,
		grayDead = false,
		bigFaction = false,
		elements = ElementDefaults(ns.ELEMENTS.npc),
	},

	-- Gegenstände, Zauber, Quests
	itemBorder = true,
	itemIcon = true,
	itemId = true,
	itemIconId = true,
	itemMaxStack = true,
	spellIcon = true,
	spellId = true,
	spellIconId = true,
	spellBorderColor = { 0.6, 0.6, 0.6, 0.8 },
	spellBgColor = { 0, 0, 0, 0.8 },
	questBorder = true,
	questId = true,
	idsWithModifier = false,     -- IDs nur mit gedrückter Umschalt-, Strg- oder Alt-Taste
}

---------------------------------------------------------------------------
-- Medien
---------------------------------------------------------------------------

function ns.LSM()
	return LibStub and LibStub("LibSharedMedia-3.0", true)
end

-- Einträge einer LSM-Art als { Name, Name } (für Dropdowns), ohne die Namen in skip
function ns.LSMEntries(kind, skip)
	local list = {}
	local lsm = ns.LSM()
	if lsm then
		for _, name in ipairs(lsm:List(kind)) do
			if not (skip and skip[name]) then
				list[#list + 1] = { name, name }
			end
		end
	end
	return list
end

-- Pfad einer LSM-Datei oder nil
function ns.LSMFetch(kind, name)
	local lsm = ns.LSM()
	return lsm and lsm:IsValid(kind, name) and lsm:Fetch(kind, name) or nil
end

---------------------------------------------------------------------------
-- Zeilen eines Tooltips
---------------------------------------------------------------------------

function ns.Left(tip, i)
	return _G[tip:GetName() .. "TextLeft" .. i]
end

function ns.Right(tip, i)
	return _G[tip:GetName() .. "TextRight" .. i]
end

-- Zeile leeren (links und rechts)
function ns.Blank(tip, i)
	local left, right = ns.Left(tip, i), ns.Right(tip, i)
	if left then
		left:SetText("")
	end
	if right then
		right:SetText("")
	end
end

-- Hängt eine leere Zeile an und liefert ihren linken Text
function ns.NewLine(tip)
	tip:AddLine(" ")
	return ns.Left(tip, tip:NumLines())
end

-- Zeile, deren linker Text genau text ist (secret-Texte werden übersprungen)
function ns.FindLine(tip, text)
	for i = 1, tip:NumLines() do
		local left = ns.Left(tip, i)
		local t = left and left:GetText()
		if not IsSecret(t) and t == text then
			return i
		end
	end
end

-- Farbe 0–1 als sechsstelliger Hexwert
function ns.Hex(r, g, b)
	return ("%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- Hexwert als r, g, b (nil bei ungültigem Wert)
function ns.RGB(hex)
	if type(hex) ~= "string" or not hex:match("^%x%x%x%x%x%x$") then
		return nil
	end
	return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

-- UnitIsUnit als true/false. Nicht vergleichbare Einheiten (RequiresComparableUnitTokens) werfen im
-- Client einen Fehler, secret-Ergebnisse sind nicht lesbar: beides gilt als false.
function ns.IsUnit(a, b)
	local ok, same = pcall(UnitIsUnit, a, b)
	if not ok or IsSecret(same) then
		return false
	end
	return same and true or false
end

-- Umschalt, Strg oder Alt gedrückt
function ns.AnyModifier()
	return IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown()
end

---------------------------------------------------------------------------
-- Gestaltete Tooltips
-- GameTooltip immer, die übrigen mit moreTooltips. Manche entstehen erst mit ihrem Addon
-- (FriendsTooltip mit Blizzard_FriendsFrame): bei jedem ADDON_LOADED erneut suchen.
---------------------------------------------------------------------------

ns.MORE_TOOLTIPS = { "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1",
	"ItemRefShoppingTooltip2", "FriendsTooltip" }

function ns.Tooltips()
	local list = { GameTooltip }
	if ns.db.moreTooltips then
		for _, name in ipairs(ns.MORE_TOOLTIPS) do
			if _G[name] then
				list[#list + 1] = _G[name]
			end
		end
	end
	return list
end

-- gehört tip zu den gestalteten Tooltips?
function ns.IsStyled(tip)
	return tip and tip.qnStyled or false
end

-- Einstellungen auf alle Tooltips anwenden
function ns.Apply()
	for _, tip in ipairs(ns.Tooltips()) do
		ns.Style.Setup(tip)
	end
	ns.Style.ApplyAll()
	ns.StatusBar.Apply()
end

---------------------------------------------------------------------------
-- Laden
---------------------------------------------------------------------------

ns.OnLoad(function()
	-- Einstellungen je Profil (= Layout des Bearbeitungsmodus); ns.db ist immer das aktive Profil.
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnTooltipDB",
		defaults = ns.defaults,
		onSwitch = function()
			ns.Apply()
			ns.RefreshElementsPages()
		end,
	})
	ns.Style.Init()
	ns.StatusBar.Init()
	ns.Unit.Init()
	ns.Target.Init()
	ns.Inspect.Init()
	ns.Model.Init()
	ns.Anchor.Init()
	ns.Ids.Init()
	ns.Chat.Init()
	ns.Apply()
	ns.InitOptions()
	-- später geladene Tooltips (FriendsTooltip) nachziehen
	ns.events.Register("ADDON_LOADED", function()
		ns.Apply()
	end)
end)

---------------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------------

lib.RegisterSlash("QNTOOLTIP", { "/qntt", "/qntooltip" }, function(cmd)
	if cmd == "" or cmd == "config" or cmd == "options" then
		ns.OpenOptions()
	elseif cmd == "reset" then
		ns.store:ResetActive()
		ns.Print(L["Einstellungen zurückgesetzt."])
	else
		ns.Print(L["Befehle: /qntt [config | reset]\n  config – Optionen öffnen\n  reset – alle Einstellungen des aktiven Profils zurücksetzen"])
	end
end)
