-- Szenario 5: qnInventory mit Titan – Plugins Bank/Taschen und Gold, Fraktionsfilter, Optionsseite
--   * Titan wird nachgebildet (nur, was Titan.lua anfasst); Farben/Beträge als lesbare Marken
--   * Leiste: "Bank: ?" solange die Bank nie offen war, "Taschen: belegt/vorhanden"
--   * Tooltips: je Fraktion ein Block mit Summe; nur die eigene Fraktion (und unbekannte), mit Option beide
--   * Accountbank: Gold jederzeit, Inhalt beim Bankier mit Sichtrecht; in Titan- und Item-Tooltip
--   * Charakterauswahl der Ansichten: andere Fraktion nur mit Option
--   * Löschen über die Optionsseite (Rückfrage)

-- Titan-Nachbau ------------------------------------------------------------------
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
Titan_Global = { colors = { alliance = "00adf0", horde = "ff2934" } }
local registered = {}
function TitanUtils_PluginToRegister(self) registered[#registered + 1] = self end
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

-- Laden ----------------------------------------------------------------------------
C_AddOns.IsAddOnLoaded = function(name) return name == "Titan" end
-- Taschen des eingeloggten Charakters: Rucksack Platz 1 und Tasche 1 Platz 2 belegt, je 16 Plätze
local CONTENT = { [0] = { [1] = { itemID = 100, stackCount = 5 } }, [1] = { [2] = { itemID = 200 } } }
C_Container.GetContainerItemInfo = function(bag, slot) return CONTENT[bag] and CONTENT[bag][slot] end
local itemTooltip
TooltipDataProcessor.AddTooltipPostCall = function(_, fn) itemTooltip = fn end

LoadAddon("qnCore")
local inv = LoadAddon("qnInventory")
function LibStub(name) if name == "AceLocale-3.0" then return { GetLocale = function() return TLOC end } end end

local bankBtn, goldBtn = _G.TitanPanelqnInvBankButton, _G.TitanPanelqnInvGoldButton
Check(bankBtn and goldBtn, "Plugin-Knöpfe nach Titans Namensschema angelegt")
Check(bankBtn._template == "TitanPanelComboTemplate" and bankBtn.registry.id == "qnInvBank" and goldBtn.registry.id == "qnInvGold",
	"Vorlage und registry.id")
for _, b in ipairs({ bankBtn, goldBtn }) do
	VARS[b.registry.id] = CopyTable(b.registry.savedVariables)
end

local function Tank(t) return { size = 16, items = t or {} } end
qnInventoryDB = { realms = { Realm = {
	Alli = { class = "MAGE", faction = "Alliance", money = 100, containers = { [0] = Tank({ [1] = {} }) },
		bankTabs = { Tank({ [1] = {}, [2] = {} }), Tank() } },
	Hordi = { class = "ROGUE", faction = "Horde", money = 500 },
	Alt = { class = "PRIEST", money = 7 },   -- Fraktion unbekannt (vor 0.3.0 gespeichert)
} } }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local me = qnInventoryDB.realms.Realm.Tester
Check(me.faction == "Alliance", "Fraktion des eingeloggten Charakters gespeichert")
Check(inv.options.bothFactions == false and inv.options.viewsBothFactions == false, "Optionen: andere Fraktion aus (Opt-in)")

-- Leiste ---------------------------------------------------------------------------
local l1, v1, l2, v2 = bankBtn.registry.buttonTextFunction("qnInvBank")
local slots = 16 * (NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1)
Check(l1 == inv.L["Bank: "] and v1 == "<grau>?" and l2 == "Taschen: " and v2 == "<weiß>2/" .. slots,
	"Leiste Bank/Taschen: " .. tostring(l1) .. tostring(v1) .. tostring(l2) .. tostring(v2))
local used, total = inv.Titan.BankSlots(qnInventoryDB.realms.Realm.Alli)
Check(used == 2 and total == 32, "Bankplätze aus den Fächern gezählt")
Check(inv.Titan.SlotText(10, 16, true) == "<gelb>10/16" and inv.Titan.SlotText(15, 16, true) == "<rot>15/16"
	and inv.Titan.SlotText(5, 16, false) == "<hell>5/16", "Farben nach Füllstand wie TitanBag")
local gl, gv = goldBtn.registry.buttonTextFunction("qnInvGold")
Check(gl == "Gold: " and gv == "$" .. (12345 + 100 + 7) .. "c", "Leiste Gold: alle gezeigten Charaktere: " .. tostring(gv))
VARS.qnInvGold.ViewAll = false
_, gv = goldBtn.registry.buttonTextFunction("qnInvGold")
Check(gv == "$12345c", "Leiste Gold: nur dieser Charakter")
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
Check(gold:find(allyBlock, 1, true), "Gold: Block der eigenen Fraktion mit Summe:\n" .. gold)
Check(gold:find("<gold>Gesamtes Gold auf:|<grau>" .. UNKNOWN, 1, true) and gold:find("Gesamtes Gold:|$7c", 1, true),
	"Gold: eigener Block für unbekannte Fraktion")
Check(not gold:find("Hordi", 1, true), "Gold: andere Fraktion ohne Option nicht gezeigt")
Check(gold:find("<gold>" .. TOTAL .. ":|$12452c", 1, true) and gold:find("Sitzungsstatistik", 1, true),
	"Gold: Summe über alle Blöcke, Sitzung")
Check(not gold:find(ACCOUNT_BANK_PANEL_TITLE, 1, true), "Gold: leere Accountbank ohne Zeile")
local bank = TipText(bankBtn.registry.tooltipTemplateFunction)
local bankBlock = table.concat({ "<gold>" .. inv.L["Belegte Plätze auf"] .. ":|" .. ALLY, SPACER,
	"|cffffffffAlli|r|<grau>" .. BANK .. " <weiß>2/32   <grau>" .. HUD_EDIT_MODE_BAGS_LABEL .. " <weiß>1/16" }, "\n")
Check(bank:find(bankBlock, 1, true) and bank:find("<grau>" .. UNKNOWN, 1, true) and not bank:find("Hordi", 1, true),
	"Bank/Taschen: Blöcke je Fraktion:\n" .. bank)

inv.options.bothFactions = true
gold = TipText(goldBtn.registry.tooltipTemplateFunction)
Check(gold:find("<gold>Gesamtes Gold auf:|" .. HORDE .. "\n" .. SPACER .. "\n|cffffffffHordi|r|$500c\n" .. SPACER .. "\nGesamtes Gold:|$500c", 1, true),
	"Option: eigener Horde-Block")
local pA, pH = gold:find(ALLY, 1, true), gold:find(HORDE, 1, true)
Check(pA and pH and pA < pH, "eigene Fraktion zuerst")
bank = TipText(bankBtn.registry.tooltipTemplateFunction)
Check(bank:find(HORDE, 1, true) and bank:find("Hordi", 1, true), "Option: Horde-Block im Bank-Tooltip")
inv.options.bothFactions = false

-- Accountbank ------------------------------------------------------------------------
QN_ACCOUNT_BANK.money = 1000
FireEvent("ACCOUNT_MONEY")
Check(qnInventoryDB.account.money == 1000, "Gold der Accountbank gespeichert")
gold = TipText(goldBtn.registry.tooltipTemplateFunction)
Check(gold:find("<gold>" .. ACCOUNT_BANK_PANEL_TITLE .. ":|$1000c", 1, true) and gold:find("<gold>" .. TOTAL .. ":|$13452c", 1, true),
	"Gold: Accountbank und Summe samt Accountbank")
_, gv = goldBtn.registry.buttonTextFunction("qnInvGold")
Check(gv == "$13452c", "Leiste Gold: alle samt Accountbank")
C_Bank.FetchPurchasedBankTabData = function(t) return t == Enum.BankType.Account and { { ID = 12 } } or {} end
CONTENT[12] = { [1] = { itemID = 100, stackCount = 3 } }
FireEvent("BANKFRAME_OPENED")
Check(qnInventoryDB.account.bank == nil, "Accountbank ohne Sichtrecht nicht gelesen")
QN_ACCOUNT_BANK.view = true
FireEvent("BANK_TABS_CHANGED")
FireEvent("BANKFRAME_CLOSED")
local acc = qnInventoryDB.account
Check(acc.bank and acc.bank[100] == 3 and acc.bankTabs[1].id == 12 and acc.bankTabs[1].size == 16, "Accountbank gelesen")
bank = TipText(bankBtn.registry.tooltipTemplateFunction)
Check(bank:find("<gold>" .. ACCOUNT_BANK_PANEL_TITLE .. ":|<weiß>1/16", 1, true), "Bank-Tooltip: Plätze der Accountbank")
local lines = {}
GameTooltip.AddLine = function(_, t) lines[#lines + 1] = t end
GameTooltip.AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. "|" .. tostring(b) end
itemTooltip(GameTooltip, { id = 100 })
local itemText = table.concat(lines, ";")
Check(itemText:find(ACCOUNT_BANK_PANEL_TITLE .. "|3", 1, true) and itemText:find(TOTAL .. "|8", 1, true),
	"Item-Tooltip: Accountbank mitgezählt: " .. itemText)

-- Menü -------------------------------------------------------------------------------
menu = {}
goldBtn.registry.menuContextFunction(goldBtn, {})
Check(menu[1].label == "Liste:ViewAll" and menu[#menu].label == OPTIONS, "Gold-Menü: Anzeige, Sitzung, Optionen")

-- Aktualisierung nach Datenänderung ------------------------------------------------
updated = {}
FireEvent("PLAYER_MONEY")
Check(updated.qnInvBank and updated.qnInvGold, "Leiste nach Geldänderung aufgefrischt")

-- Charakterauswahl der Ansichten -------------------------------------------------------
local function Keys(list)
	local keys = {}
	for i, e in ipairs(list) do keys[i] = e[1]:gsub("^.-\t", "") end
	return table.concat(keys, ",")
end
Check(Keys(inv.CharEntries()) == "Alli,Alt,Tester", "Ansichten: ohne andere Fraktion: " .. Keys(inv.CharEntries()))
SETTINGS.QNINVENTORY_VIEWSBOTHFACTIONS:SetValue(true)
Check(Keys(inv.CharEntries()) == "Alli,Alt,Hordi,Tester", "Ansichten: Option schließt die andere Fraktion ein")

-- Löschen über die Optionsseite ----------------------------------------------------
local pick = SETTINGS.QNINVENTORY_DELETECHAR
Check(pick and pick:GetValue() == "", "Auswahl zum Löschen anfangs leer")
pick:SetValue(inv.CharKey("Realm", "Hordi"))
StaticPopupDialogs.QNINVENTORY_DELETE_CHAR.OnAccept(nil, pick:GetValue())
Check(qnInventoryDB.realms.Realm.Hordi == nil and pick:GetValue() == "", "Charakter gelöscht, Auswahl zurückgesetzt")
StaticPopupDialogs.QNINVENTORY_DELETE_CHAR.OnAccept(nil, inv.PlayerKey())
Check(qnInventoryDB.realms.Realm.Tester ~= nil, "eingeloggter Charakter bleibt")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
