-- Szenario 4: qnInventory – Tooltip eines Gegenstands in den Ansichten (Taschen/Bank/Post)
--   * Anker wie bei Blizzards Taschenplätzen (ContainerFrameItemButton_CalculateItemTooltipAnchors)
--   * mit qnViewPort: danach qnViewPort.BagTooltip (ganz auf den Monitor der Tasche)
--   * ohne qnViewPort: kein Fehler

LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")

local b = inv.CreateItemButton(UIParent)
b._w = 100   -- GetRight der Attrappe = Breite: links der Fenstermitte
local enter = b._scripts.OnEnter

-- ohne Link: kein Tooltip
TOOLTIP = { lines = {} }
enter(b)
Check(TOOLTIP.owner == nil, "ohne Link kein Tooltip")

-- ohne qnViewPort
b.link = "item:100"
GameTooltip:ClearAllPoints()
local ok, err = pcall(enter, b)
Check(ok, "ohne qnViewPort ohne Fehler: " .. tostring(err))
local p = GameTooltip._points[1]
Check(TOOLTIP.owner == b and TOOLTIP.anchor == "ANCHOR_NONE" and p and p[1] == "BOTTOMLEFT" and p[2] == b and p[3] == "TOPRIGHT",
	"Anker wie Blizzards Taschenplatz (links der Mitte: nach oben rechts)")
b._w = 1500   -- rechts der Fenstermitte
GameTooltip:ClearAllPoints()
enter(b)
p = GameTooltip._points[1]
Check(p and p[1] == "BOTTOMRIGHT" and p[3] == "TOPLEFT", "rechts der Mitte: nach oben links")

-- mit qnViewPort (nur die Schnittstelle)
local calls = {}
qnViewPort = { BagTooltip = function(tip, owner) calls[#calls + 1] = { tip, owner } end }
enter(b)
Check(#calls == 1 and calls[1][1] == GameTooltip and calls[1][2] == b, "qnViewPort.BagTooltip mit Tooltip und Knopf aufgerufen")
qnViewPort = nil

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
