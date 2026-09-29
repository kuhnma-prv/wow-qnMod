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
		return false, L["The game window is only %d × %d pixels. It must span both monitors (main monitor width + %d).%s"]:format(
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
local mapPlace = NewPlacement("zoneMap", L["Zone Map"], 1, 0.8, 0)
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
		ns.Print(L["The Zone Map cannot be loaded in combat."])
		return
	end
	if not LoadZoneMap() then
		ns.Print(L["Zone Map (Blizzard_BattlefieldMap) could not be loaded."])
		return
	end
	local f = _G.BattlefieldMapFrame
	if (f:IsShown() and true or false) ~= (on and true or false) then
		f:Toggle()
	end
	if on and not f:IsShown() then
		ns.Print(L["The Zone Map is not available here (Blizzard does not show it in every instance, for example)."])
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
			ns.Print(L["Dual monitor mode on: 3D world on the main monitor."])
		else
			ns.EndKeep()
			ns.ApplyViewport({ 0, 0, 0, 0 })
			ns.Layout.ReleaseUI()
			ns.Print(L["Dual monitor mode off."])
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
		ns.Print((ns.Layout.Active() and L["Second monitor: %d × %d, top offset %d (only used without monitor data)"]
			or L["Second monitor: %d × %d, top offset %d"]):format(DB().width, DB().height, DB().offsetY))
	else
		-- ein Schlüssel; Print gibt jede Zeile als eigene Chatzeile aus
		ns.Print(L["/qnvp dual – options   |   on / off   |   left / right\n/qnvp dual W H [Y] – size of the second monitor in pixels, Y = distance from the top (only without monitor data)\n/qnvp dual guides – show placement areas   |   map – open the World Map   |   zonemap – toggle the Zone Map"])
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
	info:SetText(L["|cffccccccGame window:|r %d × %d     |cffccccccSecond monitor in the window:|r %s     |cffccccccWorld:|r %s%s%s"]:format(
		ns.screen[1], ns.screen[2],
		second and ("x %d, y %d, %d × %d"):format(second.x, second.y, second.w, second.h) or L["none"],
		main and ("%d × %d"):format(main.w, main.h) or L["whole window"],
		data and ("\n" .. L["|cff80ff80Monitor data active|r – position and size above are measured and cannot be changed (\"Monitors\" page)."]) or "",
		ok and "" or ("\n|cffff8080" .. msg .. "|r")))
end

-- Monitorliste der Seite „Monitore“ samt Lage der Blizzard-Oberfläche
local function RefreshMonitorText()
	local lines = ns.Layout.Describe()
	lines[#lines + 1] = ""
	lines[#lines + 1] = ns.Layout.IsUIConstrained() and L["Blizzard interface: on the main monitor"]
		or L["Blizzard interface: across the whole window"]
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
	local enable = Check(L["Dual monitor mode enabled (3D world on the main monitor only)"], nil, nil, nil,
		function() return DB().enabled end, Dual.SetEnabled)
	enable:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -4, -14)

	-- Lage des 2. Monitors: Handwerte ohne Monitordaten, sonst gemessene Werte (gesperrt)
	local side = Choice(L["Position of the second monitor"], 220, {
		{ "RIGHT", L["Right of the main monitor"] },
		{ "LEFT", L["Left of the main monitor"] },
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
	UI.Tooltip(side, L["Position of the second monitor"], L["Only adjustable without monitor data. With monitor data, position, size and offset are measured (qnViewPort\\scripts)."])

	local wBox = NumBox(HUD_EDIT_MODE_SETTING_CHAT_FRAME_WIDTH, "width")
	wBox:SetPoint("TOPLEFT", side, "BOTTOMLEFT", -90, -18)
	local hBox = NumBox(HUD_EDIT_MODE_SETTING_CHAT_FRAME_HEIGHT, "height")
	hBox:SetPoint("LEFT", wBox, "RIGHT", 70, 0)
	local yBox = NumBox(L["Distance from top"], "offsetY")
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
			list[#list + 1] = { 0, L["Main monitor (%d × %d)"]:format(r.w, r.h) }
		elseif r == main then
			list[#list + 1] = { i, L["Monitor %d (%d × %d), main"]:format(i, r.w, r.h) }
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
	UI.Tooltip(monitor, monitorTitle, L["Numbers as on the \"Monitors\" page."])

	local corner = Choice(L["Corner"], 150, CORNERS,
		function() return Corner(prefix) end,
		function(p) DB()[prefix .. "Point"] = p end, Dual.ApplyAll)
	corner:SetPoint("LEFT", monitor, "RIGHT", 60, 0)
	UI.Tooltip(corner, cornerTitle)

	local offsetX = NumBox(L["Horizontal offset"], prefix .. "OffsetX", Dual.ApplyAll)
	offsetX:SetPoint("TOPLEFT", monitor, "BOTTOMLEFT", 80, -14)
	local offsetY = NumBox(L["vertical"], prefix .. "OffsetY", Dual.ApplyAll)
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
	local cBags = Check(L["Place bags when opened"], "bags",
		L["Moves open bags to the chosen corner each time they open. They stack vertically from there, further columns towards the center of the monitor."],
		Dual.ApplyAll)
	cBags:SetPoint("TOPLEFT", bagHead, "BOTTOMLEFT", -4, -4)
	local bagMonitor = PlacementControls("bags", cBags, L["Monitor for the bags"], L["Corner for the bags"])

	-- Zonenkarte
	local mapHead = UI.Text(page, "GameFontNormal", L["Zone Map (Shift+M)"])
	mapHead:SetPoint("TOPLEFT", bagMonitor, "BOTTOMLEFT", -90, -52)
	local cShow = Check(L["Show Zone Map"], nil,
		L["Shows or hides Blizzard's Zone Map. Blizzard remembers the state itself (CVar showBattlefieldMinimap)."],
		nil, Dual.IsZoneMapShown, Dual.SetZoneMapShown)
	cShow:SetPoint("TOPLEFT", mapHead, "BOTTOMLEFT", -4, -4)
	local cPlace = Check(L["Place Zone Map when shown"], "zoneMap",
		L["Moves the Zone Map and its tab to the chosen corner each time it is shown. Dragging the tab then only lasts until it is shown again."],
		Dual.ApplyAll)
	cPlace:SetPoint("TOPLEFT", cShow, "BOTTOMLEFT", 0, -2)
	local mapMonitor, mapOffsetX = PlacementControls("zoneMap", cPlace, L["Monitor for the Zone Map"], L["Corner for the Zone Map"])
	-- Größe gilt auch ohne Platzierung; linksbündig mit dem Monitor-Knopf
	local mapScale = ZoneMapScaleSlider()
	mapScale:SetPoint("TOPLEFT", mapOffsetX, "BOTTOMLEFT", -80, -14)

	-- Weltkarte: maximiert und verkleinert („Karte & Questlog“) je auf einen ganzen Monitor
	local worldHead = UI.Text(page, "GameFontNormal", WORLDMAP_BUTTON)
	worldHead:SetPoint("TOPLEFT", mapScale, "BOTTOMLEFT", -90, -20)
	local cWorld = Check(L["Maximized World Map on"], "worldMap",
		L["Blizzard places the maximized World Map across the whole game window, i.e. across all monitors. On: map and black background only on the selected monitor."],
		Dual.ApplyAll)
	cWorld:SetPoint("TOPLEFT", worldHead, "BOTTOMLEFT", -4, -4)
	local worldMonitor = Choice("", 240, MonitorEntries,
		function() return MonitorIndex("worldMap") end,
		function(i) DB().worldMapMonitor = i end, Dual.ApplyAll)
	worldMonitor:SetPoint("LEFT", cWorld, "LEFT", 260, 0)
	UI.Tooltip(worldMonitor, L["Monitor for the maximized World Map"], L["Numbers as on the \"Monitors\" page."])
	local cQuest = Check(L["\"Map & Quest Log\" on"], "questLog",
		L["The minimized World Map with the quest log – opening the quest log shows this view. Blizzard places it at the left edge of the game window. On: at the left edge of the selected monitor."],
		Dual.ApplyAll)
	cQuest:SetPoint("TOPLEFT", cWorld, "BOTTOMLEFT", 0, -6)
	local questMonitor = Choice("", 240, MonitorEntries,
		function() return MonitorIndex("questLog") end,
		function(i) DB().questLogMonitor = i end, Dual.ApplyAll)
	questMonitor:SetPoint("LEFT", cQuest, "LEFT", 260, 0)
	UI.Tooltip(questMonitor, L["Monitor for \"Map & Quest Log\""], L["Numbers as on the \"Monitors\" page."])

	local cFollow = Check(L["Map follows the current zone"], "mapFollowZone",
		L["While the map is open, switches to the new zone's map when you enter it. Blizzard shows the current zone anyway when the map opens."])
	cFollow:SetPoint("TOPLEFT", cQuest, "BOTTOMLEFT", 0, -6)
	local cOpen = Check(L["Open the map on login"], "mapAutoOpen",
		L["Only on login and after /reload, not after loading screens."])
	cOpen:SetPoint("LEFT", cFollow, "LEFT", 300, 0)
	local cFade = Check(L["Do not fade the map while moving"], "mapNoFade",
		L["Sets the Blizzard option mapFade to 0. Turning this off restores the previous value. Blizzard only fades the map while the mouse is not over it – so hardly ever with the maximized map."],
		function() ApplyMapFade(true) end)
	cFade:SetPoint("TOPLEFT", cFollow, "BOTTOMLEFT", 0, -2)

	local cGuides = Check(L["Show areas"], "guides",
		L["Outlines the areas: blue bags, yellow Zone Map, green World Map, purple \"Map & Quest Log\" (only while placement is on)."], Dual.UpdateArea)
	cGuides:SetPoint("TOPLEFT", cFade, "BOTTOMLEFT", 0, -10)

	local apply = ApplyButton(cGuides, false)
	local openMap = UI.Button(page, L["Open map"], 160, Dual.OpenMap)
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
	GameTooltip:AddLine(L["Moves only this element onto a monitor by the shortest path. Marked in red: its current area."], 1, 1, 1, true)
	if e.editMode then
		GameTooltip:AddLine(L["Edit Mode frame: lasts until /reload or until the layout is reloaded. To keep it: move it in Edit Mode."], 1, 0.8, 0.3, true)
	end
	if e.protected then
		GameTooltip:AddLine(L["Protected frame: not in combat. Moving it from addon code can cause \"action blocked\" messages (taint)."], 1, 0.5, 0.5, true)
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
	row.button = UI.Button(row, L["Move into visible area"], 180, function(self)
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
		listHeader:SetText("|cff80ff80" .. L["All shown interface elements are on a monitor."] .. "|r")
	else
		listHeader:SetText(L["%d element(s) fully or partly outside the monitors"]:format(#list))
	end
	listPage.Fit()
end

-- Liste im Inhalt der Seite (blättert mit der Seite)
local function BuildVisibleList(parent, anchor)
	listHeader = UI.Text(parent, "GameFontNormal", L["Not checked yet – press \"Check visibility\"."])
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
	local cData = Check(L["Use monitor data"], "useMonitorData",
		L["Off: position and size of the second monitor come from the \"Second Monitor\" page."], function()
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
	local uiMain = UI.Button(page, L["Interface to main monitor"], 220, function()
		ns.Layout.ConstrainUI()
		Dual.RefreshOptions()
	end, L["Places UIParent over the main monitor once. Caution: this moves ALL Blizzard windows attached to UIParent (action bars, minimap, objective tracker, chat …). Lasts until reset or /reload; dual monitor mode only."])
	uiMain:SetPoint("TOPLEFT", apply, "BOTTOMLEFT", 0, -10)
	local uiReset = UI.Button(page, RESET, 160, function()
		ns.Layout.ReleaseUI()
		Dual.RefreshOptions()
	end, L["Places the Blizzard interface across the whole game window again."])
	uiReset:SetPoint("LEFT", uiMain, "RIGHT", 10, 0)
	local check = UI.Button(page, L["Check visibility"], 160, Dual.CheckVisible,
		L["Finds all shown interface elements that are fully or partly outside every monitor and lists them below. Only what you click there, one at a time, is moved."])
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
	NewPage(L["Monitors"],
		L["The monitor data (Monitors.lua) is written by qnViewPort\\scripts\\Initialize-WowMonitors.ps1: select the monitors once and set the main monitor. Set-WowWindow.ps1 then stretches the game window across the selected monitors and updates the data. /reload after a change."],
		BuildMonitorPage)
	sub = NewPage(L["Second Monitor"],
		L["The game window must be stretched across several monitors (windowed mode, e.g. 5760 × 2160). The 3D world is then placed on the main monitor. Move interface elements with Blizzard's Edit Mode; elements outside the monitors are listed on the \"Monitors\" page, bags, Zone Map and World Map are on the \"Placement\" page."],
		BuildPage)
	NewPage(L["Placement"],
		L["Places bags and the Zone Map in a corner of a monitor and the World Map on a monitor. Offsets are counted in pixels inward from the edges of the corner. Unless checked, qnViewPort does not touch that window."],
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
