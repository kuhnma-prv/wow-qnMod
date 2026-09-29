-- qnInventory: bags view of another character, recreated like Blizzard's combined
-- bags (ContainerFrameCombinedBags): 10 columns, slots from bottom right to top left,
-- backpack at the bottom, gold below. Blizzard does not show the reagent bag and keyring there,
-- so neither do we.

local _, ns = ...

local L = ns.L

local COLUMNS, SPACING, BUTTON_SIZE = 10, 5, 37
local PADDING_WIDTH, PADDING_HEIGHT = 15, 75

local view = {}
ns.RegisterView("bags", view)

local frame, money, notice, search
local buttons = {}   -- button pool; the first `shown` are in use
local shown = 0

local function Button(i)
	local b = buttons[i]
	if not b then
		b = ns.CreateItemButton(frame)
		b.emptyBackgroundAtlas = "bags-item-slot64"
		local bg = b:CreateTexture(nil, "BACKGROUND", "ItemSlotBackgroundCombinedBagsTemplate", -6)
		bg:SetAllPoints()
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

local function Create()
	frame = CreateFrame("Frame", "qnInventoryBagsFrame", UIParent, "PortraitFrameFlatTemplate")
	NineSliceUtil.ApplyLayoutByName(frame.NineSlice, "HeldBagLayout")
	frame:SetFrameStrata("MEDIUM")
	frame:SetPortraitToAsset("Interface/Icons/Inv_misc_bag_08")
	frame:SetTitle(COMBINED_BAG_TITLE)
	ns.SetupWindow(frame)

	money = CreateFrame("Frame", "qnInventoryBagsFrameMoneyFrame", frame, "ContainerMoneyFrameTemplate")
	MoneyFrame_SetType(money, "STATIC")
	money:UnregisterAllEvents()   -- does not show the gold of the logged-in character
	money:SetPoint("BOTTOMLEFT", 8, 8)
	money:SetPoint("BOTTOMRIGHT", -8, 8)

	search = ns.CreateSearchBox(frame, ShownButtons)
	search:SetPoint("TOPLEFT", 62, -37)
	search:SetWidth(330)

	notice = ns.CreateNotice(frame)
	notice:SetText(L["This character's bags have not been recorded yet. Logging in with it once is enough."])

	ns.AttachHeader(frame, "bags")
end

-- At the position of Blizzard's bags, otherwise their default position
local function Place()
	local live = ContainerFrameCombinedBags
	frame:ClearAllPoints()
	frame:SetScale(live:GetScale())
	if live:IsShown() and live:GetRight() then
		frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", live:GetRight(), live:GetBottom())
	else
		frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y)
	end
end

function view:Refresh()
	local char = ns.CharFromKey(self.key)
	local containers = char and char.containers
	shown = 0
	-- like Blizzard: last bag first, slots backwards; the grid starts at the bottom right
	if containers then
		for bag = Constants.InventoryConstants.NumBagSlots, Enum.BagIndex.Backpack, -1 do
			local c = containers[bag]
			if c then
				for slot = c.size, 1, -1 do
					shown = shown + 1
					local b = Button(shown)
					ns.SetItem(b, c.items[slot])
					b:Show()
				end
			end
		end
	end
	for i = shown + 1, #buttons do
		buttons[i]:Hide()
	end
	notice:SetShown(not containers)

	MoneyFrame_Update(money, char and char.money or 0)
	local list = ShownButtons()
	if #list > 0 then
		AnchorUtil.GridLayout(list, AnchorUtil.CreateAnchor("BOTTOMRIGHT", money, "TOPRIGHT", 0, 4),
			AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.BottomRightToTopLeft, COLUMNS, SPACING, SPACING))
	end

	-- size like ContainerFrameCombinedBagsMixin (without currency bar)
	local rows = math.max(math.ceil(shown / COLUMNS), 3)
	local width = COLUMNS * BUTTON_SIZE + (COLUMNS - 1) * SPACING + PADDING_WIDTH
	local height = rows * BUTTON_SIZE + (rows - 1) * SPACING + PADDING_HEIGHT + money:GetHeight() + 12
	frame:SetSize(width, height)
	NineSliceUtil.UpdateCornerCropping(frame, height)
	search.Apply()
end

function view:Show(key)
	if not frame then Create() end
	self.key = key
	local wasShown = frame:IsShown()
	if not wasShown then Place() end
	-- close Blizzard's bags only after placing
	CloseAllBags()
	self:Refresh()
	frame:Show()
end
