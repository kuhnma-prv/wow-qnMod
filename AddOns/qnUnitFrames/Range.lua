-- qnUnitFrames: range icon to the right of Blizzard's target and focus frame.
--
-- Shown as soon as the unit is within range of the farthest ranged action that is currently
-- available (known, not passive, not off-spec, usable apart from missing power); the icon is the
-- one of this action. Within melee range it switches to the icon of the melee auto attack.
-- Spells with a minimum range (hunter shots) do not count while the unit is too close for them
-- (within duel distance and not in melee range): then no icon appears, as nothing can attack.
-- Spells that only mark (Hunter's Mark, far beyond any attack) never choose the icon.
-- Optional distance text inside the icon: the exact distance where the game reports it
-- (UnitDistanceSquared), otherwise the range bracket from the range checks ("20-30", "<5").
-- Size and position (offset from the frame's right edge) per frame in the profile.
--
-- The icon is an insecure child of TargetFrame/FocusFrame (hides and scales with it); the Blizzard
-- frames themselves are never changed. Range checks: C_Spell.IsSpellInRange (nil = cannot be
-- checked); units that cannot be attacked get no icon.

local _, ns = ...
local lib = qnCore

local AUTO_ATTACK = 6603   -- "Auto Attack", fallback if the spell book does not report it
local MELEE_MAX = 8        -- spells with at most this max range count as melee spells
local MELEE_RANGE = 5      -- melee range in yards for the distance text
local INTERVAL = 0.2       -- seconds between range checks
local DUEL_DISTANCE = 3    -- CheckInteractDistance index: duel range (about 10 yards)
-- CheckInteractDistance indices with their distance in yards (PlayerScriptDocumentation) for the
-- range bracket
local INTERACT = { { index = 3, range = 10 }, { index = 2, range = 11 }, { index = 1, range = 28 } }

-- harmful spells that do not stand for an attack: their range would show the icon far beyond
-- every real attack (Hunter's Mark: 100 yards). Matched by ID and by the name of the first rank,
-- which covers every rank. They still help the distance text.
local NOT_ATTACKS = { 1130, 14323, 14324, 14325 }   -- Hunter's Mark, ranks 1-4

-- unit, Blizzard frame, prefix of the setting keys (Core.lua defaults)
ns.RANGE_UNITS = {
	{ unit = "target", frame = "TargetFrame", key = "rangeTarget" },
	{ unit = "focus", frame = "FocusFrame", key = "rangeFocus" },
}

local icons = {}       -- [unit] = frame with .tex
ns.rangeIcons = icons
local ranged = {}      -- { { id, range, minRange }, ... } farthest first
local marks = {}       -- { { id, range }, ... } ranged spells from NOT_ATTACKS (distance text only)
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
	wipe(marks)
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
						local entry = { id = id, range = range, minRange = lib.Plain(spell.minRange, 0) or 0 }
						if notAttack[id] or notAttack[lib.Plain(spell.name, "")] then
							marks[#marks + 1] = entry
						else
							ranged[#ranged + 1] = entry
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

-- texture for the unit or nil (no icon); second value: within melee range
function ns.RangeTexture(unit)
	-- only attackable units: for friendly ones the harmful spells cannot be checked and the
	-- duel distance would show the melee icon
	if not UnitExists(unit) or not lib.Plain(UnitCanAttack("player", unit), false) then
		return nil
	end
	if InMelee(unit) then
		return meleeIcon, true
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
					return C_Spell.GetSpellTexture(r.id), false
				end
				return nil
			end
		end
	end
end

-- Distance text: exact where the game reports the distance, otherwise the bracket between the
-- farthest check that failed and the nearest check that succeeded. Spells with a minimum range
-- do not set the lower bound (false may mean "too close").
function ns.RangeDistanceText(unit, inMelee)
	local squared, checked = UnitDistanceSquared(unit)
	squared = lib.Plain(squared, nil)
	if lib.Plain(checked, false) and type(squared) == "number" then
		return tostring(math.floor(math.sqrt(squared) + 0.5))
	end
	local lower, upper = 0, nil
	local function Note(range, inRange, minRange)
		if inRange == true then
			upper = upper and math.min(upper, range) or range
		elseif inRange == false and minRange == 0 then
			lower = math.max(lower, range)
		end
	end
	if inMelee then
		upper = MELEE_RANGE
	else
		lower = MELEE_RANGE
	end
	for _, list in ipairs({ ranged, marks }) do
		for _, r in ipairs(list) do
			Note(r.range, InRange(r.id, unit), r.minRange)
		end
	end
	for _, i in ipairs(INTERACT) do
		Note(i.range, lib.Plain(CheckInteractDistance(unit, i.index), nil), 0)
	end
	if not upper then
		return ">" .. math.floor(lower)
	end
	if lower > 0 and lower < upper then
		return math.floor(lower) .. "-" .. math.floor(upper)
	end
	return "<" .. math.floor(upper)
end

function ns.UpdateRangeIcons()
	for unit, icon in pairs(icons) do
		local tex, inMelee
		if icon.active then
			tex, inMelee = ns.RangeTexture(unit)
		end
		if tex then
			icon.tex:SetTexture(tex)
			icon.text:SetText(icon.distance and ns.RangeDistanceText(unit, inMelee) or "")
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
