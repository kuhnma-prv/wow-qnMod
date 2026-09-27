-- qnViewPort: verkleinert den Bereich, in dem die 3D-Welt gezeichnet wird.
-- Für WoW Classic Forever; Profile und Hilfsfunktionen aus qnCore.
-- Core: Einstellungen, Anwenden auf WorldFrame, Randfarbe und -muster, Slash-Befehle.

local ADDON, ns = ...
_G.qnViewPort = ns

local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

-- Versätze in Bildschirmpixeln: links, rechts, oben, unten
ns.defaults = {
	viewport = { 0, 0, 0, 0 },
	color = { 0, 0, 0, 1 },
	pattern = "none",      -- Hintergrundmuster über der Farbe: "none", Schlüssel aus ns.PATTERNS oder "lsm:<Name>"
	patternAlpha = 0.5,    -- Deckkraft des Musters (0–1)
	suppressMessage = false,
	-- Zweiter Monitor (SecondScreen.lua); Größen in Bildschirmpixeln
	dual = {
		enabled = false,
		side = "RIGHT",        -- Lage des 2. Monitors neben dem Hauptmonitor: "RIGHT" oder "LEFT"
		width = 1920,
		height = 1200,
		offsetY = 0,           -- Abstand der Oberkante des 2. Monitors von der Fensteroberkante
		bags = false,          -- Taschen beim Öffnen an eine Monitorecke legen
		bagsMonitor = 0,       -- 0 = Hauptmonitor, sonst Nummer wie auf der Seite „Monitore“
		bagsPoint = "BOTTOMRIGHT",
		bagsOffsetX = 130,     -- Abstand vom senkrechten Rand der Ecke (Pixel)
		bagsOffsetY = 330,     -- Abstand vom waagerechten Rand der Ecke (Pixel), z. B. Platz für Leisten
		zoneMap = false,       -- Zonenkarte (BattlefieldMapFrame) beim Anzeigen an eine Monitorecke legen
		zoneMapMonitor = 0,
		zoneMapPoint = "TOPRIGHT",
		zoneMapOffsetX = 20,
		zoneMapOffsetY = 300,
		mapFollowZone = true,
		mapAutoOpen = false,
		mapNoFade = false,     -- mapFade = 0; der vorherige Wert steht dann in ns.global.mapFadeSaved
		guides = false,
		useMonitorData = true, -- Monitors.lua (scripts\) statt der Werte oben verwenden
	},
	-- Titan Panel (Titan.lua): Monitor je durchgehender Leiste, 0 = wie Titan (ganze Oberfläche)
	titan = {
		Bar = 0,
		Bar2 = 0,
		AuxBar = 0,
		AuxBar2 = 0,
	},
}

-- Kontoweit (qnViewPortDB.global, ns.global), nicht je Profil: gehört zum Rechner bzw. zum Client.
local GLOBAL_DEFAULTS = {
	layoutKey = "",        -- zuletzt automatisch übernommene Monitoranordnung (Layout.Refresh)
	-- mapFadeSaved: Wert des CVars mapFade vor „Karte beim Laufen nicht ausblenden“ (nil = nichts gemerkt)
}

-- Einstellungen des Zwei-Monitor-Modus im aktiven Profil (Layout.lua, SecondScreen.lua)
function ns.DualDB()
	return ns.db.dual
end

-- Passt ein Profil aus älteren Versionen an (vor dem Ergänzen der Vorgaben).
local function Upgrade(db)
	local dual = db.dual
	if type(dual) ~= "table" then
		return
	end
	-- Taschen: „auf dem Hauptmonitor“ -> Monitorwahl
	if dual.bagsOnMain ~= nil and dual.bagsMonitor == nil then
		dual.bagsMonitor = dual.bagsOnMain and 0 or 2
	end
	-- früher je Profil, jetzt kontoweit. qnCore hat qnViewPortDB.global beim Laden schon angelegt;
	-- der erste gefundene Wert gilt.
	local global = qnViewPortDB.global
	if global.layoutKey == nil and type(dual.layoutKey) == "string" and dual.layoutKey ~= "" then
		global.layoutKey = dual.layoutKey
	end
	if global.mapFadeSaved == nil and dual.mapFadeSaved ~= nil then
		global.mapFadeSaved = dual.mapFadeSaved
	end
end

-- Veraltete Schlüssel (qnCore löscht sie nach Upgrade)
local OBSOLETE = {
	"dual.uiOnMain",      -- war kurz standardmäßig an und hat die Oberfläche ungefragt verschoben
	"dual.constrainUI",   -- verschob die Oberfläche bei jedem Einloggen; jetzt nur noch auf Knopfdruck
	"dual.bagsOnMain",    -- jetzt dual.bagsMonitor (Upgrade)
	-- Andocken auf dem 2. Monitor entfernt
	"dual.chat", "dual.map", "dual.pad", "dual.mapShare", "dual.dockMonitor",
	"dual.layoutKey", "dual.mapFadeSaved",   -- jetzt kontoweit (Upgrade)
}

---------------------------------------------------------------------------
-- Bildschirmgröße
---------------------------------------------------------------------------

ns.screen = { 1920, 1080 }

-- Rahmen ohne Elternrahmen über das ganze Spielfenster, Skalierung 1. Bezugsgröße für alle
-- Umrechnungen – UIParent taugt dafür nicht mehr, weil Layout.lua ihn verkleinern kann.
local screenRef = CreateFrame("Frame")
screenRef:SetAllPoints()
ns.screenRef = screenRef

-- Einheiten pro Bildschirmpixel bei wirksamer Skalierung 1 (x, y)
function ns.UnitsPerPixel()
	local w, h = screenRef:GetWidth(), screenRef:GetHeight()
	if not (w and h and w > 0 and h > 0) then
		-- noch nicht angeordnet: UIParent ist zu diesem Zeitpunkt noch nicht verkleinert
		w, h = UIParent:GetWidth() * UIParent:GetScale(), UIParent:GetHeight() * UIParent:GetScale()
	end
	return w / ns.screen[1], h / ns.screen[2]
end

-- Größe des Spielfensters; vor dem ersten Zeichnen kann sie noch 0 sein, dann die Bildschirmgröße.
function ns.UpdateScreenSize()
	local size = C_VideoOptions.GetCurrentGameWindowSize()
	if size and size.x > 0 and size.y > 0 then
		ns.screen = { size.x, size.y }
		return
	end
	local x, y = GetPhysicalScreenSize()
	if x > 0 and y > 0 then
		ns.screen = { x, y }
	end
end

-- Begrenzt die Versätze: jede Seite >= 0, gegenüberliegende Seiten zusammen
-- höchstens die halbe Bildschirmbreite bzw. -höhe (mehrere Monitore: 7/8, siehe unten).
-- changedH/changedV = zuletzt geänderte Seite je Achse (1/2 bzw. 3/4); sie wird zuerst gekürzt.
function ns.Clamp(v, changedH, changedV)
	local w, h = ns.screen[1], ns.screen[2]
	local out = {}
	for i = 1, 4 do
		out[i] = math.max(0, math.floor((tonumber(v[i]) or 0) + 0.5))
	end
	local function Pair(a, b, limit, changed)
		local excess = out[a] + out[b] - limit
		if excess > 0 then
			local first = (changed == b) and b or a
			local second = (first == a) and b or a
			local cut = math.min(excess, out[first])
			out[first] = out[first] - cut
			out[second] = out[second] - (excess - cut)
		end
	end
	-- Über mehrere Monitore (Zwei-Monitor-Modus oder Monitordaten; Layout.Refresh legt die Welt dann
	-- auch ohne den Modus auf den Hauptmonitor) darf die Welt kleiner als die halbe Fensterbreite sein
	-- (z. B. kleiner Hauptmonitor, großer Zweitmonitor); mindestens 1/8 bleibt.
	local data = ns.Layout.Active()
	local wide = ns.db.dual.enabled or (data and #data.monitors > 1)
	Pair(1, 2, wide and math.floor(w * 7 / 8) or math.floor(w / 2), changedH)
	Pair(3, 4, wide and math.floor(h * 7 / 8) or math.floor(h / 2), changedV)
	return out
end

---------------------------------------------------------------------------
-- Randflächen außerhalb der Welt
---------------------------------------------------------------------------

local border = CreateFrame("Frame")
border:SetFrameStrata("BACKGROUND")
border:SetFrameLevel(0)
border:SetAllPoints()
border:Hide()

-- Je Rand eine Farbfläche und darüber eine gekachelte Musterfläche an denselben Punkten
local edges, patterns = {}, {}
for i = 1, 4 do
	edges[i] = border:CreateTexture(nil, "BACKGROUND", nil, -7)
	patterns[i] = border:CreateTexture(nil, "BACKGROUND", nil, -6)
	patterns[i]:SetAllPoints(edges[i])
	patterns[i]:Hide()
end
local eLeft, eRight, eTop, eBottom = edges[1], edges[2], edges[3], edges[4]
eLeft:SetPoint("RIGHT", WorldFrame, "LEFT")
eLeft:SetPoint("TOP", WorldFrame)
eLeft:SetPoint("BOTTOM", WorldFrame)
eRight:SetPoint("LEFT", WorldFrame, "RIGHT")
eRight:SetPoint("TOP", WorldFrame)
eRight:SetPoint("BOTTOM", WorldFrame)
eTop:SetPoint("LEFT", eLeft)
eTop:SetPoint("RIGHT", eRight)
eTop:SetPoint("BOTTOM", WorldFrame, "TOP")
eBottom:SetPoint("LEFT", eLeft)
eBottom:SetPoint("RIGHT", eRight)
eBottom:SetPoint("TOP", WorldFrame, "BOTTOM")

function ns.SetBorderColor(c)
	c = c or ns.defaults.color
	for _, tex in ipairs(edges) do
		tex:SetColorTexture(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1)
	end
end

-- Kachelbare Blizzard-Texturen (im Forever-Quelltext mit horizTile/vertTile verwendet)
ns.PATTERNS = {
	{ "rock", L["Fels"], "Interface\\FrameGeneral\\UI-Background-Rock" },
	{ "marble", L["Marmor"], "Interface\\FrameGeneral\\UI-Background-Marble" },
	{ "wood", L["Holz"], "Interface\\BlackMarket\\BlackMarketBackground-Tile" },
	{ "dialog", L["Dialog"], "Interface\\DialogFrame\\UI-DialogBox-Background" },
	{ "dialogDark", L["Dialog dunkel"], "Interface\\DialogFrame\\UI-DialogBox-Background-Dark" },
	{ "tooltip", L["Tooltip"], "Interface\\Tooltips\\UI-Tooltip-Background" },
	{ "parchment", L["Pergament"], "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal" },
	{ "achievement", ACHIEVEMENTS, "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground" },
}

local function LSM()
	return LibStub and LibStub("LibSharedMedia-3.0", true)
end

-- Auswahlliste für das Dropdown: { Schlüssel, Text }; Muster aus LibSharedMedia (falls vorhanden) dahinter
function ns.PatternChoices()
	local list = { { "none", L["Kein Muster (nur Farbe)"] } }
	for _, p in ipairs(ns.PATTERNS) do
		list[#list + 1] = { p[1], p[2] }
	end
	local lsm = LSM()
	if lsm then
		for _, name in ipairs(lsm:List("background")) do
			if name ~= "None" then
				list[#list + 1] = { "lsm:" .. name, name .. " |cff999999(LSM)|r" }
			end
		end
	end
	return list
end

local function PatternFile(key)
	for _, p in ipairs(ns.PATTERNS) do
		if p[1] == key then
			return p[3]
		end
	end
	local name = type(key) == "string" and key:match("^lsm:(.+)$")
	local lsm = name and LSM()
	return lsm and lsm:IsValid("background", name) and lsm:Fetch("background", name) or nil
end

function ns.SetBorderPattern(key, alpha)
	local file = PatternFile(key)
	for _, tex in ipairs(patterns) do
		if file then
			tex:SetTexture(file, "REPEAT", "REPEAT")
			tex:SetHorizTile(true)
			tex:SetVertTile(true)
			tex:SetAlpha(alpha or ns.defaults.patternAlpha)
			tex:Show()
		else
			tex:Hide()
		end
	end
end

-- Farbe und Muster des aktiven Profils
function ns.UpdateBorderLook()
	ns.SetBorderColor(ns.db.color)
	ns.SetBorderPattern(ns.db.pattern, ns.db.patternAlpha)
end

local function UpdateBorder(l, t, r, b)
	if l > 0 or t > 0 or r > 0 or b > 0 then
		eLeft:SetPoint("LEFT", WorldFrame, -l, 0)
		eRight:SetPoint("RIGHT", WorldFrame, r, 0)
		eTop:SetPoint("TOP", WorldFrame, 0, t)
		eBottom:SetPoint("BOTTOM", WorldFrame, 0, -b)
		border:Show()
	else
		border:Hide()
	end
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------

-- Methoden der Widget-Klasse, nicht die (gehookten) Felder von WorldFrame.
-- So lösen eigene Aufrufe die Hooks nicht erneut aus.
local dummy = CreateFrame("Frame")
local FrameClearAllPoints, FrameSetPoint = dummy.ClearAllPoints, dummy.SetPoint
ns.FrameClearAllPoints, ns.FrameSetPoint = FrameClearAllPoints, FrameSetPoint

local current   -- zuletzt angewendete (begrenzte) Versätze; kann vom gespeicherten Wert abweichen
local Reapply

-- Setzt WorldFrame auf die Versätze v (Bildschirmpixel), ohne zu speichern.
-- Im Kampf (WorldFrame geschützt) erst danach mit dem dann aktuellen Wert.
function ns.SetWorldFrame(v)
	if WorldFrame:IsProtected() and lib.DeferInCombat(Reapply) then
		return
	end
	-- WorldFrame hat keinen Elternrahmen; seine Einheiten entsprechen screenRef (Skalierung 1).
	local ux, uy = ns.UnitsPerPixel()
	local l, r = v[1] * ux, v[2] * ux
	local t, b = v[3] * uy, v[4] * uy
	FrameClearAllPoints(WorldFrame)
	FrameSetPoint(WorldFrame, "TOPLEFT", l, -t)
	FrameSetPoint(WorldFrame, "BOTTOMRIGHT", -r, b)
	UpdateBorder(l, t, r, b)
end

-- Wendet die Versätze begrenzt an, ohne sie zu speichern (Laden, Fenstergröße, Profilwechsel):
-- so bleibt der gespeicherte Wert erhalten, auch wenn das Fenster vorübergehend kleiner ist.
function ns.ShowViewport(v)
	current = ns.Clamp(v)
	ns.SetWorldFrame(current)
	ns.OnViewportChanged(current)
	return current
end

-- Eingabe des Spielers: begrenzt anwenden und speichern.
function ns.ApplyViewport(v)
	ns.db.viewport = ns.ShowViewport(v)
end

-- Angewendete Versätze (für die Optionsseite)
function ns.GetViewport()
	return current or ns.db.viewport
end

Reapply = function()
	if current then
		ns.SetWorldFrame(current)
	end
end

-- Viewport, Oberfläche und Platzierungsbereiche neu anwenden (Laden, Fenstergröße, Profilwechsel).
-- Gespeichert wird dabei nur eine neu übernommene Monitoranordnung (Layout.Refresh).
function ns.ApplyGeometry()
	ns.UpdateScreenSize()
	if ns.db.dual.enabled and not ns.Layout.Active() then
		-- ohne Monitordaten: Viewport aus den Handeinstellungen berechnen
		ns.ShowViewport(ns.Dual.GetViewport())
	else
		ns.ShowViewport(ns.db.viewport)
	end
	ns.Layout.Refresh()
	-- ausdrücklich gewählte Begrenzung der Oberfläche mit neuer Größe bzw. Skalierung neu rechnen
	ns.Layout.ReapplyUI()
	ns.Dual.ApplyAll()
end

-- Nach einem Profilwechsel (qnCore): alle Einstellungen des neuen Profils anwenden.
-- Verschiebt Blizzard-Rahmen nur, wenn das Profil es ausdrücklich verlangt (bags, zoneMap).
function ns.ApplyProfile()
	ns.EndKeep()
	ns.UpdateBorderLook()
	-- Begrenzung der Oberfläche gilt nur im Zwei-Monitor-Modus
	if not ns.db.dual.enabled then
		ns.Layout.ReleaseUI()
	end
	ns.ApplyGeometry()
	ns.Dual.ApplyMapFade()
	ns.Dual.RefreshOptions()
	ns.RefreshOptions()
	ns.Titan.Apply()
end

function ns.IsActive()
	local v = ns.db.viewport
	return v[1] ~= 0 or v[2] ~= 0 or v[3] ~= 0 or v[4] ~= 0
end

---------------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------------

-- msg ungekürzt: die vier Versätze stehen als rohe Zahlen darin
lib.RegisterSlash("QNVIEWPORT", { "/qnvp", "/qnviewport", "/viewport" }, function(cmd, rest, msg)
	local l, r, t, b = msg:match("^(%d+%.?%d*)%s+(%d+%.?%d*)%s+(%d+%.?%d*)%s+(%d+%.?%d*)$")
	if l then
		local v = { tonumber(l), tonumber(r), tonumber(t), tonumber(b) }
		if v[1] + v[2] + v[3] + v[4] > 0 then
			ns.OpenOptions()
			ns.ApplyWithConfirm(v)
		else
			ns.EndKeep()
			ns.ApplyViewport(v)
			ns.Print(L["Viewport zurückgesetzt."])
		end
	elseif msg == "" then
		ns.OpenOptions()
	elseif cmd == "dual" then
		ns.Dual.Slash(rest)
	elseif not ns.Layout.Slash(msg:lower()) then
		-- ein Schlüssel; Print gibt jede Zeile als eigene Chatzeile aus
		ns.Print(L["/qnvp – Optionen öffnen\n/qnvp 0 0 0 0 – Viewport zurücksetzen\n/qnvp L R O U – Versätze in Pixeln setzen (links, rechts, oben, unten)\n/qnvp dual – Zweiter Monitor (/qnvp dual help)\n/qnvp monitors – Monitordaten anzeigen\n/qnvp check – Rahmen außerhalb der Monitore suchen (verschieben: Optionen → Monitore)"])
	end
end)

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

local events = ns.events

ns.OnLoad(function()
	-- Einstellungen je Profil (= Layout des Bearbeitungsmodus, qnCore); ns.db ist immer das aktive Profil.
	local store = lib.Profiles.Register({
		ns = ns,
		sv = "qnViewPortDB",
		defaults = ns.defaults,
		upgrade = Upgrade,
		obsolete = OBSOLETE,
		onSwitch = ns.ApplyProfile,
	})
	ns.global = lib.MergeDefaults(store.global, GLOBAL_DEFAULTS)
	ns.UpdateBorderLook()

	-- Blizzard setzt WorldFrame u. a. bei Zwischensequenzen zurück; danach neu anwenden.
	hooksecurefunc(WorldFrame, "ClearAllPoints", Reapply)
	hooksecurefunc(WorldFrame, "SetAllPoints", Reapply)
	hooksecurefunc(WorldFrame, "SetPoint", Reapply)

	ns.InitOptions()
	ns.InitSecondScreen()
	-- Titan legt seine Anker gleich an: dafür schon die echte Fenstergröße (sonst die Vorgabe oben)
	ns.UpdateScreenSize()
	ns.InitTitan()
	ns.Layout.Init()
	ns.ApplyGeometry()

	-- ab hier ist ns.db gesetzt
	events.Register("PLAYER_LOGIN", function()
		-- LibSharedMedia-Muster anderer Addons sind erst jetzt sicher registriert
		ns.UpdateBorderLook()
		if ns.IsActive() and not ns.db.suppressMessage then
			C_Timer.After(8, function()
				ns.Print(L["Eigener Viewport ist aktiv. /qnvp zum Einstellen, /qnvp 0 0 0 0 zum Zurücksetzen."])
			end)
		end
	end)
	-- Neue Anordnung (z. B. Set-WowWindow.ps1 nach dem Einloggen): Viewport vom Hauptmonitor
	events.Register("DISPLAY_SIZE_CHANGED", ns.ApplyGeometry)
	events.Register("UI_SCALE_CHANGED", ns.ApplyGeometry)
end)
