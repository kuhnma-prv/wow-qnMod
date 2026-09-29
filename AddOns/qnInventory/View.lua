-- qnInventory: shared parts of the bags, bank and mail views (ViewBags/ViewBank/ViewMail).
-- The views recreate Blizzard's windows with their templates and graphics, but show the
-- stored data of any of our own characters (this or a connected realm).
-- Blizzard's windows themselves cannot be used for this: they only read the containers
-- or the mailbox of the logged-in character, the bank only at the banker.
--
-- Above every window (also above Blizzard's bags, bank and mailbox) hangs a bar with the
-- character selection and buttons for the respective other views. The logged-in character's
-- bags are always shown in Blizzard's window; bank and mail are shown in the view so they are
-- reachable away from the bank and mailbox too.

local _, ns = ...

local SEP = "\t"   -- separates realm and name in the selection key (occurs in no name)

local views = {}     -- kind ("bags", "bank", "mail") -> view
local headers = {}   -- all header bars, for refreshing after a change

-- Order of the buttons in the header bar
local KINDS = { "bags", "bank", "mail" }
local KIND_TEXT = { bags = HUD_EDIT_MODE_BAGS_LABEL, bank = BANK, mail = MAIL_LABEL }

---------------------------------------------------------------------------
-- Selection
---------------------------------------------------------------------------

function ns.CharKey(realm, name)
	return realm .. SEP .. name
end

function ns.PlayerKey()
	return ns.CharKey(ns.realm, ns.player)
end

-- Selected character of the views (default: the logged-in one)
local selected

-- Data, name and realm for a key (default: selected character); data nil if deleted
function ns.CharFromKey(key)
	local realm, name = strsplit(SEP, key or selected or ns.PlayerKey())
	local realmDB = qnInventoryDB.realms[realm]
	return realmDB and realmDB[name], name, realm
end

-- Entries of the character selection: this realm, then connected realms with "Name-Realm".
-- The other faction only with the option viewsBothFactions; allFactions = always all (options page).
function ns.CharEntries(allFactions)
	local entries = {}
	local both = allFactions == true or ns.options.viewsBothFactions
	local function Add(realmDB, realm, suffix)
		for _, name in ipairs(ns.SortedChars(realmDB)) do
			local char = realmDB[name]
			if ns.FactionShown(char, both) then
				local label = suffix and (name .. "-" .. realm) or name
				entries[#entries + 1] = { ns.CharKey(realm, name), qnCore.ClassColoredName(label, char.class) }
			end
		end
	end
	Add(ns.realmDB, ns.realm)
	for _, r in ipairs(ns.ConnectedRealms()) do
		Add(r.db, r.realm, true)
	end
	return entries
end

---------------------------------------------------------------------------
-- Views
-- A view has frame, Show(self, key) (fills and shows) and Refresh(self); key = shown
-- character.
---------------------------------------------------------------------------

function ns.RegisterView(kind, view)
	views[kind] = view
end

local function RefreshHeaders()
	for _, header in ipairs(headers) do
		header:Refresh()
	end
end

-- Shows the view kind for key (default: selected character). Bags of the logged-in
-- character: Blizzard's window.
function ns.Show(kind, key)
	selected = key or selected or ns.PlayerKey()
	local view = views[kind]
	if kind == "bags" and selected == ns.PlayerKey() then
		if view.frame then view.frame:Hide() end
		OpenAllBags()
	else
		view:Show(selected)
	end
	RefreshHeaders()
end

-- Like Show, but hides a view of the same character that is already shown
function ns.Toggle(kind, key)
	local view = views[kind]
	key = key or selected or ns.PlayerKey()
	if kind == "bags" and key == ns.PlayerKey() then
		selected = key
		if view.frame then view.frame:Hide() end
		ToggleAllBags()
		RefreshHeaders()
	elseif view.frame and view.frame:IsShown() and view.key == key then
		view.frame:Hide()
	else
		ns.Show(kind, key)
	end
end

-- Stored data of the logged-in character have changed (Scan.lua, Mail.lua)
function ns.ViewChanged(kind)
	local view = views[kind]
	if view and view.frame and view.frame:IsShown() and view.key == ns.PlayerKey() then
		view:Refresh()
	end
end

---------------------------------------------------------------------------
-- Header bar: character selection and buttons for the other views
-- live = Blizzard's window: always shows the logged-in character.
---------------------------------------------------------------------------

local BUTTON_WIDTH, DROPDOWN_WIDTH, BAR_HEIGHT = 70, 170, 24

function ns.AttachHeader(host, kind, live)
	local bar = CreateFrame("Frame", nil, host)
	bar:SetHeight(BAR_HEIGHT)
	bar:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", 0, 2)

	local function Key()
		if live then
			return ns.PlayerKey()
		end
		return views[kind].key or ns.PlayerKey()
	end

	local right, width = nil, 0
	for i = #KINDS, 1, -1 do
		local other = KINDS[i]
		if other ~= kind then
			local b = qnCore.UI.Button(bar, KIND_TEXT[other], BUTTON_WIDTH, function()
				ns.Toggle(other, Key())
			end)
			b:SetHeight(BAR_HEIGHT - 2)
			if right then
				b:SetPoint("RIGHT", right, "LEFT", -2, 0)
			else
				b:SetPoint("RIGHT")
			end
			right, width = b, width + BUTTON_WIDTH + 2
		end
	end

	local dd = qnCore.UI.Dropdown(bar, DROPDOWN_WIDTH, function() return ns.CharEntries() end, Key, function(key)
		ns.Show(kind, key)
	end)
	dd:SetPoint("RIGHT", right, "LEFT", -4, 0)
	bar:SetWidth(width + DROPDOWN_WIDTH + 4)

	function bar:Refresh()
		dd:Refresh()
	end
	headers[#headers + 1] = bar
	return bar
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

-- Movable by dragging the window area, Escape closes (name required for UISpecialFrames)
function ns.SetupWindow(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetToplevel(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	tinsert(UISpecialFrames, frame:GetName())
	frame:Hide()
end

-- On opening: next to Blizzard's open window (bank at the banker, mailbox), otherwise at the
-- position of a left Blizzard window. gap = spacing (the bank's side tabs sit on the outer right).
function ns.PlaceBeside(frame, live, gap)
	frame:ClearAllPoints()
	if live and live:IsShown() then
		frame:SetPoint("TOPLEFT", live, "TOPRIGHT", gap, 0)
	else
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
	end
end

-- Notice in the middle of the window as long as nothing is stored
function ns.CreateNotice(frame)
	local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetPoint("CENTER")
	fs:SetWidth(280)
	fs:Hide()
	return fs
end

---------------------------------------------------------------------------
-- Item buttons: link instead of container slot, tooltip via the link, click with Shift/Ctrl as
-- usual (chat link, dressing room).
---------------------------------------------------------------------------

-- Anchor as for Blizzard's bag slots (ContainerFrameItemButton_CalculateItemTooltipAnchors);
-- with qnViewPort then fully onto the bag's monitor.
local function ItemOnEnter(self)
	if not self.link then return end
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)
	GameTooltip:SetHyperlink(self.link)
	GameTooltip:Show()
	local vp = _G.qnViewPort   -- optional addon
	if vp and vp.BagTooltip then
		vp.BagTooltip(GameTooltip, self)
	end
end

local function ItemOnClick(self)
	if self.link then
		HandleModifiedItemClick(self.link)
	end
end

function ns.CreateItemButton(parent)
	local b = CreateFrame("ItemButton", nil, parent)
	b:SetScript("OnEnter", ItemOnEnter)
	b:SetScript("OnLeave", GameTooltip_Hide)
	b:SetScript("OnClick", ItemOnClick)
	return b
end

local function SetQuality(b, link)
	local quality = C_Item.GetItemQualityByID(link)
	if quality then
		SetItemButtonQuality(b, quality, link)
		return
	end
	-- item not cached yet: add the border once the data is available
	SetItemButtonQuality(b, nil)
	local itemID = C_Item.GetItemInfoInstant(link)
	if not itemID then return end
	Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
		if b.link == link then
			SetItemButtonQuality(b, C_Item.GetItemQualityByID(link), link)
		end
	end)
end

-- entry = { link, count } or nil (empty slot)
function ns.SetItem(b, entry)
	local link = entry and entry[1]
	b.link = link
	if link then
		SetItemButtonTexture(b, C_Item.GetItemIconByID(link))
		SetItemButtonCount(b, entry[2])
		SetQuality(b, link)
	else
		SetItemButtonTexture(b, nil)
		SetItemButtonCount(b, 0)
		SetItemButtonQuality(b, nil)
	end
	if b.searchOverlay then
		b.searchOverlay:Hide()
	end
end

---------------------------------------------------------------------------
-- Search: buttons whose item does not match the search text are dimmed (like Blizzard's search)
---------------------------------------------------------------------------

local function Matches(link, text)
	local name = C_Item.GetItemInfo(link)
	return name and name:lower():find(text, 1, true) ~= nil
end

-- buttons() returns the shown item buttons
function ns.CreateSearchBox(frame, buttons)
	local box = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
	box:SetHeight(20)
	function box.Apply()
		local text = box:GetText():lower()
		for _, b in ipairs(buttons()) do
			b.searchOverlay:SetShown(text ~= "" and not (b.link and Matches(b.link, text)))
		end
	end
	box:HookScript("OnTextChanged", box.Apply)
	return box
end

---------------------------------------------------------------------------
-- Start: header bars on Blizzard's windows
---------------------------------------------------------------------------

function ns.InitViews()
	ns.OnDataChanged(function(kind)
		if kind == "chars" then
			RefreshHeaders()
		else
			ns.ViewChanged(kind)
		end
	end)
	ns.AttachHeader(ContainerFrameCombinedBags, "bags", true)
	-- Blizzard's bags replace the bags view at the same position
	ContainerFrameCombinedBags:HookScript("OnShow", function()
		local frame = views.bags.frame
		if frame then frame:Hide() end
	end)
	ns.AttachHeader(BankFrame, "bank", true)
	EventUtil.ContinueOnAddOnLoaded("Blizzard_MailFrame", function()
		ns.AttachHeader(MailFrame, "mail", true)
	end)
end
