-- Scenario 5: qnViewPort without Titan – no "Titan Panel" subpage, no hooks, profile switch
-- and apply run without errors.

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = {
	["account:Raid"] = { titan = { Bar = 2 } },
} }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

local tt = vp.Titan
Check(not tt.active and tt.category == nil, "without Titan: not active, no subpage")
Check(_G.qnViewPortTitanAnchorBar == nil, "without Titan: no anchors")
Check(Titan_G == nil, "without Titan: no Titan globals created")
local ok, err = pcall(function()
	tt.Apply()
	SetEditModeLayout(1)
	SetEditModeLayout(3)
end)
Check(ok, "apply and profile switch without Titan: " .. tostring(err))
Check(qnViewPortDB.profiles["account:Raid"].titan.Bar == 2, "saved Titan selection is kept")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
