-- Scenario 12: qnViewPort – talent window on a monitor ("Placement" page, option "talents")
--   * without the option qnViewPort does not touch the window
--   * one anchor on UIParent: same point and offsets, on the selected monitor
--   * several anchors: same offset of the center, measured from the monitor's center
--   * re-anchoring by the panel manager (ShowUIPanel/UpdateUIPanelPositions) is followed up
--   * switching off restores Blizzard's anchors

qnViewPortMonitors = { window = { x = 0, y = 0, width = 5760, height = 2160 }, monitors = {
	{ x = 0, y = 0, width = 3840, height = 2160, main = true },
	{ x = 3840, y = 377, width = 1920, height = 1200 },
} }
C_VideoOptions.GetCurrentGameWindowSize = function() return { x = 5760, y = 2160 } end
qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = { ["account:Raid"] = { dual = { enabled = true } } } }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()

vp.screenRef:SetSize(3413, 1280)
UIParent:SetSize(3413, 1280)
vp.Dual.ApplyAll()

local d = vp.db.dual
local second
for i, r in ipairs(vp.Layout.GetVisible()) do
	if r.x == 3840 then second = i end
end
Check(second ~= nil, "2nd monitor in the selection")
local ux = vp.UnitsPerPixel()
local function OnSecond(area)
	local p = (area._points or {})[1] or {}
	return p[1] == "TOPLEFT" and p[2] == vp.screenRef and math.abs(p[4] - 3840 * ux) < 0.01
end

-- Blizzard_PlayerSpells loads on demand: PlayerSpellsFrame, anchors read back from _points
local f = CreateFrame("Frame", "PlayerSpellsFrame", UIParent)
f.GetNumPoints = function(self) return #(self._points or {}) end
f.GetPoint = function(self, i)
	local p = (self._points or {})[i or 1]
	if p then return p[1], p[2], p[3], p[4], p[5] end
end
f:Hide()
f:SetPoint("TOP", UIParent, "TOP", 0, -100)   -- like the panel manager: one anchor on UIParent
FireEvent("ADDON_LOADED", "Blizzard_PlayerSpells")
local function P(i) return (f._points or {})[i or 1] or {} end

-- 1. without option: untouched
ShowUIPanel(f) RunTimers()
Check(#f._points == 1 and P()[2] == UIParent, "without option: on UIParent")
f:Hide()

-- 2. option on: same anchor, on the 2nd monitor
d.talents, d.talentsMonitor = true, second
vp.Dual.ApplyAll()
ShowUIPanel(f) RunTimers()
local p = P()
Check(#f._points == 1 and p[1] == "TOP" and p[3] == "TOP" and p[2] ~= UIParent and OnSecond(p[2])
	and p[4] == 0 and p[5] == -100, "one anchor: same point and offsets on the 2nd monitor")
local area = p[2]

-- 3. Blizzard re-anchors (another window opens): placed again
f:ClearAllPoints()
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 400, -116)
UpdateUIPanelPositions(f) RunTimers()
p = P()
Check(#f._points == 1 and p[1] == "TOPLEFT" and p[2] == area and p[4] == 400 and p[5] == -116,
	"re-anchored by Blizzard: on the monitor again")

-- 4. several anchors: center offset from UIParent's center, measured from the area's center
f:ClearAllPoints()
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -100, 100)
local ucx, ucy = UIParent:GetCenter()
f.GetCenter = function() return ucx + 120, ucy - 40 end
UpdateUIPanelPositions(f) RunTimers()
p = P()
Check(#f._points == 1 and p[1] == "CENTER" and p[2] == area and p[3] == "CENTER"
	and math.abs(p[4] - 120) < 0.01 and math.abs(p[5] + 40) < 0.01,
	("several anchors: center offset kept on the monitor (%s %s)"):format(tostring(p[4]), tostring(p[5])))
f.GetCenter = nil

-- 5. switched off: Blizzard's anchors restored
d.talents = false
vp.Dual.ApplyAll()
Check(#f._points == 2 and P(1)[1] == "TOPLEFT" and P(1)[2] == UIParent and P(2)[1] == "BOTTOMRIGHT"
	and P(2)[4] == -100, "switched off: Blizzard's anchors restored")

-- 6. off: further layouts are not touched
f:ClearAllPoints()
f:SetPoint("TOP", UIParent, "TOP", 0, -100)
UpdateUIPanelPositions(f) RunTimers()
Check(#f._points == 1 and P()[2] == UIParent, "switched off: later layouts untouched")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
