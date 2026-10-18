-- Scenario 9: qnGatherer - options pages, slash command, toggles, data actions, filter helpers,
-- minimap button
C_Map.GetMapWorldSize = function() return 2000, 1000 end
C_Map.GetBestMapForUnit = function() return 1429 end
C_Map.GetMapInfo = function(map) return { name = "Elwynn" } end
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, L, A = gt.DB, gt.L, gt.Actions
local MAP = 1429

-- pages
Check(gt.category ~= nil and type(gt.OpenOptions) == "function", "options registered")
for _, key in ipairs({ "show", "origins", "launcher", "worldMap", "minimap", "circle", "colors", "fishing", "radius", "locks" }) do
	Check(gt.builders[key] ~= nil, "builder " .. key)
end
local kinds = gt.OptionKinds()
Check(#kinds == 4 and kinds[1] == "herb" and kinds[4] == "treasure", "kinds offered on Forever: herb, mine, fish, treasure")
Check(gt.builders.show.settings.herb:GetValue() == "profession" and gt.builders.worldMap.settings.scale:GetValue() == 1,
	"controls read the profile")
Check(gt.builders.radius.settings.mine:GetValue() == 15 and gt.builders.locks.settings.mine:GetValue() == false,
	"controls read the account-wide data options")
gt.builders.locks.settings.mine:SetValue(true)
Check(DB.IsLocked("mine"), "lock set from the options")
gt.builders.locks.settings.mine:SetValue(false)
Check(not DB.IsLocked("mine"), "lock removed from the options")

-- slash command and toggles
SlashCmdList.QNGATHERER("minimap")
Check(gt.db.minimap.show == false and gt.builders.minimap.settings.show:GetValue() == false, "/qngatherer minimap hides the icons")
SlashCmdList.QNGATHERER("minimap")
Check(gt.db.minimap.show == true, "and shows them again")
SlashCmdList.QNGATHERER("worldmap")
Check(gt.db.worldMap.show == false, "/qngatherer worldmap")
gt.ToggleWorldMap()
Check(gt.db.worldMap.show == true, "toggle (key binding)")
SlashCmdList.QNGATHERER("sound")
Check(gt.db.soundBoost == true, "/qngatherer sound")
SlashCmdList.QNGATHERER("sound")
local opened = 0
local open = gt.OpenOptions
gt.OpenOptions = function() opened = opened + 1 end
SlashCmdList.QNGATHERER("")
SlashCmdList.QNGATHERER("options")
SlashCmdList.QNGATHERER("help")
Check(opened == 2, "/qngatherer and /qngatherer options open the options, help does not")
Check(SLASH_QNGATHERER1 == "/qngatherer" and SLASH_QNGATHERER2 == "/qng", "slash commands")
Check(BINDING_NAME_QNGATHERER_TOGGLE_MINIMAP == L["Minimap icons on/off"], "key binding names")

-- data actions
local function Node(kind, x, y, res, origin)
	DB.Ingest({ t = "node", kind = kind, map = MAP, x = x, y = y, res = res or "i:2770" }, origin or "own")
end
Node("mine", 0.5, 0.5)
Node("mine", 0.515, 0.5)
gt.builders.radius.settings.mine:SetValue(31)
Check(A.Cleanup() == 1, "cleanup with the larger radius")
Node("herb", 0.2, 0.2, "i:2447")
Node("herb", 0.3, 0.3, "i:2447")
StaticPopupDialogs.QNGATHERER_DELETE_ZONE.OnAccept(nil, { kind = "herb", map = MAP })
Check(DB.CountNodes("herb", MAP) == 0, "delete in the zone (popup)")
gt.builders.locks.settings.mine:SetValue(true)
Check(A.DeleteZone("mine", MAP) == 0 and not A.ClearKind("mine") and DB.CountNodes("mine") == 1, "locked kind: nothing deleted")
gt.builders.locks.settings.mine:SetValue(false)
StaticPopupDialogs.QNGATHERER_DELETE_KIND.OnAccept(nil, "mine")
Check(DB.CountNodes("mine") == 0, "delete the whole kind (popup)")
Node("mine", 0.7, 0.7, "i:2770", "guild:Bob-Realm")
Node("mine", 0.8, 0.8, "i:2770", "import:gm2")
StaticPopupDialogs.QNGATHERER_DELETE_ORIGIN.OnAccept(nil, "guild:")
Check(DB.CountNodes("mine") == 1, "remove guild data (popup)")
Check(A.DeleteOrigin("import:") == 1 and DB.CountNodes("mine") == 0, "remove imported data")

-- filter helpers
DB.Ingest({ t = "res", res = "o:2", kind = "herb", names = { [GetLocale()] = "Zwergenwurz" } }, "own")
DB.Ingest({ t = "res", res = "o:1", kind = "herb", names = { [GetLocale()] = "Ackerkraut" } }, "own")
local entries = gt.FilterEntries("herb")
Check(entries[1][2] == "Ackerkraut" and entries[#entries][2] == "Zwergenwurz", "filter list sorted by name")
gt.SetFilterAll("herb", false)
Check(gt.db.filter.herb["o:1"] == false and gt.db.filter.herb["o:2"] == false, "filter: none")
gt.SetFilterAll("herb", true)
Check(gt.db.filter.herb["o:1"] == nil, "filter: all")

-- minimap button
local Lc = gt.Launcher
local function Near(a, b) return math.abs(a - b) < 1e-6 end
local x, y = Lc.Offset(0, 80, "ROUND")
Check(Near(x, 80) and Near(y, 0), "button at 0 degrees: right")
x, y = Lc.Offset(90, 80, "ROUND")
Check(Near(x, 0) and Near(y, 80), "button at 90 degrees: top")
x, y = Lc.Offset(45, 80, "SQUARE")
Check(Near(x, 80) and Near(y, 80), "square minimap: button in the corner")
Lc.Click("RightButton")
Check(opened == 3, "right-click opens the options")
Lc.Click("LeftButton")
Check(gt.db.minimap.show == false, "left-click toggles the minimap icons")
IsShiftKeyDown = function() return true end
Lc.Click("LeftButton")
Check(gt.db.worldMap.show == false, "Shift-left-click toggles the world map icons")
IsShiftKeyDown = function() return false end
Check(Lc.button:IsShown(), "button shown by default")
gt.builders.launcher.settings.show:SetValue(false)
Check(not Lc.button:IsShown() and DB.global.launcher.show == false, "button hidden from the options")
local lines = {}
Lc.Tooltip({ AddLine = function(_, t) lines[#lines + 1] = t end, AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. "=" .. b end })
Check(lines[2] == L["Minimap icons"] .. "=" .. L["off"], "tooltip shows the state")
gt.OpenOptions = open
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
