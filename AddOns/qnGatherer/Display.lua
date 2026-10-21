-- qnGatherer: what the world map and the minimap show. Visibility per kind (always / with the
-- profession / while tracking / never), filters per resource and origin, names, icons, colors
-- and tooltip lines. D.Refresh() redraws both displays (merged into one call per frame).

local ADDON, ns = ...
local DB = ns.DB
local L = ns.L

local D = {}
ns.Display = D

local refreshed = qnCore.NewSignal()   -- redraw needed
local professions     -- [kind] = true/false, nil = read again
local tracking        -- [spellID] = true for active tracking, nil = read again
local icons = {}      -- [res] = icon

-- Names of the import adapters (origin "import:<key>")
ns.IMPORT_NAMES = { gm2 = "GatherMate2", gt = "GatherTogether", file = "qnGatherer" }   -- do not translate

-- fn() after every change that needs a redraw (data, settings, profession, tracking)
D.OnRefresh = refreshed.Add

D.Refresh = qnCore.Debounce(refreshed.Fire)

---------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------

-- Does the character have the profession of the kind? Kinds without a profession: always.
function D.HasProfession(key)
	if not professions then
		professions = {}
		for kindKey, kind in pairs(ns.KINDS) do
			local known = true
			if kind.skill then
				local info = C_SkillInfo.GetSkillLineInfoByID(kind.skill)
				local rank = info and ns.Plain(info.rank, 0) or 0
				known = rank > 0
			end
			professions[kindKey] = known
		end
	end
	return professions[key]
end

-- Is minimap tracking of the kind active? Kinds without tracking: like HasProfession.
function D.IsTracking(key)
	local kind = ns.KINDS[key]
	if #kind.track == 0 then
		return D.HasProfession(key)
	end
	if not tracking then
		tracking = {}
		for i = 1, C_Minimap.GetNumTrackingTypes() do
			local info = C_Minimap.GetTrackingInfo(i)
			if info and info.spellID and ns.Plain(info.active) then
				tracking[info.spellID] = true
			end
		end
	end
	for _, id in ipairs(kind.track) do
		if tracking[id] then
			return true
		end
	end
	return false
end

-- Is kind shown with mode ("always", "profession", "tracking", "never"; default: profile show[kind])?
function D.KindShown(key, mode)
	mode = mode or ns.db.show[key]
	if mode == "always" then
		return true
	elseif mode == "profession" then
		return D.HasProfession(key)
	elseif mode == "tracking" then
		return D.IsTracking(key)
	end
	return false
end

-- Passes resource res of origin the filters of the profile?
function D.NodeShown(key, res, origin)
	local filter = ns.db.filter[key]
	if filter and filter[res] == false then
		return false
	end
	if origin and origin ~= "own" then
		if origin:sub(1, 6) == "guild:" then
			return ns.db.origins.guild
		elseif origin:sub(1, 7) == "import:" then
			return ns.db.origins.import
		end
	end
	return true
end

---------------------------------------------------------------------------
-- Names, icons, colors
---------------------------------------------------------------------------

-- Main product of the resource, or nil
function D.ResourceItem(res)
	local entry = DB.GetResource(res)
	if entry and entry.item then
		return entry.item
	end
	return tonumber(res:match("^i:(%d+)$"))
end

-- Display name: name in the client language > item name > name of the key > any known name > key
function D.ResourceName(res)
	local entry = DB.GetResource(res)
	local name = entry and entry.names[GetLocale()]
	if name then
		return name
	end
	local item = D.ResourceItem(res)
	if item then
		name = C_Item.GetItemNameByID(item)
		if name then
			return name
		end
		C_Item.RequestLoadItemDataByID(item)
	end
	name = res:match("^n:%l+:(.+)$")
	if name then
		return name
	end
	if entry then
		local _, any = next(entry.names)
		if any then
			return any
		end
	end
	return res
end

function D.ResourceIcon(key, res)
	local icon = icons[res]
	if not icon then
		local item = D.ResourceItem(res)
		local kind = ns.KINDS[key]
		icon = item and C_Item.GetItemIconByID(item) or (kind and C_Spell.GetSpellTexture(kind.spells[1])) or 134400
		icons[res] = icon
	end
	return icon
end

-- Color of the kind { r, g, b, a } (tracking circle, areas, tooltip)
function D.Color(key)
	return ns.db.circle.colors[key] or ns.KINDS[key].color
end

-- Text about the origin of a node, nil for own nodes
function D.OriginText(origin)
	if not origin or origin == "own" then
		return nil
	end
	local who = origin:match("^guild:(.+)$")
	if who then
		return L["Found by %s"]:format(who)
	end
	local adapter = origin:match("^import:(.+)$")
	if adapter then
		return L["Imported from %s"]:format(ns.IMPORT_NAMES[adapter] or adapter)
	end
	return origin
end

-- Tooltip lines of a node entry { kind, res, origin }
function D.AddTooltipLines(tooltip, entry)
	local c = D.Color(entry.kind)
	tooltip:AddLine(D.ResourceName(entry.res), c[1], c[2], c[3])
	local res = DB.GetResource(entry.res)
	if res and res.skill then
		tooltip:AddLine(L["Required skill: %d"]:format(res.skill), 0.8, 0.8, 0.8)
	end
	local origin = D.OriginText(entry.origin)
	if origin then
		tooltip:AddLine(origin, 0.6, 0.6, 0.6)
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

ns.events.Register("SKILL_LINES_CHANGED", function()
	professions = nil
	D.Refresh()
end)

ns.events.Register("MINIMAP_UPDATE_TRACKING", function()
	tracking = nil
	D.Refresh()
end)

function D.Init()
	DB.OnChange(function()
		D.Refresh()
	end)
end
