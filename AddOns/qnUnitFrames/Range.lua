-- qnUnitFrames: range icon to the right of Blizzard's target and focus frame.
--
-- Shown as soon as the unit is within range of the farthest ranged action that is currently
-- available (known, not passive, not off-spec, usable apart from missing power); the icon is the
-- one of this action. Within melee range it switches to the icon of the melee auto attack.
-- Spells with a minimum range (hunter shots) do not count while the unit is too close for them
-- (within duel distance and not in melee range): then no icon appears, as nothing can attack.
-- Spells that only mark (Hunter's Mark, far beyond any attack) never choose the icon.
-- Optional distance text inside the icon: the actual distance in yards, only where the game
-- reports it (UnitDistanceSquared, otherwise UnitPosition of player and unit); no estimate from
-- the range checks. /qnuf distance prints what the game reports for the target.
-- Size and position (offset from the frame's right edge) per frame in the profile.
--
-- The icon is an insecure child of TargetFrame/FocusFrame (hides and scales with it); the Blizzard
-- frames themselves are never changed. Range checks: C_Spell.IsSpellInRange (nil = cannot be
-- checked); units that cannot be attacked get no icon.

local _, ns = ...
local lib = qnCore

local AUTO_ATTACK = 6603   -- "Auto Attack", fallback if the spell book does not report it
local MELEE_MAX = 8        -- spells with at most this max range count as melee spells
local INTERVAL = 0.2       -- seconds between range checks
local DUEL_DISTANCE = 3    -- CheckInteractDistance index: duel range (about 10 yards)

-- harmful spells that do not stand for an attack: their range would show the icon far beyond
-- every real attack (Hunter's Mark: 100 yards). Matched by ID and by the name of the first rank,
-- which covers every rank.
local NOT_ATTACKS = { 1130, 14323, 14324, 14325 }   -- Hunter's Mark, ranks 1-4

-- unit, Blizzard frame, prefix of the setting keys (Core.lua defaults)
ns.RANGE_UNITS = {
	{ unit = "target", frame = "TargetFrame", key = "rangeTarget" },
	{ unit = "focus", frame = "FocusFrame", key = "rangeFocus" },
}

local icons = {}       -- [unit] = frame with .tex
ns.rangeIcons = icons
local ranged = {}      -- { { id, range, minRange }, ... } farthest first
local melee = {}       -- spell IDs for the melee check, auto attack first
local meleeIcon        -- texture of the auto attack
local ticker

---------------------------------------------------------------------------
-- Spells from the spell book
---------------------------------------------------------------------------

-- [spellID] = true and [name] = true of the NOT_ATTACKS spells
local function NotAttacks()
	local set = {}
	for _, id in ipairs(NOT_ATTACKS) do
		set[id] = true
		local spell = C_Spell.GetSpellInfo(id)
		if spell and spell.name then
			set[spell.name] = true
		end
	end
	return set
end

function ns.ScanRangeSpells()
	wipe(ranged)
	wipe(melee)
	local notAttack = NotAttacks()
	local autoAttack
	local bank = Enum.SpellBookSpellBank.Player
	for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
		for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
			local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
			local id = item and item.itemType == Enum.SpellBookItemType.Spell and not item.isPassive
				and not item.isOffSpec and item.spellID
			if id then
				if C_SpellBook.IsAutoAttackSpellBookItem(slot, bank) then
					autoAttack = id
				elseif C_Spell.IsSpellHarmful(id) then
					local spell = C_Spell.GetSpellInfo(id)
					local range = spell and lib.Plain(spell.maxRange, 0) or 0
					if range > MELEE_MAX then
						if not (notAttack[id] or notAttack[lib.Plain(spell.name, "")]) then
							ranged[#ranged + 1] = { id = id, range = range, minRange = lib.Plain(spell.minRange, 0) or 0 }
						end
					else
						melee[#melee + 1] = id
					end
				end
			end
		end
	end
	table.insert(melee, 1, autoAttack or AUTO_ATTACK)
	meleeIcon = C_Spell.GetSpellTexture(autoAttack or AUTO_ATTACK)
	-- farthest first; equal range: spell book order
	for i, r in ipairs(ranged) do
		r.order = i
	end
	table.sort(ranged, function(a, b)
		if a.range ~= b.range then
			return a.range > b.range
		end
		return a.order < b.order
	end)
end

---------------------------------------------------------------------------
-- Range check
---------------------------------------------------------------------------

-- true/false, nil = cannot be checked (also for a secret result)
local function InRange(id, unit)
	local r = C_Spell.IsSpellInRange(id, unit)
	if lib.IsSecret(r) then
		return nil
	end
	return r
end

-- can be cast right now (missing power does not count)
local function Usable(id)
	local usable, noPower = C_Spell.IsSpellUsable(id)
	return lib.Plain(usable, false) or lib.Plain(noPower, false)
end

local function WithinDuelDistance(unit)
	return lib.Plain(CheckInteractDistance(unit, DUEL_DISTANCE), false)
end

-- Melee only if no checkable melee spell is out of range: in the game single spells report
-- true far beyond melee range (Heroic Strike at charge distance), the auto attack returns nil.
-- Without a checkable melee spell (e.g. druid in caster form) the duel distance decides.
local function InMelee(unit)
	local checked, outside = false, false
	for _, id in ipairs(melee) do
		local r = InRange(id, unit)
		if r ~= nil then
			checked = true
			outside = outside or not r
		end
	end
	if checked then
		return not outside
	end
	return WithinDuelDistance(unit)
end

-- texture for the unit or nil (no icon)
function ns.RangeTexture(unit)
	-- only attackable units: for friendly ones the harmful spells cannot be checked and the
	-- duel distance would show the melee icon
	if not UnitExists(unit) or not lib.Plain(UnitCanAttack("player", unit), false) then
		return nil
	end
	if InMelee(unit) then
		return meleeIcon
	end
	-- farthest usable ranged spell; one with a minimum range is skipped while the unit is too
	-- close for it (outside melee, within duel distance: the hunter's dead zone)
	local tooClose
	for _, r in ipairs(ranged) do
		if Usable(r.id) then
			if r.minRange > 0 and tooClose == nil then
				tooClose = WithinDuelDistance(unit)
			end
			if r.minRange == 0 or not tooClose then
				if InRange(r.id, unit) then
					return C_Spell.GetSpellTexture(r.id)
				end
				return nil
			end
		end
	end
end

-- x, y, z, mapID of the unit as plain numbers, nil if the game does not report them
local function Position(unit)
	local x, y, z, mapID = UnitPosition(unit)
	x, y, z, mapID = lib.Plain(x, nil), lib.Plain(y, nil), lib.Plain(z, nil), lib.Plain(mapID, nil)
	if type(x) == "number" and type(y) == "number" then
		return x, y, type(z) == "number" and z or 0, mapID
	end
end

-- actual distance to the unit in yards, nil if the game reports neither the distance
-- (UnitDistanceSquared) nor both positions on the same map (UnitPosition)
function ns.UnitDistance(unit)
	local squared, checked = UnitDistanceSquared(unit)
	squared = lib.Plain(squared, nil)
	if lib.Plain(checked, false) and type(squared) == "number" then
		return math.sqrt(squared)
	end
	local px, py, pz, pmap = Position("player")
	local ux, uy, uz, umap = Position(unit)
	if px and ux and pmap == umap then
		return math.sqrt((px - ux) ^ 2 + (py - uy) ^ 2 + (pz - uz) ^ 2)
	end
end

-- distance text inside the icon: whole yards or "" (no estimate from the range checks)
function ns.RangeDistanceText(unit)
	local distance = ns.UnitDistance(unit)
	return distance and tostring(math.floor(distance + 0.5)) or ""
end

-- /qnuf distance: what the game reports for the target (check in the game)
function ns.PrintDistanceInfo()
	local function Show(...)
		local parts = {}
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			parts[i] = lib.IsSecret(v) and "secret" or tostring(v)   -- do not translate
		end
		return table.concat(parts, ", ")
	end
	ns.Print("UnitDistanceSquared(target): " .. Show(UnitDistanceSquared("target")))   -- do not translate
	ns.Print("UnitPosition(player): " .. Show(UnitPosition("player")))   -- do not translate
	ns.Print("UnitPosition(target): " .. Show(UnitPosition("target")))   -- do not translate
	ns.Print("distance: " .. tostring(ns.UnitDistance("target")))   -- do not translate
end

function ns.UpdateRangeIcons()
	for unit, icon in pairs(icons) do
		local tex = icon.active and ns.RangeTexture(unit)
		if tex then
			icon.tex:SetTexture(tex)
			icon.text:SetText(icon.distance and ns.RangeDistanceText(unit) or "")
			icon:Show()
		else
			icon:Hide()
		end
	end
end

---------------------------------------------------------------------------
-- Frames and settings
---------------------------------------------------------------------------

local function CreateIcon(entry)
	local parent = _G[entry.frame]
	if not parent then
		return nil
	end
	local icon = CreateFrame("Frame", nil, parent)
	icon:SetFrameStrata(parent:GetFrameStrata())
	icon:SetFrameLevel(parent:GetFrameLevel() + 10)
	icon.tex = icon:CreateTexture(nil, "ARTWORK")
	icon.tex:SetAllPoints()
	icon.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon.text = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	icon.text:SetPoint("BOTTOM", 0, 1)
	icon:Hide()
	icons[entry.unit] = icon
	return icon
end

-- applies size, position and on/off from the profile; the check runs only while an icon is on
function ns.ApplyRange()
	local db = ns.db
	if not db then
		return
	end
	local any = false
	for _, entry in ipairs(ns.RANGE_UNITS) do
		local key = entry.key
		local icon = icons[entry.unit] or (db[key] and CreateIcon(entry))
		if icon then
			icon.active = db[key]
			icon.distance = db[key .. "Distance"]
			icon:SetSize(db[key .. "Size"], db[key .. "Size"])
			icon:ClearAllPoints()
			icon:SetPoint("LEFT", icon:GetParent(), "RIGHT", db[key .. "X"], db[key .. "Y"])
			any = any or icon.active
		end
	end
	if any and not ticker then
		ticker = C_Timer.NewTicker(INTERVAL, ns.UpdateRangeIcons)
	elseif not any and ticker then
		ticker:Cancel()
		ticker = nil
	end
	ns.UpdateRangeIcons()
end

function ns.InitRange()
	local Rescan = lib.Debounce(function()
		ns.ScanRangeSpells()
		ns.UpdateRangeIcons()
	end)
	ns.events.Register("SPELLS_CHANGED", Rescan)
	ns.events.Register("PLAYER_TARGET_CHANGED", ns.UpdateRangeIcons)
	ns.events.Register("PLAYER_FOCUS_CHANGED", ns.UpdateRangeIcons)
	ns.ScanRangeSpells()
end
