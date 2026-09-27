-- qnInventory: Taschen, Bank und Gold des eingeloggten Charakters erfassen.
-- Die Bank ist nur lesbar, solange das Bankfenster offen ist; danach gilt
-- der zuletzt gespeicherte Stand.

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

-- Zählt alle Items der Container
local function Count(containerIDs)
	local counts = {}
	for _, bag in ipairs(containerIDs) do
		for slot = 1, GetContainerNumSlots(bag) do
			local info = GetContainerItemInfo(bag, slot)
			if info and info.itemID then
				ns.AddCount(counts, info.itemID, info.stackCount)
			end
		end
	end
	return counts
end

local function ScanBags()
	ns.char.bags = Count(BAG_IDS)
end

local function ScanBank()
	if bankOpen then
		ns.char.bank = Count(BankIDs())
	end
end

local function ScanMoney()
	ns.char.money = GetMoney()
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
