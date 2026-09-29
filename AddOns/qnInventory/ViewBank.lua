-- qnInventory: Bankansicht, nachgebaut wie Blizzards Bankfenster in Forever (Camelot/BankFrame.xml
-- mit BankPanelTemplate): alle Fächer hintereinander, 8 Spalten, 88 Plätze je Seite, Seitenreiter
-- rechts, darunter die Taschenplätze der Bank. Zeigt den zuletzt gespeicherten Stand, auch für den
-- eingeloggten Charakter fern der Bank.

local _, ns = ...

local L = ns.L

local COLUMNS, PER_PAGE = 8, 88
-- Breite wie BankPanel (480); im Spiel mit dem Original verglichen
local BASE_WIDTH, BASE_HEIGHT, ROW_HEIGHT = 480, 460, 47

local view = {}
ns.RegisterView("bank", view)

local frame, notice, search, bagText, money, costText, cost, purchase
local buttons, bagButtons, pageTabs = {}, {}, {}
local shown = 0
local page = 1

-- Blizzards Bankknöpfe haben einen Rahmen in Knopfgröße; ItemButton bringt einen 64×64 großen mit
local function FitNormalTexture(b)
	local normal = b:GetNormalTexture()
	normal:ClearAllPoints()
	normal:SetAllPoints()
end

-- Kaufen, Sortieren: nur beim Bankier; hier abgeschaltet, mit Hinweis
local function Disable(b, tooltip)
	b:SetEnabled(false)
	b:SetMotionScriptsWhileDisabled(true)
	qnCore.UI.Tooltip(b, tooltip)
end

local function Button(i)
	local b = buttons[i]
	if not b then
		b = ns.CreateItemButton(frame)
		FitNormalTexture(b)
		local bg = b:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetAtlas("bags-item-bankslot64", TextureKitConstants.IgnoreAtlasSize)
		buttons[i] = b
	end
	return b
end

local function ShownButtons()
	local list = {}
	for i = 1, shown do
		list[i] = buttons[i]
	end
	return list
end

-- Taschenplatz der Bank (wie BankItemButtonBagTemplate, ohne Kauf und Ziehen)
local function BagButton(i)
	local b = bagButtons[i]
	if not b then
		b = ns.CreateItemButton(frame)
		b:SetScale(0.75)
		FitNormalTexture(b)
		b:GetNormalTexture():SetAtlas("bank-frame-bag-slotframe", TextureKitConstants.IgnoreAtlasSize)
		local bg = b:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetAtlas("bank-frame-bag-slot-bg")
		b.DisabledOverlay = b:CreateTexture(nil, "ARTWORK", nil, 1)
		b.DisabledOverlay:SetAllPoints()
		b.DisabledOverlay:SetAtlas("bankslot-icon-lock")
		if i == 1 then
			b:SetPoint("TOPLEFT", bagText, "TOPRIGHT", 20, 5)
		else
			b:SetPoint("TOPLEFT", bagButtons[i - 1], "TOPLEFT", 50, 0)
		end
		b:HookScript("OnEnter", function(self)
			if not self.link then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(self.DisabledOverlay:IsShown() and BANK_BAG_PURCHASE or BANK_BAG)
				GameTooltip:Show()
			end
		end)
		bagButtons[i] = b
	end
	return b
end

local function PageTab(i)
	local tab = pageTabs[i]
	if not tab then
		tab = CreateFrame("Frame", nil, frame, "BankPageTabTemplate")
		if i == 1 then
			tab:SetPoint("TOPLEFT", frame, "TOPRIGHT", 3, -60)
		else
			tab:SetPoint("TOPLEFT", pageTabs[i - 1], "BOTTOMLEFT", 0, -2)
		end
		-- eigener Klick statt BankPanelMixin.PageSelected (das gehört Blizzards Bankfenster)
		tab:SetCustomOnMouseUpHandler(function(self, button, upInside)
			if button == "LeftButton" and upInside then
				page = self.pageNumber
				view:Refresh()
			end
		end)
		pageTabs[i] = tab
	end
	return tab
end

local function Create()
	frame = CreateFrame("Frame", "qnInventoryBankFrame", UIParent, "PortraitFrameTemplate")
	frame:SetSize(BASE_WIDTH, BASE_HEIGHT)
	frame:SetPortraitToAsset("Interface/ICONS/INV_SideTab_Bank_c60")
	frame:SetTitle(BANK)
	ns.SetupWindow(frame)

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAtlas("bank-frame-background")
	bg:SetHorizTile(true)
	bg:SetVertTile(true)
	bg:SetPoint("TOPLEFT", 0, -20)
	bg:SetPoint("BOTTOMRIGHT", 0, 30)

	local divider = frame:CreateTexture(nil, "ARTWORK")
	divider:SetAtlas("bank-divider", TextureKitConstants.UseAtlasSize)
	divider:SetScale(0.48)
	divider:SetPoint("BOTTOM", 0, 220)

	bagText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge2")
	bagText:SetText(BAGSLOTTEXT_COLON)
	bagText:SetPoint("BOTTOMLEFT", 43, 80)

	search = ns.CreateSearchBox(frame, ShownButtons)
	search:SetPoint("TOPRIGHT", -56, -33)
	search:SetWidth(110)

	-- Sortierknopf wie BankAutoSortButtonTemplate
	local sort = CreateFrame("Button", nil, frame)
	sort:SetSize(28, 26)
	sort:SetPoint("LEFT", search, "RIGHT", 8, -1)
	sort:SetNormalAtlas("bags-button-autosort-up")
	sort:GetNormalTexture():SetDesaturated(true)
	Disable(sort, L["Sorting is only possible at a banker."])

	-- Preis des nächsten Fachs wie BagCost, MoneyDisplay und PurchaseButton
	costText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed3")
	costText:SetText(COSTS_LABEL)
	costText:SetHeight(12)
	costText:SetPoint("BOTTOMLEFT", 101, 45)
	cost = CreateFrame("Frame", "qnInventoryBankFrameCostFrame", frame, "SmallMoneyFrameTemplate")
	MoneyFrame_SetType(cost, "STATIC")
	cost:UnregisterAllEvents()
	cost:SetPoint("TOPLEFT", costText, "TOPRIGHT", 8, 0)
	purchase = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	purchase:SetSize(124, 21)
	purchase:SetText(BANKSLOTPURCHASE)
	purchase:SetPoint("TOPLEFT", cost, "TOPRIGHT", 8, 4)
	Disable(purchase, L["Purchasing is only possible at a banker."])

	-- Gold des Charakters unten rechts wie BankPanelMoneyFrameTemplate (ohne Ein-/Auszahlen)
	local border = CreateFrame("Frame", nil, frame, "ThinGoldEdgeTemplate")
	border:SetSize(178, 19)
	border:SetPoint("BOTTOMRIGHT", -6, 6)
	money = CreateFrame("Frame", "qnInventoryBankFrameMoneyFrame", frame, "SmallMoneyFrameTemplate")
	MoneyFrame_SetType(money, "STATIC")
	money:UnregisterAllEvents()
	money:SetPoint("RIGHT", border)

	notice = ns.CreateNotice(frame)
	notice:SetText(L["This character's bank has not been recorded yet. Opening the bank with it once is enough."])

	ns.AttachHeader(frame, "bank")
end

-- Plätze aller Fächer hintereinander, wie BankPanelMixin:GenerateItemSlotsForSelectedTab
local function AllSlots(tabs)
	local slots = {}
	for _, tab in ipairs(tabs) do
		for slot = 1, tab.size do
			slots[#slots + 1] = tab.items[slot] or false
		end
	end
	return slots
end

local function LayoutPage(slots)
	local pages = math.max(1, math.ceil(#slots / PER_PAGE))
	page = math.min(page, pages)
	local first = (page - 1) * PER_PAGE
	shown = math.min(PER_PAGE, #slots - first)
	local rowStart
	for i = 1, shown do
		local b = Button(i)
		b:ClearAllPoints()
		if i == 1 then
			b:SetPoint("TOPLEFT", frame, "TOPLEFT", 47, -63)
			rowStart = b
		elseif i % COLUMNS == 1 then
			b:SetPoint("TOPLEFT", rowStart, "BOTTOMLEFT", 0, -10)
			rowStart = b
		else
			b:SetPoint("TOPLEFT", buttons[i - 1], "TOPRIGHT", 13, 0)
		end
		local entry = slots[first + i] or nil
		ns.SetItem(b, entry)
		-- wie CamelotBankPanelItemButtonMixin:Refresh
		b:GetNormalTexture():SetAtlas(entry and "bank-frame-bag-slotframe" or "bank-frame-item-slotframe",
			TextureKitConstants.IgnoreAtlasSize)
		b:Show()
	end
	return pages
end

function view:Refresh()
	local char = ns.CharFromKey(self.key)
	local tabs = char and char.bankTabs
	local pages = 0
	shown = 0
	if tabs then
		pages = LayoutPage(AllSlots(tabs))
	end
	for i = shown + 1, #buttons do
		buttons[i]:Hide()
	end
	notice:SetShown(not tabs)

	-- Seitenreiter
	for i = 1, pages do
		local tab = PageTab(i)
		tab:SetPageInfo(Enum.BankType.Character, i, page)
		tab:Show()
	end
	for i = pages + 1, #pageTabs do
		pageTabs[i]:Hide()
	end

	-- Taschenplätze ab dem zweiten Fach (das erste ist die Bank selbst)
	local maxTabs = tabs and char.bankMaxTabs or 0
	bagText:SetShown(maxTabs > 1)
	for i = 1, math.max(maxTabs - 1, #bagButtons) do
		local b = BagButton(i)
		if i < maxTabs then
			local tab = tabs[i + 1]
			local link = tab and tab.link
			ns.SetItem(b, link and { link, 1 })
			if tab and not link then
				SetItemButtonTexture(b, nil)
			end
			b.DisabledOverlay:SetShown(not tab)
			b:Show()
		else
			b:Hide()
		end
	end

	local tabCost = tabs and char.bankTabCost
	costText:SetShown(tabCost ~= nil)
	cost:SetShown(tabCost ~= nil)
	purchase:SetShown(tabCost ~= nil)
	MoneyFrame_Update(cost, tabCost or 0)
	MoneyFrame_Update(money, char and char.money or 0)

	local rows = math.ceil(shown / COLUMNS)
	frame:SetHeight(BASE_HEIGHT + math.max(0, rows - 6) * ROW_HEIGHT)
	search.Apply()
end

function view:Show(key)
	if not frame then Create() end
	if self.key ~= key then page = 1 end
	self.key = key
	if not frame:IsShown() then
		ns.PlaceBeside(frame, BankFrame, 50)
	end
	self:Refresh()
	frame:Show()
end
