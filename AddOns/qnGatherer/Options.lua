-- qnGatherer: options in Blizzard's settings window (Settings API).
--   qnGatherer   shown kinds, nodes of the guild / imports, minimap button
--   World Map    icons, size, opacity, fishing areas                       (profile)
--   Minimap      icons, edge, tooltips, size, opacity, tracking ring       (profile)
--   Filter       single resources per kind (canvas page, list of the known resources)
--   Fishing      sound boost                                               (profile)
--   Data         merge radius, database lock, cleanup, deleting            (account-wide)
-- Toggles of the slash command, the key bindings and the launchers go through ns.SetOption,
-- so that the settings window shows them too.

local ADDON, ns = ...
local L = ns.L
local S = qnCore.Settings
local UI = qnCore.UI
local DB, D = ns.DB, ns.Display

ns.builders = {}

local POPUP_ZONE = "QNGATHERER_DELETE_ZONE"
local POPUP_KIND = "QNGATHERER_DELETE_KIND"
local POPUP_ORIGIN = "QNGATHERER_DELETE_ORIGIN"

local function Apply()
	D.Refresh()
end

-- Kinds offered in the options: those whose gathering spell exists on the client
local function Kinds()
	local list = {}
	for _, key in ipairs(ns.KIND_ORDER) do
		if ns.KindAvailable(key) then
			list[#list + 1] = key
		end
	end
	return list
end
ns.OptionKinds = Kinds

local function VisibilityEntries()
	return {
		{ "always", ALWAYS },
		{ "profession", L["With the profession"] },
		{ "tracking", L["While tracking"] },
		{ "never", NEVER },
	}
end

-- Sets a value through the builder of the page (settings window shows it); builder = key in ns.builders
function ns.SetOption(builder, key, value)
	ns.builders[builder]:Set(key, value)
	D.Refresh()
end

function ns.ToggleMinimap()
	ns.SetOption("minimap", "show", not ns.db.minimap.show)
	ns.Print(ns.db.minimap.show and L["Minimap icons shown."] or L["Minimap icons hidden."])
end

function ns.ToggleWorldMap()
	ns.SetOption("worldMap", "show", not ns.db.worldMap.show)
	ns.Print(ns.db.worldMap.show and L["World map icons shown."] or L["World map icons hidden."])
end

function ns.ToggleSoundBoost()
	ns.SetOption("fishing", "soundBoost", not ns.db.soundBoost)
	ns.Print(ns.db.soundBoost and L["Sound boost while fishing on."] or L["Sound boost while fishing off."])
end

---------------------------------------------------------------------------
-- Data actions (also used by the slash command and the tests)
---------------------------------------------------------------------------

local Actions = {}
ns.Actions = Actions

local function LockedMessage(kind)
	ns.Print(L["The database of %s is locked."]:format(ns.KINDS[kind].name))
end

function Actions.Cleanup()
	local removed = 0
	for _, kind in ipairs(ns.KIND_ORDER) do
		removed = removed + DB.Cleanup(kind)
	end
	ns.Print(L["Cleanup finished: %d duplicate nodes removed."]:format(removed))
	return removed
end

function Actions.DeleteZone(kind, map)
	if DB.IsLocked(kind) then
		LockedMessage(kind)
		return 0
	end
	local count = DB.DeleteZone(kind, map)
	ns.Print(L["%d nodes deleted."]:format(count))
	return count
end

function Actions.ClearKind(kind)
	if not DB.ClearKind(kind) then
		LockedMessage(kind)
		return false
	end
	ns.Print(L["All nodes of %s deleted."]:format(ns.KINDS[kind].name))
	return true
end

function Actions.DeleteOrigin(origin)
	local count = DB.DeleteOrigin(origin)
	ns.Print(L["%d nodes deleted."]:format(count))
	return count
end

-- Current map of the player and its name
local function CurrentZone()
	local map = C_Map.GetBestMapForUnit("player")
	local info = map and C_Map.GetMapInfo(map)
	return map, info and info.name or UNKNOWN
end

---------------------------------------------------------------------------
-- Pages
---------------------------------------------------------------------------

local function BuildMain(cat, layout)
	local show = S.New({ store = ns.store, prefix = "QNGATHERER_SHOW_", apply = Apply,
		source = function() return ns.db.show end, defaults = ns.defaults.show })
	ns.builders.show = show
	S.Header(layout, L["Shown nodes"])
	for _, key in ipairs(Kinds()) do
		show:Dropdown(cat, key, ns.KINDS[key].name, VisibilityEntries,
			L["Always: always shown. With the profession: only if this character has the profession. While tracking: only while the matching minimap tracking (Find Herbs, Find Minerals …) is active. Never: hidden; nodes are still recorded."],
			Settings.VarType.String)
	end

	local origins = S.New({ store = ns.store, prefix = "QNGATHERER_ORIGINS_", apply = Apply,
		source = function() return ns.db.origins end, defaults = ns.defaults.origins })
	ns.builders.origins = origins
	S.Header(layout, L["Origin"])
	origins:Checkbox(cat, "guild", L["Show nodes found by your guild"])
	origins:Checkbox(cat, "import", L["Show imported nodes"])

	local launcher = S.New({ prefix = "QNGATHERER_LAUNCHER_", source = function() return DB.global.launcher end,
		defaults = DB.LAUNCHER_DEFAULTS, apply = function() ns.Launcher.Update() end })
	ns.builders.launcher = launcher
	S.Header(layout, L["Minimap button"])
	launcher:Checkbox(cat, "show", L["Show minimap button"],
		L["Left-click: journal. Shift-left-click: minimap icons on/off. Ctrl-left-click: world map icons on/off. Right-click: options. Drag to move it along the minimap. Applies to all characters."])
end

local function BuildWorldMap(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, WORLDMAP_BUTTON)
	local B = S.New({ store = ns.store, prefix = "QNGATHERER_WORLDMAP_", apply = Apply,
		source = function() return ns.db.worldMap end, defaults = ns.defaults.worldMap })
	ns.builders.worldMap = B
	B:Checkbox(cat, "show", L["Show icons on the world map"])
	B:Checkbox(cat, "clickable", L["Icons clickable"],
		L["Tooltip on mouse over and menu on right-click (delete, waypoint). Off: the icons let the mouse through to the map."])
	B:Slider(cat, "scale", L["Icon size"], 0.5, 3, 0.05, S.FractionFormatter)
	B:Slider(cat, "alpha", L["Icon opacity"], 0.1, 1, 0.05, S.FractionFormatter)
	B:Checkbox(cat, "areas", L["Show fishing areas"],
		L["Fishing areas as colored ellipses (learned from your catches or imported)."])
end

local function BuildMinimap(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, MINIMAP_LABEL)
	local B = S.New({ store = ns.store, prefix = "QNGATHERER_MINIMAP_", apply = Apply,
		source = function() return ns.db.minimap end, defaults = ns.defaults.minimap })
	ns.builders.minimap = B
	B:Checkbox(cat, "show", L["Show icons on the minimap"])
	B:Checkbox(cat, "tooltips", L["Tooltips on the minimap"],
		L["Tooltip on mouse over, left-click pings the place. Off: the icons let the mouse through."])
	B:Checkbox(cat, "edge", L["Show nodes on the edge"],
		L["Nodes outside the view slide along the edge of the minimap and fade out with the distance."])
	B:Slider(cat, "scale", L["Icon size"], 0.5, 3, 0.05, S.FractionFormatter)
	B:Slider(cat, "alpha", L["Icon opacity"], 0.1, 1, 0.05, S.FractionFormatter)

	local C = S.New({ store = ns.store, prefix = "QNGATHERER_CIRCLE_", apply = Apply,
		source = function() return ns.db.circle end, defaults = ns.defaults.circle })
	ns.builders.circle = C
	S.Header(layout, L["Tracking ring"])
	C:Dropdown(cat, "show", L["Show tracking ring"], VisibilityEntries,
		L["Within the tracking distance the icon becomes a ring in the color of the kind."], Settings.VarType.String)
	C:Slider(cat, "distance", L["Tracking distance (yards)"], 50, 240, 5)
	local colors = S.New({ store = ns.store, prefix = "QNGATHERER_COLOR_", apply = Apply,
		source = function() return ns.db.circle.colors end, defaults = ns.defaults.circle.colors })
	ns.builders.colors = colors
	for _, key in ipairs(Kinds()) do
		colors:Color(cat, key, ns.KINDS[key].name, L["Color of the tracking ring and of the areas."])
	end
end

local function BuildFishing(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, FISHING)
	local B = S.New({ store = ns.store, prefix = "QNGATHERER_FISHING_" })
	ns.builders.fishing = B
	B:Checkbox(cat, "soundBoost", L["Sound boost while fishing"],
		L["Turns the effect sound on and to full volume while you fish, so that the splash is easy to hear. Your settings are restored when the cast ends."])

	local M = S.New({ store = ns.store, prefix = "QNGATHERER_MINI_", source = function() return ns.db.mini end,
		defaults = ns.defaults.mini, apply = function() ns.Mini.Refresh() end })
	ns.builders.mini = M
	S.Header(layout, L["Info window"])
	M:Checkbox(cat, "fishing", L["Open while fishing"],
		L["Shows the zone, its skill range and the fish of the zone with your catches when you cast."])
	M:Checkbox(cat, "gathering", L["Open while gathering"],
		L["Shows the resources of the zone with the required skill when you gather herbs, ore or open chests."])
	M:Slider(cat, "delay", L["Close after (seconds)"], 3, 30, 1, nil,
		L["The window closes this long after the cast unless \"Keep open\" is checked (/qngatherer mini)."])
end

local function BuildData(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Data"])
	local kinds = Kinds()

	local radius = S.New({ prefix = "QNGATHERER_RADIUS_", source = function() return DB.global.radius end,
		defaults = DB.RADIUS_DEFAULTS })
	ns.builders.radius = radius
	S.Header(layout, L["Merge radius (yards)"])
	for _, key in ipairs(kinds) do
		radius:Slider(cat, key, ns.KINDS[key].name, 0, ns.KINDS[key].maxRadius, 1, nil,
			L["Nodes of the same resource within this distance count as one node. After a change, clean up the database."])
	end
	S.Button(layout, L["Clean up database"], L["Clean up"], function()
		Actions.Cleanup()
	end, L["Merges nodes within the merge radius again and removes unreadable entries. Locked kinds stay untouched."])

	local locks = S.New({ prefix = "QNGATHERER_LOCK_", source = function() return DB.global.locks end,
		defaults = DB.LOCK_DEFAULTS })
	ns.builders.locks = locks
	S.Header(layout, L["Database lock"])
	for _, key in ipairs(kinds) do
		locks:Checkbox(cat, key, ns.KINDS[key].name,
			L["Locked: nothing is added, deleted, cleaned up or imported for this kind."])
	end

	local first = kinds[1] or ns.KIND_ORDER[1]
	local pick = { kind = first }
	local P = S.New({ prefix = "QNGATHERER_PICK_", source = function() return pick end, defaults = { kind = first } })
	S.Header(layout, DELETE)
	P:Dropdown(cat, "kind", L["Kind"], function()
		local list = {}
		for _, key in ipairs(kinds) do
			list[#list + 1] = { key, ns.KINDS[key].name }
		end
		return list
	end, nil, Settings.VarType.String)
	qnCore.Popup.Confirm(POPUP_ZONE, L["Delete all nodes of %s in %s?"], DELETE, function(data)
		Actions.DeleteZone(data.kind, data.map)
	end)
	qnCore.Popup.Confirm(POPUP_KIND, L["Delete all stored nodes of %s?"], DELETE, function(kind)
		Actions.ClearKind(kind)
	end)
	qnCore.Popup.Confirm(POPUP_ORIGIN, "%s", DELETE, function(origin)
		Actions.DeleteOrigin(origin)
	end)
	S.Button(layout, L["Delete in the current zone"], DELETE, function()
		local map, name = CurrentZone()
		if map then
			StaticPopup_Show(POPUP_ZONE, ns.KINDS[pick.kind].name, name, { kind = pick.kind, map = map })
		end
	end, L["Deletes all nodes of the selected kind in the zone you are in. They do not come back through the guild or an import."])
	S.Button(layout, L["Delete all nodes of the kind"], DELETE, function()
		StaticPopup_Show(POPUP_KIND, ns.KINDS[pick.kind].name, nil, pick.kind)
	end, L["Deletes all stored nodes and areas of the selected kind."])
	S.Button(layout, L["Remove guild data"], REMOVE, function()
		StaticPopup_Show(POPUP_ORIGIN, L["Remove all nodes found by your guild?"], nil, "guild:")
	end)
	S.Button(layout, L["Remove imported data"], REMOVE, function()
		StaticPopup_Show(POPUP_ORIGIN, L["Remove all imported nodes?"], nil, "import:")
	end)
end

---------------------------------------------------------------------------
-- Import page: adapters of other addons, text export/import (account-wide)
---------------------------------------------------------------------------

local POPUP_EXPORT = "QNGATHERER_EXPORT"
local POPUP_IMPORT_TEXT = "QNGATHERER_IMPORT_TEXT"
local IMPORT_BUTTON = COOLDOWN_VIEWER_SETTINGS_IMPORT_LAYOUT   -- "Import"

-- Imports from adapter key with the mode chosen on the page; message if its data is missing
function Actions.Import(key, mode)
	local adapter = ns.Import.Get(key)
	if not adapter then
		return nil
	end
	if not adapter.Available() then
		ns.Print(L["No data of %s found. It has to be loaded; for addons that do not load on Forever use the offline tool (tools\\Convert-QnGatherer.ps1)."]:format(adapter.name))
		return nil
	end
	return ns.Import.Run(key, { mode = mode })
end

local function BuildImport(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, IMPORT_BUTTON)
	local pick = { mode = "merge" }
	local P = S.New({ prefix = "QNGATHERER_IMPORTMODE_", source = function() return pick end, defaults = { mode = "merge" } })
	S.Header(layout, L["Other addons"])
	P:Dropdown(cat, "mode", L["Import mode"], {
		{ "merge", L["Merge"], L["Adds what is new; nodes you deleted stay deleted."] },
		{ "replace", REPLACE, L["First removes everything imported from this addon before, then imports again."] },
	}, nil, Settings.VarType.String)
	for _, adapter in ipairs(ns.Import.adapters) do
		S.Button(layout, adapter.name, IMPORT_BUTTON, function()
			Actions.Import(adapter.key, pick.mode)
		end, L["Imports the data of %s (nodes, areas, zone information) as \"imported\". The addon has to be loaded."]:format(adapter.name))
	end
	local auto = S.New({ prefix = "QNGATHERER_IMPORTOPT_", source = function() return DB.global.importOptions end,
		defaults = { auto = false } })
	ns.builders.importOptions = auto
	auto:Checkbox(cat, "auto", L["Import automatically"],
		L["On login, imports again from every loaded addon whose data version changed since the last import."])

	S.Header(layout, L["Exchange with other qnGatherer users"])
	qnCore.Popup.EditText(POPUP_EXPORT, L["Copy the text (Ctrl+C):"], function() return ns.Import.Export() end, function() end, 1000000)
	qnCore.Popup.EditText(POPUP_IMPORT_TEXT, L["Paste an export text (Ctrl+V):"], function() return "" end,
		function(text) ns.Import.FromText(text) end, 1000000)
	S.Button(layout, L["Export your nodes"], L["Export"], function()
		StaticPopup_Show(POPUP_EXPORT)
	end, L["Your own nodes and fishing areas as text for another qnGatherer."])
	S.Button(layout, L["Import an export text"], IMPORT_BUTTON, function()
		StaticPopup_Show(POPUP_IMPORT_TEXT)
	end, L["Imports the text of another qnGatherer as \"imported\"."])
end

---------------------------------------------------------------------------
-- Guild page: exchange of nodes with the guild (account-wide)
---------------------------------------------------------------------------

local POPUP_IGNORE = "QNGATHERER_SYNC_IGNORE"

-- Ignore list as text "Name-Realm, Name2" and back
function ns.IgnoreText()
	return table.concat(DB.global.sync.ignore, ", ")
end

function ns.SetIgnoreText(text)
	local list = {}
	for name in tostring(text or ""):gmatch("[^,;%s]+") do
		list[#list + 1] = name
	end
	DB.global.sync.ignore = list
end

local function BuildSync(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, GUILD)
	local B = S.New({ prefix = "QNGATHERER_SYNC_", source = function() return DB.global.sync end,
		defaults = { enabled = true, relayGuild = false, shareImports = false },
		apply = function() ns.Sync.OptionsChanged() end })
	ns.builders.sync = B
	B:Checkbox(cat, "enabled", L["Exchange nodes with your guild"],
		L["Sends the nodes you find to the guild members who use qnGatherer and takes over theirs (shown as \"Found by …\"). Nothing is deleted through the exchange; nodes you deleted stay deleted."])
	B:Checkbox(cat, "relayGuild", L["Pass on nodes found by your guild"],
		L["Members who come online later also get the nodes you received from others. Off: only your own nodes are sent."])
	B:Checkbox(cat, "shareImports", L["Share imported data"],
		L["Also sends the nodes you imported from other addons."])
	qnCore.Popup.EditText(POPUP_IGNORE, L["Ignore these members (Name-Realm, separated by commas):"], ns.IgnoreText, ns.SetIgnoreText)
	S.Button(layout, L["Ignored members"], L["Edit …"], function()
		StaticPopup_Show(POPUP_IGNORE)
	end, L["Nothing is taken over from these members."])
	S.Button(layout, STATUS, SHOW, function()
		ns.Sync.Status()
	end, L["Shows in the chat how many members use qnGatherer and how many nodes were exchanged (/qngatherer sync)."])
end

---------------------------------------------------------------------------
-- Filter page (canvas): one checkbox per known resource, grouped by kind
---------------------------------------------------------------------------

local filterPage
local rows = {}

local function Filter(kind)
	local f = ns.db.filter[kind]
	if not f then
		f = {}
		ns.db.filter[kind] = f
	end
	return f
end

-- Known resources of kind sorted by name: { { res, name }, ... }
function ns.FilterEntries(kind)
	local list = {}
	for res, entry in pairs(DB.global.catalog) do
		if entry.kind == kind then
			list[#list + 1] = { res, D.ResourceName(res) }
		end
	end
	table.sort(list, function(a, b) return a[2] < b[2] end)
	return list
end

-- Shows all or no resources of kind
function ns.SetFilterAll(kind, shown)
	local f = Filter(kind)
	for _, e in ipairs(ns.FilterEntries(kind)) do
		if shown then
			f[e[1]] = nil   -- nil = shown (default)
		else
			f[e[1]] = false
		end
	end
	D.Refresh()
end

local function Row(i)
	local row = rows[i]
	if not row then
		row = {}
		row.header = UI.Text(filterPage.content, "GameFontNormal", "")
		row.check = CreateFrame("CheckButton", nil, filterPage.content, "UICheckButtonTemplate")
		row.check:SetSize(24, 24)
		row.label = UI.Text(filterPage.content, "GameFontHighlight", "")
		row.label:SetPoint("LEFT", row.check, "RIGHT", 4, 0)
		row.all = UI.Button(filterPage.content, ALL, 80, function() ns.SetFilterAll(row.kind, true) filterPage.Rebuild() end)
		row.none = UI.Button(filterPage.content, NONE, 80, function() ns.SetFilterAll(row.kind, false) filterPage.Rebuild() end)
		row.check:SetScript("OnClick", function(self)
			if self:GetChecked() then
				Filter(row.kind)[row.res] = nil
			else
				Filter(row.kind)[row.res] = false
			end
			D.Refresh()
		end)
		rows[i] = row
	end
	return row
end

local function HideRow(row)
	row.header:Hide()
	row.check:Hide()
	row.label:Hide()
	row.all:Hide()
	row.none:Hide()
end

local function BuildFilter(category)
	filterPage = UI.Page(FILTER, {
		desc = L["Hide single resources on the world map and the minimap. The list contains the resources you have gathered, imported or received from your guild. Hidden resources are still recorded."],
		defaults = function()
			wipe(ns.db.filter)
			D.Refresh()
			filterPage.Rebuild()
		end,
	})
	function filterPage.Rebuild()
		for _, row in ipairs(rows) do
			HideRow(row)
		end
		local i, anchor, y = 0, filterPage.top, -12
		local empty = true
		for _, kind in ipairs(Kinds()) do
			local entries = ns.FilterEntries(kind)
			if #entries > 0 then
				empty = false
				i = i + 1
				local head = Row(i)
				head.kind = kind
				head.header:SetText(ns.KINDS[kind].name)
				head.header:ClearAllPoints()
				head.header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
				head.header:Show()
				head.all:ClearAllPoints()
				head.all:SetPoint("LEFT", head.header, "LEFT", 220, 0)
				head.all:Show()
				head.none:ClearAllPoints()
				head.none:SetPoint("LEFT", head.all, "RIGHT", 6, 0)
				head.none:Show()
				anchor, y = head.header, -8
				local filter = Filter(kind)
				for _, e in ipairs(entries) do
					i = i + 1
					local row = Row(i)
					row.kind, row.res = kind, e[1]
					row.check:ClearAllPoints()
					row.check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
					row.check:SetChecked(filter[e[1]] ~= false)
					row.check:Show()
					row.label:SetText(e[2])
					row.label:Show()
					anchor, y = row.check, 0
				end
				y = -14
			end
		end
		filterPage.empty = filterPage.empty or UI.Text(filterPage.content, "GameFontDisable", L["No resources known yet."])
		filterPage.empty:ClearAllPoints()
		filterPage.empty:SetPoint("TOPLEFT", filterPage.top, "BOTTOMLEFT", 0, -12)
		filterPage.empty:SetShown(empty)
		filterPage.Fit()
	end
	filterPage.panel:SetScript("OnShow", filterPage.Rebuild)
	Settings.RegisterCanvasLayoutSubcategory(category, filterPage.panel, FILTER)
end

---------------------------------------------------------------------------

local function Build(category, layout)
	BuildMain(category, layout)
	BuildWorldMap(category)
	BuildMinimap(category)
	BuildFilter(category)
	BuildFishing(category)
	BuildData(category)
	BuildImport(category)
	BuildSync(category)
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnGatherer", Build)
end

---------------------------------------------------------------------------
-- Slash command (English only)
---------------------------------------------------------------------------

local HELP = L["qnGatherer commands:\n/qngatherer - journal\n/qngatherer options - options\n/qngatherer mini - info window: keep open on/off\n/qngatherer minimap - minimap icons on/off\n/qngatherer worldmap - world map icons on/off\n/qngatherer sound - sound boost while fishing on/off\n/qngatherer sync - status of the guild exchange\n/qngatherer cleanup - clean up the database\n/qngatherer help - this help"]

function ns.InitSlash()
	qnCore.RegisterSlash("QNGATHERER", { "/qngatherer", "/qng" }, function(cmd)
		if cmd == "" or cmd == "journal" then
			ns.Journal.Toggle()
		elseif cmd == "options" then
			ns.OpenOptions()
		elseif cmd == "mini" then
			ns.Mini.TogglePinned()
		elseif cmd == "minimap" then
			ns.ToggleMinimap()
		elseif cmd == "worldmap" then
			ns.ToggleWorldMap()
		elseif cmd == "sound" then
			ns.ToggleSoundBoost()
		elseif cmd == "sync" then
			ns.Sync.Status()
		elseif cmd == "cleanup" then
			Actions.Cleanup()
		else
			ns.Print(HELP)
		end
	end)
end

-- Key bindings (Bindings.xml)
BINDING_HEADER_QNGATHERER = "qnGatherer"   -- do not translate
BINDING_NAME_QNGATHERER_JOURNAL = L["Open/close the journal"]
BINDING_NAME_QNGATHERER_TOGGLE_MINIMAP = L["Minimap icons on/off"]
BINDING_NAME_QNGATHERER_TOGGLE_WORLDMAP = L["World map icons on/off"]
