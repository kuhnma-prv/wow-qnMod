-- qnInventory: mail view, recreated like Blizzard's inbox (Blizzard_MailFrame: MailFrame with
-- InboxFrame, 7 letters per page from MailItemTemplate). A click on a letter opens its
-- attachments next to it (simplified OpenMailFrame: sender, subject, attachments, gold or C.O.D.; the
-- addon does not read the letter text, that would mark the letter as read).
-- The remaining time is calculated from the stored expiry time.

local _, ns = ...

local L = ns.L

local ROWS = INBOXITEMS_TO_DISPLAY or 7
local DAY = 24 * 60 * 60

local view = {}
ns.RegisterView("mail", view)

local frame, inbox, notice, pageText, prevButton, nextButton
local rows = {}
local page = 1
local openLetter   -- letter shown in the reading window

---------------------------------------------------------------------------
-- Reading window
---------------------------------------------------------------------------

local reader, readerSender, readerSubject, readerMoney, readerMoneyLabel
local attachments = {}

local function CreateReader()
	reader = CreateFrame("Frame", "qnInventoryOpenMailFrame", UIParent, "ButtonFrameTemplate")
	ButtonFrameTemplate_HideButtonBar(reader)
	reader:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)
	ns.SetupWindow(reader)

	local fromLabel = reader:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fromLabel:SetText(FROM)
	fromLabel:SetPoint("TOPRIGHT", reader, "TOPLEFT", 100, -80)
	readerSender = reader:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	readerSender:SetJustifyH("LEFT")
	readerSender:SetPoint("LEFT", fromLabel, "RIGHT", 6, 0)
	readerSender:SetPoint("RIGHT", reader, "RIGHT", -16, 0)

	local subjectLabel = reader:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	subjectLabel:SetText(MAIL_SUBJECT_LABEL)
	subjectLabel:SetPoint("TOPRIGHT", fromLabel, "BOTTOMRIGHT", 0, -10)
	readerSubject = reader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	readerSubject:SetJustifyH("LEFT")
	readerSubject:SetJustifyV("TOP")
	readerSubject:SetPoint("TOPLEFT", subjectLabel, "TOPRIGHT", 6, 0)
	readerSubject:SetPoint("RIGHT", reader, "RIGHT", -16, 0)

	readerMoneyLabel = reader:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	readerMoneyLabel:SetPoint("BOTTOMLEFT", 20, 60)
	readerMoney = CreateFrame("Frame", "qnInventoryOpenMailMoneyFrame", reader, "SmallMoneyFrameTemplate")
	MoneyFrame_SetType(readerMoney, "STATIC")
	readerMoney:UnregisterAllEvents()
	readerMoney:SetPoint("TOPLEFT", readerMoneyLabel, "BOTTOMLEFT", 0, -4)

	for i = 1, ATTACHMENTS_MAX_RECEIVE do
		local b = ns.CreateItemButton(reader)
		b.emptyBackgroundAtlas = "bags-item-slot64"
		local col, row = (i - 1) % ATTACHMENTS_PER_ROW_RECEIVE, floor((i - 1) / ATTACHMENTS_PER_ROW_RECEIVE)
		b:SetPoint("TOPLEFT", reader, "TOPLEFT", 20 + col * 43, -150 - row * 43)
		attachments[i] = b
	end
end

local function ShowLetter(letter)
	if not reader then CreateReader() end
	openLetter = letter
	reader:SetPortraitToAsset(letter.icon or "Interface\\Icons\\INV_Letter_15")
	reader:SetTitle(letter.subject or "")
	readerSender:SetText(letter.sender or UNKNOWN)
	readerSubject:SetText(letter.subject or "")
	for i, b in ipairs(attachments) do
		local entry = letter.items[i]
		ns.SetItem(b, entry)
		b:SetShown(entry ~= nil)
	end
	local cod = letter.cod or 0
	local money = cod > 0 and cod or (letter.money or 0)
	readerMoneyLabel:SetText(cod > 0 and COD_AMOUNT or ENCLOSED_MONEY)
	readerMoneyLabel:SetShown(money > 0)
	readerMoney:SetShown(money > 0)
	MoneyFrame_Update(readerMoney, money)
	reader:Show()
end

---------------------------------------------------------------------------
-- Inbox
---------------------------------------------------------------------------

local function LetterOnEnter(self)
	local letter = self.letter
	if not letter then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local count = #letter.items
	if count == 1 then
		GameTooltip:SetHyperlink(letter.items[1][1])
	elseif count > 1 then
		GameTooltip:AddLine(MAIL_MULTIPLE_ITEMS .. " (" .. count .. ")")
	end
	local cod, money = letter.cod or 0, letter.money or 0
	if money > 0 or cod > 0 then
		if count > 0 then
			GameTooltip:AddLine(" ")
		end
		GameTooltip:AddLine(cod > 0 and COD_AMOUNT or ENCLOSED_MONEY, nil, nil, nil, true)
		GameTooltip_AddMoneyLine(GameTooltip, cod > 0 and cod or money)
	end
	GameTooltip:Show()
end

local function LetterOnClick(self)
	if not self.letter then return end
	if reader and reader:IsShown() and openLetter == self.letter then
		reader:Hide()
	else
		ShowLetter(self.letter)
	end
	view:Refresh()
end

local function CreateRow(i)
	local name = "qnInventoryMailItem" .. i
	local row = CreateFrame("Frame", name, inbox, "MailItemTemplate")
	if i == 1 then
		row:SetPoint("TOPLEFT", 13, -70)
	else
		row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT")
	end
	row.name = name
	-- the button's scripts belong to Blizzard's inbox (InboxFrame, GetInboxItem)
	local b = row.Button
	b:UnregisterAllEvents()
	b:SetScript("OnEvent", nil)
	b:SetScript("OnUpdate", nil)
	b:SetScript("OnEnter", LetterOnEnter)
	b:SetScript("OnLeave", GameTooltip_Hide)
	b:SetScript("OnClick", LetterOnClick)
	rows[i] = row
	return row
end

-- Page button like Blizzard's PrevPageButton/NextPageButton
local function PageButton(prefix, text, point, x, textPoint, textRel)
	local b = CreateFrame("Button", nil, inbox)
	b:SetSize(32, 32)
	b:SetPoint(point, x, 10)
	b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prefix .. "Page-Up")
	b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prefix .. "Page-Down")
	b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prefix .. "Page-Disabled")
	b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	local fs = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetText(text)
	fs:SetPoint(textPoint, b, textRel)
	return b
end

local function Create()
	frame = CreateFrame("Frame", "qnInventoryMailFrame", UIParent, "ButtonFrameTemplate")
	frame:SetPortraitToAsset("Interface\\MailFrame\\Mail-Icon")
	frame:SetTitle(INBOX)
	ButtonFrameTemplate_HideButtonBar(frame)
	frame.Inset:SetPoint("TOPLEFT", 4, -58)
	ns.SetupWindow(frame)
	frame:HookScript("OnHide", function()
		if reader then reader:Hide() end
	end)

	inbox = CreateFrame("Frame", nil, frame)
	inbox:SetAllPoints()
	local bg = inbox:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface\\MailFrame\\UI-MailFrameBG")
	bg:SetSize(512, 512)
	bg:SetPoint("TOPLEFT", 7, -62)

	pageText = inbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	pageText:SetPoint("BOTTOM", 0, 18)

	for i = 1, ROWS do
		CreateRow(i)
	end

	prevButton = PageButton("Prev", PREV, "BOTTOMLEFT", 14, "LEFT", "RIGHT")
	prevButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		page = page - 1
		view:Refresh()
	end)
	nextButton = PageButton("Next", NEXT, "BOTTOMRIGHT", -14, "RIGHT", "LEFT")
	nextButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		page = page + 1
		view:Refresh()
	end)

	notice = ns.CreateNotice(inbox)
	notice:SetText(L["This character's mailbox has not been recorded yet. Opening the mailbox with it once is enough."])

	ns.AttachHeader(frame, "mail")
end

-- Remaining time like InboxMixin:Update
local function ExpireText(expires)
	local daysLeft = ((expires or 0) - time()) / DAY
	if daysLeft >= 1 then
		return GREEN_FONT_COLOR_CODE .. format(DAYS_ABBR, floor(daysLeft)) .. " " .. FONT_COLOR_CODE_CLOSE
	end
	return RED_FONT_COLOR_CODE .. SecondsToTime(math.max(0, floor(daysLeft * DAY))) .. FONT_COLOR_CODE_CLOSE
end

-- One row like InboxMixin:Update; letter = nil clears it
local function FillRow(row, letter)
	local name = row.name
	local b = row.Button
	b.letter = letter
	local sender, subject = _G[name .. "Sender"], _G[name .. "Subject"]
	local expire = _G[name .. "ExpireTime"]
	if not letter then
		b:Hide()
		sender:SetText("")
		subject:SetText("")
		expire:Hide()
		return
	end

	b:Show()
	local first = letter.items[1]
	local icon = _G[name .. "ButtonIcon"]
	icon:SetTexture(letter.icon)
	if first then
		SetItemButtonCount(b, first[2])
		SetItemButtonQuality(b, C_Item.GetItemQualityByID(first[1]), first[1])
	else
		SetItemButtonCount(b, 0)
		b.IconBorder:Hide()
		b.IconOverlay:Hide()
	end
	sender:SetText(letter.sender or UNKNOWN)
	subject:SetText(letter.subject or "")

	if letter.read then
		sender:SetTextColor(0.75, 0.75, 0.75)
		subject:SetTextColor(0.75, 0.75, 0.75)
		_G[name .. "ButtonSlot"]:SetVertexColor(0.5, 0.5, 0.5)
		icon:SetDesaturated(true)
		b.IconBorder:SetVertexColor(0.5, 0.5, 0.5)
	else
		sender:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
		subject:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		_G[name .. "ButtonSlot"]:SetVertexColor(1.0, 0.82, 0)
		icon:SetDesaturated(false)
	end

	expire:SetText(ExpireText(letter.expires))
	expire.tooltip = nil
	expire:Show()

	local isCOD = (letter.cod or 0) > 0
	_G[name .. "ButtonCOD"]:SetShown(isCOD)
	_G[name .. "ButtonCODBackground"]:SetShown(isCOD)
	b:SetChecked(reader and reader:IsShown() and openLetter == letter)
end

function view:Refresh()
	local char = ns.CharFromKey(self.key)
	local list = char and char.mailList
	local count = list and #list or 0
	local pages = math.max(1, math.ceil(count / ROWS))
	page = math.max(1, math.min(page, pages))
	local first = (page - 1) * ROWS
	for i, row in ipairs(rows) do
		FillRow(row, list and list[first + i])
	end
	notice:SetShown(not list)
	pageText:SetText(pages > 1 and PAGE_NUMBER:format(page) or "")
	prevButton:SetEnabled(page > 1)
	nextButton:SetEnabled(page < pages)
end

function view:Show(key)
	if not frame then Create() end
	if self.key ~= key then
		page = 1
		if reader then reader:Hide() end
	end
	self.key = key
	if not frame:IsShown() then
		ns.PlaceBeside(frame, MailFrame, 10)
	end
	self:Refresh()
	frame:Show()
end
