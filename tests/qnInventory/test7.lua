-- Scenario 7: qnInventory 0.3.5 - the views expose their window (view.frame): Toggle closes an
-- open view of the same character, showing your own bags hides the view of another character

LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")
qnInventoryDB = { realms = { Realm = { Zwilling = { class = "MAGE", containers = {
	[0] = { size = 2, items = { [1] = { "|Hitem:100|h[A]|h", 1 } } },
} } } } }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)

local key
for _, e in ipairs(inv.CharEntries()) do if e[1]:find("Zwilling", 1, true) then key = e[1] end end
Check(key ~= nil, "other character in the selection")

inv.Show("bags", key)
local frame = _G.qnInventoryBagsFrame
Check(frame and frame:IsShown(), "bags view of the other character shown")

inv.Toggle("bags", key)
Check(not frame:IsShown(), "Toggle closes the open view of the same character")

inv.Toggle("bags", key)
Check(frame:IsShown(), "Toggle opens it again")

inv.Show("bags", inv.PlayerKey())
Check(not frame:IsShown(), "own bags hide the view of the other character")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
