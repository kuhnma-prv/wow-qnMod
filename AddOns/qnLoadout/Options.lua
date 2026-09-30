-- qnLoadout: options page (canvas layout) in Blizzard's settings window.
-- Top: choice among the sets of the player's class, summary, "Load set" (with confirmation).
-- Bottom: export of the current state under a name; the JSON appears in a text field for copying and
-- is stored in the saved variable (Convert-QnLoadout.ps1 -Import).

local _, ns = ...
local lib = qnCore
local L = ns.L
local UI = lib.UI

local page, infoText, setDropdown, summary, loadButton, nameBox, output
ns.ui = {}   -- for the tests

local function ClassName()
	return (UnitClass("player"))
end

-- chosen set of the player's class (remembered per class), otherwise the first one
function ns.SelectedSet()
	local class = ns.PlayerClass()
	return ns.FindSet(class, ns.db.lastSet[class]) or ns.SetsForClass(class)[1]
end

local function SetEntries()
	local list = {}
	for _, set in ipairs(ns.SetsForClass(ns.PlayerClass())) do
		list[#list + 1] = { set.name, set.name }
	end
	return list
end

local function Refresh()
	if not (page and page.panel:IsVisible()) then
		return
	end
	local set = ns.SelectedSet()
	if set then
		infoText:SetText(L["Sets for %s:"]:format(ClassName()))
		local lines = {}
		if set.desc and set.desc ~= "" then
			lines[#lines + 1] = set.desc
		end
		lines[#lines + 1] = L["%d macros, %d numpad keys"]:format(#(set.macros or {}), #(set.numpad or {}))
		summary:SetText(table.concat(lines, "\n"))
	else
		infoText:SetText(L["No sets for %s. Sets come from AddOns\\qnLoadout\\Sets (JSON, converted with tools\\Convert-QnLoadout.ps1)."]:format(ClassName()))
		summary:SetText("")
	end
	setDropdown:SetShown(set ~= nil)
	loadButton:SetShown(set ~= nil)
	setDropdown:Refresh()
	page.Fit()
end
ns.RefreshOptions = Refresh

lib.Popup.Confirm("QNLOADOUT_LOAD", L["Load set %s?\nqn macros are created or changed and the numpad keys of the set are assigned for this character."], L["Load"], function()
	local set = ns.SelectedSet()
	if set then
		ns.LoadSet(set)
	end
end)

local function ShowExport(name)
	local json, report = ns.Export(name)
	output.box:SetText(json)
	output:Show()
	output.box:SetFocus()
	output.box:HighlightText()
	local untranslated = {}
	for spell in pairs(report.untranslated) do
		untranslated[#untranslated + 1] = spell
	end
	if #untranslated > 0 then
		table.sort(untranslated)
		ns.Print(L["Spells without English name in Spells.json (exported by ID): %s"]:format(table.concat(untranslated, ", ")))
	end
	local missing = ns.MissingItems()
	if #missing > 0 then
		ns.Print(L["Item names not loaded, not translated into English: %s"]:format(table.concat(missing, ", ")))
	end
	if report.other > 0 then
		ns.Print(L["%d slots with other content (items, mounts …) were left out."]:format(report.other))
	end
	ns.Print(L["Exported as %s. After logging out or /reload, tools\\Convert-QnLoadout.ps1 -Import writes it into Sets as a JSON file."]:format(name))
	page.Fit()
end

-- item names are needed to translate the macro texts into English
local function DoExport()
	local name = strtrim(nameBox:GetText() or "")
	if name == "" then
		ns.Print(L["Enter a name for the export."])
		return
	end
	ns.WhenItemsLoaded(function()
		ShowExport(name)
	end)
end

local function Build()
	page = UI.Page("qnLoadout", { desc =
		L["Loads a set of qn macros and numpad assignments (qnNumKeyPad) for your class. Only macros whose name starts with \"qn\" are created or changed – other macros stay untouched, nothing is deleted. Numpad keys listed in the set are assigned or cleared, all others stay unchanged. Not possible in combat."] })
	local parent = page.content
	ns.ui.panel = page.panel

	infoText = UI.Text(parent, "GameFontNormal")
	infoText:SetPoint("TOPLEFT", page.top, "BOTTOMLEFT", 0, -14)
	infoText:SetWidth(600)

	setDropdown = UI.Dropdown(parent, 300, SetEntries, function()
		local set = ns.SelectedSet()
		return set and set.name
	end, function(name)
		ns.db.lastSet[ns.PlayerClass()] = name
		Refresh()
	end)
	setDropdown:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 110, -12)
	UI.Label(parent, setDropdown, L["Set:"])
	ns.ui.set = setDropdown

	loadButton = UI.Button(parent, L["Load set"], 140, function()
		local set = ns.SelectedSet()
		if set then
			StaticPopup_Show("QNLOADOUT_LOAD", set.name)
		end
	end)
	loadButton:SetPoint("LEFT", setDropdown, "RIGHT", 20, 0)
	ns.ui.load = loadButton

	summary = UI.Text(parent, "GameFontHighlightSmall")
	summary:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -48)
	summary:SetWidth(600)
	ns.ui.summary = summary

	-- Export ---------------------------------------------------------------
	local exportTitle = UI.Text(parent, "GameFontNormal", L["Export"])
	exportTitle:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -28)
	local exportDesc = UI.Text(parent, "GameFontHighlightSmall",
		L["Saves the numpad assignments of this character (normal actions and the switched-on Ctrl/Alt sets) and its qn macros as a set: spells by ID, macros by name. Items and other content are left out."])
	exportDesc:SetPoint("TOPLEFT", exportTitle, "BOTTOMLEFT", 0, -8)
	exportDesc:SetWidth(600)

	nameBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	nameBox:SetSize(250, 22)
	nameBox:SetAutoFocus(false)
	nameBox:SetMaxLetters(60)
	nameBox:SetPoint("TOPLEFT", exportDesc, "BOTTOMLEFT", 115, -14)
	nameBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		DoExport()
	end)
	UI.Label(parent, nameBox, HOUSING_NEIGHBORHOOD_SETTINGS_NAME, 14)   -- Blizzard "Name:"
	ns.ui.name = nameBox

	local exportButton = UI.Button(parent, L["Export"], 140, DoExport)
	exportButton:SetPoint("LEFT", nameBox, "RIGHT", 16, 0)
	ns.ui.export = exportButton

	-- InputScrollFrameTemplate (Blizzard_SharedXML): multi-line text field with scrolling
	output = CreateFrame("ScrollFrame", nil, parent, "InputScrollFrameTemplate")
	output:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", -110, -16)
	output:SetSize(600, 220)
	output.box = output.EditBox
	output.box:SetWidth(582)   -- OnLoad calculates with the width before SetSize
	output.box:SetMaxLetters(0)
	output:Hide()
	ns.ui.output = output

	page.panel:SetScript("OnShow", function()
		if (nameBox:GetText() or "") == "" then
			nameBox:SetText(("%s %s"):format(ClassName(), UnitName("player")))   -- do not translate
		end
		Refresh()
	end)
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	Build()
	lib.Settings.NewCategory(ns, "qnLoadout", function() end, page.panel)
end
