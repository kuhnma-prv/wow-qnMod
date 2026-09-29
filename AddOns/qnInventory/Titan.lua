-- qnInventory: Titan-Plugins (nur wenn Titan geladen ist, ## OptionalDeps: Titan).
--   qnInvBank  [Bank-Symbol] Bank: 30/40  Taschen: 20/26   belegte/vorhandene Plätze des eingeloggten
--              Charakters, Farbe nach Füllstand wie TitanBag. Tooltip: je Fraktion ein Block mit
--              Summe, danach die Accountbank. Linksklick: Taschen-Ansicht, Umschalt-Linksklick: Bank.
--   qnInvGold  [Gold-Symbol] Gold: 2G 20S 53K   Tooltip wie TitanGold, aber je Fraktion ein Block
--              (Charaktere, Gesamtes Gold), danach Accountbank und Summe über alles, Sitzungsstatistik.
-- Zwei Plugins, weil Titan je Plugin genau einen Tooltip zeigt; nebeneinander wirken sie wie eines.
-- Gezeigt werden dieser und die verbundenen Realms; die andere Fraktion nur mit der Option
-- bothFactions (Options.lua). Titans eigene Texte (TitanGold, TitanBag) kommen aus Titans Lokalisierung.
-- Titan meldet Plugins beim Betreten der Welt an; die Knöpfe entstehen deshalb schon beim Laden.

local _, ns = ...
local L = ns.L

local Titan = {}
ns.Titan = Titan

local BANK_ID, GOLD_ID = "qnInvBank", "qnInvGold"
local ICON_BANK = "Interface\\Minimap\\Tracking\\Banker"
local ICON_GOLD = "Interface\\Icons\\INV_Misc_Coin_01"
local FACTION_ICON = {
	Alliance = "Interface\\FriendsFrame\\PlusManz-Alliance",
	Horde = "Interface\\FriendsFrame\\PlusManz-Horde",
}
local SPACER_LEFT, SPACER_RIGHT = "-------------------------", "----------------------"   -- wie TitanGold

-- Anteil belegter Plätze wie TitanBag: unter 50 % weiß, unter 75 % gelb, unter 90 % orange, sonst rot
local THRESHOLDS = {
	Values = { 0.5, 0.75, 0.9 },
	Colors = { HIGHLIGHT_FONT_COLOR, NORMAL_FONT_COLOR, ORANGE_FONT_COLOR, RED_FONT_COLOR },
}

local session = {}   -- money, time: Stand beim Einloggen bzw. nach „Sitzung zurücksetzen“

-- Titans Texte (AceLocale, dieselben wie TitanGold/TitanBag)
local function TL()
	return LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
end

---------------------------------------------------------------------------
-- Daten
---------------------------------------------------------------------------

-- belegte und vorhandene Plätze einer Liste von Behältern; nil, solange nichts erfasst ist
local function Count(list)
	if not list then return end
	local used, total = 0, 0
	for _, c in pairs(list) do
		total = total + (c.size or 0)
		for _ in pairs(c.items or {}) do
			used = used + 1
		end
	end
	return used, total
end

-- Taschen: Rucksack und Taschen 1-4 samt Reagenzientasche, ohne Schlüsselbund
function Titan.BagSlots(char)
	if not char.containers then return end
	local list = {}
	for bag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
		list[#list + 1] = char.containers[bag]
	end
	return Count(list)
end

-- Bank: gekaufte Fächer; nil, solange die Bank mit dem Charakter nie offen war
function Titan.BankSlots(char)
	return Count(char.bankTabs)
end

-- Rang der Fraktion in der Reihenfolge: eigene, andere, unbekannte
local function Rank(faction)
	if faction == ns.char.faction then return 1 end
	return faction == "?" and 3 or 2
end

-- Gezeigte Charaktere nach Fraktion: { { faction, chars = { { char, label }, … } }, … }
-- faction "?" = unbekannt. Je Fraktion erst dieser Realm, dann verbundene ("Name-Realm").
function Titan.Groups()
	local both = ns.options.bothFactions
	local groups, byFaction = {}, {}
	local function Add(realmDB, realm, suffix)
		for _, name in ipairs(ns.SortedChars(realmDB)) do
			local char = realmDB[name]
			if ns.FactionShown(char, both) then
				local faction = char.faction or "?"
				local g = byFaction[faction]
				if not g then
					g = { faction = faction, chars = {} }
					byFaction[faction] = g
					groups[#groups + 1] = g
				end
				local label = suffix and (name .. "-" .. realm) or name
				g.chars[#g.chars + 1] = { char = char, label = qnCore.ClassColoredName(label, char.class) }
			end
		end
	end
	Add(ns.realmDB, ns.realm)
	for _, r in ipairs(ns.ConnectedRealms()) do
		Add(r.db, r.realm, true)
	end
	table.sort(groups, function(a, b) return Rank(a.faction) < Rank(b.faction) end)
	return groups
end

local function GroupMoney(g)
	local total = 0
	for _, c in ipairs(g.chars) do
		total = total + (c.char.money or 0)
	end
	return total
end

-- Gold aller gezeigten Charaktere samt Accountbank
local function TotalMoney()
	local total = ns.account.money or 0
	for _, g in ipairs(Titan.Groups()) do
		total = total + GroupMoney(g)
	end
	return total
end

-- Plätze der Accountbank; nil, solange sie nie gesehen wurde oder kein Fach gekauft ist
function Titan.AccountSlots()
	local tabs = ns.account.bankTabs
	if tabs and #tabs > 0 then
		return Count(tabs)
	end
end

---------------------------------------------------------------------------
-- Texte
---------------------------------------------------------------------------

local function Colored(id)
	return TitanGetVar(id, "ShowColoredText")
end

-- "30/40" in der Farbe des Füllstands, "?" wenn unbekannt
function Titan.SlotText(used, total, colored)
	if not used or total == 0 then
		return TitanUtils_GetGrayText("?")
	end
	local text = ("%d/%d"):format(used, total)
	if not colored then
		return TitanUtils_GetHighlightText(text)
	end
	local color = TitanUtils_GetThresholdColor(THRESHOLDS, total > 0 and used / total or 1)
	return TitanUtils_GetColoredText(text, color)
end

-- Betrag wie TitanGold: "2G 20S 53K", Münzfarben je nach „Farbigen Text anzeigen“
function Titan.Cash(copper, colored)
	return (TitanUtils_CashToString(copper or 0, LARGE_NUMBER_SEPERATOR, DECIMAL_SEPERATOR, false, true, false, colored))
end

local function FactionName(faction)
	if faction == "Alliance" then
		return TitanUtils_GetHexText(FACTION_ALLIANCE, Titan_Global.colors.alliance)
	elseif faction == "Horde" then
		return TitanUtils_GetHexText(FACTION_HORDE, Titan_Global.colors.horde)
	end
	return TitanUtils_GetGrayText(faction == "?" and UNKNOWN or faction)
end

local function FactionIcon(faction)
	local tex = FACTION_ICON[faction]
	if not tex then return "" end
	local size = TitanPanelGetVar("FontSize") or 12
	return (" |T%s:%d:%d:2:0|t"):format(tex, size, size)
end

-- Kopf eines Fraktionsblocks: "<Titel>:"  "<Fraktion> <Symbol>", darunter die Trennlinie
local function GroupHeader(tip, title, faction)
	tip:AddDoubleLine(TitanUtils_GetGoldText(title .. ":"), FactionName(faction) .. FactionIcon(faction))
	tip:AddDoubleLine(SPACER_LEFT, SPACER_RIGHT)
end

---------------------------------------------------------------------------
-- Plugin Bank/Taschen
---------------------------------------------------------------------------

local function BankButtonText()
	if not ns.char then return end
	local colored = Colored(BANK_ID)
	local bankUsed, bankTotal = Titan.BankSlots(ns.char)
	local bagUsed, bagTotal = Titan.BagSlots(ns.char)
	return L["Bank: "], Titan.SlotText(bankUsed, bankTotal, colored),
		TL()["TITAN_BAG_BUTTON_LABEL"], Titan.SlotText(bagUsed, bagTotal, colored)
end

-- "Bank 30/40   Taschen 20/26"
local function SlotsLine(bankUsed, bankTotal, bagUsed, bagTotal, colored)
	return ("%s %s   %s %s"):format(TitanUtils_GetGrayText(BANK), Titan.SlotText(bankUsed, bankTotal, colored),
		TitanUtils_GetGrayText(HUD_EDIT_MODE_BAGS_LABEL), Titan.SlotText(bagUsed, bagTotal, colored))
end

function Titan.BankTooltip(tip)
	local colored = Colored(BANK_ID)
	tip:AddLine(L["Bank and Bags"], 1, 1, 1)
	-- je Fraktion ein Block mit eigener Summe
	for _, g in ipairs(Titan.Groups()) do
		tip:AddLine(" ")
		GroupHeader(tip, L["Used slots on"], g.faction)
		local sum = { 0, 0, 0, 0 }
		for _, c in ipairs(g.chars) do
			local bankUsed, bankTotal = Titan.BankSlots(c.char)
			local bagUsed, bagTotal = Titan.BagSlots(c.char)
			sum[1], sum[2] = sum[1] + (bankUsed or 0), sum[2] + (bankTotal or 0)
			sum[3], sum[4] = sum[3] + (bagUsed or 0), sum[4] + (bagTotal or 0)
			tip:AddDoubleLine(c.label, SlotsLine(bankUsed, bankTotal, bagUsed, bagTotal, colored))
		end
		tip:AddDoubleLine(SPACER_LEFT, SPACER_RIGHT)
		tip:AddDoubleLine(TOTAL .. ":", SlotsLine(sum[1], sum[2], sum[3], sum[4], colored))
	end
	local accountUsed, accountTotal = Titan.AccountSlots()
	if accountUsed then
		tip:AddLine(" ")
		tip:AddDoubleLine(TitanUtils_GetGoldText(ACCOUNT_BANK_PANEL_TITLE .. ":"), Titan.SlotText(accountUsed, accountTotal, colored))
	end
	tip:AddLine(" ")
	tip:AddLine(TitanUtils_GetGreenText(L["Left-click: bags, Shift-left-click: bank"]))
end

local function BankMenu(_, root)
	Titan_Menu.AddCommand(root, BANK_ID, HUD_EDIT_MODE_BAGS_LABEL, function() ns.Toggle("bags") end)
	Titan_Menu.AddCommand(root, BANK_ID, BANK, function() ns.Toggle("bank") end)
	Titan_Menu.AddCommand(root, BANK_ID, OPTIONS, function() ns.OpenOptions() end)
end

local function BankClick(_, button)
	if button == "LeftButton" then
		ns.Toggle(IsShiftKeyDown() and "bank" or "bags")
	end
end

---------------------------------------------------------------------------
-- Plugin Gold
---------------------------------------------------------------------------

local function GoldButtonText()
	if not ns.char then return end
	local money = TitanGetVar(GOLD_ID, "ViewAll") and TotalMoney() or (ns.char.money or 0)
	return TL()["TITAN_GOLD_MENU_TEXT"] .. ": ", Titan.Cash(money, Colored(GOLD_ID))
end

function Titan.GoldTooltip(tip)
	local T = TL()
	local colored = Colored(GOLD_ID)
	tip:AddLine(T["TITAN_GOLD_TOOLTIP"], 1, 1, 1)
	-- je Fraktion ein Block wie TitanGold mit eigener Summe
	local groups = Titan.Groups()
	for _, g in ipairs(groups) do
		tip:AddLine(" ")
		GroupHeader(tip, T["TITAN_GOLD_TOOLTIPTEXT"], g.faction)
		for _, c in ipairs(g.chars) do
			tip:AddDoubleLine(c.label, Titan.Cash(c.char.money, colored))
		end
		tip:AddDoubleLine(SPACER_LEFT, SPACER_RIGHT)
		tip:AddDoubleLine(T["TITAN_GOLD_TTL_GOLD"] .. ":", Titan.Cash(GroupMoney(g), colored))
	end
	-- Accountbank und Summe über alles, sobald es mehr als einen Block gibt
	local account = (ns.account.money or 0) > 0 and ns.account.money   -- leere Accountbank: keine Zeile
	if account or #groups > 1 then
		tip:AddLine(" ")
		if account then
			tip:AddDoubleLine(TitanUtils_GetGoldText(ACCOUNT_BANK_PANEL_TITLE .. ":"), Titan.Cash(account, colored))
		end
		tip:AddDoubleLine(TitanUtils_GetGoldText(TOTAL .. ":"), Titan.Cash(TotalMoney(), colored))
	end

	-- Sitzungsstatistik
	local now = GetMoney()
	local diff = now - (session.money or now)
	local hours = math.max(GetTime() - (session.time or GetTime()), 1) / 3600
	local earned = diff >= 0
	tip:AddLine(" ")
	tip:AddLine(TitanUtils_GetHighlightText(T["TITAN_GOLD_STATS_TITLE"]))
	tip:AddDoubleLine(T["TITAN_GOLD_START_GOLD"], Titan.Cash(session.money, colored))
	local color = earned and TitanUtils_GetGreenText or TitanUtils_GetRedText
	tip:AddDoubleLine(color(T[earned and "TITAN_GOLD_SESS_EARNED" or "TITAN_GOLD_SESS_LOST"]), Titan.Cash(math.abs(diff), colored))
	tip:AddDoubleLine(color(T[earned and "TITAN_GOLD_PERHOUR_EARNED" or "TITAN_GOLD_PERHOUR_LOST"]),
		Titan.Cash(math.floor(math.abs(diff) / hours), colored))
end

local function ResetSession()
	session.money, session.time = GetMoney(), GetTime()
end

local function GoldMenu(_, root)
	local T = TL()
	Titan_Menu.AddSelectorList(root, GOLD_ID, nil, "ViewAll", {
		{ L["Gold of all characters"], true },
		{ T["TITAN_GOLD_TOGGLE_PLAYER_TEXT"], false },
	})
	Titan_Menu.AddDivider(root)
	Titan_Menu.AddCommand(root, GOLD_ID, T["TITAN_GOLD_RESET_SESS_TEXT"], ResetSession)
	Titan_Menu.AddCommand(root, GOLD_ID, OPTIONS, function() ns.OpenOptions() end)
end

---------------------------------------------------------------------------
-- Anlegen
---------------------------------------------------------------------------

local CONTROLS = { ShowIcon = true, ShowLabelText = true, ShowColoredText = true, DisplayOnRightSide = true }

local function Create(id, registry, onClick)
	local button = CreateFrame("Button", "TitanPanel" .. id .. "Button", CreateFrame("Frame", nil, UIParent),
		"TitanPanelComboTemplate")
	button:SetFrameStrata("FULLSCREEN")
	registry.id = id
	registry.category = "Information"
	registry.version = ns.version
	registry.iconWidth = 16
	registry.controlVariables = CONTROLS
	button.registry = registry
	if onClick then
		button:SetScript("OnClick", function(self, mouse)
			onClick(self, mouse)
			TitanPanelButton_OnClick(self, mouse)
		end)
	end
	return button
end

function Titan.Update()
	for _, id in ipairs({ BANK_ID, GOLD_ID }) do
		TitanPanelButton_UpdateButton(id)
		local button = TitanUtils_GetButton(id)
		if button then
			TitanPanelButton_UpdateTooltip(button)
		end
	end
end

-- Ohne Titan: keine Plugins
Titan.active = C_AddOns.IsAddOnLoaded("Titan") and type(TitanUtils_PluginToRegister) == "function"
if Titan.active then
	Create(BANK_ID, {
		menuText = L["qnInventory Bank/Bags"],
		buttonTextFunction = BankButtonText,
		tooltipTemplateFunction = Titan.BankTooltip,
		menuContextFunction = BankMenu,
		icon = ICON_BANK,
		notes = L["Used bank and bag slots; the tooltip lists all characters by faction."],
		savedVariables = { ShowIcon = true, ShowLabelText = true, ShowColoredText = true, DisplayOnRightSide = false },
	}, BankClick)
	Create(GOLD_ID, {
		menuText = L["qnInventory Gold"],
		buttonTextFunction = GoldButtonText,
		tooltipTemplateFunction = Titan.GoldTooltip,
		menuContextFunction = GoldMenu,
		icon = ICON_GOLD,
		notes = L["Gold of all characters like TitanGold, from the data of qnInventory."],
		savedVariables = { ShowIcon = true, ShowLabelText = true, ShowColoredText = true, DisplayOnRightSide = false,
			ViewAll = true },
	})
end

-- aus Core.lua nach PLAYER_LOGIN
function ns.InitTitan()
	if not Titan.active then return end
	ResetSession()
	ns.OnDataChanged(Titan.Update)
end
