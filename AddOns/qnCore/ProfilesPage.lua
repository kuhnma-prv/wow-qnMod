-- qnCore: Optionsseite "Profile" (Canvas-Layout).
-- Zeigt das aktive Profil (= Layout des Bearbeitungsmodus) und alle gespeicherten
-- Profile. Kopieren in das aktive Profil, Löschen und Zurücksetzen wahlweise für
-- alle qn-Addons oder nur für eines.

local _, ns = ...
local lib = qnCore
local L = ns.L
local P = lib.Profiles
local UI = lib.UI

local page, sub   -- page: UI.Page
local activeText, scopeDropdown, listContent, emptyText
local rows = {}
local scope = "*"          -- "*" = alle qn-Addons, sonst Addon-Name

local ROW_HEIGHT = 28

local function ScopeStores()
	if scope == "*" then
		return P.stores
	end
	local store = P.stores[scope]
	return store and { store } or {}
end

local function ScopeLabel()
	return scope == "*" and L["alle qn-Addons"] or scope
end

local function ScopeEntries()
	local list = { { "*", L["Alle qn-Addons"] } }
	for _, store in ipairs(P.stores) do
		list[#list + 1] = { store.name, store.name }
	end
	return list
end

---------------------------------------------------------------------------
-- Rückfragen
---------------------------------------------------------------------------

-- Rückfrage mit fertigem Text (%s); onAccept(data) führt aus, danach wird die Liste neu gezeichnet.
local function Confirm(name, button1, onAccept)
	lib.Popup.Confirm(name, "%s", button1, function(data)
		onAccept(data)
		ns.RefreshProfilesPage()
	end)
end

Confirm("QNCORE_PROFILE_COPY", ACCEPT, function(data)
	local n, deferred = P.CopyToActive(data.key, data.stores)
	ns.Print(L["%d Addon(s) übernommen aus %s."], n, P.GetLabel(data.key))
	if deferred then
		ns.Print(L["Im Kampf: wird nach dem Kampf angewendet."])
	end
end)

Confirm("QNCORE_PROFILE_DELETE", DELETE, function(data)
	local n = P.Delete(data.key, data.stores)
	ns.Print(L["Profil %s bei %d Addon(s) gelöscht."], data.label, n)
end)

Confirm("QNCORE_PROFILE_RESET", ACCEPT, function(data)
	local deferred = P.ResetActive(data.stores)
	ns.Print(L["Aktives Profil zurückgesetzt (%s)."], data.scope)
	if deferred then
		ns.Print(L["Im Kampf: wird nach dem Kampf angewendet."])
	end
end)

---------------------------------------------------------------------------
-- Liste
---------------------------------------------------------------------------

local function UsedBy(key)
	local names = {}
	for _, store in ipairs(P.stores) do
		if store:HasProfile(key) then
			names[#names + 1] = store.name
		end
	end
	return table.concat(names, ", ")
end

local function Row(i)
	local row = rows[i]
	if row then
		return row
	end
	row = CreateFrame("Frame", nil, listContent)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
	row:SetPoint("RIGHT", listContent, "RIGHT")
	row:EnableMouse(true)   -- für den Tooltip; die Knöpfe sind Kindrahmen und liegen darüber
	if i % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, 0.04)
	end
	row.name = UI.Text(row, "GameFontHighlight")
	row.name:SetPoint("LEFT", 4, 0)
	row.name:SetWidth(300)
	row.name:SetWordWrap(false)

	row.delete = UI.Button(row, DELETE, 90, function(self)
		local key = self:GetParent().key
		local label = P.GetLabel(key)
		StaticPopup_Show("QNCORE_PROFILE_DELETE", L["Profil %s löschen (%s)?"]:format(label, ScopeLabel()), nil,
			{ key = key, label = label, stores = ScopeStores() })
	end)
	row.delete:SetHeight(22)
	row.delete:SetPoint("RIGHT", -4, 0)

	row.copy = UI.Button(row, L["In aktives Profil kopieren"], 190, function(self)
		local key = self:GetParent().key
		StaticPopup_Show("QNCORE_PROFILE_COPY",
			L["Einstellungen aus %s in das aktive Profil %s übernehmen (%s)?\nDie bisherigen Einstellungen des aktiven Profils gehen verloren."]:format(
				P.GetLabel(key), P.GetLabel(P.GetActiveKey()), ScopeLabel()), nil,
			{ key = key, stores = ScopeStores() })
	end)
	row.copy:SetHeight(22)
	row.copy:SetPoint("RIGHT", row.delete, "LEFT", -6, 0)

	UI.Tooltip(row, function(self) return P.GetLabel(self.key) end,
		function(self) return L["Vorhanden bei: %s"]:format(UsedBy(self.key)) end, "ANCHOR_TOPLEFT")
	rows[i] = row
	return row
end

function ns.RefreshProfilesPage()
	if not (page and page.panel:IsVisible()) then
		return
	end
	local active = P.GetActiveKey()
	activeText:SetText("|cffcccccc" .. L["Aktives Profil:"] .. "|r " .. P.GetLabel(active))
	scopeDropdown:Refresh()

	local keys = P.GetKnownKeys(ScopeStores())
	for i, key in ipairs(keys) do
		local row = Row(i)
		row.key = key
		local isActive = key == active
		row.name:SetText(P.GetLabel(key) .. (isActive and ("  |cff80ff80" .. L["(aktiv)"] .. "|r") or ""))
		row.copy:SetEnabled(not isActive and active ~= nil)
		row.delete:SetEnabled(not isActive)
		row:Show()
	end
	for i = #keys + 1, #rows do
		rows[i]:Hide()
	end
	listContent:SetHeight(math.max(1, #keys) * ROW_HEIGHT)
	emptyText:SetShown(#keys == 0)
	page.Fit()
end

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------

local function Build()
	page = UI.Page(L["Profile"], { desc =
		L["Alle qn-Addons speichern ihre Einstellungen je Layout des Bearbeitungsmodus (Esc → Bearbeitungsmodus). Wechselst du dort das Layout, wechselt auch das Profil. Charakterspezifische Layouts haben eigene Profile, die nur dieser Charakter benutzt. Ein neues Layout startet mit einer Kopie des bisher aktiven Profils."] })
	local parent = page.content

	activeText = UI.Text(parent, "GameFontNormal")
	activeText:SetPoint("TOPLEFT", page.top, "BOTTOMLEFT", 0, -16)

	scopeDropdown = UI.Dropdown(parent, 220, ScopeEntries, function() return scope end, function(v)
		scope = v
		ns.RefreshProfilesPage()
	end)
	scopeDropdown:SetPoint("TOPLEFT", activeText, "BOTTOMLEFT", 90, -14)
	UI.Label(parent, scopeDropdown, L["Gilt für:"])

	local reset = UI.Button(parent, L["Aktives Profil zurücksetzen"], 220, function()
		local stores = ScopeStores()
		StaticPopup_Show("QNCORE_PROFILE_RESET",
			L["Aktives Profil %s auf die Standardwerte zurücksetzen (%s)?"]:format(P.GetLabel(P.GetActiveKey()), ScopeLabel()), nil,
			{ stores = stores, scope = ScopeLabel() })
	end, L["Setzt die Einstellungen des aktiven Profils auf die Standardwerte (für die unter 'Gilt für' gewählten Addons)."])
	reset:SetPoint("LEFT", scopeDropdown, "RIGHT", 20, 0)

	local header = UI.Text(parent, "GameFontNormal", L["Gespeicherte Profile"])
	header:SetPoint("TOPLEFT", activeText, "BOTTOMLEFT", 0, -56)

	-- Liste im Inhalt der Seite (blättert mit der Seite)
	listContent = CreateFrame("Frame", nil, parent)
	listContent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
	listContent:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	listContent:SetHeight(ROW_HEIGHT)
	local bg = listContent:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.25)

	emptyText = UI.Text(listContent, "GameFontDisable", L["Noch keine Profile – das Layout ist noch nicht ermittelt."])
	emptyText:SetPoint("LEFT", 8, 0)

	page.panel:SetScript("OnShow", ns.RefreshProfilesPage)
end

function ns.InitProfilesPage()
	Build()
	sub = Settings.RegisterCanvasLayoutSubcategory(ns.category, page.panel, L["Profile"])
	P.OnChange(ns.RefreshProfilesPage)
end

function ns.OpenProfiles()
	lib.OpenCategory(sub)
end
