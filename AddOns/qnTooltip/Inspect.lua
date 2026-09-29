-- qnTooltip: item level of other players via inspect (NotifyInspect, INSPECT_READY,
-- C_PaperDollInfo.GetInspectItemLevel), cached per GUID. The player's own level comes from
-- GetAverageItemLevel (equipped gear). As long as nothing is known, the tooltip shows "??".
-- Only out of combat and not while Blizzard's inspect window is open.

local _, ns = ...
local IsSecret = ns.IsSecret

local Inspect = {}
ns.Inspect = Inspect

local CACHE_TIME = 600   -- seconds a level stays valid
local THROTTLE = 1.5     -- seconds between two requests

local cache = {}         -- [GUID] = { level, time }
local pending            -- { guid, unit } of the running request
local lastRequest = 0

local UNKNOWN = "|cff999999??|r"

local function InspectFrameOpen()
	return InspectFrame and InspectFrame:IsShown()
end

local function Request(unit, guid)
	if InCombatLockdown() or InspectFrameOpen() then
		return
	end
	if GetTime() - lastRequest < THROTTLE then
		return
	end
	if not CanInspect(unit) then
		return
	end
	lastRequest = GetTime()
	pending = { guid = guid, unit = unit }
	NotifyInspect(unit)
end

-- level as a number or UNKNOWN; nil if it cannot be determined (secret GUID)
function Inspect.ItemLevel(unit, guid)
	if IsSecret(guid) or not guid then
		return nil
	end
	if guid == UnitGUID("player") then
		local _, equipped = GetAverageItemLevel()
		return equipped and math.floor(equipped + 0.5) or nil
	end
	local entry = cache[guid]
	if entry and GetTime() - entry[2] < CACHE_TIME then
		return entry[1]
	end
	Request(unit, guid)
	return entry and entry[1] or UNKNOWN
end

local function OnReady(_, guid)
	local p = pending
	if not p or IsSecret(guid) or guid ~= p.guid then
		return
	end
	pending = nil
	local unitGUID = UnitGUID(p.unit)
	if IsSecret(unitGUID) or unitGUID ~= guid then
		return
	end
	local level = C_PaperDollInfo.GetInspectItemLevel(p.unit)
	if not IsSecret(level) and level and level > 0 then
		cache[guid] = { math.floor(level + 0.5), GetTime() }
	end
	if not InspectFrameOpen() then
		ClearInspectPlayer()
	end
	-- rebuild the tooltip with the new level if it still shows this unit
	if GameTooltip:IsShown() and GameTooltip.qnUnit == p.unit then
		GameTooltip:SetUnit(p.unit)
	end
end

function Inspect.Init()
	ns.events.Register("INSPECT_READY", OnReady)
end
