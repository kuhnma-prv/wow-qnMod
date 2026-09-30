-- qnLoadout: export the current state of the character as a set.
-- Every key of the numpad bar (normal actions and the switched-on Ctrl/Alt sets) with its spell (English
-- name from Spells.json, otherwise the ID plus the client name), macro (name) or empty; macro texts are
-- translated into English (Spells.lua); other content (items, mounts …) is left out.
-- Macros: the qn macros used on the bar and all qn character macros, with kind, icon and text.
-- Stored in qnLoadoutDB.exports[name] (compact JSON) and returned readable for copying.

local _, ns = ...
local L = ns.L
local J = ns.JsonObject

-- qnNumKeyPad sets to export: normal actions (nil) and the switched-on modifier sets
local function ExportedSets(nkp)
	local list = { false }
	for _, set in ipairs({ "ctrl", "alt" }) do
		if nkp.SetPage(set) then
			list[#list + 1] = set
		end
	end
	return list
end

local function NumpadEntries(macroNames, report)
	local nkp = qnNumKeyPad
	local entries = {}
	for _, set in ipairs(ExportedSets(nkp)) do
		set = set or nil
		for _, key in ipairs(nkp.GetLayout(nkp.db.layout).keys) do
			local slot = nkp.IsKeyShown(key) and nkp.SlotOfBinding(key.binding, set)
			if slot then
				local kind, text, id = nkp.SlotContent(slot)
				local entry
				if kind == "" then
					entry = J({ { "key", key.binding }, { "set", set }, { "empty", true } })
				elseif kind == "spell" and id then
					-- English name from Spells.json; otherwise the ID with the client name for reading
					local english = ns.EnglishSpellName(text)
					if english then
						entry = J({ { "key", key.binding }, { "set", set }, { "spell", english } })
					else
						entry = J({ { "key", key.binding }, { "set", set }, { "spell", id }, { "name", text } })
						report.untranslated[text] = true
					end
				elseif kind == "macro" then
					entry = J({ { "key", key.binding }, { "set", set }, { "macro", text } })
					macroNames[text] = true
				else
					report.other = report.other + 1
				end
				entries[#entries + 1] = entry
			end
		end
	end
	return entries
end

local function MacroEntry(index)
	local name, icon, body = GetMacroInfo(index)
	local perChar = index > Constants.MacroConsts.MAX_ACCOUNT_MACROS
	return J({ { "name", name }, { "scope", perChar and "char" or "account" }, { "icon", icon }, { "body", ns.MacroToEnglish(body or "") } })
end

local function MacroEntries(macroNames)
	local list, done = {}, {}
	local function Add(index)
		local name = GetMacroInfo(index)
		if name and ns.IsQnMacro(name) and not done[name] then
			done[name] = true
			list[#list + 1] = MacroEntry(index)
		end
	end
	-- all qn character macros, then the qn account macros used on the bar
	local account, character = GetNumMacros()
	local base = Constants.MacroConsts.MAX_ACCOUNT_MACROS
	for index = base + 1, base + character do
		Add(index)
	end
	for index = 1, account do
		if macroNames[GetMacroInfo(index)] then
			Add(index)
		end
	end
	return list
end

-- Returns the readable JSON and the report { other = number of left out slots, untranslated = { [client
-- spell name] = true } for spells without English name in Spells.json }.
function ns.Export(name)
	local report = { other = 0, untranslated = {} }
	local macroNames = {}
	local numpad = NumpadEntries(macroNames, report)
	local set = J({
		{ "name", name },
		{ "class", ns.PlayerClass() },
		{ "macros", MacroEntries(macroNames) },
		{ "numpad", numpad },
	})
	ns.db.exports[name] = { class = ns.PlayerClass(), time = time(), json = ns.ToJson(set) }
	return ns.ToJson(set, "  "), report
end
