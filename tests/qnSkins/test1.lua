-- Scenario 1: qnSkins - positioning of the elements (raw methods, UI scale, skin scale),
-- re-applying after Blizzard moved an element, combat, Edit Mode, artwork rectangles
LoadAddon("qnCore")
local skins = LoadAddon("qnSkins")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local L = skins.L

-- The skin's band is a straight line; the shapes the band can also draw (wave with raised parts,
-- inner and upper line) are tested with this spec in place of it.
local FLAT_BAND = skins.skins.dragonlair.art[1]
local WAVE_BAND = { key = "band", kind = "band", bg = FLAT_BAND.bg, bgColor = FLAT_BAND.bgColor,
	lineColor = FLAT_BAND.lineColor, rope = FLAT_BAND.rope, ropeThickness = 6, grade = 0.4, corner = 16,
	inner = { gap = 14, grade = 0.9 }, upper = { group = "center", reachLeft = 270, reachRight = 220 },
	base = { rel = { "bar1" }, pad = 6, drop = 10, left = { "zonemap", "possess", "extra" }, leftPad = 4 },
	raise = {
		{ key = "center", around = { "status1", "status2", "menu", "bar2", "bar1", "pet", "vehicle" }, pad = { 14, 14, 8 }, rise = 20 },
		{ key = "right", around = { "threat", "numpad" }, pad = { 2, 10, 8 }, rise = 20, edge = "right" },
	} }
skins.skins.dragonlair.art[1] = WAVE_BAND
-- a figure filling an area between two points (the skin had one: the dragon above the micro menu)
table.insert(skins.skins.dragonlair.art, { key = "dragon", kind = "model", creature = 10184, animation = 100, rotation = 0.9,
	zoom = 1, from = { "menu", "TOPLEFT", 0, 38 }, to = { "bar1", "TOPLEFT", -4, 50 } })
local Art = skins.Art

-- last point of a frame as "x,y" (offsets to UIParent BOTTOMLEFT)
local function At(f)
	local p = f._points and f._points[#f._points]
	if not p then return "none" end
	return ("%s %s %g,%g"):format(p[1], p[2] == UIParent and "UIParent" or "?", p[4], p[5])
end
local function Near(a, b) return math.abs(a - b) < 0.01 end

-- possess bar and extra abilities hidden, still at the position of an old layout (top of the screen)
PossessActionBar.GetBottom = function() return 900 end
ExtraAbilityContainer.GetBottom = function() return 900 end

-- no skin: nothing moved, no artwork
Check(skins.db.skin == "none", "default: no skin")
Check(At(MainActionBar) == "none", "default: action bar untouched")

-- skin without positioning: artwork only, elements stay
skins.store:Set("skin", "dragonlair")
RunTimers()
Check(At(MainActionBar) == "none", "without 'Position elements' the elements stay")
Check(Art.Get("band") and Art.Get("band"):IsShown(), "band shown")
Check(Art.Get("warrior") and Art.Get("warrior"):IsShown(), "warrior shown")

-- positioning (UIParent 1920 x 1080, scale 1)
local overrides = EDIT_MODE_OVERRIDE_CALLS
skins.store:Set("position", true)
RunTimers()
Check(EDIT_MODE_OVERRIDE_CALLS == overrides, "only raw widget methods used (no Edit Mode override)")
Check(At(MainStatusTrackingBarContainer) == "BOTTOMLEFT UIParent 545,2", "status bar 1 centered at the bottom: " .. At(MainStatusTrackingBarContainer))
Check(At(SecondaryStatusTrackingBarContainer) == "BOTTOMLEFT UIParent 545,13", "status bar 2 above: " .. At(SecondaryStatusTrackingBarContainer))
Check(At(MicroMenuContainer) == "BOTTOMLEFT UIParent 545,26", "micro menu above the status bars: " .. At(MicroMenuContainer))
Check(At(MultiBarRight) == "none" and At(MultiBarLeft) == "none", "action bars 4 and 5 left alone")
Check(At(MultiBarBottomLeft) == "BOTTOMLEFT UIParent 839,68", "action bar 2 above the row right of the menu: " .. At(MultiBarBottomLeft))
Check(At(MainActionBar) == "BOTTOMLEFT UIParent 839,115", "action bar 1 above: " .. At(MainActionBar))
Check(At(PetActionBar) == "BOTTOMLEFT UIParent 1049,164", "pet bar right above: " .. At(PetActionBar))
Check(At(MainMenuBarVehicleLeaveButton) == "BOTTOMLEFT UIParent 839,164", "vehicle button left above: " .. At(MainMenuBarVehicleLeaveButton))

-- artwork around the elements
local bd = Art.Get("band")
-- line height at x (UI units = units here, UI scale 1)
local function LineAt(x, pts)
	pts = pts or bd.shape.points
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		if x >= a[1] and x <= b[1] then
			return a[2] + (b[2] - a[2]) * (x - a[1]) / math.max(b[1] - a[1], 1e-9)
		end
	end
	return -1   -- beyond the end of the line
end
local function MinBetween(x1, x2)
	local m = math.huge
	for x = x1, x2 do m = math.min(m, LineAt(x)) end
	return m
end
-- base = top of action bar 1 (160) + 6 = 166; center = cluster up to the vehicle button (196) + 8 = 204,
-- at least base + 20; left edge = base + 10 = 176
Check(At(bd) == "BOTTOMLEFT UIParent 0,0" and bd._w == 1920 and bd._h == 204, "band over the full width, as high as the line at the left edge: " .. At(bd) .. " " .. bd._w .. "x" .. bd._h)
-- upper line: from the left edge along the main line (176 down to 166 at 436) to 270 before the cluster
-- (x 261, y 170.0), straight up to the corner (531, 204), flat, straight down from (1393, 204) into the
-- inner line 220 further right (1613, 152) and ends there
local upper = bd.shape.points
local py = 176 - 10 * 261 / 436
Check(Near(LineAt(0), 176) and math.abs(LineAt(125) - (176 - 10 * 125 / 436)) < 0.01, "upper line falls gently from the left edge: " .. LineAt(125))
Check(math.abs(MinBetween(0, 530) - py) < 0.6, "upper line turns up 270 before the cluster: " .. MinBetween(0, 530))
Check(math.abs(LineAt(396) - (py + 135 * (204 - py) / 270)) < 0.1, "upper line rises straight to the corner: " .. LineAt(396))
Check(Near(LineAt(545), 204) and Near(LineAt(960), 204) and Near(LineAt(1380), 204), "flat just above the bar cluster")
Check(math.abs(LineAt(1503) - (204 - 110 * 52 / 220)) < 0.1, "upper line falls once straight right of the cluster: " .. LineAt(1503))
local last = upper[#upper]
Check(Near(last[1], 1613) and Near(last[2], 152), ("upper line ends on the inner line: %.1f,%.1f"):format(last[1], last[2]))
-- inner line: 14 lower at the sides, gradient 0.9 (foot at 531 - 52 / 0.9), runs into the main line over the cluster
local inner = bd.shape.inner
Check(Near(LineAt(0, inner), 162) and Near(LineAt(300, inner), 162 - 10 * 300 / (531 - 52 / 0.9)) and Near(LineAt(1700, inner), 152), "inner line parallel 14 below at the sides")
Check(Near(LineAt(507, inner), 152 + (507 - (531 - 52 / 0.9)) * 0.9) and Near(LineAt(960, inner), 204), "inner line rises later and steeper and runs into the main line over the cluster")local below = true
for x = 0, upper[#upper][1] - 1, 7 do
	if LineAt(x, inner) > LineAt(x) + 0.01 then below = false end
end
Check(below, "inner line never above the upper line")
local rope = 0
for i = 1, bd.lines.used do
	if bd.lines[i]._texture == "Interface\\AddOns\\qnSkins\\Media\\Rope" then rope = rope + 1 end
end
Check(rope == #bd.shape.points - 1 + #inner - 1, "cord texture on every piece of both lines: " .. rope)local box = Art.Get("boxBars")
Check(At(box) == "BOTTOMLEFT UIParent 539,-2" and box._w == 846 and box._h == 168, "box around the bars: " .. At(box) .. " " .. box._w .. "x" .. box._h)
local dragon, warrior = Art.Get("dragon"), Art.Get("warrior")
Check(At(dragon) == "BOTTOMLEFT UIParent 545,104" and dragon._w == 290 and dragon._h == 106, "dragon lies on the micro menu left of action bars 1 and 2: " .. At(dragon) .. " " .. dragon._w .. "x" .. dragon._h)
Check(At(warrior) == "BOTTOMLEFT UIParent 1335,-38" and warrior._h == 240, "warrior behind the right end of the status bars: " .. At(warrior))

-- qnThreatMeter and qnNumKeyPad: the band rises around them as well
local threat = CreateFrame("Frame", "qnThreatMeterFrame", UIParent)
threat._w, threat._h, threat.GetLeft = 200, 100, function() return 1550 end
local numpad = CreateFrame("Frame", "qnNumKeyPadBar", UIParent)
numpad._w, numpad._h, numpad.GetLeft = 150, 100, function() return 1700 end
skins.Refresh()
RunTimers()
-- right group: threat meter 1486..1686 and numpad 1700..1850 plus pad (1476..), at least base + 28 = 228
-- little room: the inner line falls and rises in a V at 1448.5 (204 - 55.5 * 0.9 = 154.05)
local v = math.huge
for x = 1394, 1483 do v = math.min(v, LineAt(x, bd.shape.inner)) end
Check(v > 154 and v < 160, "between center and threat meter the inner line meets in a (rounded) V: " .. v)
Check(Near(LineAt(1490, bd.shape.inner), 186) and Near(LineAt(1919, bd.shape.inner), 186), "inner line rises just before the threat meter and runs to the right edge")
local up = bd.shape.points[#bd.shape.points]
Check(math.abs(up[1] - (1484 - 34 / 0.9)) < 0.1 and Near(up[2], LineAt(up[1], bd.shape.inner)), ("upper line ends in the dip before the inner line rises again: %.1f,%.1f"):format(up[1], up[2]))
Check(Near(LineAt(1919, bd.shape.inner), 186), "inner line runs into the main line over threat meter and numpad")
Check(At(threat) == "BOTTOMLEFT UIParent 1486,0" and At(numpad) == "none", "threat meter left of the numpad with a gap, numpad not moved: " .. At(threat))
Check(threat:GetScale() == 1 and threat._scale == nil, "threat meter keeps its own scale")
Check(Art.Get("boxThreat"):IsShown() and Art.Get("boxNumpad"):IsShown(), "boxes around threat meter and numpad")
Check(bd._h == 204, "hidden possess bar and extra abilities at the top of the screen ignored: " .. bd._h)
-- hidden possess bar at its Edit Mode position left of the cluster (300..390, top 170): both lines stay
-- above it (plus 4): the lowest height left of the cluster rises to 170 + 4 + 14 = 188
PossessActionBar.GetLeft = function() return 300 end
PossessActionBar.GetBottom = function() return 140 end
skins.Refresh()
RunTimers()
Check(bd._h == 204 and LineAt(390, bd.shape.inner) >= 173.9 and LineAt(300, bd.shape.inner) >= 173.9, "lines stay above the hidden possess bar left of the cluster: " .. LineAt(390, bd.shape.inner))
PossessActionBar.GetBottom = function() return 900 end
-- the skin's own band: one straight line 4 above the highest element at the bottom (here the threat
-- meter window is not placed, the vehicle button top 196 is the highest), over the full width
skins.skins.dragonlair.art[1] = FLAT_BAND
skins.Refresh()
RunTimers()
local flat = bd.shape.points
Check(#flat == 2 and Near(flat[1][1], 0) and Near(flat[2][1], 1920) and Near(flat[1][2], 200) and Near(flat[2][2], 200) and not bd.shape.inner,
	("skin band: one horizontal line just above all elements: %.1f..%.1f at %.1f"):format(flat[1][1], flat[#flat][1], flat[1][2]))
local thin = 0
for i = 1, bd.lines.used do
	if bd.lines[i]._texture == FLAT_BAND.rope and bd.lines[i]._thickness == 4 then thin = thin + 1 end
end
Check(thin == 1, "cord 4 units thick")
skins.skins.dragonlair.art[1] = WAVE_BAND
skins.Refresh()
RunTimers()

-- Blizzard moves an element (Edit Mode layout): applied again in the next frame
MainActionBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 50)
Check(At(MainActionBar) == "BOTTOM UIParent 0,50", "Blizzard moved action bar 1")
RunTimers()
Check(At(MainActionBar) == "BOTTOMLEFT UIParent 839,115", "position restored after Blizzard's SetPoint")

-- figures stand still in combat
Check(skins.db.pauseInCombat == true and not Art.paused, "figures move out of combat")
FireEvent("PLAYER_REGEN_DISABLED")
Check(Art.paused == true, "figures paused in combat")
FireEvent("PLAYER_REGEN_ENABLED")
Check(Art.paused == false, "figures move again after combat")
skins.store:Set("pauseInCombat", false)
FireEvent("PLAYER_REGEN_DISABLED")
Check(Art.paused == false, "option off: figures keep moving in combat")
FireEvent("PLAYER_REGEN_ENABLED")
skins.store:Set("pauseInCombat", true)

-- in combat only after combat
QN_COMBAT = true
MainActionBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 50)
RunTimers()
Check(At(MainActionBar) == "BOTTOM UIParent 0,50", "protected bar not moved in combat")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
RunTimers()
Check(At(MainActionBar) == "BOTTOMLEFT UIParent 839,115", "position restored after combat")

-- Edit Mode: the user arranges freely, afterwards the skin applies again
QN_EDIT_MODE = true
EventRegistry:TriggerEvent("EditMode.Enter")
MainActionBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 50)
RunTimers()
Check(At(MainActionBar) == "BOTTOM UIParent 0,50", "not moved while the Edit Mode is active")
QN_EDIT_MODE = false
EventRegistry:TriggerEvent("EditMode.Exit")
RunTimers()
Check(At(MainActionBar) == "BOTTOMLEFT UIParent 839,115", "applied again after the Edit Mode")

-- skin scale 2: elements twice as large, offsets in their own (scaled) units
skins.store:Set("scale", 2)
RunTimers()
Check(MainStatusTrackingBarContainer:GetScale() == 2, "status bar scaled to 2")
Check(At(MainStatusTrackingBarContainer) == "BOTTOMLEFT UIParent 65,2", "status bar 1 at scale 2: " .. At(MainStatusTrackingBarContainer))
skins.store:Set("scale", 1)

-- UI scale 0.5: the same offsets in UI units
UIParent.GetEffectiveScale = function() return 0.5 end
FireEvent("UI_SCALE_CHANGED")
RunTimers()
Check(At(MainStatusTrackingBarContainer) == "BOTTOMLEFT UIParent 545,2", "UI scale 0.5: same offsets in UI units: " .. At(MainStatusTrackingBarContainer))
Check(At(bd) == "BOTTOMLEFT UIParent 0,0" and Near(bd._w, 1920), "UI scale 0.5: band unchanged in UI units: " .. At(bd))
UIParent.GetEffectiveScale = nil

-- two monitors (qnViewPort): chosen monitor 2 on the right half
qnCore.Visible.SetAreaProvider(function()
	return { { l = 960, r = 1920, t = 1080, b = 0 }, { l = 0, r = 960, t = 1080, b = 0 } }
end)
skins.store:Set("monitor", 2)
RunTimers()
Check(At(MainStatusTrackingBarContainer) == "BOTTOMLEFT UIParent 1025,2", "monitor 2 (right): " .. At(MainStatusTrackingBarContainer))
skins.store:Set("offsetX", -100)
RunTimers()
Check(At(MainStatusTrackingBarContainer) == "BOTTOMLEFT UIParent 925,2", "horizontal offset: " .. At(MainStatusTrackingBarContainer))
qnCore.Visible.SetAreaProvider(nil)

-- other skin: artwork of the first one hidden
skins.store:Set("skin", "stoneframe")
RunTimers()
Check(not dragon:IsShown() and not warrior:IsShown(), "figures of the dragon skin hidden")
Check(not bd:IsShown() and Art.Get("backdrop"):IsShown(), "panel of the stone frame shown, band hidden")

-- trying out a model
skins.store:Set("skin", "dragonlair")
RunTimers()
SlashCmdList.QNSKINS("model dragon d:8570 5 1.2")
Check(dragon.spec.display == 8570 and dragon.spec.animation == 5 and dragon.spec.rotation == 1.2, "model tried out")
SlashCmdList.QNSKINS("model backdrop 1")
SlashCmdList.QNSKINS("help")
SlashCmdList.QNSKINS("list")
SlashCmdList.QNSKINS("frames")
SlashCmdList.QNSKINS("apply")

SlashCmdList.QNSKINS("camera dragon 1.5 0 -0.3")
RunTimers()
Check(dragon.spec.zoom == 1.5 and dragon.spec.position[3] == -0.3 and dragon.spec.display == 8570, "camera tried out, tried model kept")
Check(skins.db[skins.FigureKey("dragonlair", "dragon", "zoom")] == 1.5 and skins.db[skins.FigureKey("dragonlair", "dragon", "animation")] == 5,
	"camera values and animation stored in the profile")
-- page "Figures": a slider changes the figure at once
skins.store:Set(skins.FigureKey("dragonlair", "dragon", "height"), 2.5)
skins.store:Set(skins.FigureKey("dragonlair", "warrior", "rotation"), 1)
RunTimers()
Check(dragon.spec.position[3] == 2.5 and warrior.spec.rotation == 1, "figure settings applied without reload")
-- area of a figure extended downwards: the frame grows (the model is cut off at its frame)
local h0, b0 = dragon._h, dragon._points[#dragon._points][5]
skins.store:Set(skins.FigureKey("dragonlair", "dragon", "areaBottom"), 60)
RunTimers()
Check(Near(dragon._h, h0 + 60) and Near(dragon._points[#dragon._points][5], b0 - 60), "figure area extended downwards: " .. dragon._h)
skins.store:Set(skins.FigureKey("dragonlair", "dragon", "areaBottom"), 0)
RunTimers()
Check(skins.defaults[skins.FigureKey("dragonlair", "warrior", "animation")] == 0 and skins.defaults[skins.FigureKey("dragonlair", "warrior", "rotation")] == -0.4,
	"figure defaults from the skin")

-- the warrior is a city guard of the player's faction
Check(warrior.spec.creature == 68, "Alliance: Stormwind City Guard")
local faction = UnitFactionGroup
UnitFactionGroup = function() return "Horde" end
skins.Refresh()
RunTimers()
Check(warrior.spec.creature == 3296, "Horde: Orgrimmar Grunt")
UnitFactionGroup = faction
skins.Refresh()
RunTimers()
Check(warrior.spec.creature == 68, "back to the Alliance guard")

-- no skin: everything hidden
skins.store:Set("skin", "none")
RunTimers()
Check(not Art.Get("backdrop") and not bd:IsShown() and not dragon:IsShown(), "no skin: artwork hidden")
Check(#skins.SkinEntries() == 3 and skins.SkinEntries()[1][2] == L["None"], "dropdown: none + 2 skins")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
