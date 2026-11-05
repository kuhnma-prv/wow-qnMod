-- qnUnitFrames: opt-in placement of Blizzard's target frame next to the player frame.
--
-- With "Align target frame" on, the target frame sits with its top edge at the top edge of the
-- player frame, `alignTargetGap` pixels to the right of it. Blizzard (login, Edit Mode layout,
-- moving the frame) places it again; that is noticed via hooksecurefunc and answered in the next
-- frame. While the Edit Mode is open nothing is moved, so it can still be dragged there.
--
-- Taint: the Edit Mode systems override SetPoint and ClearAllPoints with Blizzard code; calling
-- them from addon code would run that code tainted. Therefore the raw widget methods are used
-- (they run no Blizzard Lua code and do not trigger our own hook).

local _, ns = ...
local lib = qnCore

local proto = CreateFrame("Frame")
local RawSetPoint, RawClearAllPoints = proto.SetPoint, proto.ClearAllPoints

local hooked

-- UI units (effective scale 1) of one screen pixel
local function PixelSize()
	local _, height = GetPhysicalScreenSize()
	return 768 / height
end

local function Edit()
	return EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
end

-- Places the target frame; does nothing if off, in the Edit Mode or without both frames.
function ns.AlignTarget()
	local db = ns.db
	if not db or not db.alignTarget or Edit() then
		return
	end
	local frame, player = TargetFrame, PlayerFrame
	if not frame or not player then
		return
	end
	if InCombatLockdown() then
		lib.DeferInCombat(ns.AlignTarget)
		return
	end
	local gap = db.alignTargetGap * PixelSize() / frame:GetEffectiveScale()
	RawClearAllPoints(frame)
	RawSetPoint(frame, "TOPLEFT", player, "TOPRIGHT", gap, 0)
end

-- Starts watching the target frame as soon as the option is on.
function ns.ApplyAlign()
	if ns.db.alignTarget and TargetFrame and not hooked then
		hooked = true
		hooksecurefunc(TargetFrame, "SetPoint", ns.AlignTargetLater)
	end
	ns.AlignTarget()
end

ns.AlignTargetLater = lib.Debounce(function() ns.AlignTarget() end)

function ns.InitAlign()
	ns.events.Register("PLAYER_ENTERING_WORLD", ns.ApplyAlign)
	EventRegistry:RegisterCallback("EditMode.Exit", ns.AlignTargetLater, ns)
end
