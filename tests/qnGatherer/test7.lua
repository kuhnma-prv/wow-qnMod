-- Scenario 7: qnGatherer - display: visibility modes, filters, origins, names, tooltip lines,
-- world map content and menu
C_Map.GetMapWorldSize = function() return 2000, 1000 end
QN_SKILLS = { [186] = 150 }   -- Mining learned, Herbalism not
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, D, W, L = gt.DB, gt.Display, gt.WorldMap, gt.L
local MAP = 1429

-- professions and tracking
Check(D.HasProfession("mine") and not D.HasProfession("herb") and D.HasProfession("treasure"), "professions from the skill lines")
QN_SKILLS[182] = 1
Check(not D.HasProfession("herb"), "professions cached")
FireEvent("SKILL_LINES_CHANGED")
Check(D.HasProfession("herb"), "read again after SKILL_LINES_CHANGED")
Check(not D.IsTracking("herb"), "herb tracking off")
for i, t in ipairs(QN_TRACKING) do
	if t.spellID == 2383 then C_Minimap.SetTracking(i, true) end
end
Check(D.IsTracking("herb") and not D.IsTracking("mine"), "tracking read again after MINIMAP_UPDATE_TRACKING")
Check(D.IsTracking("fish") == D.HasProfession("fish") and not D.IsTracking("fish"), "kind without tracking spell: like profession")

-- visibility modes
Check(D.KindShown("mine", "always") and not D.KindShown("mine", "never") and D.KindShown("mine", "profession")
	and not D.KindShown("mine", "tracking") and D.KindShown("herb", "tracking"), "visibility modes")
Check(D.KindShown("treasure") and D.KindShown("mine") and not D.KindShown("fish"), "profile defaults")

-- content of the world map
DB.Ingest({ t = "res", res = "o:1731", kind = "mine", item = 2770, skill = 65, names = { [GetLocale()] = "Kupferader" } }, "own")
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.4, y = 0.4, res = "o:1731" }, "own")
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.6, y = 0.6, res = "i:2771" }, "guild:Bob-Realm")
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.8, y = 0.8, res = "n:mine:Zinnader" }, "import:gm2")
DB.Ingest({ t = "node", kind = "herb", map = MAP, x = 0.2, y = 0.2, res = "i:2447" }, "own")
DB.Ingest({ t = "area", kind = "fish", map = MAP, x = 0.3, y = 0.3, rx = 0.05, ry = 0.05, class = "learned", res = { "i:6291" } }, "own")
local nodes, areas = W.Collect(MAP)
Check(#nodes == 4 and #areas == 0, "all nodes of shown kinds, no areas by default")
local first = nodes[1]
Check(first.kind == "herb" and first.res == "i:2447" and math.abs(first.x - 0.2) < 0.0002, "entry fields, kinds in order")
gt.db.filter.mine = { ["i:2771"] = false }
Check(#W.Collect(MAP) == 3, "filtered resource hidden")
gt.db.origins.import = false
Check(#W.Collect(MAP) == 2, "imported nodes hidden")
gt.db.origins.guild, gt.db.origins.import, gt.db.filter.mine = false, true, nil
Check(#W.Collect(MAP) == 3, "guild nodes hidden")
gt.db.origins.guild = true
gt.db.show.herb = "never"
Check(#W.Collect(MAP) == 3, "kind set to never hidden")
gt.db.worldMap.areas, gt.db.show.fish = true, "always"
nodes, areas = W.Collect(MAP)
Check(#areas == 1 and areas[1].kind == "fish" and areas[1].origin == "own", "areas shown when switched on")
gt.db.filter.fish = { ["i:6291"] = false }
nodes, areas = W.Collect(MAP)
Check(#areas == 0, "area hidden when all its fish are filtered")
gt.db.worldMap.show = false
nodes, areas = W.Collect(MAP)
Check(#nodes == 0 and #areas == 0, "world map icons switched off")
gt.db.worldMap.show = true

-- names, icons, origin texts
QN_ITEM_NAMES = { [2771] = "Zinnerz" }
QN_ITEM_REQUESTS = {}
Check(D.ResourceName("o:1731") == "Kupferader", "name from the catalog")
Check(D.ResourceName("i:2771") == "Zinnerz", "name from the item")
Check(D.ResourceName("n:mine:Zinnader") == "Zinnader", "name from the name key")
Check(D.ResourceName("i:9999") == "i:9999" and QN_ITEM_REQUESTS[9999], "unknown item: key, item data requested")
Check(D.ResourceItem("o:1731") == 2770 and D.ResourceItem("i:2771") == 2771 and D.ResourceItem("n:mine:x") == nil, "main product")
Check(D.ResourceIcon("mine", "o:1731") ~= nil and D.ResourceIcon("treasure", "n:treasure:x") ~= nil, "icons")
Check(D.OriginText("own") == nil and D.OriginText("guild:Bob-Realm") == L["Found by %s"]:format("Bob-Realm")
	and D.OriginText("import:gm2") == L["Imported from %s"]:format("GatherMate2"), "origin texts")
Check(D.Color("mine")[1] == 1 and D.Color("herb")[2] == 1, "kind colors")

-- tooltip lines
local lines = {}
local tip = { AddLine = function(_, text) lines[#lines + 1] = text end }
D.AddTooltipLines(tip, { kind = "mine", res = "o:1731", origin = "guild:Bob-Realm" })
Check(lines[1] == "Kupferader" and lines[2] == L["Required skill: %d"]:format(65) and lines[3] == L["Found by %s"]:format("Bob-Realm"),
	"tooltip: name, required skill, origin")

-- world map menu: delete and waypoint
local entry = { kind = "mine", coord = DB.Encode(0.4, 0.4), x = 0.4, y = 0.4, res = "o:1731", origin = "own" }
local owner = { entry = entry, mapID = MAP }
function owner:PinsUnderMouse() return { self } end
W.ShowMenu(owner)
Check(MENU_LOG[2] and MENU_LOG[2][2] == L["Delete: %s"]:format("Kupferader"), "menu entry to delete")
Check(MENU_LOG[3] and MENU_LOG[3][2] == L["Set waypoint"] and #MENU_LOG == 3, "waypoint entry, no TomTom without TomTom")
MENU_LOG[2][3]()
Check(DB.GetNode("mine", MAP, entry.coord) == nil, "deleted from the menu")
TomTom = { AddWaypoint = function(_, map, x, y, opts) TOMTOM = { map, x, y, opts.title } end }
W.ShowMenu(owner)
MENU_LOG[4][3]()
Check(TOMTOM and TOMTOM[1] == MAP and TOMTOM[4] == "Kupferader", "TomTom waypoint")

-- data changes redraw the displays
local redrawn = 0
D.OnRefresh(function() redrawn = redrawn + 1 end)
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.1, y = 0.1, res = "o:1731" }, "own")
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.15, y = 0.15, res = "o:1731" }, "own")
RunTimers()
Check(redrawn == 1, "changes merged into one redraw")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
