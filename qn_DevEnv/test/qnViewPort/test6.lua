-- Szenario 6: qnViewPort – ausdrücklich gewählte Begrenzung der Oberfläche auf den Hauptmonitor
-- bleibt erhalten: nach Blizzards UpdateUIParentPosition (PLAYER_ENTERING_WORLD), bei neuer
-- UI-Skalierung bzw. Fenstergröße neu gerechnet, im Kampf erst danach, ohne Rekursion.
-- Monitore aus qnViewPort\Monitors.lua: 5760 × 2160, Hauptmonitor 3840 × 2160 links.

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { profiles = { ["account:Raid"] = { dual = { enabled = true } } }, global = {} }
LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()

-- Aufrufe von Blizzards Funktion zählen (Hook nach dem von qnViewPort)
local calls = 0
hooksecurefunc("UpdateUIParentPosition", function() calls = calls + 1 end)

local ux = vp.UnitsPerPixel()
local function Near(a, b) return math.abs(a - b) < 1e-6 end
-- UIParent genau mit den zwei eigenen Punkten auf dem Hauptmonitor (rechts 1920 Pixel frei)
local function OnMain(scale)
	local p = UIParent._points
	return p and #p == 2 and p[1][1] == "TOPLEFT" and p[2][1] == "BOTTOMRIGHT"
		and Near(p[2][2], -1920 * ux / (scale or 1)) and Near(p[2][3], 0)
end

-- ohne Knopfdruck: Blizzards Aufruf bleibt unangetastet
UIParent._points = {}
UpdateUIParentPosition()
Check(#UIParent._points == 1 and not vp.Layout.IsUIConstrained(), "ohne Begrenzung: nur Blizzards Punkt")

-- Knopf „Oberfläche auf den Hauptmonitor“
vp.Layout.ConstrainUI()
Check(vp.Layout.IsUIConstrained() and OnMain(), "Knopf: UIParent auf dem Hauptmonitor")

-- Blizzard setzt TOPLEFT neu (Ladebildschirm): Begrenzung wird sofort wieder angewendet
UpdateUIParentPosition()
Check(OnMain() and vp.Layout.IsUIConstrained(), "nach UpdateUIParentPosition: Begrenzung wieder angewendet")
FireEvent("PLAYER_ENTERING_WORLD", false, false) RunTimers()
UpdateUIParentPosition()
Check(OnMain(), "Ladebildschirm: Begrenzung bleibt")
Check(calls == 3, "keine Rekursion: Blizzards Funktion nur dreimal aufgerufen (" .. calls .. ")")

-- neue UI-Skalierung: Versätze in UIParent-Einheiten neu gerechnet
rawset(UIParent, "GetScale", function() return 2 end)
FireEvent("UI_SCALE_CHANGED") RunTimers()
Check(OnMain(2), "UI_SCALE_CHANGED: Versätze mit Skalierung 2 neu gerechnet")
rawset(UIParent, "GetScale", nil)
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
Check(OnMain(1), "DISPLAY_SIZE_CHANGED: wieder mit Skalierung 1")

-- im Kampf: erst nach dem Kampf
QN_COMBAT = true
UIParent._points = {}
UpdateUIParentPosition()
Check(#UIParent._points == 1, "Kampf: nichts verschoben")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(OnMain(), "nach dem Kampf: Begrenzung wieder angewendet")

-- Zurücksetzen: danach wieder nur Blizzard
vp.Layout.ReleaseUI()
UIParent._points = {}
UpdateUIParentPosition()
Check(#UIParent._points == 1 and not vp.Layout.IsUIConstrained(), "nach Zurücksetzen: Blizzards Punkt bleibt")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
