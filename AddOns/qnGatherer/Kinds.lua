-- qnGatherer: gathering kinds (spells that gather, tracking spells, skill lines, colors, merge radius).
-- Gas, Archaeology and Logging are kept generic; they are only offered where their gathering
-- spell exists on the client (ns.KindAvailable).

local ADDON, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- Kinds
-- key       stored key (never translated)
-- name      display name
-- spells    spell IDs whose cast gathers this kind
-- track     spell IDs of the minimap tracking for this kind (visibility "while tracking")
-- skill     skill line of the profession (visibility "with profession"); nil = everybody
-- color     default color of the tracking circle and the areas { r, g, b, a }
-- radius    default merge radius in yards (nodes of the same resource within it are one node)
-- maxRadius upper limit of the radius option
---------------------------------------------------------------------------

ns.KIND_ORDER = { "herb", "mine", "fish", "treasure", "gas", "archaeology", "logging" }

ns.KINDS = {
	herb = { name = L["Herbalism"], spells = { 2366 }, track = { 2383 }, skill = 182,
		color = { 0, 1, 0, 1 }, radius = 15, maxRadius = 30 },
	mine = { name = L["Mining"], spells = { 2575 }, track = { 2580 }, skill = 186,
		color = { 1, 0.1, 0.1, 1 }, radius = 15, maxRadius = 30 },
	fish = { name = L["Fishing"], spells = { 7620 }, track = {}, skill = 356,
		color = { 1, 1, 0, 1 }, radius = 15, maxRadius = 30 },
	treasure = { name = L["Treasure"], spells = { 3365, 22810, 1804 }, track = { 2481 },
		color = { 1, 0, 1, 1 }, radius = 15, maxRadius = 30 },
	gas = { name = L["Gas"], spells = { 30427 }, track = {}, skill = 202,
		color = { 0, 1, 1, 1 }, radius = 50, maxRadius = 100 },
	archaeology = { name = L["Archaeology"], spells = { 73979 }, track = {}, skill = 794,
		color = { 1, 1, 0.5, 1 }, radius = 10, maxRadius = 30 },
	logging = { name = L["Logging"], spells = { 167895 }, track = {},
		color = { 0.4, 0.7, 1, 1 }, radius = 20, maxRadius = 30 },
}

local kindBySpell = {}
for key, kind in pairs(ns.KINDS) do
	kind.key = key
	for _, id in ipairs(kind.spells) do
		kindBySpell[id] = key
	end
end

-- Kind by spell name (built on first use): professions can have one gathering spell ID per rank
local kindBySpellName

-- Key of the kind gathered by spellID, or nil.
function ns.KindForSpell(spellID)
	local key = kindBySpell[spellID]
	if key then
		return key
	end
	if not kindBySpellName then
		kindBySpellName = {}
		for _, kindKey in ipairs(ns.KIND_ORDER) do
			for _, id in ipairs(ns.KINDS[kindKey].spells) do
				local name = C_Spell.GetSpellName(id)
				if name then
					kindBySpellName[name] = kindBySpellName[name] or kindKey
				end
			end
		end
	end
	local name = C_Spell.GetSpellName(spellID)
	return name and kindBySpellName[name]
end

-- Does the client know one of the gathering spells of the kind?
function ns.KindAvailable(key)
	local kind = ns.KINDS[key]
	if not kind then
		return false
	end
	for _, id in ipairs(kind.spells) do
		if C_Spell.GetSpellName(id) then
			return true
		end
	end
	return false
end
