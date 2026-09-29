-- Szenario 14: qnCore.PointEntries – gemeinsame Auswahl der Ankerpunkte (qnNumKeyPad, qnTooltip,
-- qnViewPort): neun Punkte bzw. nur die vier Ecken, Texte aus der Locale von qnCore.

local core = LoadAddon("qnCore")
local L = core.L

local all = qnCore.PointEntries()
local order = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local ok = #all == 9
for i, point in ipairs(order) do
	ok = ok and all[i][1] == point and type(all[i][2]) == "string" and all[i][2] ~= ""
end
Check(ok, "neun Ankerpunkte in der Reihenfolge des Rasters")
Check(all[1][2] == L["Top left"] and all[5][2] == L["Center"] and all[8][2] == L["Bottom center"], "Texte aus der Locale von qnCore")

local corners = qnCore.PointEntries(true)
Check(#corners == 4 and corners[1][1] == "TOPLEFT" and corners[4][1] == "BOTTOMRIGHT"
	and corners[4][2] == L["Bottom right"], "nur Ecken")

-- jede Liste ist neu (Aufrufer dürfen sie verändern)
all[1][2] = "x"
Check(qnCore.PointEntries()[1][2] == L["Top left"], "neue Liste je Aufruf")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
