-- qnUnitFrames: Optionsseite "Klickbelegung" (Canvas-Layout).
-- Oben die Maustaste, darunter eine Zeile je Zusatztaste: Aktion (Dropdown) und bei Zauber die
-- Auswahl aus dem Zauberbuch, bei Makro der Makrotext. Gilt für die eigene Klasse im aktiven Profil.
-- Makros werden unten auf der Seite mehrzeilig bearbeitet (Eingabefenster haben nur eine Zeile).

local _, ns = ...
local lib = qnCore
local L = ns.L
local UI = lib.UI

local page, sub
local infoText, buttonDropdown
local rows = {}
ns.clicksUI = { rows = rows }   -- für die Tests (dazu .button = Dropdown der Maustaste, .macro = Makro-Editor)
local button = "1"   -- gewählte Maustaste
local editKey        -- Belegung, deren Zauber gerade im Eingabefenster steht
local macroKey       -- Belegung, deren Makro gerade im Makro-Editor steht
local editor         -- Makro-Editor

local OTHER = {}   -- Eintrag "Anderer Zauber …" in der Zauberliste (kein Zaubername kann ihm gleichen)
local ROW_HEIGHT = 34
local MACRO_LETTERS = 255   -- Länge eines Makros

---------------------------------------------------------------------------
-- Zauberbuch
---------------------------------------------------------------------------

-- Namen der aktiven (nicht passiven) Zauber des Spielers, sortiert, ohne Doppelte
function ns.SpellNames()
	local seen, list = {}, {}
	local bank = Enum.SpellBookSpellBank.Player
	for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
		if info and not info.shouldHide and not info.offSpecID then
			for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
				local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
				local name = item and item.name
				if name and not ns.IsSecret(name) and item.itemType == Enum.SpellBookItemType.Spell
					and not item.isPassive and not seen[name] then
					seen[name] = true
					list[#list + 1] = name
				end
			end
		end
	end
	table.sort(list)
	return list
end

local function SpellEntries(current)
	local list = {}
	local found = false
	for _, name in ipairs(ns.SpellNames()) do
		list[#list + 1] = { name, name }
		found = found or name == current
	end
	-- von Hand eingetragen oder (noch) nicht im Zauberbuch: trotzdem als Auswahl zeigen
	if current and current ~= "" and not found then
		table.insert(list, 1, { current, current })
	end
	list[#list + 1] = { OTHER, L["Anderer Zauber …"] }
	return list
end

---------------------------------------------------------------------------
-- Eingabefenster
---------------------------------------------------------------------------

local function Entry(key)
	return ns.Bindings()[key]
end

local function Value()
	local entry = editKey and Entry(editKey)
	return entry and entry.value or ""
end

lib.Popup.EditText("QNUNITFRAMES_SPELL", L["Name oder Zauber-ID für %s:"], Value, function(text)
	if editKey then
		ns.SetBinding(editKey, "spell", strtrim(text))
		ns.RefreshClicksPage()
	end
end, 255)

local function EditSpell(key)
	editKey = key
	StaticPopup_Show("QNUNITFRAMES_SPELL", ns.BindingText(key))
end

---------------------------------------------------------------------------
-- Makro-Editor (mehrzeilig, unten auf der Seite)
---------------------------------------------------------------------------

local function CloseMacro()
	macroKey = nil
	editor.box:ClearFocus()
	editor:Hide()
end

local function EditMacro(key)
	macroKey = key
	local entry = Entry(key)
	editor.label:SetText(L["Makrotext für %s (für die angeklickte Einheit: [@mouseover], z. B. /cast [@mouseover] Heilen):"]:format(ns.BindingText(key)))
	editor.box:SetText(entry and entry.value or "")
	editor:Show()
	editor.box:SetFocus()
end

local function AcceptMacro()
	local key = macroKey
	if key then
		-- Leerzeilen und Leerraum an den Enden entfernen
		local text = strtrim((editor.box:GetText():gsub("\r", ""):gsub("\n%s*\n", "\n")))
		CloseMacro()
		ns.SetBinding(key, "macro", text)
		ns.RefreshClicksPage()
	end
end

local function CreateMacroEditor(anchor)
	editor = CreateFrame("Frame", nil, page)
	editor:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
	editor:SetSize(620, 130)
	editor:Hide()
	ns.clicksUI.macro = editor

	editor.label = UI.Text(editor, "GameFontNormal")
	editor.label:SetPoint("TOPLEFT", 0, 0)
	editor.label:SetWidth(620)

	-- InputScrollFrameTemplate (Blizzard_SharedXML): mehrzeiliges Eingabefeld mit Bildlauf
	local scroll = CreateFrame("ScrollFrame", nil, editor, "InputScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", editor.label, "BOTTOMLEFT", 5, -10)
	scroll:SetSize(600, 64)
	editor.box = scroll.EditBox
	editor.box:SetWidth(582)   -- OnLoad rechnet mit der Breite vor SetSize
	editor.box:SetMaxLetters(MACRO_LETTERS)

	editor.accept = UI.Button(editor, ACCEPT, 110, AcceptMacro)
	editor.accept:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", -5, -10)
	editor.cancel = UI.Button(editor, CANCEL, 110, CloseMacro)
	editor.cancel:SetPoint("LEFT", editor.accept, "RIGHT", 8, 0)
end

lib.Popup.Confirm("QNUNITFRAMES_CLEAR", L["Alle Klickbelegungen für %s im aktiven Profil löschen?"], DELETE, function()
	wipe(ns.Bindings())
	ns.ApplyChange()
	ns.RefreshClicksPage()
end)

---------------------------------------------------------------------------
-- Zeilen
---------------------------------------------------------------------------

local function RowKey(row)
	return row.prefix .. button
end

local function SetKind(row, kind)
	local key = RowKey(row)
	local entry = Entry(key)
	if entry and entry.type == kind then
		return
	end
	ns.SetBinding(key, kind, "")
	ns.RefreshClicksPage()
	if kind == "macro" then
		EditMacro(key)
	end
end

local function CreateRow(i, prefix, anchor)
	local row = CreateFrame("Frame", nil, page)
	row.prefix = prefix
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, i == 1 and -12 or 0)
	row:SetPoint("RIGHT", page, "RIGHT", -16, 0)
	if i % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, 0.04)
	end

	row.label = UI.Text(row, "GameFontNormal", ns.ModifierText(prefix))
	row.label:SetPoint("LEFT", 6, 0)
	row.label:SetWidth(170)

	row.kind = UI.Dropdown(row, 170, ns.TYPES, function()
		local entry = Entry(RowKey(row))
		return entry and entry.type or ""
	end, function(kind)
		SetKind(row, kind)
	end)
	row.kind:SetPoint("LEFT", row.label, "RIGHT", 6, 0)

	row.spell = UI.Dropdown(row, 260, function()
		local entry = Entry(RowKey(row))
		return SpellEntries(entry and entry.value)
	end, function()
		local entry = Entry(RowKey(row))
		return entry and entry.value
	end, function(value)
		local key = RowKey(row)
		if value == OTHER then
			EditSpell(key)
			return
		end
		ns.SetBinding(key, "spell", value)
		ns.RefreshClicksPage()
	end, L["Zauber wählen …"], 400)
	row.spell:SetPoint("LEFT", row.kind, "RIGHT", 10, 0)

	row.macro = UI.Button(row, L["Bearbeiten …"], 110, function()
		EditMacro(RowKey(row))
	end)
	row.macro:SetHeight(22)
	row.macro:SetPoint("LEFT", row.kind, "RIGHT", 10, 0)
	row.macroText = UI.Text(row, "GameFontHighlightSmall")
	row.macroText:SetPoint("LEFT", row.macro, "RIGHT", 8, 0)
	row.macroText:SetPoint("RIGHT", row, "RIGHT", -6, 0)
	row.macroText:SetWordWrap(false)

	rows[i] = row
	return row
end

local function RefreshRow(row)
	local entry = Entry(RowKey(row))
	local kind = entry and entry.type or ""
	row.kind:Refresh()
	row.spell:SetShown(kind == "spell")
	if kind == "spell" then
		row.spell:Refresh()
	end
	row.macro:SetShown(kind == "macro")
	row.macroText:SetShown(kind == "macro")
	if kind == "macro" then
		local text = entry.value or ""
		row.macroText:SetText(text ~= "" and text:gsub("\n", " · ") or ("|cff808080" .. L["(leer)"] .. "|r"))
	end
end

function ns.RefreshClicksPage()
	if not (page and page:IsVisible()) then
		return
	end
	infoText:SetText(L["Belegung für %s im Profil %s"]:format(UnitClass("player"), lib.Profiles.GetLabel(lib.Profiles.GetActiveKey())))
	buttonDropdown:Refresh()
	for _, row in ipairs(rows) do
		RefreshRow(row)
	end
	-- Editor schließen, wenn sein Makro nicht mehr zur Anzeige passt (andere Maustaste, andere
	-- Aktion, Profilwechsel)
	if macroKey then
		local entry = Entry(macroKey)
		if not (entry and entry.type == "macro") or not macroKey:find(button .. "$") then
			CloseMacro()
		end
	end
end

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------

local function Build()
	local title = UI.Text(page, "GameFontNormalLarge", L["qnUnitFrames – Klickbelegung"])
	title:SetPoint("TOPLEFT", 16, -16)
	local desc = UI.Text(page, "GameFontHighlightSmall",
		L["Klicks auf Blizzards Gruppen- und Schlachtzugsrahmen wirken Zauber oder Makros auf das angeklickte Mitglied. Die Belegung gilt je Klasse und liegt im aktiven Profil (Layout des Bearbeitungsmodus). Im Kampf lässt sie sich nicht ändern; Änderungen folgen nach dem Kampf."])
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	desc:SetWidth(620)

	infoText = UI.Text(page, "GameFontNormal")
	infoText:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)

	buttonDropdown = UI.Dropdown(page, 200, ns.BUTTONS, function() return button end, function(v)
		button = v
		ns.RefreshClicksPage()
	end)
	buttonDropdown:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 110, -12)
	ns.clicksUI.button = buttonDropdown
	UI.Label(page, buttonDropdown, L["Maustaste:"])

	local clear = UI.Button(page, L["Alle löschen"], 140, function()
		StaticPopup_Show("QNUNITFRAMES_CLEAR", UnitClass("player"))
	end, L["Löscht alle Klickbelegungen der eigenen Klasse im aktiven Profil (alle Maustasten)."])
	clear:SetPoint("LEFT", buttonDropdown, "RIGHT", 20, 0)

	local anchor = CreateFrame("Frame", nil, page)
	anchor:SetSize(1, 1)
	anchor:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -44)
	local last = anchor
	for i, prefix in ipairs(ns.MODIFIERS) do
		last = CreateRow(i, prefix, last)
	end

	local hint = UI.Text(page, "GameFontHighlightSmall",
		L["'Blizzard-Standard' lässt den Klick unverändert (Linksklick: Ziel auswählen, Rechtsklick: Menü). Belegst du Linksklick ohne Zusatztaste mit einem Zauber, wählst du mit ihm kein Ziel mehr aus."])
	hint:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -14)
	hint:SetWidth(620)

	CreateMacroEditor(hint)

	page:SetScript("OnShow", ns.RefreshClicksPage)
end

function ns.InitClicksPage(category)
	page = CreateFrame("Frame")
	page:Hide()
	Build()
	sub = Settings.RegisterCanvasLayoutSubcategory(category, page, L["Klickbelegung"])
end

function ns.OpenClicksPage()
	lib.OpenCategory(sub)
end
