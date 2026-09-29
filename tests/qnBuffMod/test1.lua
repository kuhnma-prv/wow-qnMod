-- Scenario 1: load qnBuffMod, log in, options, profile switch
local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
AURAS.player = {
	{ name = "Machtwort: Seelenstärke", icon = 135987, applications = 0, duration = 1800, expirationTime = 2500, sourceUnit = "player", spellId = 1243, isHelpful = true, auraInstanceID = 1 },
}
-- before login: no windows, options pages show window 1 with defaults
Check(bm.GetWindow(1) == nil and SETTINGS.QNBUFFMOD_EDITWINDOW:GetValue() == 1 and SETTINGS.QNBUFFMOD_B_BUFFSIZE1:GetValue() == bm.windowDefaults.buffSize1
	and SETTINGS.QNBUFFMOD_W_LOCKWINDOW:GetValue() == false, "before PLAYER_LOGIN: window 1 with defaults")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local ids = bm.WindowIDs()
Check(#ids == 1 and ids[1] == 1 and bm.GetWindow(1):IsEnabled(), "one window after login")
Check(type(bm.db.windows) == "table" and type(bm.db.windows[1]) == "table", "window 1 in the profile (windows[1])")
Check(#bm.GetEntries(1) == 1, "aura shown")
SetEditModeLayout(3)
Check(qnBuffModDB.profiles["account:Raid"] == bm.db, "Profil account:Raid = ns.db")
-- window option via the settings window (flat format)
SETTINGS.QNBUFFMOD_W_LOCKWINDOW:SetValue(true)
Check(bm.db.windows[1].lockWindow == true, "lockWindow saved in window 1")
SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(1)
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(30)
SETTINGS.QNBUFFMOD_G_SORTSEQ2:SetValue(2)
local w = bm.db.windows[1]
Check(w.layoutType == 1 and w.buffSize1 == 30, "layout and buttons saved")
Check(w.sortSeq2 == 2 and w.sortSeq1 == 1, "group saved, duplicate spell type in the other slot resolved")
-- sparse: default value is not saved
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(bm.windowDefaults.buffSize1)
Check(w.buffSize1 == nil, "default value omitted")
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(30)
-- color swatch keeps the opacity, opacity slider changes only a
SETTINGS.QNBUFFMOD_BGCOLORBUFF:SetValue("ff00ff00")
local c = bm.db.bgColorBUFF
Check(c[1] == 0 and c[2] == 1 and c[3] == 0 and c[4] == 0.5, "color set, opacity kept")
SETTINGS.QNBUFFMOD_BGCOLORBUFF_ALPHA:SetValue(0.3)
c = bm.db.bgColorBUFF
Check(c[1] == 0 and c[2] == 1 and c[4] == 0.3, "opacity set, color kept")
SETTINGS.QNBUFFMOD_HIDEBLIZZARDBUFFS:SetValue(false)
-- window selection and Alt-click behavior
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(1)
bm.EditWindow(1)
Check(bm.SelectedID() == 1, "window 1 selected")
-- profile switch: new layout -> copy, windows rebuilt
SetEditModeLayout(4)
local raid = qnBuffModDB.profiles["account:Raid"]
Check(bm.db ~= raid and bm.db.windows[1].buffSize1 == 30 and bm.db.windows[1].position ~= nil, "copy with window settings and position")
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(40)
Check(raid.windows[1].buffSize1 == 30, "old profile unchanged")
SetEditModeLayout(3)
Check(SETTINGS.QNBUFFMOD_B_BUFFSIZE1:GetValue() == 30, "back: window shows the Raid profile's value")
Check(#bm.WindowIDs() == 1 and bm.GetWindow(1):IsEnabled(), "one window again after the switch")
Check(bm.GetWindow(1).o.buffSize1 == 30, "window built with the Raid profile's values")
LOG = {}
SlashCmdList.QNBUFFMOD("")
local opened = false
for _, l in ipairs(LOG) do if l == "Öffne qnBuffMod" then opened = true end end
Check(opened, "/qnbuff opens the options")
Check(SLASH_QNBUFFMOD1 == "/qnbuff" and SLASH_QNBUFFMOD2 == "/qnbuffmod" and SLASH_QNBUFFMOD3 == "/qnaura", "slash commands")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
