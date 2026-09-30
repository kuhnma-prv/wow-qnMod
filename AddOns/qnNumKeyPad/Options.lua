-- qnNumKeyPad: options in the Blizzard settings window (Settings API).
-- The settings belong to the active profile (qnCore); after a profile switch
-- qnCore reloads the controls.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

-- Values from slash commands and buttons are set via ns.store:Set or ns.store:SetValues (qnCore):
-- that way the settings window shows them too; SetValues applies several values with a single
-- ns.Apply (otherwise the bar would briefly sit at an intermediate spot, e.g. new x with old y).

---------------------------------------------------------------------------
-- Custom visibility condition (macro conditions for the "visibility" state driver)
---------------------------------------------------------------------------

qnCore.Popup.EditText("QNNUMKEYPAD_CUSTOM", L["Custom visibility condition (macro syntax, e.g. [combat] show; hide):"],
	function() return ns.db.custom end,
	function(text) ns.store:Set("custom", text) end, 500)

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------

local PAGES = {
	{ 1, L["Page 1 – Action Bar 1"] },
	{ 2, L["Page 2 – Action Bar 1, second page"] },
	{ 3, L["Page 3 – Action Bar 4 (right)"] },
	{ 4, L["Page 4 – Action Bar 5 (right)"] },
	{ 5, L["Page 5 – Action Bar 3 (bottom right)"] },
	{ 6, L["Page 6 – Action Bar 2 (bottom left)"] },
	{ 7, L["Page 7 – Stance/Form 1"] },
	{ 8, L["Page 8 – Stance/Form 2"] },
	{ 9, L["Page 9 – Stance/Form 3"] },
	{ 10, L["Page 10 – Stance/Form 4"] },
	{ 13, L["Page 13 – Action Bar 6"] },
	{ 14, L["Page 14 – Action Bar 7"] },
	{ 15, L["Page 15 – Action Bar 8"] },
}

local function LayoutEntries()
	local list = {}
	for _, layout in ipairs(ns.LAYOUTS) do
		list[#list + 1] = { layout.id, layout.name }
	end
	return list
end

---------------------------------------------------------------------------
-- Mouse (account-wide, Mice.lua)
---------------------------------------------------------------------------

local function MouseEntries()
	local list = { { ns.MOUSE_NONE, NONE_KEY } }
	for _, mouse in ipairs(ns.MICE) do
		list[#list + 1] = { mouse.id, mouse.name }
	end
	return list
end

local function KeyEntries()
	local list = { { "", NONE_KEY } }
	for _, key in ipairs(ns.NUMPAD_KEYS) do
		list[#list + 1] = { key, GetBindingText(key) }
	end
	return list
end

local function BuildMouse(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Mouse"])
	-- not per profile: the assignment belongs to the mouse, not to the Edit Mode layout
	local global = ns.store.global
	local MB = S.New({ prefix = "QNNKP_", source = function() return global end, defaults = { mouse = ns.MOUSE_NONE } })

	S.Header(layout, L["Gaming mouse"])
	local device = MB:Dropdown(cat, "mouse", L["Mouse"], MouseEntries(),
		L["Mouse whose buttons send numeric keypad keys. Applies to all characters and profiles."])

	local keys = KeyEntries()
	local fixedTip = L["Cannot be changed: the mouse always uses this button for clicking."]
	local keyTip = L["Numeric keypad key that the mouse software (e.g. Logitech G HUB) assigns to this button."]
	for _, mouse in ipairs(ns.MICE) do
		local function Selected()
			return global.mouse == mouse.id
		end
		local function Never()
			return false
		end
		local BB = S.New({
			prefix = "QNNKP_" .. mouse.id .. "_",
			source = function() return ns.MouseButtons(mouse.id) end,
			defaults = ns.MouseDefaults(mouse),
		})
		S.Header(layout, L["Button assignment – %s"]:format(mouse.name))
		for _, button in ipairs(mouse.buttons) do
			if button.fixed then
				-- shown like the others, but always disabled; stores nothing
				local setting = Settings.RegisterProxySetting(cat, BB.prefix .. button.id, Settings.VarType.String,
					button.id, "fixed", function() return "fixed" end, function() end)
				S.Depends(S.Dropdown(cat, setting, { { "fixed", button.fixed } }, fixedTip), device, Never)
			else
				S.Depends(BB:Dropdown(cat, button.id, button.id, keys, keyTip), device, Selected)
			end
		end
	end
end

local function Never()
	return false
end

local function Build(category, layout)
	local B = S.New({ store = ns.store, prefix = "QNNKP_", apply = ns.Apply })
	-- Settings that determine which pages are used: check the pages afterwards
	local check = ns.ApplyAndCheck

	-- General -------------------------------------------------------------
	local cat = category
	S.Header(layout, GENERAL)
	B:Checkbox(cat, "enabled", L["Numpad enabled"],
		L["Off: bar hidden and all numpad keybinds removed."])
	B:Checkbox(cat, "locked", L["Lock position"],
		L["Prevents accidental moving. When unlocked, the bar shows a green area for dragging; right-clicking it opens these options."])
	B:Checkbox(cat, "lockActions", L["Always lock actions"],
		L["Actions can only be dragged out with the 'Pick Up Action' key (default: Shift). Works in addition to the Blizzard option 'Lock Action Bars'."])
	B:Checkbox(cat, "lockInCombat", L["Lock actions in combat"],
		L["Prevents accidentally dragging actions out during combat."])

	S.Header(layout, L["Keyboard"])
	B:Dropdown(cat, "layout", L["Keyboard layout"], LayoutEntries(), nil, nil, check)
	B:Checkbox(cat, "showEnter", L["Show Enter key"],
		L["Warning: binds Enter and thereby unbinds 'Open Chat' while the numpad is active."], check)
	B:Checkbox(cat, "showNav", L["Show navigation keys"],
		L["Insert, Home, Page Up/Down, Delete, End. Overrides their current bindings (chat scroll, camera)."], check)
	-- switched off for now: page 15 (keys 25-28) belongs to the Ctrl set (Core.lua Sanitize)
	B:Checkbox(cat, "showArrow", L["Show arrow keys"],
		L["Not available for now: the arrow keys would need page 15, which the Ctrl set uses."], check):AddModifyPredicate(Never)
	B:Checkbox(cat, "bindShift", L["Also bind with Shift"],
		L["Shift+key triggers the same action. Prevents Shift+numpad from triggering the default bindings (e.g. action bar paging)."])
	B:Checkbox(cat, "stance", L["Stance switching"],
		L["Keys 1–12 follow the stance/form bar like the main action bar does (e.g. Battle Stance, Cat Form, Stealth). Without a stance the bar's own slots apply."])

	-- Appearance ----------------------------------------------------------
	local look, lookLayout = Settings.RegisterVerticalLayoutSubcategory(category, APPEARANCE_LABEL)
	S.Header(lookLayout, L["Size and spacing"])
	B:Slider(look, "scale", L["Scale"], 0.3, 2, 0.05, S.DecimalFormatter)
	B:Slider(look, "padH", L["Horizontal spacing"], 0, 30, 1)
	B:Slider(look, "padV", L["Vertical spacing"], 0, 30, 1)
	B:Slider(look, "blockGap", L["Gap to extra block"], 0, 80, 1, nil,
		L["Additional gap between the numpad and the navigation/arrow keys."])

	-- own header instead of APPEARANCE_LABEL: in English that would match the page name ("Appearance")
	S.Header(lookLayout, DISPLAY)
	B:Slider(look, "alpha", L["Opacity"], 0, 1, 0.05, S.FractionFormatter)
	B:Slider(look, "bgAlpha", L["Background opacity"], 0, 1, 0.05, S.FractionFormatter)
	B:Checkbox(look, "showGrid", L["Show empty buttons"])
	B:Dropdown(look, "labels", L["Key labels"], {
		{ 1, L["Short (1, 2, +, …)"] },
		{ 2, L["Key name (Num 1, …)"] },
		{ 3, NONE_KEY },
	})
	B:Slider(look, "fontSize", L["Label font size"], 0, 24, 1, S.FontSizeFormatter)
	B:Checkbox(look, "hideMacro", L["Hide macro text"])
	B:Checkbox(look, "hideBorder", L["Hide equipped item border"])
	B:Checkbox(look, "zoom", L["Zoom icons"], L["Crops the border of the icons."])
	B:Dropdown(look, "flyout", L["Flyout direction"], {
		{ "UP", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_UP },
		{ "DOWN", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_DOWN },
		{ "LEFT", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT },
		{ "RIGHT", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT },
	})
	B:Checkbox(look, "clickThrough", L["Click-through"],
		L["Buttons ignore the mouse; only the keyboard triggers them."])

	-- Position ------------------------------------------------------------
	local pos, posLayout = Settings.RegisterVerticalLayoutSubcategory(category, L["Position"])
	S.Header(posLayout, L["Position"])
	-- the same setting as under "General", just a second control
	Settings.CreateCheckbox(pos, B.settings.locked)
	B:Dropdown(pos, "point", L["Anchor"], qnCore.PointEntries(), L["Reference point on the screen and on the bar. The bar stays in place when this changes."],
		nil, ns.KeepPosition)
	B:Slider(pos, "x", L["X offset"], -3000, 3000, 1)
	B:Slider(pos, "y", L["Y offset"], -3000, 3000, 1)
	S.Button(posLayout, L["Center horizontally"], L["Center"], function() ns.CenterBar(true) end)
	S.Button(posLayout, L["Center vertically"], L["Center"], function() ns.CenterBar(false) end)
	S.Button(posLayout, L["Reset position"], RESET, ns.ResetPosition)
	B:Checkbox(pos, "autoVisible", L["Keep in visible area automatically"],
		L["Moves the bar back onto a monitor after dragging, on login and when the monitor arrangement changes. With qnViewPort and monitor data, only areas that are actually visible on a monitor count."])
	S.Button(posLayout, L["Find bar"], L["Move into visible area"], ns.MoveIntoVisible,
		L["Moves the bar onto the nearest visible monitor now (/qnnkp visible)."])

	-- Visibility ----------------------------------------------------------
	local vis, visLayout = Settings.RegisterVerticalLayoutSubcategory(category, HUD_EDIT_MODE_SETTING_AURA_FRAME_VISIBLE_SETTING)
	S.Header(visLayout, L["Fading"])
	local fade = B:Checkbox(vis, "fade", L["Fade out without mouseover"],
		L["Fades the bar to the opacity set below while the mouse is not over it."])
	local function Fading()
		return ns.db.fade
	end
	S.Depends(B:Slider(vis, "fadeAlpha", L["Faded opacity"], 0, 1, 0.05, S.FractionFormatter), fade, Fading)
	S.Depends(B:Slider(vis, "fadeDelay", L["Delay"], 0, 3, 0.1, S.SecondsFormatter), fade, Fading)

	S.Header(visLayout, L["Hiding"])
	local custom = B:Checkbox(vis, "useCustom", L["Use custom condition"],
		L["Replaces all of the following switches with a custom macro condition."])
	local function NotCustom()
		return not ns.db.useCustom
	end
	S.Depends(B:Checkbox(vis, "hideVehicle", L["Hide in vehicle / while possessing"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideCombat", L["Hide in combat"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideNoCombat", L["Hide out of combat"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hidePet", L["Hide with pet"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideNoPet", L["Hide without pet"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideStealth", L["Hide in stealth"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideForm", L["Hide in stance/form"]), custom, NotCustom)
	B:Register(vis, "custom", L["Custom condition"])
	S.Button(visLayout, L["Custom condition"], L["Edit …"], function()
		StaticPopup_Show("QNNUMKEYPAD_CUSTOM")
	end, L["Macro condition with show/hide, e.g. '[combat] show; [mod:alt] show; hide'."])

	-- Action slots --------------------------------------------------------
	local slots, slotsLayout = Settings.RegisterVerticalLayoutSubcategory(category, L["Action slots"])
	S.Header(slotsLayout, L["Action slots"])
	local note = L["The actions are stored in the slots of this page. A Blizzard action bar using the same page shows the same actions – hide it in Edit Mode."]
	B:Dropdown(slots, "page1", L["Keys 1–12"], PAGES, note, nil, check)
	B:Dropdown(slots, "page2", L["Keys 13–24"], PAGES, note, nil, check)
	B:Dropdown(slots, "page3", L["Keys 25–28"], PAGES, L["The actions are stored in the slots of this page. A Blizzard action bar using the same page shows the same actions – hide it in Edit Mode. Only used when the arrow keys are shown: all four arrow keys with the Macintosh layout, Down and Right Arrow with Windows, Microsoft Office and Natural Elite, Right Arrow with Natural Multimedia, never with Razer Naga."], nil, check):AddModifyPredicate(Never)

	S.Header(slotsLayout, L["Modifier sets"])
	local setNote = L["While the key is held, keys 1–12 show and trigger the actions of this page (keyboard and mouse). Keys 13 and higher do not switch. With Ctrl and Alt held together, the normal actions apply."]
	for _, set in ipairs({
		{ "ctrl", L["Ctrl set"], L["Ctrl set: page"], setNote },
		-- switched off for now (Core.lua Sanitize)
		{ "alt", L["Alt set"], L["Alt set: page"], L["Not available for now."] .. "\n\n" .. setNote .. "\n\n" .. L["Note: Alt is also Blizzard's default self cast key – spells that can target a friend are then cast on yourself."], true },
	}) do
		local key = set[1]
		local on = B:Checkbox(slots, key .. "Set", set[2], set[4], check)
		if set[5] then
			on:AddModifyPredicate(Never)
		end
		S.Depends(B:Dropdown(slots, key .. "Page", set[3], PAGES, note, nil, check), on, function()
			return ns.db[key .. "Set"]
		end)
	end

	BuildMouse(category)
	ns.InitMouseActions(category)
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnNumKeyPad", Build)
end