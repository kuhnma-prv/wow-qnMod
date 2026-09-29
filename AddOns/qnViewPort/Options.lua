-- qnViewPort: Optionsseite im Blizzard-Einstellungsfenster (Canvas-Layout).
-- Vorschau mit ziehbaren Rändern, vier Eingabefelder, Übernehmen mit 20 Sekunden
-- Bestätigungsfrist, Farbe und Muster der Fläche außerhalb der Welt.
-- Alle Werte gehören zum aktiven Profil (qnCore).

local _, ns = ...
local L = ns.L
local UI = qnCore.UI

local page                       -- qnCore.UI.Page
local panel, content             -- page.panel (Anmeldung, Skripte), page.content (Steuerelemente)
local pending = { 0, 0, 0, 0 }   -- in der Vorschau bearbeitete Werte
local boxes = {}                 -- Eingabefelder links, rechts, oben, unten
local preview, inner, ratioScreen, ratioView
local applyButton, resetButton, keepButton, colorSwatch
local patternDropdown, alphaSlider
local dragging                   -- { l, r, t, b } = welche Ränder gezogen werden

local PREVIEW_WIDTH = 320
local PREVIEW_TOP = 104          -- Abstand der Vorschau vom oberen Rand des Inhalts (unter der Kopfzeile)
local PAD = 4
local KEEP_SECONDS = 20

---------------------------------------------------------------------------
-- Seitenverhältnis als Dezimalzahl und Bruch (z. B. 1.78 (16/9))
---------------------------------------------------------------------------

-- Kleinster Nenner a (bis 100), zu dem ein Zähler b (bis 100) auf zwei Stellen denselben Wert ergibt.
-- Passende Zähler liegen höchstens 1 neben value * a.
local function Quotient(value)
	local s = ("%.2f"):format(value)
	for a = 1, 100 do
		local near = math.floor(value * a + 0.5)
		for b = math.max(1, near - 1), math.min(100, near + 1) do
			if ("%.2f"):format(b / a) == s then
				return ("%s |r(|cffffffff%d/%d|r)"):format(s, b, a)
			end
		end
	end
	return s
end

---------------------------------------------------------------------------
-- Bausteine (auch für SecondScreen.lua)
---------------------------------------------------------------------------

-- Zahlenfeld (nur Ziffern). get() liefert den angezeigten Wert, set(v) übernimmt eine Eingabe
-- (Enter oder Fokusverlust; v = nil bei leerem Feld). Escape stellt den Wert wieder her.
function ns.NumBox(parent, width, get, set)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(width, 22)
	box:SetAutoFocus(false)
	box:SetNumeric(true)
	box:SetMaxLetters(5)
	box:SetJustifyH("CENTER")
	local function Commit(self)
		set(tonumber(self:GetText()))
		self:SetText(get())
	end
	box:SetScript("OnEnterPressed", function(self)
		Commit(self)
		self:ClearFocus()
	end)
	box:SetScript("OnEditFocusLost", function(self)
		self:HighlightText(0, 0)
		Commit(self)
	end)
	box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	box:SetScript("OnEscapePressed", function(self)
		self:SetText(get())
		self:ClearFocus()
	end)
	return box
end

---------------------------------------------------------------------------
-- Anzeige aktualisieren
---------------------------------------------------------------------------

local function Refresh()
	local w, h = ns.screen[1], ns.screen[2]
	for i = 1, 4 do
		if not boxes[i]:HasFocus() then
			boxes[i]:SetText(pending[i])
		end
	end

	local pw, ph = preview:GetWidth() - 2 * PAD, preview:GetHeight() - 2 * PAD
	inner:ClearAllPoints()
	inner:SetPoint("TOPLEFT", preview, "TOPLEFT", PAD + pending[1] / w * pw, -(PAD + pending[3] / h * ph))
	inner:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", -(PAD + pending[2] / w * pw), PAD + pending[4] / h * ph)

	ratioScreen:SetText(L["|cffccccccScreen resolution: |cffffffff%s"]:format(w .. " × " .. h .. " – " .. Quotient(w / h)))
	local vw, vh = w - pending[1] - pending[2], h - pending[3] - pending[4]
	ratioView:SetText(L["|cffccccccCustom viewport: |cffffffff%s"]:format(vw .. " × " .. vh .. " – " .. (vh > 0 and Quotient(vw / vh) or "0")))
end

local function SetPending(v, changed)
	if changed <= 2 then
		pending = ns.Clamp(v, changed, nil)
	else
		pending = ns.Clamp(v, nil, changed)
	end
	Refresh()
end

-- Nach außen: Versätze angewendet (Slash-Befehl, Rücksetzen, Auflösungs- oder Profilwechsel)
function ns.OnViewportChanged(v)
	if not dragging then
		pending = CopyTable(v)
		Refresh()
	end
end

-- Eingaben in den Feldern übernehmen, bevor ein Knopf wirkt
local function ClearFocusAll()
	for _, box in ipairs(boxes) do
		box:ClearFocus()
	end
end

---------------------------------------------------------------------------
-- Übernehmen mit Bestätigungsfrist
---------------------------------------------------------------------------

local keepTicker, keepStart, keepPrevious

local function EndKeep()
	if keepTicker then
		keepTicker:Cancel()
		keepTicker = nil
	end
	keepStart, keepPrevious = nil, nil
	applyButton:Show()
	resetButton:Show()
	keepButton:Hide()
end

ns.EndKeep = EndKeep

local function KeepTick()
	local left = KEEP_SECONDS - (GetTime() - keepStart)
	if left <= 0 then
		-- gespeicherten Wert von vorher unverändert zurückschreiben
		local previous = keepPrevious
		EndKeep()
		ns.db.viewport = previous
		ns.ShowViewport(previous)
		ns.Print(L["Setting not confirmed – previous viewport restored."])
	else
		keepButton:SetText(L["Keep Settings?  Reverting in %d sec."]:format(math.ceil(left)))
	end
end

function ns.ApplyWithConfirm(v)
	if not keepStart then
		keepPrevious = CopyTable(ns.db.viewport)
	end
	keepStart = GetTime()
	ns.ApplyViewport(v)
	applyButton:Hide()
	resetButton:Hide()
	keepButton:Show()
	keepTicker = keepTicker or C_Timer.NewTicker(0.25, KeepTick)
	KeepTick()
end

---------------------------------------------------------------------------
-- Ränder in der Vorschau ziehen
---------------------------------------------------------------------------

local function OnUpdate()
	if not dragging then
		return
	end
	local scale = preview:GetEffectiveScale()
	local cx, cy = GetCursorPosition()
	cx, cy = cx / scale, cy / scale
	local left, right = preview:GetLeft() + PAD, preview:GetRight() - PAD
	local top, bottom = preview:GetTop() - PAD, preview:GetBottom() + PAD
	local w, h = ns.screen[1], ns.screen[2]
	local v = CopyTable(pending)
	if dragging.l then v[1] = (cx - left) / (right - left) * w end
	if dragging.r then v[2] = (right - cx) / (right - left) * w end
	if dragging.t then v[3] = (top - cy) / (top - bottom) * h end
	if dragging.b then v[4] = (cy - bottom) / (top - bottom) * h end
	pending = ns.Clamp(v, (dragging.l and 1) or (dragging.r and 2), (dragging.t and 3) or (dragging.b and 4))
	Refresh()
end

local HANDLES = {
	{ "TOPLEFT", { l = true, t = true } },
	{ "TOPRIGHT", { r = true, t = true } },
	{ "BOTTOMLEFT", { l = true, b = true } },
	{ "BOTTOMRIGHT", { r = true, b = true } },
	{ "LEFT", { l = true } },
	{ "RIGHT", { r = true } },
	{ "TOP", { t = true } },
	{ "BOTTOM", { b = true } },
}

local function CreateHandles()
	local size = 12
	local handles = {}
	for _, def in ipairs(HANDLES) do
		local point, edges = def[1], def[2]
		local handle = CreateFrame("Button", nil, inner)
		handle:SetFrameLevel(inner:GetFrameLevel() + 1)
		handles[point] = handle
		handle:SetScript("OnMouseDown", function() dragging = edges end)
		handle:SetScript("OnMouseUp", function() dragging = nil end)
		handle:SetScript("OnHide", function() dragging = nil end)
		local hl = handle:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 1, 0, 0.35)
	end
	for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
		handles[corner]:SetSize(size, size)
		handles[corner]:SetPoint(corner)
	end
	handles.LEFT:SetPoint("TOPLEFT", handles.TOPLEFT, "BOTTOMLEFT")
	handles.LEFT:SetPoint("BOTTOMRIGHT", handles.BOTTOMLEFT, "TOPRIGHT")
	handles.RIGHT:SetPoint("TOPLEFT", handles.TOPRIGHT, "BOTTOMLEFT")
	handles.RIGHT:SetPoint("BOTTOMRIGHT", handles.BOTTOMRIGHT, "TOPRIGHT")
	handles.TOP:SetPoint("TOPLEFT", handles.TOPLEFT, "TOPRIGHT")
	handles.TOP:SetPoint("BOTTOMRIGHT", handles.TOPRIGHT, "BOTTOMLEFT")
	handles.BOTTOM:SetPoint("TOPLEFT", handles.BOTTOMLEFT, "TOPRIGHT")
	handles.BOTTOM:SetPoint("BOTTOMRIGHT", handles.BOTTOMRIGHT, "BOTTOMLEFT")
end

---------------------------------------------------------------------------
-- Eingabefelder und Farbe
---------------------------------------------------------------------------

local TAB_ORDER = { 3, 2, 4, 1 }   -- oben, rechts, unten, links

local function Box(index, tooltip)
	local box = ns.NumBox(content, 50, function() return pending[index] end, function(value)
		local v = CopyTable(pending)
		v[index] = value or 0
		SetPending(v, index)
	end)
	box:SetScript("OnTabPressed", function()
		for pos, i in ipairs(TAB_ORDER) do
			if i == index then
				local step = IsShiftKeyDown() and -1 or 1
				boxes[TAB_ORDER[(pos - 1 + step) % 4 + 1]]:SetFocus()
				return
			end
		end
	end)
	UI.Tooltip(box, tooltip, L["Pixels, press Enter to confirm."])
	boxes[index] = box
	return box
end

local function UpdateSwatch()
	local c = ns.db.color
	colorSwatch.tex:SetColorTexture(c[1], c[2], c[3], 1)
end

local function OpenColorPicker()
	local c = ns.db.color
	local function Set(r, g, b, a)
		ns.db.color = { r, g, b, a }
		ns.UpdateBorderLook()
		UpdateSwatch()
	end
	-- Farbe oder Deckkraft im Farbwähler geändert
	local function Picked()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		Set(r, g, b, ColorPickerFrame:GetColorAlpha() or ns.db.color[4])
	end
	ColorPickerFrame:SetupColorPickerAndShow({
		r = c[1], g = c[2], b = c[3], opacity = c[4], hasOpacity = true,
		swatchFunc = Picked,
		opacityFunc = Picked,
		cancelFunc = function(prev)
			Set(prev.r, prev.g, prev.b, prev.a or 1)
		end,
	})
end

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------

-- Der Bereich unter den Knöpfen folgt der Höhe der Vorschau (hängt vom Seitenverhältnis ab).
-- Die Knöpfe stehen mittig, die Texte darunter links; deshalb Versatz statt Anker am Knopf:
-- Vorschau + Eingabefeld unten (8 + 22) + Knopf (10 + 26) + 14 Abstand.
local function PlaceLower()
	ratioScreen:ClearAllPoints()
	ratioScreen:SetPoint("TOPLEFT", content, "TOPLEFT", page.padLeft, -(PREVIEW_TOP + preview:GetHeight() + 80))
	page.Fit()
end

local function Build()
	local desc = page.top

	local tips = UI.Text(content, "GameFontHighlightSmall",
		L["|cffffffff/qnvp|r  open options     |cffffffff/qnvp 0 0 0 0|r  reset     |cffffffff/qnvp 5 20 15 0|r  set left, right, top, bottom"])
	tips:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)

	local w, h = ns.screen[1], ns.screen[2]
	preview = CreateFrame("Frame", nil, content, "BackdropTemplate")
	preview:SetSize(PREVIEW_WIDTH, PREVIEW_WIDTH * h / w)
	preview:SetPoint("TOP", content, "TOP", 0, -PREVIEW_TOP)
	preview:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 2 })
	preview:SetBackdropBorderColor(1, 0, 0, 1)

	inner = CreateFrame("Frame", nil, preview, "BackdropTemplate")
	inner:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 2 })
	inner:SetBackdropBorderColor(1, 1, 0, 1)
	local fill = inner:CreateTexture(nil, "BACKGROUND")
	fill:SetAllPoints()
	fill:SetColorTexture(1, 1, 0, 0.1)
	local label = UI.Text(inner, "GameFontNormal", L["Game world"])
	label:SetPoint("CENTER")
	CreateHandles()

	Box(3, HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_TOP):SetPoint("BOTTOM", preview, "TOP", 0, 8)
	Box(4, HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_BOTTOM):SetPoint("TOP", preview, "BOTTOM", 0, -8)
	Box(1, HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_LEFT):SetPoint("RIGHT", preview, "LEFT", -12, 0)
	Box(2, HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_RIGHT):SetPoint("LEFT", preview, "RIGHT", 14, 0)

	applyButton = UI.Button(content, APPLY, 130, function()
		ClearFocusAll()
		ns.ApplyWithConfirm(pending)
	end, L["Without confirmation the setting reverts after %d seconds."]:format(KEEP_SECONDS))
	applyButton:SetPoint("TOPRIGHT", boxes[4], "BOTTOM", -6, -10)

	resetButton = UI.Button(content, RESET, 130, function()
		ClearFocusAll()
		EndKeep()
		ns.ApplyViewport({ 0, 0, 0, 0 })
	end, L["Whole screen for the game world (/qnvp 0 0 0 0)."])
	resetButton:SetPoint("TOPLEFT", boxes[4], "BOTTOM", 6, -10)

	keepButton = UI.Button(content, L["Keep Settings?"], 280, EndKeep)
	keepButton:SetPoint("TOP", boxes[4], "BOTTOM", 0, -10)
	keepButton:Hide()

	ratioScreen = UI.Text(content, "GameFontHighlight")
	PlaceLower()
	ratioView = UI.Text(content, "GameFontHighlight")
	ratioView:SetPoint("TOPLEFT", ratioScreen, "BOTTOMLEFT", 0, -6)

	local check = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", ratioView, "BOTTOMLEFT", -4, -16)
	check:SetChecked(ns.db.suppressMessage)
	check:SetScript("OnClick", function(self)
		ns.db.suppressMessage = self:GetChecked() and true or false
	end)
	local checkText = UI.Text(content, "GameFontHighlight", L["Suppress the on-load message"])
	checkText:SetPoint("LEFT", check, "RIGHT", 2, 0)

	colorSwatch = CreateFrame("Button", nil, content)
	colorSwatch:SetSize(20, 20)
	colorSwatch:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 6, -10)
	local swatchBorder = colorSwatch:CreateTexture(nil, "BACKGROUND")
	swatchBorder:SetAllPoints()
	swatchBorder:SetColorTexture(1, 1, 1, 1)
	colorSwatch.tex = colorSwatch:CreateTexture(nil, "ARTWORK")
	colorSwatch.tex:SetPoint("TOPLEFT", 2, -2)
	colorSwatch.tex:SetPoint("BOTTOMRIGHT", -2, 2)
	UpdateSwatch()
	colorSwatch:SetScript("OnClick", OpenColorPicker)
	local colorText = UI.Text(content, "GameFontHighlight", L["Color of the area outside the world"])
	colorText:SetPoint("LEFT", colorSwatch, "RIGHT", 8, 0)

	-- Hintergrundmuster über der Farbe
	local patternText = UI.Text(content, "GameFontHighlight", L["Background pattern"])
	patternText:SetPoint("TOPLEFT", colorSwatch, "BOTTOMLEFT", 0, -16)
	patternDropdown = UI.Dropdown(content, 220, ns.PatternChoices, function()
		return ns.db.pattern
	end, function(value)
		ns.db.pattern = value
		ns.UpdateBorderLook()
		alphaSlider:SetEnabled(value ~= "none")
	end, L["No pattern (color only)"])
	patternDropdown:SetPoint("LEFT", patternText, "LEFT", 170, 0)
	UI.Tooltip(patternDropdown, L["Background pattern"],
		L["Tiled pattern over the color of the area outside the world. The color stays visible underneath wherever the pattern lets it show through."])

	local alphaText = UI.Text(content, "GameFontHighlight", L["Pattern opacity"])
	alphaText:SetPoint("TOPLEFT", patternText, "BOTTOMLEFT", 0, -22)
	alphaSlider = CreateFrame("Frame", nil, content, "MinimalSliderWithSteppersTemplate")
	alphaSlider:SetSize(220, 20)
	alphaSlider:SetPoint("LEFT", alphaText, "LEFT", 170, 0)
	alphaSlider:Init(ns.db.patternAlpha * 100, 0, 100, 20, {
		[MinimalSliderWithSteppersMixin.Label.Right] = function(v)
			return ("%d %%"):format(v + 0.5)
		end,
	})
	alphaSlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		ns.db.patternAlpha = math.floor(value + 0.5) / 100
		ns.UpdateBorderLook()
	end, alphaSlider)

	local function OnShow()
		ns.UpdateScreenSize()
		local sw, sh = ns.screen[1], ns.screen[2]
		preview:SetHeight(PREVIEW_WIDTH * sh / sw)
		PlaceLower()
		pending = CopyTable(ns.GetViewport())
		check:SetChecked(ns.db.suppressMessage)
		UpdateSwatch()
		patternDropdown:Refresh()
		alphaSlider:SetValue(ns.db.patternAlpha * 100)
		alphaSlider:SetEnabled(ns.db.pattern ~= "none")
		Refresh()
	end
	panel:SetScript("OnUpdate", OnUpdate)
	panel:SetScript("OnShow", OnShow)

	-- nach einem Profilwechsel (qnCore)
	function ns.RefreshOptions()
		if panel:IsVisible() then
			OnShow()
		end
	end
	panel:SetScript("OnHide", function()
		dragging = nil
	end)
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	page = UI.Page("qnViewPort", { descWidth = 560, desc =
		L["Shrinks the area in which the 3D world is rendered. The interface stays where it is – so bars and windows can be placed next to the game world."] })
	panel, content = page.panel, page.content
	qnCore.Settings.NewCategory(ns, "qnViewPort", Build, panel)
end
