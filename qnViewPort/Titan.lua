-- qnViewPort: Titan Panel auf den Monitoren (nur wenn Titan geladen ist, ## OptionalDeps: Titan).
--   * Die durchgehenden Titan-Leisten (oben: Bar, Bar2; unten: AuxBar, AuxBar2) liegen auf einem
--     wählbaren Monitor statt über dem ganzen Spielfenster.
--   * Tooltips und Steuerfenster der Titan-Plugins bleiben auf dem Monitor des Plugins.
-- Titan hängt die Leisten mit zwei Ankern an UIParent. Hier wird in Titans statischer Tabelle
-- TitanBarData der Bezugsrahmen (show.rel_fr, bott.rel_fr) durch einen eigenen Ankerrahmen je Leiste
-- ersetzt. Der liegt über dem gewählten Monitor oder – ohne Auswahl – genau über UIParent, dann
-- bleibt alles wie bei Titan. Titan selbst wird nicht verändert; nachgezogen werden nur die Breite
-- der Auto-Hide-Leiste, die Lage verborgener Leisten sowie Tooltips und Steuerfenster.
-- Einstellungen: ns.db.titan (je Profil), Monitornummern wie auf der Seite „Monitore“.

local _, ns = ...
local L = ns.L
local UI = qnCore.UI

local Titan = {}
ns.Titan = Titan

-- Die zweite Leiste liegt bei Titan eine Leistenhöhe weiter innen als die erste (Titan-Vorgabe
-- off_y). Steht die erste nicht an derselben Kante, rückt die zweite an den Rand
-- (dir: +1 nach oben, -1 nach unten).
Titan.BARS = {
	{ name = "Bar" },
	{ name = "Bar2", partner = "Bar", dir = 1 },
	{ name = "AuxBar" },
	{ name = "AuxBar2", partner = "AuxBar", dir = -1 },
}

local byFrame = {}
local anchors = {}
Titan.anchors = anchors

local function DB()
	return ns.db.titan
end

local function FrameName(bar)
	return TITAN_PANEL_DISPLAY_PREFIX .. bar
end

---------------------------------------------------------------------------
-- Monitore (dieselben Nummern wie ns.Layout.GetVisible)
---------------------------------------------------------------------------

-- Rechtecke { l, r, t, b } bei Skalierung 1, Ursprung unten links
function Titan.Monitors()
	return ns.Layout.GetVisibleAbs()
end

-- gewählter Monitor einer Leiste: Rechteck, Nummer; nil = wie Titan (auch wenn der Monitor fehlt)
local function MonitorOf(bar)
	local i = tonumber(DB()[bar]) or 0
	local r = i > 0 and Titan.Monitors()[i]
	if r then
		return r, i
	end
end

-- sichtbarer Bereich, in dem die Mitte des Rahmens liegt
local function AreaAt(frame)
	local a = qnCore.Visible.FrameAbs(frame)
	if not a then
		return nil
	end
	local x, y = (a.l + a.r) / 2, (a.t + a.b) / 2
	for _, r in ipairs(Titan.Monitors()) do
		if x >= r.l and x <= r.r and y >= r.b and y <= r.t then
			return r
		end
	end
end

---------------------------------------------------------------------------
-- Anker der Leisten
---------------------------------------------------------------------------

-- vom Spieler eingeschaltete Leiste (Titan-Einstellung, auch bei Auto-Hide)
local function BarShown(bar)
	local vars = TitanBarDataVars and TitanBarDataVars[FrameName(bar)]
	return vars and vars.show
end

-- Bereich, an dem eine Leiste ausgerichtet wird
local function AreaOf(bar)
	return MonitorOf(bar) or qnCore.Visible.FrameAbs(UIParent)
end

-- Versatz der zweiten Leiste (Einheiten bei Skalierung 1): 0, wenn die erste Leiste eingeschaltet
-- ist und an derselben Kante desselben Bereichs liegt, sonst eine Leistenhöhe zum Rand hin.
local function Shift(b, r)
	if not b.partner then
		return 0
	end
	local p = BarShown(b.partner) and AreaOf(b.partner)
	if p and p.l < r.r and p.r > r.l then
		local edge = b.dir > 0 and math.abs(p.t - r.t) or math.abs(p.b - r.b)
		if edge < 1 then
			return 0
		end
	end
	local f = _G[FrameName(b.name)]
	return b.dir * TITAN_PANEL_BAR_HEIGHT * (f and f:GetEffectiveScale() or 1)
end

local function UpdateAnchor(b)
	local a = anchors[b.name]
	local r = MonitorOf(b.name)
	a:ClearAllPoints()
	if not r then
		a:SetAllPoints(UIParent)
		return
	end
	a:SetPoint("BOTTOMLEFT", ns.screenRef, "BOTTOMLEFT", r.l, r.b + Shift(b, r))
	a:SetSize(r.r - r.l, r.t - r.b)
end

function Titan.UpdateAnchors()
	for _, b in ipairs(Titan.BARS) do
		UpdateAnchor(b)
	end
end

-- Auto-Hide-Leiste: Titan setzt sie einmal auf die Breite von UIParent.
local function FixHider(b)
	local data = TitanBarData[FrameName(b.name)]
	local hider = data and data.hider and _G[data.hider]
	local w = anchors[b.name]:GetWidth()
	if hider and w and w > 0 then
		hider:SetWidth(w / hider:GetEffectiveScale())
	end
end

-- Verborgene Leiste: Titan schiebt sie um hide_y über bzw. unter ihren Bezugsrahmen. Bei einem
-- Monitor kann dort ein anderer Monitor liegen – deshalb über das Spielfenster hinaus.
local function ParkHidden(b)
	local display = _G[FrameName(b.name)]
	if not display then
		return
	end
	local s = display:GetEffectiveScale()
	display:ClearAllPoints()
	display:SetPoint("BOTTOMLEFT", ns.screenRef, "TOPLEFT", 0, TITAN_PANEL_BAR_HEIGHT * 4)
	display:SetSize(anchors[b.name]:GetWidth() / s, TITAN_PANEL_BAR_HEIGHT)
end

local function TitanReady()
	return Titan__InitializedPEW and TitanBarDataVars and TitanBarDataVars[FrameName("Bar")] ~= nil
end

-- Anker setzen und Titan die Leisten neu zeigen lassen (Profilwechsel, neue Anordnung, Optionen)
function Titan.Apply()
	if not Titan.active then
		return
	end
	Titan.UpdateAnchors()
	if TitanReady() then
		TitanPanelBarButton_DisplayBarsWanted("qnViewPort")
	end
	Titan.RefreshOptions()
end

---------------------------------------------------------------------------
-- Tooltips und Steuerfenster
-- Titan wählt die Seite eines Tooltips nach GetScreenWidth() bzw. UIParent (TitanTemplate.lua,
-- SetPanelTooltip; TitanUtils_GetOffscreen), also nach dem ganzen Spielfenster. Am Rand eines
-- Monitors ragt der Tooltip dann in einen Teil des Fensters, der auf keinem Monitor zu sehen ist.
---------------------------------------------------------------------------

-- Legt tip neu an das Plugin button, wenn Titan ihn dort verankert hat und er über den Monitor
-- hinausragt. Titans Seite bleibt, wenn sie passt; sonst die andere Seite, und was dann noch
-- übersteht, wird hineingeschoben. Passt er, bleibt Titans Anker unverändert (Steuerfenster hängen
-- an der Mitte der Plugin-Kante, z. B. TOPLEFT an BOTTOM – neu an einer Ecke sprängen sie).
function Titan.FitToMonitor(tip, button)
	if not (tip and button and tip:IsShown()) then
		return
	end
	local point, rel, relPoint, ox, oy = tip:GetPoint(1)
	if rel ~= button or type(point) ~= "string" then
		return
	end
	local area, b = AreaAt(button), qnCore.Visible.FrameAbs(button)
	local s = tip:GetEffectiveScale()
	local w, h = (tip:GetWidth() or 0) * s, (tip:GetHeight() or 0) * s
	if not (area and b and w > 0 and h > 0) then
		return
	end

	-- Lage mit Titans Anker; ragt nichts hinaus, nichts ändern
	relPoint = type(relPoint) == "string" and relPoint or point
	local ax = (relPoint:find("LEFT$") and b.l) or (relPoint:find("RIGHT$") and b.r) or (b.l + b.r) / 2
	local ay = (relPoint:find("^TOP") and b.t) or (relPoint:find("^BOTTOM") and b.b) or (b.t + b.b) / 2
	ax, ay = ax + (tonumber(ox) or 0) * s, ay + (tonumber(oy) or 0) * s
	local l0 = (point:find("LEFT$") and ax) or (point:find("RIGHT$") and ax - w) or ax - w / 2
	local t0 = (point:find("^TOP") and ay) or (point:find("^BOTTOM") and ay + h) or ay + h / 2
	local e = 0.5   -- Rundung
	if l0 >= area.l - e and l0 + w <= area.r + e and t0 <= area.t + e and t0 - h >= area.b - e then
		return
	end

	-- senkrecht: TOP = unter dem Plugin, BOTTOM = darüber
	local v = point:find("^BOTTOM") and "BOTTOM" or "TOP"
	local below, above = b.b - h >= area.b, b.t + h <= area.t
	if v == "TOP" and not below and above then
		v = "BOTTOM"
	elseif v == "BOTTOM" and not above and below then
		v = "TOP"
	end
	-- waagerecht: LEFT = reicht nach rechts, RIGHT = nach links
	local hz = point:find("RIGHT$") and "RIGHT" or "LEFT"
	local toRight, toLeft = b.l + w <= area.r, b.r - w >= area.l
	if hz == "LEFT" and not toRight and toLeft then
		hz = "RIGHT"
	elseif hz == "RIGHT" and not toLeft and toRight then
		hz = "LEFT"
	end

	-- was dann noch übersteht, in den Monitor schieben
	local left = hz == "LEFT" and b.l or (b.r - w)
	local top = v == "TOP" and b.b or (b.t + h)
	local dx, dy = 0, 0
	if left + w > area.r then
		dx = area.r - (left + w)
	end
	if left + dx < area.l then
		dx = area.l - left
	end
	if top - h < area.b then
		dy = area.b - (top - h)
	end
	if top + dy > area.t then
		dy = area.t - top
	end

	tip:ClearAllPoints()
	tip:SetPoint(v .. hz, button, (v == "TOP" and "BOTTOM" or "TOP") .. hz, dx / s, dy / s)
end

-- Rahmen, die Titan an ein Plugin hängt: eigener Tooltip, GameTooltip (ältere Plugins),
-- Tooltip-Rahmen eines LDB-Objekts (.tooltip)
local function Fit(button)
	if not button then
		return
	end
	Titan.FitToMonitor(TitanPanelTooltip, button)
	Titan.FitToMonitor(GameTooltip, button)
	local id = button.registry and button.registry.id
	local plugin = id and TitanUtils_GetPlugin(id)
	if plugin and plugin.tooltipDisplayFrame then
		Titan.FitToMonitor(plugin.tooltipDisplayFrame, button)
	end
end

-- sofort und noch einmal im nächsten Frame (dann hat der Tooltip seine endgültige Größe)
local function FitNowAndLater(button)
	Fit(button)
	C_Timer.After(0, function()
		Fit(button)
	end)
end

---------------------------------------------------------------------------
-- Optionsseite (Unterkategorie „Titan Panel“, nur mit Titan)
---------------------------------------------------------------------------

local page
local dropdowns = {}

-- Einträge eines Dropdowns; ein gespeicherter, aber nicht mehr vorhandener Monitor bleibt sichtbar.
function Titan.Entries(bar)
	local list = { { 0, L["Wie Titan (ganze Oberfläche)"] } }
	local monitors = ns.Layout.GetVisible()
	for i, r in ipairs(monitors) do
		list[#list + 1] = { i, L["Monitor %d (%d × %d)"]:format(i, r.w, r.h) }
	end
	local saved = tonumber(DB()[bar]) or 0
	if saved > #monitors then
		list[#list + 1] = { saved, L["Monitor %d (nicht vorhanden)"]:format(saved) }
	end
	return list
end

function Titan.RefreshOptions()
	for _, dd in ipairs(dropdowns) do
		dd:Refresh()
	end
end

local function BuildPage()
	local desc = ns.Header(page, "qnViewPort – Titan Panel",
		L["Legt die durchgehenden Titan-Leisten an die obere bzw. untere Kante eines Monitors. Ein- und ausgeschaltet werden sie weiter in Titan. Tooltips der Titan-Plugins bleiben auf dem Monitor des Plugins."])

	local anchor = desc
	for i, b in ipairs(Titan.BARS) do
		local data = TitanBarData[FrameName(b.name)]
		local dd = UI.Dropdown(page, 240, function() return Titan.Entries(b.name) end,
			function() return tonumber(DB()[b.name]) or 0 end,
			function(v)
				DB()[b.name] = v
				Titan.Apply()
			end)
		dd:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", i == 1 and 164 or 0, i == 1 and -16 or -10)
		UI.Label(page, dd, data and data.locale_name or b.name)
		UI.Tooltip(dd, data and data.locale_name or b.name, L["Nummern wie auf der Seite „Monitore“."])
		dropdowns[#dropdowns + 1] = dd
		anchor = dd
	end

	local apply = UI.Button(page, APPLY, 160, Titan.Apply,
		L["Legt die Leisten erneut an ihre Monitore, z. B. nach einer Änderung der Monitoranordnung."])
	apply:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -160, -16)
end

---------------------------------------------------------------------------
-- Start (aus Core.lua nach ADDON_LOADED)
---------------------------------------------------------------------------

-- Ohne Titan: keine Anker, keine Hooks, keine Optionsseite.
function ns.InitTitan()
	if not (C_AddOns.IsAddOnLoaded("Titan") and TitanBarData and TITAN_PANEL_DISPLAY_PREFIX) then
		return
	end
	Titan.active = true

	for _, b in ipairs(Titan.BARS) do
		local a = CreateFrame("Frame", "qnViewPortTitanAnchor" .. b.name)
		a:SetAllPoints(UIParent)
		anchors[b.name] = a
		byFrame[FrameName(b.name)] = b
		local data = TitanBarData[FrameName(b.name)]
		if data then
			data.show.rel_fr = a
			data.bott.rel_fr = a
		end
	end
	Titan.UpdateAnchors()

	-- Nach Titans Anzeigen: Anker nachziehen (die zweite Leiste hängt vom Zustand der ersten ab).
	hooksecurefunc("TitanPanelBarButton_Show", function(frame)
		local b = byFrame[frame]
		if b then
			Titan.UpdateAnchors()
			FixHider(b)
		end
	end)
	hooksecurefunc("TitanPanelBarButton_Hide", function(frame)
		local b = byFrame[frame]
		if not b or TITAN_PANEL_MOVING == 1 then
			return
		end
		Titan.UpdateAnchors()
		FixHider(b)
		if MonitorOf(b.name) then
			ParkHidden(b)
		end
	end)

	hooksecurefunc("TitanPanelButton_OnEnter", FitNowAndLater)
	-- Titan legt den Tooltip beim Auffrischen neu an (z. B. die Uhr jede Sekunde)
	hooksecurefunc("TitanPanelButton_UpdateTooltip", Fit)
	hooksecurefunc("TitanPanelPluginHandle_OnUpdate", function(t)
		local id = type(t) == "table" and t[1] or t
		Fit(type(id) == "string" and _G[TitanUtils_ButtonName(id)] or nil)
	end)
	-- Steuerfenster (Linksklick, z. B. Lautstärke, Uhr-Versatz): Titan prüft nur gegen UIParent.
	hooksecurefunc("TitanPanelButton_OnClick", function(button)
		local id = button and button.registry and button.registry.id
		local frame = id and TitanUtils_GetControlFrame(id)
		if frame and frame:IsShown() then
			Titan.FitToMonitor(frame, button)
		end
	end)

	local ApplySoon = qnCore.Debounce(Titan.Apply, 0.1)
	qnCore.Visible.OnAreaChanged(ApplySoon)
	for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
		ns.events.Register(event, ApplySoon)
	end

	page = CreateFrame("Frame")
	page:Hide()
	page:SetScript("OnShow", Titan.RefreshOptions)
	BuildPage()
	Titan.category = Settings.RegisterCanvasLayoutSubcategory(ns.category, page, "Titan Panel")
end
