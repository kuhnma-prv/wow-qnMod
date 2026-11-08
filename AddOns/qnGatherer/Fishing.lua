-- qnGatherer: fishing. Counts every looted item per character and zone, learns fishing areas
-- (an ellipse around the position of the cast with the fish caught there), records fish schools
-- (game object of the loot source) and optionally raises the effect volume while fishing.

local ADDON, ns = ...
local DB = ns.DB

local F = {}
ns.Fishing = F

local LOOT_WINDOW = 5                 -- seconds after the end of the channel in which the loot still counts
local AREA_RX, AREA_RY = 0.055, 0.075 -- size of a learned area (share of the map)
local SOUND_CVARS = { "Sound_EnableSFX", "Sound_SFXVolume" }
local SUBCLASS_COOKING = 8            -- subclass of Tradegoods for meat and raw fish (no enum; check in the game)

F.stop = nil   -- GetTime() at the end of the last fishing channel, nil while fishing

---------------------------------------------------------------------------
-- Sound boost (opt-in, profile option soundBoost): effect sound on and at full volume while
-- fishing. The previous values are kept in qnGathererDB.global.soundRestore so that they are
-- restored even after a crash (next load).
---------------------------------------------------------------------------

function F.SoundOn()
	local g = DB.global
	if not (ns.db and ns.db.soundBoost) or g.soundRestore then
		return
	end
	local saved = {}
	for _, cvar in ipairs(SOUND_CVARS) do
		saved[cvar] = C_CVar.GetCVar(cvar)
	end
	g.soundRestore = saved
	C_CVar.SetCVar("Sound_EnableSFX", "1")
	C_CVar.SetCVar("Sound_SFXVolume", "1")
end

function F.SoundOff()
	local g = DB.global
	local saved = g and g.soundRestore
	if not saved then
		return
	end
	for cvar, value in pairs(saved) do
		C_CVar.SetCVar(cvar, value)
	end
	g.soundRestore = nil
end

---------------------------------------------------------------------------
-- Cast and loot
---------------------------------------------------------------------------

-- Is item a fish? Catalog (kind "fish") or item class Tradeskill/Cooking (raw fish).
function F.IsFish(item)
	local entry = DB.GetResource("i:" .. item)
	if entry then
		return entry.kind == "fish"
	end
	local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(item)
	return classID == Enum.ItemClass.Tradegoods and subClassID == SUBCLASS_COOKING
end

function F.OnCast(cast)
	F.stop = nil
	F.SoundOn()
end

function F.OnLoot(cast)
	if F.stop and GetTime() - F.stop > LOOT_WINDOW then
		return
	end
	local items, object = ns.Collector.ReadLoot()
	if not cast.map then
		return
	end
	local char = ns.CharKey()
	local fish = {}
	for _, it in ipairs(items) do
		DB.Ingest({ t = "catch", char = char, map = cast.map, item = it.item, n = it.n }, "own")
		if F.IsFish(it.item) then
			local res = "i:" .. it.item
			DB.Ingest({ t = "res", res = res, kind = "fish", item = it.item }, "own")
			fish[#fish + 1] = res
		end
	end
	if #fish > 0 then
		DB.Ingest({ t = "area", kind = "fish", map = cast.map, x = cast.x, y = cast.y,
			rx = AREA_RX, ry = AREA_RY, class = "learned", res = fish }, "own")
	end
	if object then
		ns.Collector.Record(cast, "o:" .. object, fish[1] and tonumber(fish[1]:sub(3)))
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local function EndOfCast(_, unit, _, spellID)
	if unit == "player" and not ns.IsSecret(spellID) and ns.KindForSpell(spellID) == "fish" then
		F.stop = GetTime()
		F.SoundOff()
	end
end
ns.events.Register("UNIT_SPELLCAST_CHANNEL_STOP", EndOfCast)
ns.events.Register("UNIT_SPELLCAST_FAILED", EndOfCast)
ns.events.Register("UNIT_SPELLCAST_INTERRUPTED", EndOfCast)
ns.events.Register("PLAYER_LOGOUT", F.SoundOff)
