-- Scenario 5: qnTooltip - /qntt reset: outside combat reset at once with "Settings reset.",
-- in combat deferred until after combat with the matching notice
EnableTooltips()
LoadAddon("qnCore")
local tt = LoadAddon("qnTooltip")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local L = tt.L

local chat = {}
local AddMessage = DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage = function(self, msg)
	chat[#chat + 1] = msg
	AddMessage(self, msg)
end
local function Said(text)
	for _, msg in ipairs(chat) do
		if msg:find(text, 1, true) then
			return true
		end
	end
	return false
end

-- in combat: deferred
tt.db.scale = 1.3
QN_COMBAT = true
SlashCmdList.QNTOOLTIP("reset")
Check(Said(L["In combat: settings will be reset after combat."]) and not Said(L["Settings reset."]), "in combat: notice about the deferred reset")
Check(tt.db.scale == 1.3, "in combat: not reset yet")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(tt.db.scale ~= 1.3, "reset after combat")

-- outside combat: at once
wipe(chat)
tt.db.scale = 1.3
SlashCmdList.QNTOOLTIP("reset")
Check(Said(L["Settings reset."]) and tt.db.scale ~= 1.3, "outside combat: reset at once")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
