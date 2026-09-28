-- qnInventory: Optionen im Blizzard-Einstellungsfenster (Settings-API), Seite "qnInventory".
-- Die Optionen gelten kontoweit (qnInventoryDB.options), nicht je Profil: Bestandsdaten
-- hängen an keinem Profil.
--   * Fraktionen: andere Fraktion in den Tooltips der Titan-Plugins bzw. in der Charakterauswahl
--     der Ansichten (beides Opt-in)
--   * Charakter löschen: gespeicherte Daten eines Charakters (dieser oder verbundener Realm)

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

local DELETE_POPUP = "QNINVENTORY_DELETE_CHAR"

-- Auswahl zum Löschen (nicht gespeichert); "" = keiner
local pick = { deleteChar = "" }

-- Alle gespeicherten Charaktere außer dem eingeloggten, beide Fraktionen
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

	S.Header(layout, L["Fraktionen"])
	B:Checkbox(category, "bothFactions", L["Tooltips: Allianz und Horde"],
		L["Die Tooltips der Titan-Plugins (Bank/Taschen und Gold) zeigen die Charaktere beider Fraktionen. Aus: nur die der Fraktion des eingeloggten Charakters. Die Fraktion eines Charakters ist bekannt, sobald er einmal mit dieser Version eingeloggt war; bis dahin erscheint er immer."],
		function() ns.DataChanged("chars") end)
	B:Checkbox(category, "viewsBothFactions", L["Taschen, Bank und Post: auch die andere Fraktion"],
		L["Die Charakterauswahl der Ansichten Taschen, Bank und Post enthält auch die Charaktere der anderen Fraktion. Aus: nur die der Fraktion des eingeloggten Charakters."],
		function() ns.DataChanged("chars") end)

	S.Header(layout, NARRATION_DELETE_CHARACTER_BUTTON)
	local D = S.New({ prefix = "QNINVENTORY_", source = function() return pick end, defaults = { deleteChar = "" } })
	D:Dropdown(category, "deleteChar", CHARACTER, DeleteEntries,
		L["Charakter, dessen gespeicherte Daten (Taschen, Bank, Post, Gold) gelöscht werden sollen. Der eingeloggte Charakter lässt sich nicht löschen."],
		Settings.VarType.String)

	qnCore.Popup.Confirm(DELETE_POPUP, L["Gespeicherte Daten von %s löschen?"], DELETE, function(key)
		local _, name, realm = ns.CharFromKey(key)
		if ns.DeleteChar(realm, name) then
			ns.Print(L["%s gelöscht."], realm == ns.realm and name or (name .. "-" .. realm))
		end
		D:Set("deleteChar", "")
	end)
	S.Button(layout, L["Ausgewählten Charakter löschen"], DELETE, function()
		local key = pick.deleteChar
		if key == "" then return end
		local char, name, realm = ns.CharFromKey(key)
		if not char then return end
		StaticPopup_Show(DELETE_POPUP, qnCore.ClassColoredName(realm == ns.realm and name or (name .. "-" .. realm), char.class), nil, key)
	end, L["Löscht nach einer Rückfrage die gespeicherten Daten des oben gewählten Charakters."])
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnInventory", Build)
end
