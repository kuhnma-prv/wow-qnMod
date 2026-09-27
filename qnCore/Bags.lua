-- qnCore: Taschen-Automatik.
-- Öffnet bzw. schließt die Taschen, wenn Auktionshaus, Bank, Händler usw. auf- und
-- zugehen. Je Ort eine Auswahl für das Öffnen und ein Schalter für das Schließen.
--
-- "An allen Orten gleich" (sameEverywhere): eine Auswahl gilt für jeden Ort.
-- Die Einstellungen gelten immer kontoweit (qnCoreDB.global.bags), ohne Profil und
-- ohne Charakterbezug.

local _, ns = ...
local L = ns.L

local Bags = {}
ns.Bags = Bags

-- Beim Öffnen des Ortes
Bags.OPEN_MODES = {
	{ "none", L["Nichts tun"] },
	{ "all", BINDING_NAME_OPENALLBAGS },
	{ "backpack", L["Nur den Rucksack öffnen"] },
	{ "closed", L["Alle Taschen schließen"] },
}

-- Orte (Ereignisse des Forever-Clients)
Bags.VENUES = {
	{ key = "auction", label = BUTTON_LAG_AUCTIONHOUSE, open = "AUCTION_HOUSE_SHOW", close = "AUCTION_HOUSE_CLOSED" },
	{ key = "bank", label = BANK, open = "BANKFRAME_OPENED", close = "BANKFRAME_CLOSED" },
	{ key = "gbank", label = GUILD_BANK, open = "GUILDBANKFRAME_OPENED", close = "GUILDBANKFRAME_CLOSED" },
	{ key = "merchant", label = MERCHANT, open = "MERCHANT_SHOW", close = "MERCHANT_CLOSED" },
	{ key = "trade", label = L["Handel mit Spielern"], open = "TRADE_SHOW", close = "TRADE_CLOSED" },
	{ key = "mail", label = MINIMAP_TRACKING_MAILBOX, open = "MAIL_SHOW", close = "MAIL_CLOSED" },
}

Bags.defaults = {
	enabled = true,
	sameEverywhere = false,
	allOpen = "all",
	allClose = true,
	openProfessionBags = true,   -- beim Öffnen aller eigenen Taschen auch Berufstaschen (wie Blizzard)
}
for _, v in ipairs(Bags.VENUES) do
	Bags.defaults[v.key .. "Open"] = "all"
	Bags.defaults[v.key .. "Close"] = true
end

---------------------------------------------------------------------------
-- Einstellungen (kontoweit)
---------------------------------------------------------------------------

function Bags.Config()
	return ns.global.bags
end

---------------------------------------------------------------------------
-- Berufstaschen (Kräuter-, Verzauberer-, Bergbautasche …, Reagenzientasche)
-- Blizzard öffnet sie mit "Alle Taschen öffnen" mit. Ist das abgewählt, werden sie
-- danach wieder geschlossen. Einzeln angeklickt öffnen sie sich weiterhin.
-- Mit zusammengefassten Taschen stecken Berufstaschen in den Plätzen 1–4 im gemeinsamen
-- Fenster und lassen sich nicht getrennt schließen (CloseBag schlösse das ganze Fenster);
-- dann wirkt es nur auf die Reagenzientasche.
---------------------------------------------------------------------------

-- Wie ContainerFrame_IsProfessionBag / ContainerFrame_IsReagentBag in Blizzards ContainerFrame.lua
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
	-- Blizzard meldet jedes "Alle Taschen öffnen" (Taste B, Händler, Bank, qnCore …) hier
	EventRegistry:RegisterCallback("ContainerFrame.OpenAllBags", CloseProfessionBags, Bags)
end

---------------------------------------------------------------------------
-- Ausführen
---------------------------------------------------------------------------

-- Einstellung eines Ortes (what = "Open" oder "Close"), bei "An allen Orten gleich" die gemeinsame
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
		-- Erst alles schließen: OpenAllBags tut nichts, solange eine Tasche offen ist.
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

	-- einen Frame später (Blizzards eigene Fenster haben dann schon Taschen geöffnet), mehrere
	-- Meldungen im selben Frame nur einmal
	for _, v in ipairs(Bags.VENUES) do
		ns.events.Register(v.open, qnCore.Debounce(function() OnOpen(v) end))
		ns.events.Register(v.close, qnCore.Debounce(function() OnClose(v) end))
	end
end
