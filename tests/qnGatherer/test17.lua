-- Scenario 17: qnGatherer 0.7.4 - a zone with only a resource list (GatherTogether import without
-- skill range) has no skill text; journal and info window work for it
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, J = gt.DB, gt.Journal
local MAP = 1436

Check(DB.Ingest({ t = "zone", kind = "fish", map = MAP, res = { "i:6291" } }, "import:gt") == "added",
	"zone with only a resource list added")
Check(J.ZoneSkillText("fish", MAP) == nil, "no skill text without a range")

local ok, err = pcall(gt.Mini.Text, "fish", MAP)
Check(ok, "info window text without a range: " .. tostring(err))
ok, err = pcall(J.Show, "fish")
Check(ok, "journal lists the zone without a range: " .. tostring(err))

DB.Ingest({ t = "zone", kind = "fish", map = MAP, min = 1, max = 75 }, "import:gt")
Check(J.ZoneSkillText("fish", MAP) == gt.L["Skill %d – %d"]:format(1, 75), "skill text once the range is known")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
