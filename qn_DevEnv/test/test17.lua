-- Szenario 17: qnViewPort – Viewport bei Ereignissen nur begrenzt anwenden (nicht speichern),
-- Speichern bei Eingabe, Bestätigungsfrist, mapFade, Karte beim Einloggen, Zwei-Monitor-Meldungen,
-- Taschen über UpdateContainerFrameAnchors, Kampfsperre.

-- Ergänzungen der Attrappe (vor LoadAddon)
local T = 1000
GetTime = function() return T end
C_CVar.GetCVarDefault = function(k) return ({ mapFade = "1" })[k] end
WorldFrame.IsProtected = function() return true end   -- geschützt wie im Client: Kampfsperre greift
local toggles = 0
ToggleWorldMap = function() toggles = toggles + 1 end
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
WorldMapFrame:Hide()
function WorldMapFrame:SetMapID(id) self.mapID = id end
local winW, winH = 5760, 2160
C_VideoOptions.GetCurrentGameWindowSize = function() return { x = winW, y = winH } end
local CHAT = {}
function DEFAULT_CHAT_FRAME:AddMessage(msg) CHAT[#CHAT + 1] = tostring(msg) end
local checks, boxes, drops = {}, {}, {}
local origCreateFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
	local f = origCreateFrame(kind, name, parent, template)
	if template == "UICheckButtonTemplate" then checks[#checks + 1] = f end
	if template == "InputBoxTemplate" then boxes[#boxes + 1] = f end
	if template == "WowStyle1DropdownTemplate" then drops[#drops + 1] = f end
	return f
end

-- gespeichert: links 3000 Pixel (mehr als die halbe Fensterbreite), ohne Monitordaten
qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { profiles = { ["account:Raid"] = { viewport = { 3000, 0, 0, 0 }, dual = { useMonitorData = false } } }, global = {} }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
local L = vp.L
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)

-- linker Versatz von WorldFrame in Bildschirmpixeln
local function WFLeft()
	local ux = vp.UnitsPerPixel()
	return math.floor(WorldFrame._points[1][2] / ux + 0.5)
end
local function Count(key)
	local n = 0
	for _, m in ipairs(CHAT) do if m:find(L[key], 1, true) then n = n + 1 end end
	return n
end
-- Kontrollkästchen, dessen Haken beim Auffrischen vp.db.dual[key] folgt (auch über getter)
local function CheckBox(key)
	local d = vp.db.dual
	local old, found = d[key], nil
	for _, cb in ipairs(checks) do
		if not found and rawget(cb, "Refresh") then
			d[key] = true cb:Refresh() local on = cb._checked
			d[key] = false cb:Refresh() local off = cb._checked
			if on == true and not off then found = cb end
		end
	end
	d[key] = old
	if found then found:Refresh() end
	return found
end
local function Click(cb, on)
	cb:SetChecked(on)
	cb:GetScript("OnClick")(cb)
	RunTimers()
end

-- 1. Laden: begrenzt anwenden, gespeicherten Wert behalten
Check(vp.db.viewport[1] == 3000, "Laden: gespeicherter Wert bleibt 3000: " .. vp.db.viewport[1])
Check(vp.GetViewport()[1] == 2880 and WFLeft() == 2880, "Laden: angewendet begrenzt auf 2880: " .. WFLeft())

-- 2. Fenstergröße: begrenzt anwenden, nicht speichern
winW, winH = 4000, 2000
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
Check(vp.GetViewport()[1] == 2000 and vp.db.viewport[1] == 3000, "kleineres Fenster: 2000 angewendet, 3000 gespeichert")
winW, winH = 5760, 2160
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
Check(vp.GetViewport()[1] == 2880 and vp.db.viewport[1] == 3000, "Fenster wieder groß: 2880 angewendet, 3000 gespeichert")

-- 3. Blizzard setzt WorldFrame zurück: angewendeter Wert wird wiederhergestellt
WorldFrame._points = {}
WorldFrame:SetAllPoints()
Check(WorldFrame._points[1] and WFLeft() == 2880, "Hook an WorldFrame stellt den begrenzten Viewport wieder her")

-- 4. Profilwechsel: neues Profil = Kopie, begrenzt angewendet, nichts gespeichert
SetEditModeLayout(4)
Check(vp.db ~= qnViewPortDB.profiles["account:Raid"] and vp.db.viewport[1] == 3000 and vp.GetViewport()[1] == 2880,
	"Profilwechsel: Kopie behält 3000, angewendet 2880")
SetEditModeLayout(3)

-- 5. Eingabe des Spielers speichert; ohne Bestätigung wird der gespeicherte Wert von vorher zurückgeschrieben
SlashCmdList.QNVIEWPORT("100 0 0 0")
Check(vp.db.viewport[1] == 100 and WFLeft() == 100, "/qnvp 100 0 0 0 speichert und wendet an")
T = T + 21
RunTickers()
Check(vp.db.viewport[1] == 3000 and vp.GetViewport()[1] == 2880 and Count("Einstellung nicht bestätigt – vorherigen Viewport wiederhergestellt.") == 1,
	"nach 20 s ohne Bestätigung: gespeicherter Wert 3000 unverändert zurück")
SlashCmdList.QNVIEWPORT("0 0 0 0")
Check(vp.db.viewport[1] == 0 and not vp.IsActive(), "/qnvp 0 0 0 0 speichert sofort")

-- 6. mapFade: an merkt den Wert, aus schreibt ihn zurück
local cFade = CheckBox("mapNoFade")
Check(cFade ~= nil, "Kontrollkästchen mapNoFade gefunden")
C_CVar._v.mapFade = "1"
Click(cFade, true)
Check(C_CVar._v.mapFade == "0" and qnViewPortDB.global.mapFadeSaved == "1", "mapNoFade an: mapFade 0, vorher 1 kontoweit gemerkt")
FireEvent("PLAYER_ENTERING_WORLD", false, false) RunTimers()
Check(C_CVar._v.mapFade == "0" and qnViewPortDB.global.mapFadeSaved == "1", "Ladebildschirm: bleibt 0, gemerkter Wert bleibt")
Click(cFade, false)
Check(C_CVar._v.mapFade == "1" and qnViewPortDB.global.mapFadeSaved == nil, "mapNoFade aus: 1 wiederhergestellt")
C_CVar._v.mapFade = "0"   -- vom Spieler in Blizzards Optionen gesetzt
FireEvent("PLAYER_ENTERING_WORLD", false, false) RunTimers()
Check(C_CVar._v.mapFade == "0", "mapNoFade aus: CVar wird sonst nicht angefasst")
Click(cFade, true)
Click(cFade, false)
Check(C_CVar._v.mapFade == "1", "ohne gemerkten Wert: Blizzards Vorgabe beim Ausschalten")

-- 7. Karte nur beim Einloggen bzw. /reload öffnen; Zonenwechsel bei offener Karte
vp.db.dual.mapAutoOpen = true
toggles = 0
FireEvent("PLAYER_ENTERING_WORLD", false, false) RunTimers()
Check(toggles == 0, "Ladebildschirm: Karte nicht geöffnet")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
Check(toggles == 1, "Einloggen: Karte geöffnet")
FireEvent("PLAYER_ENTERING_WORLD", false, true) RunTimers()
Check(toggles == 2, "/reload: Karte geöffnet")
Check(WorldMapFrame:GetScript("OnShow") == nil, "kein eigener OnShow-Hook an der Weltkarte")
WorldMapFrame:Show()
FireEvent("ZONE_CHANGED_NEW_AREA") RunTimers()
Check(WorldMapFrame.mapID == 1, "Zonenwechsel bei offener Karte: Karte der Zone")

-- 8. Zwei-Monitor-Modus: Meldung nur beim tatsächlichen Umschalten
CHAT = {}
SlashCmdList.QNVIEWPORT("dual on") RunTimers()
Check(Count("Zwei-Monitor-Modus aktiv: 3D-Welt auf dem Hauptmonitor.") == 1, "dual on: eine Meldung")
Check(vp.db.dual.enabled and vp.db.viewport[2] == 1920 and vp.db.viewport[1] == 0, "dual on: Viewport auf den Hauptmonitor gespeichert")
SlashCmdList.QNVIEWPORT("dual on") RunTimers()
SlashCmdList.QNVIEWPORT("dual right") RunTimers()
-- „Zwei-Monitor-Modus aktiv“: Haken folgt dual.enabled
local enable = CheckBox("enabled")
Check(enable ~= nil, "Kontrollkästchen Zwei-Monitor-Modus gefunden")
Click(enable, true)
Check(Count("Zwei-Monitor-Modus aktiv: 3D-Welt auf dem Hauptmonitor.") == 1, "erneut ein / Lage / Kontrollkästchen: keine weitere Meldung (" .. #CHAT .. ")")
SlashCmdList.QNVIEWPORT("dual 1600 1200") RunTimers()
Check(vp.db.viewport[2] == 1600 and Count("Zwei-Monitor-Modus aktiv: 3D-Welt auf dem Hauptmonitor.") == 1, "neue Größe: Viewport neu, ohne Meldung")
Click(enable, false)
Check(not vp.db.dual.enabled and vp.db.viewport[2] == 0 and Count("Zwei-Monitor-Modus aus.") == 1, "Kontrollkästchen aus: eine Meldung, Viewport zurück")
SlashCmdList.QNVIEWPORT("200 0 0 0")
vp.EndKeep()
SlashCmdList.QNVIEWPORT("dual off") RunTimers()
Check(Count("Zwei-Monitor-Modus aus.") == 1 and vp.db.viewport[1] == 200, "dual off bei ausgeschaltetem Modus: keine Meldung, Viewport bleibt")

-- 9. Taschen über den Hook an UpdateContainerFrameAnchors
local bag = CreateFrame("Frame", "ContainerFrame1")
bag:Show()
UpdateContainerFrameAnchors() RunTimers()
Check(bag._points == nil, "ohne Option: Taschen bleiben")
vp.db.dual.bags = true
ToggleBackpack() RunTimers()
Check(bag._points == nil, "ToggleBackpack ist nicht mehr gehookt")
UpdateContainerFrameAnchors() RunTimers()
local p = bag._points and bag._points[1]
Check(p and p[1] == "BOTTOMRIGHT" and p[2].qnViewPortIgnore and p[3] == "BOTTOMRIGHT", "Tasche an der Ecke des Bereichs")

-- 10. Kampfsperre
bag._points = nil
bag.IsProtected = function() return true end
QN_COMBAT = true
UpdateContainerFrameAnchors() RunTimers()
Check(bag._points == nil, "Kampf: geschützte Tasche wird nicht bewegt")
SlashCmdList.QNVIEWPORT("0 0 0 0")
Check(vp.db.viewport[1] == 0 and WFLeft() == 200, "Kampf: gespeichert, WorldFrame unverändert")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(WFLeft() == 0, "nach dem Kampf angewendet")

-- 11. Optionsseite „Zweiter Monitor“ auffrischen: Handwerte bzw. gemessene, gesperrte Werte
local function Box(key) for _, b in ipairs(boxes) do if b.key == key then return b end end end
local function Record(w)
	rawset(w, "SetEnabled", function(self, on) self._enabled = on end)
	if rawget(w, "label") then
		rawset(w.label, "SetFontObject", function(self, font) self._font = font end)
	end
end
for _, b in ipairs(boxes) do Record(b) end
local side
for _, dd in ipairs(drops) do
	Record(dd)
	for _, r in ipairs(dd._radios or {}) do
		if r.text == L["Links vom Hauptmonitor"] then side = dd end
	end
end
local wBox, hBox, yBox = Box("width"), Box("height"), Box("offsetY")
Check(wBox and hBox and yBox and side, "Felder und Lage-Auswahl gefunden")
vp.db.dual.width, vp.db.dual.height, vp.db.dual.offsetY, vp.db.dual.side = 1600, 1000, 50, "RIGHT"
vp.db.dual.mapFollowZone = true
vp.Dual.RefreshOptions()
Check(wBox._text == 1600 and hBox._text == 1000 and yBox._text == 50, ("ohne Monitordaten: Handwerte %s/%s/%s"):format(
	tostring(wBox._text), tostring(hBox._text), tostring(yBox._text)))
Check(wBox._enabled == true and wBox.label._font == "GameFontHighlight", "ohne Monitordaten: Feld bedienbar")
Check(side._enabled == true and side.label._font == "GameFontHighlight" and side._text == L["Rechts vom Hauptmonitor"],
	"ohne Monitordaten: Lage bedienbar: " .. tostring(side._text))
Check(CheckBox("mapFollowZone")._checked == true and not CheckBox("mapNoFade")._checked, ("Kontrollkästchen nach DB: %s/%s"):format(
	tostring(CheckBox("mapFollowZone")._checked), tostring(CheckBox("mapNoFade")._checked)))
local bx = Box("bagsOffsetX")
vp.db.dual.bagsOffsetX = 12
vp.Dual.RefreshOptions()
Check(bx and bx._text == 12 and bx._enabled == nil, "Abstand der Taschen: Wert, nicht gesperrt")
vp.db.dual.useMonitorData = true
vp.Dual.RefreshOptions()
Check(wBox._text == 1920 and hBox._text == 1200 and yBox._text == 377, ("Monitordaten: gemessene Werte %s/%s/%s"):format(
	tostring(wBox._text), tostring(hBox._text), tostring(yBox._text)))
Check(wBox._enabled == false and yBox.label._font == "GameFontDisable", "Monitordaten: Felder gesperrt")
Check(side._enabled == false and side.label._font == "GameFontDisable", "Monitordaten: Lage gesperrt")
Check(vp.db.dual.width == 1600, "Monitordaten: Handwert bleibt gespeichert")
vp.db.dual.useMonitorData = false
vp.Dual.RefreshOptions()
Check(wBox._text == 1600 and wBox._enabled == true, "wieder ohne Monitordaten: Handwert")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
