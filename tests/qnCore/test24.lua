-- Scenario 24: qnCore 0.3.0 - own header size of the Objective Tracker (independent of the text size)
-- and header font of the Damage Meter windows, per profile (layout)

qnCoreDB = { global = { tracking = true }, layouts = {} }

-- a window exists before qnCore loads, a second one is created afterwards
local first = { }
DamageMeter.windowDataList[1] = first
DamageMeter:SetupSessionWindow(1, first)

local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
SetEditModeLayout(3)

local line, header = ObjectiveTrackerLineFont, ObjectiveTrackerHeaderFont
local w1 = first.sessionWindow
local function Size(f) return select(2, f:GetFont()) end

-- defaults
Check(core.db.questHeaderSize == 0 and core.db.damageHeaderSize == 0, "defaults 0")
Check(qnCoreDB.settingsVersion == "1.2", "settings version 1.2")
Check(Size(header) == 14 and Size(w1.SessionTimer) == 13 and w1.Header:GetHeight() == 32, "default: Blizzard's sizes")

-- Objective Tracker: own header size, text stays
SETTINGS.QNCORE_QUESTHEADERSIZE:SetValue(8)
Check(Size(header) == 8 and Size(line) == 12, "header 8, text unchanged: " .. Size(header) .. "/" .. Size(line))
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(9)
Check(Size(header) == 8 and Size(line) == 9, "text 9, header stays 8")
SETTINGS.QNCORE_QUESTHEADERSIZE:SetValue(0)
Check(Size(header) == 11, "header like the text: text + 2 = " .. Size(header))
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(0)
Check(Size(header) == 14 and Size(line) == 12, "both back to Blizzard")
SETTINGS.QNCORE_QUESTHEADERSIZE:SetValue(10)
Check(Size(header) == 10 and Size(line) == 12, "header 10 with Blizzard's text")
ObjectiveTrackerManager:SetTextSize(15)
Check(Size(header) == 10 and Size(line) == 15, "Blizzard resets: own header size stays, text follows Blizzard")
SETTINGS.QNCORE_QUESTHEADERSIZE:SetValue(0)
Check(Size(header) == 17, "header 0: Blizzard's last font (17)")

-- Damage Meter: existing window
SETTINGS.QNCORE_DAMAGEHEADERSIZE:SetValue(10)
for _, fs in ipairs({ w1.SessionTimer, w1:GetSessionName(), w1:GetDamageMeterTypeName(), w1:GetNotActiveFontString() }) do
	Check(Size(fs) == 10, "header text of the existing window: 10")
end
Check(Size(GameFontNormalMed1) == 13, "shared font object untouched")
local h = w1.Header:GetHeight()
Check(h < 32 and h >= 22, "header bar shrinks: " .. h)
local timer = w1.SessionTimer._points[#w1.SessionTimer._points]
Check(timer[5] > -9 and timer[5] < 0, "timer moves up with the bar: " .. tostring(timer[5]))

-- new (secondary) window gets the size
local second = {}
DamageMeter.windowDataList[2] = second
DamageMeter:SetupSessionWindow(2, second)
Check(Size(second.sessionWindow.SessionTimer) == 10 and second.sessionWindow.Header:GetHeight() == h, "new window: size 10")

-- profile switch: second layout takes over, then Blizzard again
SetEditModeLayout(4)
Check(core.db.damageHeaderSize == 10 and Size(w1.SessionTimer) == 10, "new layout copies 10")
SETTINGS.QNCORE_DAMAGEHEADERSIZE:SetValue(0)
Check(Size(w1.SessionTimer) == 13 and w1.Header:GetHeight() == 32 and Size(second.sessionWindow.SessionTimer) == 13, "0: Blizzard's font and height")
local back = w1.SessionTimer._points[#w1.SessionTimer._points]
Check(back[5] == -9, "timer offset restored")
SetEditModeLayout(3)
Check(Size(w1.SessionTimer) == 10 and SETTINGS.QNCORE_DAMAGEHEADERSIZE:GetValue() == 10, "back to Raid: 10")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
