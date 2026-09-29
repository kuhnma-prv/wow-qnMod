-- Scenario 9: qnViewPort – tooltips on bag slots fully on the bag's monitor
--   * Blizzard's anchor (ContainerFrameItemButton_CalculateItemTooltipAnchors) stays if it fits
--   * at the monitor edge: other side or below the slot, remainder pushed inside (like Titan tooltips)
--   * comparison tooltips: side with room on the monitor, pushed up at the bottom
--   * foreign anchor: change nothing

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = { ["account:Raid"] = { dual = { enabled = true } } } }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

-- monitors like Monitors.lua; 1 unit = 1 pixel (abs = pixels, origin bottom left)
local M1 = { l = 0, r = 3840, t = 2160, b = 0 }
local M2 = { l = 3840, r = 5760, t = 2160 - 377, b = 2160 - 377 - 1200 }
vp.Layout.GetVisibleAbs = function() return { M1, M2 } end

local function Place(f, l, b, w, h)
	f.GetLeft = function() return l end
	f.GetBottom = function() return b end
	f._w, f._h = w, h
end
-- GetPoint returns the last set point
local function Pt(f)
	local p = f._points[#f._points]
	return p[1], p[2], p[3], p[4], p[5]
end
-- GameTooltip: the last set point (like Blizzard's single anchor); comparison tooltips: all points
GameTooltip.GetPoint = function(self) return Pt(self) end
for _, f in ipairs({ ShoppingTooltip1, ShoppingTooltip2 }) do
	f.GetNumPoints = function(self) return #(self._points or {}) end
	f.GetPoint = function(self, i) local q = self._points[i or 1] return q[1], q[2], q[3], q[4], q[5] end
end

-- Blizzard's mouse-over-bag-slot emulated (ContainerFrameItemButtonMixin:OnUpdate)
local slot = CreateFrame("ItemButton", "ContainerFrame1Item1", UIParent)
local function Hover(point, relPoint)
	GameTooltip:SetOwner(slot, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint(point, slot, relPoint)
	GameTooltip:SetBagItem(0, 1)
end

-- 1. slot top right on monitor 1, Blizzard attaches the tooltip to the top right: fits neither
--    right (monitor 2 starts only at y 1783) nor above -> left and below the slot
Place(slot, 3780, 2100, 37, 37)
Place(GameTooltip, 0, 0, 300, 400)
Hover("BOTTOMLEFT", "TOPRIGHT")
local p, rel, rp, x, y = Pt(GameTooltip)
Check(p == "TOPRIGHT" and rel == slot and rp == "BOTTOMRIGHT" and x == 0 and y == 0,
	("top right on monitor 1: flipped left and down (%s %s %s %s)"):format(p, rp, x, y))

-- 2. slot at the top of monitor 2: no monitor above -> below the slot
Place(slot, 4000, M2.t - 43, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
p, rel, rp = Pt(GameTooltip)
Check(p == "TOPLEFT" and rp == "BOTTOMLEFT", ("top of monitor 2: below the slot (%s %s)"):format(p, rp))

-- 3. slot on the right of monitor 2, Blizzard attaches to the left: fits, anchor stays
Place(slot, 5600, 1000, 37, 37)
Hover("BOTTOMRIGHT", "TOPLEFT")
p, rel, rp = Pt(GameTooltip)
Check(#GameTooltip._points == 1 and p == "BOTTOMRIGHT" and rp == "TOPLEFT", "fits: Blizzard's anchor stays")

-- 4. slot at the left edge of monitor 2, Blizzard to the left (window center): would reach onto monitor 1
Place(slot, 3850, 1000, 37, 37)
Hover("BOTTOMRIGHT", "TOPLEFT")
p, rel, rp = Pt(GameTooltip)
Check(p == "BOTTOMLEFT" and rp == "TOPLEFT", ("left edge of monitor 2: flipped right (%s %s)"):format(p, rp))

-- 5. again in the next frame (final size): grew larger, no longer fits above
Place(slot, 4000, 1300, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
Check(#GameTooltip._points == 1, "immediately: fits, anchor stays")
GameTooltip._h = 600
RunTimers()
p, rel, rp = Pt(GameTooltip)
Check(p == "TOPLEFT" and rp == "BOTTOMLEFT", ("next frame with final height: below the slot (%s %s)"):format(p, rp))
GameTooltip._h = 400

-- 6. comparison tooltips: GameTooltip at the right edge of monitor 1 -> comparison to its left
local mgr = TooltipComparisonManager
Place(slot, 3700, 1200, 37, 37)
Hover("BOTTOMRIGHT", "TOPLEFT")
Place(GameTooltip, 3400, 1237, 300, 400)
Place(ShoppingTooltip1, 0, 0, 300, 350)
Place(ShoppingTooltip2, 0, 0, 280, 380)
mgr.tooltip, mgr.anchorFrame = GameTooltip, GameTooltip
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, true)
p, rel, rp = Pt(ShoppingTooltip1)
local p2, rel2, rp2 = Pt(ShoppingTooltip2)
Check(p == "TOPRIGHT" and rel == GameTooltip and rp == "TOPLEFT" and p2 == "TOPRIGHT" and rel2 == ShoppingTooltip1 and rp2 == "TOPLEFT",
	("comparison at the right edge of monitor 1: left of the tooltip (%s %s / %s %s)"):format(p, rp, p2, rp2))

-- 7. comparison at the bottom of monitor 2: room on the right, too tall -> pushed up
Place(slot, 4000, 700, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
Place(GameTooltip, 4037, 737, 300, 200)
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, true)
p, rel, rp, x, y = Pt(ShoppingTooltip2)
p2, rel2, rp2 = Pt(ShoppingTooltip1)
Check(p == "TOPLEFT" and rel == GameTooltip and rp == "TOPRIGHT" and y == M2.b - (937 - 380),
	("comparison at the bottom of monitor 2: right, pushed up by %s (%s %s %s)"):format(tostring(y), p, rp, tostring(M2.b - (937 - 380))))
Check(p2 == "TOPLEFT" and rel2 == ShoppingTooltip2 and rp2 == "TOPRIGHT", "second comparison next to it")

-- 8. only one comparison, it fits on the right
Place(GameTooltip, 1000, 1500, 300, 200)
Place(slot, 963, 1463, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
Place(GameTooltip, 1000, 1500, 300, 200)
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, false)
p, rel, rp = Pt(ShoppingTooltip1)
Check(#ShoppingTooltip1._points == 2 and p == "LEFT" and rp == "RIGHT", ("one comparison with room: Blizzard's anchor stays (%s %s)"):format(p, rp))

-- 8a. Blizzard left, fits: stays – also across several refreshes (no flicker)
mgr.testSide = "left"
Place(slot, 3000, 1000, 37, 37)
local sides = {}
for i = 1, 3 do
	Hover("BOTTOMLEFT", "TOPRIGHT")
	Place(GameTooltip, 3037, 1037, 300, 400)
	ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
	mgr:AnchorShoppingTooltips(true, true)
	RunTimers()
	local q = ShoppingTooltip1._points
	sides[i] = #q == 2 and q[2][1] == "RIGHT" and q[2][2] == GameTooltip and q[2][3] == "LEFT"
end
Check(sides[1] and sides[2] and sides[3], "Blizzard left with room: stays left, on every refresh")

-- 8b. Blizzard left, no room (left edge of monitor 2): right – the same on every refresh
Place(slot, 3850, 1000, 37, 37)
for i = 1, 3 do
	Hover("BOTTOMLEFT", "TOPRIGHT")
	Place(GameTooltip, 3887, 1037, 300, 400)
	ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
	mgr:AnchorShoppingTooltips(true, true)
	RunTimers()
	p, rel, rp = Pt(ShoppingTooltip2)
	sides[i] = p == "TOPLEFT" and rel == GameTooltip and rp == "TOPRIGHT"
end
Check(sides[1] and sides[2] and sides[3], "Blizzard left without room on monitor 2: right, on every refresh")
mgr.testSide = nil

-- 9. other frame (no SetBagItem) with GameTooltip: comparison untouched; foreign anchor: untouched
local other = CreateFrame("Button", nil, UIParent)
GameTooltip:SetOwner(other, "ANCHOR_NONE")
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, true)
p = Pt(ShoppingTooltip2)
Check(p == "LEFT", "tooltip of another frame: comparison untouched")
GameTooltip:SetOwner(slot, "ANCHOR_NONE")
GameTooltip:ClearAllPoints()
GameTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 5, 5)
Place(slot, 3780, 2100, 37, 37)
GameTooltip:SetBagItem(0, 1)
Check(#GameTooltip._points == 1 and select(2, Pt(GameTooltip)) == UIParent, "tooltip not anchored to the bag slot: untouched")

-- 10. slot on no monitor (invisible strip above monitor 2): change nothing
Place(slot, 4500, M2.t + 100, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
Check(#GameTooltip._points == 1, "slot on no monitor: anchor stays")

-- 11. interface for other bag views (qnInventory): SetHyperlink instead of SetBagItem
local view = CreateFrame("ItemButton", nil, UIParent)
Place(view, 3780, 2100, 37, 37)
Place(GameTooltip, 0, 0, 300, 400)
GameTooltip:SetOwner(view, "ANCHOR_NONE")
GameTooltip:ClearAllPoints()
GameTooltip:SetPoint("BOTTOMLEFT", view, "TOPRIGHT")
GameTooltip:Show()
qnViewPort.BagTooltip(GameTooltip, view)
p, rel, rp = Pt(GameTooltip)
Check(p == "TOPRIGHT" and rel == view and rp == "BOTTOMRIGHT", ("BagTooltip: adjusted like a bag slot (%s %s)"):format(p, rp))
-- comparison later via Blizzard's event: now belongs to this button
Place(GameTooltip, 3517, 1700, 300, 400)
mgr.tooltip, mgr.anchorFrame = GameTooltip, GameTooltip
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, true)
p, rel, rp = Pt(ShoppingTooltip1)
Check(p == "TOPRIGHT" and rel == GameTooltip and rp == "TOPLEFT", "BagTooltip: comparison afterwards on the monitor (left)")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
