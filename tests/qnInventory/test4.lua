-- Scenario 4: qnInventory - item tooltip in the views (bags/bank/mail)
--   * anchor as for Blizzard's bag slots (ContainerFrameItemButton_CalculateItemTooltipAnchors)
--   * with qnViewPort: then qnViewPort.BagTooltip (fully onto the bag's monitor)
--   * without qnViewPort: no error

LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")

local b = inv.CreateItemButton(UIParent)
b._w = 100   -- the stub's GetRight = width: left of the window center
local enter = b._scripts.OnEnter

-- without link: no tooltip
TOOLTIP = { lines = {} }
enter(b)
Check(TOOLTIP.owner == nil, "no tooltip without link")

-- without qnViewPort
b.link = "item:100"
GameTooltip:ClearAllPoints()
local ok, err = pcall(enter, b)
Check(ok, "without qnViewPort without error: " .. tostring(err))
local p = GameTooltip._points[1]
Check(TOOLTIP.owner == b and TOOLTIP.anchor == "ANCHOR_NONE" and p and p[1] == "BOTTOMLEFT" and p[2] == b and p[3] == "TOPRIGHT",
	"anchor like Blizzard's bag slot (left of center: towards top right)")
b._w = 1500   -- right of the window center
GameTooltip:ClearAllPoints()
enter(b)
p = GameTooltip._points[1]
Check(p and p[1] == "BOTTOMRIGHT" and p[3] == "TOPLEFT", "right of center: towards top left")

-- with qnViewPort (interface only)
local calls = {}
qnViewPort = { BagTooltip = function(tip, owner) calls[#calls + 1] = { tip, owner } end }
enter(b)
Check(#calls == 1 and calls[1][1] == GameTooltip and calls[1][2] == b, "qnViewPort.BagTooltip called with tooltip and button")
qnViewPort = nil

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
