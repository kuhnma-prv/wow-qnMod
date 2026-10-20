-- Scenario 22: qnCore - RegisterCommands (options, help, reset in and out of combat), store:Toggle,
-- Blocked, B:When, Clamp/ValidColor, Profiles.Register takes ns.defaults
LoadAddon("qnCore")
local lib = qnCore
local L = lib.NewLocale({}, "qnCore")   -- texts as qnCore shows them

local chat = {}
local AddMessage = DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage = function(self, msg)
	chat[#chat + 1] = msg
	AddMessage(self, msg)
end
local function Said(text)
	for _, msg in ipairs(chat) do
		if msg:find(text, 1, true) then return true end
	end
	return false
end

-- test addon with a profile store
local ns = {}
lib.NewAddon(ns, "qnTestAddon")
ns.defaults = { locked = false, size = 3 }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
qnTestAddonDB = {}
ns.store = lib.Profiles.Register({ ns = ns, sv = qnTestAddonDB, settingsVersion = "1.0" })
ns.db = ns.store.db
Check(ns.store.defaults == ns.defaults, "Register takes ns.defaults")

-- RegisterCommands
local opened, ran = 0, nil
function ns.OpenOptions() opened = opened + 1 end
lib.RegisterCommands(ns, "QNTESTADDON", { "/qntest" }, { run = function(rest) ran = rest end, reset = "reset" }, "Help text")
SlashCmdList.QNTESTADDON("")
SlashCmdList.QNTESTADDON("config")
SlashCmdList.QNTESTADDON("options")
Check(opened == 3, "empty, config and options open the options")
SlashCmdList.QNTESTADDON("run Some Thing")
Check(ran == "Some Thing", "subcommand gets the rest as typed")
SlashCmdList.QNTESTADDON("unknown")
Check(Said("Help text"), "unknown subcommand prints the help")

-- reset
ns.store:Set("size", 9)
QN_COMBAT = true
SlashCmdList.QNTESTADDON("reset")
Check(Said(L["In combat: settings will be reset after combat."]) and ns.db.size == 9, "reset in combat: deferred with notice")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(ns.db.size == 3, "reset after combat")
SlashCmdList.QNTESTADDON("reset")
Check(Said(L["Settings reset."]), "reset outside combat")

-- Toggle
Check(ns.store:Toggle("locked") == true and ns.db.locked == true, "Toggle on")
Check(ns.store:Toggle("locked") == false and ns.db.locked == false, "Toggle off")

-- Blocked
local out = {}
local function P(msg) out[#out + 1] = msg end
Check(lib.Blocked(P) == false and #out == 0, "not blocked out of combat")
QN_COMBAT = true
Check(lib.Blocked(P) and out[1] == L["Not possible in combat."], "blocked in combat with default text")
QN_COMBAT = false
local cursor = GetCursorInfo
GetCursorInfo = function() return "spell" end
Check(lib.Blocked(P, nil, true) and out[2] == L["Something is on the cursor – place or drop it first."], "blocked with something on the cursor")
Check(lib.Blocked(P) == false, "cursor only checked on request")
GetCursorInfo = cursor

-- B:When
local t = { a = true, b = false, c = 2 }
local B = lib.Settings.New({ prefix = "QNTEST_", source = function() return t end, defaults = {} })
Check(B:When("a")() and not B:When("b")() and B:When("b", false)() and B:When("c", 2)() and not B:When("c", 3)(), "When")

-- Clamp / ValidColor
Check(lib.Clamp(5, 0, 3) == 3 and lib.Clamp(-1, 0, 3) == 0 and lib.Clamp("x", 0, 3) == nil, "Clamp")
Check(lib.ValidColor({ 1, 0, 0, 1 }) and not lib.ValidColor({ 1, 0, 0 }) and not lib.ValidColor("red"), "ValidColor")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
