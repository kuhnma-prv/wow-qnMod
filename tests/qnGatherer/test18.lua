-- Scenario 18: qnGatherer 0.7.4 - guild exchange: repeated requests of a member are answered only
-- once while the answer is queued; no answers while the queue is full
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
local function Queued(pattern)
	local count = 0
	for _, m in ipairs(Sy.queue) do
		if m[1]:find(pattern) then count = count + 1 end
	end
	return count
end
local function Msg(text, channel)
	FireEvent("CHAT_MSG_ADDON", "qnGather", text, channel, BOB)
end

DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.4, y = 0.4, res = "o:1731" }, "own")
RunTimers()
Pump()
Msg("H~1~0000abcd", "GUILD")   -- Bob is known now
Pump()

-- the same requests many times before anything was sent: one answer each
for _ = 1, 50 do
	Msg("R~1~mine~1429", "WHISPER")
	Msg("L~1", "WHISPER")
end
Check(Queued("^DE~1~mine~1429~") == 1 and Queued("^D~1~mine~1429~") == 1, "map answered once: " .. Queued("^DE~1~mine~1429~"))
Check(Queued("^ME~1~") == 1, "list answered once: " .. Queued("^ME~1~"))

-- after the answer went out the member may ask again
Pump()
Msg("R~1~mine~1429", "WHISPER")
Check(Queued("^DE~1~mine~1429~") == 1, "answered again after sending")
Pump()

-- full queue: requests are not answered, own messages are still queued
for i = 1, 2000 do
	Sy.queue[i] = { "X~1", "GUILD" }
end
Msg("R~1~mine~1429", "WHISPER")
Msg("L~1", "WHISPER")
Check(#Sy.queue == 2000, "no answers while the queue is full: " .. #Sy.queue)
Sy.Hello(true)
Check(#Sy.queue == 2001, "own hello still queued")
for i = #Sy.queue, 1, -1 do Sy.queue[i] = nil end
Msg("R~1~mine~1429", "WHISPER")
Check(Queued("^DE~1~mine~1429~") == 1, "answered again once there is room")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
