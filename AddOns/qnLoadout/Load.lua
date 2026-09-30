-- qnLoadout: load a set into the game.
--
-- Spell and item names in the set are English; macro texts and numpad spells are translated into the
-- client language on the way (Translate.lua). Item names are loaded first if needed.
-- 1. Macros: only qn macros (name prefix ns.PREFIX). An existing macro of the same name and kind
--    (account/character) is changed with EditMacro – it keeps its place on the action bars –,
--    otherwise it is created. Nothing is deleted.
-- 2. Numpad: every listed key gets its spell or macro or is cleared (empty); keys that are not
--    listed stay unchanged. Placing goes through qnNumKeyPad (bar's own slot, Ctrl/Alt set).
-- Only out of combat and with an empty cursor; the result is reported in the chat.

local _, ns = ...
local L = ns.L

local DEFAULT_ICON = 134400   -- question mark (INV_Misc_QuestionMark)

---------------------------------------------------------------------------
-- Macros
---------------------------------------------------------------------------

-- Index of the macro with this name among the account (perChar false) or character macros
function ns.FindMacro(name, perChar)
	local account, character = GetNumMacros()
	local base = Constants.MacroConsts.MAX_ACCOUNT_MACROS
	local first, last = 1, account
	if perChar then
		first, last = base + 1, base + character
	end
	for index = first, last do
		if GetMacroInfo(index) == name then
			return index
		end
	end
end

-- Character macro first, then account macro
local function AnyMacro(name)
	return ns.FindMacro(name, true) or ns.FindMacro(name, false)
end

local function HasRoom(perChar)
	local account, character = GetNumMacros()
	if perChar then
		return character < Constants.MacroConsts.MAX_CHARACTER_MACROS
	end
	return account < Constants.MacroConsts.MAX_ACCOUNT_MACROS
end

local function LoadMacros(set, report)
	for _, macro in ipairs(set.macros or {}) do
		local name, perChar = macro.name, macro.scope == "char"
		if not ns.IsQnMacro(name) then
			report.skipped[#report.skipped + 1] = L["Macro %s: the name must start with \"qn\"."]:format(tostring(name))
		else
			local index = ns.FindMacro(name, perChar)
			if index then
				EditMacro(index, name, macro.icon or DEFAULT_ICON, ns.MacroToClient(macro.body or ""))
				report.updated = report.updated + 1
			elseif ns.FindMacro(name, not perChar) then
				report.skipped[#report.skipped + 1] = (perChar
					and L["Macro %s: exists as an account macro – the set wants a character macro."]
					or L["Macro %s: exists as a character macro – the set wants an account macro."]):format(name)
			elseif not HasRoom(perChar) then
				report.skipped[#report.skipped + 1] = L["Macro %s: no free macro place."]:format(name)
			else
				CreateMacro(name, macro.icon or DEFAULT_ICON, ns.MacroToClient(macro.body or ""), perChar)
				report.created = report.created + 1
			end
		end
	end
end

---------------------------------------------------------------------------
-- Numpad
---------------------------------------------------------------------------

-- Display name of a numpad entry, e.g. "STRG-Num 3"
function ns.EntryKeyText(entry)
	local text = GetBindingText(entry.key)
	if entry.set == "ctrl" then
		return CTRL_KEY_TEXT .. "-" .. text
	elseif entry.set == "alt" then
		return ALT_KEY_TEXT .. "-" .. text
	end
	return text
end

local REASONS = {
	layout = L["%s: this key is not on the bar with the current keyboard layout."],
	off = L["%s: this set is switched off in qnNumKeyPad."],
	fixed = L["%s: keys 13 and higher do not switch with Ctrl or Alt."],
}

local function LoadNumpad(set, report)
	local nkp = qnNumKeyPad
	for _, entry in ipairs(set.numpad or {}) do
		local keyText = ns.EntryKeyText(entry)
		local slot, reason = nkp.SlotOfBinding(entry.key, entry.set)
		if not slot then
			report.skipped[#report.skipped + 1] = (REASONS[reason] or REASONS.layout):format(keyText)
		elseif entry.empty then
			nkp.ClearSlot(slot)
			report.cleared = report.cleared + 1
		elseif type(entry.spell) == "string" and not ns.ClientSpellName(entry.spell) then
			report.skipped[#report.skipped + 1] = L["%s: spell %s is not in Spells.json."]:format(keyText, entry.spell)
		elseif entry.spell ~= nil then
			-- English name -> name of the client language; an ID is used as it is
			local spell = type(entry.spell) == "string" and ns.ClientSpellName(entry.spell) or entry.spell
			if nkp.SetSlotSpell(slot, spell) then
				report.set = report.set + 1
			else
				report.skipped[#report.skipped + 1] = L["%s: spell %s is not known."]:format(keyText, tostring(entry.spell))
			end
		elseif entry.macro then
			local index = AnyMacro(entry.macro)
			if index and nkp.SetSlotMacro(slot, index) then
				report.set = report.set + 1
			else
				report.skipped[#report.skipped + 1] = L["%s: macro %s not found."]:format(keyText, entry.macro)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Load
---------------------------------------------------------------------------

local function DoLoad(set)
	if InCombatLockdown() then
		ns.Print(L["Sets cannot be loaded in combat."])
		return nil
	end
	if GetCursorInfo() then
		ns.Print(L["Something is on the cursor – place or drop it first."])
		return nil
	end
	local report = { created = 0, updated = 0, set = 0, cleared = 0, skipped = {} }
	-- items of the set's macros whose client name could not be loaded
	for _, english in ipairs(ns.MissingItems()) do
		for _, macro in ipairs(set.macros or {}) do
			if (macro.body or ""):find(english, 1, true) then
				report.skipped[#report.skipped + 1] = L["Item %s: name not loaded, stays in English in the macros."]:format(english)
				break
			end
		end
	end
	-- macros first: the numpad entries may refer to them
	LoadMacros(set, report)
	LoadNumpad(set, report)
	ns.Print(L["Set %s loaded: %d macros created, %d changed, %d numpad keys set, %d cleared."]:format(
		set.name, report.created, report.updated, report.set, report.cleared))
	for _, line in ipairs(report.skipped) do
		ns.Print(L["Skipped: %s"]:format(line))
	end
	return report
end

-- Loads the set once the item names are known (usually right away). Returns the report
-- { created, updated, set, cleared, skipped = { text, ... } } if it was loaded right away, otherwise nil
-- (not possible, or still waiting for item names - then the chat reports the result).
function ns.LoadSet(set)
	local report
	ns.WhenItemsLoaded(function()
		report = DoLoad(set)
	end)
	return report
end
