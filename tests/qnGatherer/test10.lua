-- Scenario 10: qnGatherer - journal (skill text, zones, search, resources, preview, focus) and
-- info window (content, auto open/close, pinning)
C_Map.GetMapWorldSize = function() return 2000, 1000 end
local playerMap = 1436
C_Map.GetBestMapForUnit = function() return playerMap end
QN_MAPINFO = { [1429] = { name = "Elwynn" }, [1436] = { name = "Westfall" } }
QN_ITEM_NAMES = { [2771] = "Zinnerz", [6291] = "Kleiner Fisch" }
QN_SKILLS = { [186] = 120, [356] = 80 }
local SkillInfo = C_SkillInfo.GetSkillLineInfoByID
C_SkillInfo.GetSkillLineInfoByID = function(id)
	local info = SkillInfo(id)
	if info and id == 356 then info.modifier = 25 end
	return info
end
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, J, Mi, L = gt.DB, gt.Journal, gt.Mini, gt.L
local CHAR = gt.CharKey()

-- data
DB.Ingest({ t = "res", res = "o:1731", kind = "mine", item = 2770, skill = 1, names = { [GetLocale()] = "Kupferader" } }, "own")
DB.Ingest({ t = "node", kind = "mine", map = 1429, x = 0.4, y = 0.4, res = "o:1731" }, "own")
DB.Ingest({ t = "node", kind = "mine", map = 1429, x = 0.6, y = 0.6, res = "o:1731" }, "own")
DB.Ingest({ t = "res", res = "i:2771", kind = "mine", item = 2771, skill = 65 }, "import:gt")
DB.Ingest({ t = "node", kind = "mine", map = 1436, x = 0.5, y = 0.5, res = "i:2771" }, "own")
DB.Ingest({ t = "res", res = "i:6291", kind = "fish", item = 6291 }, "own")
DB.Ingest({ t = "area", kind = "fish", map = 1436, x = 0.3, y = 0.3, rx = 0.05, ry = 0.05, class = "learned", res = { "i:6291" } }, "own")
DB.Ingest({ t = "catch", char = CHAR, map = 1436, item = 6291, n = 4 }, "own")
DB.Ingest({ t = "catch", char = CHAR, map = 1436, item = 118, n = 2 }, "own")   -- not a fish
DB.Ingest({ t = "zone", kind = "fish", map = 1436, min = 1, max = 75 }, "import:gt")

-- skill texts
Check(J.SkillText("mine") == L["%s %d"]:format(MINING, 120), "skill text")
Check(J.SkillText("fish") == L["%s %d (+%d)"]:format(FISHING, 80, 25), "skill text with bonus")
Check(J.SkillText("herb") == HERBALISM, "unknown skill: only the name")

-- zones and search
local zones = J.Zones("mine", "")
Check(#zones == 2 and zones[1].name == "Elwynn" and zones[1].nodes == 2 and zones[2].name == "Westfall", "zones sorted by name with node count")
zones = J.Zones("mine", "WEST")
Check(#zones == 1 and zones[1].map == 1436, "search by zone name (case-insensitive)")
zones = J.Zones("mine", "kupfer")
Check(#zones == 1 and zones[1].map == 1429, "search by resource name")
zones = J.Zones("fish", "")
Check(#zones == 1 and zones[1].skill == L["Skill %d – %d"]:format(1, 75), "fishing zone with skill range")
Check(#J.Zones("herb", "") == 0, "no zones without data")

-- resources of a zone
local res = J.Resources("fish", 1436)
Check(#res == 1 and res[1].name == "Kleiner Fisch" and res[1].catches == 4 and res[1].areas == 1, "fish of the zone with catches, junk left out")
Check(J.ResourceDetail(res[1]) == L["caught: %d"]:format(4), "detail: catches")
res = J.Resources("mine", 1436)
Check(res[1].skill == 65 and J.ResourceDetail(res[1]) == L["Required skill: %d"]:format(65) .. " · " .. L["%d nodes"]:format(1), "detail: skill and nodes")

-- window and preview
QN_MAPART = { [1436] = { layer = { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 }, textures = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 } } }
QN_EXPLORED = { [1436] = { { textureWidth = 300, textureHeight = 200, offsetX = 10, offsetY = 20, fileDataIDs = { 21, 22 } } } }
J.Show("mine", 1436)
Check(J.frame:IsShown() and J.state.kind == "mine" and J.state.map == 1436, "journal opened on kind and zone")
local nodes, areas = J.DrawPreview()
Check(nodes == 1 and areas == 0, "preview: nodes of the zone")
J.SelectKind("fish")
Check(J.state.map == 1436 and DB.global.windows.journal.kind == "fish", "kind switched, first zone selected, kind remembered")
nodes, areas = J.DrawPreview()
Check(nodes == 0 and areas == 1, "preview: areas")
J.Focus("i:9999")
nodes, areas = J.DrawPreview()
Check(areas == 0, "focus on another resource hides the area")
J.Focus("i:9999")
Check(J.state.focus == nil, "second click removes the focus")
J.SelectKind("mine")
J.SelectZone(1429)
nodes, areas = J.DrawPreview()
Check(nodes == 0 and J.frame.noMap:IsShown(), "zone without map art: notice")
playerMap = 1436
J.CurrentZone()
Check(J.state.map == 1436, "current zone")
J.Toggle()
Check(not J.frame:IsShown(), "toggle closes")

-- info window content
local text = Mi.Text("fish", 1436)
Check(text:find("Westfall", 1, true) and text:find("Kleiner Fisch", 1, true) and text:find(L["caught: %d"]:format(4), 1, true)
	and text:find(L["Skill %d – %d"]:format(1, 75), 1, true), "info text: zone, skill range, fish with catches")
Check(Mi.Text("herb", 1436):find(L["No data for this zone yet."], 1, true) ~= nil, "info text without data")

-- opens while fishing, closes after the cast
FireEvent("UNIT_SPELLCAST_SENT", "player", "", "Cast-F", 7620)
Check(Mi.frame and Mi.frame:IsShown() and Mi.kind == "fish", "opens while fishing")
Check(Mi.frame.status:GetText() == L["Listen for the splash …"], "status while fishing")
FireEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player", "Cast-F", 7620)
Check(Mi.frame:IsShown() and Mi.frame.status:GetText() == "", "still open right after the cast")
RunTimers()
Check(not Mi.frame:IsShown() and DB.global.windows.mini.pinned == false, "closed after the delay, not unpinned by the timer")

-- pinned
SlashCmdList.QNGATHERER("mini")
Check(Mi.frame:IsShown() and DB.global.windows.mini.pinned, "/qngatherer mini pins and shows")
FireEvent("UNIT_SPELLCAST_SENT", "player", "", "Cast-F", 7620)
FireEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player", "Cast-F", 7620)
RunTimers()
Check(Mi.frame:IsShown(), "pinned: stays open")
Mi.frame:Hide()
Check(DB.global.windows.mini.pinned == false, "closing with X unpins")

-- gathering only when switched on
FireEvent("UNIT_SPELLCAST_SENT", "player", "Kupferader", "Cast-M", 2575)
Check(not Mi.frame:IsShown(), "gathering: off by default")
FireEvent("UNIT_SPELLCAST_STOP", "player", "Cast-M", 2575)
gt.db.mini.gathering = true
FireEvent("UNIT_SPELLCAST_SENT", "player", "Kupferader", "Cast-M", 2575)
Check(Mi.frame:IsShown() and Mi.kind == "mine", "gathering: opens when switched on")
Mi.frame.journal:GetScript("OnClick")(Mi.frame.journal)
Check(J.frame:IsShown() and J.state.kind == "mine" and J.state.map == 1436, "journal button opens the journal on kind and zone")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
