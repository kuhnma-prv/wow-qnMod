-- Scenario 14: qnCore.PointEntries – shared selection of anchor points (qnNumKeyPad, qnTooltip,
-- qnViewPort): nine points or only the four corners, texts from qnCore's locale.

local core = LoadAddon("qnCore")
local L = core.L

local all = qnCore.PointEntries()
local order = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local ok = #all == 9
for i, point in ipairs(order) do
	ok = ok and all[i][1] == point and type(all[i][2]) == "string" and all[i][2] ~= ""
end
Check(ok, "nine anchor points in grid order")
Check(all[1][2] == L["Top left"] and all[5][2] == L["Center"] and all[8][2] == L["Bottom center"], "texts from qnCore's locale")

local corners = qnCore.PointEntries(true)
Check(#corners == 4 and corners[1][1] == "TOPLEFT" and corners[4][1] == "BOTTOMRIGHT"
	and corners[4][2] == L["Bottom right"], "corners only")

-- every list is new (callers may modify it)
all[1][2] = "x"
Check(qnCore.PointEntries()[1][2] == L["Top left"], "new list per call")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
