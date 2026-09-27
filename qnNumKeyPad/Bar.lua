-- qnNumKeyPad: Leiste, Tasten, Tastenbelegung, Sichtbarkeit, Haltungswechsel.
--
-- Aufbau: ein sicherer Kopf-Rahmen
-- (SecureHandlerStateTemplate) mit Blizzards ActionBarButtonTemplate-Tasten.
-- Sichtbarkeit und Haltungswechsel laufen über Zustandstreiber, damit sie
-- auch im Kampf funktionieren; ebenso Tastenbelegung und Ziehsperre (sichere
-- Schnipsel am Kopf-Rahmen). Alles, was geschützte Rahmen verändert,
-- läuft über ns.Apply() und wird im Kampf aufgeschoben.

local _, ns = ...
local L = ns.L

local BUTTON_SIZE = 45
local INSET = 4

local bar, overlay, fader
local buttons = {}
local keys = {}             -- Tastenindex -> unsichtbarer Stellvertreter für die Tastenbelegung
local visibleKeys = {}      -- Tastenindex -> Taste des aktuellen Layouts
local cursorGrid = false    -- Spieler hält gerade eine Aktion am Mauszeiger
local keepPending = false   -- Ankerwechsel im Kampf: Versätze noch nicht umgerechnet

-- Versätze werden auf ganze Einheiten von UIParent gerundet gespeichert.
local function Round(v)
	return math.floor(v + 0.5)
end

---------------------------------------------------------------------------
-- Aktionsplätze
---------------------------------------------------------------------------

-- Tastengruppe: Taste 1-12 liegt auf page1, 13-24 auf page2, 25-28 auf page3.
local function Group(i)
	return (i <= 12 and 1) or (i <= 24 and 2) or 3
end

local function Slot(i)
	local page = ns.db["page" .. Group(i)]
	return (page - 1) * NUM_ACTIONBAR_BUTTONS + (i - 1) % NUM_ACTIONBAR_BUTTONS + 1
end

-- Im sicheren Umfeld: Tasten 1-12 spiegeln bei aktivem Haltungswechsel die
-- Haltungsseite (7-11) der Hauptleiste, sonst gilt der eigene Platz.
local CHILD_PAGE = [[
	local page = tonumber(message) or 0
	local index = self:GetAttribute("qn-index")
	if page > 0 and index <= 12 then
		self:SetAttribute("action", (page - 1) * 12 + index)
	else
		self:SetAttribute("action", self:GetAttribute("qn-own"))
	end
]]

-- Im sicheren Umfeld (OnDragStart jeder Taste, control = Leiste): zusätzliche Sperre gegen
-- versehentliches Herausziehen. false bricht ab; sonst läuft Blizzards Handler unverändert
-- (dort gilt weiter die Blizzard-Einstellung „Aktionsleisten sperren“).
local DRAG_LOCK = [[
	if (control:GetAttribute("qn-lockall") or (control:GetAttribute("qn-lockcombat") and PlayerInCombat()))
		and not IsModifiedClick("PICKUPACTION") then
		return false
	end
]]

-- Im sicheren Umfeld (self = Leiste): Tastenbelegung nur, solange der Ziffernblock aktiv und die
-- Leiste nicht vom Sichtbarkeitstreiber verborgen ist (statehidden; unabhängig von UIParent, also
-- auch bei ausgeblendeter Oberfläche). qn-bound verhindert Neubelegen bei jedem Treiberdurchlauf.
local BIND = [[
	local want = self:GetAttribute("qn-enabled") and not self:GetAttribute("statehidden") and true or false
	if want == self:GetAttribute("qn-bound") then
		return
	end
	self:SetAttribute("qn-bound", want)
	self:ClearBindings()
	if want then
		local shift = self:GetAttribute("qn-shift")
		for n = 1, self:GetAttribute("qn-count") or 0 do
			local key, target = self:GetAttribute("qn-key" .. n), self:GetAttribute("qn-target" .. n)
			self:SetBindingClick(false, key, target, "LeftButton")
			if shift then
				self:SetBindingClick(false, "SHIFT-" .. key, target, "LeftButton")
			end
		end
	end
]]

-- OnAttributeChanged der Leiste: der Sichtbarkeitstreiber setzt statehidden bei jedem Zeigen/Verbergen
local ON_HIDDEN = [[
	if name == "statehidden" then
]] .. BIND .. [[
	end
]]

---------------------------------------------------------------------------
-- Tastendarstellung (auch im Kampf erlaubt)
---------------------------------------------------------------------------

local function UpdateHotkey(button)
	local db = ns.db
	local hotkey = button.HotKey
	local key = visibleKeys[button.qnIndex]
	local text
	if key then
		if db.labels == 1 then
			text = key.label
		elseif db.labels == 2 then
			text = GetBindingText(key.binding, true)
		end
	end
	local size = db.fontSize > 0 and db.fontSize or button.qnFontSize
	hotkey:SetFont(button.qnFont, size, button.qnFontFlags)
	hotkey:SetHeight(db.fontSize > 0 and size + 2 or 10)
	if text and text ~= "" then
		hotkey:SetText(text)
		hotkey:Show()
	else
		hotkey:SetText(RANGE_INDICATOR)
		hotkey:Hide()
	end
end

local function UpdateLook(button)
	local db = ns.db
	button.Name:SetShown(not db.hideMacro)
	-- grüner Rahmen für ausgerüstete Gegenstände (wie ActionButton:Update)
	-- button.action setzt Blizzard schon beim Erzeugen (UpdateAction, CalculateAction liefert immer einen Platz)
	button.Border:SetShown(not db.hideBorder and C_ActionBar.IsEquippedAction(button.action))
	if db.zoom then
		button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	else
		button.icon:SetTexCoord(0, 1, 0, 1)
	end
	local showEmpty = db.showGrid or not db.locked or cursorGrid
	local hasAction = C_ActionBar.HasAction(button.action)
	button:SetAlpha((showEmpty or hasAction) and 1 or 0)
end

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------

local function CreateButton(i)
	local button = CreateFrame("CheckButton", "qnNumKeyPadButton" .. i, bar, "ActionBarButtonTemplate")
	button.qnIndex = i
	button.qnFont, button.qnFontSize, button.qnFontFlags = button.HotKey:GetFont()
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetAttribute("qn-index", i)
	button:SetAttribute("qn-own", Slot(i))
	button:SetAttribute("action", Slot(i))
	button:SetAttribute("_childupdate-page", CHILD_PAGE)

	hooksecurefunc(button, "UpdateHotkeys", UpdateHotkey)
	hooksecurefunc(button, "Update", UpdateLook)

	-- zusätzliche Sperre gegen versehentliches Herausziehen: sicher umhüllt, damit Blizzards
	-- Handler (PickupAction, SpellFlyout:Hide) auch im Kampf ungetaintet läuft
	SecureHandlerWrapScript(button, "OnDragStart", bar, DRAG_LOCK)

	-- Tastenbelegung über einen Stellvertreter: Seine Vorlage (SecureActionButton_OnClick) beachtet
	-- „Aktion beim Drücken“ (CVar ActionButtonUseKeyDown); die Taste selbst behandelt jeden Klick
	-- als Mausklick und handelt erst beim Loslassen. type=click klickt dann die Taste (einmal).
	local key = CreateFrame("Button", "qnNumKeyPadKey" .. i, button, "SecureActionButtonTemplate")
	key:EnableMouse(false)
	key:RegisterForClicks("AnyDown", "AnyUp")
	key:SetAttribute("type", "click")
	key:SetAttribute("clickbutton", button)
	keys[i] = key

	buttons[i] = button
	return button
end

-- Lage am eingestellten Anker speichern: relativ zu UIParent (liegt mit qnViewPort evtl. nicht
-- bei 0,0), in Einheiten von UIParent
local function SavePosition()
	local point = ns.db.point
	local x, y = qnCore.PointOffset(bar, point, point, true)
	if x then
		ns.store:SetValues({ x = Round(x), y = Round(y) })
	end
end

local function CreateOverlay()
	overlay = CreateFrame("Frame", nil, bar)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(bar:GetFrameLevel() + 50)
	overlay:EnableMouse(true)
	overlay:RegisterForDrag("LeftButton")

	local tex = overlay:CreateTexture(nil, "BACKGROUND")
	tex:SetAllPoints()
	tex:SetColorTexture(0, 1, 0, 0.3)

	local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOP", 0, -INSET - 2)
	text:SetText("qnNumKeyPad")

	overlay:SetScript("OnDragStart", function()
		if InCombatLockdown() then
			return
		end
		bar:StartMoving()
	end)
	overlay:SetScript("OnDragStop", function()
		bar:StopMovingOrSizing()
		if not InCombatLockdown() then
			SavePosition()   -- über ns.Apply folgt die Prüfung auf den sichtbaren Bereich
		end
	end)
	overlay:SetScript("OnMouseUp", function(_, mouse)
		if mouse == "RightButton" then
			ns.OpenOptions()
		end
	end)
	overlay:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("qnNumKeyPad")
		GameTooltip:AddLine(L["Linke Maustaste ziehen: verschieben"], 1, 1, 1)
		GameTooltip:AddLine(L["Rechtsklick: Optionen"], 1, 1, 1)
		GameTooltip:AddLine(L["/qnnkp lock: Position sperren"], 1, 1, 1)
		GameTooltip:Show()
	end)
	overlay:SetScript("OnLeave", GameTooltip_Hide)
	overlay:Hide()
end

local function CreateFader()
	fader = CreateFrame("Frame")
	local elapsed, lastOver = 0, 0
	local lastAlpha   -- zuletzt gesetzte Deckkraft; nil = beim nächsten Durchlauf setzen
	fader:SetScript("OnShow", function()
		lastAlpha = nil   -- ohne Ausblenden setzt ApplyCosmetic die Deckkraft selbst
	end)
	fader:SetScript("OnUpdate", function(_, e)
		elapsed = elapsed + e
		if elapsed < 0.05 then
			return
		end
		elapsed = 0
		local db = ns.db
		local now = GetTime()
		local over = bar:IsVisible() and (bar:IsMouseOver()
			or (SpellFlyout:IsShown() and SpellFlyout:IsMouseOver()))
		if over or cursorGrid or not db.locked then
			lastOver = now
		end
		local alpha = now - lastOver > db.fadeDelay and db.fadeAlpha or db.alpha
		if alpha ~= lastAlpha then
			lastAlpha = alpha
			bar:SetAlpha(alpha)
		end
	end)
	fader:Hide()
end

function ns.CreateBar()
	bar = CreateFrame("Frame", "qnNumKeyPadBar", UIParent, "SecureHandlerStateTemplate")
	ns.bar = bar
	bar:SetFrameStrata("MEDIUM")
	bar:SetClampedToScreen(true)
	bar:SetMovable(true)
	bar:SetDontSavePosition(true)
	bar:SetSize(BUTTON_SIZE * 4, BUTTON_SIZE * 5)
	bar:SetPoint("CENTER")
	bar:SetAttribute("_onstate-page", [[ self:ChildUpdate("page", newstate) ]])
	-- Tastenbelegung folgt der Sichtbarkeit, auch im Kampf (Fahrzeug, eigene Bedingung)
	SecureHandlerWrapScript(bar, "OnAttributeChanged", bar, ON_HIDDEN)

	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints()
	bar.bg:SetColorTexture(0, 0, 0, 0)

	for i = 1, ns.MAX_BUTTONS do
		CreateButton(i)
	end
	CreateOverlay()
	CreateFader()

	-- Option autoVisible (qnCore): nach dem Laden, bei neuer Fenstergröße und Monitoranordnung;
	-- ns.Apply prüft zusätzlich nach jeder Änderung. Verschiebt es die Leiste, folgt über
	-- SavePosition und ns.Apply noch eine (dann leere) Prüfung.
	ns.QueueVisibleCheck = qnCore.Visible.Keep(bar, function() return ns.db.autoVisible end, SavePosition)

	ns.events.Register("ACTIONBAR_SHOWGRID", function()
		cursorGrid = true
		ns.ApplyCosmetic()
	end)
	ns.events.Register("ACTIONBAR_HIDEGRID", function()
		cursorGrid = false
		ns.ApplyCosmetic()
	end)
	-- Zieh-Fläche im Kampf verbergen (hier kein ApplyCosmetic: InCombatLockdown() ist bei
	-- PLAYER_REGEN_DISABLED evtl. noch falsch); nach dem Kampf zeigt Core sie wieder.
	ns.events.Register("PLAYER_REGEN_DISABLED", function()
		overlay:Hide()
	end)
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------

local function IsKeyShown(key)
	local db = ns.db
	return key.type == "Numeric"
		or (key.type == "Enter" and db.showEnter)
		or (key.type == "Nav" and db.showNav)
		or (key.type == "Arrow" and db.showArrow)
end

local function ApplyLayout()
	local db = ns.db
	local layout = ns.GetLayout(db.layout)
	wipe(visibleKeys)

	local stepX, stepY = BUTTON_SIZE + db.padH, BUTTON_SIZE + db.padV
	local pos = {}
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for i, key in ipairs(layout.keys) do
		if IsKeyShown(key) then
			local x = (key.col - 1) * stepX
			if key.col < 1 then
				x = x - db.blockGap
			end
			local y = (key.row - 1) * stepY
			visibleKeys[i] = key
			pos[i] = { x, y }
			minX, minY = math.min(minX, x), math.min(minY, y)
			maxX, maxY = math.max(maxX, x + BUTTON_SIZE), math.max(maxY, y + BUTTON_SIZE)
		end
	end

	bar:SetSize(maxX - minX + 2 * INSET, maxY - minY + 2 * INSET)
	for i, button in ipairs(buttons) do
		button:SetAttribute("qn-own", Slot(i))
		local p = pos[i]
		if p then
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", INSET + p[1] - minX, -(INSET + p[2] - minY))
			button:Show()
		else
			button:Hide()
		end
	end
end

local function ApplyPosition()
	if keepPending then
		return   -- ns.KeepPosition rechnet nach dem Kampf erst die Versätze um
	end
	local db = ns.db
	bar:SetScale(db.scale)
	local s = bar:GetScale()
	bar:ClearAllPoints()
	bar:SetPoint(db.point, UIParent, db.point, db.x / s, db.y / s)
end

local function ApplyStance()
	if ns.db.stance then
		RegisterStateDriver(bar, "page", "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; 0")
	else
		UnregisterStateDriver(bar, "page")
		bar:SetAttribute("state-page", "0")
	end
	-- eigene Plätze können sich geändert haben, ohne dass der Zustand wechselt
	SecureHandlerExecute(bar, [[ self:ChildUpdate("page", self:GetAttribute("state-page")) ]])
end

-- Legt die Belegung als Attribute der Leiste ab; gesetzt wird sie im sicheren Umfeld (BIND), damit
-- der Sichtbarkeitstreiber sie auch im Kampf aufheben und wiederherstellen kann.
local function ApplyBindings()
	local db = ns.db
	local n = 0
	for i, key in pairs(visibleKeys) do
		n = n + 1
		bar:SetAttribute("qn-key" .. n, key.binding)
		bar:SetAttribute("qn-target" .. n, keys[i]:GetName())
	end
	bar:SetAttribute("qn-count", n)
	bar:SetAttribute("qn-shift", db.bindShift)
	bar:SetAttribute("qn-enabled", db.enabled)
	bar:SetAttribute("qn-bound", nil)   -- neu belegen, auch wenn sich die Sichtbarkeit nicht ändert
	SecureHandlerExecute(bar, BIND)
end

local function VisibilityDriver()
	local db = ns.db
	if not db.locked then
		return "show"
	end
	if db.useCustom and strtrim(db.custom) ~= "" then
		return db.custom
	end
	local parts = {}
	local function Add(cond)
		parts[#parts + 1] = cond .. " hide"
	end
	if db.hideVehicle then Add("[vehicleui][overridebar][possessbar]") end
	if db.hideCombat then Add("[combat]") end
	if db.hideNoCombat then Add("[nocombat]") end
	if db.hidePet then Add("[pet]") end
	if db.hideNoPet then Add("[nopet]") end
	if db.hideStealth then Add("[stealth]") end
	if db.hideForm then Add("[form]") end
	parts[#parts + 1] = "show"
	return table.concat(parts, "; ")
end

local function ApplyVisibility()
	if ns.db.enabled then
		RegisterStateDriver(bar, "visibility", VisibilityDriver())
	else
		UnregisterStateDriver(bar, "visibility")
		bar:Hide()
	end
end

local function ApplyButtons()
	local db = ns.db
	-- für DRAG_LOCK (liest die Leiste als control)
	bar:SetAttribute("qn-lockall", db.lockActions)
	bar:SetAttribute("qn-lockcombat", db.lockInCombat)
	for _, button in ipairs(buttons) do
		button:EnableMouse(not db.clickThrough)
		-- OnAttributeChanged der Vorlage ruft UpdateFlyout auf
		button:SetAttribute("flyoutDirection", db.flyout)
	end
end

-- Nur ungeschützte Darstellung, darf auch im Kampf laufen.
function ns.ApplyCosmetic()
	if not bar then
		return
	end
	local db = ns.db
	bar.bg:SetColorTexture(0, 0, 0, db.bgAlpha)
	fader:SetShown(db.fade)
	if not db.fade then
		bar:SetAlpha(db.alpha)
	end
	overlay:SetShown(db.enabled and not db.locked and not InCombatLockdown())
	for _, button in ipairs(buttons) do
		UpdateHotkey(button)
		UpdateLook(button)
	end
end

function ns.ApplyAll()
	ApplyLayout()
	ApplyPosition()
	ApplyStance()
	ApplyBindings()
	ApplyButtons()
	ApplyVisibility()
	ns.ApplyCosmetic()
end

-- Nach einem Ankerwechsel die Versätze so umrechnen, dass die Leiste bleibt, wo sie ist.
-- Im Kampf nach dem Kampf; bis dahin setzt ApplyPosition die Leiste nicht neu (sonst stünde sie
-- mit neuem Anker und alten Versätzen woanders, falls vorher schon ein ns.Apply wartete).
function ns.KeepPosition()
	if qnCore.DeferInCombat(ns.KeepPosition) then
		keepPending = true
		return
	end
	keepPending = false
	if bar:GetLeft() then
		SavePosition()
	else
		ns.Apply()
	end
end

-- Seite -> Blizzard-Leiste, die dieselben Plätze benutzt
local PAGE_BARS = {
	[3] = "MultiBarRight", [4] = "MultiBarLeft", [5] = "MultiBarBottomRight",
	[6] = "MultiBarBottomLeft", [13] = "MultiBar5", [14] = "MultiBar6", [15] = "MultiBar7",
}

local lastWarning = ""   -- zuletzt ausgegebene Warnungen

-- Warnt, wenn benutzte Seiten doppelt vergeben oder von einer sichtbaren Blizzard-Leiste belegt sind.
-- Liest die Einstellungen direkt (nicht die angewendete Leiste), damit es auch im Kampf stimmt.
-- Dieselben Warnungen erscheinen nur einmal hintereinander (z. B. Einloggen und Profilwechsel).
function ns.CheckPages()
	local db = ns.db
	local used = {}   -- Tastengruppe -> Seite
	for i, key in ipairs(ns.GetLayout(db.layout).keys) do
		if IsKeyShown(key) then
			used[Group(i)] = db["page" .. Group(i)]
		end
	end
	local lines, seen = {}, {}
	for n = 1, 3 do
		local page = used[n]
		if page and not seen[page] then
			seen[page] = true
			for m = n + 1, 3 do
				if used[m] == page then
					lines[#lines + 1] = L["Warnung: Seite %d ist für mehrere Tastengruppen eingestellt."]:format(page)
					break
				end
			end
			local blizz = _G[PAGE_BARS[page] or ""]
			if page == 1 or (blizz and blizz:IsShown()) then
				lines[#lines + 1] = L["Warnung: Seite %d wird auch von einer eingeblendeten Blizzard-Leiste benutzt."]:format(page)
			end
		end
	end
	local text = table.concat(lines, "\n")
	if text ~= lastWarning then
		lastWarning = text
		for _, line in ipairs(lines) do
			ns.Print(line)
		end
	end
end

-- Knopf und Slash-Befehl: Leiste in den sichtbaren Bereich holen (mit qnViewPort auf einen
-- Monitor), mit Rückmeldung. Nicht im Kampf (geschützt).
function ns.MoveIntoVisible()
	if bar and qnCore.Visible.MoveAndReport(bar, L["Leiste"], ns.Print) then
		SavePosition()   -- rechnet auf den eingestellten Anker um
	end
end

function ns.ResetPosition()
	local d = ns.defaults
	ns.store:SetValues({ point = d.point, x = d.x, y = d.y })
end

-- Zentriert die Leiste waagerecht bzw. senkrecht, unabhängig vom Anker.
function ns.CenterBar(horizontal)
	-- mittig liegt der Ankerpunkt der Leiste um (0.5 - Anteil) × (Platz neben der Leiste) vom Anker entfernt
	local fx, fy = qnCore.AnchorFactors(ns.db.point)
	local s = bar:GetScale()
	local pw, ph = UIParent:GetSize()
	if horizontal then
		ns.store:Set("x", Round((0.5 - fx) * (pw - bar:GetWidth() * s)))
	else
		ns.store:Set("y", Round((0.5 - fy) * (ph - bar:GetHeight() * s)))
	end
end
