-- qnNumKeyPad: "Mouse Buttons" options page (canvas layout).
-- At the top the set (normal actions, Ctrl or Alt set), below it one row per assignable button of the
-- selected mouse (Mice.lua): button with the numpad key it sends, the kind of action (dropdown) and the spell from the spellbook or the macro. The choice is
-- placed directly into the bar's own action slot of that numpad key (PlaceAction) – the bar shows it
-- and WoW stores it per character like every action slot. Not in combat.

local _, ns = ...
local lib = qnCore
local L = ns.L
local UI = lib.UI

local page, parent, infoText, anchor, setDropdown
local set = ""   -- edited set: "" = normal actions, "ctrl", "alt"
local rows = {}
ns.mouseUI = { rows = rows }   -- for the tests

local ROW_HEIGHT = 34

---------------------------------------------------------------------------
-- Action slots
---------------------------------------------------------------------------

-- Content of an action slot: kind ("", "spell", "macro", "other") and display text;
-- for spells also the spell ID. Macros are recognized by their name (GetActionText): for a
-- macro that shows a spell, GetActionInfo returns the spell ID instead of the macro index.
function ns.SlotContent(slot)
	local actionType, id = GetActionInfo(slot)
	if not actionType or ns.IsSecret(actionType) then
		return ""
	end
	local text = GetActionText(slot)
	if ns.IsSecret(text) then
		text = nil
	end
	if actionType == "spell" and not ns.IsSecret(id) then
		return "spell", C_Spell.GetSpellName(id) or tostring(id), id
	elseif actionType == "macro" then
		return "macro", text or MACRO
	end
	return "other", text or actionType
end

-- Changes only out of combat and with an empty cursor (PlaceAction would swap with it).
local function CanChange()
	if InCombatLockdown() then
		ns.Print(L["Action slots cannot be changed in combat."])
		return false
	end
	if GetCursorInfo() then
		ns.Print(L["Something is on the cursor – place or drop it first."])
		return false
	end
	return true
end

-- pickup puts the new action on the cursor; PlaceAction puts it into the slot and the previous
-- action on the cursor, which ClearCursor drops.
local function Place(slot, pickup, value)
	if not CanChange() then
		return false
	end
	pickup(value)
	if GetCursorInfo() then
		PlaceAction(slot)
	end
	ClearCursor()
	return true
end

function ns.SetSlotSpell(slot, spellID)
	return Place(slot, C_Spell.PickupSpell, spellID)
end

function ns.SetSlotMacro(slot, macroIndex)
	return Place(slot, PickupMacro, macroIndex)
end

-- PickupAction takes the action out of the slot, ClearCursor drops it.
function ns.ClearSlot(slot)
	if not CanChange() then
		return false
	end
	PickupAction(slot)
	ClearCursor()
	return true
end

---------------------------------------------------------------------------
-- Choices
---------------------------------------------------------------------------

-- Active (non-passive) spells of the spellbook: { { spellID, name }, ... } sorted by name
function ns.SpellbookSpells()
	local seen, list = {}, {}
	local bank = Enum.SpellBookSpellBank.Player
	for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
		if info and not info.shouldHide and not info.offSpecID then
			for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
				local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
				local name = item and item.name
				local id = item and (item.spellID or item.actionID)
				if name and id and not ns.AnySecret(name, id) and item.itemType == Enum.SpellBookItemType.Spell
					and not item.isPassive and not seen[name] then
					seen[name] = true
					list[#list + 1] = { id, name }
				end
			end
		end
	end
	table.sort(list, function(a, b) return a[2] < b[2] end)
	return list
end

-- Account and character macros: { { index, name }, ... }
function ns.MacroList()
	local list = {}
	local account, character = GetNumMacros()
	local base = Constants.MacroConsts.MAX_ACCOUNT_MACROS
	local function Add(index)
		local name = GetMacroInfo(index)
		if name then
			list[#list + 1] = { index, name }
		end
	end
	for i = 1, account do
		Add(i)
	end
	for i = base + 1, base + character do
		Add(i)
	end
	return list
end

-- value of the entry whose name matches (nil = none)
local function FindByName(list, name)
	for _, entry in ipairs(list) do
		if entry[2] == name then
			return entry[1]
		end
	end
end

---------------------------------------------------------------------------
-- Rows
---------------------------------------------------------------------------

-- slot of the row in the edited set; otherwise nil and the reason (ns.SlotOfBinding)
local function RowSlot(row)
	if not row.binding then
		return nil
	end
	return ns.SlotOfBinding(row.binding, set ~= "" and set or nil)
end

-- normal actions and the switched-on modifier sets
local function SetEntries()
	local list = { { "", L["Normal actions"] } }
	if ns.SetPage("ctrl") then
		list[#list + 1] = { "ctrl", L["Ctrl set"] }
	end
	if ns.SetPage("alt") then
		list[#list + 1] = { "alt", L["Alt set"] }
	end
	return list
end

local function KindEntries(row)
	local list = { { "", EMPTY }, { "spell", L["Spell"] }, { "macro", MACRO } }
	local slot = RowSlot(row)
	if slot and ns.SlotContent(slot) == "other" then
		list[#list + 1] = { "other", OTHER }
	end
	return list
end

local function SetKind(row, kind)
	local slot = RowSlot(row)
	if not slot then
		return
	end
	row.pending = nil
	if kind == "" then
		ns.ClearSlot(slot)
	elseif kind ~= ns.SlotContent(slot) then
		-- the slot changes only once a spell or macro is chosen
		row.pending = kind
	end
	ns.RefreshMouseActions()
end

local function CreateRow(i)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", i == 1 and anchor or rows[i - 1], "BOTTOMLEFT", 0, i == 1 and -12 or 0)
	row:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	if i % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, 0.04)
	end

	row.label = UI.Text(row, "GameFontNormal")
	row.label:SetPoint("LEFT", 6, 0)
	row.label:SetWidth(170)

	row.kind = UI.Dropdown(row, 140, function() return KindEntries(row) end, function()
		local slot = RowSlot(row)
		return row.pending or (slot and ns.SlotContent(slot)) or ""
	end, function(kind)
		SetKind(row, kind)
	end)
	row.kind:SetPoint("LEFT", row.label, "RIGHT", 6, 0)

	row.spell = UI.Dropdown(row, 260, ns.SpellbookSpells, function()
		local slot = RowSlot(row)
		if not slot then
			return nil
		end
		local kind, name = ns.SlotContent(slot)
		return kind == "spell" and FindByName(ns.SpellbookSpells(), name) or nil
	end, function(id)
		row.pending = nil
		ns.SetSlotSpell(RowSlot(row), id)
		ns.RefreshMouseActions()
	end, L["Choose spell …"], 400)
	row.spell:SetPoint("LEFT", row.kind, "RIGHT", 10, 0)

	row.macro = UI.Dropdown(row, 260, ns.MacroList, function()
		local slot = RowSlot(row)
		if not slot then
			return nil
		end
		local kind, name = ns.SlotContent(slot)
		return kind == "macro" and FindByName(ns.MacroList(), name) or nil
	end, function(index)
		row.pending = nil
		ns.SetSlotMacro(RowSlot(row), index)
		ns.RefreshMouseActions()
	end, L["Choose macro …"], 400)
	row.macro:SetPoint("LEFT", row.kind, "RIGHT", 10, 0)

	-- other content (item, mount …) or why the row cannot be used
	row.note = UI.Text(row, "GameFontHighlightSmall")
	row.note:SetPoint("LEFT", row.kind, "RIGHT", 10, 0)
	row.note:SetPoint("RIGHT", row, "RIGHT", -6, 0)
	row.note:SetWordWrap(false)

	rows[i] = row
	return row
end

local function RefreshRow(row, mouse, button)
	row.button = button.id
	row.binding = ns.MouseBinding(mouse, button.id)
	row.label:SetText(("%s (%s)"):format(button.id, row.binding and GetBindingText(row.binding) or NONE_KEY))   -- do not translate
	local slot, reason = RowSlot(row)
	local kind, text = "", nil
	if slot then
		kind, text = ns.SlotContent(slot)
	else
		row.pending = nil
	end
	local shown = row.pending or kind
	row.kind:SetEnabled(slot ~= nil)
	row.kind:Refresh()
	row.spell:SetShown(shown == "spell")
	row.macro:SetShown(shown == "macro")
	if shown == "spell" then
		row.spell:Refresh()
	elseif shown == "macro" then
		row.macro:Refresh()
	end
	local note
	if not row.binding then
		note = L["No numpad key assigned (page \"Mouse\")."]
	elseif reason == "fixed" then
		note = L["Keys 13 and higher do not switch with Ctrl or Alt."]
	elseif not slot then
		note = L["This key is not on the bar with the current keyboard layout."]
	elseif shown == "other" then
		note = text
	end
	row.note:SetText(note or "")
	row.note:SetShown(note ~= nil)
	row:Show()
end

function ns.RefreshMouseActions()
	if not (page and page.panel:IsVisible()) then
		return
	end
	-- a set switched off in the meantime (or in another profile): back to the normal actions
	if set ~= "" and not ns.SetPage(set) then
		set = ""
	end
	setDropdown:Refresh()
	local mouse = ns.GetMouse(ns.store.global.mouse)
	setDropdown:SetShown(mouse ~= nil)
	local n = 0
	if mouse then
		infoText:SetText(L["Actions of the %s buttons for this character"]:format(mouse.name))
		for _, button in ipairs(mouse.buttons) do
			if not button.fixed then
				n = n + 1
				RefreshRow(rows[n] or CreateRow(n), mouse, button)
			end
		end
	else
		infoText:SetText(L["No mouse selected – choose one on the page \"Mouse\"."])
	end
	for i = n + 1, #rows do
		rows[i].pending = nil
		rows[i]:Hide()
	end
	page.Fit()
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------

function ns.InitMouseActions(category)
	page = UI.Page(L["Mouse Buttons"], { desc =
		L["Places a spell or macro into the action slot of the numpad key that a mouse button sends. The bar shows it right away; WoW stores action slots per character. The Ctrl set (page \"Action slots\") holds the actions for Ctrl + button. With stance switching, keys 1–12 use the stance bar's slots while in a stance – this page sets the bar's own slots. Not possible in combat."] })
	parent = page.content

	infoText = UI.Text(parent, "GameFontNormal")
	infoText:SetPoint("TOPLEFT", page.top, "BOTTOMLEFT", 0, -14)

	setDropdown = UI.Dropdown(parent, 200, SetEntries, function() return set end, function(v)
		set = v
		for _, row in ipairs(rows) do
			row.pending = nil
		end
		ns.RefreshMouseActions()
	end)
	setDropdown:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 110, -12)
	ns.mouseUI.set = setDropdown
	UI.Label(parent, setDropdown, L["Set:"])

	anchor = CreateFrame("Frame", nil, parent)
	anchor:SetSize(1, 1)
	anchor:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -44)

	page.panel:SetScript("OnShow", ns.RefreshMouseActions)
	ns.events.Register("ACTIONBAR_SLOT_CHANGED", ns.RefreshMouseActions)
	Settings.RegisterCanvasLayoutSubcategory(category, page.panel, L["Mouse Buttons"])
end
