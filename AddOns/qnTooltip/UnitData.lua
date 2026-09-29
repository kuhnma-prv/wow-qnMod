-- qnTooltip: Daten einer Einheit und Aufbau der Zeilen aus den Bausteinen.
-- Viele Einheiten-Werte können secret sein (Name, Gilde, Stufe …). Solche Werte werden weder
-- verglichen noch verknüpft: jede Zeile ist ein Formatmuster mit Werten und geht als Ganzes an
-- SetFormattedText. Farben und Filter brauchen lesbare Werte; fehlen sie, entfällt die Farbe bzw.
-- der Baustein.

local _, ns = ...
local L = ns.L
local IsSecret = ns.IsSecret

local UD = {}
ns.UnitData = UD

-- Wert vorhanden? secret gilt als vorhanden (nur SetFormattedText sieht ihn)
local function Has(v)
	return IsSecret(v) or (v ~= nil and v ~= "")
end
UD.Has = Has

local function Plain(v)
	if IsSecret(v) then
		return nil
	end
	return v
end

---------------------------------------------------------------------------
-- Symbole
---------------------------------------------------------------------------

local ROLE_ICON = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:%s|t"
local ROLE_COORDS = { TANK = "0:19:22:41", HEALER = "20:39:1:20", DAMAGER = "20:39:22:41" }
local CLASS_ICON = "|TInterface\\TargetingFrame\\UI-Classes-Circles:14:14:0:0:256:256:%d:%d:%d:%d|t"
local FACTION_ICON = { Alliance = "|A:UI-HUD-UnitFrame-SmallCircle-Alliance:14:14|a", Horde = "|A:UI-HUD-UnitFrame-SmallCircle-Horde:14:14|a" }
local FFA_ICON = "|A:UI-HUD-UnitFrame-Player-PVP-FFAIcon:14:14|a"
local QUEST_ICON = "|A:UI-HUD-UnitFrame-Target-PortraitOn-Boss-Quest:14:14|a"
local FRIEND_ICON = "|A:friendslist-favorite:14:14|a"
UD.BIG_FACTION = { Alliance = "Interface\\Timer\\Alliance-Logo", Horde = "Interface\\Timer\\Horde-Logo" }

---------------------------------------------------------------------------
-- Rohdaten
---------------------------------------------------------------------------

function UD.Collect(unit)
	local raw = { unit = unit }
	raw.isPlayer = Plain(UnitIsPlayer(unit))
	-- Forever (camelot): UnitName liefert Vor- und Nachname (NameUtil.GetUnitFirstName, IsPlayerMe),
	-- nicht den Realm. Den Realm liefert GetPlayerInfoByGUID ("" = eigener Realm).
	raw.name, raw.surname = UnitName(unit)
	raw.pvpName = UnitPVPName(unit)
	raw.level = UnitLevel(unit)
	raw.effectiveLevel = UnitEffectiveLevel(unit)
	raw.raceName = UnitRace(unit)
	raw.className, raw.class = UnitClass(unit)
	raw.factionGroup, raw.factionName = UnitFactionGroup(unit)
	raw.reaction = UnitReaction(unit, "player")
	raw.classif = UnitClassification(unit)
	raw.creature = UnitCreatureType(unit)
	raw.sex = UnitSex(unit)
	raw.guid = UnitGUID(unit)
	if raw.isPlayer then
		raw.guildName, raw.guildRank, raw.guildIndex, raw.guildRealm = GetGuildInfo(unit)
		raw.role = UnitGroupRolesAssigned(unit)
		local guid = Plain(raw.guid)
		if guid then
			raw.realm = select(7, GetPlayerInfoByGUID(guid))
		end
	end
	return raw
end

-- Text ohne das erste Vorkommen von part (reiner Textvergleich); pos = Fundstelle
local function Without(text, part)
	local pos = text:find(part, 1, true)
	if not pos then
		return text, nil
	end
	return text:sub(1, pos - 1) .. text:sub(pos + #part), pos
end

-- Titel aus UnitPVPName ohne Vor- und Nachname; zweiter Wert: steht der Titel vor dem Namen?
local function Title(raw)
	local name, pvpName = Plain(raw.name), Plain(raw.pvpName)
	if not (name and pvpName) or name == pvpName then
		return nil
	end
	local rest, pos = Without(pvpName, name)
	if not pos then
		return nil
	end
	local surname = Plain(raw.surname)
	if surname and surname ~= "" then
		rest = Without(rest, surname)
	end
	local title = strtrim((rest:gsub(",", "")))
	if title == "" then
		return nil
	end
	return title, pos > 1
end

-- Zone eines Schlachtzugsmitglieds
local function Zone(unit)
	local index = Plain(UnitInRaid(unit))
	if index then
		return (select(7, GetRaidRosterInfo(index)))
	end
end

-- Bewegungstempo in Prozent (nur lesbare Werte)
local function Speed(unit)
	local speed = Plain(GetUnitSpeed(unit))
	if not speed or speed == 0 then
		return nil
	end
	return math.floor(speed / BASE_MOVEMENT_SPEED * 100 + 0.5)
end

---------------------------------------------------------------------------
-- Werte der Bausteine (nil = nicht anzeigen)
---------------------------------------------------------------------------

local VALUES = {}
UD.VALUES = VALUES

function VALUES.friendIcon(raw)
	local guid = Plain(raw.guid)
	if raw.isPlayer and guid and guid ~= Plain(UnitGUID("player")) and Plain(C_FriendList.IsFriend(guid)) then
		return FRIEND_ICON
	end
end

function VALUES.raidIcon(raw)
	local index = Plain(GetRaidTargetIndex(raw.unit))
	if index and ICON_LIST[index] then
		return ICON_LIST[index] .. "0|t"
	end
end

function VALUES.roleIcon(raw)
	local coords = ROLE_COORDS[Plain(raw.role) or ""]
	return coords and ROLE_ICON:format(coords)
end

function VALUES.pvpIcon(raw)
	if Plain(UnitIsPVPFreeForAll(raw.unit)) then
		return FFA_ICON
	end
end

function VALUES.factionIcon(raw)
	return FACTION_ICON[Plain(raw.factionGroup) or ""]
end

function VALUES.classIcon(raw)
	local c = CLASS_ICON_TCOORDS[Plain(raw.class) or ""]
	return c and CLASS_ICON:format(c[1] * 256, c[2] * 256, c[3] * 256, c[4] * 256)
end

function VALUES.questIcon(raw)
	if Plain(UnitIsQuestBoss(raw.unit)) then
		return QUEST_ICON
	end
end

function VALUES.title(raw)
	return (Title(raw))
end

function VALUES.name(raw)
	return raw.name
end

function VALUES.surname(raw)
	if raw.isPlayer then
		return raw.surname
	end
end

function VALUES.realm(raw)
	if not raw.isPlayer then
		return nil
	end
	if Has(raw.realm) then
		return raw.realm
	end
	return GetRealmName()
end

function VALUES.statusAFK(raw)
	return Plain(UnitIsAFK(raw.unit)) and AFK or nil
end

function VALUES.statusDND(raw)
	return Plain(UnitIsDND(raw.unit)) and DND or nil
end

function VALUES.statusDC(raw)
	return raw.isPlayer and Plain(UnitIsConnected(raw.unit)) == false and PLAYER_OFFLINE or nil
end

function VALUES.guildName(raw)
	return raw.guildName
end

function VALUES.guildRank(raw)
	return raw.guildRank
end

function VALUES.guildIndex(raw)
	if Has(raw.guildName) then
		return raw.guildIndex
	end
end

function VALUES.guildRealm(raw)
	return raw.guildRealm
end

function VALUES.levelValue(raw)
	local level = raw.level
	if not IsSecret(level) and (level == nil or level < 0) then
		return "??"
	end
	return level
end

function VALUES.factionName(raw)
	return raw.factionName
end

function VALUES.gender(raw)
	local sex = Plain(raw.sex)
	return (sex == 2 and MALE) or (sex == 3 and FEMALE) or nil
end

function VALUES.raceName(raw)
	return raw.raceName
end

function VALUES.className(raw)
	if raw.isPlayer then
		return raw.className
	end
end

function VALUES.isPlayer(raw)
	return raw.isPlayer and PLAYER or nil
end

function VALUES.role(raw)
	local role = Plain(raw.role)
	return role and role ~= "NONE" and _G[role] or nil
end

function VALUES.moveSpeed(raw)
	return Speed(raw.unit)
end

function VALUES.itemLevel(raw)
	if raw.isPlayer then
		return ns.Inspect.ItemLevel(raw.unit, raw.guid)
	end
end

function VALUES.zone(raw)
	return Zone(raw.unit)
end

local function Classif(raw)
	local level, classif = Plain(raw.level), Plain(raw.classif)
	if level == -1 or classif == "worldboss" then
		return "boss"
	end
	return classif
end

function VALUES.classifBoss(raw)
	return Classif(raw) == "boss" and BOSS or nil
end

function VALUES.classifElite(raw)
	return Classif(raw) == "elite" and ELITE or nil
end

function VALUES.classifRare(raw)
	local c = Classif(raw)
	return (c == "rare" or c == "rareelite") and MAP_LEGEND_RARE or nil
end

function VALUES.creature(raw)
	return raw.creature
end

function VALUES.reactionName(raw)
	local reaction = Plain(raw.reaction)
	return reaction and _G["FACTION_STANDING_LABEL" .. reaction] or nil
end

---------------------------------------------------------------------------
-- Beispielwerte für die Vorschau auf den Optionsseiten: der lesbare Wert der Einheit, sonst ein
-- Beispiel (Blizzard-Texte), sonst der Name des Bausteins. raw darf nil sein.
---------------------------------------------------------------------------

local SAMPLES = {
	friendIcon = function() return FRIEND_ICON end,
	raidIcon = function() return ICON_LIST[8] .. "0|t" end,
	roleIcon = function() return ROLE_ICON:format(ROLE_COORDS.TANK) end,
	pvpIcon = function() return FFA_ICON end,
	factionIcon = function() return FACTION_ICON.Alliance end,
	classIcon = function() return VALUES.classIcon({ class = "WARRIOR" }) end,
	questIcon = function() return QUEST_ICON end,
	statusAFK = function() return AFK end,
	statusDND = function() return DND end,
	statusDC = function() return PLAYER_OFFLINE end,
	isPlayer = function() return PLAYER end,
	role = function() return TANK end,
	gender = function() return MALE end,
	levelValue = function() return 60 end,
	moveSpeed = function() return 100 end,
	classifBoss = function() return BOSS end,
	classifElite = function() return ELITE end,
	classifRare = function() return MAP_LEGEND_RARE end,
	reactionName = function() return FACTION_STANDING_LABEL5 end,
}

function UD.Sample(key, raw, label)
	local value = raw and Plain(VALUES[key](raw))
	if value ~= nil and value ~= "" then
		return value
	end
	local sample = SAMPLES[key]
	return sample and sample() or label
end

---------------------------------------------------------------------------
-- Farbfunktionen: liefern r, g, b oder nil
---------------------------------------------------------------------------

local COLORS = {}
UD.COLORS = COLORS

function COLORS.class(raw)
	local c = qnCore.ClassColor(raw.class)
	if c then
		return c.r, c.g, c.b
	end
end

function COLORS.level(raw)
	local level = Plain(raw.effectiveLevel) or Plain(raw.level)
	if not level then
		return nil
	end
	local c = GetCreatureDifficultyColor(level > 0 and level or 999)
	return c.r, c.g, c.b
end

function COLORS.reaction(raw)
	local c = FACTION_BAR_COLORS[Plain(raw.reaction) or 4]
	if c then
		return c.r, c.g, c.b
	end
end

function COLORS.faction(raw)
	local group = Plain(raw.factionGroup)
	if not group then
		return nil
	elseif group == "Neutral" then
		return 0.9, 0.7, 0
	elseif group == UnitFactionGroup("player") then
		return 0, 1, 0.2
	end
	return 1, 0.2, 0
end

function COLORS.selection(raw)
	local r, g, b = UnitSelectionColor(raw.unit)
	if not ns.AnySecret(r, g, b) then
		return r, g, b
	end
end

-- Auswahl im Dropdown: { Schlüssel, Anzeigename }
function UD.ColorEntries()
	return {
		{ "default", DEFAULT },
		{ "class", L["Class Color"] },
		{ "level", L["Level Color"] },
		{ "reaction", L["Reaction Color"] },
		{ "faction", L["Faction Color"] },
		{ "selection", L["Selection Color"] },
	}
end

-- r, g, b zu einer Farbe (Funktion oder Hexwert) oder nil
function UD.Color(key, raw)
	local fn = COLORS[key]
	if fn then
		return fn(raw)
	end
	return ns.RGB(key)
end

---------------------------------------------------------------------------
-- Filter: "none", "<name>" oder "!<name>" (verneint)
---------------------------------------------------------------------------

local FILTERS = {}
UD.FILTERS = FILTERS

function FILTERS.inraid() return IsInRaid() end
function FILTERS.ingroup() return IsInGroup() end
function FILTERS.incombat() return InCombatLockdown() end
function FILTERS.ininstance() return (IsInInstance()) end
function FILTERS.inpvp() return select(2, IsInInstance()) == "pvp" end
function FILTERS.inarena() return select(2, IsInInstance()) == "arena" end
function FILTERS.samerealm(raw) return not Has(raw.realm) end
function FILTERS.reaction5(raw) return (Plain(raw.reaction) or 4) >= 5 end
function FILTERS.reaction6(raw) return (Plain(raw.reaction) or 4) >= 6 end
function FILTERS.sameguild(raw)
	local name = Plain(raw.guildName)
	return name ~= nil and name == GetGuildInfo("player")
end

function UD.FilterEntries()
	local list = { { "none", NONE } }
	for _, f in ipairs({
		{ "ingroup", L["in a group"] },
		{ "inraid", L["in a raid"] },
		{ "incombat", L["in combat"] },
		{ "ininstance", L["in an instance"] },
		{ "inpvp", L["in a battleground"] },
		{ "inarena", L["in an arena"] },
		{ "samerealm", L["from your realm"] },
		{ "sameguild", L["from your guild"] },
		{ "reaction5", L["reputation friendly or better"] },
		{ "reaction6", L["reputation honored or better"] },
	}) do
		list[#list + 1] = { f[1], L["only %s"]:format(f[2]) }
		list[#list + 1] = { "!" .. f[1], L["not %s"]:format(f[2]) }
	end
	return list
end

local function Pass(filter, raw)
	if not filter or filter == "none" or filter == "" then
		return true
	end
	local negate = filter:sub(1, 1) == "!"
	local fn = FILTERS[negate and filter:sub(2) or filter]
	if not fn then
		return true
	end
	local ok = fn(raw) and true or false
	return ok ~= negate
end

---------------------------------------------------------------------------
-- Formate
---------------------------------------------------------------------------

-- Gültiges Format: genau ein Platzhalter (%s; bei Zahlen auch %d), sonst nur %%.
function UD.ValidFormat(fmt, kind)
	if type(fmt) ~= "string" then
		return false
	end
	local rest = fmt:gsub("%%%%", "")
	local n = 0
	for c in rest:gmatch("%%(.?)") do
		if c == "s" or (c == "d" and kind == "number") then
			n = n + 1
		else
			return false
		end
	end
	return n == 1
end

-- Wert mit einem Format (nur lesbare Werte, für die Vorschau auf den Optionsseiten); nil = ungültig
function UD.FormatValue(fmt, kind, value)
	if not UD.ValidFormat(fmt, kind) then
		return nil
	end
	if kind == "number" and not fmt:gsub("%%%%", ""):find("%%s") then
		value = tonumber(value) or 0
	else
		value = tostring(value)
	end
	local ok, text = pcall(string.format, fmt, value)
	return ok and text or nil
end

local function Format(cfg, default, kind)
	if UD.ValidFormat(cfg.format, kind) then
		return cfg.format
	end
	return default.format
end

-- Beschriftungen vor dem Wert (Gegenstandsstufe); % im Text maskiert
local LABELS = {
	itemLevel = function()
		return "|cffffd100" .. STAT_AVERAGE_ITEM_LEVEL:gsub("%%", "%%%%") .. ":|r "
	end,
}

---------------------------------------------------------------------------
-- Zeilen
-- Liefert eine Liste { pattern, args } in Zeilenfolge; opts.gray: alles grau (tote Einheiten)
---------------------------------------------------------------------------

function UD.Rows(kind, elements, raw, opts)
	local showAll = ns.db.modifierShowsAll and (IsAltKeyDown() or IsControlKeyDown())
	local gray = opts and opts.gray
	local items = {}
	for index, e in ipairs(ns.ELEMENTS[kind]) do
		local key, _, ekind, default = e[1], e[2], e[3], e[4]
		local cfg = elements[key] or default
		if ekind ~= "fixed" and (showAll or (cfg.enable and Pass(cfg.filter, raw))) then
			local value = VALUES[key](raw)
			if Has(value) then
				local part
				if ekind == "icon" then
					part = "%s"
				else
					part = Format(cfg, default, ekind)
					local hex
					if gray then
						hex = "aaaaaa"
					else
						local r, g, b = UD.Color(cfg.color, raw)
						hex = r and ns.Hex(r, g, b)
					end
					if hex then
						part = "|cff" .. hex .. part .. "|r"
					end
					if LABELS[key] then
						part = LABELS[key]() .. part
					end
				end
				items[#items + 1] = { line = cfg.line or default.line, order = cfg.order or default.order, index = index,
					key = key, part = part, value = value }
			end
		end
	end
	table.sort(items, function(a, b)
		if a.line ~= b.line then
			return a.line < b.line
		elseif a.order ~= b.order then
			return a.order < b.order
		end
		return a.index < b.index
	end)

	-- Titel direkt vor oder hinter den Namen (wie im Spiel), wenn beide in derselben Zeile stehen
	local _, prefix = Title(raw)
	-- ein nachgestellter Titel folgt auf den Nachnamen, wenn dieser direkt hinter dem Namen steht
	local ti, ni, si
	for i, item in ipairs(items) do
		if item.key == "title" then ti = i elseif item.key == "name" then ni = i elseif item.key == "surname" then si = i end
	end
	if ti and ni and items[ti].line == items[ni].line then
		local title = table.remove(items, ti)
		if ti < ni then
			ni = ni - 1
		end
		if si and ti < si then
			si = si - 1
		end
		local after = (si and si == ni + 1) and si or ni
		table.insert(items, prefix and ni or after + 1, title)
	end

	local rows, current, lastLine = {}, nil, nil
	for _, item in ipairs(items) do
		if item.line ~= lastLine then
			current = { parts = {}, args = {} }
			rows[#rows + 1] = current
			lastLine = item.line
		end
		current.parts[#current.parts + 1] = item.part
		current.args[#current.args + 1] = item.value
	end
	for _, row in ipairs(rows) do
		row.pattern = table.concat(row.parts, " ")
		row.parts = nil
	end
	return rows
end
