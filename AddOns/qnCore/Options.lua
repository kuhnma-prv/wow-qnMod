-- qnCore: options in Blizzard's settings window (Settings API).
-- Main page "qnCore" (profile, Minimap, Objective Tracker) and subpage "Bag Automation".
-- Bags and the tracking switch always apply account-wide (qnCoreDB.global), never per profile or character.
-- The Objective Tracker font applies per profile (ns.store).
-- The "Profiles" page is built by ProfilesPage.lua.

local _, ns = ...
local lib = qnCore
local L = ns.L
local S = lib.Settings

local function Build(category, layout)
	local Bags = ns.Bags

	-- Main page ----------------------------------------------------------
	local B = S.New({ prefix = "QNCORE_", source = function() return ns.global end, defaults = ns.defaults })

	S.Header(layout, L["Profile"])
	S.Button(layout, L["Settings profiles"], L["Profiles …"], function() ns.OpenProfiles() end,
		L["All qn addons store their settings per Edit Mode layout. The active profile changes with the layout – character-specific layouts included."])

	S.Header(layout, MINIMAP_LABEL)
	B:Checkbox(category, "tracking", L["Remember tracking"],
		L["Remembers per character what is checked or unchecked in the Minimap tracking menu (e.g. Find Herbs, Find Minerals, Find Treasure) and restores it after logging in, /reload, changing zones and resurrection. This switch applies to all characters."],
		function(_, value) ns.Tracking.OnOptionChanged(value) end)

	-- Objective Tracker (per profile) ----------------------------------------
	local QB = S.New({ store = ns.store, prefix = "QNCORE_", apply = function()
			ns.QuestTracker.Apply()
			ns.DamageMeter.Apply()
		end })
	local function SizeList(first, list)
		local sizes = { first }
		for _, size in ipairs(list) do
			sizes[#sizes + 1] = { size, tostring(size) }
		end
		return sizes
	end
	S.Header(layout, HUD_EDIT_MODE_OBJECTIVE_TRACKER_LABEL)
	QB:Dropdown(category, "questTextSize", HUD_EDIT_MODE_SETTING_OBJECTIVE_TRACKER_TEXT_SIZE,
		SizeList({ 0, L["As in Edit Mode"] }, ns.QuestTracker.SIZES),
		L["Objective Tracker text size below Blizzard's minimum of 12. \"As in Edit Mode\": Blizzard's slider applies. Saved per Edit Mode layout."],
		Settings.VarType.Number)
	QB:Dropdown(category, "questHeaderSize", L["Header size"],
		SizeList({ 0, L["Like the text"] }, ns.QuestTracker.HEADER_SIZES),
		L["Objective Tracker header size below Blizzard's minimum of 14. \"Like the text\": 2 larger than the text size (as in Edit Mode). Saved per Edit Mode layout."],
		Settings.VarType.Number)

	-- Damage Meter (per profile) ---------------------------------------------
	S.Header(layout, L["Damage Meter"])
	QB:Dropdown(category, "damageHeaderSize", L["Header size"],
		SizeList({ 0, L["As Blizzard"] }, ns.DamageMeter.SIZES),
		L["Font size of the header of the Damage Meter windows (timer, session, type). \"As Blizzard\": the default size. The header bar shrinks with it. Saved per Edit Mode layout."],
		Settings.VarType.Number)

	-- Bag Automation ---------------------------------------------------
	local bags, bagsLayout = Settings.RegisterVerticalLayoutSubcategory(category, L["Bag Automation"])

	local BB = S.New({
		prefix = "QNCORE_BAGS_",
		source = Bags.Config,
		defaults = Bags.defaults,
	})

	S.Header(bagsLayout, GENERAL)
	BB:Checkbox(bags, "enabled", L["Bag automation enabled"],
		L["Turn off if another bag addon handles opening and closing."])
	BB:Checkbox(bags, "openProfessionBags", L["Also open profession bags"],
		L["When all your bags open (B key, merchant, bank …), also open profession bags such as herb or enchanting bags and the reagent bag. Off: they stay closed; clicking one still opens it. With combined bags this only affects the reagent bag."])

	BB:Checkbox(bags, "hideGamepadBar", L["Hide the gamepad bag bar"],
		L["Forever shows a stray backpack icon at the top right of the combined bags (it covers the sort button and shows the ammo count). On: hides it as long as the gamepad interface is off."],
		Bags.ApplyGamepadBar)

	local same = BB:Checkbox(bags, "sameEverywhere", L["Same at every location"],
		L["On: one setting applies to every location (auction house, bank, merchant …). Off: each location is set up separately."])

	local Same, NotSame = BB:When("sameEverywhere"), BB:When("sameEverywhere", false)

	S.Depends(BB:Dropdown(bags, "allOpen", L["Everywhere: on open"], Bags.OPEN_MODES,
		L["What happens to your bags when one of the locations opens."], Settings.VarType.String), same, Same)
	S.Depends(BB:Checkbox(bags, "allClose", L["Everywhere: close all bags on close"]), same, Same)

	for _, v in ipairs(Bags.VENUES) do
		S.Header(bagsLayout, v.label)
		S.Depends(BB:Dropdown(bags, v.key .. "Open", L["%s: on open"]:format(v.label), Bags.OPEN_MODES,
			L["What happens to your bags when this location opens: %s."]:format(v.label), Settings.VarType.String), same, NotSame)
		S.Depends(BB:Checkbox(bags, v.key .. "Close", L["%s: close all bags on close"]:format(v.label)), same, NotSame)
	end
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnCore", Build)
end
