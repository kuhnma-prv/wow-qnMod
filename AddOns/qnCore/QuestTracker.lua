-- qnCore: smaller font in the Objective Tracker, per profile (= Edit Mode layout).
--
-- Blizzard's slider in Edit Mode ranges from 12 to 20: ObjectiveTrackerManager:SetTextSize
-- rejects smaller values, font templates only exist from ObjectiveTrackerFont12. qnCore therefore
-- sets the size of the two fonts ObjectiveTrackerLineFont and ObjectiveTrackerHeaderFont
-- directly (header 2 larger, as with Blizzard). Blizzard's slider stays untouched.
-- If Blizzard resets the font (layout switch, slider), a hook on SetFontObject restores the
-- own size - even before Blizzard rebuilds the tracker.
-- The tracker is NEVER rebuilt by qnCore: calling ObjectiveTrackerManager:UpdateAll
-- from addon code taints its data; Blizzard's later update (e.g. via
-- Edit Mode on a specialization change) then reads auras in the scenario module
-- (ShouldShowMawBuffs -> C_UnitAuras.GetAuraDataByIndex) and fails on secret values.
-- Blizzard adjusts line spacing on its next own rebuild (quest progress, zone change,
-- at the latest /reload).

local _, ns = ...

local QT = {}
ns.QuestTracker = QT

QT.SIZES = { 8, 9, 10, 11 }   -- choices below Blizzard's minimum

local LINE_BASE, HEADER_BASE = 12, 14   -- templates that file and height come from
local HEADER_EXTRA = 2                  -- like headerExtraSize in Blizzard_ObjectiveTrackerManager.lua

-- font templates last set by Blizzard (default from Blizzard_ObjectiveTrackerFonts.xml)
local blizzLine, blizzHeader = "ObjectiveTrackerFont12", "ObjectiveTrackerFont14"
local applied = 0   -- size currently set by qnCore, 0 = Blizzard's font
local hooked = false

local function Wanted()
	return ns.db and ns.db.questTextSize or 0
end

-- Set font to size. File and height come from Blizzard's template of size base: each alphabet has
-- a different file and height (e.g. Chinese 15 at size 12), hence scale proportionally.
local function SetSize(font, base, size)
	local template = _G["ObjectiveTrackerFont" .. base]
	local path, height, flags = template:GetFont()
	if not path or not height then
		return
	end
	font:SetFont(path, height * size / base, flags or "")
end

local function Override(size)
	SetSize(ObjectiveTrackerLineFont, LINE_BASE, size)
	SetSize(ObjectiveTrackerHeaderFont, HEADER_BASE, size + HEADER_EXTRA)
end

-- Blizzard has set a font template: remember it and restore the own size
local function OnLineFont(_, font)
	blizzLine = font
	if applied > 0 then
		SetSize(ObjectiveTrackerLineFont, LINE_BASE, applied)
	end
end

local function OnHeaderFont(_, font)
	blizzHeader = font
	if applied > 0 then
		SetSize(ObjectiveTrackerHeaderFont, HEADER_BASE, applied + HEADER_EXTRA)
	end
end

local function Hook()
	if hooked or not ObjectiveTrackerManager then
		return false
	end
	hooked = true
	hooksecurefunc(ObjectiveTrackerLineFont, "SetFontObject", OnLineFont)
	hooksecurefunc(ObjectiveTrackerHeaderFont, "SetFontObject", OnHeaderFont)
	return true
end

-- Apply the size of the active profile (option, profile switch, start)
function QT.Apply()
	if not hooked then
		return
	end
	local size = Wanted()
	if size == applied then
		return
	end
	applied = size
	if size > 0 then
		Override(size)
	else
		ObjectiveTrackerLineFont:SetFontObject(blizzLine)
		ObjectiveTrackerHeaderFont:SetFontObject(blizzHeader)
	end
end

function QT.Init()
	if Hook() then
		QT.Apply()
		return
	end
	-- Blizzard_ObjectiveTracker loads before the addons; if not, on its own ADDON_LOADED
	ns.events.Register("ADDON_LOADED", function(_, name)
		if name == "Blizzard_ObjectiveTracker" and Hook() then
			QT.Apply()
		end
	end)
end
