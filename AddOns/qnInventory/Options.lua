-- qnInventory: options in the Blizzard settings window (Settings API), page "qnInventory".
-- The options apply account-wide (qnInventoryDB.options), not per profile: inventory data
-- are not tied to any profile.
--   * Factions: other faction in the tooltips of the Titan plugins or in the character selection
--     of the views (both opt-in)
--   * Delete character: stored data of a character (this or a connected realm)

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

local DELETE_POPUP = "QNINVENTORY_DELETE_CHAR"

-- Selection for deletion (not saved); "" = none
local pick = { deleteChar = "" }

-- All stored characters except the logged-in one, both factions
local function DeleteEntries()
	local entries = { { "", NONE } }
	for _, e in ipairs(ns.CharEntries(true)) do
		if e[1] ~= ns.PlayerKey() then
			entries[#entries + 1] = e
		end
	end
	return entries
end

local function Build(category, layout)
	local B = S.New({ prefix = "QNINVENTORY_", source = function() return ns.options end,
		defaults = ns.OPTION_DEFAULTS })

	S.Header(layout, L["Factions"])
	B:Checkbox(category, "bothFactions", L["Tooltips: Alliance and Horde"],
		L["The tooltips of the Titan plugins (bank/bags and gold) show the characters of both factions. Off: only those of the logged-in character's faction. A character's faction is known once it has logged in with this version; until then it is always shown."],
		function() ns.DataChanged("chars") end)
	B:Checkbox(category, "viewsBothFactions", L["Bags, bank and mail: include the other faction"],
		L["The character selection of the bags, bank and mail views also contains the characters of the other faction. Off: only those of the logged-in character's faction."],
		function() ns.DataChanged("chars") end)

	S.Header(layout, NARRATION_DELETE_CHARACTER_BUTTON)
	local D = S.New({ prefix = "QNINVENTORY_", source = function() return pick end, defaults = { deleteChar = "" } })
	D:Dropdown(category, "deleteChar", CHARACTER, DeleteEntries,
		L["Character whose stored data (bags, bank, mail, gold) should be deleted. The logged-in character cannot be deleted."],
		Settings.VarType.String)

	qnCore.Popup.Confirm(DELETE_POPUP, L["Delete the stored data of %s?"], DELETE, function(key)
		local _, name, realm = ns.CharFromKey(key)
		if ns.DeleteChar(realm, name) then
			ns.Print(L["%s deleted."], realm == ns.realm and name or (name .. "-" .. realm))
		end
		D:Set("deleteChar", "")
	end)
	S.Button(layout, L["Delete selected character"], DELETE, function()
		local key = pick.deleteChar
		if key == "" then return end
		local char, name, realm = ns.CharFromKey(key)
		if not char then return end
		StaticPopup_Show(DELETE_POPUP, qnCore.ClassColoredName(realm == ns.realm and name or (name .. "-" .. realm), char.class), nil, key)
	end, L["Deletes the stored data of the character selected above after confirmation."])
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnInventory", Build)
end
