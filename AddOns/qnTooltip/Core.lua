-- qnTooltip: customizable tooltips (look, position, unit lines built from elements,
-- health bar, target, item level, IDs).
-- Core: namespace, defaults, unit line elements, media, line helpers, loading, slash.

local ADDON, ns = ...
_G.qnTooltip = ns

local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L
local IsSecret = ns.IsSecret

---------------------------------------------------------------------------
-- Elements of the unit lines
-- Per unit kind a list { key, display name, kind, default }. Kind:
--   "icon"    icon: on/off, line, order, filter
--   "text"    text: plus color and format (exactly one %s)
--   "number"  number: format with %d or %s
--   "fixed"   no line of its own (the NPC title is always in Blizzard's title line)
-- Color: name of a color function (ns.UnitData.COLORS) or a six-digit hex value.
---------------------------------------------------------------------------

local function Icon(line, order, enable)
	return { enable = enable, line = line, order = order, filter = "none" }
end

local function Text(line, order, enable, color, format, filter)
	return { enable = enable, line = line, order = order, color = color, format = format, filter = filter or "none" }
end

ns.ELEMENTS = {
	player = {
		{ "friendIcon", L["Friend Icon"], "icon", Icon(1, 1, true) },
		{ "raidIcon", L["Raid Target Icon"], "icon", Icon(1, 2, true) },
		{ "roleIcon", L["Role Icon"], "icon", Icon(1, 3, true) },
		{ "pvpIcon", L["PvP Icon"], "icon", Icon(1, 4, true) },
		{ "factionIcon", L["Faction Icon"], "icon", Icon(1, 5, true) },
		{ "classIcon", L["Class Icon"], "icon", Icon(1, 6, true) },
		{ "title", HONOR_REWARD_TITLE_TOOLTIP, "text", Text(1, 7, true, "ccffff", "%s") },
		{ "name", NAME, "text", Text(1, 8, true, "class", "%s") },
		{ "surname", L["Surname"], "text", Text(1, 9, true, "class", "%s") },
		{ "realm", L["Realm"], "text", Text(1, 9, true, "00eeee", "%s") },
		{ "statusAFK", AFK, "text", Text(1, 10, true, "ffd200", "(%s)") },
		{ "statusDND", DND, "text", Text(1, 11, true, "ffd200", "(%s)") },
		{ "statusDC", PLAYER_OFFLINE, "text", Text(1, 12, true, "999999", "(%s)") },
		{ "guildName", GUILD, "text", Text(2, 1, true, "ff00ff", "<%s>") },
		{ "guildIndex", L["Guild Rank Number"], "text", Text(2, 2, false, "cc88ff", "%s") },
		{ "guildRank", RANK, "text", Text(2, 3, true, "cc88ff", "(%s)") },
		{ "guildRealm", L["Guild Realm"], "text", Text(2, 4, true, "00cccc", "%s") },
		{ "levelValue", L["Level"], "text", Text(3, 1, true, "level", "%s") },
		{ "factionName", FACTION, "text", Text(3, 2, true, "faction", "%s") },
		{ "gender", L["Gender"], "text", Text(3, 3, false, "999999", "%s") },
		{ "raceName", RACE, "text", Text(3, 4, true, "cccccc", "%s") },
		{ "className", CLASS, "text", Text(3, 5, true, "class", "%s") },
		{ "isPlayer", PLAYER, "text", Text(3, 6, false, "ffffff", "(%s)") },
		{ "role", ROLE, "text", Text(3, 7, false, "ffffff", "(%s)") },
		{ "moveSpeed", L["Movement Speed"], "number", Text(3, 8, false, "e8e7a8", "%d%%") },
		{ "itemLevel", STAT_AVERAGE_ITEM_LEVEL, "text", Text(4, 1, true, "ffffff", "%s") },
		{ "zone", ZONE, "text", Text(5, 1, false, "ffffff", "%s") },
	},
	npc = {
		{ "raidIcon", L["Raid Target Icon"], "icon", Icon(1, 1, true) },
		{ "classIcon", L["Class Icon"], "icon", Icon(1, 2, false) },
		{ "questIcon", L["Quest Icon"], "icon", Icon(1, 3, true) },
		{ "name", NAME, "text", Text(1, 4, true, "default", "%s") },
		{ "npcTitle", HONOR_REWARD_TITLE_TOOLTIP, "fixed", Text(0, 0, true, "99e8e8", "<%s>") },
		{ "levelValue", L["Level"], "text", Text(2, 1, true, "level", "%s") },
		{ "classifBoss", BOSS, "text", Text(2, 2, true, "ff0000", "(%s)") },
		{ "classifElite", ELITE, "text", Text(2, 3, true, "ffff33", "(%s)") },
		{ "classifRare", MAP_LEGEND_RARE, "text", Text(2, 4, true, "ffaaff", "(%s)") },
		{ "creature", L["Creature Type"], "text", Text(2, 5, true, "selection", "%s") },
		{ "reactionName", REPUTATION, "text", Text(2, 6, true, "33ffff", "<%s>", "reaction6") },
		{ "moveSpeed", L["Movement Speed"], "number", Text(2, 7, false, "e8e7a8", "%d%%") },
	},
}

-- element defaults: { key = default }
local function ElementDefaults(list)
	local t = {}
	for _, e in ipairs(list) do
		t[e[1]] = e[4]
	end
	return t
end

-- list entry for a key
function ns.Element(kind, key)
	for _, e in ipairs(ns.ELEMENTS[kind]) do
		if e[1] == key then
			return e
		end
	end
end

---------------------------------------------------------------------------
-- Defaults
-- The settings of the unit kinds are in player/npc (each on its own page).
---------------------------------------------------------------------------

ns.defaults = {
	-- Appearance
	scale = 1,
	bgFile = "rock",
	bgColor = { 0, 0, 0, 0.7 },
	borderStyle = "default",     -- default | angular | none
	borderSize = 1,              -- "angular" only
	borderColor = { 0.6, 0.6, 0.6, 0.8 },
	mask = true,                 -- light gradient over the header line
	headerFont = "default",
	headerSize = 0,              -- 0 = Blizzard size
	headerFlag = "default",
	bodyFont = "default",
	bodySize = 0,
	bodyFlag = "default",
	moreTooltips = true,         -- also ItemRef, comparison and friends tooltips
	hideUnitFrameHint = true,    -- remove the "right-click for frame settings" hint
	chatHover = true,            -- tooltip when hovering chat links
	modifierShowsAll = true,     -- Alt or Ctrl: show all elements

	-- Position (only on request: "blizzard" lets Blizzard or Edit Mode decide)
	anchorMode = "blizzard",     -- blizzard | cursor | cursorRight | static
	anchorPoint = "BOTTOMRIGHT",
	anchorX = -60,
	anchorY = 120,
	returnInCombat = true,       -- at Blizzard's spot in combat
	returnOnUnitFrame = false,   -- at Blizzard's spot over unit frames
	hideInCombat = false,
	combatModifier = "none",     -- none | alt | ctrl | shift: shows hidden tooltips

	-- Health bar
	barHide = false,
	barHeight = 4,
	barPosition = "bottom",      -- default | bottom | top
	barOffsetX = 0,              -- 0 = matching the border
	barTexture = "Blizzard",
	barText = true,
	barPercent = true,
	barColor = "auto",           -- default | auto | smooth
	barFont = "default",
	barSize = 10,
	barFlag = "THINOUTLINE",

	-- Units
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

	-- Items, spells, quests
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
	idsWithModifier = false,     -- IDs only while Shift, Ctrl or Alt is held
}

---------------------------------------------------------------------------
-- Media
---------------------------------------------------------------------------

function ns.LSM()
	return LibStub and LibStub("LibSharedMedia-3.0", true)
end

-- entries of an LSM media type as { name, name } (for dropdowns), without the names in skip
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

-- path of an LSM file or nil
function ns.LSMFetch(kind, name)
	local lsm = ns.LSM()
	return lsm and lsm:IsValid(kind, name) and lsm:Fetch(kind, name) or nil
end

---------------------------------------------------------------------------
-- Tooltip lines
---------------------------------------------------------------------------

function ns.Left(tip, i)
	return _G[tip:GetName() .. "TextLeft" .. i]
end

function ns.Right(tip, i)
	return _G[tip:GetName() .. "TextRight" .. i]
end

-- clear a line (left and right)
function ns.Blank(tip, i)
	local left, right = ns.Left(tip, i), ns.Right(tip, i)
	if left then
		left:SetText("")
	end
	if right then
		right:SetText("")
	end
end

-- Appends an empty line and returns its left text
function ns.NewLine(tip)
	tip:AddLine(" ")
	return ns.Left(tip, tip:NumLines())
end

-- line whose left text is exactly text (secret texts are skipped)
function ns.FindLine(tip, text)
	for i = 1, tip:NumLines() do
		local left = ns.Left(tip, i)
		local t = left and left:GetText()
		if not IsSecret(t) and t == text then
			return i
		end
	end
end

-- color 0-1 as a six-digit hex value
function ns.Hex(r, g, b)
	return ("%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- hex value as r, g, b (nil for an invalid value)
function ns.RGB(hex)
	if type(hex) ~= "string" or not hex:match("^%x%x%x%x%x%x$") then
		return nil
	end
	return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

-- UnitIsUnit as true/false. Non-comparable units (RequiresComparableUnitTokens) raise an error in
-- the client, secret results are not readable: both count as false.
function ns.IsUnit(a, b)
	local ok, same = pcall(UnitIsUnit, a, b)
	if not ok or IsSecret(same) then
		return false
	end
	return same and true or false
end

-- Shift, Ctrl or Alt held
function ns.AnyModifier()
	return IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown()
end

---------------------------------------------------------------------------
-- Styled tooltips
-- GameTooltip always, the others with moreTooltips. Some only come into existence with their addon
-- (FriendsTooltip with Blizzard_FriendsFrame): look them up again on every ADDON_LOADED.
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

-- is tip one of the styled tooltips?
function ns.IsStyled(tip)
	return tip and tip.qnStyled or false
end

-- apply the settings to all tooltips
function ns.Apply()
	for _, tip in ipairs(ns.Tooltips()) do
		ns.Style.Setup(tip)
	end
	ns.Style.ApplyAll()
	ns.StatusBar.Apply()
end

---------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------

ns.OnLoad(function()
	-- Settings per profile (= Edit Mode layout); ns.db is always the active profile.
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
	-- pick up tooltips loaded later (FriendsTooltip)
	ns.events.Register("ADDON_LOADED", function()
		ns.Apply()
	end)
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

lib.RegisterSlash("QNTOOLTIP", { "/qntt", "/qntooltip" }, function(cmd)
	if cmd == "" or cmd == "config" or cmd == "options" then
		ns.OpenOptions()
	elseif cmd == "reset" then
		ns.store:ResetActive()
		ns.Print(L["Settings reset."])
	else
		ns.Print(L["Commands: /qntt [config | reset]\n  config – open options\n  reset – reset all settings of the active profile"])
	end
end)
