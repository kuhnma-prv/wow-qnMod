-- qnBuffMod: ein Fenster. Die Symbolfläche (frame) trägt die Einträge und ist an ihrer Ankerecke
-- an der nächsten Ecke von UIParent verankert; der Hintergrund (bg) umschließt sie mit Rand.
-- Ein abgeschaltetes Fenster hat keine Rahmen (frame = nil); freie Rahmensätze werden wiederverwendet.

local _, ns = ...
local lib = qnCore
local L = ns.L
local E = ns.enum

local Window = {}
Window.__index = Window
ns.Window = Window

local BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local INSET = 4
local GROW_LEFT = { [2] = true, [4] = true, [7] = true, [8] = true }
local GROW_UP = { [3] = true, [4] = true, [6] = true, [8] = true }

local pool = {}          -- freie Rahmensätze (nie mit Sichtbarkeitstreiber)
local retired = {}       -- abgegebene Rahmensätze mit Treiber: erst nach dem Kampf in den Pool
local lookVersion = 0

function Window.New(id)
	return setmetatable({ id = id, items = {} }, Window)
end

-- gespeicherte (dünne) Einstellungstabelle
function Window:Settings()
	local windows = ns.db.windows
	local t = windows[self.id]
	if type(t) ~= "table" then
		t = {}
		windows[self.id] = t
	end
	return t
end

function Window:Label()
	return L["Fenster %d"]:format(self.id)
end

---------------------------------------------------------------------------
-- Darstellung (aus den wirksamen Einstellungen)
---------------------------------------------------------------------------

local function ComputeLook(o)
	lookVersion = lookVersion + 1
	local style = o.buttonStyle
	local layout = o.layoutType
	local growLeft, growUp = GROW_LEFT[layout] or false, GROW_UP[layout] or false
	local look = {
		version = lookVersion,
		style = style,
		layout = layout,
		columns = layout <= 4,
		growLeft = growLeft,
		growUp = growUp,
		point = (growUp and "BOTTOM" or "TOP") .. (growLeft and "RIGHT" or "LEFT"),
		font = o.fontSize,
	}
	if style == E.style.ICON then
		look.size = o.buffSize2
		look.bar = 0
		look.iconRight = false
		look.fullIcon = o.normalIconBorder2
		look.colorIcons = o.colorCodeIcons2
		look.showTimers = o.showTimers2
		look.timeFormat = o.durationFormat2
		look.showDays = o.showDays2
		look.dataSide = o.dataSide2
		look.dataSpacing = o.spacingFromIcon2
		look.barOutside = false
	else
		look.size = o.buffSize1
		look.bar = o.detailWidth1 >= 1 and o.detailWidth1 or 0
		-- Standard: Symbol auf der Seite der Ankerecke (rechts bei Layout 2, 4, 7, 8)
		local defaultRight = growLeft
		if o.rightAlign1 == E.side.DEFAULT then
			look.iconRight = defaultRight
		else
			look.iconRight = o.rightAlign1 == E.side.RIGHT
		end
		look.fullIcon = o.normalIconBorder1
		look.colorIcons = o.colorCodeIcons1
		look.barShown = o.colorBuffs1
		look.colorBackground = o.colorCodeBackground1
		look.showNames = o.showNames1
		look.colorNames = o.colorCodeDebuffs1
		look.nameJustWithTime = o.nameJustifyWithTime1
		look.nameJustNoTime = o.nameJustifyNoTime1
		look.showTimers = o.showTimers1
		look.timeFormat = o.durationFormat1
		look.showDays = o.showDays1
		look.timeAt = o.durationLocation1
		look.timeJustNoName = o.timeJustifyNoName1
		look.timerBar = o.showBuffTimer1
		look.timerBackground = o.showTimerBackground1
		look.padLeft = o.spacingOnLeft1
		look.padRight = o.spacingOnRight1
		-- Leiste außerhalb der Symbolfläche: Spalten ohne Begrenzung oder Symbol auf der anderen Seite
		look.barOutside = look.bar > 0 and ((look.columns and o.maxWraps == 0) or look.iconRight ~= defaultRight)
	end
	look.cellW = look.size + look.bar
	return look
end

---------------------------------------------------------------------------
-- Rahmen
---------------------------------------------------------------------------

local function NewFrames()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetMovable(true)
	f:SetSize(1, 1)
	local bg = CreateFrame("Frame", nil, f, "BackdropTemplate")
	bg:SetFrameLevel(f:GetFrameLevel())
	bg:SetBackdrop(BACKDROP)
	local title = bg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("BOTTOM", bg, "TOP", 0, 2)
	title:Hide()
	return { frame = f, bg = bg, title = title, entries = {} }
end

-- Abgegebene Rahmensätze mit Treiber: Treiber abbauen (geschützt), verbergen, in den Pool
local function ReleaseRetired()
	for _, set in ipairs(retired) do
		UnregisterStateDriver(set.frame, "visibility")
		set.driver = nil
		set.frame:Hide()
		pool[#pool + 1] = set
	end
	wipe(retired)
end

-- Rahmensatz zurückgeben. Mit Treiber im Kampf erst danach; bis dahin kann der Treiber den Rahmen
-- wieder einblenden, deshalb unsichtbar und ohne Maus.
local function Release(set)
	if not set.driver then
		pool[#pool + 1] = set
		return
	end
	retired[#retired + 1] = set
	if lib.DeferInCombat(ReleaseRetired) then
		set.frame:SetAlpha(0)
		set.bg:EnableMouse(false)
		return
	end
	ReleaseRetired()
end

function Window:IsEnabled()
	return self.frame ~= nil
end

-- Rahmen anlegen und anzeigen (an der gespeicherten Position bzw. in der Bildschirmmitte)
function Window:Enable()
	if self.frame then
		return
	end
	local set = table.remove(pool) or NewFrames()
	self.set = set
	self.frame, self.bg, self.title, self.entries = set.frame, set.bg, set.title, set.entries
	for _, e in ipairs(self.entries) do
		e.win = self
	end
	local f = self.frame
	f:SetAlpha(1)
	f:ClearAllPoints()
	local p = self:Settings().position
	if p then
		f:SetSize(p[6] or 1, p[7] or 1)
		f:SetPoint(p[1], _G[p[2]] or UIParent, p[3], p[4], p[5])
		self.point = p[1]
		self.anchor = { p[1], p[3], p[4], p[5] }
	else
		self.point = nil
		self.center = true
	end
	f:Show()
	self:WireScripts()   -- erst nach dem Show: das erste Einblenden liest nichts neu
	self:Apply()
end

-- Rahmen freigeben; die Einstellungen bleiben unverändert
function Window:Disable()
	local f = self.frame
	if not f then
		return
	end
	f:SetScript("OnUpdate", nil)
	f:SetScript("OnShow", nil)
	self.bg:SetScript("OnMouseDown", nil)
	self.bg:SetScript("OnMouseUp", nil)
	self.bg:SetScript("OnEnter", nil)
	self.bg:SetScript("OnLeave", nil)
	for _, e in ipairs(self.entries) do
		ns.Tooltip.Hide(e)
		e:Hide()
		e.rec = nil
	end
	f:StopMovingOrSizing()
	f:Hide()
	wipe(self.items)
	local set = self.set
	set.driver, self.driver = self.driver, nil
	self.frame, self.bg, self.title, self.entries, self.set = nil, nil, nil, nil, nil
	Release(set)
end

---------------------------------------------------------------------------
-- Maus
---------------------------------------------------------------------------

function Window:StartDrag()
	if self.o.lockWindow or not self.frame then
		return
	end
	self.dragging = true
	self.frame:StartMoving()
end

function Window:StopDrag()
	if not self.dragging then
		return
	end
	self.dragging = false
	self.frame:StopMovingOrSizing()
	self:Reanchor(true)
	self:SavePosition()
end

-- Linke Taste: Alt = Fenster in den Optionen wählen, sonst ziehen
function Window:MouseDown(button)
	if button ~= "LeftButton" then
		return
	end
	if IsAltKeyDown() then
		ns.EditWindow(self.id)
	else
		self:StartDrag()
	end
end

function Window:MouseUp(button)
	if button == "LeftButton" then
		self:StopDrag()
	end
end

-- Rechtsklick: aufhebbare Stärkungszauber/Auren entfernen – nur in Fenstern für den Spieler,
-- außerhalb des Kampfes und ohne Aurensperre
function Window:Cancel(e)
	local rec = e.rec
	if not rec or rec.weapon or InCombatLockdown() or ns.Auras.Restricted() or self.unit ~= "player" then
		return false
	end
	if rec.kind ~= ns.kind.BUFF and rec.kind ~= ns.kind.AURA then
		return false
	end
	CancelUnitBuff(self.unit, rec.index, rec.filter)
	return true
end

local function KeyDown()
	return GetCVarBool("ActionButtonUseKeyDown")
end

function Window:WireEntry(e)
	local win = self
	e:SetScript("OnEnter", ns.Tooltip.ShowEntry)
	e:SetScript("OnLeave", ns.Tooltip.Hide)
	e:SetScript("OnMouseDown", function(btn, button)
		if button == "RightButton" then
			if KeyDown() then
				win:Cancel(btn)
			end
		else
			win:MouseDown(button)
		end
	end)
	e:SetScript("OnMouseUp", function(btn, button)
		if button == "RightButton" then
			if not KeyDown() and btn:IsMouseOver() then
				win:Cancel(btn)
			end
		else
			win:MouseUp(button)
		end
	end)
end

function Window:WireScripts()
	local win = self
	local f, bg = self.frame, self.bg
	f:SetScript("OnUpdate", function(_, elapsed)
		win:OnUpdate(elapsed)
	end)
	-- beim Einblenden (Sichtbarkeitstreiber) neu lesen
	f:SetScript("OnShow", function()
		ns.RefreshWindowUnit(win)
	end)
	bg:SetScript("OnMouseDown", function(_, button)
		win:MouseDown(button)
	end)
	bg:SetScript("OnMouseUp", function(_, button)
		win:MouseUp(button)
	end)
	bg:SetScript("OnEnter", function(frame)
		ns.Tooltip.ShowBackground(frame, win.id)
	end)
	bg:SetScript("OnLeave", ns.Tooltip.HideBackground)
	for _, e in ipairs(self.entries) do
		self:WireEntry(e)
	end
end

-- Maus am Hintergrund und Fenstertitel (hängen an der offenen Fensterseite der Optionen)
function Window:ApplyMouse()
	if not self.frame then
		return
	end
	local pageOpen = ns.WindowPageOpen()
	self.bg:EnableMouse(pageOpen or not self.o.lockWindow)
	if pageOpen then
		self.title:SetText(self:Label())
		if ns.SelectedID() == self.id then
			self.title:SetTextColor(1, 1, 1)
		else
			self.title:SetTextColor(1, 0.82, 0)
		end
		self.title:Show()
	else
		self.title:Hide()
	end
end

---------------------------------------------------------------------------
-- Lage
---------------------------------------------------------------------------

-- An der Ankerecke point (Vorgabe: die des Layouts) an der nächsten Ecke von UIParent verankern.
-- clampIn: liegt der Ankerpunkt außerhalb von UIParent, wird er hereingeholt.
function Window:Reanchor(clampIn, point)
	local f = self.frame
	point = point or self.look.point
	local rel = lib.NearestCorner(f, point)
	local x, y = lib.PointOffset(f, point, rel)
	if not x then
		return
	end
	if clampIn then
		local w, h = UIParent:GetWidth(), UIParent:GetHeight()
		local fx, fy = lib.AnchorFactors(rel)
		local px = math.max(0, math.min(w, x + fx * w))
		local py = math.max(0, math.min(h, y + fy * h))
		x, y = px - fx * w, py - fy * h
	end
	f:ClearAllPoints()
	f:SetPoint(point, UIParent, rel, x, y)
	self.point = point
	self.anchor = { point, rel, x, y }
end

function Window:SavePosition()
	local a = self.anchor
	if not a or not self.frame then
		return
	end
	self:Settings().position = { a[1], "UIParent", a[2], a[3], a[4], self.frame:GetWidth(), self.frame:GetHeight() }
end

-- Bildschirmmitte
function Window:ResetPosition()
	if not self.frame then
		return
	end
	self.frame:ClearAllPoints()
	self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	self:Reanchor(false)
	self:SavePosition()
end

-- In den sichtbaren Bereich holen (samt Hintergrund und Rand); Meldung von qnCore
function Window:BringIntoView()
	if not self.frame then
		return false
	end
	local moved = lib.Visible.MoveAndReport(self.frame, self:Label(), ns.Print, { insets = true })
	if moved then
		self:Reanchor(false)
		self:SavePosition()
	end
	return moved
end

---------------------------------------------------------------------------
-- Einstellungen anwenden
---------------------------------------------------------------------------

function Window:ShownUnit()
	local o = self.o
	if o.unitType == E.unit.PLAYER then
		if o.vehicleBuffs and ns.inVehicle then
			return "vehicle"
		end
		return "player"
	end
	return ns.UNITS[o.unitType] or "player"
end

-- Hintergrundfarbe, Rand, Bildschirmhaltung
function Window:ApplyBackground()
	if not self.frame then
		return
	end
	local o, bg = self.o, self.bg
	local c = o.useCustomBackgroundColor and o.windowBackgroundColor or ns.db.backgroundColor
	if not ns.ValidColor(c) then
		c = ns.defaults.backgroundColor
	end
	if o.showBackground then
		bg:SetBackdropColor(c[1], c[2], c[3], c[4])
	else
		bg:SetBackdropColor(0, 0, 0, 0)
	end
	bg:SetBackdropBorderColor(1, 1, 1, o.showBorder and 1 or 0)
	self.frame:SetClampedToScreen(o.clampWindow)
end

-- Sichtbarkeitstreiber (geschützt: im Kampf erst danach)
function Window:ApplyVisibility()
	local f = self.frame
	if not f then
		return
	end
	self.applyVisibility = self.applyVisibility or function()
		self:ApplyVisibility()
	end
	if lib.DeferInCombat(self.applyVisibility) then
		return
	end
	local cond = ns.WindowCondition(self.o)
	if cond then
		RegisterStateDriver(f, "visibility", cond)
		self.driver = cond
	else
		if self.driver then
			UnregisterStateDriver(f, "visibility")
		end
		self.driver = nil
		f:Show()
	end
end

-- Alle Einstellungen des Fensters anwenden
function Window:Apply()
	if not self.frame then
		return
	end
	self.o = ns.ResolveOptions(self:Settings())
	local oldPoint = self.point
	self.look = ComputeLook(self.o)
	self.unit = self:ShownUnit()
	ns.UpdateWatched()
	self:ApplyBackground()
	self:ApplyMouse()
	self:ApplyVisibility()
	-- neue Ankerecke: erst an ihr verankern, dann wächst das Fenster von dort (kein Sprung)
	if oldPoint and oldPoint ~= self.look.point then
		self:Reanchor(false, self.look.point)
	end
	self:Arrange()
	if self.center then
		self.center = nil
		self.frame:ClearAllPoints()
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	self:Reanchor(true)
	self:SavePosition()
end

-- Neue Einheit (Fahrzeug) übernehmen; true, wenn sie sich geändert hat
function Window:UpdateUnit()
	if not self.frame then
		return false
	end
	local unit = self:ShownUnit()
	if unit == self.unit then
		return false
	end
	self.unit = unit
	return true
end

---------------------------------------------------------------------------
-- Einträge auswählen und sortieren
---------------------------------------------------------------------------

local HUGE = math.huge

local function ExpiryKey(rec)
	if ns.Auras.HasExpiry(rec) and not rec.outOfRange then
		return rec.expiration
	end
	return HUGE
end

local COMPARE = {
	[E.sort.NAME] = function(a, b)
		if a.name == b.name then
			return 0
		end
		return a.name < b.name and -1 or 1
	end,
	[E.sort.TIME] = function(a, b)
		local x, y = ExpiryKey(a), ExpiryKey(b)
		if x == y then
			return 0
		end
		return x < y and -1 or 1
	end,
	[E.sort.INDEX] = function(a, b)
		if a.index == b.index then
			return 0
		end
		return a.index < b.index and -1 or 1
	end,
}

local SORTS = { E.sort.NAME, E.sort.TIME, E.sort.INDEX }

-- Hilfstabellen und Sortierstand, je Arrange wiederverwendet (Sortieren läuft ohne Unterbrechung)
local slotOf, seq, used, sorts = {}, {}, {}, {}
local sortO, sortOrder, sortReverse

-- Gruppierung c ("F" = Fensterplatz, "E" = eigene, sonst ohne Ablauf) von a und b: -1, 0, 1
local function Group(c, a, b)
	local o = sortO
	if c == "F" then
		local x, y = slotOf[a], slotOf[b]
		return x == y and 0 or (x < y and -1 or 1)
	elseif c == "E" then
		if o.separateOwn == E.own.WITH then
			return 0
		end
		local ownA, ownB = a.caster == "player", b.caster == "player"
		if ownA == ownB then
			return 0
		end
		return (ownA == (o.separateOwn == E.own.FIRST)) and -1 or 1
	else
		if o.separateZero ~= E.zero.FIRST and o.separateZero ~= E.zero.LAST then
			return 0
		end
		local zeroA, zeroB = ExpiryKey(a) == HUGE, ExpiryKey(b) == HUGE
		if zeroA == zeroB then
			return 0
		end
		return (zeroA == (o.separateZero == E.zero.FIRST)) and -1 or 1
	end
end

-- Gruppierung (nicht umgekehrt), dann Haupt- und Nachsortierung (umkehrbar), sonst Lesereihenfolge
local function Before(a, b)
	for _, c in ipairs(sortOrder) do
		local r = Group(c, a, b)
		if r ~= 0 then
			return r < 0
		end
	end
	for _, m in ipairs(sorts) do
		local r = COMPARE[m](a, b)
		if r ~= 0 then
			if sortReverse then
				return r > 0
			end
			return r < 0
		end
	end
	return seq[a] < seq[b]
end

-- Einträge des Fensters in Anzeigereihenfolge (ohne Begrenzung durch maxWraps); füllt self.items
function Window:CollectItems()
	local o = self.o
	local unit = self.unit
	local items = wipe(self.items)
	wipe(slotOf)
	wipe(seq)
	wipe(used)
	local weaponSlot
	for k = 1, 5 do
		local group = o["sortSeq" .. k]
		if group == E.group.WEAPONS then
			weaponSlot = weaponSlot or k
		elseif ns.FILTERS[group] then
			for _, rec in ipairs(ns.Auras.List(unit, group)) do
				if not used[rec.key] then
					local zero = ExpiryKey(rec) == HUGE
					if not ((o.separateZero == E.zero.HIDE and zero) or (o.separateZero == E.zero.ONLY and not zero)) then
						used[rec.key] = true
						items[#items + 1] = rec
						slotOf[rec] = k
						seq[rec] = #items
					end
				end
			end
		end
	end

	local main = o.sortMethod
	wipe(sorts)
	sorts[1] = main
	for _, m in ipairs(SORTS) do
		if m ~= main then
			sorts[#sorts + 1] = m
		end
	end
	sortO, sortOrder, sortReverse = o, ns.GROUP_ORDER[o.groupByPriority], o.sortDirection
	table.sort(items, Before)
	sortO = nil

	-- Waffenverzauberungen als Block vor die erste Gruppe hinter dem Waffenplatz (nur beim Spieler)
	if weaponSlot and unit == "player" then
		local weapons = ns.Weapons.List()
		if #weapons > 0 then
			local at = #items + 1
			for i, rec in ipairs(items) do
				if slotOf[rec] > weaponSlot then
					at = i
					break
				end
			end
			for i, rec in ipairs(weapons) do
				table.insert(items, at + i - 1, rec)
			end
		end
	end
	return items
end

---------------------------------------------------------------------------
-- Raster
---------------------------------------------------------------------------

-- Einträge neu auswählen, anordnen und zeichnen
function Window:Arrange()
	local f = self.frame
	if not f then
		return
	end
	local o, look = self.o, self.look
	local items = self:CollectItems()
	local along = o.wrapAfter
	local limit = o.maxWraps > 0 and along * o.maxWraps or nil
	if limit and #items > limit then
		for i = #items, limit + 1, -1 do
			items[i] = nil
		end
	end
	self.items = items
	local n = #items
	local wraps = o.maxWraps > 0 and o.maxWraps or math.max(1, math.ceil(n / along))

	-- Raster: Spalten (Layout 1–4) oder Zeilen (5–8)
	local nH, nV, hGap, vGap
	if look.columns then
		nH, nV, hGap, vGap = wraps, along, o.wrapSpacing, o.buffSpacing
	else
		nH, nV, hGap, vGap = along, wraps, o.buffSpacing, o.wrapSpacing
	end
	local cellW, cellH = look.cellW, look.size
	local width = nH * cellW + (nH - 1) * hGap
	local height = nV * cellH + (nV - 1) * vGap
	-- Leiste außerhalb: gehört nicht zur Symbolfläche, verbreitert den Hintergrund
	local barLeft, barRight, shift = 0, 0, 0
	if look.barOutside then
		width = width - look.bar
		if look.iconRight then
			barLeft, shift = look.bar, look.bar
		else
			barRight = look.bar
		end
	end

	local now = GetTime()
	local entries = self.entries
	for i, rec in ipairs(items) do
		local e = entries[i]
		if not e then
			e = ns.Entry.New(self, f)
			entries[i] = e
			self:WireEntry(e)
		end
		if e.lookVersion ~= look.version then
			ns.Entry.Setup(e, look)
		end
		local line, pos = math.floor((i - 1) / along), (i - 1) % along
		local h, v
		if look.columns then
			h, v = line, pos
		else
			h, v = pos, line
		end
		if look.growLeft then
			h = nH - 1 - h
		end
		if look.growUp then
			v = nV - 1 - v
		end
		local x, y = h * (cellW + hGap) - shift, -(v * (cellH + vGap))
		e:ClearAllPoints()
		e:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
		e.x, e.y = x, y
		ns.Entry.Paint(e, rec, look, now)
		e:Show()
	end
	for i = n + 1, #entries do
		local e = entries[i]
		if e.rec and GameTooltip:IsOwned(e) then
			ns.Tooltip.Hide(e)
		end
		e:Hide()
		e.rec = nil
	end
	f:SetSize(width, height)

	-- Hintergrund: 4 px plus Randabstände plus ggf. Leiste
	local left = INSET + o.userEdgeLeft + barLeft
	local right = INSET + o.userEdgeRight + barRight
	local top = INSET + o.userEdgeTop
	local bottom = INSET + o.userEdgeBottom
	local edges = self.edges or {}
	self.edges = edges
	edges.left, edges.right, edges.top, edges.bottom = left, right, top, bottom
	edges.barLeft, edges.barRight = barLeft, barRight
	self.bg:ClearAllPoints()
	self.bg:SetPoint("TOPLEFT", f, "TOPLEFT", -left, top)
	self.bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", right, -bottom)
	f:SetClampRectInsets(-left, right, top, -bottom)
end

-- Einträge neu zeichnen, ohne neu anzuordnen (Farben, Texte, Waffen-Takt)
function Window:Refresh()
	if not self.frame then
		return
	end
	local now = GetTime()
	for i, rec in ipairs(self.items) do
		-- Waffen werden bei jedem Lesen neu erzeugt: den aktuellen Stand desselben Platzes zeichnen
		if rec.weapon and ns.Weapons.slots[rec.slot] then
			rec = ns.Weapons.slots[rec.slot]
			self.items[i] = rec
		end
		local e = self.entries[i]
		if e then
			ns.Entry.Paint(e, rec, self.look, now)
		end
	end
end

-- Restzeiten und Blinken (nur für angezeigte Einträge; läuft nur, solange das Fenster sichtbar ist)
function Window:OnUpdate()
	local now = GetTime()
	local pulse = ns.Pulse(now)
	for i = 1, #self.items do
		local e = self.entries[i]
		if e and e.rec then
			if e.nextUpdate and now >= e.nextUpdate then
				ns.Entry.UpdateTime(e, now)
			elseif e.flashing then
				e.icon:SetAlpha(pulse)
			end
		end
	end
end
