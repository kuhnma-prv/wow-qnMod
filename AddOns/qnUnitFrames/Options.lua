-- qnUnitFrames: options in the Blizzard settings panel (Settings API).
-- Main page: toggles and frame selection; the click bindings themselves are built by ClicksPage.lua.
-- The settings belong to the active profile (qnCore); after a profile switch qnCore re-reads the
-- controls.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

local function Build(category, layout)
	local B = S.New({ store = ns.store, prefix = "QNUF_", apply = ns.ApplyChange })

	S.Header(layout, GENERAL)
	B:Checkbox(category, "enabled", L["Click casting enabled"],
		L["Off: all qnUnitFrames bindings are removed; the frames behave as without the addon."])
	S.Button(layout, L["Click Bindings"], L["Edit …"], function() ns.OpenClicksPage() end,
		L["Sets what a click with which mouse button and modifier key does on a party or raid frame (/qnuf clicks)."])
	B:Checkbox(category, "tooltip", L["Show bindings in tooltip"],
		L["Shows below the tooltip of a bound frame which click does what."])

	S.Header(layout, HUD_EDIT_MODE_SETTINGS_CATEGORY_TITLE_FRAMES)
	B:Checkbox(category, "raidStyle", L["Raid-style frames"],
		L["Blizzard's raid frames and the party frames with the option 'Use Raid-Style Party Frames'."])
	B:Checkbox(category, "party", L["Classic party frames"],
		L["The party frames without the option 'Use Raid-Style Party Frames'."])
	B:Checkbox(category, "pets", L["Pet frames"],
		L["Also bind the frames of party members' pets."])

	ns.InitClicksPage(category)
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnUnitFrames", Build)
end
