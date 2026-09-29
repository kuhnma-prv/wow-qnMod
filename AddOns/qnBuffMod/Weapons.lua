-- qnBuffMod: temporary weapon enchants of the player (main hand and off hand).
-- Weapons.slots[slot] = record as for the auras, additionally weapon = true and slot.

local _, ns = ...
local lib = qnCore
local Plain, IsSecret = lib.Plain, lib.IsSecret

local Weapons = { slots = {} }
ns.Weapons = Weapons

Weapons.SLOTS = { INVSLOT_MAINHAND, INVSLOT_OFFHAND }

local states = {}   -- [slot] = { name, icon, duration, last, known, warned }
local tick = 0

-- Name of the enchant from the weapon's tooltip: line "Name (number unit)", e.g. "Instant Poison (30 min)"
local function TooltipName(slot)
	local data = C_TooltipInfo.GetInventoryItem("player", slot)
	if type(data) ~= "table" or IsSecret(data) or type(data.lines) ~= "table" then
		return nil
	end
	for _, line in ipairs(data.lines) do
		local text = type(line) == "table" and not IsSecret(line) and line.leftText
		if type(text) == "string" and not IsSecret(text) then
			local name = text:match("^(.-) %(%d+ [^%)]+%)$")
			if name and name ~= "" then
				return name
			end
		end
	end
	return nil
end

local function ReadSlot(slot, index, now)
	local info = C_PaperDollInfo.GetTemporaryEnchantmentInfo(slot)
	if info == nil or IsSecret(info) then
		states[slot] = nil
		return nil
	end
	local ms = Plain(info.remainingTimeMs, 0)
	local charges = Plain(info.chargesRemaining, 0)
	local remaining = (type(ms) == "number" and ms or 0) / 1000
	local icon = Plain(GetInventoryItemTexture("player", slot), nil) or ns.QUESTION_MARK

	local st = states[slot]
	local name = TooltipName(slot)
	local known = name ~= nil
	if not name then
		if remaining < 1 and st and st.name then
			name = st.name
		else
			name = UNKNOWN
		end
	end
	-- previously unknown name now read (same icon, same slot): the same enchant
	if st and st.icon == icon and not st.known and known then
		st.name = name
	end
	if st and st.name == name and st.icon == icon then
		if remaining > st.last + 0.5 then
			-- same enchant, time remaining increased: renewed
			st.duration = remaining
			st.warned = nil
			ns.Recast.Forget(name)
		end
		st.duration = math.max(st.duration, remaining)
	else
		st = { name = name, icon = icon, duration = remaining }
		states[slot] = st
	end
	st.last = remaining
	st.known = known

	return {
		weapon = true,
		slot = slot,
		key = "weapon:" .. slot,
		name = name,
		icon = icon,
		count = type(charges) == "number" and charges or 0,
		duration = remaining > 0 and st.duration or 0,
		expiration = remaining > 0 and now + remaining or 0,
		index = index,
		kind = ns.kind.ITEM,
		state = st,
	}
end

-- Reads both slots; true if the set of enchanted slots has changed.
function Weapons.Read()
	local changed, now = false, GetTime()
	for index, slot in ipairs(Weapons.SLOTS) do
		local rec = ReadSlot(slot, index, now)
		if (rec ~= nil) ~= (Weapons.slots[slot] ~= nil) then
			changed = true
		end
		Weapons.slots[slot] = rec
	end
	return changed
end

function Weapons.Update()
	ns.WeaponsChanged(Weapons.Read())
end

-- Enchanted slots in the order main hand, off hand
function Weapons.List()
	local list = {}
	for _, slot in ipairs(Weapons.SLOTS) do
		if Weapons.slots[slot] then
			list[#list + 1] = Weapons.slots[slot]
		end
	end
	return list
end

-- One-second tick (Core): while a weapon is enchanted, re-read every second if the name is unknown,
-- otherwise every 2 s.
function Weapons.Tick()
	if not next(Weapons.slots) then
		tick = 0
		return
	end
	tick = tick + 1
	local unknown = false
	for _, rec in pairs(Weapons.slots) do
		if not rec.state.known then
			unknown = true
		end
	end
	if unknown or tick % 2 == 0 then
		Weapons.Update()
	end
end

function Weapons.Init()
	ns.events.Register("WEAPON_ENCHANT_CHANGED", Weapons.Update)
	ns.events.Register("WEAPON_SLOT_CHANGED", Weapons.Update)
end
