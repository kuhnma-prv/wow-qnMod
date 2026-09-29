-- Scenario 1: migration from the old format, profile switching, bags, profile page.

-- old data (before qnCore)
qnViewPortDB = { viewport = { 10, 0, 0, 0 }, color = { 0, 0, 0, 1 }, dual = { enabled = false, bagsOnMain = true } }
qnMeterDB = { scale = 1.2, styleVersion = 2, keepVisible = true }
qnNumKeyPadDB = { scale = 1.5, layout = "Windows" }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
local nkp = LoadAddon("qnNumKeyPad")
local vp = LoadAddon("qnViewPort")
local inv = LoadAddon("qnInventory")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

local P = qnCore.Profiles
Check(P.GetActiveKey() == nil, "no active profile before EDIT_MODE_LAYOUTS_UPDATED")
Check(meter.db.scale == 1.2 and meter.db.keepVisible == nil, "qnMeter: provisional table from old format, upgrade ran")
Check(nkp.db.scale == 1.5, "qnNumKeyPad: template from SavedVariablesPerCharacter")
Check(vp.db.suppressMessage == false and vp.db.dual.bagsMonitor == 0 and vp.db.dual.bagsOnMain == nil, "qnViewPort: old format + upgrade (viewport sets Layout.Refresh because of new monitor arrangement)")

SetEditModeLayout(3)
Check(P.GetActiveKey() == "account:Raid", "active profile = account layout Raid: " .. tostring(P.GetActiveKey()))
Check(qnMeterDB.profiles["account:Raid"] == meter.db, "qnMeter: provisional table became profile account:Raid")
Check(qnMeterDB.profiles["account:Raid"].scale == 1.2, "qnMeter: value carried over")
Check(qnNumKeyPadDB == nil, "qnNumKeyPad: old char table deleted after first switch")
Check(qnNumKeyPadProfiles.profiles["account:Raid"].scale == 1.5, "qnNumKeyPad: value in profile")
Check(qnCoreCharDB.layout == "account:Raid", "qnCoreCharDB remembers the layout")

-- change setting via the settings window
SETTINGS.QNMETER_SCALE:SetValue(1.3)
Check(meter.db.scale == 1.3, "qnMeter: proxy writes to the active profile")

-- switch to character-specific layout via Blizzard's SelectLayout (hook)
SetEditModeLayout(4, true)
local charKey = "char:Tester-Realm:Solo"
Check(P.GetActiveKey() == charKey, "switch via SelectLayout detected: " .. tostring(P.GetActiveKey()))
Check(meter.db.scale == 1.3 and meter.db ~= qnMeterDB.profiles["account:Raid"], "new profile = copy of the previous one")
SETTINGS.QNMETER_SCALE:SetValue(0.8)
Check(SETTINGS.QNMETER_SCALE:GetValue() == 0.8, "proxy reads new profile")
SetEditModeLayout(3, true)
Check(meter.db.scale == 1.3 and SETTINGS.QNMETER_SCALE:GetValue() == 1.3, "back to Raid: old value")
Check(P.GetLabel(charKey):find(qnCore.GERMAN and "charakterspezifisch" or "character%-specific"), "display name: " .. P.GetLabel(charKey))
Check(P.GetLabel("preset:1") == "preset:1", "unknown profile without description shows key")

-- qnViewPort: profile switch applies viewport
vp.db.viewport = { 0, 0, 0, 0 }
SetEditModeLayout(1)
Check(P.GetActiveKey() == "preset:1", "preset layout 1")
Check(vp.db.viewport[1] == 0, "qnViewPort: new profile takes over the current viewport")

-- bags
SetEditModeLayout(3, true)
local Bags = core.Bags
LOG = {}
FireEvent("MERCHANT_SHOW") RunTimers()
Check(table.concat(LOG, ";") == "CloseAllBags(nil);OpenAllBags(nil)", "merchant: open all bags: " .. table.concat(LOG, ";"))
SETTINGS.QNCORE_BAGS_MERCHANTOPEN:SetValue("backpack")
LOG = {}
FireEvent("MERCHANT_SHOW") RunTimers()
Check(table.concat(LOG, ";") == "CloseAllBags(nil);OpenBackpack(nil)", "merchant: backpack only")
SETTINGS.QNCORE_BAGS_SAMEEVERYWHERE:SetValue(true)
SETTINGS.QNCORE_BAGS_ALLOPEN:SetValue("none")
LOG = {}
FireEvent("MERCHANT_SHOW") RunTimers()
FireEvent("MERCHANT_CLOSED") RunTimers()
Check(table.concat(LOG, ";") == "CloseAllBags(nil)", "same everywhere: nothing on open, close on close: " .. table.concat(LOG, ";"))
Check(qnCoreDB.global.bags.sameEverywhere == true and qnCoreDB.profiles["account:Raid"].bags == nil, "bags account-wide, not in qnCore's profile")
SetEditModeLayout(4, true)
Check(Bags.Config().allOpen == "none" and Bags.Config().sameEverywhere, "bags also apply in the other profile")
Check(qnCoreCharDB.bags == nil and qnCoreCharDB.chatTimestamps == nil, "nothing stored per character")
Check(SETTINGS.QNCORE_G_BAGSSHARED == nil, "switch 'Same in all profiles' removed")local venues = {}
for _, v in ipairs(Bags.VENUES) do venues[#venues + 1] = v.key end
Check(table.concat(venues, ",") == "auction,bank,gbank,merchant,trade,mail", "venues of the Forever client: " .. table.concat(venues, ","))
Check(SETTINGS.QNCORE_BAGS_BANKBAGS == nil and SETTINGS.QNCORE_BAGS_VOIDOPEN == nil, "no bank slot / void storage option")

-- timestamp option removed (exists in the game)
Check(SETTINGS.QNCORE_CHATTIMESTAMPS == nil and core.Chat == nil, "no timestamp option anymore")
SetEditModeLayout(3, true)
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(C_CVar._v.showTimestamps == "none", "CVar showTimestamps untouched")
-- profile page
local n = P.CopyToActive(charKey)
Check(n == 4 and meter.db.scale == 0.8, "copy from char profile to active (all addons incl. qnCore): " .. n)
Check(meter.db == qnMeterDB.profiles["account:Raid"], "copy keeps the table")
n = P.Delete("preset:1")
Check(n == 4 and qnMeterDB.profiles["preset:1"] == nil and qnCoreDB.layouts["preset:1"] == nil, "delete preset:1")
Check(P.Delete("account:Raid") == 0, "active profile cannot be deleted")
P.ResetActive({ P.stores.qnMeter })
Check(meter.db.scale == 1 and nkp.db.scale == 1.5, "reset only for qnMeter: " .. meter.db.scale .. " / " .. nkp.db.scale)

-- combat: switch is deferred
QN_COMBAT = true
SetEditModeLayout(4, true)
Check(P.GetActiveKey() == "account:Raid", "no switch in combat")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(P.GetActiveKey() == charKey, "caught up after combat")

-- dropdowns in qnViewPort
local found = 0
for _, s in pairs(SETTINGS) do found = found + 1 end
print("settings registered: " .. found)
for _, cmd in ipairs({ "", "status", "x" }) do SlashCmdList.QNCORE(cmd) end
SlashCmdList.QNMETER("lock")
Check(meter.db.locked == true, "/qnm lock via Settings")
SlashCmdList.QNNUMKEYPAD("lock")
Check(nkp.db.locked == true, "/qnnkp lock")
SlashCmdList.QNINVENTORY("gold")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
