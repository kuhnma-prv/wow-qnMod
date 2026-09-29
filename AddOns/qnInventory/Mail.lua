-- qnInventory: mailbox.
-- Sending: when SendMail is called, the attachments and gold of a mail to one of our own characters
-- (this or a connected realm) are put on hold and only credited to that character's mailbox at
-- MAIL_SEND_SUCCESS. For gold or attachments to strangers, Blizzard_SecureTransferUI asks first
-- (SECURE_TRANSFER_CONFIRM_SEND_MAIL); sending then happens via C_SecureTransfer.SendMail, and
-- MAIL_SEND_SUCCESS only comes afterwards. The pending entry is discarded at MAIL_FAILED and
-- SECURE_TRANSFER_CANCEL. The confirmation's cancel button reports nothing; the pending entry then
-- stays until the next SendMail call replaces it (MAIL_SEND_SUCCESS only comes after an actual
-- send).
-- Cash on delivery (C.O.D.): attachments only belong to the recipient after payment and do not count.
-- Receiving: while the mailbox is open, its content is stored.
-- For the mail view (ViewMail.lua) additionally every letter individually (char.mailList, see Core.lua).

local _, ns = ...

local IsSecret = ns.IsSecret

local DAY = 24 * 60 * 60
-- Letters to our own characters stay in the mailbox for 30 days
local MAIL_DAYS = 30
local LETTER_ICON = "Interface\\Icons\\INV_Letter_15"

local mailOpen = false
local pending   -- { realmDB, target = name, items = { [itemID] = count }, money = copper, letter = letter }

-- Own character for the entered recipient: realm data and stored name, otherwise nil.
-- Accepts "name", "Name" and "Name-Realm" (this or a connected realm).
local function FindRecipient(recipient)
	local name, realm = strsplit("-", strtrim(recipient), 2)
	local realmDB = ns.realmDB
	if realm and realm ~= "" then
		realmDB = select(2, ns.FindRealm(realm))
		if not realmDB then
			return nil
		end
	end
	local target = ns.FindChar(name, realmDB)
	if target then
		return realmDB, target
	end
end

-- After the SendMail call the attachments are still present
local function OnSendMail(recipient, subject)
	pending = nil
	local realmDB, target = FindRecipient(recipient)
	if not target or (realmDB == ns.realmDB and target == ns.player) then return end

	-- C.O.D. (secret: treated as C.O.D. to be safe)
	local cod = ns.Plain(GetSendMailCOD(), 1)
	local items, attachments, icon = {}, {}, nil
	for i = 1, ATTACHMENTS_MAX_SEND do
		local _, itemID, texture, count = GetSendMailItem(i)
		if not ns.AnySecret(itemID, texture, count) and itemID then
			if cod == 0 then
				ns.AddCount(items, itemID, count)
			end
			-- GetSendMailItemLink is not in the Forever source (C function, cannot be verified)
			local link = GetSendMailItemLink and GetSendMailItemLink(i)
			attachments[#attachments + 1] = { link or ("item:" .. itemID), count or 1 }
			icon = icon or texture
		end
	end
	local money = GetSendMailMoney()
	if IsSecret(money) then money = 0 end

	local letter = {
		sender = ns.player, subject = subject, money = money, cod = cod,
		expires = time() + MAIL_DAYS * DAY, icon = icon or LETTER_ICON, items = attachments,
	}
	pending = { realmDB = realmDB, target = target, items = items, money = money, letter = letter }
end

local function DropPending()
	pending = nil
end

local function CommitSend()
	local p = pending
	pending = nil
	local char = p and p.realmDB[p.target]
	if not char then return end

	if not char.mail then
		-- recipient's mailbox never seen: only part of it is known
		char.mail = {}
		char.mailIncomplete = true
	end
	for itemID, count in pairs(p.items) do
		ns.AddCount(char.mail, itemID, count)
	end
	char.mailMoney = (char.mailMoney or 0) + p.money
	-- newest letter on top, as in the mailbox
	char.mailList = char.mailList or {}
	table.insert(char.mailList, 1, p.letter)
	ns.DataChanged("mail")
end

-- Content of the mailbox; aborts (old state remains) if a value is secret
local function ScanInbox()
	local numItems, totalItems = GetInboxNumItems()
	if IsSecret(numItems) then return end

	local items, money, list = {}, 0, {}
	local now = time()
	for i = 1, numItems do
		local packageIcon, stationeryIcon, sender, subject, mailMoney, codAmount, daysLeft, itemCount,
			wasRead, _, _, _, isGM = GetInboxHeaderInfo(i)
		if ns.AnySecret(packageIcon, stationeryIcon, sender, subject, mailMoney, codAmount, daysLeft,
			itemCount, wasRead, isGM) then return end
		money = money + (mailMoney or 0)
		local letter = {
			sender = sender, subject = subject, money = mailMoney, cod = codAmount, read = wasRead or nil,
			expires = now + floor((daysLeft or 0) * DAY),
			icon = (packageIcon and not isGM) and packageIcon or stationeryIcon, items = {},
		}
		if itemCount and itemCount > 0 then
			for a = 1, ATTACHMENTS_MAX_RECEIVE do
				local _, itemID, _, count, _, _, isCurrency = GetInboxItem(i, a)
				if ns.AnySecret(itemID, count, isCurrency) then return end
				if itemID and not isCurrency then
					-- C.O.D.: attachments are only ours after payment
					if (codAmount or 0) == 0 then
						ns.AddCount(items, itemID, count)
					end
					local link = GetInboxItemLink(i, a)
					if IsSecret(link) then return end
					letter.items[#letter.items + 1] = { link or ("item:" .. itemID), count or 1 }
				end
			end
		end
		list[i] = letter
	end

	ns.char.mail = items
	ns.char.mailMoney = money
	ns.char.mailList = list
	-- More mail than the server shows at once (max. 50)
	ns.char.mailIncomplete = (not IsSecret(totalItems) and totalItems and totalItems > numItems) or nil
	ns.DataChanged("mail")
end

function ns.InitMail()
	local events = ns.events
	events.Register("MAIL_SHOW", function() mailOpen = true end)
	events.Register("MAIL_CLOSED", function() mailOpen = false end)
	-- only here is the data available; MAIL_SHOW comes earlier with an empty mailbox
	events.Register("MAIL_INBOX_UPDATE", function()
		if mailOpen then ScanInbox() end
	end)
	events.Register("MAIL_SEND_SUCCESS", CommitSend)
	events.Register("MAIL_FAILED", DropPending)
	events.Register("SECURE_TRANSFER_CANCEL", DropPending)
	hooksecurefunc("SendMail", OnSendMail)
end
