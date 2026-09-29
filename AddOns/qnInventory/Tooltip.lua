-- qnInventory: inventory of all characters in the item tooltip.
-- Header line "Character  Bags/Bank/Mail", then per character:  <name in class color>  x/y/z
-- First this realm, then connected realms with "Name-Realm", finally the account bank.
-- "?" means: bank or mailbox was never opened with this character.
-- "+" after the mail: mailbox only partially known (more than 50 letters or only our
-- own mails to a character whose mailbox was never opened).

local _, ns = ...

local L = ns.L
local IsSecret = ns.IsSecret

local function AddLines(tooltip, itemID)
	local total, lines = 0, {}
	-- realm = nil: this realm (name without realm), otherwise connected realm ("Name-Realm")
	local function AddRealm(realmDB, realm)
		for _, name in ipairs(ns.SortedChars(realmDB)) do
			local char = realmDB[name]
			local bag = char.bags and char.bags[itemID] or 0
			local bank = char.bank and char.bank[itemID] or 0
			local mail = char.mail and char.mail[itemID] or 0
			if bag + bank + mail > 0 then
				total = total + bag + bank + mail
				local mailText = char.mail and (mail .. (char.mailIncomplete and "+" or "")) or "?"
				local label = qnCore.ClassColoredName(realm and (name .. "-" .. realm) or name, char.class)
				if not realm and name == ns.player then
					label = label .. " " .. L["(me)"]
				end
				lines[#lines + 1] = { label,
					("%d/%s/%s"):format(bag, char.bank and bank or "?", mailText) }
			end
		end
	end
	AddRealm(ns.realmDB)
	for _, r in ipairs(ns.ConnectedRealms()) do
		AddRealm(r.db, r.realm)
	end
	-- account bank (shared by all characters)
	local account = ns.account.bank and ns.account.bank[itemID] or 0
	if account > 0 then
		total = total + account
		lines[#lines + 1] = { ACCOUNT_BANK_PANEL_TITLE, account }
	end
	if #lines == 0 then return end

	tooltip:AddLine(" ")
	local r, g, b = NORMAL_FONT_COLOR:GetRGB()
	tooltip:AddDoubleLine(CHARACTER, L["Bags/Bank/Mail"], r, g, b, r, g, b)
	for _, line in ipairs(lines) do
		tooltip:AddDoubleLine(line[1], line[2], 1, 1, 1, 1, 1, 1)
	end
	if #lines > 1 then
		tooltip:AddDoubleLine(TOTAL, total, r, g, b, r, g, b)
	end
end

local function OnItemTooltip(tooltip, data)
	if not data then return end
	if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
	local itemID = data.id
	if not itemID or IsSecret(itemID) then return end
	AddLines(tooltip, itemID)
end

function ns.InitTooltip()
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
end
