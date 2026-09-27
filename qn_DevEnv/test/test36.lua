-- Szenario 36: qnViewPort – kontoweite Werte und Profilwechsel
--   * layoutKey und mapFadeSaved aus alten Profilen nach qnViewPortDB.global übernommen
--   * übernommene Monitoranordnung gilt einmal je Anordnung, nicht einmal je Profil
--   * ohne Zwei-Monitor-Modus, mit Monitordaten: Viewport des Hauptmonitors nicht auf die halbe
--     Fensterbreite gekürzt
--   * Profilwechsel wendet mapFade an und gibt eine begrenzte Oberfläche frei

local KEY = "5760x2160;0,0,3840,2160*;3840,377,1920,1200"   -- Anordnung aus qnViewPort\Monitors.lua
qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = {
	["account:Raid"] = { viewport = { 10, 1920, 0, 0 },
		dual = { enabled = true, mapNoFade = true, mapFadeSaved = "1", layoutKey = KEY } },
	["char:Tester-Realm:Solo"] = { viewport = { 5, 0, 0, 0 }, dual = { enabled = false, layoutKey = "" } },
} }
C_CVar._v.mapFade = "0"   -- von mapNoFade gesetzt (vorher 1)
local CHAT = {}
function DEFAULT_CHAT_FRAME:AddMessage(msg) CHAT[#CHAT + 1] = tostring(msg) end

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
local L = vp.L
-- Meldungen „Monitoranordnung übernommen …“ (Text bis zum Doppelpunkt, in der Sprache des Clients)
local TAKEN = L["Monitoranordnung übernommen: %d Monitore, 3D-Welt auf dem Hauptmonitor (%d × %d)."]:match("^[^:]+")
local function Taken()
	local n = 0
	for _, m in ipairs(CHAT) do if m:find(TAKEN, 1, true) then n = n + 1 end end
	return n
end
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()
local raid, solo = qnViewPortDB.profiles["account:Raid"], qnViewPortDB.profiles["char:Tester-Realm:Solo"]
local g = qnViewPortDB.global

-- 1. Migration
Check(g.layoutKey == KEY and raid.dual.layoutKey == nil and solo.dual.layoutKey == nil,
	"layoutKey kontoweit übernommen, aus den Profilen entfernt: " .. tostring(g.layoutKey))
Check(g.mapFadeSaved == "1" and raid.dual.mapFadeSaved == nil, "mapFadeSaved kontoweit übernommen")
Check(vp.global == g, "ns.global = qnViewPortDB.global")
Check(C_CVar._v.mapFade == "0", "Raid mit mapNoFade: mapFade bleibt 0")
Check(Taken() == 0 and raid.viewport[1] == 10, "bekannte Anordnung: nicht erneut übernommen")

-- 2. Profilwechsel: begrenzte Oberfläche frei, mapFade zurück, Anordnung nicht erneut übernommen
vp.Layout.ConstrainUI()
Check(vp.Layout.IsUIConstrained(), "Raid: Oberfläche auf dem Hauptmonitor")
SetEditModeLayout(4)
Check(vp.db == solo, "Profil Solo aktiv")
local pts = UIParent._points
Check(not vp.Layout.IsUIConstrained() and pts[#pts][1] == "BOTTOMRIGHT" and pts[#pts][2] == 0 and pts[#pts][3] == 0,
	"Solo ohne Zwei-Monitor-Modus: Oberfläche wieder über das ganze Fenster")
Check(C_CVar._v.mapFade == "1" and g.mapFadeSaved == nil, "Solo ohne mapNoFade: mapFade 1 wiederhergestellt")
Check(Taken() == 0 and solo.viewport[1] == 5, "Solo: Anordnung nicht erneut übernommen, Viewport bleibt")
SetEditModeLayout(3)
Check(C_CVar._v.mapFade == "0" and g.mapFadeSaved == "1", "zurück auf Raid: mapFade 0, 1 gemerkt")
Check(not vp.Layout.IsUIConstrained(), "Profilwechsel begrenzt die Oberfläche nicht von selbst")

-- 3. Neue Anordnung ohne Zwei-Monitor-Modus: kleiner Hauptmonitor links, großer rechts.
-- Fenster 2880 × 1080 (gleiches Seitenverhältnis): Hauptmonitor 960 × 540, rechts 1920 Pixel frei.
SetEditModeLayout(4)
qnViewPortMonitors = { window = { x = 0, y = 0, width = 5760, height = 2160 }, monitors = {
	{ x = 0, y = 0, width = 1920, height = 1080, main = true },
	{ x = 1920, y = 0, width = 3840, height = 2160 },
} }
C_VideoOptions.GetCurrentGameWindowSize = function() return { x = 2880, y = 1080 } end
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
local v = solo.viewport
Check(Taken() == 1 and v[1] == 0 and v[2] == 1920 and v[3] == 0 and v[4] == 540,
	("Solo: Hauptmonitor übernommen, nicht auf die halbe Breite gekürzt: %d %d %d %d"):format(v[1], v[2], v[3], v[4]))
Check(g.layoutKey ~= KEY, "neue Anordnung kontoweit gemerkt")
SetEditModeLayout(3)
Check(Taken() == 1 and raid.viewport[1] == 10 and raid.viewport[2] == 1920,
	"Raid: dieselbe Anordnung nicht noch einmal übernommen, Viewport bleibt")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
