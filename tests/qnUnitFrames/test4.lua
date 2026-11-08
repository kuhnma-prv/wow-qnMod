---------------------------------------------------------------------------
-- Scenario 4: qnUnitFrames - target frame next to the player frame (opt-in): placement with the
-- raw widget methods (top edge, gap in screen pixels), re-applied when Blizzard moves the frame,
-- not in the Edit Mode, deferred in combat, sanitize of the new values, settings version 1.3
---------------------------------------------------------------------------

-- Profile of the last session (settings version 1.2) with broken values
qnCoreCharDB = { layout = "preset:1" }
qnUnitFramesDB = { global = {}, settingsVersion = "1.2", profiles = {
	["preset:1"] = { alignTarget = "yes", alignTargetGap = 9999 },
} }

local player = CreateFrame("Button", "PlayerFrame", UIParent)
local target = CreateFrame("Button", "TargetFrame", UIParent)

LoadAddon("qnCore")
local uf = LoadAddon("qnUnitFrames")
local db = qnUnitFramesDB.profiles["preset:1"]

Check(qnUnitFramesDB.settingsVersion == "1.3", "settings version 1.3")
Check(db.alignTarget == false and db.alignTargetGap == 400, "broken values: flag back to the default (off), gap limited to 400 px")

SetEditModeLayout(1)
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD")
RunTimers()
Check(target._points == nil, "off by default: target frame untouched")

uf.store:Set("alignTargetGap", 40)
local PIXEL = 768 / 2160   -- stub: 5760x2160 screen
local function Placed()
	local p = target._points and target._points[#target._points]
	return p and p[1] == "TOPLEFT" and p[2] == player and p[3] == "TOPRIGHT"
		and math.abs(p[4] - 40 * PIXEL) < 1e-6 and p[5] == 0
end

SlashCmdList.QNUNITFRAMES("aligntarget")
Check(db.alignTarget == true, "/qnuf aligntarget turns the option on")
Check(Placed(), "top left of the target frame on the top right of the player frame, 40 px")
Check(#target._points == 1, "only one anchor point (cleared before)")

-- Blizzard places the frame again (layout) -> placed again in the next frame
target:ClearAllPoints()
target:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200)
RunTimers()
Check(Placed(), "Blizzard moved the frame: placed again")

-- gap
uf.store:Set("alignTargetGap", 100)
local p = target._points[#target._points]
Check(math.abs(p[4] - 100 * PIXEL) < 1e-6, "gap 100 px")
uf.store:Set("alignTargetGap", 40)

-- Edit Mode: nothing is moved; afterwards placed again
QN_EDIT_MODE = true
target:ClearAllPoints()
target:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200)
RunTimers()
Check(target._points[1][2] == UIParent, "Edit Mode: frame stays where it was put")
QN_EDIT_MODE = false
EventRegistry:TriggerEvent("EditMode.Exit")
RunTimers()
Check(Placed(), "after the Edit Mode: placed again")

-- combat: deferred
QN_COMBAT = true
target:ClearAllPoints()
target:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200)
RunTimers()
Check(target._points[1][2] == UIParent, "combat: not moved")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(Placed(), "after combat: placed")

-- off: no longer moved
uf.store:Set("alignTarget", false)
target:ClearAllPoints()
target:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200)
RunTimers()
Check(target._points[1][2] == UIParent, "off: Blizzard's position stays")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
