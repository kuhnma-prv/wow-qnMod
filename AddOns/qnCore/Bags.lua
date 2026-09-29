-- qnCore: bag automation.
-- Opens or closes the bags when the auction house, bank, merchant etc. open and
-- close. Per location one choice for opening and one switch for closing.
--
-- "Same at every location" (sameEverywhere): one choice applies to every location.
-- The settings always apply account-wide (qnCoreDB.global.bags), without profile and
-- without character binding.

local _, ns = ...
local L = ns.L

local Bags = {}
ns.Bags = Bags

-- When the location opens
Bags.OPEN_MODES = {
	{ "none", L["Do nothing"] },
	{ "all", BINDING_NAME_OPENALLBAGS },
	{ "backpack", L["Backpack only"] },
	{ "closed", L["Close all bags"] },
}

-- Locations (events of the Forever client)
Bags.VENUES = {
	{ key = "auction", label = BUTTON_LAG_AUCTIONHOUSE, open = "AUCTION_HOUSE_SHOW", close = "AUCTION_HOUSE_CLOSED" },
	{ key = "bank", label = BANK, open = "BANKFRAME_OPENED", close = "BANKFRAME_CLOSED" },
	{ key = "gbank", label = GUILD_BANK, open = "GUILDBANKFRAME_OPENED", close = "GUILDBANKFRAME_CLOSED" },
	{ key = "merchant", label = MERCHANT, open = "MERCHANT_SHOW", close = "MERCHANT_CLOSED" },
	{ key = "trade", label = L["Player Trading Frame"], open = "TRADE_SHOW", close = "TRADE_CLOSED" },
	{ key = "mail", label = MINIMAP_TRACKING_MAILBOX, open = "MAIL_SHOW", close = "MAIL_CLOSED" },
}

Bags.defaults = {
	enabled = true,
	sameEverywhere = false,
	allOpen = "all",
	allClose = true,
	openProfessionBags = true,   -- when opening all own bags, also open profession bags (like Blizzard)
}
for _, v in ipairs(Bags.VENUES) do
	Bags.defaults[v.key .. "Open"] = "all"
	Bags.defaults[v.key .. "Close"] = true
end

---------------------------------------------------------------------------
-- Settings (account-wide)
---------------------------------------------------------------------------

function Bags.Config()
	return ns.global.bags
end

---------------------------------------------------------------------------
-- Profession bags (herb, enchanting, mining bag ..., reagent bag)
-- Blizzard opens them along with "Open All Bags". If that is unchecked, they are
-- closed again afterwards. Clicked individually they still open.
-- With combined bags, profession bags in slots 1-4 sit in the shared
-- window and cannot be closed separately (CloseBag would close the whole window);
-- then it only affects the reagent bag.
---------------------------------------------------------------------------

-- Like ContainerFrame_IsProfessionBag / ContainerFrame_IsReagentBag in Blizzard's ContainerFrame.lua
local function IsProfessionBag(id)
	if id == Enum.BagIndex.ReagentBag then
		return true
	end
	return IsInventoryItemProfessionBag("player", C_Container.ContainerIDToInventoryID(id)) and true or false
end

local function CloseProfessionBags()
	local cfg = Bags.Config()
	if not cfg.enabled or cfg.openProfessionBags then
		return
	end
	for id = 1, NUM_TOTAL_BAG_FRAMES do
		if IsBagOpen(id) and IsProfessionBag(id) and not ContainerFrameSettingsManager:IsUsingCombinedBags(id) then
			CloseBag(id)
		end
	end
end

local function HookOpenAllBags()
	-- Blizzard reports every "Open All Bags" (B key, merchant, bank, qnCore ...) here
	EventRegistry:RegisterCallback("ContainerFrame.OpenAllBags", CloseProfessionBags, Bags)
end

---------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------

-- Setting of a location (what = "Open" or "Close"); with "Same at every location" the shared one
local function Setting(cfg, venue, what)
	return cfg[(cfg.sameEverywhere and "all" or venue.key) .. what]
end

local function OnOpen(venue)
	local cfg = Bags.Config()
	if not cfg.enabled then
		return
	end
	local mode = Setting(cfg, venue, "Open")
	if mode == "all" or mode == "backpack" or mode == "closed" then
		-- Close everything first: OpenAllBags does nothing while a bag is open.
		CloseAllBags()
		if mode == "backpack" then
			OpenBackpack()
		elseif mode == "all" then
			OpenAllBags()
		end
	end
end

local function OnClose(venue)
	local cfg = Bags.Config()
	if cfg.enabled and Setting(cfg, venue, "Close") then
		CloseAllBags()
	end
end

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

function Bags.Init()
	HookOpenAllBags()

	-- one frame later (Blizzard's own windows have already opened bags by then), several
	-- events in the same frame only once
	for _, v in ipairs(Bags.VENUES) do
		ns.events.Register(v.open, qnCore.Debounce(function() OnOpen(v) end))
		ns.events.Register(v.close, qnCore.Debounce(function() OnClose(v) end))
	end
end
