-- qnInventory: record bags, bank and gold of the logged-in character.
-- The bank is only readable while the bank window is open; afterwards
-- the last stored state applies.
-- Stored are the totals per item (tooltip) and the content per slot (views, View*.lua).
-- The account bank (shared by all characters of the account) lives in qnInventoryDB.account;
-- its gold is readable at any time, its content only at the banker.

local _, ns = ...
local IsSecret = ns.IsSecret

local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo

local bankOpen = false

-- Backpack, bags 1-4, reagent bag, keyring
local BAG_IDS = {}
for bag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
	BAG_IDS[#BAG_IDS + 1] = bag
end
BAG_IDS[#BAG_IDS + 1] = Enum.BagIndex.Keyring

-- Purchased tabs of the character bank (Forever: CharacterBankTab_1 ...) or of the account bank
local function BankIDs(bankType)
	local ids = {}
	for _, tab in ipairs(C_Bank.FetchPurchasedBankTabData(bankType or Enum.BankType.Character)) do
		ids[#ids + 1] = tab.ID
	end
	return ids
end

-- Link of the bag that forms the container (bags 1-4, bank tabs from the second on), otherwise nil.
-- Whether ContainerIDToInventoryID also knows bank tabs can only be checked in game, hence pcall.
local function BagLink(bag)
	if bag <= Enum.BagIndex.Backpack then return end
	local ok, invID = pcall(C_Container.ContainerIDToInventoryID, bag)
	if ok and invID then
		return GetInventoryItemLink("player", invID)
	end
end

-- Reads the containers: totals per item and content per slot
--   counts     { [itemID] = count }
--   containers { [container ID] = { size, link, items = { [slot] = { link, count } } } }
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
	ns.DataChanged("bags")
end

-- Reads the tabs of a bank: totals per item and tabs in the order of the bank window
local function ReadBank(bankType)
	local ids = BankIDs(bankType)
	local counts, containers = Read(ids)
	local tabs = {}
	for i, id in ipairs(ids) do
		local tab = containers[id]
		tab.id = id
		tabs[i] = tab
	end
	return counts, tabs
end

local function ScanBank()
	if not bankOpen then return end
	ns.char.bank, ns.char.bankTabs = ReadBank(Enum.BankType.Character)
	ns.char.bankMaxTabs = C_Bank.FetchMaxNumBankTabs(Enum.BankType.Character)
	local nextTab = C_Bank.FetchNextPurchasableBankTabData(Enum.BankType.Character)
	ns.char.bankTabCost = nextTab and nextTab.tabCost
	ns.DataChanged("bank")
end

-- Account bank: only at the banker and if this character may view it
local function ScanAccountBank()
	if not bankOpen or not C_Bank.CanViewBank(Enum.BankType.Account) then return end
	ns.account.bank, ns.account.bankTabs = ReadBank(Enum.BankType.Account)
	ns.DataChanged("account")
end

local function ScanAccountMoney()
	local money = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
	if not IsSecret(money) and type(money) == "number" then
		ns.account.money = money
		ns.DataChanged("account")
	end
end

local function ScanMoney()
	ns.char.money = GetMoney()
	ns.DataChanged("bags")
end

function ns.InitScan()
	local events = ns.events
	events.Register("PLAYER_ENTERING_WORLD", function()
		ScanBags()
		ScanMoney()
		ScanAccountMoney()
	end)
	events.Register("BAG_UPDATE_DELAYED", function()
		ScanBags()
		ScanBank()
		ScanAccountBank()
	end)
	events.Register("PLAYER_MONEY", ScanMoney)
	events.Register("ACCOUNT_MONEY", ScanAccountMoney)
	-- fires per changed slot; count several slots at once only once
	events.Register("PLAYERBANKSLOTS_CHANGED", qnCore.Debounce(ScanBank))
	events.Register("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", qnCore.Debounce(ScanAccountBank))
	events.Register("BANK_TABS_CHANGED", function()
		ScanBank()
		ScanAccountBank()
	end)
	events.Register("BANKFRAME_OPENED", function()
		bankOpen = true
		ScanBank()
		ScanAccountBank()
	end)
	events.Register("BANKFRAME_CLOSED", function()
		bankOpen = false
	end)
end
