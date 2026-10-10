-- Scenario 6: qnInventory 0.3.4 - bags view of another character lists the slots in the order of
-- Blizzard's combined bags (UpdateItemSort: backpack first, slots ascending, grid from the bottom right)

LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")
qnInventoryDB = { realms = { Realm = { Zwilling = { class = "MAGE", containers = {
	[0] = { size = 3, items = { [1] = { "|Hitem:100|h[A]|h", 1 }, [3] = { "|Hitem:103|h[C]|h", 1 } } },
	[1] = { size = 2, items = { [1] = { "|Hitem:200|h[D]|h", 1 }, [2] = { "|Hitem:201|h[E]|h", 1 } } },
} } } } }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)

local order = {}
local orig = AnchorUtil.GridLayout
AnchorUtil.GridLayout = function(list, ...)
	for i, b in ipairs(list) do order[i] = b.link or "-" end
	return orig and orig(list, ...)
end
local entries = inv.CharEntries()
local key
for _, e in ipairs(entries) do if e[1]:find("Zwilling", 1, true) then key = e[1] end end
inv.Show("bags", key)
AnchorUtil.GridLayout = orig

Check(#order == 5, "five slots in the grid: " .. #order)
Check(order[1] == "|Hitem:100|h[A]|h" and order[2] == "-" and order[3] == "|Hitem:103|h[C]|h",
	"first = backpack slot 1 (bottom right), then slots ascending: " .. table.concat(order, ","))
Check(order[4] == "|Hitem:200|h[D]|h" and order[5] == "|Hitem:201|h[E]|h", "bag 1 after the backpack: " .. table.concat(order, ","))

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
