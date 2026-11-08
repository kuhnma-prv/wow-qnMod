-- qnMarkers: markers above nameplates (opt-in).
--
-- Per nameplate an own frame as child of the nameplate base frame (not of its pooled UnitFrame,
-- Blizzard_NamePlateBase.lua): border, background, icon and target glow. Nothing is written into
-- Blizzard's tables; the unit of a nameplate is tracked from NAME_PLATE_UNIT_ADDED/REMOVED.
-- Unit values can be secret (SecretWhenUnitIdentityRestricted: UnitClass, UnitIsPVP,
-- UnitGroupRolesAssigned, UnitCreatureType, UnitInRaid; UnitIsUnit when comparisons are restricted):
-- a secret value counts as "unknown" - the rule that needs it is skipped, nothing is compared.

local _, ns = ...
local L = ns.L
local lib = qnCore

local MEDIA = "Interface\\AddOns\\qnMarkers\\Media\\"
local CIRCLE = MEDIA .. "Circle"
local GLOW = MEDIA .. "Glow"
local BORDER = 2              -- width of the border in pixels
local GLOW_FACTOR = 1.6       -- glow size relative to the marker
local TOTEM = 11              -- creature type id of totems (UnitCreatureType)
local MAX_PLATES = 60         -- nameplate tokens scanned on a full refresh

local FRIEND_COLOR = { 1, 0.45, 0.65, 1 }
local GUILD_COLOR = { 0.25, 1, 0.25, 1 }
local ENEMY_COLOR = { 1, 0, 0, 1 }
local WHITE = { 1, 1, 1, 1 }

-- Textures for the icon type "Texture": { key, name, file }
ns.TEXTURES = {
	{ "arrow", L["Arrow"], MEDIA .. "Arrow" },
	{ "heart", L["Heart"], MEDIA .. "Heart" },
	{ "shield", L["Shield"], MEDIA .. "Shield" },
	{ "dot", L["Dot"], CIRCLE },
	{ "skull", RAID_TARGET_8, ns.MarkerIcon(8) },
	{ "star", RAID_TARGET_1, ns.MarkerIcon(1) },
	{ "custom", L["Custom texture"] },
}

ns.ICON_TYPES = { class = true, role = true, texture = true }
ns.FALLBACK_TYPES = { none = true, class = true, role = true, texture = true }
ns.SHAPES = { square = true, circle = true }

local markers = setmetatable({}, { __mode = "k" })   -- nameplate -> marker frame
local units = setmetatable({}, { __mode = "k" })     -- nameplate -> unit token
local pending = {}                                   -- unit token -> true (added) / false (removed)
local refreshAll = false

---------------------------------------------------------------------------
-- Unit rules
---------------------------------------------------------------------------

local Plain = lib.Plain

local function IsGroupMember(unit)
	return Plain(UnitInParty(unit), false) or Plain(UnitInRaid(unit), nil) ~= nil
end

-- Friend in the friend list or on Battle.net
local function IsFriend(unit)
	local guid = Plain(UnitGUID(unit), nil)
	if not guid then
		return false
	end
	if Plain(C_FriendList.IsFriend(guid), false) then
		return true
	end
	return C_BattleNet.GetAccountInfoByGUID(guid) ~= nil
end

local function IsTotem(unit)
	local _, id = UnitCreatureType(unit)
	return Plain(id, nil) == TOTEM
end

local function InArena()
	local _, kind = IsInInstance()
	return kind == "arena"
end

-- friendly, enemy: group members are always friendly, neutral units count as friendly
local function Reaction(unit, inGroup)
	if inGroup then
		return true, false
	end
	local enemy = Plain(UnitIsEnemy("player", unit), false) and true or false
	return not enemy, enemy
end

local function ClassFile(unit)
	local _, classFile = UnitClass(unit)
	return Plain(classFile, nil)
end

local function Role(unit, inGroup)
	if not inGroup then
		return nil
	end
	local role = Plain(UnitGroupRolesAssigned(unit), nil)
	if role == nil or role == "NONE" then
		return nil
	end
	return role
end

local function AtlasExists(atlas)
	return atlas and C_Texture.GetAtlasInfo(atlas) ~= nil
end

-- File or atlas of the setting "Texture"
function ns.TextureOf(key)
	local p = ns.db.plates
	if key == "custom" then
		local custom = strtrim(p.customTexture or "")
		if custom ~= "" then
			return custom
		end
		key = ns.defaults.plates.texture
	end
	for _, t in ipairs(ns.TEXTURES) do
		if t[1] == key and t[3] then
			return t[3]
		end
	end
	return ns.TEXTURES[1][3]
end

-- Color of role and texture icons
local function IconColor(unit, enemy)
	local p = ns.db.plates
	if enemy and p.enemyRed then
		return ENEMY_COLOR
	end
	if p.classColors then
		local c = lib.ClassColor(ClassFile(unit))
		if c then
			return { c.r, c.g, c.b, 1 }
		end
	end
	return WHITE
end

-- Icon of one icon type ("class", "role", "texture") or nil if not available for the unit
local function IconOfType(kind, unit, isPlayer, inGroup, enemy)
	local p = ns.db.plates
	if kind == "class" then
		local classFile = isPlayer and ClassFile(unit)
		local atlas = classFile and GetClassAtlas(classFile:lower())
		if AtlasExists(atlas) then
			return { atlas = atlas }
		end
	elseif kind == "role" then
		local role = Role(unit, inGroup)
		local atlas = role and GetIconForRole(role)
		if AtlasExists(atlas) then
			return { atlas = atlas, color = IconColor(unit, enemy), desaturate = p.desaturate }
		end
	elseif kind == "texture" then
		return { file = ns.TextureOf(p.texture), color = IconColor(unit, enemy), desaturate = p.desaturate, rotation = p.rotation }
	end
	return nil
end

-- Marker for a unit: { atlas | file | portrait, color, desaturate, rotation, side, scale } or nil.
-- side = settings of the friendly or enemy markers (size, offset, background, shape, border).
function ns.MarkerFor(unit)
	local p = ns.db.plates
	if not p.enabled or not UnitExists(unit) then
		return nil
	end
	-- the own nameplate (personal resource display) and totems get nothing
	if Plain(UnitIsUnit(unit, "player"), false) or IsTotem(unit) then
		return nil
	end
	if p.arenaOnly and not InArena() then
		return nil
	end

	-- pets: portrait of the pet
	local ownPet = Plain(UnitIsUnit(unit, "pet"), false)
	if ownPet or Plain(UnitIsOtherPlayersPet(unit), false) then
		if (ownPet and not p.ownPet) or (not ownPet and not p.pets) then
			return nil
		end
		return { portrait = true, side = p.friendly, scale = ownPet and 1 or p.petScale }
	end

	local isPlayer = Plain(UnitIsPlayer(unit), false)
	local inGroup = IsGroupMember(unit)
	local friendly, enemy = Reaction(unit, inGroup)
	local side = enemy and p.enemy or p.friendly

	-- special icons
	if isPlayer and friendly then
		if p.friends and IsFriend(unit) then
			return { file = MEDIA .. "Heart", color = FRIEND_COLOR, side = side }
		end
		if p.guild and Plain(UnitIsInMyGuild(unit), false) then
			return { file = MEDIA .. "Shield", color = GUILD_COLOR, side = side }
		end
	end

	local pass = (p.enemies and isPlayer and enemy)
		or (p.allies and isPlayer and friendly)
		or (p.group and inGroup)
		or (p.npcs and not isPlayer)
		or (p.pvp and isPlayer and Plain(UnitIsPVP(unit), false))
	if not pass then
		return nil
	end

	-- role filter: only units whose role is known (group members with an assigned role)
	local role = Role(unit, inGroup)
	if role and not p[({ TANK = "tank", HEALER = "healer", DAMAGER = "dps" })[role] or "dps"] then
		return nil
	end

	local icon = IconOfType(side.icon, unit, isPlayer, inGroup, enemy)
	if not icon and side.fallback ~= "none" then
		icon = IconOfType(side.fallback, unit, isPlayer, inGroup, enemy)
	end
	if not icon then
		return nil
	end
	icon.side = side
	icon.unit = unit
	return icon
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function NewMarker(plate)
	local m = CreateFrame("Frame", nil, plate)
	m:SetFrameLevel(plate:GetFrameLevel() + 10)
	m.border = m:CreateTexture(nil, "BACKGROUND", nil, 0)
	m.bg = m:CreateTexture(nil, "BACKGROUND", nil, 1)
	m.icon = m:CreateTexture(nil, "ARTWORK")
	m.mask = m:CreateMaskTexture()
	m.mask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m.mask:SetAllPoints(m.icon)
	m.glow = m:CreateTexture(nil, "OVERLAY")
	m.glow:SetTexture(GLOW)
	m.glow:SetBlendMode("ADD")
	m.glow:SetPoint("CENTER")
	m.glow:Hide()
	m:Hide()
	markers[plate] = m
	return m
end

-- Round (masked) or square
local function SetRound(m, round)
	if m.round == round then
		return
	end
	m.round = round
	if round then
		m.icon:AddMaskTexture(m.mask)
	else
		m.icon:RemoveMaskTexture(m.mask)
	end
end

local function Fill(texture, round, r, g, b, a)
	if round then
		texture:SetTexture(CIRCLE)
		texture:SetVertexColor(r, g, b, a)
	else
		texture:SetColorTexture(r, g, b, a)
	end
end

local function UpdateGlow(plate, targetPlate)
	local m = markers[plate]
	if not m then
		return
	end
	if targetPlate == nil then
		targetPlate = C_NamePlate.GetNamePlateForUnit("target") or false
	end
	local on = ns.db.plates.targetGlow and m:IsShown() and plate == targetPlate
	if on then
		local c = ns.db.plates.glowColor
		m.glow:SetVertexColor(lib.UnpackColor(c, 1))
	end
	m.glow:SetShown(on and true or false)
end

local function Draw(plate, unit)
	local spec = unit and ns.MarkerFor(unit)
	local m = markers[plate]
	if not spec then
		if m then
			m:Hide()
			m.glow:Hide()
		end
		return
	end
	m = m or NewMarker(plate)
	local p, side = ns.db.plates, spec.side
	local round = side.shape == "circle" or spec.portrait
	local size = side.size * (spec.scale or 1)
	local pad = side.background and side.padding or 0
	local border = side.border and BORDER or 0
	local outer = size + 2 * (pad + border)

	m:SetIgnoreParentAlpha(not p.distanceFade)
	m:SetSize(outer, outer)
	m:ClearAllPoints()
	m:SetPoint("BOTTOM", plate, "TOP", side.offsetX, side.offsetY)

	-- border in class color (only where the class is known)
	local c = side.border and lib.ClassColor(ClassFile(spec.unit or unit))
	if c then
		m.border:ClearAllPoints()
		m.border:SetAllPoints(m)
		Fill(m.border, round, c.r, c.g, c.b, 1)
		m.border:Show()
	else
		m.border:Hide()
	end
	if side.background then
		m.bg:ClearAllPoints()
		m.bg:SetPoint("TOPLEFT", border, -border)
		m.bg:SetPoint("BOTTOMRIGHT", -border, border)
		Fill(m.bg, round, 0, 0, 0, 1)
		m.bg:Show()
	else
		m.bg:Hide()
	end

	local icon = m.icon
	icon:ClearAllPoints()
	icon:SetPoint("TOPLEFT", border + pad, -(border + pad))
	icon:SetPoint("BOTTOMRIGHT", -(border + pad), border + pad)
	SetRound(m, round)
	if spec.portrait then
		SetPortraitTexture(icon, unit)
	elseif spec.atlas then
		icon:SetAtlas(spec.atlas, false)
	else
		icon:SetTexture(spec.file)
	end
	icon:SetDesaturated(spec.desaturate and true or false)
	icon:SetVertexColor(lib.UnpackColor(spec.color or WHITE, 1))
	icon:SetRotation(math.rad(spec.rotation or 0))

	m.glow:SetSize(outer * GLOW_FACTOR, outer * GLOW_FACTOR)
	m:Show()
	UpdateGlow(plate)
end

local function UpdateAllGlows()
	local targetPlate = C_NamePlate.GetNamePlateForUnit("target") or false
	for plate in pairs(markers) do
		UpdateGlow(plate, targetPlate)
	end
end

---------------------------------------------------------------------------
-- Events: nameplates arrive in bursts, so they share one pass in the next frame
-- (other nameplate addons have had theirs first)
---------------------------------------------------------------------------

local function Flush()
	if not ns.db then
		return   -- before ADDON_LOADED
	end
	if not ns.db.plates.enabled then
		-- switched off: hide what is there, look at no nameplate
		refreshAll = false
		wipe(pending)
		for _, m in pairs(markers) do
			m:Hide()
			m.glow:Hide()
		end
		return
	end
	if refreshAll then
		refreshAll = false
		wipe(pending)
		for plate in pairs(markers) do
			if not units[plate] then
				markers[plate]:Hide()
			end
		end
		for i = 1, MAX_PLATES do
			local unit = "nameplate" .. i
			local plate = C_NamePlate.GetNamePlateForUnit(unit)
			if plate then
				units[plate] = unit
				Draw(plate, unit)
			end
		end
		return
	end
	for unit, added in pairs(pending) do
		local plate = C_NamePlate.GetNamePlateForUnit(unit)
		if plate then
			units[plate] = added and unit or nil
			Draw(plate, added and unit or nil)
		end
	end
	wipe(pending)
end
local QueueFlush = lib.Debounce(Flush)

-- Settings changed, group, friends or guild changed: look at every nameplate again
function ns.ApplyPlates()
	refreshAll = true
	QueueFlush()
end

local events = ns.events
events.Register("NAME_PLATE_UNIT_ADDED", function(_, unit)
	pending[unit] = true
	QueueFlush()
end)
events.Register("NAME_PLATE_UNIT_REMOVED", function(_, unit)
	-- hide at once: the nameplate base frame is reused for the next unit
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	if plate then
		units[plate] = nil
		if markers[plate] then
			markers[plate]:Hide()
			markers[plate].glow:Hide()
		end
	end
	pending[unit] = nil
end)
events.Register("PLAYER_TARGET_CHANGED", UpdateAllGlows)
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "UNIT_PET",
	"FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED", "PLAYER_GUILD_UPDATE", "ZONE_CHANGED_NEW_AREA" }) do
	events.Register(e, ns.ApplyPlates)
end
events.Register("UNIT_FACTION", function(_, unit)
	if unit and unit:find("^nameplate") then
		pending[unit] = true
		QueueFlush()
	end
end)

-- for scenarios
ns.PlateMarker = function(plate) return markers[plate] end
