-- qnUnitFrames: range icon to the right of Blizzard's target and focus frame.
--
-- Shown as soon as the unit is within range of the farthest ranged action that is currently
-- available (known, not passive, not off-spec, usable apart from missing power); the icon is the
-- one of this action. Within melee range it switches to the icon of the melee auto attack.
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

-- unit, Blizzard frame, prefix of the setting keys (Core.lua defaults)
ns.RANGE_UNITS = {
	{ unit = "target", frame = "TargetFrame", key = "rangeTarget" },
	{ unit = "focus", frame = "FocusFrame", key = "rangeFocus" },
}

local icons = {}       -- [unit] = frame with .tex
ns.rangeIcons = icons
local ranged = {}      -- { { id, range }, ... } farthest first
local melee = {}       -- spell IDs for the melee check, auto attack first
local meleeIcon        -- texture of the auto attack
local ticker

---------------------------------------------------------------------------
-- Spells from the spell book
---------------------------------------------------------------------------

function ns.ScanRangeSpells()
	wipe(ranged)
	wipe(melee)
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
						ranged[#ranged + 1] = { id = id, range = range }
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

-- farthest ranged spell that can be cast right now (missing power does not count)
local function BestRanged()
	for _, r in ipairs(ranged) do
		local usable, noPower = C_Spell.IsSpellUsable(r.id)
		if lib.Plain(usable, false) or lib.Plain(noPower, false) then
			return r.id
		end
	end
end

-- texture for the unit or nil (no icon)
function ns.RangeTexture(unit)
	-- only attackable units: for friendly ones the harmful spells cannot be checked and the
	-- duel distance would show the melee icon
	if not UnitExists(unit) or not lib.Plain(UnitCanAttack("player", unit), false) then
		return nil
	end
	-- melee only if no checkable melee spell is out of range: in the game single spells report
	-- true far beyond melee range (Heroic Strike at charge distance), the auto attack returns nil.
	-- Without a checkable melee spell (e.g. druid in caster form) the duel distance decides.
	local checked, outside = false, false
	for _, id in ipairs(melee) do
		local r = InRange(id, unit)
		if r ~= nil then
			checked = true
			outside = outside or not r
		end
	end
	if checked then
		if not outside then
			return meleeIcon
		end
	elseif lib.Plain(CheckInteractDistance(unit, DUEL_DISTANCE), false) then
		return meleeIcon
	end
	local id = BestRanged()
	if id and InRange(id, unit) then
		return C_Spell.GetSpellTexture(id)
	end
end

function ns.UpdateRangeIcons()
	for unit, icon in pairs(icons) do
		local tex = icon.active and ns.RangeTexture(unit)
		if tex then
			icon.tex:SetTexture(tex)
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
