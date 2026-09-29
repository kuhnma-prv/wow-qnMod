-- qnViewPort: Monitoranordnung.
-- Liest qnViewPortMonitors aus Monitors.lua (erzeugt von scripts\Initialize-WowMonitors.ps1
-- bzw. Set-WowWindow.ps1) und liefert daraus
--   * den Hauptmonitor: Viewport der 3D-Welt und Bereich für UIParent,
--   * die Teile des Fensters, die auf einem Monitor zu sehen sind,
--   * den 2. Monitor und die wählbaren Monitore für die Platzierungsbereiche (SecondScreen.lua).
-- Dazu: UIParent auf den Hauptmonitor begrenzen, Rahmen außerhalb der Monitore finden.
-- Den sichtbaren Bereich liefert es qnCore.Visible (Rahmen in den sichtbaren Bereich holen, auch für
-- qnMeter, qnNumKeyPad, qnBuffMod) und meldet dort jede Änderung der Anordnung.
-- Rechtecke in Fensterpixeln { x, y, w, h }, Ursprung oben links. "abs" = Einheiten bei
-- wirksamer Skalierung 1, Ursprung unten links (wie GetLeft() * GetEffectiveScale()).

local _, ns = ...
local L = ns.L
local Visible = qnCore.Visible

local Layout = {}
ns.Layout = Layout

local DB = ns.DualDB

---------------------------------------------------------------------------
-- Monitordaten
---------------------------------------------------------------------------

local cache, cacheW, cacheH, problem

-- Monitordaten, umgerechnet auf die aktuelle Fenstergröße; nil wenn keine oder unpassend.
function Layout.GetData()
	local W, H = ns.screen[1], ns.screen[2]
	if cacheW == W and cacheH == H then
		return cache or nil
	end
	cacheW, cacheH, cache, problem = W, H, false, nil

	local data = _G.qnViewPortMonitors
	if type(data) ~= "table" or type(data.window) ~= "table" or type(data.monitors) ~= "table" then
		problem = L["No monitor data – run qnViewPort\\scripts\\Initialize-WowMonitors.ps1, then /reload."]
		return nil
	end
	local dw, dh = tonumber(data.window.width) or 0, tonumber(data.window.height) or 0
	if dw <= 0 or dh <= 0 then
		problem = L["Monitor data without window size."]
		return nil
	end
	-- Anders großes Fenster (z. B. Auflösungsskalierung) nur bei gleichem Seitenverhältnis umrechnen.
	if math.abs(dw / dh - W / H) > 0.01 then
		problem = L["Game window %d × %d does not match the monitor data (%d × %d) – run Set-WowWindow.ps1."]:format(W, H, dw, dh)
		return nil
	end
	local kx, ky = W / dw, H / dh
	local function Px(v, k)
		return math.floor((tonumber(v) or 0) * k + 0.5)
	end
	local list, main = {}, nil
	for _, m in ipairs(data.monitors) do
		local r = {
			index = #list + 1,
			x = Px(m.x, kx), y = Px(m.y, ky), w = Px(m.width, kx), h = Px(m.height, ky),
			name = m.name, device = m.device, selected = m.selected,
		}
		if r.w > 0 and r.h > 0 then
			list[#list + 1] = r
			if m.main and not main then
				main = r
			end
		end
	end
	main = main or list[1]
	if not main then
		problem = L["Monitor data without a monitor."]
		return nil
	end
	cache = { monitors = list, main = main }
	return cache
end

-- Monitordaten, sofern sie benutzt werden sollen
function Layout.Active()
	return DB().useMonitorData and Layout.GetData() or nil
end

function Layout.GetProblem()
	Layout.GetData()
	return problem
end

-- ganzes Spielfenster
function Layout.Full()
	return { x = 0, y = 0, w = ns.screen[1], h = ns.screen[2] }
end

local function IsFull(r)
	return r.x < 1 and r.y < 1 and r.w > ns.screen[1] - 1 and r.h > ns.screen[2] - 1
end

-- Rechteck des 2. Monitors aus den Handeinstellungen (x, y, w, h)
local function ManualSecond()
	local d = DB()
	local W, H = ns.screen[1], ns.screen[2]
	local w2 = math.max(1, math.min(math.floor(d.width), W - 1))
	local h2 = math.max(1, math.min(math.floor(d.height), H))
	local oy = math.max(0, math.min(math.floor(d.offsetY), H - h2))
	return { x = (d.side == "LEFT") and 0 or (W - w2), y = oy, w = w2, h = h2 }
end

-- Hauptmonitor, auf dem die 3D-Welt liegt; nil = ganzes Fenster
function Layout.GetMainRect()
	local data = Layout.Active()
	if data then
		return data.main
	end
	if DB().enabled then
		local s = ManualSecond()
		local W, H = ns.screen[1], ns.screen[2]
		return { x = (DB().side == "LEFT") and s.w or 0, y = 0, w = W - s.w, h = H }
	end
end

-- 2. Monitor: größter Nicht-Hauptmonitor aus den Monitordaten, sonst aus den Handeinstellungen
function Layout.GetSecondRect()
	local data = Layout.Active()
	if not data then
		return ManualSecond()
	end
	local best
	for _, r in ipairs(data.monitors) do
		if r ~= data.main and (not best or r.w * r.h > best.w * best.h) then
			best = r
		end
	end
	return best
end

-- Teile des Fensters, die auf einem Monitor zu sehen sind (Fensterpixel)
function Layout.GetVisible()
	local data = Layout.Active()
	if data then
		return data.monitors
	end
	if DB().enabled then
		return { Layout.GetMainRect(), ManualSecond() }
	end
	return { Layout.Full() }
end

-- Viewport-Versätze { links, rechts, oben, unten } für ein Rechteck
function Layout.ViewportFor(r)
	local W, H = ns.screen[1], ns.screen[2]
	return { r.x, W - r.x - r.w, r.y, H - r.y - r.h }
end

function Layout.ToAbs(r)
	local ux, uy = ns.UnitsPerPixel()
	local H = ns.screen[2]
	return { l = r.x * ux, r = (r.x + r.w) * ux, t = (H - r.y) * uy, b = (H - r.y - r.h) * uy }
end

function Layout.GetVisibleAbs()
	local out = {}
	for i, r in ipairs(Layout.GetVisible()) do
		out[i] = Layout.ToAbs(r)
	end
	return out
end

---------------------------------------------------------------------------
-- UIParent auf den Hauptmonitor begrenzen
-- Blizzards Oberfläche hängt fast vollständig an UIParent (Ecken, Mitte). Liegt UIParent
-- nur über dem Hauptmonitor, landet sie dort – auch bei unterschiedlich großen Monitoren,
-- wo Teile des Fensters auf keinem Monitor zu sehen sind.
---------------------------------------------------------------------------

-- Nur auf Knopfdruck (Optionen, Seite „Monitore“): verschiebt damit alle Blizzard-Rahmen, die an
-- UIParent hängen. Gilt bis zum Zurücksetzen, zum Abschalten des Zwei-Monitor-Modus, einem Profil
-- ohne Zwei-Monitor-Modus oder /reload. Solange hält ReapplyUI die gewählte Begrenzung aufrecht.
local constrained = false
local constrainedRect   -- zuletzt angewendeter Bereich (Pixel), solange constrained

-- rect = Bereich in Pixeln oder nil = ganzes Fenster. Liefert true, wenn angewendet.
local function SetUIParent(rect)
	if InCombatLockdown() then
		ns.Print(L["%s is protected – cannot be moved in combat."]:format("UIParent"))
		return false
	end
	-- ns.FrameSetPoint = Methode der Widget-Klasse (ohne Umweg über überschriebene Methoden)
	local W, H = ns.screen[1], ns.screen[2]
	local ux, uy = ns.UnitsPerPixel()
	local s = UIParent:GetScale()
	ns.FrameClearAllPoints(UIParent)
	if rect then
		-- UIParent hat keinen Elternrahmen: Versätze in eigenen Einheiten, bezogen auf das Fenster
		ns.FrameSetPoint(UIParent, "TOPLEFT", rect.x * ux / s, -rect.y * uy / s)
		ns.FrameSetPoint(UIParent, "BOTTOMRIGHT", -(W - rect.x - rect.w) * ux / s, (H - rect.y - rect.h) * uy / s)
	else
		ns.FrameSetPoint(UIParent, "TOPLEFT", 0, 0)
		ns.FrameSetPoint(UIParent, "BOTTOMRIGHT", 0, 0)
	end
	constrained = rect ~= nil
	constrainedRect = rect
	Visible.Notify()
	return true
end

-- Wendet die ausdrücklich gewählte Begrenzung erneut an: Blizzard setzt UIParent bei jedem
-- PLAYER_ENTERING_WORLD zurück (UpdateUIParentPosition, UIParentUtil.lua), und die Versätze in
-- UIParent-Einheiten hängen von Fenstergröße und Skalierung ab (ns.ApplyGeometry). Im Kampf erst
-- danach. Keine Rekursion: SetUIParent setzt über ns.FrameSetPoint, nicht über Blizzards Funktion.
local function ReapplyUI()
	if not constrained or qnCore.DeferInCombat(ReapplyUI) then
		return
	end
	-- Bereich neu ermitteln (Fenstergröße kann sich geändert haben), sonst der gemerkte
	local rect = DB().enabled and Layout.GetMainRect()
	if not rect or IsFull(rect) then
		rect = constrainedRect
	end
	SetUIParent(rect)
end
Layout.ReapplyUI = ReapplyUI

-- Knopf „Oberfläche auf den Hauptmonitor“ (Seite „Monitore“)
function Layout.ConstrainUI()
	local rect = DB().enabled and Layout.GetMainRect()
	if not rect or IsFull(rect) then
		ns.Print(L["Only in dual monitor mode, when the game window spans several monitors."])
		return
	end
	if SetUIParent(rect) then
		ns.Print(L["Blizzard interface on the main monitor (until reset or /reload)."])
	end
end

-- Knopf „Zurücksetzen“ bzw. Zwei-Monitor-Modus aus: wieder über das ganze Fenster
function Layout.ReleaseUI()
	if constrained then
		SetUIParent(nil)
	end
end

function Layout.IsUIConstrained()
	return constrained
end

---------------------------------------------------------------------------
-- Sichtbarkeit von Rahmen (Rechnen und Verschieben: qnCore.Visible)
---------------------------------------------------------------------------

local function FrameName(f)
	return f:GetName() or f:GetDebugName()
end

-- Herkunft: Blizzard, wenn der globale Name von Blizzards (sicherem) Code angelegt wurde.
local function Source(f)
	local name = f:GetName()
	if name and _G[name] == f and issecurevariable then
		local secure, addon = issecurevariable(_G, name)
		if secure then
			return "Blizzard", true
		end
		return addon or "Addon", false
	end
	return L["unnamed"], false
end

-- Prüft alle sichtbaren Oberflächenelemente (Kinder von UIParent) und liefert die, die ganz
-- oder teilweise außerhalb der Monitore liegen, Blizzard zuerst. Verschiebt nichts.
function Layout.CheckFrames()
	local rects = Layout.GetVisibleAbs()
	local ui = Visible.FrameAbs(UIParent)
	local result = {}
	for _, f in ipairs({ UIParent:GetChildren() }) do
		if not f:IsForbidden() and not f.qnViewPortIgnore
			and f:IsVisible() and f:GetAlpha() > 0.05 then
			local a = Visible.FrameAbs(f)
			local fullscreen = a and ui and math.abs(a.l - ui.l) < 2 and math.abs(a.r - ui.r) < 2
				and math.abs(a.t - ui.t) < 2 and math.abs(a.b - ui.b) < 2
			if a and not fullscreen and a.r - a.l > 4 and a.t - a.b > 4 then
				local visible = Visible.VisibleFraction(a, rects)
				if visible <= 0.9999 then
					local source, blizzard = Source(f)
					result[#result + 1] = {
						frame = f, name = FrameName(f), source = source, blizzard = blizzard,
						visible = visible, editMode = f.system ~= nil, protected = f:IsProtected(),
					}
				end
			end
		end
	end
	table.sort(result, function(x, y)
		if x.blizzard ~= y.blizzard then
			return x.blizzard
		end
		return x.name < y.name
	end)
	return result
end

-- Verschiebt EIN Element in den sichtbaren Bereich (Knopf in der Liste der Optionen).
-- Chatfenster: Lage über Blizzards Funktion speichern, sonst setzt der Chat sie beim Laden zurück.
function Layout.MoveFrame(f)
	local name = FrameName(f)
	local moved = Visible.MoveAndReport(f, name, ns.Print)
	if moved then
		if name:match("^ChatFrame%d+$") then
			FCF_SavePositionAndDimensions(f)
		end
		if f.system ~= nil then
			ns.Print(L["Edit Mode frame: lasts until /reload or until the layout is reloaded. To keep it: move it in Edit Mode."])
		end
	end
	return moved
end

---------------------------------------------------------------------------
-- Tooltips am Monitorrand (Titan-Plugins in Titan.lua, Taschenplätze in SecondScreen.lua)
-- Blizzard und Titan wählen die Seite eines Tooltips nach GetScreenWidth() bzw. UIParent, also
-- nach dem ganzen Spielfenster. Am Rand eines Monitors ragt der Tooltip dann in einen Teil des
-- Fensters, der auf keinem Monitor zu sehen ist, oder auf den Nachbarmonitor.
---------------------------------------------------------------------------

-- Monitor (abs-Rechteck), auf dem die Mitte von frame liegt; nil = auf keinem
function Layout.MonitorAt(frame)
	local a = Visible.FrameAbs(frame)
	if not a then
		return nil
	end
	local x, y = (a.l + a.r) / 2, (a.t + a.b) / 2
	for _, r in ipairs(Layout.GetVisibleAbs()) do
		if x >= r.l and x <= r.r and y >= r.b and y <= r.t then
			return r
		end
	end
end

-- Legt tip neu an owner, wenn er dort verankert ist und über den Monitor von owner hinausragt.
-- Die bisherige Seite bleibt, wenn sie passt; sonst die andere Seite, und was dann noch
-- übersteht, wird hineingeschoben. Passt er, bleibt der Anker unverändert (Titans Steuerfenster
-- hängen an der Mitte der Plugin-Kante, z. B. TOPLEFT an BOTTOM – neu an einer Ecke sprängen sie).
function Layout.FitToMonitor(tip, owner)
	if not (tip and owner and tip:IsShown()) then
		return
	end
	local point, rel, relPoint, ox, oy = tip:GetPoint(1)
	if rel ~= owner or type(point) ~= "string" then
		return
	end
	local area, b = Layout.MonitorAt(owner), Visible.FrameAbs(owner)
	local s = tip:GetEffectiveScale()
	local w, h = (tip:GetWidth() or 0) * s, (tip:GetHeight() or 0) * s
	if not (area and b and w > 0 and h > 0) then
		return
	end

	-- Lage mit dem bisherigen Anker; ragt nichts hinaus, nichts ändern
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

	-- senkrecht: TOP = unter owner, BOTTOM = darüber
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
	tip:SetPoint(v .. hz, owner, (v == "TOP" and "BOTTOM" or "TOP") .. hz, dx / s, dy / s)
end

-- Seite, auf der die Vergleichs-Tooltips an tip hängen: true = rechts, false = links, nil = unbekannt.
-- Blizzard: RIGHT an LEFT bzw. LEFT an RIGHT von tip; hier: TOPRIGHT an TOPLEFT bzw. TOPLEFT an TOPRIGHT.
local function CompareSide(tip, shown)
	for _, t in ipairs(shown) do
		for i = 1, t:GetNumPoints() do
			local _, rel, relPoint = t:GetPoint(i)
			if rel == tip and type(relPoint) == "string" then
				if relPoint:find("RIGHT$") then
					return true
				elseif relPoint:find("LEFT$") then
					return false
				end
			end
		end
	end
end

-- Vergleichs-Tooltips (tip.shoppingTooltips) neben tip auf dessen Monitor.
-- Blizzard (TooltipComparisonManager:AnchorShoppingTooltips) wählt die Seite nach GetScreenWidth()
-- und hängt die Tooltips mit TOP an tip. Passt Blizzards Seite auf den Monitor, bleibt sie – sonst
-- wechselten sich Blizzards und diese Wahl bei jeder Auffrischung ab (Flackern). Sonst die Seite
-- mit genug Platz, notfalls die mit mehr Platz; ragen sie unten hinaus, werden sie hochgeschoben.
function Layout.FitCompareToMonitor(tip)
	local list = tip and tip.shoppingTooltips
	local primary, secondary = list and list[1], list and list[2]
	if not (primary and primary:IsShown()) then
		return
	end
	local area, g = Layout.MonitorAt(tip), Visible.FrameAbs(tip)
	if not (area and g) then
		return
	end
	local shown = { primary }
	if secondary and secondary:IsShown() then
		shown[2] = secondary
	end
	local width, height = 0, 0
	for _, t in ipairs(shown) do
		local s = t:GetEffectiveScale()
		width = width + (t:GetWidth() or 0) * s
		height = math.max(height, (t:GetHeight() or 0) * s)
	end
	if width <= 0 then
		return
	end
	local roomRight, roomLeft = area.r - g.r, g.l - area.l
	local current = CompareSide(tip, shown)
	local right
	if current == true and roomRight >= width or current == false and roomLeft >= width then
		right = current
	elseif roomRight >= width then
		right = true
	elseif roomLeft >= width then
		right = false
	else
		right = roomRight >= roomLeft
	end
	local dy = 0
	if g.t - height < area.b then
		dy = math.min(area.b - (g.t - height), area.t - g.t)
	end
	if right == current and dy == 0 then
		return   -- Blizzards Lage passt
	end

	-- first hängt an tip, der zweite daneben (Reihenfolge wie bei Blizzard)
	local s = primary:GetEffectiveScale()
	primary:ClearAllPoints()
	if secondary then
		secondary:ClearAllPoints()
	end
	if #shown == 1 then
		primary:SetPoint(right and "TOPLEFT" or "TOPRIGHT", tip, right and "TOPRIGHT" or "TOPLEFT", 0, dy / s)
	elseif right then
		secondary:SetPoint("TOPLEFT", tip, "TOPRIGHT", 0, dy / secondary:GetEffectiveScale())
		primary:SetPoint("TOPLEFT", secondary, "TOPRIGHT")
	else
		primary:SetPoint("TOPRIGHT", tip, "TOPLEFT", 0, dy / s)
		secondary:SetPoint("TOPRIGHT", primary, "TOPLEFT")
	end
end

---------------------------------------------------------------------------
-- Anordnung übernehmen (Start, Fenstergröße geändert)
---------------------------------------------------------------------------

local function Key(data)
	local parts = { ns.screen[1] .. "x" .. ns.screen[2] }
	for _, m in ipairs(data.monitors) do
		parts[#parts + 1] = ("%d,%d,%d,%d%s"):format(m.x, m.y, m.w, m.h, m == data.main and "*" or "")
	end
	return table.concat(parts, ";")
end

-- Neue Monitoranordnung: einmalig die 3D-Welt (Viewport) auf den Hauptmonitor legen.
-- Schaltet weder den Zwei-Monitor-Modus ein noch verschiebt es Oberflächenelemente.
-- Spätere Änderungen des Spielers am Viewport bleiben, bis sich die Anordnung ändert.
function Layout.Refresh()
	local data = Layout.Active()
	if data and #data.monitors > 1 and not IsFull(data.main) then
		local key = Key(data)
		local g = ns.global
		if key ~= g.layoutKey then
			-- kontoweit gespeichert: die Übernahme gilt einmal je Anordnung, nicht einmal je Profil
			g.layoutKey = key
			ns.EndKeep()
			ns.ApplyViewport(Layout.ViewportFor(data.main))
			ns.Print(L["Monitor layout applied: %d monitors, 3D world on the main monitor (%d × %d)."]:format(
				#data.monitors, data.main.w, data.main.h))
		end
	end
	Visible.Notify()
end

---------------------------------------------------------------------------
-- Ereignisse und Hooks
---------------------------------------------------------------------------

-- Start (aus Core.lua nach ADDON_LOADED); angewendet wird danach über ns.ApplyGeometry.
-- Ab hier gilt für qnCore.Visible der Bereich auf den Monitoren.
function Layout.Init()
	Visible.SetAreaProvider(Layout.GetVisibleAbs)
	ns.events.Register("PLAYER_ENTERING_WORLD", Visible.Notify)
	-- Blizzard legt UIParent hier wieder über das ganze Fenster (oben nur um Notch/Debug-Leisten versetzt)
	hooksecurefunc("UpdateUIParentPosition", ReapplyUI)
end

---------------------------------------------------------------------------
-- Slash: /qnvp monitors | check
---------------------------------------------------------------------------

function Layout.Describe()
	local lines = {}
	local data = Layout.GetData()
	if not data then
		lines[1] = "|cffff8080" .. (problem or L["No monitor data."]) .. "|r"
		return lines
	end
	for _, m in ipairs(data.monitors) do
		lines[#lines + 1] = ("%d: %s  x %d, y %d, %d × %d%s%s"):format(m.index, m.name or m.device or "?",
			m.x, m.y, m.w, m.h, m == data.main and ("  |cff80ff80%s|r"):format(L["Main monitor"]) or "",
			m.selected == false and ("  (%s)"):format(L["not selected, but shows part of the window"]) or "")
	end
	if not DB().useMonitorData then
		lines[#lines + 1] = "|cffffff80" .. L["Monitor data is turned off (options, Second Monitor)."] .. "|r"
	end
	return lines
end

function Layout.Slash(cmd)
	if cmd == "monitors" or cmd == "monitore" then
		ns.Print((constrained and L["Game window %d × %d, interface on the main monitor:"]
			or L["Game window %d × %d, interface across the whole window:"]):format(ns.screen[1], ns.screen[2]))
		for _, line in ipairs(Layout.Describe()) do
			ns.Print(line)
		end
		return true
	elseif cmd == "check" then
		Layout.Report()
		return true
	end
	return false
end

-- Kurzbeschreibung eines Prüfergebnisses
function Layout.DescribeEntry(e)
	local where = e.visible < 0.0001 and ("|cffff6060%s|r"):format(L["fully outside"])
		or L["|cffffd060partly outside|r (%d %% visible)"]:format(math.floor(e.visible * 100))
	local notes = { e.source }
	if e.editMode then notes[#notes + 1] = HUD_EDIT_MODE_MENU end
	if e.protected then notes[#notes + 1] = L["protected"] end
	return where, table.concat(notes, ", ")
end

-- Meldet Rahmen außerhalb der Monitore im Chat (/qnvp check). Verschiebt nichts.
function Layout.Report()
	local list = Layout.CheckFrames()
	if #list == 0 then
		ns.Print(L["All visible interface elements are on a monitor."])
	end
	for _, e in ipairs(list) do
		local where, notes = Layout.DescribeEntry(e)
		ns.Print(("|cffffff80%s|r – %s – %s"):format(e.name, where, notes))
	end
	if #list > 0 then
		ns.Print(L["Move them one at a time: Options → qnViewPort → Monitors."])
	end
end
