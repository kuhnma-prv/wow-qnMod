-- qnInventory: gemeinsame Teile der Ansichten Taschen, Bank und Post (ViewBags/ViewBank/ViewMail).
-- Die Ansichten bilden Blizzards Fenster mit deren Vorlagen und Grafiken nach, zeigen aber die
-- gespeicherten Daten eines beliebigen eigenen Charakters (dieser oder ein verbundener Realm).
-- Blizzards Fenster selbst lassen sich dafür nicht nutzen: sie lesen ausschließlich die Container
-- bzw. den Briefkasten des eingeloggten Charakters, die Bank nur beim Bankier.
--
-- Über jedem Fenster (auch über Blizzards Taschen, Bank und Briefkasten) hängt eine Leiste mit der
-- Charakterauswahl und Knöpfen für die jeweils anderen Ansichten. Taschen des eingeloggten
-- Charakters zeigt immer Blizzards Fenster; Bank und Post zeigt die Ansicht, damit sie auch
-- fern von Bank und Briefkasten erreichbar sind.

local _, ns = ...

local SEP = "\t"   -- trennt Realm und Name im Auswahlschlüssel (kommt in keinem Namen vor)

local views = {}     -- kind ("bags", "bank", "mail") -> Ansicht
local headers = {}   -- alle Kopfleisten, zum Auffrischen nach einem Wechsel

-- Reihenfolge der Knöpfe in der Kopfleiste
local KINDS = { "bags", "bank", "mail" }
local KIND_TEXT = { bags = HUD_EDIT_MODE_BAGS_LABEL, bank = BANK, mail = MAIL_LABEL }

---------------------------------------------------------------------------
-- Auswahl
---------------------------------------------------------------------------

function ns.CharKey(realm, name)
	return realm .. SEP .. name
end

function ns.PlayerKey()
	return ns.CharKey(ns.realm, ns.player)
end

-- Gewählter Charakter der Ansichten (Vorgabe: der eingeloggte)
local selected

-- Daten, Name und Realm zu einem Schlüssel (Vorgabe: gewählter Charakter); Daten nil, wenn gelöscht
function ns.CharFromKey(key)
	local realm, name = strsplit(SEP, key or selected or ns.PlayerKey())
	local realmDB = qnInventoryDB.realms[realm]
	return realmDB and realmDB[name], name, realm
end

-- Einträge der Charakterauswahl: dieser Realm, dann verbundene Realms mit "Name-Realm".
-- Die andere Fraktion nur mit der Option viewsBothFactions; allFactions = immer alle (Optionsseite).
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
-- Ansichten
-- Eine Ansicht hat frame, Show(self, key) (füllt und zeigt) und Refresh(self); key = gezeigter
-- Charakter.
---------------------------------------------------------------------------

function ns.RegisterView(kind, view)
	views[kind] = view
end

local function RefreshHeaders()
	for _, header in ipairs(headers) do
		header:Refresh()
	end
end

-- Zeigt die Ansicht kind für key (Vorgabe: gewählter Charakter). Taschen des eingeloggten
-- Charakters: Blizzards Fenster.
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

-- Wie Show, blendet eine schon gezeigte Ansicht desselben Charakters aber aus
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

-- Gespeicherte Daten des eingeloggten Charakters haben sich geändert (Scan.lua, Mail.lua)
function ns.ViewChanged(kind)
	local view = views[kind]
	if view and view.frame and view.frame:IsShown() and view.key == ns.PlayerKey() then
		view:Refresh()
	end
end

---------------------------------------------------------------------------
-- Kopfleiste: Charakterauswahl und Knöpfe für die anderen Ansichten
-- live = Blizzards Fenster: zeigt immer den eingeloggten Charakter.
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
-- Fenster
---------------------------------------------------------------------------

-- Verschiebbar über die Fensterfläche, Escape schließt (Name nötig für UISpecialFrames)
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

-- Beim Öffnen: neben Blizzards offenes Fenster (Bank beim Bankier, Briefkasten), sonst an den
-- Platz eines linken Blizzard-Fensters. gap = Abstand (Seitenreiter der Bank liegen rechts außen).
function ns.PlaceBeside(frame, live, gap)
	frame:ClearAllPoints()
	if live and live:IsShown() then
		frame:SetPoint("TOPLEFT", live, "TOPRIGHT", gap, 0)
	else
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
	end
end

-- Hinweis mitten im Fenster, solange nichts gespeichert ist
function ns.CreateNotice(frame)
	local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetPoint("CENTER")
	fs:SetWidth(280)
	fs:Hide()
	return fs
end

---------------------------------------------------------------------------
-- Item-Knöpfe: Link statt Container-Platz, Tooltip über den Link, Klick mit Umschalt/Strg wie
-- gewohnt (Chat-Link, Anprobe).
---------------------------------------------------------------------------

-- Anker wie bei Blizzards Taschenplätzen (ContainerFrameItemButton_CalculateItemTooltipAnchors);
-- mit qnViewPort danach ganz auf den Monitor der Tasche.
local function ItemOnEnter(self)
	if not self.link then return end
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)
	GameTooltip:SetHyperlink(self.link)
	GameTooltip:Show()
	local vp = _G.qnViewPort   -- optionales Addon
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
	-- Item noch nicht im Cache: Rahmen nachtragen, sobald die Daten da sind
	SetItemButtonQuality(b, nil)
	local itemID = C_Item.GetItemInfoInstant(link)
	if not itemID then return end
	Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
		if b.link == link then
			SetItemButtonQuality(b, C_Item.GetItemQualityByID(link), link)
		end
	end)
end

-- entry = { Link, Anzahl } oder nil (leerer Platz)
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
-- Suche: Knöpfe, deren Item nicht zum Suchtext passt, werden abgedunkelt (wie Blizzards Suche)
---------------------------------------------------------------------------

local function Matches(link, text)
	local name = C_Item.GetItemInfo(link)
	return name and name:lower():find(text, 1, true) ~= nil
end

-- buttons() liefert die gezeigten Item-Knöpfe
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
-- Start: Kopfleisten an Blizzards Fenstern
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
	-- Blizzards Taschen ersetzen die Taschenansicht an derselben Stelle
	ContainerFrameCombinedBags:HookScript("OnShow", function()
		local frame = views.bags.frame
		if frame then frame:Hide() end
	end)
	ns.AttachHeader(BankFrame, "bank", true)
	EventUtil.ContinueOnAddOnLoaded("Blizzard_MailFrame", function()
		ns.AttachHeader(MailFrame, "mail", true)
	end)
end
