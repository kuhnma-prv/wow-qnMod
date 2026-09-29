-- Scenario 1: qnThreatMeter - slash commands, test mode, context menu (on deDE and enUS without missing translation)
local core = LoadAddon("qnCore")
local meter = LoadAddon("qnThreatMeter")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local L = meter.L
local T = meter.Threat
for _, cmd in ipairs({ "help", "lock", "lock", "test", "check", "visible", "test", "reset" }) do
	SlashCmdList.QNTHREATMETER(cmd)
end
RunTimers()
Check(T.testMode == false, "test mode off again after /qnm test twice")
SlashCmdList.QNTHREATMETER("test")
RunTimers()
Check(T.testMode == true, "test mode on")
Check(T.frame and T.frame.OnMenu, "window with context menu")
T.frame.OnMenu(T.frame, T.frame)
local texts = {}
for _, e in ipairs(MENU_LOG) do texts[#texts + 1] = tostring(e[2]) end
Check(#MENU_LOG >= 6, "menu with entries: " .. table.concat(texts, ", "))
Check(tContains(texts, L["Test Mode"]) and tContains(texts, LOCK_FRAME), "menu texts via L or GlobalStrings")
SlashCmdList.QNTHREATMETER("test")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
