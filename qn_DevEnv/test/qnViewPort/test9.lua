-- Szenario 9: qnViewPort – Tooltips auf Taschenplätzen ganz auf dem Monitor der Tasche
--   * Blizzards Anker (ContainerFrameItemButton_CalculateItemTooltipAnchors) bleibt, wenn er passt
--   * am Monitorrand: andere Seite bzw. unter den Platz, Rest hineingeschoben (wie Titan-Tooltips)
--   * Vergleichs-Tooltips: Seite mit Platz auf dem Monitor, unten hochgeschoben
--   * fremder Anker: nichts ändern

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = { ["account:Raid"] = { dual = { enabled = true } } } }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

-- Monitore wie Monitors.lua; 1 Einheit = 1 Pixel (abs = Pixel, Ursprung unten links)
local M1 = { l = 0, r = 3840, t = 2160, b = 0 }
local M2 = { l = 3840, r = 5760, t = 2160 - 377, b = 2160 - 377 - 1200 }
vp.Layout.GetVisibleAbs = function() return { M1, M2 } end

local function Place(f, l, b, w, h)
	f.GetLeft = function() return l end
	f.GetBottom = function() return b end
	f._w, f._h = w, h
end
-- GetPoint liefert den zuletzt gesetzten Punkt
local function Pt(f)
	local p = f._points[#f._points]
	return p[1], p[2], p[3], p[4], p[5]
end
-- GameTooltip: der zuletzt gesetzte Punkt (wie Blizzards einzelner Anker); Vergleichs-Tooltips: alle Punkte
GameTooltip.GetPoint = function(self) return Pt(self) end
for _, f in ipairs({ ShoppingTooltip1, ShoppingTooltip2 }) do
	f.GetNumPoints = function(self) return #(self._points or {}) end
	f.GetPoint = function(self, i) local q = self._points[i or 1] return q[1], q[2], q[3], q[4], q[5] end
end

-- Blizzards Maus-über-Taschenplatz nachgebildet (ContainerFrameItemButtonMixin:OnUpdate)
local slot = CreateFrame("ItemButton", "ContainerFrame1Item1", UIParent)
local function Hover(point, relPoint)
	GameTooltip:SetOwner(slot, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint(point, slot, relPoint)
	GameTooltip:SetBagItem(0, 1)
end

-- 1. Platz oben rechts auf Monitor 1, Blizzard hängt den Tooltip nach oben rechts: passt weder
--    rechts (Monitor 2 beginnt erst bei y 1783) noch oben -> links und unter den Platz
Place(slot, 3780, 2100, 37, 37)
Place(GameTooltip, 0, 0, 300, 400)
Hover("BOTTOMLEFT", "TOPRIGHT")
local p, rel, rp, x, y = Pt(GameTooltip)
Check(p == "TOPRIGHT" and rel == slot and rp == "BOTTOMRIGHT" and x == 0 and y == 0,
	("oben rechts auf Monitor 1: nach links und unten geklappt (%s %s %s %s)"):format(p, rp, x, y))

-- 2. Platz oben auf Monitor 2: darüber liegt kein Monitor -> unter den Platz
Place(slot, 4000, M2.t - 43, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
p, rel, rp = Pt(GameTooltip)
Check(p == "TOPLEFT" and rp == "BOTTOMLEFT", ("oben auf Monitor 2: unter den Platz (%s %s)"):format(p, rp))

-- 3. Platz rechts auf Monitor 2, Blizzard hängt nach links: passt, Anker bleibt
Place(slot, 5600, 1000, 37, 37)
Hover("BOTTOMRIGHT", "TOPLEFT")
p, rel, rp = Pt(GameTooltip)
Check(#GameTooltip._points == 1 and p == "BOTTOMRIGHT" and rp == "TOPLEFT", "passt: Blizzards Anker bleibt")

-- 4. Platz am linken Rand von Monitor 2, Blizzard nach links (Fenstermitte): ragte auf Monitor 1
Place(slot, 3850, 1000, 37, 37)
Hover("BOTTOMRIGHT", "TOPLEFT")
p, rel, rp = Pt(GameTooltip)
Check(p == "BOTTOMLEFT" and rp == "TOPLEFT", ("linker Rand von Monitor 2: nach rechts geklappt (%s %s)"):format(p, rp))

-- 5. im nächsten Frame noch einmal (endgültige Größe): größer geworden, passt nicht mehr darüber
Place(slot, 4000, 1300, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
Check(#GameTooltip._points == 1, "sofort: passt, Anker bleibt")
GameTooltip._h = 600
RunTimers()
p, rel, rp = Pt(GameTooltip)
Check(p == "TOPLEFT" and rp == "BOTTOMLEFT", ("nächster Frame mit endgültiger Höhe: unter den Platz (%s %s)"):format(p, rp))
GameTooltip._h = 400

-- 6. Vergleichs-Tooltips: GameTooltip am rechten Rand von Monitor 1 -> Vergleich links davon
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
	("Vergleich am rechten Rand von Monitor 1: links vom Tooltip (%s %s / %s %s)"):format(p, rp, p2, rp2))

-- 7. Vergleich unten auf Monitor 2: rechts ist Platz, zu hoch -> hochgeschoben
Place(slot, 4000, 700, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
Place(GameTooltip, 4037, 737, 300, 200)
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, true)
p, rel, rp, x, y = Pt(ShoppingTooltip2)
p2, rel2, rp2 = Pt(ShoppingTooltip1)
Check(p == "TOPLEFT" and rel == GameTooltip and rp == "TOPRIGHT" and y == M2.b - (937 - 380),
	("Vergleich unten auf Monitor 2: rechts, um %s hochgeschoben (%s %s %s)"):format(tostring(y), p, rp, tostring(M2.b - (937 - 380))))
Check(p2 == "TOPLEFT" and rel2 == ShoppingTooltip2 and rp2 == "TOPRIGHT", "zweiter Vergleich daneben")

-- 8. nur ein Vergleich, der passt rechts
Place(GameTooltip, 1000, 1500, 300, 200)
Place(slot, 963, 1463, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
Place(GameTooltip, 1000, 1500, 300, 200)
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, false)
p, rel, rp = Pt(ShoppingTooltip1)
Check(#ShoppingTooltip1._points == 2 and p == "LEFT" and rp == "RIGHT", ("ein Vergleich mit Platz: Blizzards Anker bleibt (%s %s)"):format(p, rp))

-- 8a. Blizzard links, passt: bleibt – auch über mehrere Auffrischungen (kein Flackern)
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
Check(sides[1] and sides[2] and sides[3], "Blizzard links mit Platz: bleibt links, bei jeder Auffrischung")

-- 8b. Blizzard links, kein Platz (linker Rand von Monitor 2): rechts – bei jeder Auffrischung gleich
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
Check(sides[1] and sides[2] and sides[3], "Blizzard links ohne Platz auf Monitor 2: rechts, bei jeder Auffrischung")
mgr.testSide = nil

-- 9. anderer Rahmen (kein SetBagItem) mit GameTooltip: Vergleich unberührt; fremder Anker: unberührt
local other = CreateFrame("Button", nil, UIParent)
GameTooltip:SetOwner(other, "ANCHOR_NONE")
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, true)
p = Pt(ShoppingTooltip2)
Check(p == "LEFT", "Tooltip eines anderen Rahmens: Vergleich unberührt")
GameTooltip:SetOwner(slot, "ANCHOR_NONE")
GameTooltip:ClearAllPoints()
GameTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 5, 5)
Place(slot, 3780, 2100, 37, 37)
GameTooltip:SetBagItem(0, 1)
Check(#GameTooltip._points == 1 and select(2, Pt(GameTooltip)) == UIParent, "Tooltip nicht am Taschenplatz verankert: unberührt")

-- 10. Platz auf keinem Monitor (unsichtbarer Streifen über Monitor 2): nichts ändern
Place(slot, 4500, M2.t + 100, 37, 37)
Hover("BOTTOMLEFT", "TOPRIGHT")
Check(#GameTooltip._points == 1, "Platz auf keinem Monitor: Anker bleibt")

-- 11. Schnittstelle für andere Taschenansichten (qnInventory): SetHyperlink statt SetBagItem
local view = CreateFrame("ItemButton", nil, UIParent)
Place(view, 3780, 2100, 37, 37)
Place(GameTooltip, 0, 0, 300, 400)
GameTooltip:SetOwner(view, "ANCHOR_NONE")
GameTooltip:ClearAllPoints()
GameTooltip:SetPoint("BOTTOMLEFT", view, "TOPRIGHT")
GameTooltip:Show()
qnViewPort.BagTooltip(GameTooltip, view)
p, rel, rp = Pt(GameTooltip)
Check(p == "TOPRIGHT" and rel == view and rp == "BOTTOMRIGHT", ("BagTooltip: wie Taschenplatz angepasst (%s %s)"):format(p, rp))
-- Vergleich später über Blizzards Ereignis: gehört jetzt zu diesem Knopf
Place(GameTooltip, 3517, 1700, 300, 400)
mgr.tooltip, mgr.anchorFrame = GameTooltip, GameTooltip
ShoppingTooltip1:ClearAllPoints() ShoppingTooltip2:ClearAllPoints()
mgr:AnchorShoppingTooltips(true, true)
p, rel, rp = Pt(ShoppingTooltip1)
Check(p == "TOPRIGHT" and rel == GameTooltip and rp == "TOPLEFT", "BagTooltip: Vergleich danach auf dem Monitor (links)")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
