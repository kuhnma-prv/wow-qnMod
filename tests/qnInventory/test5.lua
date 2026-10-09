-- Scenario 5: qnInventory with Titan - bank/bags and gold plugins, faction filter, options page
--   * Titan is emulated (only what Titan.lua touches); colors/amounts as readable markers
--   * bar: "Bank: ?" as long as the bank was never open, "Taschen: used/available"
--   * tooltips: one block with total per faction; only the own faction (and unknown), with option both
--   * account bank: gold any time, contents at the banker with view permission; in Titan and item tooltip
--   * character selection of the views: other faction only with option
--   * deletion via the options page (confirmation)

-- Titan emulation ------------------------------------------------------------------
ORANGE_FONT_COLOR = ORANGE_FONT_COLOR or CreateColor(1, 0.5, 0)
HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR or CreateColor(1, 1, 1)
RED_FONT_COLOR = RED_FONT_COLOR or CreateColor(1, 0.1, 0.1)
local COLOR_NAME = { [HIGHLIGHT_FONT_COLOR] = "weiß", [NORMAL_FONT_COLOR] = "gelb", [ORANGE_FONT_COLOR] = "orange", [RED_FONT_COLOR] = "rot" }
TITAN_ID = "Titan"
local TLOC = {
	TITAN_BAG_BUTTON_LABEL = "Taschen: ", TITAN_GOLD_MENU_TEXT = "Gold", TITAN_GOLD_TOOLTIP = "Gold-Info",
	TITAN_GOLD_TOOLTIPTEXT = "Gesamtes Gold auf", TITAN_GOLD_TTL_GOLD = "Gesamtes Gold", TITAN_GOLD_STATS_TITLE = "Sitzungsstatistik",
	TITAN_GOLD_START_GOLD = "Anfängliches Gold", TITAN_GOLD_SESS_EARNED = "Eingenommen", TITAN_GOLD_SESS_LOST = "Ausgegeben",
	TITAN_GOLD_PERHOUR_EARNED = "Eingenommen pro Stunde", TITAN_GOLD_PERHOUR_LOST = "Ausgegeben pro Stunde",
	TITAN_GOLD_TOGGLE_PLAYER_TEXT = "Spielergold", TITAN_GOLD_RESET_SESS_TEXT = "Sitzung zurücksetzen",
}
Titan_G = { colors = { alliance = "00adf0", horde = "ff2934" }, plugins = {} }
local registered = {}
function Titan_G.plugins.ToRegister(self) registered[#registered + 1] = self end
local VARS = {}
function TitanGetVar(id, key) return (VARS[id] or {})[key] end
function TitanPanelGetVar() return 12 end
function TitanUtils_GetHexText(t, hex) return "<" .. hex .. ">" .. t end
function TitanUtils_GetGoldText(t) return "<gold>" .. t end
function TitanUtils_GetGrayText(t) return "<grau>" .. t end
function TitanUtils_GetGreenText(t) return "<grün>" .. t end
function TitanUtils_GetRedText(t) return "<rot>" .. t end
function TitanUtils_GetHighlightText(t) return "<hell>" .. t end
function TitanUtils_GetColoredText(t, c) return "<" .. (COLOR_NAME[c] or "?") .. ">" .. t end
function TitanUtils_GetThresholdColor(tbl, v)
	for i, limit in ipairs(tbl.Values) do
		if v < limit then return tbl.Colors[i] end
	end
	return tbl.Colors[#tbl.Colors]
end
function TitanUtils_CashToString(v, sep, dec, onlyGold, labels, icons, colored) return ("$%d%s"):format(v, colored and "c" or "") end
local updated = {}
function TitanPanelButton_UpdateButton(id) updated[id] = (updated[id] or 0) + 1 end
function TitanUtils_GetButton(id) return _G["TitanPanel" .. id .. "Button"] end
function TitanPanelButton_UpdateTooltip() end
function TitanPanelButton_OnClick() end
local menu
Titan_Menu = {
	AddCommand = function(_, _, label, fn) menu[#menu + 1] = { label = label, fn = fn } end,
	AddSelectorList = function(_, _, _, opt, list) menu[#menu + 1] = { label = "Liste:" .. opt, list = list } end,
	AddDivider = function() end,
}

-- Loading ----------------------------------------------------------------------------
C_AddOns.IsAddOnLoaded = function(name) return name == "Titan" end
-- Bags of the logged-in character: backpack slot 1 and bag 1 slot 2 used, 16 slots each
local CONTENT = { [0] = { [1] = { itemID = 100, stackCount = 5 } }, [1] = { [2] = { itemID = 200 } } }
C_Container.GetContainerItemInfo = function(bag, slot) return CONTENT[bag] and CONTENT[bag][slot] end
local itemTooltip
TooltipDataProcessor.AddTooltipPostCall = function(_, fn) itemTooltip = fn end

LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")
function LibStub(name) if name == "AceLocale-3.0" then return { GetLocale = function() return TLOC end } end end

local bankBtn, goldBtn = _G.TitanPanelqnInvBankButton, _G.TitanPanelqnInvGoldButton
Check(bankBtn and goldBtn, "plugin buttons created per Titan's naming scheme")
Check(bankBtn._template == "TitanPanelComboTemplate" and bankBtn.registry.id == "qnInvBank" and goldBtn.registry.id == "qnInvGold",
	"template and registry.id")
for _, b in ipairs({ bankBtn, goldBtn }) do
	VARS[b.registry.id] = CopyTable(b.registry.savedVariables)
end

local function Tank(t) return { size = 16, items = t or {} } end
qnInventoryDB = { realms = { Realm = {
	Alli = { class = "MAGE", faction = "Alliance", money = 100, containers = { [0] = Tank({ [1] = {} }) },
		bankTabs = { Tank({ [1] = {}, [2] = {} }), Tank() } },
	Hordi = { class = "ROGUE", faction = "Horde", money = 500 },
	Alt = { class = "PRIEST", money = 7 },   -- faction unknown (saved before 0.3.0)
} } }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local me = qnInventoryDB.realms.Realm.Tester
Check(me.faction == "Alliance", "faction of the logged-in character saved")
Check(inv.options.bothFactions == false and inv.options.viewsBothFactions == false, "options: other faction off (opt-in)")

-- Bar ---------------------------------------------------------------------------
local l1, v1, l2, v2 = bankBtn.registry.buttonTextFunction("qnInvBank")
local slots = 16 * (NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1)
Check(l1 == inv.L["Bank: "] and v1 == "<grau>?" and l2 == "Taschen: " and v2 == "<weiß>2/" .. slots,
	"bar bank/bags: " .. tostring(l1) .. tostring(v1) .. tostring(l2) .. tostring(v2))
local used, total = inv.Titan.BankSlots(qnInventoryDB.realms.Realm.Alli)
Check(used == 2 and total == 32, "bank slots counted from the tabs")
Check(inv.Titan.SlotText(10, 16, true) == "<gelb>10/16" and inv.Titan.SlotText(15, 16, true) == "<rot>15/16"
	and inv.Titan.SlotText(5, 16, false) == "<hell>5/16", "colors by fill level like TitanBag")
local gl, gv = goldBtn.registry.buttonTextFunction("qnInvGold")
Check(gl == "Gold: " and gv == "$" .. (12345 + 100 + 7) .. "c", "bar gold: all shown characters: " .. tostring(gv))
VARS.qnInvGold.ViewAll = false
_, gv = goldBtn.registry.buttonTextFunction("qnInvGold")
Check(gv == "$12345c", "bar gold: only this character")
VARS.qnInvGold.ViewAll = true

-- Tooltips -------------------------------------------------------------------------
local function TipText(fn)
	local lines = {}
	local tip = {
		AddLine = function(_, t) lines[#lines + 1] = t end,
		AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. "|" .. b end,
	}
	fn(tip)
	return table.concat(lines, "\n")
end
local ALLY = "<00adf0>" .. FACTION_ALLIANCE .. " |TInterface\\FriendsFrame\\PlusManz-Alliance:12:12:2:0|t"
local HORDE = "<ff2934>" .. FACTION_HORDE .. " |TInterface\\FriendsFrame\\PlusManz-Horde:12:12:2:0|t"
local SPACER = "-------------------------|----------------------"
local gold = TipText(goldBtn.registry.tooltipTemplateFunction)
local allyBlock = table.concat({ "<gold>Gesamtes Gold auf:|" .. ALLY, SPACER, "|cffffffffAlli|r|$100c", "|cffffffffTester|r|$12345c",
	SPACER, "Gesamtes Gold:|$12445c" }, "\n")
Check(gold:find(allyBlock, 1, true), "gold: block of the own faction with total:\n" .. gold)
Check(gold:find("<gold>Gesamtes Gold auf:|<grau>" .. UNKNOWN, 1, true) and gold:find("Gesamtes Gold:|$7c", 1, true),
	"gold: separate block for unknown faction")
Check(not gold:find("Hordi", 1, true), "gold: other faction not shown without option")
Check(gold:find("<gold>" .. TOTAL .. ":|$12452c", 1, true) and gold:find("Sitzungsstatistik", 1, true),
	"gold: total over all blocks, session")
Check(not gold:find(ACCOUNT_BANK_PANEL_TITLE, 1, true), "gold: empty account bank without line")
local bank = TipText(bankBtn.registry.tooltipTemplateFunction)
local bankBlock = table.concat({ "<gold>" .. inv.L["Used slots on"] .. ":|" .. ALLY, SPACER,
	"|cffffffffAlli|r|<grau>" .. BANK .. " <weiß>2/32   <grau>" .. HUD_EDIT_MODE_BAGS_LABEL .. " <weiß>1/16" }, "\n")
Check(bank:find(bankBlock, 1, true) and bank:find("<grau>" .. UNKNOWN, 1, true) and not bank:find("Hordi", 1, true),
	"bank/bags: blocks per faction:\n" .. bank)

inv.options.bothFactions = true
gold = TipText(goldBtn.registry.tooltipTemplateFunction)
Check(gold:find("<gold>Gesamtes Gold auf:|" .. HORDE .. "\n" .. SPACER .. "\n|cffffffffHordi|r|$500c\n" .. SPACER .. "\nGesamtes Gold:|$500c", 1, true),
	"option: separate Horde block")
local pA, pH = gold:find(ALLY, 1, true), gold:find(HORDE, 1, true)
Check(pA and pH and pA < pH, "own faction first")
bank = TipText(bankBtn.registry.tooltipTemplateFunction)
Check(bank:find(HORDE, 1, true) and bank:find("Hordi", 1, true), "option: Horde block in the bank tooltip")
inv.options.bothFactions = false

-- Account bank ------------------------------------------------------------------------
QN_ACCOUNT_BANK.money = 1000
FireEvent("ACCOUNT_MONEY")
Check(qnInventoryDB.account.money == 1000, "account bank gold saved")
gold = TipText(goldBtn.registry.tooltipTemplateFunction)
Check(gold:find("<gold>" .. ACCOUNT_BANK_PANEL_TITLE .. ":|$1000c", 1, true) and gold:find("<gold>" .. TOTAL .. ":|$13452c", 1, true),
	"gold: account bank and total including account bank")
_, gv = goldBtn.registry.buttonTextFunction("qnInvGold")
Check(gv == "$13452c", "bar gold: all including account bank")
C_Bank.FetchPurchasedBankTabData = function(t) return t == Enum.BankType.Account and { { ID = 12 } } or {} end
CONTENT[12] = { [1] = { itemID = 100, stackCount = 3 } }
FireEvent("BANKFRAME_OPENED")
Check(qnInventoryDB.account.bank == nil, "account bank not read without view permission")
QN_ACCOUNT_BANK.view = true
FireEvent("BANK_TABS_CHANGED")
FireEvent("BANKFRAME_CLOSED")
local acc = qnInventoryDB.account
Check(acc.bank and acc.bank[100] == 3 and acc.bankTabs[1].id == 12 and acc.bankTabs[1].size == 16, "account bank read")
bank = TipText(bankBtn.registry.tooltipTemplateFunction)
Check(bank:find("<gold>" .. ACCOUNT_BANK_PANEL_TITLE .. ":|<weiß>1/16", 1, true), "bank tooltip: account bank slots")
local lines = {}
GameTooltip.AddLine = function(_, t) lines[#lines + 1] = t end
GameTooltip.AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. "|" .. tostring(b) end
itemTooltip(GameTooltip, { id = 100 })
local itemText = table.concat(lines, ";")
Check(itemText:find(ACCOUNT_BANK_PANEL_TITLE .. "|3", 1, true) and itemText:find(TOTAL .. "|8", 1, true),
	"item tooltip: account bank included: " .. itemText)

-- Menu -------------------------------------------------------------------------------
menu = {}
goldBtn.registry.menuContextFunction(goldBtn, {})
Check(menu[1].label == "Liste:ViewAll" and menu[#menu].label == OPTIONS, "gold menu: display, session, options")

-- Refresh after data change ------------------------------------------------
updated = {}
FireEvent("PLAYER_MONEY")
Check(updated.qnInvBank and updated.qnInvGold, "bar refreshed after money change")

-- Character selection of the views -------------------------------------------------------
local function Keys(list)
	local keys = {}
	for i, e in ipairs(list) do keys[i] = e[1]:gsub("^.-\t", "") end
	return table.concat(keys, ",")
end
Check(Keys(inv.CharEntries()) == "Alli,Alt,Tester", "views: without other faction: " .. Keys(inv.CharEntries()))
SETTINGS.QNINVENTORY_VIEWSBOTHFACTIONS:SetValue(true)
Check(Keys(inv.CharEntries()) == "Alli,Alt,Hordi,Tester", "views: option includes the other faction")

-- Deletion via the options page ----------------------------------------------------
local pick = SETTINGS.QNINVENTORY_DELETECHAR
Check(pick and pick:GetValue() == "", "deletion selection initially empty")
pick:SetValue(inv.CharKey("Realm", "Hordi"))
StaticPopupDialogs.QNINVENTORY_DELETE_CHAR.OnAccept(nil, pick:GetValue())
Check(qnInventoryDB.realms.Realm.Hordi == nil and pick:GetValue() == "", "character deleted, selection reset")
StaticPopupDialogs.QNINVENTORY_DELETE_CHAR.OnAccept(nil, inv.PlayerKey())
Check(qnInventoryDB.realms.Realm.Tester ~= nil, "logged-in character stays")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
