-- qnMeter: Fenster und Balken in der Optik des eingebauten Damage Meters
-- (Blizzard_DamageMeter: DamageMeterSessionWindow.xml, DamageMeterEntry.xml).

local _, ns = ...

local HEADER_HEIGHT = 32
local CONTENT_LEFT, CONTENT_TOP = 5, -2      -- wie ScrollBox-Anker unter dem Header
local CONTENT_RIGHT, CONTENT_BOTTOM = -1, 6
local NO_HEADER_TOP = 6

local Window = {}
ns.Window = Window

local function ApplyFont(fs, size)
	fs:SetFontObject(NumberFontNormal)
	local file, _, flags = fs:GetFont()
	if file and size and size > 0 then
		fs:SetFont(file, size, flags)
	end
end


---------------------------------------------------------------------------
-- Balken (entspricht DamageMeterEntryTemplate)
---------------------------------------------------------------------------

local RowMixin = {}

function RowMixin:SetMinMaxValues(...)
	self.status:SetMinMaxValues(...)
end

function RowMixin:SetValue(...)
	self.status:SetValue(...)
end

function RowMixin:SetBarColor(r, g, b)
	self.status:GetStatusBarTexture():SetVertexColor(r, g, b)
end

-- class: Klassenname für den Klassen-Atlas; nil blendet das Symbol aus.
function RowMixin:SetClassIcon(class)
	if class == self.iconClass then
		return
	end
	self.iconClass = class
	if class then
		self.icon.tex:SetAtlas(GetClassAtlas(class))
		self.icon.tex:Show()
	else
		self.icon.tex:Hide()
	end
end

local function CreateRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	Mixin(row, RowMixin)
	row:SetClipsChildren(true)

	local icon = CreateFrame("Frame", nil, row)
	icon:SetPoint("LEFT")
	icon.tex = icon:CreateTexture(nil, "ARTWORK")
	icon.tex:SetAllPoints()
	row.icon = icon

	local status = CreateFrame("StatusBar", nil, row)
	status:SetMinMaxValues(0, 1)
	status:SetValue(0)
	row.status = status

	-- Hintergrund und Rand; Atlas und Anker hängen vom Stil ab (StyleBar).
	row.bg = status:CreateTexture(nil, "BACKGROUND")
	row.edge = status:CreateTexture(nil, "OVERLAY")
	row.edge:SetAtlas("ui-damagemeters-bar-shadowedge")
	row.edge:SetPoint("TOPLEFT", -2, 2)
	row.edge:SetPoint("BOTTOMRIGHT", 2, -2)

	row.right = status:CreateFontString(nil, "OVERLAY")
	row.right:SetJustifyH("LEFT")

	row.left = status:CreateFontString(nil, "OVERLAY")
	row.left:SetJustifyH("LEFT")
	row.left:SetWordWrap(false)

	row:Hide()
	return row
end

---------------------------------------------------------------------------
-- Stile wie DamageMeterEntryMixin (Default, Thin, Bordered, FullBackground)
---------------------------------------------------------------------------

local STYLE_THIN = Enum.DamageMeterStyle.Thin
local STYLE_BORDERED = Enum.DamageMeterStyle.Bordered

-- Wie GetBackgroundAtlasForStyle/GetBackgroundInsetsForStyle/GetBackgroundEdgeVisibilityForStyle.
local function SetupBackground(row, style)
	local bordered = style == STYLE_BORDERED
	local bg = row.bg
	bg:SetAtlas(bordered and "UI-HUD-CoolDownManager-Bar-BG" or "ui-damagemeters-bar-shadowbg")
	bg:ClearAllPoints()
	bg:SetPoint("TOPLEFT", -2, 2)
	bg:SetPoint("BOTTOMRIGHT", bordered and 6 or 2, bordered and -7 or -2)
	row.edge:SetShown(not bordered)
end

local function SetupAnchors(row, style, showIcons)
	local status, name, value = row.status, row.left, row.right
	status:ClearAllPoints()
	name:ClearAllPoints()
	value:ClearAllPoints()

	-- Anker am Symbol bzw. am Zeilenrand (GetIconAttachmentAnchor).
	local relTo, relPoint, x = row, "LEFT", 0
	if showIcons then
		relTo, relPoint = row.icon, "RIGHT"
		if style == STYLE_BORDERED or style == STYLE_THIN then
			x = 5
		end
	end

	if style == STYLE_THIN then
		-- Text oben, schmaler Balken darunter.
		name:SetPoint("TOP", row, "TOP", 0, 0)
		name:SetPoint("LEFT", relTo, relPoint, x, 0)
		name:SetPoint("RIGHT", value, "LEFT", -25, 0)
		value:SetPoint("TOP", row, "TOP", 0, 0)
		value:SetPoint("RIGHT", row, "RIGHT", -3, 0)
		status:SetPoint("LEFT", relTo, relPoint, x, 0)
		status:SetPoint("TOP", name, "BOTTOM", 0, 0)
		status:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)
	else
		status:SetPoint("LEFT", relTo, relPoint, x, 0)
		status:SetPoint("TOP", row, "TOP", 0, -1)
		status:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 1)
		name:SetPoint("LEFT", status, "LEFT", 2, 0)
		name:SetPoint("RIGHT", value, "LEFT", -25, 0)
		value:SetPoint("RIGHT", status, "RIGHT", -3, 0)
	end
end

---------------------------------------------------------------------------
-- Wirksame Darstellungswerte: eigene Optionen oder vom Damage Meter.
---------------------------------------------------------------------------

function Window.GetEffective(db)
	local e = {
		linked = false,
		barHeight = db.barHeight,
		barSpacing = db.barSpacing,
		showIcons = db.showIcons,
		classColors = db.classColors,
		bgAlpha = db.bgAlpha,
		style = db.style,
		fontSize = db.fontSize,
		textScale = 1,
		windowAlpha = 1,
	}
	local dm = DamageMeter
	if db.linkDamageMeter then
		e.linked = true
		e.barHeight = dm:GetBarHeight()
		e.barSpacing = dm:GetBarSpacing()
		e.style = dm:GetStyle()
		e.textScale = dm:GetTextScale()
		e.fontSize = 0
		e.bgAlpha = dm:GetBackgroundAlpha()
		e.windowAlpha = dm:GetWindowAlpha()
		-- Vor dem Laden des Bearbeitungsmodus sind diese noch nil.
		local icons = dm:ShouldShowBarIcons()
		if icons ~= nil then
			e.showIcons = icons
		end
		local classColors = dm:ShouldUseClassColor()
		if classColors ~= nil then
			e.classColors = classColors
		end
	end
	return e
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------

local SETTINGS_ATLAS = {
	normal = "common-dropdown-a-button-settings-shadowless",
	hover = "common-dropdown-a-button-settings-hover-shadowless",
	pressed = "common-dropdown-a-button-settings-pressed-shadowless",
}

local function CreateSettingsButton(f)
	local b = CreateFrame("Button", nil, f)
	b:SetSize(27, 27)
	b:SetPoint("TOPRIGHT", f.header, "TOPRIGHT", -3, -3)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetPoint("CENTER")
	local function SetState(state)
		b.icon:SetAtlas(SETTINGS_ATLAS[state], true)
	end
	SetState("normal")
	b:SetScript("OnEnter", function() SetState("hover") end)
	b:SetScript("OnLeave", function() SetState("normal") end)
	b:SetScript("OnMouseDown", function() SetState("pressed") end)
	b:SetScript("OnMouseUp", function(self)
		SetState(self:IsMouseOver() and "hover" or "normal")
	end)
	b:SetScript("OnClick", function(self)
		f:OnMenu(self)
	end)
	return b
end

-- Nach Verschieben oder Größenänderung: Lage merken, ggf. in den sichtbaren Bereich holen
-- (f.checkVisible aus qnCore.Visible.Keep, Threat.lua).
local function FinishMove(f)
	f:StopMovingOrSizing()
	Window.SavePosition(f)
	if f.checkVisible then
		f.checkVisible()
	end
end

local function CreateResizeButton(f)
	local b = CreateFrame("Button", nil, f)
	b:SetSize(60, 60)
	b:SetPoint("BOTTOMRIGHT", 9, -8)
	b:SetFrameLevel(f:GetFrameLevel() + 20)
	b:SetAlpha(0)
	local normal = b:CreateTexture()
	normal:SetAtlas("damagemeters-scalehandle")
	b:SetNormalTexture(normal)
	local highlight = b:CreateTexture()
	highlight:SetAtlas("damagemeters-scalehandle-hover")
	b:SetHighlightTexture(highlight)
	local pushed = b:CreateTexture()
	pushed:SetAtlas("damagemeters-scalehandle-pressed")
	b:SetPushedTexture(pushed)

	-- Gesperrt ist der Anfasser ausgeblendet (ApplyStyle).
	b:SetScript("OnMouseDown", function()
		f.isSizing = true
		f:StartSizing("BOTTOMRIGHT")
	end)
	b:SetScript("OnMouseUp", function()
		f.isSizing = false
		FinishMove(f)
		f.UpdateHover()   -- Maus kann jetzt außerhalb stehen
	end)
	return b
end

function Window.Create(name, db)
	local f = CreateFrame("Frame", name, UIParent)
	f.db = db
	f.bars = {}
	f:SetFrameStrata("MEDIUM")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetResizable(true)
	f:SetResizeBounds(150, 60, 800, 900)

	-- Hintergrund über das ganze Fenster, Deckkraft einstellbar.
	f.background = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	f.background:SetAllPoints()
	f.background:SetAtlas("damagemeters-background")

	-- Kopfleiste
	f.header = f:CreateTexture(nil, "BACKGROUND", nil, 0)
	f.header:SetHeight(HEADER_HEIGHT)
	f.header:SetPoint("TOPLEFT")
	f.header:SetPoint("TOPRIGHT")
	f.header:SetAtlas("ui-damagemeters-header-bar")

	f.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalMed1")
	f.titleText:SetPoint("TOPLEFT", f.header, "TOPLEFT", 6, -9)
	f.titleText:SetJustifyH("LEFT")
	f.titleText:SetWordWrap(false)

	f.infoText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalMed1")
	f.infoText:SetJustifyH("RIGHT")

	f.settingsButton = CreateSettingsButton(f)
	f.infoText:SetPoint("RIGHT", f.settingsButton, "LEFT", -2, 0)
	f.titleText:SetPoint("RIGHT", f.infoText, "LEFT", -6, 0)

	f.resizeButton = CreateResizeButton(f)

	-- Verschieben über das ganze Fenster, Rechtsklick öffnet das Menü.
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if not self.db.locked then
			self:StartMoving()
		end
	end)
	f:SetScript("OnDragStop", FinishMove)
	f:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" then
			self:OnMenu(self)
		end
	end)

	f:SetScript("OnSizeChanged", function()
		Window.Layout(f)
	end)

	-- Größenanfasser wie bei Blizzard nur bei Mausberührung einblenden. Überblenden nur nach
	-- Betreten/Verlassen (Fenster und die Knöpfe, die die Maus selbst abfangen) und nach dem Ziehen;
	-- danach hält der Überblender an.
	local fade = CreateFrame("Frame", nil, f)
	fade:Hide()
	fade:SetScript("OnUpdate", function(self, dt)
		local target = (f:IsMouseOver() or f.isSizing) and 1 or 0
		local a = f.resizeButton:GetAlpha()
		if a ~= target then
			local step = dt / 0.25
			a = target > a and math.min(target, a + step) or math.max(target, a - step)
			f.resizeButton:SetAlpha(a)
		end
		if a == target then
			self:Hide()
		end
	end)
	f.hoverFade = fade
	f.UpdateHover = function()
		fade:Show()
	end
	for _, region in ipairs({ f, f.settingsButton, f.resizeButton }) do
		region:HookScript("OnEnter", f.UpdateHover)
		region:HookScript("OnLeave", f.UpdateHover)
	end

	return f
end

-- Speichert die Lage relativ zu UIParent, in Einheiten von UIParent (unabhängig von der Skalierung
-- des Fensters). Nicht über GetPoint: nach dem Ziehen kann der Anker am Bildschirm statt an
-- UIParent hängen, und UIParent liegt mit qnViewPort evtl. nicht bei 0,0.
function Window.SavePosition(f)
	local x, y = qnCore.PointOffset(f, "TOPLEFT", "BOTTOMLEFT", true)
	if x then
		f.db.point = { "TOPLEFT", "BOTTOMLEFT", math.floor(x + 0.5), math.floor(y + 0.5) }
	end
	f.db.width = math.floor(f:GetWidth() + 0.5)
	f.db.height = math.floor(f:GetHeight() + 0.5)
end

-- Versätze in Einheiten von UIParent: beim Setzen durch die Skalierung des Fensters teilen, damit
-- es beim Ändern der Skalierung an seiner Ecke stehen bleibt.
function Window.RestorePosition(f)
	local p = f.db.point
	local s = f.db.scale or 1
	f:ClearAllPoints()
	f:SetPoint(p[1] or "CENTER", UIParent, p[2] or "CENTER", (p[3] or 0) / s, (p[4] or 0) / s)
	f:SetSize(f.db.width, f.db.height)
end

local function Eff(f)
	if not f.eff then
		f.eff = Window.GetEffective(f.db)
	end
	return f.eff
end

-- Übernimmt Darstellungsoptionen auf Fenster und alle Balken.
function Window.ApplyStyle(f)
	local db = f.db
	f.eff = Window.GetEffective(db)
	local e = f.eff

	f:SetScale(db.scale)
	f:SetAlpha(e.windowAlpha)
	f.background:SetAlpha(e.bgAlpha)

	local showHeader = db.showTitle
	f.header:SetShown(showHeader)
	f.titleText:SetShown(showHeader)
	f.infoText:SetShown(showHeader)
	f.settingsButton:SetShown(showHeader)
	f.resizeButton:SetShown(not db.locked)

	for _, row in ipairs(f.bars) do
		Window.StyleBar(f, row)
	end
	Window.Layout(f)
end

function Window.StyleBar(f, row)
	local db = f.db
	local e = Eff(f)
	local h = e.barHeight
	row:SetHeight(h)

	-- Balkentextur: Atlas oder Dateipfad (SetStatusBarTexture nimmt beides).
	row.status:SetStatusBarTexture(ns.GetTexturePath(db.texture))

	row.icon:SetSize(h, h)
	row.icon:SetShown(e.showIcons)
	SetupBackground(row, e.style)
	SetupAnchors(row, e.style, e.showIcons)

	for _, fs in ipairs({ row.left, row.right }) do
		ApplyFont(fs, e.fontSize)
		fs:SetTextScale(e.textScale)
	end
	row.iconClass = false -- Symbol beim nächsten Setzen neu laden
end

local function ContentTop(db)
	return db.showTitle and (-HEADER_HEIGHT + CONTENT_TOP) or -NO_HEADER_TOP
end

-- Anzahl der Balken, die in die aktuelle Fensterhöhe passen.
function Window.GetCapacity(f)
	local e = Eff(f)
	local h = f:GetHeight() + ContentTop(f.db) - CONTENT_BOTTOM
	return math.max(0, math.floor((h + e.barSpacing) / (e.barHeight + e.barSpacing)))
end

-- Verankert die i-te Zeile unter der Kopfleiste.
local function AnchorRow(f, row, i)
	local e = Eff(f)
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", f, "TOPLEFT", CONTENT_LEFT, ContentTop(f.db) - (i - 1) * (e.barHeight + e.barSpacing))
	row:SetPoint("RIGHT", f, "RIGHT", CONTENT_RIGHT, 0)
end

function Window.GetBar(f, i)
	local row = f.bars[i]
	if not row then
		row = CreateRow(f)
		f.bars[i] = row
		Window.StyleBar(f, row)
		AnchorRow(f, row, i)
	end
	return row
end

function Window.Layout(f)
	for i, row in ipairs(f.bars) do
		AnchorRow(f, row, i)
	end
end

function Window.HideBarsFrom(f, first)
	for i = first, #f.bars do
		f.bars[i]:Hide()
	end
end
