-- qnInventory: Briefkasten.
-- Versand: Beim Aufruf von SendMail werden Anhänge und Gold einer Post an einen eigenen Charakter
-- (dieser oder ein verbundener Realm) vorgemerkt und erst bei MAIL_SEND_SUCCESS dessen Briefkasten
-- gutgeschrieben. Bei Gold oder Anhängen an Fremde fragt Blizzard_SecureTransferUI erst nach
-- (SECURE_TRANSFER_CONFIRM_SEND_MAIL); gesendet wird dann über C_SecureTransfer.SendMail, und
-- MAIL_SEND_SUCCESS kommt erst danach. Verworfen wird die Vormerkung bei MAIL_FAILED und
-- SECURE_TRANSFER_CANCEL. Der Abbrechen-Knopf der Nachfrage meldet nichts; die Vormerkung bleibt
-- dann liegen, bis der nächste SendMail-Aufruf sie ersetzt (MAIL_SEND_SUCCESS kommt nur nach einem
-- Versand).
-- Nachnahme (C.O.D.): Anhänge gehören erst nach dem Bezahlen dem Empfänger und zählen nicht.
-- Empfang: Solange der Briefkasten offen ist, wird sein Inhalt gespeichert.

local _, ns = ...

local IsSecret = ns.IsSecret

local mailOpen = false
local pending   -- { realmDB, target = Name, items = { [itemID] = Anzahl }, money = Kupfer }

-- Eigener Charakter zum eingegebenen Empfänger: Daten des Realms und gespeicherter Name, sonst nil.
-- Akzeptiert "name", "Name" und "Name-Realm" (dieser oder ein verbundener Realm).
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

-- Nach dem Aufruf von SendMail sind die Anhänge noch vorhanden
local function OnSendMail(recipient)
	pending = nil
	local realmDB, target = FindRecipient(recipient)
	if not target or (realmDB == ns.realmDB and target == ns.player) then return end

	local items = {}
	-- Nachnahme (secret: vorsichtshalber als Nachnahme behandelt)
	if ns.Plain(GetSendMailCOD(), 1) == 0 then
		for i = 1, ATTACHMENTS_MAX_SEND do
			local _, itemID, _, count = GetSendMailItem(i)
			if not ns.AnySecret(itemID, count) and itemID then
				ns.AddCount(items, itemID, count)
			end
		end
	end
	local money = GetSendMailMoney()
	if IsSecret(money) then money = 0 end

	pending = { realmDB = realmDB, target = target, items = items, money = money }
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
		-- Briefkasten des Empfängers noch nie gesehen: nur ein Teil ist bekannt
		char.mail = {}
		char.mailIncomplete = true
	end
	for itemID, count in pairs(p.items) do
		ns.AddCount(char.mail, itemID, count)
	end
	char.mailMoney = (char.mailMoney or 0) + p.money
end

-- Inhalt des Briefkastens; bricht ab (alter Stand bleibt), wenn ein Wert secret ist
local function ScanInbox()
	local numItems, totalItems = GetInboxNumItems()
	if IsSecret(numItems) then return end

	local items, money = {}, 0
	for i = 1, numItems do
		local _, _, _, _, mailMoney, codAmount, _, itemCount = GetInboxHeaderInfo(i)
		if ns.AnySecret(mailMoney, codAmount, itemCount) then return end
		money = money + (mailMoney or 0)
		-- Nachnahme: Anhänge erst nach dem Bezahlen eigener Besitz
		if itemCount and itemCount > 0 and (codAmount or 0) == 0 then
			for a = 1, ATTACHMENTS_MAX_RECEIVE do
				local _, itemID, _, count, _, _, isCurrency = GetInboxItem(i, a)
				if ns.AnySecret(itemID, count, isCurrency) then return end
				if itemID and not isCurrency then
					ns.AddCount(items, itemID, count)
				end
			end
		end
	end

	ns.char.mail = items
	ns.char.mailMoney = money
	-- Mehr Post, als der Server auf einmal anzeigt (max. 50)
	ns.char.mailIncomplete = (not IsSecret(totalItems) and totalItems and totalItems > numItems) or nil
end

function ns.InitMail()
	local events = ns.events
	events.Register("MAIL_SHOW", function() mailOpen = true end)
	events.Register("MAIL_CLOSED", function() mailOpen = false end)
	-- erst hier sind die Daten da; MAIL_SHOW kommt davor mit leerem Briefkasten
	events.Register("MAIL_INBOX_UPDATE", function()
		if mailOpen then ScanInbox() end
	end)
	events.Register("MAIL_SEND_SUCCESS", CommitSend)
	events.Register("MAIL_FAILED", DropPending)
	events.Register("SECURE_TRANSFER_CANCEL", DropPending)
	hooksecurefunc("SendMail", OnSendMail)
end
