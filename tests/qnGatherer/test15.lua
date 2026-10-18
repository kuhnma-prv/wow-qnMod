-- Scenario 15: qnGatherer - guild exchange safety: unknown members, invalid data, ignore list,
-- own messages, other versions, tombstones, rate limit, throttle, combat, switched off
C_Map.GetMapWorldSize = function() return 2000, 1000 end
C_Map.GetBestMapForUnit = function() return 1429 end
local MapInfo = C_Map.GetMapInfo
C_Map.GetMapInfo = function(map) if map == 999999 then return nil end return MapInfo(map) end
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, Sy = gt.DB, gt.Sync
local MAP = 1429

local function Pump(n)
	for _ = 1, n or 500 do
		if #Sy.queue == 0 then return end
		RunTickers()
	end
end
local function Msg(text, channel, sender)
	FireEvent("CHAT_MSG_ADDON", "qnGather", text, channel, sender)
end
local function C(x, y) return DB.Encode(x, y) end
Pump()
QN_SENT = {}

DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.4, y = 0.4, res = "o:1731" }, "own")
RunTimers()
Pump()
QN_SENT = {}

-- unknown member (no hello through the guild): whisper requests and data are ignored
Msg("L~1", "WHISPER", "Eve-Realm")
Msg("R~1~mine~1429", "WHISPER", "Eve-Realm")
Pump()
Check(#QN_SENT == 0, "requests of unknown members not answered")
Msg("D~1~mine~1429~" .. C(0.1, 0.1) .. ",o:1", "WHISPER", "Eve-Realm")
Check(DB.CountNodes("mine", MAP) == 1, "data without a request ignored")
Msg("L~1", "GUILD", "Eve-Realm")
Pump()
Check(#QN_SENT == 0, "requests through the guild channel ignored")

-- live data from the guild: valid entries taken over, invalid ones rejected
Msg("B~1~mine~1429~" .. C(0.2, 0.2) .. ",o:1732;" .. C(0.3, 0.3) .. ",x:1;123456789,o:1;abc,o:2", "GUILD", "Bob-Realm")
Check(DB.GetNode("mine", MAP, C(0.2, 0.2)).origin == "guild:Bob-Realm", "valid live entry taken over")
Check(DB.CountNodes("mine", MAP) == 2 and Sy.stats.rejected == 3, "invalid res, coordinate and number rejected")
Msg("B~1~mine~999999~" .. C(0.2, 0.2) .. ",o:1732", "GUILD", "Bob-Realm")
Msg("B~1~nope~1429~" .. C(0.2, 0.2) .. ",o:1732", "GUILD", "Bob-Realm")
Check(DB.CountNodes("mine", 999999) == 0 and DB.CountNodes("mine", MAP) == 2, "unknown map and kind ignored")
Msg("B~1~mine~1429~" .. C(0.6, 0.6) .. ",o:1732", "WHISPER", "Bob-Realm")
Check(DB.CountNodes("mine", MAP) == 2, "live data only through the guild channel")

-- own messages, other versions, too long, other prefixes, ignored members
Msg("B~1~mine~1429~" .. C(0.7, 0.7) .. ",o:1732", "GUILD", "Tester-Realm")
Msg("B~2~mine~1429~" .. C(0.7, 0.7) .. ",o:1732", "GUILD", "Bob-Realm")
Msg("B~1~mine~1429~" .. C(0.7, 0.7) .. ",o:1732" .. (";" .. C(0.8, 0.8) .. ",o:1732"):rep(20), "GUILD", "Bob-Realm")
FireEvent("CHAT_MSG_ADDON", "Other", "B~1~mine~1429~" .. C(0.7, 0.7) .. ",o:1732", "GUILD", "Bob-Realm")
gt.SetIgnoreText("eve-realm, Mallory-Realm")
Check(#DB.global.sync.ignore == 2 and gt.IgnoreText() == "eve-realm, Mallory-Realm", "ignore list from text")
Msg("B~1~mine~1429~" .. C(0.7, 0.7) .. ",o:1732", "GUILD", "Eve-Realm")
Check(DB.CountNodes("mine", MAP) == 2, "own, other version, too long, other prefix, ignored: nothing taken over")

-- deleted nodes stay deleted
DB.Delete("mine", MAP, C(0.2, 0.2))
Msg("B~1~mine~1429~" .. C(0.2, 0.2) .. ",o:1732", "GUILD", "Bob-Realm")
Check(DB.GetNode("mine", MAP, C(0.2, 0.2)) == nil, "tombstone blocks the guild node")

-- rate limit per member
Sy.maxRecords = 2
Msg("B~1~herb~1429~" .. C(0.1, 0.5) .. ",o:1;" .. C(0.3, 0.5) .. ",o:2;" .. C(0.5, 0.5) .. ",o:3", "GUILD", "Dave-Realm")
Check(DB.CountNodes("herb", MAP) == 2, "at most the limit per member and hour")
AdvanceTime(3601)
Msg("B~1~herb~1429~" .. C(0.7, 0.5) .. ",o:4", "GUILD", "Dave-Realm")
Check(DB.CountNodes("herb", MAP) == 3, "limit resets after an hour")
Sy.maxRecords = 5000

-- throttle: the message stays queued and goes out later
Sy.Hello(true)   -- fresh hello, so that the hello ticker of RunTickers does not queue another one
Pump()
QN_SENT = {}
Sy.Send("H~1~00000001", "GUILD")
QN_SEND_RESULT = 3
RunTickers()
Check(#Sy.queue == 1 and #QN_SENT == 0, "throttled: still queued")
QN_SEND_RESULT = nil
Pump(3)
Check(#Sy.queue == 1, "waits a few ticks after throttling")
Pump(10)
Check(#Sy.queue == 0 and #QN_SENT == 1, "sent after the pause")

-- combat and chat lockdown pause sending
Sy.Send("H~1~00000002", "GUILD")
QN_COMBAT = true
Pump(5)
Check(#Sy.queue == 1, "nothing sent in combat")
QN_COMBAT = false
QN_CHAT_LOCKDOWN = true
Pump(5)
Check(#Sy.queue == 1, "nothing sent during chat lockdown")
QN_CHAT_LOCKDOWN = false
Pump()
Check(#Sy.queue == 0, "sent afterwards")

-- switched off: nothing sent, nothing taken over; queue cleared
QN_SENT = {}
gt.builders.sync.settings.enabled:SetValue(false)
Check(not Sy.Enabled(), "exchange switched off in the options")
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.9, y = 0.1, res = "o:1731" }, "own")
RunTimers()
Pump()
Msg("B~1~mine~1429~" .. C(0.95, 0.95) .. ",o:1732", "GUILD", "Bob-Realm")
Check(#QN_SENT == 0 and DB.GetNode("mine", MAP, C(0.95, 0.95)) == nil, "off: nothing sent or taken over")
gt.builders.sync.settings.enabled:SetValue(true)
Pump()
Check(#QN_SENT == 1 and QN_SENT[1][2]:find("^H~1~"), "switched on again: hello")

-- not in a guild
QN_IN_GUILD = false
Check(not Sy.Enabled(), "outside a guild: off")
QN_IN_GUILD = nil
SlashCmdList.QNGATHERER("sync")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
