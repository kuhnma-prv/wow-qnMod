-- qnGatherer: journal window. Choose a kind (dropdown), on the left the zones with data (search by
-- zone or resource name, "Current zone"), on the right a preview of the zone map with the nodes and
-- areas, below it the resources of the zone (icon, required skill, nodes, own catches). Clicking a
-- resource shows only its nodes and areas on the preview; clicking it again shows all.
-- Everything comes from the database: zones only appear once something is recorded or imported.

local ADDON, ns = ...
local L = ns.L
local DB, D = ns.DB, ns.Display
local UI = qnCore.UI

local J = {}
ns.Journal = J

local WIDTH, HEIGHT = 940, 640
local LIST_WIDTH = 250
local PREVIEW_WIDTH = 640
local ROW_HEIGHT = 20
local RES_ROW_HEIGHT = 24
local NODE_SIZE = 14
local AREA_ALPHA = 0.4
local AREA_TEXTURE = "Interface\\AddOns\\qnGatherer\\Media\\Area"

local frame
local state = { kind = nil, map = nil, search = "", focus = nil }
J.state = state

-- Skinning: no nodes, only the level bands of an import (zones and leather per band)
local SKINNING_KEY = "skinning"
local SKINNING_INFO = { name = SKINNING, skill = 393, spells = { 8613 } }

local function KindInfo(kind)
	return ns.KINDS[kind] or (kind == SKINNING_KEY and SKINNING_INFO)
end

---------------------------------------------------------------------------
-- Content (also used by the tests and the mini window)
---------------------------------------------------------------------------

function J.ZoneName(map)
	local info = C_Map.GetMapInfo(map)
	return info and info.name or ("#" .. map)
end

-- Maps of kind with data: { [map] = true }
local function ZoneSet(kind)
	if kind == SKINNING_KEY then
		local maps = {}
		for _, band in ipairs(DB.GetSkinning()) do
			for _, map in ipairs(band.maps) do maps[map] = true end
		end
		return maps
	end
	return DB.MapsWithData(kind)
end

-- "Fishing 150 (+25)", "Fishing 150" or only the name if the skill is unknown
function J.SkillText(kind)
	local k = KindInfo(kind)
	local info = k.skill and C_SkillInfo.GetSkillLineInfoByID(k.skill)
	local rank = info and ns.Plain(info.rank, 0) or 0
	if rank <= 0 then
		return k.name
	end
	local modifier = ns.Plain(info.modifier, 0) or 0
	if modifier ~= 0 then
		return L["%s %d (+%d)"]:format(k.name, rank, modifier)
	end
	return L["%s %d"]:format(k.name, rank)
end

-- Text of the skill range of a zone ("Skill 1 – 75"), nil if unknown (a zone may only have
-- a resource list)
function J.ZoneSkillText(kind, map)
	local zone = DB.GetZone(kind, map)
	if zone and zone.min and zone.max then
		return L["Skill %d – %d"]:format(zone.min, zone.max)
	end
end

-- Does a resource of kind on map have a name containing text (lower case)?
local function ResourceMatches(kind, map, text)
	for _, e in ipairs(DB.ZoneResources(kind, map, ns.CharKey())) do
		if D.ResourceName(e.res):lower():find(text, 1, true) then
			return true
		end
	end
	return false
end

-- Zones of kind matching search (zone or resource name), sorted by name:
-- { { map, name, nodes, skill }, ... }
function J.Zones(kind, search)
	local text = (search or ""):lower()
	local list = {}
	for map in pairs(ZoneSet(kind)) do
		local name = J.ZoneName(map)
		if text == "" or name:lower():find(text, 1, true) or (kind ~= SKINNING_KEY and ResourceMatches(kind, map, text)) then
			list[#list + 1] = { map = map, name = name, nodes = DB.CountNodes(kind, map), skill = J.ZoneSkillText(kind, map) }
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

-- Resources of the zone sorted by required skill, then name: entries of DB.ZoneResources plus
-- name, item and skill
function J.Resources(kind, map)
	if kind == SKINNING_KEY then
		-- level bands that suggest this zone, with their leather
		local list = {}
		for _, band in ipairs(DB.GetSkinning()) do
			for _, m in ipairs(band.maps) do
				if m == map then
					list[#list + 1] = { res = "i:" .. band.item, item = band.item, nodes = 0, catches = 0, catchesAll = 0,
						name = L["Level %d – %d"]:format(band.low, band.high),
						detail = L["Skill %d – %d"]:format(band.skill, band.skillHigh) .. " · " .. D.ResourceName("i:" .. band.item) }
				end
			end
		end
		return list
	end
	local list = DB.ZoneResources(kind, map, ns.CharKey())
	for _, e in ipairs(list) do
		local entry = DB.GetResource(e.res)
		e.name = D.ResourceName(e.res)
		e.item = D.ResourceItem(e.res)
		e.skill = entry and entry.skill
		e.cond = entry and entry.cond
	end
	table.sort(list, function(a, b)
		if (a.skill or 0) ~= (b.skill or 0) then return (a.skill or 0) < (b.skill or 0) end
		return a.name < b.name
	end)
	return list
end

-- Detail line of a resource row: required skill, nodes, own catches
function J.ResourceDetail(e)
	if e.detail then
		return e.detail
	end
	local parts = {}
	if e.skill then parts[#parts + 1] = L["Required skill: %d"]:format(e.skill) end
	if e.nodes > 0 then parts[#parts + 1] = L["%d nodes"]:format(e.nodes) end
	if e.catches > 0 then parts[#parts + 1] = L["caught: %d"]:format(e.catches) end
	if (e.catchesAll or 0) > e.catches then parts[#parts + 1] = L["all characters: %d"]:format(e.catchesAll) end
	if e.cond then parts[#parts + 1] = e.cond end
	return table.concat(parts, " · ")
end

-- Exploration overlays from imports (whole zone visible); same format as
-- C_MapExplorationInfo.GetExploredMapTextures
function J.ExtraOverlays(map)
	return DB.GetOverlays(C_Map.GetMapArtID(map))
end

local AREA_CLASS_TEXT = {}
local function AreaClassText(class)
	if not next(AREA_CLASS_TEXT) then
		AREA_CLASS_TEXT.learned = L["Learned from your catches"]
		AREA_CLASS_TEXT.reported = L["Reported area"]
		AREA_CLASS_TEXT.school = L["Fish school area"]
	end
	return AREA_CLASS_TEXT[class] or class
end

---------------------------------------------------------------------------
-- Map preview
---------------------------------------------------------------------------

local preview, canvas
local tiles, markers = {}, {}

local function Tile(i)
	local t = tiles[i]
	if not t then
		t = canvas:CreateTexture(nil, "BACKGROUND")
		tiles[i] = t
	end
	t:SetDrawLayer("BACKGROUND", 0)
	t:SetTexCoord(0, 1, 0, 1)
	t:ClearAllPoints()
	t:Show()
	return t
end

local function MarkerEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if self.area then
		local c = D.Color(state.kind)
		GameTooltip:AddLine(AreaClassText(self.area.class), c[1], c[2], c[3])
		for _, res in ipairs(self.area.res) do
			GameTooltip:AddLine(D.ResourceName(res), 1, 1, 1)
		end
		local origin = D.OriginText(DB.OriginName(self.area.o))
		if origin then GameTooltip:AddLine(origin, 0.6, 0.6, 0.6) end
	else
		D.AddTooltipLines(GameTooltip, self.entry)
	end
	GameTooltip:Show()
end

local function Marker(i)
	local m = markers[i]
	if not m then
		m = CreateFrame("Button", nil, canvas)
		m.tex = m:CreateTexture(nil, "ARTWORK")
		m.tex:SetAllPoints()
		m:SetScript("OnEnter", MarkerEnter)
		m:SetScript("OnLeave", GameTooltip_Hide)
		markers[i] = m
	end
	m:ClearAllPoints()
	m:Show()
	return m
end

-- Draws map, overlays, areas and nodes; returns the number of shown nodes and areas.
function J.DrawPreview()
	for _, t in ipairs(tiles) do t:Hide() end
	for _, m in ipairs(markers) do m:Hide() end
	local map, kind = state.map, state.kind
	frame.noMap:Hide()
	if not map then
		return 0, 0
	end
	local layers = C_Map.GetMapArtLayers(map)
	local layer = layers and layers[1]
	if not layer then
		frame.noMap:Show()
		return 0, 0
	end
	local w, h = layer.layerWidth, layer.layerHeight
	local scale = PREVIEW_WIDTH / w
	canvas:SetSize(w, h)
	canvas:SetScale(scale)
	preview:SetHeight(h * scale)

	-- base tiles in rows
	local n = 0
	local cols = math.ceil(w / layer.tileWidth)
	for i, file in ipairs(C_Map.GetMapArtLayerTextures(map, 1) or {}) do
		n = n + 1
		local t = Tile(n)
		local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
		t:SetSize(layer.tileWidth, layer.tileHeight)
		t:SetPoint("TOPLEFT", canvas, "TOPLEFT", col * layer.tileWidth, -row * layer.tileHeight)
		t:SetTexture(file)
	end

	-- explored areas (account) and imported overlays: the whole zone visible
	local overlays = {}
	for _, list in ipairs({ C_MapExplorationInfo.GetExploredMapTextures(map) or {}, J.ExtraOverlays(map) }) do
		for _, o in ipairs(list) do overlays[#overlays + 1] = o end
	end
	for _, o in ipairs(overlays) do
		local wide = math.ceil(o.textureWidth / layer.tileWidth)
		local tall = math.ceil(o.textureHeight / layer.tileHeight)
		for j = 1, tall do
			local ph, fh = layer.tileHeight, layer.tileHeight
			if j == tall then
				ph = o.textureHeight % layer.tileHeight
				if ph == 0 then ph = layer.tileHeight end
				fh = 16
				while fh < ph do fh = fh * 2 end
			end
			for k = 1, wide do
				local pw, fw = layer.tileWidth, layer.tileWidth
				if k == wide then
					pw = o.textureWidth % layer.tileWidth
					if pw == 0 then pw = layer.tileWidth end
					fw = 16
					while fw < pw do fw = fw * 2 end
				end
				local file = o.fileDataIDs[(j - 1) * wide + k]
				if file then
					n = n + 1
					local t = Tile(n)
					t:SetDrawLayer("BACKGROUND", 1)
					t:SetSize(pw, ph)
					t:SetTexCoord(0, pw / fw, 0, ph / fh)
					t:SetPoint("TOPLEFT", canvas, "TOPLEFT", o.offsetX + layer.tileWidth * (k - 1), -(o.offsetY + layer.tileHeight * (j - 1)))
					t:SetTexture(file)
				end
			end
		end
	end

	-- areas, then nodes (filtered by the selected resource)
	if not ns.KINDS[kind] then
		return 0, 0   -- skinning: map only
	end
	local focus = state.focus
	local c = D.Color(kind)
	local count, shownNodes, shownAreas = 0, 0, 0
	for _, a in ipairs(DB.GetAreas(kind, map)) do
		local match = not focus
		for _, res in ipairs(a.res) do
			if res == focus then match = true end
		end
		if match then
			count = count + 1
			shownAreas = shownAreas + 1
			local m = Marker(count)
			m.area, m.entry = a, nil
			m:SetSize(math.max(a.rx * 2 * w, 35 / scale), math.max(a.ry * 2 * h, 35 / scale))
			m:SetPoint("CENTER", canvas, "TOPLEFT", a.x * w, -a.y * h)
			m.tex:SetTexture(AREA_TEXTURE)
			m.tex:SetVertexColor(c[1], c[2], c[3], AREA_ALPHA)
			m:SetFrameLevel(canvas:GetFrameLevel() + 1)
		end
	end
	for coord, node in DB.Nodes(kind, map) do
		if not focus or node.res == focus then
			count = count + 1
			shownNodes = shownNodes + 1
			local x, y = DB.Decode(coord)
			local m = Marker(count)
			m.area, m.entry = nil, { kind = kind, res = node.res, origin = node.origin }
			m:SetSize(NODE_SIZE / scale, NODE_SIZE / scale)
			m:SetPoint("CENTER", canvas, "TOPLEFT", x * w, -y * h)
			m.tex:SetTexture(D.ResourceIcon(kind, node.res))
			m.tex:SetVertexColor(1, 1, 1, 1)
			m:SetFrameLevel(canvas:GetFrameLevel() + 2)
		end
	end
	return shownNodes, shownAreas
end

---------------------------------------------------------------------------
-- Lists
---------------------------------------------------------------------------

local zoneRows, resRows = {}, {}

local function ZoneRow(i)
	local row = zoneRows[i]
	if not row then
		row = CreateFrame("Button", nil, frame.zoneContent)
		row:SetSize(LIST_WIDTH - 30, ROW_HEIGHT)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row.selected = row:CreateTexture(nil, "BACKGROUND")
		row.selected:SetAllPoints()
		row.selected:SetColorTexture(1, 0.82, 0, 0.2)
		row.name = UI.Text(row, "GameFontHighlightSmall", "")
		row.name:SetPoint("LEFT", 4, 0)
		row.info = UI.Text(row, "GameFontDisableSmall", "")
		row.info:SetPoint("RIGHT", -4, 0)
		row:SetScript("OnClick", function(self)
			J.SelectZone(self.map)
		end)
		zoneRows[i] = row
	end
	row:Show()
	return row
end

local function ResRow(i)
	local row = resRows[i]
	if not row then
		row = CreateFrame("Button", nil, frame.resContent)
		row:SetSize(PREVIEW_WIDTH - 20, RES_ROW_HEIGHT)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row.selected = row:CreateTexture(nil, "BACKGROUND")
		row.selected:SetAllPoints()
		row.selected:SetColorTexture(1, 0.82, 0, 0.2)
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(RES_ROW_HEIGHT - 4, RES_ROW_HEIGHT - 4)
		row.icon:SetPoint("LEFT", 2, 0)
		row.name = UI.Text(row, "GameFontHighlight", "")
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
		row.detail = UI.Text(row, "GameFontDisableSmall", "")
		row.detail:SetPoint("RIGHT", -6, 0)
		row:SetScript("OnClick", function(self)
			J.Focus(self.res)
		end)
		row:SetScript("OnEnter", function(self)
			if self.item then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetItemByID(self.item)
				GameTooltip:Show()
			end
		end)
		row:SetScript("OnLeave", GameTooltip_Hide)
		resRows[i] = row
	end
	row:Show()
	return row
end

local function RefreshZones()
	for _, row in ipairs(zoneRows) do row:Hide() end
	local zones = J.Zones(state.kind, state.search)
	for i, z in ipairs(zones) do
		local row = ZoneRow(i)
		row.map = z.map
		row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
		row.name:SetText(z.name)
		row.info:SetText(z.skill or (z.nodes > 0 and tostring(z.nodes) or ""))
		row.selected:SetShown(z.map == state.map)
	end
	frame.zoneContent:SetHeight(math.max(1, #zones * ROW_HEIGHT))
	frame.empty:SetShown(#zones == 0)
	frame.empty:SetText(L["No data for %s yet. Gather, import or receive nodes from your guild to fill the journal."]:format(KindInfo(state.kind).name))
	return zones
end

local function RefreshResources()
	for _, row in ipairs(resRows) do row:Hide() end
	if not state.map then
		frame.zoneTitle:SetText("")
		return {}
	end
	local skill = J.ZoneSkillText(state.kind, state.map)
	frame.zoneTitle:SetText(skill and ("%s  |cffaaaaaa%s|r"):format(J.ZoneName(state.map), skill) or J.ZoneName(state.map))
	local list = J.Resources(state.kind, state.map)
	for i, e in ipairs(list) do
		local row = ResRow(i)
		row.res, row.item = e.res, e.item
		row:SetPoint("TOPLEFT", 0, -(i - 1) * RES_ROW_HEIGHT)
		row.icon:SetTexture(D.ResourceIcon(state.kind, e.res))
		row.name:SetText(e.name)
		row.detail:SetText(J.ResourceDetail(e))
		row.selected:SetShown(e.res == state.focus)
	end
	frame.resContent:SetHeight(math.max(1, #list * RES_ROW_HEIGHT))
	return list
end

function J.Refresh()
	if not frame or not frame:IsShown() then
		return
	end
	frame:SetTitle(J.SkillText(state.kind))
	frame:SetPortraitToAsset(C_Spell.GetSpellTexture(KindInfo(state.kind).spells[1]) or 134400)
	frame.kindDropdown:Refresh()
	local zones = RefreshZones()
	if state.map and not ZoneSet(state.kind)[state.map] then
		state.map = nil
	end
	if not state.map and zones[1] then
		state.map = zones[1].map
		RefreshZones()
	end
	RefreshResources()
	J.DrawPreview()
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------

function J.SelectKind(kind)
	state.kind, state.map, state.focus = kind, nil, nil
	DB.global.windows.journal.kind = kind
	J.Refresh()
end

function J.SelectZone(map)
	state.map, state.focus = map, nil
	J.Refresh()
end

function J.Focus(res)
	state.focus = (state.focus ~= res) and res or nil
	J.Refresh()
end

function J.CurrentZone()
	local map = C_Map.GetBestMapForUnit("player")
	if map then
		state.search = ""
		frame.search:SetText("")
		J.SelectZone(map)
	end
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

-- Position relative to UIParent at the window's current anchor points (qnCore.SavePoint)
local function SavePosition(f, key)
	local point, _, relPoint = f:GetPoint()
	DB.global.windows[key].pos = qnCore.SavePoint(f, point or "CENTER", relPoint or "CENTER") or DB.global.windows[key].pos
end
J.SavePosition = SavePosition

local function RestorePosition(f, key, default)
	local pos = DB.global.windows[key].pos
	if pos then
		qnCore.RestorePoint(f, pos)
	else
		f:ClearAllPoints()
		f:SetPoint(unpack(default))
	end
end
J.RestorePosition = RestorePosition

-- Movable window with the position in qnGathererDB.global.windows[key], Escape closes
function J.SetupWindow(f, key, default)
	UI.Movable(f, { toplevel = true, onStop = function(self) SavePosition(self, key) end })
	RestorePosition(f, key, default)
end

local function KindEntries()
	local list = {}
	for _, key in ipairs(ns.OptionKinds()) do
		list[#list + 1] = { key, ns.KINDS[key].name }
	end
	if #DB.GetSkinning() > 0 then
		list[#list + 1] = { SKINNING_KEY, SKINNING }
	end
	return list
end

local function Create()
	frame = CreateFrame("Frame", "qnGathererJournal", UIParent, "ButtonFrameTemplate")
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetFrameStrata("HIGH")
	J.SetupWindow(frame, "journal", { "CENTER", UIParent, "CENTER", 0, 40 })
	tinsert(UISpecialFrames, frame:GetName())
	frame:Hide()
	frame.Inset:ClearAllPoints()
	frame.Inset:SetPoint("TOPLEFT", 4, -60)
	frame.Inset:SetPoint("BOTTOMRIGHT", -6, 26)

	frame.kindDropdown = UI.Dropdown(frame, 180, KindEntries, function() return state.kind end, J.SelectKind)
	frame.kindDropdown:SetPoint("TOPLEFT", 70, -30)

	frame.search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
	frame.search:SetSize(LIST_WIDTH - 20, 20)
	frame.search:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 12, -8)
	frame.search:HookScript("OnTextChanged", function(self)
		state.search = self:GetText() or ""
		RefreshZones()
	end)
	frame.current = UI.Button(frame, L["Current zone"], LIST_WIDTH - 20, J.CurrentZone)
	frame.current:SetPoint("TOPLEFT", frame.search, "BOTTOMLEFT", -4, -4)

	local zoneScroll = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
	zoneScroll:SetPoint("TOPLEFT", frame.current, "BOTTOMLEFT", 0, -6)
	zoneScroll:SetPoint("BOTTOMLEFT", frame.Inset, "BOTTOMLEFT", 8, 6)
	zoneScroll:SetWidth(LIST_WIDTH - 24)
	frame.zoneContent = CreateFrame("Frame", nil, zoneScroll)
	frame.zoneContent:SetSize(LIST_WIDTH - 30, 1)
	zoneScroll:SetScrollChild(frame.zoneContent)
	frame.empty = UI.Text(frame, "GameFontDisable", "")
	frame.empty:SetWidth(LIST_WIDTH - 30)
	frame.empty:SetPoint("TOPLEFT", zoneScroll, "TOPLEFT", 4, -4)

	frame.zoneTitle = UI.Text(frame, "GameFontNormalLarge", "")
	frame.zoneTitle:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", LIST_WIDTH + 12, -10)

	preview = CreateFrame("Frame", nil, frame)
	preview:SetSize(PREVIEW_WIDTH, PREVIEW_WIDTH * 2 / 3)
	preview:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", LIST_WIDTH + 10, -34)
	preview:SetClipsChildren(true)
	canvas = CreateFrame("Frame", nil, preview)
	canvas:SetPoint("TOPLEFT")
	frame.noMap = UI.Text(preview, "GameFontDisable", L["No map available for this zone."])
	frame.noMap:SetPoint("CENTER")

	local resScroll = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
	resScroll:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -8)
	resScroll:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -26, 6)
	frame.resContent = CreateFrame("Frame", nil, resScroll)
	frame.resContent:SetSize(PREVIEW_WIDTH - 20, 1)
	resScroll:SetScrollChild(frame.resContent)

	frame:SetScript("OnShow", function(self)
		J.Refresh()
		qnCore.Visible.Move(self)
	end)
	J.frame = frame
end

function J.Toggle()
	if not frame then Create() end
	frame:SetShown(not frame:IsShown())
end

function J.Show(kind, map)
	if not frame then Create() end
	if kind and kind ~= state.kind then
		J.SelectKind(kind)
	end
	if map then
		state.map, state.focus = map, nil
	end
	if frame:IsShown() then
		J.Refresh()
	else
		frame:Show()
	end
end

function J.Init()
	local kinds = ns.OptionKinds()
	local saved = DB.global.windows.journal.kind
	state.kind = (saved and KindInfo(saved)) and saved or kinds[1] or ns.KIND_ORDER[1]
	D.OnRefresh(J.Refresh)
end
