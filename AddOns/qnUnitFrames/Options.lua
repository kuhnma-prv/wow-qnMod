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

	-- range icon: one block per frame (Range.lua)
	local R = S.New({ store = ns.store, prefix = "QNUF_", apply = function() ns.ApplyRange() end })
	S.Header(layout, L["Range Icon"])
	local frames = {
		rangeTarget = { L["At the target frame"],
			L["Shows to the right of the target frame the icon of your farthest ranged action that can be used right now, as soon as the target is within its range. Within melee range the icon of the auto attack appears."] },
		rangeFocus = { L["At the focus frame"],
			L["Shows to the right of the focus frame the icon of your farthest ranged action that can be used right now, as soon as the focus is within its range. Within melee range the icon of the auto attack appears."] },
	}
	for _, entry in ipairs(ns.RANGE_UNITS) do
		local key = entry.key
		local function IsOn()
			return R.settings[key]:GetValue()
		end
		local on = R:Checkbox(category, key, frames[key][1], frames[key][2])
		local size, offset = ns.RANGE_SIZE, ns.RANGE_OFFSET
		S.Depends(R:Slider(category, key .. "Size", HUD_EDIT_MODE_SETTING_ACTION_BAR_ICON_SIZE, size[1], size[2], 1), on, IsOn)
		S.Depends(R:Slider(category, key .. "X", L["Horizontal offset"], offset[1], offset[2], 1, nil,
			L["Distance from the right edge of the frame; negative values move the icon to the left."]), on, IsOn)
		S.Depends(R:Slider(category, key .. "Y", L["Vertical offset"], offset[1], offset[2], 1, nil,
			L["Distance from the vertical center of the frame; positive values move the icon up."]), on, IsOn)
	end

	ns.InitClicksPage(category)
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnUnitFrames", Build)
end
