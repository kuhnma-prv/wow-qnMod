-- qnInventory: Taschen, Bank und Gold des eingeloggten Charakters erfassen.
-- Die Bank ist nur lesbar, solange das Bankfenster offen ist; danach gilt
-- der zuletzt gespeicherte Stand.
-- Gespeichert werden die Summen je Item (Tooltip) und der Inhalt je Platz (Ansichten, View*.lua).

local _, ns = ...

local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo

local bankOpen = false

-- Rucksack, Taschen 1-4, Reagenzientasche, Schlüsselbund
local BAG_IDS = {}
for bag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
	BAG_IDS[#BAG_IDS + 1] = bag
end
BAG_IDS[#BAG_IDS + 1] = Enum.BagIndex.Keyring

-- Gekaufte Fächer der Charakterbank (Forever: CharacterBankTab_1 ...)
local function BankIDs()
	local ids = {}
	for _, tab in ipairs(C_Bank.FetchPurchasedBankTabData(Enum.BankType.Character)) do
		ids[#ids + 1] = tab.ID
	end
	return ids
end

-- Link der Tasche, die den Container bildet (Taschen 1-4, Bankfächer ab dem zweiten), sonst nil.
-- Ob ContainerIDToInventoryID auch Bankfächer kennt, ist nur im Spiel prüfbar, daher pcall.
local function BagLink(bag)
	if bag <= Enum.BagIndex.Backpack then return end
	local ok, invID = pcall(C_Container.ContainerIDToInventoryID, bag)
	if ok and invID then
		return GetInventoryItemLink("player", invID)
	end
end

-- Liest die Container: Summen je Item und Inhalt je Platz
--   counts     { [itemID] = Anzahl }
--   containers { [Container-ID] = { size, link, items = { [Platz] = { Link, Anzahl } } } }
local function Read(containerIDs)
	local counts, containers = {}, {}
	for _, bag in ipairs(containerIDs) do
		local size = GetContainerNumSlots(bag)
		local items = {}
		for slot = 1, size do
			local info = GetContainerItemInfo(bag, slot)
			if info and info.itemID then
				ns.AddCount(counts, info.itemID, info.stackCount)
				items[slot] = { info.hyperlink or ("item:" .. info.itemID), info.stackCount or 1 }
			end
		end
		containers[bag] = { size = size, link = BagLink(bag), items = items }
	end
	return counts, containers
end

local function ScanBags()
	ns.char.bags, ns.char.containers = Read(BAG_IDS)
	ns.ViewChanged("bags")
end

local function ScanBank()
	if not bankOpen then return end
	local ids = BankIDs()
	local containers
	ns.char.bank, containers = Read(ids)
	-- Reihenfolge der Fächer wie im Bankfenster
	local tabs = {}
	for i, id in ipairs(ids) do
		local tab = containers[id]
		tab.id = id
		tabs[i] = tab
	end
	ns.char.bankTabs = tabs
	ns.char.bankMaxTabs = C_Bank.FetchMaxNumBankTabs(Enum.BankType.Character)
	local nextTab = C_Bank.FetchNextPurchasableBankTabData(Enum.BankType.Character)
	ns.char.bankTabCost = nextTab and nextTab.tabCost
	ns.ViewChanged("bank")
end

local function ScanMoney()
	ns.char.money = GetMoney()
	ns.ViewChanged("bags")
end

function ns.InitScan()
	local events = ns.events
	events.Register("PLAYER_ENTERING_WORLD", function()
		ScanBags()
		ScanMoney()
	end)
	events.Register("BAG_UPDATE_DELAYED", function()
		ScanBags()
		ScanBank()
	end)
	events.Register("PLAYER_MONEY", ScanMoney)
	-- kommt je geändertem Platz; mehrere Plätze auf einmal nur einmal zählen
	events.Register("PLAYERBANKSLOTS_CHANGED", qnCore.Debounce(ScanBank))
	events.Register("BANK_TABS_CHANGED", ScanBank)
	events.Register("BANKFRAME_OPENED", function()
		bankOpen = true
		ScanBank()
	end)
	events.Register("BANKFRAME_CLOSED", function()
		bankOpen = false
	end)
end
