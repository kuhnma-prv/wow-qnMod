-- qnGatherer: small info window. Opens when you fish (profile mini.fishing) or gather (mini.gathering)
-- and shows the skill, the zone, its skill range and the resources of the zone with required skill
-- and your catches; while fishing "Listen for the splash …". It closes mini.delay seconds after the
-- cast unless it is pinned (/qngatherer mini, checkbox "Keep open"; the X unpins it).

local ADDON, ns = ...
local L = ns.L
local DB, D, J = ns.DB, ns.Display, ns.Journal
local UI = qnCore.UI

local Mini = {}
ns.Mini = Mini

local WIDTH, HEIGHT = 340, 260

local frame
local closeTimer
Mini.kind = nil       -- kind shown
Mini.casting = false  -- a cast of that kind is running

---------------------------------------------------------------------------
-- Content
---------------------------------------------------------------------------

-- Text of the window for kind on map (also used by the tests)
function Mini.Text(kind, map)
	local lines = {}
	if not map then
		return L["No position in this area."]
	end
	local skill = J.ZoneSkillText(kind, map)
	lines[#lines + 1] = NORMAL_FONT_COLOR:WrapTextInColorCode(J.ZoneName(map)) .. (skill and ("  |cffaaaaaa" .. skill .. "|r") or "")
	local list = J.Resources(kind, map)
	if #list == 0 then
		lines[#lines + 1] = L["No data for this zone yet."]
	end
	for _, e in ipairs(list) do
		local detail = J.ResourceDetail(e)
		lines[#lines + 1] = ("|T%s:16|t %s%s"):format(D.ResourceIcon(kind, e.res), e.name,
			detail ~= "" and ("  |cffaaaaaa" .. detail .. "|r") or "")
	end
	return table.concat(lines, "\n")
end

function Mini.Refresh()
	if not frame or not frame:IsShown() or not Mini.kind then
		return
	end
	frame:SetTitle(J.SkillText(Mini.kind))
	frame.text:SetText(Mini.Text(Mini.kind, C_Map.GetBestMapForUnit("player")))
	frame.content:SetHeight(math.max(1, frame.text:GetStringHeight() + 8))
	frame.status:SetText(Mini.casting and Mini.kind == "fish" and L["Listen for the splash …"] or "")
	frame.pin:SetChecked(DB.global.windows.mini.pinned)
end

---------------------------------------------------------------------------
-- Opening and closing
---------------------------------------------------------------------------

local function CancelClose()
	if closeTimer then
		closeTimer:Cancel()
		closeTimer = nil
	end
end

local function Create()
	frame = CreateFrame("Frame", "qnGathererMini", UIParent, "PortraitFrameFlatTemplate")
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetFrameStrata("MEDIUM")
	J.SetupWindow(frame, "mini", { "RIGHT", UIParent, "RIGHT", -260, 0 })
	frame:Hide()
	local scroll = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 14, -64)
	scroll:SetPoint("BOTTOMRIGHT", -30, 52)
	frame.content = CreateFrame("Frame", nil, scroll)
	frame.content:SetSize(WIDTH - 50, 1)
	scroll:SetScrollChild(frame.content)
	frame.text = UI.Text(frame.content, "GameFontHighlightSmall", "")
	frame.text:SetWidth(WIDTH - 54)
	frame.text:SetJustifyH("LEFT")
	frame.text:SetPoint("TOPLEFT", 2, -2)
	frame.status = UI.Text(frame, "GameFontNormal", "")
	frame.status:SetPoint("BOTTOMLEFT", 16, 34)
	frame.pin = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
	frame.pin:SetSize(24, 24)
	frame.pin:SetPoint("BOTTOMLEFT", 10, 6)
	frame.pinLabel = UI.Text(frame, "GameFontHighlightSmall", L["Keep open"])
	frame.pinLabel:SetPoint("LEFT", frame.pin, "RIGHT", 2, 0)
	frame.pin:SetScript("OnClick", function(self)
		Mini.SetPinned(self:GetChecked())
	end)
	frame.journal = UI.Button(frame, L["Journal"], 100, function()
		J.Show(Mini.kind, C_Map.GetBestMapForUnit("player"))
	end)
	frame.journal:SetPoint("BOTTOMRIGHT", -10, 8)
	-- the X unpins (like closing a pinned window)
	frame:HookScript("OnHide", function()
		CancelClose()
		if Mini.closing then
			Mini.closing = false
		else
			DB.global.windows.mini.pinned = false
		end
	end)
	frame:SetPortraitToAsset("Interface\\AddOns\\qnCore\\Media\\qnIcon")
	Mini.frame = frame
end

function Mini.Show(kind)
	if not frame then Create() end
	CancelClose()
	Mini.kind = kind or Mini.kind or "fish"
	frame:Show()
	Mini.Refresh()
end

-- Closes the window without unpinning (timer)
function Mini.Close()
	if frame and frame:IsShown() then
		Mini.closing = true
		frame:Hide()
	end
end

function Mini.SetPinned(on)
	DB.global.windows.mini.pinned = on and true or false
	if on then
		Mini.Show(Mini.kind)
	end
	if frame then
		frame.pin:SetChecked(on)
	end
end

function Mini.TogglePinned()
	if DB.global.windows.mini.pinned then
		Mini.SetPinned(false)
		Mini.Close()
	else
		Mini.SetPinned(true)
	end
end

-- A cast of kind starts
function Mini.OnCast(kind)
	local opts = ns.db.mini
	local auto = (kind == "fish" and opts.fishing) or (kind ~= "fish" and opts.gathering)
	Mini.casting = true
	if auto then
		Mini.Show(kind)
	elseif frame and frame:IsShown() then
		CancelClose()
		Mini.kind = kind
		Mini.Refresh()
	end
end

-- The cast ended: close after the delay unless pinned
function Mini.OnCastEnd()
	Mini.casting = false
	if not frame or not frame:IsShown() then
		return
	end
	Mini.Refresh()
	if DB.global.windows.mini.pinned then
		return
	end
	CancelClose()
	closeTimer = C_Timer.NewTimer(ns.db.mini.delay, function()
		closeTimer = nil
		if not DB.global.windows.mini.pinned then
			Mini.Close()
		end
	end)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

ns.events.Register("UNIT_SPELLCAST_SENT", function(_, unit, _, _, spellID)
	if unit == "player" and not ns.IsSecret(spellID) then
		local kind = ns.KindForSpell(spellID)
		if kind then
			Mini.OnCast(kind)
		end
	end
end)

local function EndOfCast(_, unit, _, spellID)
	if unit == "player" and Mini.casting and not ns.IsSecret(spellID) and ns.KindForSpell(spellID) then
		Mini.OnCastEnd()
	end
end
for _, event in ipairs({ "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" }) do
	ns.events.Register(event, EndOfCast)
end

ns.events.Register("ZONE_CHANGED_NEW_AREA", function()
	Mini.Refresh()
end)

function Mini.Init()
	D.OnRefresh(Mini.Refresh)
	if DB.global.windows.mini.pinned then
		Mini.Show("fish")
	end
end
