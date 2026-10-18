-- Scenario 14: qnGatherer - guild exchange protocol: hello, live updates, list/map requests in both
-- directions, digests, remembered state per member
C_Map.GetMapWorldSize = function() return 2000, 1000 end
C_Map.GetBestMapForUnit = function() return 1429 end
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local DB, Sy = gt.DB, gt.Sync
local MAP = 1429
local BOB = "Bob-Realm"

local function Pump()
	for _ = 1, 500 do
		if #Sy.queue == 0 then return end
		RunTickers()
	end
end
local function Sent(pattern, channel, target)
	for _, m in ipairs(QN_SENT) do
		if m[2]:find(pattern) and (not channel or m[3] == channel) and (not target or m[4] == target) then
			return m
		end
	end
end
local function Msg(text, channel, sender)
	FireEvent("CHAT_MSG_ADDON", "qnGather", text, channel, sender or BOB)
end

Check(QN_PREFIXES and QN_PREFIXES.qnGather, "prefix registered")
Check(Sy.Enabled(), "exchange on by default in a guild")

-- own data, hello after login
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.4, y = 0.4, res = "o:1731" }, "own")
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.5, y = 0.5, res = "o:1732" }, "guild:Carl-Realm")
RunTimers()
Pump()
local hello = Sent("^H~1~%x+$", "GUILD")
Check(hello ~= nil, "hello to the guild")
Check(Sent("^B~1~mine~1429~%d+,o:1731$", "GUILD") ~= nil, "new own node sent live")
Check(not Sent("o:1732", "GUILD"), "nodes of other members are not sent live")

-- digests: only shared nodes; they change with the data
local d1 = Sy.Digests()
Check(d1.maps["mine,1429"] and hello[2] == "H~1~" .. d1.total, "hello carries the digest")
DB.global.sync.relayGuild = true
Sy.OptionsChanged()
local d2 = Sy.Digests()
Check(d2.maps["mine,1429"] ~= d1.maps["mine,1429"], "relaying guild nodes changes the digest")
DB.global.sync.relayGuild = false
Sy.OptionsChanged()
Check(Sy.Digests().maps["mine,1429"] == d1.maps["mine,1429"], "digest stable for the same data")
Check(Sy.Hash({ "a", "b" }) ~= Sy.Hash({ "ab" }) and #Sy.Hash({}) == 8, "hash separates entries, 8 hex digits")

-- a member says hello with other data: list request by whisper
QN_SENT = {}
Msg("H~1~0000abcd", "GUILD")
Pump()
Check(Sent("^L~1$", "WHISPER", BOB) ~= nil, "list requested from the member")

-- the member answers: map digests -> requests for changed maps only
QN_SENT = {}
Msg("M~1~mine,1429,deadbeef;herb,1429,cafe0001;nope,1429,aaaa0000", "WHISPER")
Pump()
Check(Sent("^R~1~mine~1429$", "WHISPER", BOB) and Sent("^R~1~herb~1429$", "WHISPER", BOB), "changed maps requested")
Check(not Sent("nope"), "unknown kinds ignored")
local coordA, coordB = DB.Encode(0.6, 0.6), DB.Encode(0.7, 0.3)
Msg("D~1~mine~1429~" .. coordA .. ",o:1731;" .. coordB .. ",i:2771", "WHISPER")
local n = DB.GetNode("mine", MAP, coordB)
Check(n and n.res == "i:2771" and n.origin == "guild:" .. BOB, "nodes of the member taken over")
Msg("DE~1~mine~1429~deadbeef", "WHISPER")
Msg("ME~1~0000abcd", "WHISPER")
Check(DB.global.sync.seen[BOB].total == nil, "not finished while a map is outstanding")
Msg("DE~1~herb~1429~cafe0001", "WHISPER")
Check(DB.global.sync.seen[BOB].total == "0000abcd" and DB.global.sync.seen[BOB].maps["mine,1429"] == "deadbeef", "state of the member remembered")

-- same hello again: nothing requested; a changed map later: only that map
QN_SENT = {}
Msg("H~1~0000abcd", "GUILD")
Pump()
Check(not Sent("^L~1$"), "unchanged member: no request")
Msg("H~1~0000beef", "GUILD")
Pump()
QN_SENT = {}
Msg("M~1~mine,1429,deadbeef;herb,1429,cafe0002", "WHISPER")
Pump()
Check(Sent("^R~1~herb~1429$") and not Sent("^R~1~mine~1429$"), "only the changed map requested")

-- the other direction: the member requests our list and a map
QN_SENT = {}
Msg("L~1", "WHISPER")
Pump()
Check(Sent("^M~1~mine,1429," .. d1.maps["mine,1429"], "WHISPER", BOB) and Sent("^ME~1~%x+$", "WHISPER", BOB), "own map digests sent")
QN_SENT = {}
Msg("R~1~mine~1429", "WHISPER")
Pump()
local data = Sent("^D~1~mine~1429~", "WHISPER", BOB)
Check(data and data[2]:find("o:1731", 1, true) and not data[2]:find("i:2771", 1, true), "map sent with own nodes only")
Check(Sent("^DE~1~mine~1429~" .. Sy.Digests().maps["mine,1429"] .. "$", "WHISPER", BOB) ~= nil, "end of the map with its digest")

-- many nodes: split into several messages of at most 250 bytes
for i = 1, 40 do
	DB.Ingest({ t = "node", kind = "herb", map = MAP, x = 0.01 + i * 0.02, y = 0.9, res = "o:" .. (1600 + i) }, "own")
end
RunTimers()
QN_SENT = {}
Msg("R~1~herb~1429", "WHISPER")
Pump()
local parts, longest = 0, 0
for _, m in ipairs(QN_SENT) do
	if m[2]:find("^D~1~herb~1429~") then
		parts = parts + 1
		longest = math.max(longest, #m[2])
	end
end
Check(parts > 1 and longest <= 250, "split into parts of at most 250 bytes")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
