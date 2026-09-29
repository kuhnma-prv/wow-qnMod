-- Szenario 1: qnMeter – Slash-Befehle, Testmodus, Kontextmenü (auf deDE und enUS ohne fehlende Übersetzung)
local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local L = meter.L
local T = meter.Threat
for _, cmd in ipairs({ "help", "lock", "lock", "test", "check", "visible", "test", "reset" }) do
	SlashCmdList.QNMETER(cmd)
end
RunTimers()
Check(T.testMode == false, "Testmodus nach zweimal /qnm test wieder aus")
SlashCmdList.QNMETER("test")
RunTimers()
Check(T.testMode == true, "Testmodus an")
Check(T.frame and T.frame.OnMenu, "Fenster mit Kontextmenü")
T.frame.OnMenu(T.frame, T.frame)
local texts = {}
for _, e in ipairs(MENU_LOG) do texts[#texts + 1] = tostring(e[2]) end
Check(#MENU_LOG >= 6, "Menü mit Einträgen: " .. table.concat(texts, ", "))
Check(tContains(texts, L["Test Mode"]) and tContains(texts, LOCK_FRAME), "Menütexte über L bzw. GlobalStrings")
SlashCmdList.QNMETER("test")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
