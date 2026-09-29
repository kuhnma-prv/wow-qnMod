-- Szenario 8: qnViewPort – Weltkarte auf einem Monitor (Seite „Platzierung“)
--   * maximierte Weltkarte („worldMap“): Größe wie Blizzards UpdateMaximizedSize, aber aus dem
--     gewählten Monitor; oben mittig am Monitor, schwarze Fläche nur dort
--   * verkleinert = „Karte & Questlog“ („questLog“): Blizzards Anker (UIParent TOPLEFT) an den Monitor
--   * Neuanordnung durch die Fensterverwaltung (ShowUIPanel/UpdateUIPanelPositions) wird nachgezogen
--   * ohne Option fasst qnViewPort die Karte nicht an; Abschalten stellt Blizzards Lage wieder her

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

-- realistische Fläche: 5760 × 2160 Pixel bei UI-Skalierung wie im Client (1 Einheit ≈ 1,69 Pixel)
vp.screenRef:SetSize(3413, 1280)
UIParent:SetSize(3413, 1280)
vp.Dual.ApplyAll()

local f = WorldMapFrame
local d = vp.db.dual
local function P(frame, i) return (frame._points or {})[i or 1] or {} end
-- Nummer des 2. Monitors in der Auswahl (wie auf der Seite „Monitore“)
local second
for i, r in ipairs(vp.Layout.GetVisible()) do
	if r.x == 3840 then second = i end
end
Check(second ~= nil, "2. Monitor in der Auswahl")
local ux = vp.UnitsPerPixel()
local function OnSecond(area)
	local p = P(area)
	return p[1] == "TOPLEFT" and p[2] == vp.screenRef and math.abs(p[4] - 3840 * ux) < 0.01
end

-- 1. Ohne Option: Blizzards Lage bleibt
ShowUIPanel(f) f:Maximize() RunTimers()
Check(P(f)[1] == "TOP" and P(f)[2] == UIParent, "ohne Option: maximierte Karte an UIParent")
Check(P(f.BlackoutFrame)[2] == UIParent, "ohne Option: schwarze Fläche über UIParent")
f:Minimize() RunTimers()
Check(P(f)[1] == "TOPLEFT" and P(f)[2] == UIParent and P(f)[4] == 16, "ohne Option: verkleinerte Karte an UIParent")

-- 2. Maximierte Karte auf den 2. Monitor
d.worldMap, d.worldMapMonitor = true, second
vp.Dual.ApplyAll()
f:Maximize() RunTimers()
local area = P(f)[2]
Check(P(f)[1] == "TOP" and area ~= UIParent and P(f)[3] == "TOP" and OnSecond(area), "maximiert: oben mittig am 2. Monitor")
Check(P(f.BlackoutFrame)[1] == "ALL" and P(f.BlackoutFrame)[2] == area, "maximiert: schwarze Fläche nur auf dem Monitor")
-- Blizzards Rechnung mit der Monitorfläche: Breite aus der Höhe begrenzt durch die Monitorbreite - 30
local aw, ah = area:GetWidth(), area:GetHeight()
local unclamped = (ah - 67) * 702 / (534 - 67)
local w = math.min(aw - 30, unclamped)
Check(math.abs(aw - 1920 * ux) < 0.01 and f._w == math.floor(w) and f._h == math.floor((ah - 67) * (w / unclamped) + 67)
	and f._w > 0 and f._w <= aw - 30,
	("maximiert: Größe aus dem Monitor (%s × %s in %s × %s)"):format(f._w, f._h, aw, ah))
-- Fensterverwaltung setzt die Karte neu: wird nachgezogen
UpdateUIPanelPositions(f)
Check(P(f)[2] == area, "nach UpdateUIPanelPositions wieder am Monitor")

-- 3. Verkleinert ohne questLog: Blizzards Lage, schwarze Fläche zurück
f:Minimize() RunTimers()
Check(P(f)[2] == UIParent and P(f.BlackoutFrame)[2] == UIParent, "verkleinert ohne questLog: an UIParent, Fläche zurück")

-- 4. „Karte & Questlog“ auf den 2. Monitor: Blizzards Anker am Monitor
d.questLog, d.questLogMonitor = true, second
vp.Dual.ApplyAll()
local p = P(f)
local qArea = p[2]
Check(p[1] == "TOPLEFT" and qArea ~= UIParent and p[3] == "TOPLEFT" and p[4] == 16 and p[5] == -116 and OnSecond(qArea),
	"Karte & Questlog: Blizzards Versatz am 2. Monitor")
ShowUIPanel(f) RunTimers()
Check(P(f)[2] == qArea and P(f)[4] == 16, "nach ShowUIPanel wieder am Monitor, Versatz nicht doppelt")

-- 5. Abschalten: zurück zu Blizzards Lage
d.questLog = false
vp.Dual.ApplyAll()
Check(P(f)[2] == UIParent and P(f)[4] == 16 and P(f)[5] == -116, "questLog aus: wieder an UIParent")
f:Maximize() RunTimers()
Check(P(f)[2] ~= UIParent, "maximiert mit worldMap: am Monitor")
d.worldMap = false
vp.Dual.ApplyAll()
Check(P(f)[1] == "TOP" and P(f)[2] == UIParent and P(f.BlackoutFrame)[2] == UIParent, "worldMap aus: wieder an UIParent")
f:Minimize() f:Maximize() RunTimers()
Check(P(f)[2] == UIParent, "danach fasst qnViewPort die Karte nicht mehr an")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
