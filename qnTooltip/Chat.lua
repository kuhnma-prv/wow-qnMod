-- qnTooltip: Tooltip beim Überfahren von Links im Chat (Gegenstände, Zauber, Quests …), am Mauszeiger.

local _, ns = ...

local Chat = {}
ns.Chat = Chat

-- Link-Arten, die GameTooltip:SetHyperlink anzeigen kann
local TYPES = { item = true, spell = true, enchant = true, quest = true, talent = true, achievement = true, currency = true }

local hooked = {}
local showing = false

local function OnEnter(frame, link)
	if not ns.db.chatHover or type(link) ~= "string" then
		return
	end
	local kind = link:match("^([^:]+):")
	if not (kind and TYPES[kind:lower()]) then
		return
	end
	GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
	GameTooltip:SetHyperlink(link)
	GameTooltip:Show()
	showing = true
end

local function OnLeave()
	if showing then
		showing = false
		GameTooltip:Hide()
	end
end

local function Hook(frame)
	if frame and not hooked[frame] then
		hooked[frame] = true
		frame:HookScript("OnHyperlinkEnter", OnEnter)
		frame:HookScript("OnHyperlinkLeave", OnLeave)
	end
end

local function HookAll()
	for i = 1, Constants.ChatFrameConstants.MaxChatWindows do
		Hook(_G["ChatFrame" .. i])
	end
end

function Chat.Init()
	HookAll()
	ns.events.Register("UPDATE_CHAT_WINDOWS", HookAll)
end
