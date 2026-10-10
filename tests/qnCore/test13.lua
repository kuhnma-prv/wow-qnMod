-- Scenario 13: objective tracker font below Blizzard's minimum, per profile (layout)

-- qnCoreDB without profiles yet (only account-wide values)
qnCoreDB = { global = { tracking = true }, layouts = {} }

local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
SetEditModeLayout(3)

local line, header, M = ObjectiveTrackerLineFont, ObjectiveTrackerHeaderFont, ObjectiveTrackerManager
local raid = "account:Raid"
Check(type(qnCoreDB.profiles) == "table" and qnCoreDB.global.tracking == true, "qnCoreDB: profiles created, account-wide values stay")
Check(qnCoreDB.settingsVersion == "1.1" and qnCoreDB.ownProfiles == nil, "qnCoreDB: settingsVersion written, no ownProfiles marker")
Check(core.store and core.db == qnCoreDB.profiles[raid] and core.db.questTextSize == 0, "qnCore has one profile per layout, default 0")
Check(qnCore.Profiles.stores.qnCore == core.store, "qnCore appears among the profiles")
Check(M.updates == 0 and select(2, line:GetFont()) == 12, "default: Blizzard's font unchanged, no rebuild")

-- selection 10 via the settings window
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(10)
Check(select(2, line:GetFont()) == 10 and select(2, header:GetFont()) == 12, "10: lines 10, header 12: " .. select(2, line:GetFont()) .. "/" .. select(2, header:GetFont()))
Check(M.updates == 0, "no rebuild from addon code (taint): " .. M.updates)

-- Blizzard resets the font (layout, slider): own size stays, before Blizzard's rebuild
M:SetTextSize(15)
Check(select(2, line:GetFont()) == 10 and select(2, header:GetFont()) == 12, "after SetTextSize(15) back to 10/12")
local blizzUpdates = M.updates   -- Blizzard's own rebuild in SetTextSize

-- second layout: copy (10), then back to Blizzard
SetEditModeLayout(4)
Check(core.db ~= qnCoreDB.profiles[raid] and core.db.questTextSize == 10, "new layout takes over 10")
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(0)
Check(select(2, line:GetFont()) == 15 and select(2, header:GetFont()) == 17, "0: Blizzard's last set font (15/17): " .. select(2, line:GetFont()))

-- profile switch applies
SetEditModeLayout(3)
Check(select(2, line:GetFont()) == 10 and SETTINGS.QNCORE_QUESTTEXTSIZE:GetValue() == 10, "back to Raid: 10")

-- in combat: font immediately (font objects are not protected)
QN_COMBAT = true
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(8)
Check(select(2, line:GetFont()) == 8, "in combat: font 8")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(M.updates == blizzUpdates, "never a rebuild from addon code")

-- other scripts: height in proportion to the template (e.g. Chinese 15 at 12)
ObjectiveTrackerFont12:SetFont("Fonts\\ARKai_T.ttf", 15, "")
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(10)
local path, h = line:GetFont()
Check(path == "Fonts\\ARKai_T.ttf" and h == 12.5, "file and proportion of the template: " .. tostring(path) .. " " .. tostring(h))

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
