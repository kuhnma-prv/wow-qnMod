-- Szenario 4: qnViewPort mit Titan – durchgehende Titan-Leisten auf einem gewählten Monitor,
-- Tooltips am Monitorrand. Titan selbst wird nachgebildet (nur, was qnViewPort anfasst):
-- TitanBarData, TitanBarDataVars, TitanPanelBarButton_Show/Hide/DisplayBarsWanted wie in
-- Titan.lua (SetBar, _Hide). Ohne Titan: Szenario 5.

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = {
	["account:Raid"] = { titan = { AuxBar = 2 } },
	["preset:1"] = { titan = { AuxBar = 0 } },
} }

---------------------------------------------------------------------------
-- Titan-Nachbau
---------------------------------------------------------------------------
TITAN_PANEL_DISPLAY_PREFIX = "Titan_Bar__Display_"
TITAN_PANEL_BAR_HEIGHT = 24
TITAN_PANEL_MOVING = 0
Titan__InitializedPEW = false
local P = TITAN_PANEL_DISPLAY_PREFIX
local DEF = {
	Bar = { "Oben", "TOPLEFT", "TOPLEFT", "BOTTOMRIGHT", "TOPRIGHT", 0, 72 },
	Bar2 = { "Oben 2", "TOPLEFT", "TOPLEFT", "BOTTOMRIGHT", "TOPRIGHT", -24, 240 },
	AuxBar2 = { "Unten 2", "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", 48, -48 },
	AuxBar = { "Unten", "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", 24, -72 },
}
TitanBarData = {}
TitanBarDataVars = {}   -- Titan füllt es erst beim Betreten der Welt
local vars = {}
for name, d in pairs(DEF) do
	TitanBarData[P .. name] = {
		name = name, locale_name = d[1], hider = "Titan_Bar__Hider_" .. name, hide_y = d[7],
		show = { pt = d[2], rel_fr = "UIParent", rel_pt = d[3] },
		bott = { pt = d[4], rel_fr = "UIParent", rel_pt = d[5] },
	}
	vars[P .. name] = { off_x = 0, off_y = d[6], show = false, auto_hide = false }
	CreateFrame("Button", P .. name, UIParent)
	CreateFrame("Button", "Titan_Bar__Hider_" .. name, UIParent)._w = 1920
end
function TitanPanelBarButton_Show(frame)
	local data, v = TitanBarData[frame], TitanBarDataVars[frame]
	local display = _G[frame]
	display:ClearAllPoints()
	display:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, v.off_x, v.off_y)
	display:SetPoint(data.bott.pt, data.bott.rel_fr, data.bott.rel_pt, v.off_x, v.off_y - TITAN_PANEL_BAR_HEIGHT)
	_G[data.hider]:Hide()
end
function TitanPanelBarButton_Hide(frame)
	if TITAN_PANEL_MOVING == 1 then return end
	local data, v = TitanBarData[frame], TitanBarDataVars[frame]
	local display = _G[frame]
	display:ClearAllPoints()
	display:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, v.off_x, data.hide_y)
	local hider = _G[data.hider]
	if v.show and v.auto_hide then
		hider:ClearAllPoints()
		hider:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, v.off_x, v.off_y)
		hider:Show()
	else
		hider:Hide()
	end
end
local shows = 0
function TitanPanelBarButton_DisplayBarsWanted(reason)
	shows = shows + 1
	for frame, v in pairs(TitanBarDataVars) do
		if v.show and not v.auto_hide then
			TitanPanelBarButton_Show(frame)
		else
			TitanPanelBarButton_Hide(frame)
		end
	end
end

-- Plugins und Tooltips (TitanTemplate.lua): nur die globalen Funktionen, an die qnViewPort sich hängt
TitanPanelTooltip = CreateFrame("GameTooltip", "TitanPanelTooltip", UIParent)
local plugins, controls = {}, {}
function TitanUtils_GetPlugin(id) return plugins[id] end
function TitanUtils_ButtonName(id) return "TitanPanel" .. id .. "Button" end
function TitanUtils_GetControlFrame(id) return controls[id] end
function TitanPanelButton_OnEnter(self) end
function TitanPanelButton_UpdateTooltip(self) end
function TitanPanelPluginHandle_OnUpdate(t, oldarg) end
function TitanPanelButton_OnClick(self, button) end

---------------------------------------------------------------------------
-- Laden; Monitore wie qnViewPort (5760 × 2160, 2. Monitor 1920 × 1200 bei y 377)
---------------------------------------------------------------------------
local isLoaded = C_AddOns.IsAddOnLoaded
C_AddOns.IsAddOnLoaded = function(name) return name == "Titan" or isLoaded(name) end
LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
local tt, L = vp.Titan, vp.L
-- Monitore wie Monitors.lua; 1 Einheit = 1 Pixel (abs = Pixel, Ursprung unten links)
local M1 = { l = 0, r = 3840, t = 2160, b = 0 }
local M2 = { l = 3840, r = 5760, t = 2160 - 377, b = 2160 - 377 - 1200 }
local PX = { { x = 0, y = 0, w = 3840, h = 2160 }, { x = 3840, y = 377, w = 1920, h = 1200 } }
local function SetMonitors(n)
	vp.Layout.GetVisibleAbs = function() return n == 1 and { M1 } or { M1, M2 } end
	vp.Layout.GetVisible = function() return n == 1 and { PX[1] } or PX end
end
SetMonitors(2)
local screen = vp.screenRef

Check(tt.active and tt.category ~= nil, "mit Titan: aktiv, Unterseite „Titan Panel“ angelegt")
for name in pairs(DEF) do
	Check(TitanBarData[P .. name].show.rel_fr == _G["qnViewPortTitanAnchor" .. name]
		and TitanBarData[P .. name].bott.rel_fr == _G["qnViewPortTitanAnchor" .. name], "Bezugsrahmen ersetzt: " .. name)
end
local function Set(bar, v)
	vp.db.titan[bar] = v
	tt.Apply()
end

FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(shows == 0, "vor Titans Start keine Anzeige über Titan")
TitanBarDataVars = vars
Titan__InitializedPEW = true
vars[P .. "Bar"].show = true
vars[P .. "AuxBar"].show = true

local function Anchor(name)
	return _G["qnViewPortTitanAnchor" .. name]._points
end
local function OnMonitor(name, r, dy)
	local p = Anchor(name)
	local a = _G["qnViewPortTitanAnchor" .. name]
	return #p == 1 and p[1][1] == "BOTTOMLEFT" and p[1][2] == screen and p[1][4] == r.l and p[1][5] == r.b + (dy or 0)
		and a._w == r.r - r.l and a._h == r.t - r.b
end
local function Whole(name)
	local p = Anchor(name)
	return #p == 1 and p[1][1] == "ALL" and p[1][2] == UIParent
end

---------------------------------------------------------------------------
-- Profil „account:Raid“: untere Leiste auf Monitor 2
---------------------------------------------------------------------------
tt.Apply()
Check(shows == 1, "Apply lässt Titan die Leisten neu zeigen")
Check(OnMonitor("AuxBar", M2), "Unten auf Monitor 2")
Check(Whole("Bar") and Whole("Bar2"), "ohne Auswahl wie Titan (Anker = UIParent)")
local d = _G[P .. "AuxBar"]._points
Check(d[1][2] == qnViewPortTitanAnchorAuxBar and d[2][2] == qnViewPortTitanAnchorAuxBar and d[1][5] == 24,
	"Titan setzt die Leiste an den Anker (Versatz von Titan)")
Check(_G["Titan_Bar__Hider_AuxBar"]._w == 1920, "Auto-Hide-Leiste auf Monitorbreite")

-- obere Leisten
Set("Bar", 2)
Check(OnMonitor("Bar", M2), "Oben auf Monitor 2")
vars[P .. "Bar2"].show = true
Set("Bar2", 1)
Check(OnMonitor("Bar2", M1, 24), "Oben 2 allein auf Monitor 1: an die Kante gerückt")
Set("Bar2", 2)
Check(OnMonitor("Bar2", M2), "Oben 2 unter Oben auf demselben Monitor: Titans Versatz bleibt")
vars[P .. "Bar"].show = false
tt.Apply()
Check(OnMonitor("Bar2", M2, 24), "Oben ausgeschaltet: Oben 2 an die Kante")
local bar = _G[P .. "Bar"]._points
Check(bar[1][1] == "BOTTOMLEFT" and bar[1][2] == screen and bar[1][3] == "TOPLEFT",
	"verborgene Leiste über dem Spielfenster geparkt")
vars[P .. "Bar"].show = true

-- untere Leiste 2
vars[P .. "AuxBar2"].show = true
Set("AuxBar2", 1)
Check(OnMonitor("AuxBar2", M1, -24), "Unten 2 allein auf Monitor 1: nach unten gerückt")
Set("AuxBar2", 0)
Check(Whole("AuxBar2"), "Unten 2 zurück auf wie Titan")

-- Auto-Hide
vars[P .. "AuxBar"].auto_hide = true
tt.Apply()
local h = _G["Titan_Bar__Hider_AuxBar"]
Check(h._points[1][2] == qnViewPortTitanAnchorAuxBar and h._w == 1920, "Auto-Hide-Leiste am Monitor und auf seiner Breite")
Check(_G[P .. "AuxBar"]._points[1][2] == screen, "automatisch verborgene Leiste geparkt")

-- Titan verschiebt gerade: nichts anfassen
TITAN_PANEL_MOVING = 1
_G[P .. "AuxBar"]:ClearAllPoints()
TitanPanelBarButton_Hide(P .. "AuxBar")
Check(#_G[P .. "AuxBar"]._points == 0, "TITAN_PANEL_MOVING: kein Parken")
TITAN_PANEL_MOVING = 0
vars[P .. "AuxBar"].auto_hide = false

---------------------------------------------------------------------------
-- Dropdown: Einträge, fehlender Monitor
---------------------------------------------------------------------------
-- Einträge wie beim Aufklappen des Dropdowns
local function Labels(key)
	local list = {}
	for _, e in ipairs(tt.Entries(key)) do
		list[#list + 1] = e[2]
	end
	return list
end
local labels = Labels("Bar")
Check(#labels == 3 and labels[1] == L["Wie Titan (ganze Oberfläche)"]
	and labels[2] == L["Monitor %d (%d × %d)"]:format(1, 3840, 2160)
	and labels[3] == L["Monitor %d (%d × %d)"]:format(2, 1920, 1200), "Dropdown: wie Titan + Monitore mit Pixelgröße")
SetMonitors(1)
tt.Apply()
Check(Whole("Bar") and Whole("AuxBar"), "Monitor 2 fehlt: Leisten wie Titan")
labels = Labels("Bar")
Check(#labels == 3 and labels[3] == L["Monitor %d (nicht vorhanden)"]:format(2), "gespeicherter Monitor bleibt im Dropdown sichtbar")
Check(qnViewPortDB.profiles["account:Raid"].titan.Bar == 2, "Auswahl bleibt gespeichert")
SetMonitors(2)

---------------------------------------------------------------------------
-- Profilwechsel (Layout des Bearbeitungsmodus)
---------------------------------------------------------------------------
SetEditModeLayout(1)
Check(Whole("AuxBar") and Whole("Bar"), "Profil preset:1: Leisten wie Titan")
SetEditModeLayout(3)
Check(OnMonitor("AuxBar", M2) and OnMonitor("Bar", M2), "zurück auf Raid: wieder Monitor 2")

---------------------------------------------------------------------------
-- Tooltips am Rand des Monitors
---------------------------------------------------------------------------
local btn = CreateFrame("Button", "TitanPanelClockButton", UIParent)
btn.registry = { id = "Clock" }
local function Place(f, l, b, w, h)
	f.GetLeft = function() return l end
	f.GetBottom = function() return b end
	f._w, f._h = w, h
end
-- Titans Anker nachbilden: GetPoint liefert den zuletzt gesetzten Punkt
local function Anchored(f, point)
	f:ClearAllPoints()
	f:SetPoint(point, btn, "BOTTOMLEFT", 0, 0)
	f.GetPoint = function(self) local p = self._points[1] return p[1], p[2], p[3], p[4], p[5] end
	f:Show()
end
local function Last(f)
	local p = f._points[#f._points]
	return p[1], p[2], p[3], p[4], p[5]
end

-- oben rechts auf Monitor 1: Titan hängt ihn nach rechts, dort ist kein Monitor mehr
Place(btn, 3800, 2136, 30, 24)
Place(TitanPanelTooltip, 0, 0, 200, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
TitanPanelButton_OnEnter(btn)
local p, rel, rp, x, y = Last(TitanPanelTooltip)
Check(p == "TOPRIGHT" and rel == btn and rp == "BOTTOMRIGHT" and x == 0 and y == 0,
	("Tooltip am rechten Rand des Monitors nach links geklappt: %s %s %s %s"):format(p, rp, x, y))
-- passt er, bleibt Titans Seite
Place(btn, 1000, 2136, 30, 24)
Anchored(TitanPanelTooltip, "TOPLEFT")
TitanPanelButton_UpdateTooltip(btn)
p, rel, rp = Last(TitanPanelTooltip)
Check(p == "TOPLEFT" and rp == "BOTTOMLEFT", "Tooltip mit Platz: Titans Seite bleibt")
-- breiter als der Platz auf beiden Seiten: hineingeschoben
Place(btn, 1000, 2136, 30, 24)
Place(TitanPanelTooltip, 0, 0, 3000, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
TitanPanelPluginHandle_OnUpdate({ "Clock", 2 })
p, rel, rp, x = Last(TitanPanelTooltip)
Check(p == "TOPLEFT" and x == 3840 - 4000, ("zu breiter Tooltip in den Monitor geschoben: %s %s"):format(p, x))
-- breiter als der Monitor: linke Kante bleibt sichtbar
Place(btn, 50, 2136, 30, 24)
Place(TitanPanelTooltip, 0, 0, 3900, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
TitanPanelButton_UpdateTooltip(btn)
p, rel, rp, x = Last(TitanPanelTooltip)
Check(p == "TOPLEFT" and x == -50, ("breiter als der Monitor: an dessen linken Rand: %s %s"):format(p, x))
-- untere Leiste auf Monitor 2: darunter ist kein Monitor, also darüber
Place(btn, 4000, M2.b, 30, 24)
Place(TitanPanelTooltip, 0, 0, 200, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
TitanPanelButton_OnEnter(btn)
p, rel, rp = Last(TitanPanelTooltip)
Check(p == "BOTTOMLEFT" and rp == "TOPLEFT", "Tooltip an der Unterkante von Monitor 2 nach oben geklappt")
-- fremder Anker (nicht am Plugin): nicht anfassen
GameTooltip:ClearAllPoints()
GameTooltip:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, 5)
GameTooltip.GetPoint = function(self) local q = self._points[1] return q[1], q[2], q[3], q[4], q[5] end
TitanPanelButton_OnEnter(btn)
Check(#GameTooltip._points == 1 and GameTooltip._points[1][2] == UIParent, "GameTooltip eines anderen Rahmens bleibt unberührt")
-- Steuerfenster
local ctrl = CreateFrame("Frame", "TitanPanelClockControlFrame", UIParent)
controls.Clock = ctrl
Place(btn, 3800, 2136, 30, 24)
Place(ctrl, 0, 0, 150, 150)
Anchored(ctrl, "TOPLEFT")
TitanPanelButton_OnClick(btn, "LeftButton")
p = Last(ctrl)
Check(p == "TOPRIGHT", "Steuerfenster am rechten Monitorrand nach links")
RunTimers()
-- Steuerfenster mit Platz: Titans Anker (Mitte der Plugin-Unterkante) bleibt, kein Sprung
Place(btn, 1000, 2136, 30, 24)
ctrl:ClearAllPoints()
ctrl:SetPoint("TOPLEFT", btn, "BOTTOM", 0, 0)
TitanPanelButton_OnClick(btn, "LeftButton")
p, rel, rp = Last(ctrl)
Check(#ctrl._points == 1 and p == "TOPLEFT" and rp == "BOTTOM", ("Steuerfenster mit Platz: Titans Anker bleibt: %s %s"):format(p, tostring(rp)))

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
