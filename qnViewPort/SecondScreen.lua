-- qnViewPort: Zwei-Monitor-Modus.
-- Voraussetzung: Das Spielfenster ist über mehrere Monitore gezogen (z. B. 5760 × 2160
-- bei 3840 × 2160 + 1920 × 1200). Dieses Modul
--   * berechnet daraus den Viewport, so dass die 3D-Welt nur auf dem Hauptmonitor liegt,
--   * legt auf Wunsch Taschen und Zonenkarte an eine Ecke eines wählbaren Monitors
--     und zeigt/verbirgt die Zonenkarte,
--   * legt auf Wunsch die maximierte Weltkarte auf einen Monitor und bietet ein paar
--     Einstellungen für die Weltkarte.
-- Der Chat wird nicht verschoben. Alle Angaben in Bildschirmpixeln des Spielfensters.

local _, ns = ...
local L = ns.L
local UI = qnCore.UI

local Dual = {}
ns.Dual = Dual

local DB = ns.DualDB

---------------------------------------------------------------------------
-- Geometrie
---------------------------------------------------------------------------

-- Viewport-Versätze { links, rechts, oben, unten }: 3D-Welt nur auf dem Hauptmonitor
function Dual.GetViewport()
	local r = ns.Layout.GetMainRect()
	return r and ns.Layout.ViewportFor(r) or { 0, 0, 0, 0 }
end

-- Umrechnung Pixel -> UIParent-Einheiten (unabhängig davon, ob UIParent verkleinert ist)
local function Scale()
	local ux, uy = ns.UnitsPerPixel()
	local s = UIParent:GetEffectiveScale()
	return ux / s, uy / s
end

-- Passt das Spielfenster zur eingestellten Monitoranordnung?
function Dual.CheckWindow()
	if ns.Layout.Active() then
		return true
	end
	local W = ns.screen[1]
	local d = DB()
	local problem = d.useMonitorData and ns.Layout.GetProblem()
	-- Grobe Prüfung: Der Hauptmonitor ist mindestens halb so breit wie der 2. Monitor.
	if W < d.width * 1.5 then
		return false, L["Das Spielfenster ist nur %d × %d Pixel groß. Es muss über beide Monitore reichen (Hauptmonitor-Breite + %d).%s"]:format(
			ns.screen[1], ns.screen[2], d.width, problem and ("\n" .. problem) or "")
	end
	return true
end

---------------------------------------------------------------------------
-- Platzierungsbereiche: Ecke eines Monitors, nach innen versetzt.
-- Gleicher Aufbau für Taschen („bags“) und Zonenkarte („zoneMap“). Einstellungen je Präfix:
--   <p> (an/aus), <p>Monitor (0 = Hauptmonitor), <p>Point (Ecke), <p>OffsetX, <p>OffsetY (Pixel)
---------------------------------------------------------------------------

-- { Ecke, Text } – zugleich die Einträge des Auswahlknopfs
local CORNERS = qnCore.PointEntries(true)

-- Gewählte Ecke; unbekannter Wert: unten rechts
local function Corner(prefix)
	local p = DB()[prefix .. "Point"]
	for _, c in ipairs(CORNERS) do
		if c[1] == p then
			return p
		end
	end
	return "BOTTOMRIGHT"
end

-- Liegt die Ecke rechts bzw. oben?
local function CornerDirs(p)
	local fx, fy = qnCore.AnchorFactors(p)
	return fx == 1, fy == 1
end

-- Auswählbare Monitore: [0] = Hauptmonitor, dann alle Monitore mit sichtbarem Teil im Fenster
local function Monitors()
	local list = { [0] = ns.Layout.GetMainRect() or ns.Layout.Full() }
	for i, r in ipairs(ns.Layout.GetVisible()) do
		list[i] = r
	end
	return list
end

local function MonitorIndex(prefix)
	local i = DB()[prefix .. "Monitor"] or 0
	return Monitors()[i] and i or 0   -- gewählter Monitor nicht mehr vorhanden: Hauptmonitor
end

local placements = {}

local function NewPlacement(prefix, label, r, g, b)
	local area = CreateFrame("Frame", nil, UIParent)
	area:SetFrameStrata("BACKGROUND")
	area:SetFrameLevel(1)
	area:EnableMouse(false)
	area.qnViewPortIgnore = true
	local guide = CreateFrame("Frame", nil, area, "BackdropTemplate")
	guide:SetAllPoints()
	guide:SetFrameStrata("HIGH")
	guide:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 2 })
	guide:SetBackdropBorderColor(r, g, b, 0.9)
	local fs = guide:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	fs:SetPoint("CENTER")
	fs:SetText("qnViewPort – " .. label)
	fs:SetTextColor(r, g, b)
	guide:Hide()
	local pl = { prefix = prefix, area = area, guide = guide }
	placements[#placements + 1] = pl
	return pl
end

local bagPlace = NewPlacement("bags", HUD_EDIT_MODE_BAGS_LABEL, 0, 0.8, 1)
local mapPlace = NewPlacement("zoneMap", L["Zonenkarte"], 1, 0.8, 0)
-- ganze Monitore (ohne …Point/…Offset: Ecke unten rechts, Abstände 0)
local worldPlace = NewPlacement("worldMap", WORLDMAP_BUTTON, 0.3, 1, 0.3)
local questPlace = NewPlacement("questLog", MAP_AND_QUEST_LOG, 1, 0.5, 1)

-- Legt einen Bereich fest: Monitor, Ecke, Abstände von den Rändern dieser Ecke.
local function UpdatePlacement(pl)
	local d = DB()
	local prefix = pl.prefix
	local r = Monitors()[MonitorIndex(prefix)]
	local right, top = CornerDirs(Corner(prefix))
	local ox = math.max(0, math.min(tonumber(d[prefix .. "OffsetX"]) or 0, r.w - 50))
	local oy = math.max(0, math.min(tonumber(d[prefix .. "OffsetY"]) or 0, r.h - 50))
	local x, y = right and r.x or (r.x + ox), top and (r.y + oy) or r.y
	local w, h = r.w - ox, r.h - oy
	local sx, sy = Scale()
	pl.area:ClearAllPoints()
	-- am ganzen Fenster verankert, nicht an UIParent (der liegt evtl. nur über dem Hauptmonitor)
	pl.area:SetPoint("TOPLEFT", ns.screenRef, "TOPLEFT", x * sx, -y * sy)
	pl.area:SetSize(w * sx, h * sy)
	pl.guide:SetShown(d[prefix] and d.guides)
end

function Dual.UpdateArea()
	for _, pl in ipairs(placements) do
		UpdatePlacement(pl)
	end
end

---------------------------------------------------------------------------
-- Taschen platzieren (nur wenn „Taschen beim Öffnen platzieren“ gewählt ist)
---------------------------------------------------------------------------

local BAG_GAP = 6

local function ShownBags()
	local list = {}
	local combined = _G.ContainerFrameCombinedBags
	if combined and combined:IsShown() then
		list[#list + 1] = combined
	end
	for i = 1, NUM_CONTAINER_FRAMES do
		local f = _G["ContainerFrame" .. i]
		if f and f:IsShown() then
			list[#list + 1] = f
		end
	end
	return list
end

-- Stapelt die offenen Taschen ab der gewählten Ecke senkrecht und dann spaltenweise
-- zur Mitte des Monitors hin.
function Dual.DockBags()
	if not DB().bags then
		return
	end
	local area = bagPlace.area
	local p = Corner("bags")
	local right, top = CornerDirs(p)
	local dirX, dirY = right and -1 or 1, top and -1 or 1
	local maxH = area:GetHeight()
	local x, y, colW = 0, 0, 0
	for _, f in ipairs(ShownBags()) do
		if f:IsProtected() and InCombatLockdown() then
			break
		end
		local k = f:GetEffectiveScale() / area:GetEffectiveScale()
		local fw, fh = f:GetWidth() * k, f:GetHeight() * k
		if y > 0 and y + fh > maxH then
			x, y, colW = x + colW + BAG_GAP, 0, 0
		end
		f:ClearAllPoints()
		f:SetPoint(p, area, p, dirX * x / k, dirY * y / k)
		y = y + fh + BAG_GAP
		colW = math.max(colW, fw)
	end
end

---------------------------------------------------------------------------
-- Tooltips auf Taschenplätzen: immer ganz auf dem Monitor des Platzes.
-- Blizzard hängt den Tooltip mit BOTTOMLEFT an TOPRIGHT bzw. BOTTOMRIGHT an TOPLEFT des Platzes,
-- je nachdem, ob der Platz links oder rechts der Mitte des ganzen Fensters liegt
-- (ContainerFrameItemButton_CalculateItemTooltipAnchors, GetScreenWidth), und füllt ihn danach
-- mit GameTooltip:SetBagItem – bei jeder Auffrischung (UpdateTooltip) wieder beides.
-- Vergleichs-Tooltips: TooltipComparisonManager:AnchorShoppingTooltips, teils aus SetBagItem
-- heraus, teils später über ein Ereignis.
---------------------------------------------------------------------------

local bagTipOwner   -- Taschenplatz, an dem GameTooltip zuletzt per SetBagItem hing

-- withCompare: auch die Vergleichs-Tooltips – nur direkt nach Blizzards Anlegen (AnchorShoppingTooltips).
-- Beim Auffrischen (SetBagItem) nicht: Blizzard legt sie danach ohnehin neu an, teils erst über das
-- Ereignis TOOLTIP_SHOW_ITEM_COMPARISON; ein eigener Eingriff dazwischen ließ sie flackern.
local function FitBagTooltip(tip, owner, withCompare)
	if tip:GetOwner() ~= owner then
		return
	end
	ns.Layout.FitToMonitor(tip, owner)
	if withCompare then
		ns.Layout.FitCompareToMonitor(tip)
	end
end

local function OnSetBagItem(tip)
	local owner = tip:GetOwner()
	bagTipOwner = owner
	if not owner then
		return
	end
	FitBagTooltip(tip, owner)
	-- im nächsten Frame noch einmal: dann hat der Tooltip seine endgültige Größe
	C_Timer.After(0, function()
		FitBagTooltip(tip, owner)
	end)
end

-- Öffentlich für Taschenansichten anderer Addons (qnInventory), die ihre Tooltips nicht über
-- SetBagItem füllen: nach dem Füllen aufrufen; tip muss an owner verankert sein.
function ns.BagTooltip(tip, owner)
	bagTipOwner = owner
	if not owner then
		return
	end
	-- Vergleichs-Tooltips hier gleich mit: Blizzard hat sie beim Füllen schon angelegt
	FitBagTooltip(tip, owner, TooltipComparisonManager.tooltip == tip)
	C_Timer.After(0, function()
		FitBagTooltip(tip, owner)
	end)
end

-- Blizzard kann den Tooltip beim Vergleich seitlich verschieben (SetAnchorType mit slide):
-- dann beides neu an den Monitor.
local function OnAnchorShoppingTooltips(manager)
	local tip = manager.tooltip
	if tip and manager.anchorFrame == tip
		and bagTipOwner and tip:GetOwner() == bagTipOwner then
		FitBagTooltip(tip, bagTipOwner, true)
	end
end

---------------------------------------------------------------------------
-- Zonenkarte (BattlefieldMapFrame aus Blizzard_BattlefieldMap, lädt bei Bedarf)
-- Blizzard hängt die Karte mit TOPLEFT an BattlefieldMapTab BOTTOMLEFT (y -5) und merkt sich
-- nur die Lage des Reiters. Deshalb wird der Reiter gesetzt; die Karte folgt.
---------------------------------------------------------------------------

local ZONEMAP_ADDON = "Blizzard_BattlefieldMap"
local TAB_GAP = 5   -- Abstand Reiter -> Karte in Blizzards XML

local function ZoneMapLoaded()
	return _G.BattlefieldMapFrame ~= nil and _G.BattlefieldMapTab ~= nil
end

local function LoadZoneMap()
	if ZoneMapLoaded() then
		return true
	end
	BattlefieldMap_LoadUI()
	return ZoneMapLoaded()
end

-- Legt Reiter + Karte als Block an die gewählte Ecke (nur mit Option „zoneMap“).
function Dual.PlaceZoneMap()
	local f, tab = _G.BattlefieldMapFrame, _G.BattlefieldMapTab
	if not (DB().zoneMap and f and tab and f:IsShown()) then
		return
	end
	local area = mapPlace.area
	local fs, ts, as = f:GetEffectiveScale(), tab:GetEffectiveScale(), area:GetEffectiveScale()
	-- Block in abs-Einheiten: Reiter oben, darunter die Karte
	local bw = f:GetWidth() * fs
	local th = tab:GetHeight() * ts
	local bh = th + TAB_GAP * fs + f:GetHeight() * fs
	local al, ab, aw, ah = area:GetRect()
	if al and bw > 0 then
		al, ab, aw, ah = al * as, ab * as, aw * as, ah * as
		local right, top = CornerDirs(Corner("zoneMap"))
		local left = right and (al + aw - bw) or al
		local upper = top and (ab + ah) or (ab + bh)
		tab:ClearAllPoints()
		-- Versätze in Einheiten des Reiters, bezogen auf die untere linke Ecke des Bereichs
		tab:SetPoint("BOTTOMLEFT", area, "BOTTOMLEFT", (left - al) / ts, (upper - th - ab) / ts)
	end
end

-- Gewählte Größe, auf 5 % gerundet und begrenzt wie der Regler (50–200 %)
local function ZoneMapScale()
	local s = tonumber(DB().zoneMapScale) or 1
	return math.max(0.5, math.min(2, math.floor(s * 20 + 0.5) / 20))
end

-- Größe von Reiter + Karte (Blizzard selbst bietet keine). Bei 100 % fasst qnViewPort die Größe
-- nicht an, außer um eine eigene Änderung zurückzunehmen.
-- Blizzard verankert den Reiter mit CENTER an UIParent BOTTOMLEFT und merkt sich die Mitte in
-- Einheiten des Reiters (BattlefieldMapOptions.position) – beim Laden passt sie also zur gleichen
-- Größe. keepCenter (Regler, Profilwechsel): Reiter behält seine Mitte auf dem Bildschirm, die
-- gemerkte Lage wird wie nach Blizzards Ziehen nachgeführt. Mit Platzierung legt PlaceZoneMap ihn.
local zoneMapScaled = false
function Dual.ScaleZoneMap(keepCenter)
	local f, tab = _G.BattlefieldMapFrame, _G.BattlefieldMapTab
	local s = ZoneMapScale()
	if not (f and tab) or (s == 1 and not zoneMapScaled) or math.abs(tab:GetScale() - s) < 0.001 then
		return
	end
	zoneMapScaled = s ~= 1
	local cx, cy = tab:GetCenter()
	local es = tab:GetEffectiveScale()
	tab:SetScale(s)
	f:SetScale(s)
	if keepCenter and cx and not DB().zoneMap then
		local ts, us = tab:GetEffectiveScale(), UIParent:GetEffectiveScale()
		tab:ClearAllPoints()
		tab:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
			(cx * es - UIParent:GetLeft() * us) / ts, (cy * es - UIParent:GetBottom() * us) / ts)
		if BattlefieldMapOptions then
			BattlefieldMapOptions.position = BattlefieldMapOptions.position or {}
			BattlefieldMapOptions.position.x, BattlefieldMapOptions.position.y = tab:GetCenter()
		end
	end
end

function Dual.SetZoneMapScale(percent)
	DB().zoneMapScale = math.floor(percent / 5 + 0.5) * 5 / 100
	Dual.ScaleZoneMap(true)
	Dual.PlaceZoneMap()
end

function Dual.IsZoneMapShown()
	return ZoneMapLoaded() and _G.BattlefieldMapFrame:IsShown() or false
end

-- Zeigt/verbirgt die Zonenkarte über Blizzards eigenen Umschalter (setzt auch den CVar
-- showBattlefieldMinimap, mit dem Blizzard sich den Zustand über das Einloggen hinaus merkt).
function Dual.SetZoneMapShown(on)
	if InCombatLockdown() and not ZoneMapLoaded() then
		ns.Print(L["Die Zonenkarte kann im Kampf nicht geladen werden."])
		return
	end
	if not LoadZoneMap() then
		ns.Print(L["Zonenkarte (Blizzard_BattlefieldMap) konnte nicht geladen werden."])
		return
	end
	local f = _G.BattlefieldMapFrame
	if (f:IsShown() and true or false) ~= (on and true or false) then
		f:Toggle()
	end
	if on and not f:IsShown() then
		ns.Print(L["Die Zonenkarte ist hier nicht verfügbar (Blizzard zeigt sie z. B. nicht in jeder Instanz)."])
	end
end

local zoneMapHooked = false
local function HookZoneMap()
	if zoneMapHooked or not ZoneMapLoaded() then
		return
	end
	zoneMapHooked = true
	Dual.ScaleZoneMap()
	-- im nächsten Frame (nach Blizzards eigener Anordnung), Zeigen und Verbergen zusammengefasst
	local Changed = qnCore.Debounce(function()
		Dual.PlaceZoneMap()
		if Dual.IsOptionsShown() then
			Dual.RefreshOptions()
		end
	end)
	_G.BattlefieldMapFrame:HookScript("OnShow", Changed)
	_G.BattlefieldMapFrame:HookScript("OnHide", Changed)
	Changed()
end

---------------------------------------------------------------------------
-- Weltkarte (verschiebt die Karte nicht). Beim Öffnen zeigt Blizzard selbst die Karte
-- der aktuellen Zone (WorldMapMixin:OnShow); hier nur der Zonenwechsel bei offener Karte.
---------------------------------------------------------------------------

local function MapToCurrentZone()
	local f = WorldMapFrame
	if not f:IsShown() then
		return
	end
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID then
		f:SetMapID(mapID)
	end
end

function Dual.OpenMap()
	if not WorldMapFrame:IsShown() and not InCombatLockdown() then
		ToggleWorldMap()
	end
end

-- mapNoFade an: bisherigen Wert von mapFade merken (mapFadeSaved) und 0 setzen.
-- Aus: gemerkten Wert zurückschreiben; wurde nichts gemerkt, beim Ausschalten (toggled)
-- Blizzards Vorgabe, sonst den CVar nicht anfassen.
-- Der gemerkte Wert ist kontoweit (ns.global): der CVar hängt an keinem Profil, beim Wechsel
-- auf ein Profil ohne mapNoFade wird er so zurückgeschrieben.
local function ApplyMapFade(toggled)
	local g = ns.global
	local value = C_CVar.GetCVar("mapFade")
	if DB().mapNoFade then
		if g.mapFadeSaved == nil and value ~= "0" then
			g.mapFadeSaved = value
		end
		C_CVar.SetCVar("mapFade", "0")
	elseif g.mapFadeSaved ~= nil or toggled then
		C_CVar.SetCVar("mapFade", g.mapFadeSaved or C_CVar.GetCVarDefault("mapFade"))
		g.mapFadeSaved = nil
	end
end
Dual.ApplyMapFade = ApplyMapFade

---------------------------------------------------------------------------
-- Weltkarte auf einem Monitor (nur mit ihren Optionen)
-- Maximiert („worldMap“): Blizzard rechnet die Größe aus der Größe von UIParent und setzt die Karte
-- oben mittig an UIParent (WorldMapMixin:UpdateMaximizedSize, maximizePoint "TOP"); die schwarze
-- Fläche (BlackoutFrame) liegt über ganz UIParent. Bei einem Fenster über mehrere Monitore reicht
-- beides über alle. Hier dieselbe Rechnung mit dem Bereich des Monitors statt UIParent.
-- Verkleinert = „Karte & Questlog“ („questLog“; ToggleQuestLog öffnet in Forever diese Ansicht):
-- Blizzards Fensterverwaltung setzt sie als linkes Fenster an UIParent TOPLEFT
-- (FramePositionDelegate:UpdateUIPanelPositions). Hier derselbe Anker am Bereich des Monitors.
---------------------------------------------------------------------------

local SPACER_HEIGHT = 67   -- TITLE_CANVAS_SPACER_FRAME_HEIGHT (lokal in Blizzard_WorldMap.lua)
local SCREEN_BORDER = 30   -- SCREEN_BORDER_PIXELS in UpdateMaximizedSize
local worldMapPlaced       -- "max" bzw. "min", solange die Karte von uns gesetzt ist

local function SetBlackout(f, target)
	if f.BlackoutFrame then
		f.BlackoutFrame:ClearAllPoints()
		f.BlackoutFrame:SetAllPoints(target)
	end
end

-- Blizzards Anker (an UIParent) unverändert an target hängen; unbekannte Anker nicht anfassen
local function Reanchor(f, target)
	local point, rel, relPoint, x, y = f:GetPoint(1)
	rel = rel or UIParent
	if not point or rel == target or (rel ~= UIParent and rel ~= questPlace.area) then
		return
	end
	f:ClearAllPoints()
	f:SetPoint(point, target, relPoint, x, y)
end

-- Größe und Lage wie Blizzards UpdateMaximizedSize, bezogen auf area
local function FitWorldMap(f, area)
	local k = area:GetEffectiveScale() / f:GetEffectiveScale()
	local pw, ph = area:GetWidth() * k - SCREEN_BORDER, area:GetHeight() * k
	local unclamped = (ph - SPACER_HEIGHT) * f.minimizedWidth / (f.minimizedHeight - SPACER_HEIGHT)
	local w = math.min(pw, unclamped)
	local h = (ph - SPACER_HEIGHT) * (w / unclamped) + SPACER_HEIGHT
	f:SetSize(math.floor(w), math.floor(h))
	f:ClearAllPoints()
	f:SetPoint("TOP", area, "TOP")
	SetBlackout(f, area)
	f:OnFrameSizeChanged()
end

function Dual.PlaceWorldMap()
	local f = _G.WorldMapFrame
	if not (f and f.IsMaximized and f.minimizedWidth) then
		return
	end
	if f:IsProtected() and qnCore.DeferInCombat(Dual.PlaceWorldMap) then
		return
	end
	local d = DB()
	local shown = f:IsShown()
	local maximized = shown and f:IsMaximized()
	if maximized and d.worldMap then
		FitWorldMap(f, worldPlace.area)
		worldMapPlaced = "max"
	elseif shown and not maximized and d.questLog then
		Reanchor(f, questPlace.area)
		SetBlackout(f, UIParent)   -- evtl. noch vom maximierten Zustand am Monitor
		worldMapPlaced = "min"
	elseif worldMapPlaced then
		-- Option aus (oder Ansicht gewechselt): zurück an UIParent wie bei Blizzard
		if worldMapPlaced == "max" and maximized then
			FitWorldMap(f, UIParent)
		elseif worldMapPlaced == "min" and shown and not maximized then
			Reanchor(f, UIParent)
		end
		SetBlackout(f, UIParent)
		worldMapPlaced = nil
	end
end

-- Nach Blizzards eigener Anordnung: Maximieren/Verkleinern, Fenstergröße, Öffnen und jede
-- Neuanordnung der Fenster (ShowUIPanel/HideUIPanel/UpdateUIPanelPositions setzen die verkleinerte
-- Karte wieder an UIParent). Sofort und noch einmal im nächsten Frame.
local worldMapHooked = false
local function HookWorldMap()
	local f = _G.WorldMapFrame
	if worldMapHooked or not (f and f.SynchronizeDisplayState and f.UpdateMaximizedSize) then
		return
	end
	worldMapHooked = true
	local later = qnCore.Debounce(Dual.PlaceWorldMap)
	local function Place()
		if worldMapPlaced or DB().worldMap or DB().questLog then
			Dual.PlaceWorldMap()
			later()
		end
	end
	hooksecurefunc(f, "SynchronizeDisplayState", Place)
	hooksecurefunc(f, "UpdateMaximizedSize", Place)
	for _, name in ipairs({ "ShowUIPanel", "HideUIPanel", "UpdateUIPanelPositions" }) do
		hooksecurefunc(name, Place)
	end
	EventRegistry:RegisterCallback("WorldMapOnShow", Place, Dual)
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------

-- Eigene Rahmen, Taschen, Zonenkarte und maximierte Weltkarte (je nur mit ihrer Option); Chat
-- und andere Blizzard-Fenster bleiben, wo sie sind.
function Dual.ApplyAll()
	Dual.UpdateArea()
	Dual.DockBags()
	Dual.ScaleZoneMap(true)
	Dual.PlaceZoneMap()
	Dual.PlaceWorldMap()
end

-- Nach geänderten Einstellungen alles neu anwenden, ohne Chatmeldung. Mit withViewport (und
-- eingeschaltetem Modus) wird auch der Viewport auf den Hauptmonitor gelegt und gespeichert.
function Dual.Reapply(withViewport)
	ns.UpdateScreenSize()
	if withViewport and DB().enabled then
		-- ohne 20-s-Bestätigung: Rückweg ist /qnvp dual off
		ns.EndKeep()
		ns.ApplyViewport(Dual.GetViewport())
	end
	qnCore.Visible.Notify()
	Dual.ApplyAll()
	Dual.RefreshOptions()
end

-- Schaltet den Modus ein/aus und setzt den passenden Viewport (die 3D-Welt, keine Oberfläche).
-- Meldung nur, wenn sich der Zustand tatsächlich ändert.
function Dual.SetEnabled(on)
	on = on and true or false
	local d = DB()
	if d.enabled ~= on then
		d.enabled = on
		ns.UpdateScreenSize()
		if on then
			local ok, msg = Dual.CheckWindow()
			if not ok then
				ns.Print("|cffff8080" .. msg .. "|r")
			end
			ns.Print(L["Zwei-Monitor-Modus aktiv: 3D-Welt auf dem Hauptmonitor."])
		else
			ns.EndKeep()
			ns.ApplyViewport({ 0, 0, 0, 0 })
			ns.Layout.ReleaseUI()
			ns.Print(L["Zwei-Monitor-Modus aus."])
		end
	end
	Dual.Reapply(true)
end

---------------------------------------------------------------------------
-- Slash: /qnvp dual ...
---------------------------------------------------------------------------

function Dual.Slash(msg)
	msg = (msg or ""):lower()
	local w, h, y = msg:match("^(%d+)%s+(%d+)%s*(%d*)$")
	if msg == "" then
		Dual.OpenOptions()
	elseif msg == "on" then
		Dual.SetEnabled(true)
	elseif msg == "off" then
		Dual.SetEnabled(false)
	elseif msg == "left" or msg == "right" then
		DB().side = msg:upper()
		Dual.Reapply(true)
	elseif msg == "guides" then
		DB().guides = not DB().guides
		Dual.UpdateArea()
	elseif msg == "map" then
		Dual.OpenMap()
	elseif msg == "zonemap" then
		Dual.SetZoneMapShown(not Dual.IsZoneMapShown())
	elseif w then
		DB().width, DB().height = tonumber(w), tonumber(h)
		if y ~= "" then DB().offsetY = tonumber(y) end
		Dual.Reapply(true)
		ns.Print((ns.Layout.Active() and L["2. Monitor: %d × %d, Versatz oben %d (gilt nur ohne Monitordaten)"]
			or L["2. Monitor: %d × %d, Versatz oben %d"]):format(DB().width, DB().height, DB().offsetY))
	else
		-- ein Schlüssel; Print gibt jede Zeile als eigene Chatzeile aus
		ns.Print(L["/qnvp dual – Optionen   |   on / off   |   left / right\n/qnvp dual B H [Y] – Größe des 2. Monitors in Pixeln, Y = Abstand von oben (nur ohne Monitordaten)\n/qnvp dual guides – Platzierungsbereiche anzeigen   |   map – Weltkarte öffnen   |   zonemap – Zonenkarte ein/aus"])
	end
end

---------------------------------------------------------------------------
-- Bausteine der Optionsseiten
---------------------------------------------------------------------------

local sub
local page           -- Seite, auf der Check/NumBox/Choice gerade bauen (NewPage)
local pages = {}
local widgets = {}

-- Eingaben in den Feldern übernehmen, bevor ein Knopf wirkt
local function ClearFocusAll()
	for _, wdg in ipairs(widgets) do
		if wdg.ClearFocus then wdg:ClearFocus() end
	end
end

-- Kontrollkästchen auf DB()[key]; mit getter/setter statt eines Schlüssels (z. B. Blizzard-Zustand).
local function Check(label, key, tooltip, onChange, getter, setter)
	local cb = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
	local fs = UI.Text(page, "GameFontHighlight", label)
	fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	cb:SetScript("OnClick", function(self)
		local on = self:GetChecked() and true or false
		if setter then
			setter(on)
		else
			DB()[key] = on
		end
		if onChange then onChange() end
	end)
	if tooltip then
		UI.Tooltip(cb, label, tooltip)
	end
	-- Auffrischen (Dual.RefreshOptions): Haken nach getter bzw. DB()[key]
	function cb:Refresh()
		if getter then
			self:SetChecked(getter())
		else
			self:SetChecked(DB()[key])
		end
	end
	widgets[#widgets + 1] = cb
	return cb
end

-- Handwerte des 2. Monitors; mit Monitordaten stattdessen die gemessenen Werte (nur Anzeige).
local MANUAL = { width = "w", height = "h", offsetY = "y" }

-- Auffrischen eines Zahlenfelds: DB()[key], außer während der Eingabe
local function RefreshBox(box)
	if not box:HasFocus() then
		box:SetText(DB()[box.key])
	end
end

-- Auffrischen eines Felds des 2. Monitors: mit Monitordaten (ctx.data) gemessener Wert, gesperrt
local function RefreshManualBox(box, ctx)
	local data, second = ctx.data, ctx.second
	if data and second then
		box:SetText(second[MANUAL[box.key]])
	elseif not box:HasFocus() then
		box:SetText(DB()[box.key])
	end
	if box.SetEnabled then
		box:SetEnabled(not data)
	end
	box.label:SetFontObject(data and "GameFontDisable" or "GameFontHighlight")
end

-- Zahlenfeld mit Beschriftung links auf DB()[key]
local function NumBox(label, key, onCommit)
	local box = ns.NumBox(page, 60, function() return DB()[key] end, function(v)
		if v and v ~= DB()[key] then
			DB()[key] = v
			if onCommit then onCommit() end
		end
	end)
	box.label = UI.Label(page, box, label)
	box.key = key
	box.Refresh = MANUAL[key] and RefreshManualBox or RefreshBox
	widgets[#widgets + 1] = box
	return box
end

-- Knopf mit Aufklappliste (qnCore), zeigt die aktive Auswahl.
-- entries() liefert { { Wert, Text }, … }, get() den aktuellen Wert, set(v) übernimmt ihn.
-- enabled() (optional): nur dann bedienbar.
local function Choice(label, width, entries, get, set, onChange, enabled)
	local dd = UI.Dropdown(page, width, entries, get, function(v)
		set(v)
		if onChange then onChange() end
		Dual.RefreshOptions()
	end)
	dd.label = UI.Label(page, dd, label)
	-- Auffrischen: aktive Auswahl zeigen (qnCore), mit enabled() auch sperren bzw. freigeben
	local showSelection = dd.Refresh
	function dd:Refresh()
		showSelection(self)
		if enabled then
			local on = enabled() and true or false
			self:SetEnabled(on)
			self.label:SetFontObject(on and "GameFontHighlight" or "GameFontDisable")
		end
	end
	widgets[#widgets + 1] = dd
	return dd
end

-- Übernehmen-Knopf einer Unterseite unter anchor
local function ApplyButton(anchor, withViewport)
	local b = UI.Button(page, APPLY, 160, function()
		ClearFocusAll()
		Dual.Reapply(withViewport)
	end)
	b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 4, -14)
	return b
end

-- Unterseite anlegen (qnCore.UI.Page: Überschrift, Trennlinie, Inhalt mit Scrollbar):
-- build(top) baut auf „page“ (= Inhalt) unter top (Beschreibung), danach Anmeldung im
-- Einstellungsfenster. Liefert Kategorie und Seite (für Fit nach dem Ein-/Ausblenden).
local function NewPage(name, desc, build)
	local ui = UI.Page(name, { desc = desc })
	ui.panel:SetScript("OnShow", Dual.RefreshOptions)
	pages[#pages + 1] = ui.panel
	page = ui.content
	build(ui.top, ui)
	return Settings.RegisterCanvasLayoutSubcategory(ns.category, ui.panel, name), ui
end

local info, monInfo

function Dual.IsOptionsShown()
	for _, p in ipairs(pages) do
		if p:IsVisible() then
			return true
		end
	end
	return false
end

-- Info-Text der Seite „Zweiter Monitor“: Spielfenster, 2. Monitor, Welt, Monitordaten, Fensterprüfung
local function RefreshInfoText(ctx)
	local data, main, second = ctx.data, ctx.main, ctx.second
	local ok, msg = Dual.CheckWindow()
	info:SetText(L["|cffccccccSpielfenster:|r %d × %d     |cffcccccc2. Monitor im Fenster:|r %s     |cffccccccWelt:|r %s%s%s"]:format(
		ns.screen[1], ns.screen[2],
		second and ("x %d, y %d, %d × %d"):format(second.x, second.y, second.w, second.h) or L["keiner"],
		main and ("%d × %d"):format(main.w, main.h) or L["ganzes Fenster"],
		data and ("\n" .. L["|cff80ff80Monitordaten aktiv|r – Lage und Größe oben sind gemessen und nicht änderbar (Seite „Monitore“)."]) or "",
		ok and "" or ("\n|cffff8080" .. msg .. "|r")))
end

-- Monitorliste der Seite „Monitore“ samt Lage der Blizzard-Oberfläche
local function RefreshMonitorText()
	local lines = ns.Layout.Describe()
	lines[#lines + 1] = ""
	lines[#lines + 1] = ns.Layout.IsUIConstrained() and L["Blizzard-Oberfläche: auf dem Hauptmonitor"]
		or L["Blizzard-Oberfläche: über das ganze Fenster"]
	monInfo:SetText(table.concat(lines, "\n"))
end

-- Alle Steuerelemente und Texte der Optionsseiten neu anzeigen.
-- ctx: data (Monitordaten, sonst nil), main und second (Rechtecke von Haupt- und 2. Monitor).
function Dual.RefreshOptions()
	ns.UpdateScreenSize()
	local data = ns.Layout.Active()
	local main, second = ns.Layout.GetMainRect(), ns.Layout.GetSecondRect()
	local ctx = { data = data, main = main, second = second }
	for _, wdg in ipairs(widgets) do
		wdg:Refresh(ctx)
	end
	RefreshInfoText(ctx)
	RefreshMonitorText()
end

---------------------------------------------------------------------------
-- Optionsseite (Unterkategorie „Zweiter Monitor“)
---------------------------------------------------------------------------

local function BuildPage(desc)
	local enable = Check(L["Zwei-Monitor-Modus aktiv (3D-Welt nur auf dem Hauptmonitor)"], nil, nil, nil,
		function() return DB().enabled end, Dual.SetEnabled)
	enable:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -4, -14)

	-- Lage des 2. Monitors: Handwerte ohne Monitordaten, sonst gemessene Werte (gesperrt)
	local side = Choice(L["Lage des 2. Monitors"], 220, {
		{ "RIGHT", L["Rechts vom Hauptmonitor"] },
		{ "LEFT", L["Links vom Hauptmonitor"] },
	}, function()
		local main, second = ns.Layout.GetMainRect(), ns.Layout.GetSecondRect()
		if ns.Layout.Active() and main and second then
			return second.x < main.x and "LEFT" or "RIGHT"
		end
		return DB().side == "LEFT" and "LEFT" or "RIGHT"
	end, function(v)
		if not ns.Layout.Active() then
			DB().side = v
		end
	end, nil, function() return not ns.Layout.Active() end)
	side:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 164, -14)
	UI.Tooltip(side, L["Lage des 2. Monitors"], L["Nur ohne Monitordaten einstellbar. Mit Monitordaten werden Lage, Größe und Abstand gemessen (qnViewPort\\scripts)."])

	local wBox = NumBox(HUD_EDIT_MODE_SETTING_CHAT_FRAME_WIDTH, "width")
	wBox:SetPoint("TOPLEFT", side, "BOTTOMLEFT", -90, -18)
	local hBox = NumBox(HUD_EDIT_MODE_SETTING_CHAT_FRAME_HEIGHT, "height")
	hBox:SetPoint("LEFT", wBox, "RIGHT", 70, 0)
	local yBox = NumBox(L["Abstand von oben"], "offsetY")
	yBox:SetPoint("LEFT", hBox, "RIGHT", 150, 0)

	-- linksbündig mit dem Kontrollkästchen oben (wBox steht 70 weiter rechts)
	local apply = ApplyButton(wBox, true)
	apply:ClearAllPoints()
	apply:SetPoint("TOPLEFT", wBox, "BOTTOMLEFT", -70, -22)

	info = UI.Text(page, "GameFontHighlight")
	info:SetPoint("TOPLEFT", apply, "BOTTOMLEFT", 0, -16)
	info:SetWidth(620)
end

---------------------------------------------------------------------------
-- Optionsseite (Unterkategorie „Platzierung“): Taschen und Zonenkarte
---------------------------------------------------------------------------

-- Monitore zur Auswahl: 0 = Hauptmonitor, dann die Nummern wie auf der Seite „Monitore“
local function MonitorEntries()
	local list, main = {}, ns.Layout.GetMainRect()
	local monitors = Monitors()
	for i = 0, #monitors do
		local r = monitors[i]
		if i == 0 then
			list[#list + 1] = { 0, L["Hauptmonitor (%d × %d)"]:format(r.w, r.h) }
		elseif r == main then
			list[#list + 1] = { i, L["Monitor %d (%d × %d), Haupt"]:format(i, r.w, r.h) }
		else
			list[#list + 1] = { i, L["Monitor %d (%d × %d)"]:format(i, r.w, r.h) }
		end
	end
	return list
end

-- Abschnitt „Monitor, Ecke, Abstände“ für eine Platzierung; liefert den Monitor-Knopf und das Feld
-- „Abstand waagerecht“ (zum Verankern).
-- monitorTitle/cornerTitle: Tooltip-Überschriften der beiden Auswahlknöpfe.
local function PlacementControls(prefix, anchor, monitorTitle, cornerTitle)
	local monitor = Choice(PRIMARY_MONITOR, 240, MonitorEntries,
		function() return MonitorIndex(prefix) end,
		function(i) DB()[prefix .. "Monitor"] = i end, Dual.ApplyAll)
	monitor:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 94, -8)
	UI.Tooltip(monitor, monitorTitle, L["Nummern wie auf der Seite „Monitore“."])

	local corner = Choice(L["Ecke"], 150, CORNERS,
		function() return Corner(prefix) end,
		function(p) DB()[prefix .. "Point"] = p end, Dual.ApplyAll)
	corner:SetPoint("LEFT", monitor, "RIGHT", 60, 0)
	UI.Tooltip(corner, cornerTitle)

	local offsetX = NumBox(L["Abstand waagerecht"], prefix .. "OffsetX", Dual.ApplyAll)
	offsetX:SetPoint("TOPLEFT", monitor, "BOTTOMLEFT", 80, -14)
	local offsetY = NumBox(L["senkrecht"], prefix .. "OffsetY", Dual.ApplyAll)
	offsetY:SetPoint("LEFT", offsetX, "RIGHT", 90, 0)
	return monitor, offsetX
end

-- Regler für die Größe der Zonenkarte (50–200 % in 5-%-Schritten, wie die Titan-Skalierung)
local function ZoneMapScaleSlider()
	local s = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
	s:SetSize(220, 20)
	s.label = UI.Label(page, s, HUD_EDIT_MODE_SETTING_MINIMAP_SIZE)
	s:Init(ZoneMapScale() * 100, 50, 200, 30, {
		[MinimalSliderWithSteppersMixin.Label.Right] = function(v)
			return ("%d %%"):format(v + 0.5)
		end,
	})
	s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		if not s.quiet then
			Dual.SetZoneMapScale(value)
		end
	end, s)
	function s:Refresh()
		self.quiet = true
		self:SetValue(ZoneMapScale() * 100)
		self.quiet = false
	end
	widgets[#widgets + 1] = s
	return s
end

local function BuildPlacementPage(desc)
	-- Taschen
	local bagHead = UI.Text(page, "GameFontNormal", HUD_EDIT_MODE_BAGS_LABEL)
	bagHead:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
	local cBags = Check(L["Taschen beim Öffnen platzieren"], "bags",
		L["Legt offene Taschen bei jedem Öffnen an die gewählte Ecke. Sie stapeln sich von dort senkrecht, weitere Spalten zur Monitormitte hin."],
		Dual.ApplyAll)
	cBags:SetPoint("TOPLEFT", bagHead, "BOTTOMLEFT", -4, -4)
	local bagMonitor = PlacementControls("bags", cBags, L["Monitor für die Taschen"], L["Ecke für die Taschen"])

	-- Zonenkarte
	local mapHead = UI.Text(page, "GameFontNormal", L["Zonenkarte (Umschalt+M)"])
	mapHead:SetPoint("TOPLEFT", bagMonitor, "BOTTOMLEFT", -90, -52)
	local cShow = Check(L["Zonenkarte anzeigen"], nil,
		L["Zeigt oder verbirgt Blizzards Zonenkarte. Blizzard merkt sich den Zustand selbst (CVar showBattlefieldMinimap)."],
		nil, Dual.IsZoneMapShown, Dual.SetZoneMapShown)
	cShow:SetPoint("TOPLEFT", mapHead, "BOTTOMLEFT", -4, -4)
	local cPlace = Check(L["Zonenkarte beim Anzeigen platzieren"], "zoneMap",
		L["Legt die Zonenkarte samt Reiter bei jedem Einblenden an die gewählte Ecke. Ziehen am Reiter wirkt dann nur bis zum nächsten Einblenden."],
		Dual.ApplyAll)
	cPlace:SetPoint("TOPLEFT", cShow, "BOTTOMLEFT", 0, -2)
	local mapMonitor, mapOffsetX = PlacementControls("zoneMap", cPlace, L["Monitor für die Zonenkarte"], L["Ecke für die Zonenkarte"])
	-- Größe gilt auch ohne Platzierung; linksbündig mit dem Monitor-Knopf
	local mapScale = ZoneMapScaleSlider()
	mapScale:SetPoint("TOPLEFT", mapOffsetX, "BOTTOMLEFT", -80, -14)

	-- Weltkarte: maximiert und verkleinert („Karte & Questlog“) je auf einen ganzen Monitor
	local worldHead = UI.Text(page, "GameFontNormal", WORLDMAP_BUTTON)
	worldHead:SetPoint("TOPLEFT", mapScale, "BOTTOMLEFT", -90, -20)
	local cWorld = Check(L["Maximierte Weltkarte auf"], "worldMap",
		L["Blizzard legt die maximierte Weltkarte über das ganze Spielfenster, bei mehreren Monitoren also über alle. An: Karte und schwarze Fläche nur auf dem gewählten Monitor."],
		Dual.ApplyAll)
	cWorld:SetPoint("TOPLEFT", worldHead, "BOTTOMLEFT", -4, -4)
	local worldMonitor = Choice("", 240, MonitorEntries,
		function() return MonitorIndex("worldMap") end,
		function(i) DB().worldMapMonitor = i end, Dual.ApplyAll)
	worldMonitor:SetPoint("LEFT", cWorld, "LEFT", 260, 0)
	UI.Tooltip(worldMonitor, L["Monitor für die maximierte Weltkarte"], L["Nummern wie auf der Seite „Monitore“."])
	local cQuest = Check(L["„Karte & Questlog“ auf"], "questLog",
		L["Die verkleinerte Weltkarte mit dem Questlog – das Questlog öffnet diese Ansicht. Blizzard legt sie an den linken Rand des Spielfensters. An: an den linken Rand des gewählten Monitors."],
		Dual.ApplyAll)
	cQuest:SetPoint("TOPLEFT", cWorld, "BOTTOMLEFT", 0, -6)
	local questMonitor = Choice("", 240, MonitorEntries,
		function() return MonitorIndex("questLog") end,
		function(i) DB().questLogMonitor = i end, Dual.ApplyAll)
	questMonitor:SetPoint("LEFT", cQuest, "LEFT", 260, 0)
	UI.Tooltip(questMonitor, L["Monitor für „Karte & Questlog“"], L["Nummern wie auf der Seite „Monitore“."])

	local cFollow = Check(L["Karte folgt der aktuellen Zone"], "mapFollowZone",
		L["Wechselt bei offener Karte beim Betreten einer neuen Zone auf deren Karte. Beim Öffnen zeigt Blizzard ohnehin die aktuelle Zone."])
	cFollow:SetPoint("TOPLEFT", cQuest, "BOTTOMLEFT", 0, -6)
	local cOpen = Check(L["Karte beim Einloggen öffnen"], "mapAutoOpen",
		L["Nur beim Einloggen und nach /reload, nicht nach Ladebildschirmen."])
	cOpen:SetPoint("LEFT", cFollow, "LEFT", 300, 0)
	local cFade = Check(L["Karte beim Laufen nicht ausblenden"], "mapNoFade",
		L["Setzt die Blizzard-Einstellung mapFade auf 0. Beim Ausschalten wird der vorherige Wert wiederhergestellt. Blizzard blendet die Karte ohnehin nur aus, solange die Maus nicht über ihr ist – bei der maximierten Karte also kaum."],
		function() ApplyMapFade(true) end)
	cFade:SetPoint("TOPLEFT", cFollow, "BOTTOMLEFT", 0, -2)

	local cGuides = Check(L["Bereiche anzeigen"], "guides",
		L["Rahmt die Bereiche ein: blau Taschen, gelb Zonenkarte, grün Weltkarte, violett „Karte & Questlog“ (nur wenn die Platzierung an ist)."], Dual.UpdateArea)
	cGuides:SetPoint("TOPLEFT", cFade, "BOTTOMLEFT", 0, -10)

	local apply = ApplyButton(cGuides, false)
	local openMap = UI.Button(page, L["Karte öffnen"], 160, Dual.OpenMap)
	openMap:SetPoint("LEFT", apply, "RIGHT", 10, 0)
end

---------------------------------------------------------------------------
-- Liste der Elemente außerhalb der Monitore, je Element ein eigener Knopf
---------------------------------------------------------------------------

local ROW_HEIGHT = 26
local listPage, listContent, listHeader, listChecked   -- listPage: UI.Page der Seite „Monitore“
local rows = {}

-- Markiert das Element, über dessen Knopf die Maus steht
local marker = CreateFrame("Frame", nil, UIParent)
marker.qnViewPortIgnore = true
marker:SetFrameStrata("TOOLTIP")
marker:Hide()
do
	local tex = marker:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints()
	tex:SetColorTexture(1, 0, 0, 0.35)
end

local function RowEnter(button)
	local e = button:GetParent().entry
	if not e then
		return
	end
	marker:ClearAllPoints()
	marker:SetAllPoints(e.frame)
	marker:Show()
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:AddLine(e.name)
	GameTooltip:AddLine(L["Verschiebt nur dieses Element auf dem kürzesten Weg auf einen Monitor. Rot markiert: seine jetzige Fläche."], 1, 1, 1, true)
	if e.editMode then
		GameTooltip:AddLine(L["Rahmen des Bearbeitungsmodus: gilt bis /reload bzw. bis das Layout neu geladen wird. Dauerhaft: im Bearbeitungsmodus verschieben."], 1, 0.8, 0.3, true)
	end
	if e.protected then
		GameTooltip:AddLine(L["Geschützter Rahmen: nicht im Kampf. Verschieben aus Addon-Code kann „Aktion blockiert“-Meldungen (Taint) auslösen."], 1, 0.5, 0.5, true)
	end
	GameTooltip:Show()
end

local function RowLeave()
	marker:Hide()
	GameTooltip:Hide()
end

local function Row(i)
	local row = rows[i]
	if row then
		return row
	end
	row = CreateFrame("Frame", nil, listContent)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
	row:SetPoint("RIGHT", listContent, "RIGHT")
	if i % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, 0.04)
	end
	row.name = UI.Text(row, "GameFontHighlight")
	row.name:SetPoint("LEFT", 4, 0)
	row.name:SetWidth(210)
	row.name:SetWordWrap(false)
	row.where = UI.Text(row, "GameFontHighlightSmall")
	row.where:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
	row.where:SetWidth(170)
	row.notes = UI.Text(row, "GameFontDisableSmall")
	row.notes:SetPoint("LEFT", row.where, "RIGHT", 6, 0)
	row.notes:SetWidth(130)
	row.notes:SetWordWrap(false)
	row.button = UI.Button(row, L["In sichtbaren Bereich holen"], 180, function(self)
		local e = self:GetParent().entry
		if e then
			marker:Hide()
			ns.Layout.MoveFrame(e.frame)
			Dual.CheckVisible()
		end
	end)
	row.button:SetHeight(22)
	row.button:SetPoint("RIGHT", -4, 0)
	row.button:SetScript("OnEnter", RowEnter)
	row.button:SetScript("OnLeave", RowLeave)
	rows[i] = row
	return row
end

-- Prüft alle Oberflächenelemente und füllt die Liste. Verschiebt nichts.
function Dual.CheckVisible()
	listChecked = true
	local list = ns.Layout.CheckFrames()
	for i, e in ipairs(list) do
		local row = Row(i)
		row.entry = e
		local where, notes = ns.Layout.DescribeEntry(e)
		row.name:SetText(e.name)
		row.where:SetText(where)
		row.notes:SetText(notes)
		row:Show()
	end
	for i = #list + 1, #rows do
		rows[i].entry = nil
		rows[i]:Hide()
	end
	listContent:SetHeight(math.max(1, #list * ROW_HEIGHT))
	listContent:SetShown(#list > 0)
	if #list == 0 then
		listHeader:SetText("|cff80ff80" .. L["Alle eingeblendeten Oberflächenelemente liegen auf einem Monitor."] .. "|r")
	else
		listHeader:SetText(L["%d Element(e) ganz oder teilweise außerhalb der Monitore"]:format(#list))
	end
	listPage.Fit()
end

-- Liste im Inhalt der Seite (blättert mit der Seite)
local function BuildVisibleList(parent, anchor)
	listHeader = UI.Text(parent, "GameFontNormal", L["Noch nicht geprüft – „Sichtbarkeit prüfen“ drücken."])
	listHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -14)

	listContent = CreateFrame("Frame", nil, parent)
	listContent:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -6)
	listContent:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	listContent:SetHeight(1)
	listContent:Hide()
	local bg = listContent:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.25)
	parent:HookScript("OnHide", RowLeave)
end

---------------------------------------------------------------------------
-- Optionsseite (Unterkategorie „Monitore“)
---------------------------------------------------------------------------

local function BuildMonitorPage(desc, ui)
	listPage = ui
	local cData = Check(L["Monitordaten verwenden"], "useMonitorData",
		L["Aus: Lage und Größe des 2. Monitors kommen von der Seite „Zweiter Monitor“."], function()
			if DB().enabled then
				Dual.Reapply(true)
			else
				ns.Layout.Refresh()
				Dual.RefreshOptions()
			end
		end)
	cData:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -4, -14)

	local apply = ApplyButton(cData, true)

	-- Blizzard-Oberfläche nur auf Knopfdruck verschieben (bis zum Zurücksetzen oder /reload)
	local uiMain = UI.Button(page, L["Oberfläche auf den Hauptmonitor"], 220, function()
		ns.Layout.ConstrainUI()
		Dual.RefreshOptions()
	end, L["Legt UIParent einmalig nur über den Hauptmonitor. Achtung: verschiebt damit ALLE Blizzard-Fenster, die an UIParent hängen (Aktionsleisten, Minikarte, Questliste, Chat …). Gilt bis zum Zurücksetzen oder /reload; nur im Zwei-Monitor-Modus."])
	uiMain:SetPoint("TOPLEFT", apply, "BOTTOMLEFT", 0, -10)
	local uiReset = UI.Button(page, RESET, 160, function()
		ns.Layout.ReleaseUI()
		Dual.RefreshOptions()
	end, L["Legt die Blizzard-Oberfläche wieder über das ganze Spielfenster."])
	uiReset:SetPoint("LEFT", uiMain, "RIGHT", 10, 0)
	local check = UI.Button(page, L["Sichtbarkeit prüfen"], 160, Dual.CheckVisible,
		L["Sucht alle eingeblendeten Oberflächenelemente, die ganz oder teilweise auf keinem Monitor liegen, und listet sie unten auf. Verschoben wird nur, was du dort einzeln anklickst."])
	check:SetPoint("LEFT", apply, "RIGHT", 10, 0)

	monInfo = UI.Text(page, "GameFontHighlight")
	monInfo:SetPoint("TOPLEFT", uiMain, "BOTTOMLEFT", 0, -16)
	monInfo:SetWidth(620)

	BuildVisibleList(page, monInfo)

	ui.panel:HookScript("OnShow", function()
		if listChecked then
			Dual.CheckVisible()   -- Lage kann sich seit der letzten Prüfung geändert haben
		end
	end)
end

function Dual.OpenOptions()
	qnCore.OpenCategory(sub)
end

---------------------------------------------------------------------------
-- Start (aus Core.lua nach ADDON_LOADED); angewendet wird danach über ns.ApplyGeometry.
---------------------------------------------------------------------------

function ns.InitSecondScreen()
	NewPage(L["Monitore"],
		L["Die Monitordaten (Monitors.lua) schreibt qnViewPort\\scripts\\Initialize-WowMonitors.ps1: einmalig Monitore auswählen und den Hauptmonitor festlegen. Set-WowWindow.ps1 zieht das Spielfenster dann über die ausgewählten Monitore und gleicht die Daten ab. Nach einer Änderung /reload."],
		BuildMonitorPage)
	sub = NewPage(L["Zweiter Monitor"],
		L["Das Spielfenster muss über mehrere Monitore gezogen sein (Fenstermodus, z. B. 5760 × 2160). Dann liegt die 3D-Welt auf dem Hauptmonitor. Oberflächenelemente verschiebst du im Bearbeitungsmodus von Blizzard; Elemente außerhalb der Monitore findest du auf der Seite „Monitore“, Taschen, Zonenkarte und Weltkarte auf der Seite „Platzierung“."],
		BuildPage)
	NewPage(L["Platzierung"],
		L["Legt Taschen und Zonenkarte an eine Ecke eines Monitors und die Weltkarte auf einen Monitor. Die Abstände zählen in Pixeln vom Rand der Ecke nach innen. Ohne Haken fasst qnViewPort das jeweilige Fenster nicht an."],
		BuildPlacementPage)

	-- Taschen: Blizzard setzt die Anker in UpdateContainerFrameAnchors – beim Öffnen und Schließen
	-- jeder Tasche und der kombinierten Tasche (ContainerFrame.lua). Unser Hook läuft danach,
	-- das Anlegen im nächsten Frame und für mehrere Aufrufe nur einmal.
	local dockLater = qnCore.Debounce(Dual.DockBags)
	hooksecurefunc("UpdateContainerFrameAnchors", function()
		if DB().bags then
			dockLater()
		end
	end)
	-- Tooltips auf Taschenplätzen
	hooksecurefunc(GameTooltip, "SetBagItem", OnSetBagItem)
	hooksecurefunc(TooltipComparisonManager, "AnchorShoppingTooltips", OnAnchorShoppingTooltips)
	-- Zonenkarte und Weltkarte: schon geladen oder später per ADDON_LOADED
	HookZoneMap()
	HookWorldMap()

	local events = ns.events
	events.Register("ADDON_LOADED", function(_, name)
		if name == ZONEMAP_ADDON then
			HookZoneMap()
		elseif name == "Blizzard_WorldMap" then
			HookWorldMap()
		end
	end)
	events.Register("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
		C_Timer.After(1, function()
			Dual.UpdateArea()
			Dual.PlaceZoneMap()
			ApplyMapFade()
			-- nur beim Einloggen bzw. /reload, nicht nach jedem Ladebildschirm
			if DB().mapAutoOpen and (isInitialLogin or isReloadingUi) then
				Dual.OpenMap()
			end
		end)
	end)
	events.Register("ZONE_CHANGED_NEW_AREA", function()
		if DB().mapFollowZone then
			MapToCurrentZone()
		end
	end)
end
