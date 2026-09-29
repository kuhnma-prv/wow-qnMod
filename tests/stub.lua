-- Minimaler WoW-Nachbau für Ladetests der qn-Addons (Forever-Client). Kein Anspruch auf Treue:
-- unbekannte Methoden sind No-ops, Fehler zeigen Lücken des Nachbaus ODER echte Fehler.

LOG = {}
local function log(fmt, ...) LOG[#LOG + 1] = string.format(fmt, ...) end
function Log(...) log(...) end

unpack = table.unpack
format, strmatch, strsub, strfind, strlen, strupper, strlower, gsub, strrep = string.format, string.match, string.sub, string.find, string.len, string.upper, string.lower, string.gsub, string.rep
floor, ceil, abs, max, min, mod = math.floor, math.ceil, math.abs, math.max, math.min, math.fmod
function tContains(t, v) for _, x in pairs(t) do if x == v then return true end end return false end
sort = table.sort
time, date = os.time, os.date
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function strtrim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
function strsplit(sep, s) local out = {} for p in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = p end return unpack(out) end
tinsert, tremove = table.insert, table.remove
function CopyTable(t) if type(t) ~= "table" then return t end local c = {} for k, v in pairs(t) do c[k] = CopyTable(v) end return c end
function tAppendAll(a, b) for _, v in ipairs(b) do a[#a + 1] = v end end
function nop() end
function Mixin(obj, ...) for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do obj[k] = v end end return obj end
function CreateFromMixins(...) return Mixin({}, ...) end
function GetClassAtlas(class) return "classicon-" .. tostring(class):lower() end
-- Kontextmenü: MENU_LOG hält die Einträge des zuletzt erzeugten Menüs ({ art, text })
MENU_LOG = {}
local function MenuRoot()
	local root = {}
	local function add(kind) return function(_, text) MENU_LOG[#MENU_LOG + 1] = { kind, text } return MenuRoot() end end
	root.CreateTitle, root.CreateButton, root.CreateCheckbox, root.CreateRadio = add("title"), add("button"), add("checkbox"), add("radio")
	root.CreateDivider, root.CreateSpacer, root.SetTag = add("divider"), add("spacer"), nop
	return root
end
MenuUtil = { CreateContextMenu = function(owner, gen) MENU_LOG = {} gen(owner, MenuRoot()) return {} end }
function geterrorhandler() return function(e) error(e, 0) end end
function securecallfunction(f, ...) return f(...) end
-- Sprache des nachgebauten Clients (run.mjs: Umgebungsvariable QN_LOCALE, Vorgabe deDE) und die
-- echten Blizzard-GlobalStrings von Forever in dieser Sprache (GlobalStrings/<Sprache>.lua)
LOCALE = LOCALE or "deDE"
function GetLocale() return LOCALE end
do
	local src = READFILE(TESTDIR .. "GlobalStrings/" .. LOCALE .. ".lua")
	assert(src, "GlobalStrings fehlen: " .. LOCALE)
	-- nur gültige Zuweisungen (die Datei enthält vereinzelt Müllzeilen wie `Tests Iacobellis = "Hallo";`)
	local ok = {}
	for line in src:gmatch("[^\n]+") do
		if line:match("^[%a_][%w_]* = \"") or line:match("^_G%[\"") then
			ok[#ok + 1] = line
		end
	end
	-- GlobalStrings enthält u. a. ADDONS = "AddOns"; den Ordnerpfad der Attrappe behalten
	local addonsPath = ADDONS
	assert(load(table.concat(ok, "\n"), "=GlobalStrings/" .. LOCALE))()
	ADDONS = addonsPath
end
NUM_CONTAINER_FRAMES = 13
NUM_ACTIONBAR_BUTTONS = 12
NUM_TOTAL_BAG_FRAMES = 5

-- Zeit und Timer -------------------------------------------------------------
local now = 1000
function GetTime() return now end
-- Zeit der Attrappe setzen bzw. vorstellen (Szenarien mit Restzeiten)
function SetTime(t) now = t end
function AdvanceTime(dt) now = now + dt end
local timers = {}
C_Timer = {}
function C_Timer.After(s, fn) timers[#timers + 1] = fn end
-- Ticker laufen nur über RunTickers() (je ein Durchlauf aller nicht abgebrochenen)
local tickers = {}
function C_Timer.NewTicker(s, fn) local t = { fn = fn } function t:Cancel() self.cancelled = true end tickers[#tickers + 1] = t return t end
function RunTickers() for _, t in ipairs(tickers) do if not t.cancelled then t.fn() end end end
function RunTimers()
	for _ = 1, 10 do
		if #timers == 0 then return end
		local list = timers
		timers = {}
		for _, fn in ipairs(list) do fn() end
	end
end

-- Ereignisse und Rahmen ---------------------------------------------------------
local frames = {}
local VALID = {}
for _, e in ipairs({ "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_DEAD", "MINIMAP_UPDATE_TRACKING",
	"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
	"PLAYER_REGEN_DISABLED", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "EDIT_MODE_LAYOUTS_UPDATED",
	"ZONE_CHANGED_NEW_AREA", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "MERCHANT_SHOW", "MERCHANT_CLOSED",
	"AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "TRADE_SHOW", "TRADE_CLOSED", "MAIL_SHOW", "MAIL_CLOSED",
	"MAIL_INBOX_UPDATE", "BAG_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "UNIT_THREAT_LIST_UPDATE",
	"UNIT_THREAT_SITUATION_UPDATE", "PLAYER_TARGET_CHANGED", "GROUP_ROSTER_UPDATE", "UPDATE_BINDINGS",
	"ACTIONBAR_SLOT_CHANGED", "UPDATE_SHAPESHIFT_FORM", "PLAYER_FOCUS_CHANGED", "UNIT_PET",
	"PLAYERBANKSLOTS_CHANGED", "ACTIONBAR_SHOWGRID", "ACTIONBAR_HIDEGRID", "BANK_TABS_CHANGED", "MAIL_FAILED", "MAIL_SEND_SUCCESS", "PLAYER_SPECIALIZATION_CHANGED", "UNIT_AURA", "GUILDBANKFRAME_OPENED", "GUILDBANKFRAME_CLOSED", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED", "WEAPON_ENCHANT_CHANGED", "UNIT_EXITING_VEHICLE", "UNIT_ENTERING_VEHICLE", "WEAPON_SLOT_CHANGED", "ADDON_RESTRICTION_STATE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "ACTIONBAR_PAGE_CHANGED", "CVAR_UPDATE" }) do
	VALID[e] = true
end
VALID.SECURE_TRANSFER_CANCEL = true   -- SecureTransferDocumentation (qnInventory)
VALID.ACCOUNT_MONEY = true   -- CurrencyInfoDocumentation (qnInventory)
VALID.PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = true   -- BankDocumentation (qnInventory)
C_EventUtils ={ IsEventValid = function(e) return VALID[e] or false end }

local Frame = {}
local FrameMT
local ChildMT
-- Unbekannte Großbuchstaben-Schlüssel: aufrufbarer Kindrahmen (Methode = No-op, Feld = parentKey-Kind)
FrameMT = { __index = function(t, k)
	-- Eingabefelder haben keine Methoden von Kontrollkästchen
	if (k == "SetChecked" or k == "GetChecked") and rawget(t, "_kind") == "EditBox" then return nil end
	local v = Frame[k]
	if v ~= nil then return v end
	if type(k) == "string" and (k:match("^%u") or (tostring(rawget(t, "_template")):find("Button") and k:match("^%l") and k ~= "db" and k ~= "entry" and k ~= "key")) then
		local child = setmetatable({ _scripts = {}, _events = {}, _kind = "Child", _shown = true, _w = 30, _h = 30 }, ChildMT)
		rawset(t, k, child)
		return child
	end
end }
ChildMT = { __index = FrameMT.__index, __call = function() return nil end }

local function NewFrame(kind, name, parent)
	local f = setmetatable({ _scripts = {}, _events = {}, _kind = kind, _shown = true, _name = name, _parent = parent, _w = 100, _h = 100 }, FrameMT)
	frames[#frames + 1] = f
	if name then _G[name] = f end
	return f
end

function Frame:SetScript(s, fn) self._scripts[s] = fn end
function Frame:GetScript(s) return self._scripts[s] end
function Frame:HookScript(s, fn)
	local old = self._scripts[s]
	self._scripts[s] = function(...) if old then old(...) end fn(...) end
end
function Frame:RegisterEvent(e)
	if not VALID[e] then error("Unbekanntes Ereignis: " .. tostring(e), 2) end
	self._events[e] = true
end
function Frame:UnregisterEvent(e) self._events[e] = nil end
function Frame:UnregisterAllEvents() self._events = {} end
function Frame:IsEventRegistered(e) return self._events[e] end
function Frame:Show() local was = self._shown self._shown = true if not was and self._scripts.OnShow then self._scripts.OnShow(self) end end
function Frame:Hide() local was = self._shown self._shown = false if was and self._scripts.OnHide then self._scripts.OnHide(self) end end
function Frame:SetShown(on) if on then self:Show() else self:Hide() end end
function Frame:IsShown() return self._shown end
function Frame:IsVisible() return self._shown and (not self._parent or self._parent == UIParent or self._parent:IsVisible()) end
function Frame:GetName() return self._name end
function Frame:GetParent() return self._parent end
function Frame:SetParent(p) self._parent = p end
function Frame:GetWidth() return self._w end
function Frame:GetHeight() return self._h end
function Frame:SetWidth(w) self._w = w end
function Frame:SetHeight(h) self._h = h end
function Frame:SetSize(w, h) self._w, self._h = w, h end
function Frame:GetSize() return self._w, self._h end
function Frame:GetScale() return self._scale or 1 end
function Frame:SetScale(s) self._scale = s end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetLeft() return 0 end
function Frame:GetRight() return self._w end
function Frame:GetTop() return self._h end
function Frame:GetBottom() return 0 end
function Frame:GetCenter() return self._w / 2, self._h / 2 end
function Frame:GetRect() return 0, 0, self._w, self._h end
function Frame:GetFrameLevel() return 1 end
function Frame:GetFrameStrata() return "MEDIUM" end
function Frame:GetNumPoints() return 0 end
function Frame:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
function Frame:SetPoint(...) self._points = self._points or {} self._points[#self._points + 1] = { ... } end
function Frame:ClearAllPoints() self._points = {} end
function Frame:SetAllPoints(rel) self._points = { { "ALL", rel } } end
function Frame:IsProtected() return self._protected or false end
function Frame:IsForbidden() return false end
function Frame:IsMouseOver() return false end
function Frame:GetAlpha() return self._alpha or 1 end
function Frame:SetAlpha(a) self._alpha = a end
-- Darstellung protokollieren (Farben, Zuschnitt, Schrift, Ausrichtung, Maus, Bildschirmhaltung)
function Frame:SetVertexColor(r, g, b, a) self._color = { r, g, b, a or 1 } end
function Frame:SetColorTexture(r, g, b, a) self._color = { r, g, b, a or 1 } end
function Frame:SetTextColor(r, g, b, a) self._textColor = { r, g, b, a or 1 } end
function Frame:SetTexCoord(...) self._texCoord = { ... } end
function Frame:SetTexture(t) self._texture = t end
function Frame:GetTexture() return self._texture end
function Frame:SetBlendMode(m) self._blend = m end
function Frame:SetJustifyH(j) self._justifyH = j end
function Frame:GetJustifyH() return self._justifyH end
function Frame:SetFontObject(f) self._font = f end
function Frame:GetFontObject() return self._font end
function Frame:EnableMouse(on) self._mouse = on and true or false end
function Frame:IsMouseEnabled() return self._mouse or false end
function Frame:SetMovable(on) self._movable = on end
function Frame:StartMoving() self._moving = true end
function Frame:StopMovingOrSizing() self._moving = false end
function Frame:SetClampedToScreen(on) self._clamped = on end
function Frame:IsClampedToScreen() return self._clamped or false end
function Frame:SetClampRectInsets(l, r, t, b) self._clampInsets = { l, r, t, b } end
function Frame:GetClampRectInsets() local c = self._clampInsets if c then return c[1], c[2], c[3], c[4] end end
-- BackdropTemplate
function Frame:SetBackdrop(b) self._backdrop = b end
function Frame:SetBackdropColor(r, g, b, a) self._bdColor = { r, g, b, a or 1 } end
function Frame:SetBackdropBorderColor(r, g, b, a) self._bdBorder = { r, g, b, a or 1 } end
function Frame:GetID() return 0 end
function Frame:GetChecked() return self._checked end
function Frame:SetChecked(v) self._checked = v end
function Frame:GetText() return self._text end
function Frame:SetText(v) self._text = v end
-- secret-Zahlen (Tabellen der Szenarien) formatiert der Client auch mit %d/%f: dann als %s ausgeben
function Frame:SetFormattedText(f, ...)
	local ok, text = pcall(string.format, f, ...)
	if not ok then
		local secret = false
		for i = 1, select("#", ...) do
			if issecretvalue((select(i, ...))) then secret = true end
		end
		if not secret then error(text, 2) end
		text = f:gsub("%%[%d%.]*[dfi]", "%%s"):format(...)
	end
	self._text = text
end
function Frame:HasFocus() return false end
function Frame:GetStringWidth() return 50 end
function Frame:NumLines() return 0 end
function Frame:GetUnboundedStringWidth() return 50 end
function Frame:GetVerticalScroll() return 0 end
function Frame:GetVerticalScrollRange() return 0 end
function Frame:GetAttribute(k) return self._attr and self._attr[k] end
-- geschützte Rahmen: Attribute im Kampf gesperrt (ADDON_ACTION_BLOCKED im Client)
function Frame:SetAttribute(k, v)
	if self._protected and InCombatLockdown() then error("ADDON_ACTION_BLOCKED: SetAttribute(" .. tostring(k) .. ") im Kampf", 2) end
	self._attr = self._attr or {} self._attr[k] = v
end
function Frame:GetObjectType() return self._kind end
function Frame:GetChildren() return end
function Frame:GetRegions() return end
function Frame:GetFontString() return NewFrame("FontString") end
function Frame:GetStatusBarTexture() return NewFrame("Texture") end
function Frame:GetMinMaxValues() return 0, 1 end
function Frame:GetValue() return 0 end
function Frame:IsEnabled() return self._enabled ~= false end
function Frame:SetEnabled(on) self._enabled = on and true or false end
function Frame:GetEditBox() return NewFrame("EditBox") end
function Frame:CreateTexture() return NewFrame("Texture", nil, self) end
function Frame:CreateFontString() return NewFrame("FontString", nil, self) end
function Frame:CreateMaskTexture() return NewFrame("Texture", nil, self) end
function Frame:CreateAnimationGroup() return NewFrame("AnimationGroup", nil, self) end
function Frame:CreateAnimation() return NewFrame("Animation", nil, self) end
function Frame:CreateLine() return NewFrame("Line", nil, self) end
-- DropdownButton (WowStyle1DropdownTemplate)
function Frame:SetupMenu(gen) self._gen = gen self:GenerateMenu() end
function Frame:GenerateMenu()
	if not self._gen then return end
	local radios = {}
	local root = { CreateRadio = function(_, text, isSel, setSel) radios[#radios + 1] = { text = text, isSel = isSel, setSel = setSel } return {} end,
		CreateButton = nop, CreateCheckbox = nop, CreateTitle = nop, CreateDivider = nop,
		SetScrollMode = function(_, h) self._scrollHeight = h end }
	self._gen(self, root)
	self._radios = radios
	self._text = nil
	for _, r in ipairs(radios) do if r.isSel() then self._text = r.text end end
end
function Frame:PickRadio(i) self._radios[i].setSel() self:GenerateMenu() end

function CreateFrame(kind, name, parent, template)
	local f = NewFrame(kind, name, parent)
	f._template = template
	-- Secure*-Vorlagen erben SecureFrameTemplate (protected="true", SecureTemplatesBase.xml)
	if template and template:find("Secure") then f._protected = true end
	-- Vorlagen mit hidden="true" in qnBuffMod
	if template and (template:find("Header") or template:find("Consolidated")) then f._shown = false end
	-- ScrollFrameTemplate (SecureUIPanelTemplates.xml): ScrollFrame_OnLoad hängt die Scrollbar an
	if template == "ScrollFrameTemplate" then
		f.ScrollBar = NewFrame("EventFrame", nil, f)
	end
	if template == "MinimalSliderWithSteppersTemplate" then
		function f:Init(v, mn, mx, steps, fmt) self._value, self._fmt = v, fmt end
		function f:RegisterCallback(ev, fn, owner) self._cb, self._owner = fn, owner end
		function f:SetValue(v) self._value = v if self._cb then self._cb(self._owner, v) end end
		function f:GetValue() return self._value end
		function f:SetEnabled(on) self._enabled = on end
	end
	return f
end

MinimalSliderWithSteppersMixin = {
	Label = { Left = 1, Right = 2, Top = 3, Min = 4, Max = 5 },
	Event = { OnValueChanged = "OnValueChanged", OnInteractStart = "OnInteractStart", OnInteractEnd = "OnInteractEnd" },
}

function FireEvent(e, ...)
	for _, f in ipairs(frames) do
		if f._events[e] and f._scripts.OnEvent then
			f._scripts.OnEvent(f, e, ...)
		end
	end
end

UIParent = NewFrame("Frame", "UIParent")
UIParent._w, UIParent._h = 1920, 1080
-- Blizzard_UIParentUtil/UIParentUtil.lua (bei PLAYER_ENTERING_WORLD): TOPLEFT um Notch/Debug-Leisten versetzt
function UpdateUIParentPosition() UIParent:SetPoint("TOPLEFT", 0, -0) end
WorldFrame = NewFrame("Frame", "WorldFrame")
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
DEFAULT_CHAT_FRAME = NewFrame("ScrollingMessageFrame")
function DEFAULT_CHAT_FRAME:AddMessage(msg) print("  [Chat] " .. tostring(msg):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
ColorPickerFrame = NewFrame("Frame", "ColorPickerFrame")
SettingsPanel = NewFrame("Frame", "SettingsPanel")
Minimap = NewFrame("Frame", "Minimap")
function GameTooltip_Hide() end
-- Tooltip protokollieren: TOOLTIP.owner/anchor, TOOLTIP.lines (Texte in Reihenfolge), TOOLTIP.aura
TOOLTIP = { lines = {} }
function GameTooltip:SetOwner(owner, anchor) TOOLTIP = { owner = owner, anchor = anchor, lines = {} } self._shown = false end
function GameTooltip:IsOwned(f) return TOOLTIP.owner == f and TOOLTIP.owner ~= nil end
function GameTooltip:GetOwner() return TOOLTIP.owner end
function GameTooltip:AddLine(text, r, g, b) TOOLTIP.lines[#TOOLTIP.lines + 1] = { text = text, r = r, g = g, b = b } end
function GameTooltip:AddDoubleLine(l, r, ...) TOOLTIP.lines[#TOOLTIP.lines + 1] = { text = l, right = r } end
function GameTooltip:SetText(text) TOOLTIP.lines[#TOOLTIP.lines + 1] = { text = text } end
function GameTooltip:SetUnitAura(unit, index, filter) TOOLTIP.aura = { unit, index, filter } end
function GameTooltip:SetInventoryItem(unit, slot) TOOLTIP.item = { unit, slot } end
function GameTooltip:SetMinimumWidth(w) TOOLTIP.minWidth = w end
function GameTooltip:Hide() self._shown = false TOOLTIP.hidden = true end
-- Taschenplatz (ContainerFrameItemButtonMixin:OnUpdate) und Vergleichs-Tooltips (GameTooltip.xml:
-- shoppingTooltips; SharedXMLGame\Tooltip\TooltipComparisonManager.lua). EnableTooltips ersetzt die
-- Tooltips durch vollständigere und setzt beides dort erneut.
function GameTooltip:SetBagItem(bag, slot) TOOLTIP.bagItem = { bag, slot } self:Show() end
function GameTooltip:SetAnchorType(anchor, x, y) TOOLTIP.anchorType = { anchor, x, y } end
-- Blizzard_UIPanels_Game\Mainline\ContainerFrame.lua
function ContainerFrameItemButton_CalculateItemTooltipAnchors(self, mainTooltip)
	if self:GetRight() < GetScreenWidth() / 2 then
		mainTooltip:SetAnchorType("ANCHOR_RIGHT", 0, 0)
		mainTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT")
	else
		mainTooltip:SetAnchorType("ANCHOR_LEFT", 0, 0)
		mainTooltip:SetPoint("BOTTOMRIGHT", self, "TOPLEFT")
	end
end
ShoppingTooltip1 = NewFrame("GameTooltip", "ShoppingTooltip1")
ShoppingTooltip2 = NewFrame("GameTooltip", "ShoppingTooltip2")
GameTooltip.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 }
TooltipComparisonManager = {}
-- nur Anzeigen und Anker wie bei Blizzard; Seite aus TooltipComparisonManager.testSide
-- ("left"/"right", Vorgabe "right"; Blizzard wählt sie nach GetScreenWidth())
function TooltipComparisonManager:AnchorShoppingTooltips(primaryShown, secondaryShown)
	local tip = self.tooltip
	local p, s = tip.shoppingTooltips[1], tip.shoppingTooltips[2]
	local a = self.anchorFrame
	p:SetShown(primaryShown)
	s:SetShown(secondaryShown)
	p:SetPoint("TOP", a, 0, 0)
	if secondaryShown then
		s:SetPoint("TOP", a, 0, 0)
		if self.testSide == "left" then
			p:SetPoint("RIGHT", a, "LEFT")
			s:SetPoint("TOPRIGHT", p, "TOPLEFT")
		else
			s:SetPoint("LEFT", a, "RIGHT")
			p:SetPoint("TOPLEFT", s, "TOPRIGHT")
		end
	elseif self.testSide == "left" then
		p:SetPoint("RIGHT", a, "LEFT")
	else
		p:SetPoint("LEFT", a, "RIGHT")
	end
end
function print(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end io.write(table.concat(t, " "), "\n") end

-- Hooks -------------------------------------------------------------------------
function hooksecurefunc(a, b, c)
	local tbl, name, fn = a, b, c
	if type(a) == "string" then tbl, name, fn = _G, a, b end
	local old = tbl[name]
	if type(old) ~= "function" then
		assert(tbl ~= _G and type(old) == "table", "hooksecurefunc: " .. tostring(name) .. " ist keine Funktion")
		old = nop   -- Methode, die der Nachbau nicht kennt
	end
	tbl[name] = function(...) local r = { old(...) } fn(...) return unpack(r) end
end

-- Spieler / Client --------------------------------------------------------------
function UnitName(u) return "Tester" end
function GetRealmName() return "Realm" end
function UnitClass() return "Krieger", "WARRIOR" end
function UnitFactionGroup() return "Alliance" end
function UnitExists() return false end
function UnitGUID() return "Player-1" end
function InCombatLockdown() return QN_COMBAT or false end
function UnitIsDeadOrGhost() return QN_DEAD or false end

-- Verfolgung an der Minikarte (Felder wie MinimapScriptTrackingFilter/-Info in Forever).
-- QN_TRACKING_BLOCKED: SetTracking bewirkt nichts (Zauber scheitert).
QN_TRACKING = {
	{ name = "Briefkasten", filterID = 12, active = true },
	{ name = "Kräutersuche", spellID = 2383, active = false },
	{ name = "Mineraliensuche", spellID = 2580, active = false },
}
C_Minimap = {}
function C_Minimap.GetNumTrackingTypes() return #QN_TRACKING end
function C_Minimap.GetTrackingFilter(i) local t = QN_TRACKING[i] return { spellID = t.spellID, filterID = t.filterID } end
function C_Minimap.GetTrackingInfo(i)
	local t = QN_TRACKING[i]
	if not t then return nil end
	return { name = t.name, texture = 0, active = t.active, type = t.spellID and "spell" or "other", subType = 0, spellID = t.spellID }
end
function C_Minimap.SetTracking(i, on)
	log("SetTracking(%d,%s)", i, tostring(on))
	if not QN_TRACKING_BLOCKED then QN_TRACKING[i].active = on end
	FireEvent("MINIMAP_UPDATE_TRACKING")
end
function C_Minimap.ClearAllTracking()
	for _, t in ipairs(QN_TRACKING) do t.active = false end
	FireEvent("MINIMAP_UPDATE_TRACKING")
end
function GetBuildInfo() return "1.60.1", "70009", "", 16001 end
function GetPhysicalScreenSize() return 5760, 2160 end
function GetCursorPosition() return 0, 0 end
function IsShiftKeyDown() return false end
function GetMoney() return 12345 end
function GetMoneyString(c) return tostring(c) end
function GetBindingKey() return nil end
function GetBindingAction() return "" end
function SetBinding() return true end
function SetOverrideBinding() end
function SetOverrideBindingClick() end
function ClearOverrideBindings() end
function RegisterStateDriver() end
function UnregisterStateDriver() end
function RegisterAttributeDriver() end
function UnregisterAttributeDriver() end
function GetActionInfo() return nil end
function HasAction() return false end
function GetNumShapeshiftForms() return 0 end
function PlaySound() end
TooltipDataProcessor = { AddTooltipPostCall = nop, AllTypes = 'ALL' }
function SendMail() end
function GetInboxNumItems() return 0, 0 end
function GetInboxHeaderInfo() return nil end
function GetInboxItem() return nil end
function GetItemInfoInstant() return nil end
for _, n in ipairs({ 'SecureHandlerExecute', 'SecureHandlerSetFrameRef', 'SecureHandlerWrapScript', 'SecureHandlerUnwrapScript', 'ActionButton_UpdateCooldown', 'SetCVar', 'ClearCursor', 'PickupAction', 'PlaceAction' }) do _G[n] = nop end
function GetCVar(k) return C_CVar._v[k] end
function GetCVarBool(k) return C_CVar._v[k] == '1' end
function IsModifiedClick() return false end
function GetModifiedClick() return 'SHIFT' end
function GetActionTexture() return nil end
function UnitAffectingCombat() return false end
function IsInGroup() return false end
function IsInRaid() return false end
function StaticPopup_Show(which, a1, a2, data) LAST_POPUP = { which = which, a1 = a1, data = data } end
SlashCmdList, StaticPopupDialogs = {}, {}
C_AddOns = {
	GetAddOnMetadata = function(a, f) return "test" end,
	IsAddOnLoaded = function() return false end,
	LoadAddOn = function() return false end,
}
C_ClassColor = { GetClassColor = function() return { WrapTextInColorCode = function(_, s) return s end } end }
C_CVar = { _v = { showTimestamps = "none", mapFade = "1", combinedBags = "0" } }
function C_CVar.GetCVar(k) return C_CVar._v[k] end
function C_CVar.SetCVar(k, v) C_CVar._v[k] = v log("SetCVar %s=%s", k, tostring(v)) end
function C_CVar.GetCVarBool(k) return C_CVar._v[k] == "1" end
C_VideoOptions = { GetCurrentGameWindowSize = function() return { x = 5760, y = 2160 } end }
C_Container = { GetContainerNumSlots = function(id) return 16 end, GetContainerItemInfo = function() return nil end }
C_Map = { GetBestMapForUnit = function() return 1 end }
C_ActionBar = setmetatable({}, { __index = function() return function() return false end end })
C_Bank = { FetchPurchasedBankTabData = function() return {} end }

Enum = {
	EditModeLayoutType = { Preset = 0, Account = 1, Character = 2, Server = 3 },
	EditModePresetLayoutsMeta = { NumValues = 2 },
	BagIndex = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, Keyring = -1, CharacterBankTab_1 = 6 },
	DamageMeterStyle = {},
	TooltipDataType = { Item = 0 },
}

-- Taschenfunktionen protokollieren
for _, fn in ipairs({ "CloseAllBags", "OpenBackpack", "OpenBag", "ToggleAllBags", "ToggleBackpack", "ToggleBag", "UpdateContainerFrameAnchors" }) do
	_G[fn] = function(a) log("%s(%s)", fn, tostring(a)) end
end

OPEN = {}
EventRegistry = { cbs = {} }
function EventRegistry:RegisterCallback(ev, fn, owner) self.cbs[ev] = self.cbs[ev] or {} table.insert(self.cbs[ev], fn) end
function EventRegistry:TriggerEvent(ev) for _, fn in ipairs(self.cbs[ev] or {}) do fn() end end
function OpenAllBags(a) log("OpenAllBags(%s)", tostring(a)) for i = 0, 5 do OPEN[i] = true end EventRegistry:TriggerEvent("ContainerFrame.OpenAllBags") end
function IsBagOpen(id) return OPEN[id] or false end
function CloseBag(id) OPEN[id] = nil log("CloseBag(%d)", id) end
PROF_BAGS = { [3] = true }
function IsInventoryItemProfessionBag(u, inv) return PROF_BAGS[inv - 30] or false end
C_Container.ContainerIDToInventoryID = function(id) return id + 30 end
Enum.BagIndex.ReagentBag = 5

-- qnInventory-Bedarf: Blizzards Fenster, an die die Kopfleisten der Ansichten kommen
ContainerFrameCombinedBags = NewFrame("Frame", "ContainerFrameCombinedBags", UIParent)
BankFrame = NewFrame("Frame", "BankFrame", UIParent)
MailFrame = NewFrame("Frame", "MailFrame", UIParent)
UISpecialFrames = {}
-- Blizzard-Addons sind in der Attrappe immer schon geladen
EventUtil = { ContinueOnAddOnLoaded = function(name, fn) fn() end }
C_Bank.FetchMaxNumBankTabs = function() return 1 end
C_Bank.FetchNextPurchasableBankTabData = function() return nil end
function GetInventoryItemLink() return nil end
function GetInboxItemLink() return nil end

-- qnBuffMod-Bedarf
BuffFrame = NewFrame("Frame", "BuffFrame")
DebuffFrame = NewFrame("Frame", "DebuffFrame")
ChatFontNormal = NewFrame("Font", "ChatFontNormal")
function ChatFontNormal:GetFont() return "Fonts\\ARIALN.TTF", 14, "" end
GameFontNormal = NewFrame("Font", "GameFontNormal")
function GameFontNormal:GetFont() return "Fonts\\FRIZQT__.TTF", 12, "" end
function CreateFont(name) local f = NewFrame("Font", name) f.GetFont = function() return "x", 12, "" end return f end

-- Questzielverfolgung (Blizzard_ObjectiveTracker) --------------------------------
-- Schriften mit Datei/Höhe; SetFontObject übernimmt wie im Client Datei und Höhe der Vorlage
local function TrackerFont(name, height)
	local f = NewFrame("Font", name)
	f._path, f._height, f._flags = "Fonts\\FRIZQT__.TTF", height, ""
	function f:GetFont() return self._path, self._height, self._flags end
	function f:SetFont(path, h, flags) self._path, self._height, self._flags = path, h, flags end
	function f:SetFontObject(src)
		if type(src) == "string" then src = _G[src] end
		self._font = src
		self._path, self._height, self._flags = src:GetFont()
	end
	_G[name] = f
	return f
end
for size = 12, 22 do TrackerFont("ObjectiveTrackerFont" .. size, size) end
TrackerFont("ObjectiveTrackerLineFont", 12)
TrackerFont("ObjectiveTrackerHeaderFont", 14)
-- wie Blizzard_ObjectiveTrackerManager.lua (Grenzen 12–20, Überschrift 2 größer)
ObjectiveTrackerManager = { updates = 0 }
function ObjectiveTrackerManager:UpdateAll() self.updates = self.updates + 1 end
function ObjectiveTrackerManager:SetTextSize(textSize)
	if textSize < 12 or textSize > 20 then return end
	ObjectiveTrackerLineFont:SetFontObject("ObjectiveTrackerFont" .. textSize)
	ObjectiveTrackerHeaderFont:SetFontObject("ObjectiveTrackerFont" .. (textSize + 2))
	self:UpdateAll()
end
GameFontNormalSmall = NewFrame("Font", "GameFontNormalSmall")
ChatFontSmall = NewFrame("Font", "ChatFontSmall")
NumberFontNormal = NewFrame("Font", "NumberFontNormal")
-- Tastentext zur Taste (C-Funktion)
function GetBindingText(key) return key end
-- Tooltipdaten eines Inventarplatzes: QN_TOOLTIP[Platz] = { "Zeile", … } (leftText je Zeile)
QN_TOOLTIP = {}
C_TooltipInfo = { GetInventoryItem = function(unit, slot)
	local lines = QN_TOOLTIP[slot]
	if not lines then return nil end
	local data = { lines = {} }
	for i, text in ipairs(lines) do data.lines[i] = { leftText = text } end
	return data
end }
INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED = 16, 17, 18
ENCHANTS = {}
C_PaperDollInfo = { GetTemporaryEnchantmentInfo = function(slot) return ENCHANTS[slot] end }
AURAS = {}
-- Filter wie im Client: HELPFUL/HARMFUL (isHarmful), CANCELABLE bzw. !CANCELABLE (Feld cancelable)
local function MatchesFilter(a, filter)
	filter = filter or "HELPFUL"
	if (a.isHarmful or false) ~= (filter:find("HARMFUL") ~= nil) then return false end
	if filter:find("!CANCELABLE", 1, true) then return not a.cancelable end
	if filter:find("CANCELABLE", 1, true) then return a.cancelable or false end
	return true
end
-- QN_AURAS_SECRET: Aurendaten gesperrt (Kampf); dann bricht die Abfrage ab wie im Client.
-- Auren mit locked = true sind einzeln gesperrt.
C_UnitAuras = { GetAuraDataByIndex = function(unit, i, filter)
	if QN_AURAS_SECRET then error("GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted") end
	local n = 0
	for _, a in ipairs(AURAS[unit] or {}) do
		if MatchesFilter(a, filter) then n = n + 1 if n == i then if a.locked then error("GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted") end return a end end
	end
end }
C_Spell = { IsSpellUsable = function() return true, false end }
function SecureCmdOptionParse(c) return "show", nil end
function GetInventoryItemTexture() return 134400 end
function CancelUnitBuff() end
function IsAltKeyDown() return false end
function IsControlKeyDown() return false end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
function UnitHasVehicleUI() return false end
function UnitIsUnit(a, b) return a == b end
function PlaySoundFile() end
function UnitIsPlayer(u) return u == "player" end
function UnitPlayerControlled(u) return u == "player" or u == "pet" end
function UnitIsFriend() return true end
function UnitCanAttack() return false end
function UnitInVehicle() return false end
function UnitClassBase() return "WARRIOR" end
function GetUnitName(u) return u end
RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { r = 1, g = 1, b = 1, colorStr = "ffffffff" } end })
function RegisterUnitWatch() end
function UnregisterUnitWatch() end
function GetInventoryItemID() return nil end
function GetItemInfo() return nil end
function IsInInstance() return false end
function CreateColor(r, g, b, a)
	local c = { r = r, g = g, b = b, a = a or 1 }
	function c:GetRGB() return self.r, self.g, self.b end
	function c:GenerateHexColor() return ("ff%02x%02x%02x"):format(math.floor(self.r * 255 + 0.5), math.floor(self.g * 255 + 0.5), math.floor(self.b * 255 + 0.5)) end
	return c
end
function CreateColorFromHexString(h)
	local a, r, g, b = h:match("^(%x%x)(%x%x)(%x%x)(%x%x)$")
	return CreateColor(tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, tonumber(a, 16) / 255)
end
AuraUtil = {
	GetAuraBorderColor = function(t) return CreateColor(t == "Magic" and 0.2 or 0.8, 0, 0) end,
	SetAuraSymbol = function(fs) fs:Hide() end,
}
function UnitInRange() return false end

-- direkt genutzte Blizzard-Globals (Forever)
issecretvalue = function() return false end
TIMESTAMP_FORMAT_NONE = "Keine"
TIMESTAMP_FORMAT_HHMM, TIMESTAMP_FORMAT_HHMMSS = "%I:%M ", "%I:%M:%S "
TIMESTAMP_FORMAT_HHMM_AMPM, TIMESTAMP_FORMAT_HHMMSS_AMPM = "%I:%M %p ", "%I:%M:%S %p "
TIMESTAMP_FORMAT_HHMM_24HR, TIMESTAMP_FORMAT_HHMMSS_24HR = "%H:%M ", "%H:%M:%S "
TimeUtil = { BetterDate = function(f, t) return os.date(f, t) end }
C_Secrets = { ShouldAurasBeSecret = function() return QN_AURAS_SECRET or false end, ShouldUnitThreatValuesBeSecret = function() return false end, ShouldUnitThreatStateBeSecret = function() return false end }
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
Enum.BankType = { Character = 0, Guild = 1, Account = 2 }
-- Accountbank (BankDocumentation): Inhalt nur, wenn CanViewBank; Gold über FetchDepositedMoney
QN_ACCOUNT_BANK = { view = false, money = 0 }
C_Bank.CanViewBank = function(t) return t == Enum.BankType.Account and QN_ACCOUNT_BANK.view or t == Enum.BankType.Character end
C_Bank.FetchDepositedMoney = function(t) return t == Enum.BankType.Account and QN_ACCOUNT_BANK.money or 0 end
Enum.DamageMeterStyle = { Default = 0, Thin = 1, Bordered = 2, FullBackground = 3 }
RaidWarningFrame = NewFrame("Frame", "RaidWarningFrame")
ChatTypeInfo = setmetatable({}, { __index = function() return { r = 1, g = 1, b = 1 } end })
function BattlefieldMap_LoadUI() end
function ToggleWorldMap() end
function FCF_SavePositionAndDimensions() end
function GetSendMailMoney() return 0 end
function GetSendMailCOD() return 0 end
-- verbundene Realms (C_AutoComplete, AutoCompleteDocumentation); Szenarien setzen QN_CONNECTED_REALMS
C_AutoComplete = C_AutoComplete or {}
function C_AutoComplete.GetAutoCompleteRealms() return QN_CONNECTED_REALMS or {} end
C_Item = { IsItemInRange = function() return nil end }
C_Bank.FetchPurchasedBankTabData = function() return {} end

-- Settings-API ------------------------------------------------------------------
Settings = { VarType = { Boolean = "boolean", Number = "number", String = "string" } }
local variables = {}
SETTINGS = variables
local function Category(name)
	local c = { name = name }
	function c:GetID() return name end
	return c
end
local function Layout()
	local l = { inits = {} }
	function l:AddInitializer(i) self.inits[#self.inits + 1] = i end
	return l
end
local function Initializer(data)
	local i = data or {}
	function i:SetParentInitializer(p, pred) self.parent, self.pred = p, pred end
	function i:AddSearchTags() end
	return i
end
function Settings.RegisterVerticalLayoutCategory(n) return Category(n), Layout() end
function Settings.RegisterVerticalLayoutSubcategory(p, n) return Category(p.name .. "/" .. n), Layout() end
function Settings.RegisterCanvasLayoutCategory(f, n) return Category(n) end
function Settings.RegisterCanvasLayoutSubcategory(p, f, n) return Category(p.name .. "/" .. n) end
function Settings.RegisterAddOnCategory(c) log("Kategorie %s", c.name) end
function Settings.OpenToCategory(id) log("Öffne %s", tostring(id)) end
function Settings.RegisterAddOnSetting() error("RegisterAddOnSetting sollte nicht mehr benutzt werden") end
function Settings.RegisterProxySetting(cat, var, vt, name, default, get, set)
	assert(not variables[var], "Variable doppelt: " .. var)
	assert(default ~= nil, "Proxy ohne Vorgabe: " .. var)
	local s = { var = var, cbs = {}, vt = vt }
	function s:GetValue() return get() end
	function s:SetValue(v)
		assert(type(v) == vt, ("Typfehler %s: %s statt %s"):format(var, type(v), vt))
		set(v)
		for _, cb in ipairs(self.cbs) do cb(self, v) end
	end
	function s:NotifyUpdate() local v = get() for _, cb in ipairs(self.cbs) do cb(self, v) end end
	function s:SetValueChangedCallback(cb) self.cbs[#self.cbs + 1] = cb end
	function s:GetDefaultValue() return default end
	variables[var] = s
	local dv = get()
	assert(type(dv) == vt, ("Typfehler beim Lesen %s: %s statt %s"):format(var, type(dv), vt))
	return s
end
function Settings.CreateCheckbox(cat, s, tip) return Initializer({ setting = s }) end
function Settings.CreateSlider(cat, s, o, tip) return Initializer({ setting = s }) end
function Settings.CreateDropdown(cat, s, getOptions, tip)
	local opts = getOptions()
	assert(type(opts) == "table" and #opts > 0, "Dropdown ohne Einträge: " .. s.var)
	return Initializer({ setting = s, getOptions = getOptions })
end
function Settings.CreateSliderOptions() return { SetLabelFormatter = nop } end
function Settings.CreateColorSwatch(cat, s, tip) return Initializer({ setting = s }) end
function Settings.CreateControlTextContainer()
	local c = { data = {} }
	function c:Add(v, t) self.data[#self.data + 1] = { value = v, label = t } end
	function c:GetData() return self.data end
	return c
end
function CreateSettingsListSectionHeaderInitializer(t) return Initializer({ header = t }) end
function CreateSettingsButtonInitializer(n, bt, click) return Initializer({ button = bt, click = click }) end

-- Bearbeitungsmodus -------------------------------------------------------------
EditModeManagerFrame = NewFrame("Frame", "EditModeManagerFrame")
EDIT_LAYOUTS = {
	{ layoutType = 0, layoutName = "Modern" },
	{ layoutType = 0, layoutName = "Klassisch" },
	{ layoutType = 1, layoutName = "Raid" },
	{ layoutType = 2, layoutName = "Solo" },
}
function EditModeManagerFrame:UpdateLayoutInfo(info) self.layoutInfo = info end
function EditModeManagerFrame:SelectLayout(i) self.layoutInfo.activeLayout = i end
function EditModeManagerFrame:SaveLayouts() end
function SetEditModeLayout(i, viaSelect)
	if viaSelect and EditModeManagerFrame.layoutInfo then
		EditModeManagerFrame:SelectLayout(i)
	else
		EditModeManagerFrame.layoutInfo = { layouts = EDIT_LAYOUTS, activeLayout = i }
		FireEvent("EDIT_MODE_LAYOUTS_UPDATED")
	end
	RunTimers()
end

-- Addons laden ------------------------------------------------------------------
function LoadAddon(name)
	local ns = {}
	local toc = READFILE(ADDONS .. "/" .. name .. "/" .. name .. ".toc")
	assert(toc, "keine TOC: " .. name)
	for line in toc:gmatch("[^\n]+") do
		line = line:gsub("\r", "")
		if line ~= "" and not line:match("^#") and not line:match("%.xml$") then
			local path = ADDONS .. "/" .. name .. "/" .. line:gsub("\\", "/")
			-- fehlende Dateien überspringt WoW; qnViewPort\Monitors.lua ist rechnerabhängig (nicht im
			-- Repo), die Szenarien setzen qnViewPortMonitors selbst
			if line ~= "Monitors.lua" and READFILE(path) then
				local chunk, err = loadfile(path)
				assert(chunk, err)
				chunk(name, ns)
			end
		end
	end
	FireEvent("ADDON_LOADED", name)
	return ns
end

function Check(cond, msg)
	if cond then print("OK    " .. msg) else print("FEHLER " .. msg) FAILS = (FAILS or 0) + 1 end
end

-- qnInventory-Bedarf
local UMLAUT = { ["Ä"] = "ä", ["Ö"] = "ö", ["Ü"] = "ü" }
local function lowerUtf8(s) return (s:lower():gsub("\195[\132\150\156]", UMLAUT)) end
function strcmputf8i(a, b) a, b = lowerUtf8(a), lowerUtf8(b) return a == b and 0 or (a < b and -1 or 1) end
function GetNormalizedRealmName() return (GetRealmName():gsub("[%s%-]", "")) end
ATTACHMENTS_MAX_SEND, ATTACHMENTS_MAX_RECEIVE = 12, 16
NORMAL_FONT_COLOR = CreateColor(1, 0.82, 0)

-- zusammengefasste Taschen (CVar combinedBags)
ContainerFrameSettingsManager = { IsUsingCombinedBags = function(_, id) return C_CVar._v.combinedBags == "1" and (not id or (id >= 0 and id <= 4)) end }

-- qnMeter-Bedarf: eingebauter Damage Meter (Blizzard_DamageMeter), Balken-Hilfen
AbbreviateLargeNumbers = function(v) if issecretvalue(v) then return v end return tostring(math.floor(v)) end
Enum.StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 }
QN_DM = { barHeight = 30, spacing = 4, style = 1, textScale = 1.2, bgAlpha = 0.7, windowAlpha = 0.9, icons = false, classColor = true }
DamageMeter = NewFrame("Frame", "DamageMeter")
for key, field in pairs({ BarHeight = "barHeight", BarSpacing = "spacing", Style = "style", TextScale = "textScale", BackgroundAlpha = "bgAlpha", WindowAlpha = "windowAlpha" }) do
	DamageMeter["Get" .. key] = function() return QN_DM[field] end
	DamageMeter["Set" .. key] = function(_, v) QN_DM[field] = v end
end
function DamageMeter:ShouldShowBarIcons() return QN_DM.icons end
function DamageMeter:SetShowBarIcons(v) QN_DM.icons = v end
function DamageMeter:ShouldUseClassColor() return QN_DM.classColor end
function DamageMeter:SetUseClassColor(v) QN_DM.classColor = v end
-- qnViewPort-Bedarf: Weltkarte (Blizzard_WorldMap lädt nicht bei Bedarf), CVar-Vorgaben
WorldMapFrame = NewFrame("Frame", "WorldMapFrame")
WorldMapFrame._shown = false
function WorldMapFrame:SetMapID(id) self.mapID = id end
-- Maximieren/Verkleinern (Blizzard_WorldMap.lua): Fensterverwaltung setzt die maximierte Karte mit
-- maximizePoint "TOP" an UIParent, die verkleinerte als linkes Fenster an UIParent TOPLEFT
-- (UIParentPanelManager.lua, UpdateUIPanelPositions); die schwarze Fläche liegt über UIParent (XML).
WorldMapFrame.minimizedWidth, WorldMapFrame.minimizedHeight = 702, 534
WorldMapFrame.isMaximized = false
WorldMapFrame.BlackoutFrame = NewFrame("Frame", nil, WorldMapFrame)
WorldMapFrame.BlackoutFrame:SetAllPoints(UIParent)
function WorldMapFrame:IsMaximized() return self.isMaximized == true end
function WorldMapFrame:GetPoint(i) local p = (self._points or {})[i or 1] if p then return unpack(p) end end
function WorldMapFrame:OnFrameSizeChanged() end
function WorldMapFrame:UpdateMaximizedSize() self:SetSize(UIParent:GetHeight() * 1.3, UIParent:GetHeight()) end
function WorldMapFrame:SynchronizeDisplayState()
	self:ClearAllPoints()
	if self:IsMaximized() then
		self:SetPoint("TOP", UIParent, "TOP")
	else
		self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
	end
end
function WorldMapFrame:Maximize() self.isMaximized = true self:UpdateMaximizedSize() self:SynchronizeDisplayState() end
function WorldMapFrame:Minimize() self.isMaximized = false self:SetSize(self.minimizedWidth, self.minimizedHeight) self:SynchronizeDisplayState() end
-- Fensterverwaltung (UIParentPanelManager.lua): zeigt/verbirgt; Lage setzt die Karte oben selbst
function ShowUIPanel(frame) if frame then frame:Show() if frame.SynchronizeDisplayState then frame:SynchronizeDisplayState() end end end
function HideUIPanel(frame) if frame then frame:Hide() end end
function UpdateUIPanelPositions(frame) if frame and frame.SynchronizeDisplayState then frame:SynchronizeDisplayState() end end
C_CVar.GetCVarDefault = function(k) return ({ mapFade = "1" })[k] end

-- qnUnitFrames-Bedarf: Rahmen im Schlachtzugsstil (Blizzard_UnitFrame\Shared\CompactUnitFrame.lua),
-- klassische Gruppenrahmen (Shared\PartyFrame.lua: Pool aus PartyMemberFrameTemplate), Zauberbuch
function CompactUnitFrame_SetUpFrame(frame, func, ...) if func then func(frame, ...) end end
PartyFrame = NewFrame("Frame", "PartyFrame")
QN_PARTY_FRAMES = {}   -- aktive Rahmen des Pools
PartyFrame.PartyMemberFramePool = { EnumerateActive = function()
	local i = 0
	return function() i = i + 1 return QN_PARTY_FRAMES[i] end
end }
function PartyFrame:InitializePartyMemberFrames() end
Enum.TooltipDataType.Unit = 2
Enum.SpellBookSpellBank = { Player = 0, Pet = 1 }
Enum.SpellBookItemType = { None = 0, Spell = 1, FutureSpell = 2, PetAction = 3, Flyout = 4 }
-- QN_SPELLBOOK[Fähigkeitenlinie] = { info = SpellBookSkillLineInfo-Felder, items = { SpellBookItemInfo, … } }
QN_SPELLBOOK = {}
C_SpellBook = {}
function C_SpellBook.GetNumSpellBookSkillLines() return #QN_SPELLBOOK end
function C_SpellBook.GetSpellBookSkillLineInfo(i)
	local line = QN_SPELLBOOK[i]
	if not line then return nil end
	local offset = 0
	for j = 1, i - 1 do offset = offset + #QN_SPELLBOOK[j].items end
	local info = CopyTable(line.info or {})
	info.name = info.name or ("Linie " .. i)
	info.itemIndexOffset, info.numSpellBookItems = offset, #line.items
	info.isGuild, info.shouldHide = false, info.shouldHide or false
	return info
end
function C_SpellBook.GetSpellBookItemInfo(slot, bank)
	for _, line in ipairs(QN_SPELLBOOK) do
		if slot <= #line.items then
			local item = CopyTable(line.items[slot])
			item.itemType = item.itemType or Enum.SpellBookItemType.Spell
			item.isPassive = item.isPassive or false
			return item
		end
		slot = slot - #line.items
	end
end

-- Sicheres Umfeld (Blizzard_RestrictedAddOnEnvironment), nur auf Anforderung eines Szenarios:
-- EnableRestrictedEnvironment() vor LoadAddon aufrufen. Nachgebaut nach dem Forever-Quelltext:
--   SecureHandlerWrapScript (SecureHandlers.lua: Wrapped_Drag, Wrapped_Attribute, Wrapped_ShowHide;
--   false aus dem Vor-Schnipsel bricht ab), SecureHandlerExecute, Rahmen-Handles (RestrictedFrames.lua:
--   Get/SetAttribute, Show/Hide mit statehidden, ClearBindings, SetBindingClick, ChildUpdate nur direkte
--   Kinder), Umfang (RestrictedEnvironment.lua, Auszug; PlayerInCombat = UnitAffectingCombat),
--   Zustandstreiber (SecureStateDriver.lua: resolveDriver, visibility setzt statehidden),
--   _onstate-<Zustand> (SecureHandlerStateTemplate), Klick über Tastenbelegung (SecureTemplates.lua:
--   SecureActionButton_OnClick mit useOnKeyDown/CVar ActionButtonUseKeyDown, SECURE_ACTIONS.click).
-- Unsicherer Code darf Belegungen, Zustandstreiber und Umhüllungen im Kampf nicht ändern (Fehler).
-- Makrobedingungen: QN_CONDITIONS[Name] = true (vehicleui, combat, bonusbar:1 …), dann UpdateStateDrivers().
-- Belegungen: BINDINGS[Besitzer][Taste] = "Rahmenname:Maustaste"; PressBinding(Taste, down) drückt bzw.
-- lässt los (Klick nur, wenn der Rahmen die Richtung mit RegisterForClicks angemeldet hat).
-- WRAPPED[Rahmen][Skript] = { header, pre }: angelegte Umhüllungen.
function EnableRestrictedEnvironment()
	BINDINGS, WRAPPED = {}, {}
	QN_CONDITIONS = QN_CONDITIONS or {}
	local all, handles, drivers = {}, {}, {}
	local secureDepth = 0
	local Changed, Run

	local function Blocked(what)
		if InCombatLockdown() and secureDepth == 0 then
			error("ADDON_ACTION_BLOCKED: " .. what .. " im Kampf", 3)
		end
	end

	-- Attribut aus sicherem Code setzen (keine Kampfsperre) und OnAttributeChanged nachbilden
	local function RawSet(frame, k, v)
		frame._attr = frame._attr or {}
		frame._attr[k] = v
		Changed(frame, k, v)
	end

	local HANDLE = {}
	HANDLE.__index = HANDLE
	local function Handle(frame)
		if not frame then return nil end
		local h = handles[frame]
		if not h then
			h = setmetatable({ _frame = frame }, HANDLE)
			handles[frame] = h
		end
		return h
	end
	function HANDLE:GetAttribute(k) return self._frame:GetAttribute(k) end
	function HANDLE:SetAttribute(k, v)
		assert(type(k) == "string" and not k:match("^_"), "Invalid attribute name")
		RawSet(self._frame, k, v)
	end
	function HANDLE:GetName() return self._frame:GetName() end
	function HANDLE:IsShown() return self._frame:IsShown() end
	function HANDLE:Show(skip) self._frame:Show() if not skip then RawSet(self._frame, "statehidden", nil) end end
	function HANDLE:Hide(skip) self._frame:Hide() if not skip then RawSet(self._frame, "statehidden", true) end end
	function HANDLE:ClearBindings() ClearOverrideBindings(self._frame) end
	function HANDLE:SetBindingClick(prio, key, name, button)
		if getmetatable(name) == HANDLE then name = name:GetName() end
		assert(type(name) == "string" and not name:find(":"), "Invalid click target name")
		SetOverrideBindingClick(self._frame, prio, key, name, button)
	end
	function HANDLE:ChildUpdate(id, message)
		for _, f in ipairs(all) do
			if f:GetParent() == self._frame and f:IsProtected() then
				local body = f:GetAttribute("_childupdate-" .. tostring(id)) or f:GetAttribute("_childupdate")
				if body then Run(body, f, self._frame, "self,scriptid,message", id, message) end
			end
		end
	end

	Run = function(body, frame, header, signature, ...)
		local env = {
			self = Handle(frame), control = Handle(header),
			math = math, string = string, select = select, tonumber = tonumber, tostring = tostring,
			format = string.format, strsub = string.sub, strmatch = string.match, strfind = string.find,
			IsModifiedClick = IsModifiedClick, SecureCmdOptionParse = SecureCmdOptionParse,
			PlayerInCombat = function() return UnitAffectingCombat("player") or UnitAffectingCombat("pet") end,
		}
		local chunk = assert(load("local " .. signature .. " = ...\n" .. body, "=Schnipsel", "t", env))
		secureDepth = secureDepth + 1
		local r = table.pack(pcall(chunk, Handle(frame), ...))
		secureDepth = secureDepth - 1
		if not r[1] then error(r[2], 0) end
		return table.unpack(r, 2, r.n)
	end

	Changed = function(frame, k, v)
		local w = WRAPPED[frame] and WRAPPED[frame].OnAttributeChanged
		if w and type(k) == "string" and not k:match("^_") then
			Run(w.pre, frame, w.header, "self,name,value", k, v)
		end
		local id = type(k) == "string" and k:match("^state%-(.+)$")
		local body = id and frame:GetAttribute("_onstate-" .. id)
		if body then Run(body, frame, frame, "self,stateid,newstate", id, v) end
	end

	-- Rahmen merken (ChildUpdate), Attribute melden, Klicks anmelden, Click()
	local create = CreateFrame
	CreateFrame = function(...)
		local f = create(...)
		all[#all + 1] = f
		local set = f.SetAttribute
		f.SetAttribute = function(self, k, v)
			set(self, k, v)
			Changed(self, k, v)
		end
		f.RegisterForClicks = function(self, ...) self._clicks = { ... } end
		f.Click = function(self, button, down)
			if self._scripts.OnClick then self._scripts.OnClick(self, button or "LeftButton", down or false) end
		end
		return f
	end

	function SecureHandlerWrapScript(frame, script, header, pre)
		Blocked("SecureHandlerWrapScript")
		assert(header and header:IsProtected(), "Header frame must be explicitly protected")
		assert(type(pre) == "string", "Invalid pre-handler body")
		WRAPPED[frame] = WRAPPED[frame] or {}
		WRAPPED[frame][script] = { header = header, pre = pre }
		if script == "OnAttributeChanged" then
			return   -- führt Changed() aus
		end
		local orig = frame._scripts[script]
		local drag = script == "OnDragStart" or script == "OnReceiveDrag"
		frame._scripts[script] = function(self, ...)
			if not InCombatLockdown() or self:IsProtected() then
				local r
				if drag then
					r = Run(pre, self, header, "self,button,kind,value", (...))
				else
					r = Run(pre, self, header, "self")
				end
				if r == false then return end
			end
			if orig then return orig(self, ...) end
		end
	end

	function SecureHandlerExecute(frame, body)
		Blocked("SecureHandlerExecute")
		assert(frame:IsProtected(), "Header frame must be explicitly protected")
		Run(body, frame, frame, "self")
	end

	function SetOverrideBindingClick(owner, prio, key, name, button)
		Blocked("SetOverrideBindingClick")
		BINDINGS[owner] = BINDINGS[owner] or {}
		BINDINGS[owner][key] = name .. ":" .. (button or "LeftButton")
	end
	function SetOverrideBinding(owner, prio, key, action)
		Blocked("SetOverrideBinding")
		BINDINGS[owner] = BINDINGS[owner] or {}
		BINDINGS[owner][key] = action
	end
	function ClearOverrideBindings(owner)
		Blocked("ClearOverrideBindings")
		BINDINGS[owner] = nil
	end

	-- Makrobedingung (Auszug aus SecureCmdOptionParse): "[a,b][c] Wert; Wert", noX verneint
	local function Parse(values)
		for clause in (values .. ";"):gmatch("([^;]*);") do
			clause = strtrim(clause)
			local conds, value = clause:match("^(%[.*%])%s*(.*)$")
			if not conds then
				return clause
			end
			for group in conds:gmatch("%[(.-)%]") do
				local ok = true
				for c in (group .. ","):gmatch("([^,]*),") do
					c = strtrim(c)
					if c ~= "" then
						local neg = c:match("^no(.+)$")
						local on
						if neg then on = not QN_CONDITIONS[neg] else on = QN_CONDITIONS[c] end
						if not on then ok = false end
					end
				end
				if ok then return value end
			end
		end
	end
	local function Resolve(frame, attribute, values)
		local v = Parse(values)
		if attribute == "state-visibility" then
			if v == "show" then
				frame:Show()
				RawSet(frame, "statehidden", nil)
			elseif v == "hide" then
				frame:Hide()
				RawSet(frame, "statehidden", true)
			end
		elseif v then
			if v == "nil" then v = nil else v = tonumber(v) or v end
			if frame:GetAttribute(attribute) ~= v then RawSet(frame, attribute, v) end
		end
	end
	function RegisterAttributeDriver(frame, attribute, values)
		Blocked("RegisterAttributeDriver")
		drivers[frame] = drivers[frame] or {}
		drivers[frame][attribute] = values
		Resolve(frame, attribute, values)
	end
	function UnregisterAttributeDriver(frame, attribute)
		Blocked("UnregisterAttributeDriver")
		if drivers[frame] then drivers[frame][attribute] = nil end
	end
	function RegisterStateDriver(frame, state, values) RegisterAttributeDriver(frame, "state-" .. state, values) end
	function UnregisterStateDriver(frame, state) UnregisterAttributeDriver(frame, "state-" .. state) end
	function UpdateStateDrivers()
		for frame, list in pairs(drivers) do
			for attribute, values in pairs(list) do Resolve(frame, attribute, values) end
		end
	end

	local function Registered(f, button, down)
		for _, r in ipairs(f._clicks or {}) do
			if (r == "AnyDown" and down) or (r == "AnyUp" and not down) or r == button .. (down and "Down" or "Up") then
				return true
			end
		end
		return false
	end
	function PressBinding(key, down)
		for _, list in pairs(BINDINGS) do
			local target = list[key]
			if target then
				local name, button = target:match("^(.-):(.+)$")
				local f = _G[name]
				if f and Registered(f, button, down) then
					if f._template == "SecureActionButtonTemplate" then
						-- SecureActionButton_OnClick ohne isKeyPress/isSecureAction (Addon-Rahmen)
						local useOnKeyDown = f:GetAttribute("useOnKeyDown")
						if useOnKeyDown == nil then useOnKeyDown = GetCVarBool("ActionButtonUseKeyDown") end
						if (down and useOnKeyDown) or (not down and not useOnKeyDown) then
							local delegate = f:GetAttribute("type") == "click" and f:GetAttribute("clickbutton")
							if delegate then delegate:Click(button) end
						end
					elseif f._scripts.OnClick then
						f._scripts.OnClick(f, button, down)
					end
				end
				return true
			end
		end
		return false
	end
end

-- qnTooltip-Bedarf: vollständige Tooltips, nur auf Anforderung eines Szenarios: EnableTooltips() vor
-- LoadAddon aufrufen. Nachgebaut nach dem Forever-Quelltext:
--   Tooltipdaten (TooltipDataHandler.lua InternalProcessInfo): Zeilen anlegen, lineIndex setzen,
--   PostCalls je Typ, Show; Typen und Zeilentypen aus TooltipInfoSharedDocumentation.
--   GameTooltipTemplate (Mainline\GameTooltip.xml): Zeilen $parentTextLeftN/RightN, NineSlice, StatusBar.
-- Einheiten: QN_UNITS[Einheit] = { name, realm, class, className, level, raceName, factionGroup,
--   factionName, reaction, classif, creature, isPlayer, guid, guild = { Name, Rang, Nr., Realm }, surname,
--   dead, health, maxHealth, pvpName, afk, raidIcon, role, title (NSC), target = Einheit }.
--   "<Einheit>target" löst sich über .target auf; QN_GUIDS[GUID] = Einheit (UnitTokenFromGUID).
-- ProcessTooltip(tip, data) verarbeitet Tooltipdaten; tip:SetUnit(Einheit) baut sie aus QN_UNITS.
function EnableTooltips()
	for _, e in ipairs({ "MODIFIER_STATE_CHANGED", "INSPECT_READY", "UPDATE_CHAT_WINDOWS" }) do VALID[e] = true end
	Enum.TooltipDataType = { Item = 0, Spell = 1, Unit = 2, Corpse = 3, Object = 4, Currency = 5, UnitAura = 7, Mount = 10, Quest = 23, Macro = 25 }
	Enum.TooltipDataLineType = { None = 0, Blank = 1, UnitName = 2, SpellName = 13, ItemName = 22, UnitLevel = 47, UnitType = 48, UnitDead = 49 }
	POSTCALLS = {}
	TooltipDataProcessor = { AllTypes = "ALL", AddTooltipPreCall = nop, AddLinePreCall = nop, AddLinePostCall = nop }
	function TooltipDataProcessor.AddTooltipPostCall(t, fn)
		POSTCALLS[t] = POSTCALLS[t] or {}
		table.insert(POSTCALLS[t], fn)
	end

	-- Schriften
	local function Font(name, file, size, flag)
		local f = NewFrame("Font", name)
		f._fontInfo = { file, size, flag }
		function f:GetFont() return unpack(self._fontInfo) end
		function f:SetFont(a, b, c) self._fontInfo = { a, b, c } end
		function f:SetShadowOffset() end
		function f:SetShadowColor() end
		return f
	end
	Font("GameTooltipHeaderText", "Fonts\\FRIZQT__.TTF", 14, "")
	Font("GameTooltipText", "Fonts\\FRIZQT__.TTF", 12, "")
	Font("Tooltip_Small", "Fonts\\FRIZQT__.TTF", 10, "")
	function NumberFontNormal:GetFont() return "Fonts\\ARIALN.TTF", 12, "" end

	-- Tooltip mit Zeilen
	local function Tooltip(name)
		local tip = NewFrame("GameTooltip", name, UIParent)
		tip._shown = false
		tip._lines = 0
		tip.NineSlice = NewFrame("Frame", nil, tip)
		local function Line(side, n)
			local key = name .. "Text" .. side .. n
			return _G[key] or NewFrame("FontString", key, tip)
		end
		function tip:NumLines() return self._lines end
		function tip:AddLine(text, r, g, b)
			self._lines = self._lines + 1
			local left, right = Line("Left", self._lines), Line("Right", self._lines)
			left._text, right._text, left._textColor = text, nil, r and { r, g, b, 1 } or nil
		end
		function tip:AddDoubleLine(l, r)
			self:AddLine(l)
			Line("Right", self._lines)._text = r
		end
		function tip:ClearLines()
			for i = 1, self._lines do Line("Left", i)._text, Line("Right", i)._text = nil, nil end
			self._lines = 0
			self._data = nil
			if self._scripts.OnTooltipCleared then self._scripts.OnTooltipCleared(self) end
		end
		function tip:SetOwner(owner, anchor, x, y)
			self._owner, self._anchor = owner, { anchor, x, y }
			self:ClearLines()
		end
		function tip:GetOwner() return self._owner end
		function tip:SetText(t) self:ClearLines() self:AddLine(t) end
		function tip:HasScript() return true end
		function tip:SetScale(s) self._scale = s end
		function tip:SetHyperlink(link) self._link = link end
		function tip:SetUnit(unit) ProcessTooltip(self, UnitTooltipData(unit)) end
		function tip:GetUnit()
			local d = self._data
			if d and d.type == Enum.TooltipDataType.Unit then
				local unit = UnitTokenFromGUID(d.guid)
				return unit and UnitName(unit), unit, d.guid
			end
		end
		-- linke Texte aller Zeilen (leere als "")
		function tip:Texts()
			local t = {}
			for i = 1, self._lines do t[i] = Line("Left", i)._text or "" end
			return t
		end
		return tip
	end
	GameTooltip = Tooltip("GameTooltip")
	for _, n in ipairs({ "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2" }) do
		Tooltip(n)
	end
	-- Vergleichs-Tooltips (GameTooltip.xml: shoppingTooltips)
	GameTooltip.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 }
	ItemRefTooltip.shoppingTooltips = { ItemRefShoppingTooltip1, ItemRefShoppingTooltip2 }
	function GameTooltip:SetBagItem(bag, slot) self._bagItem = { bag, slot } self:Show() end
	-- Lebensbalken (GameTooltipUnitHealthBarMixin: Wert 0–1)
	local bar = NewFrame("StatusBar", "GameTooltipStatusBar", GameTooltip)
	bar._shown = false
	bar._value = 0
	function bar:SetValue(v) self._value = v if self._scripts.OnValueChanged then self._scripts.OnValueChanged(self, v) end end
	function bar:GetValue() return self._value end
	function bar:SetStatusBarColor(r, g, b) self._barColor = { r, g, b } end
	function bar:SetStatusBarTexture(t) self._barTexture = t end
	GameTooltip.StatusBar = bar

	function ProcessTooltip(tip, data)
		tip:ClearLines()
		for _, line in ipairs(data.lines or {}) do
			tip:AddLine(line.leftText)
			line.lineIndex = tip:NumLines()
		end
		tip._data = data
		for _, fn in ipairs(POSTCALLS[data.type] or {}) do fn(tip, data) end
		tip:Show()
		SharedTooltip_SetBackdropStyle(tip)
	end
	function SharedTooltip_SetBackdropStyle(tip) tip.NineSlice:Show() end
	function GameTooltip_SetDefaultAnchor(tip, parent)
		tip:SetOwner(parent, "ANCHOR_NONE")
		tip:ClearAllPoints()
		tip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -13, 64)
	end
	function GameTooltip_AddInstructionLine(tip, text) tip:AddLine(text) end
	function GameTooltip_AddBlankLineToTooltip(tip) tip:AddLine(" ") end

	-- Einheiten
	QN_UNITS = QN_UNITS or {}
	QN_GUIDS = QN_GUIDS or {}
	local function Resolve(u)
		if type(u) ~= "string" then return nil end
		if QN_UNITS[u] then return u end
		local base = u:match("^(.+)target$")
		if base then
			local b = Resolve(base)
			return b and QN_UNITS[b] and Resolve(QN_UNITS[b].target)
		end
	end
	local function U(u) local r = Resolve(u) return r and QN_UNITS[r] end
	UNIT_RESOLVE = Resolve
	function UnitTokenFromGUID(guid) return QN_GUIDS[guid] end
	function UnitExists(u) return U(u) ~= nil end
	function UnitIsUnit(a, b) local ra, rb = Resolve(a), Resolve(b) return ra ~= nil and ra == rb end
	-- Forever (camelot): Vor- und Nachname (NameUtil.GetUnitFirstName); Realm über GetPlayerInfoByGUID
	function UnitName(u) local d = U(u) if d then return d.name, d.surname end end
	function GetPlayerInfoByGUID(guid) local d = U(QN_GUIDS[guid]) if d then return d.className, d.class, d.raceName, nil, d.sex, d.name, d.realm or "" end end
	function UnitPVPName(u) local d = U(u) return d and (d.pvpName or d.name) end
	function UnitGUID(u) local d = U(u) return d and d.guid end
	function UnitIsPlayer(u) local d = U(u) return d and d.isPlayer or false end
	function UnitLevel(u) local d = U(u) return d and d.level or 0 end
	function UnitEffectiveLevel(u) return UnitLevel(u) end
	function UnitRace(u) local d = U(u) return d and d.raceName end
	function UnitClass(u) local d = U(u) if d then return d.className, d.class end end
	function UnitFactionGroup(u) local d = U(u) if d then return d.factionGroup, d.factionName end end
	function UnitReaction(u) local d = U(u) return d and d.reaction end
	function UnitClassification(u) local d = U(u) return d and d.classif or "normal" end
	function UnitCreatureType(u) local d = U(u) return d and d.creature end
	function UnitSex(u) local d = U(u) return d and d.sex or 1 end
	function GetGuildInfo(u) local d = U(u) if d and d.guild then return unpack(d.guild) end end
	function UnitGroupRolesAssigned(u) local d = U(u) return d and d.role or "NONE" end
	function GetRaidTargetIndex(u) local d = U(u) return d and d.raidIcon end
	function UnitIsPVPFreeForAll() return false end
	function UnitIsQuestBoss(u) local d = U(u) return d and d.questBoss or false end
	function UnitIsAFK(u) local d = U(u) return d and d.afk or false end
	function UnitIsDND() return false end
	function UnitIsConnected() return true end
	function UnitIsDeadOrGhost(u) local d = U(u) return d and d.dead or false end
	function UnitHealth(u) local d = U(u) return d and d.health or 0 end
	function UnitHealthMax(u) local d = U(u) return d and d.maxHealth or 1 end
	function UnitHealthPercent(u) local d = U(u) if d then if issecretvalue(d.health) then return d.health end return d.health / d.maxHealth * 100 end end
	function UnitSelectionColor(u) local d = U(u) if d and d.selection then return unpack(d.selection) end return 1, 1, 0 end
	function UnitIsOtherPlayersPet() return false end
	function UnitInRaid() return nil end
	function UnitIsVisible(u) return U(u) ~= nil end
	function GetUnitSpeed(u) local d = U(u) return d and d.speed or 0 end
	function GetNumGroupMembers() return QN_GROUP and #QN_GROUP or 0 end
	function IsInRaid() return QN_GROUP_RAID or false end
	function IsInGroup() return QN_GROUP ~= nil end
	function GetRaidRosterInfo() return nil end
	QN_UNITS.player = QN_UNITS.player or { name = "Tester", class = "WARRIOR", className = "Krieger", level = 60, isPlayer = true, guid = "Player-1", factionGroup = "Alliance", factionName = FACTION_ALLIANCE, raceName = "Mensch" }
	QN_GUIDS["Player-1"] = "player"
	C_FriendList = { IsFriend = function(guid) return QN_FRIENDS and QN_FRIENDS[guid] or false end }
	-- Betrachten
	QN_INSPECT = {}   -- Protokoll der NotifyInspect-Aufrufe
	function CanInspect(u) return U(u) ~= nil end
	function NotifyInspect(u) QN_INSPECT[#QN_INSPECT + 1] = u end
	function ClearInspectPlayer() QN_INSPECT.cleared = true end
	C_PaperDollInfo.GetInspectItemLevel = function(u) local d = U(u) return d and d.itemLevel end
	function GetAverageItemLevel() return 70.4, 65.6 end

	-- Blizzard-Tabellen und -Funktionen
	ICON_LIST = {}
	for i = 1, 8 do ICON_LIST[i] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i .. ":" end
	CLASS_ICON_TCOORDS = setmetatable({}, { __index = function() return { 0, 0.25, 0, 0.25 } end })
	FACTION_BAR_COLORS = {}
	for i = 1, 8 do FACTION_BAR_COLORS[i] = { r = i / 8, g = 0.5, b = 0 } end
	function GetCreatureDifficultyColor(level) return { r = 1, g = level > 60 and 0 or 1, b = 0 } end
	function GetQuestDifficultyColor(level) return { r = 0.25, g = 0.75, b = 0.25 } end
	CurveConstants = { ScaleTo100 = {} }
	BASE_MOVEMENT_SPEED = 7
	Constants = { ChatFrameConstants = { MaxChatWindows = 10 } }
	for i = 1, 10 do NewFrame("ScrollingMessageFrame", "ChatFrame" .. i) end
	function HealthBar_OnValueChanged(self, value, smooth) self._smooth = smooth and value end
	function GetMouseFoci() return { QN_FOCUS or WorldFrame } end
	C_Item = C_Item or {}
	C_Item.GetItemQualityByID = function(id) return QN_ITEMS and QN_ITEMS[id] and QN_ITEMS[id].quality end
	C_Item.GetItemQualityColor = function(q) return 0.64, 0.21, 0.93, "ffa335ee" end
	C_Item.GetItemIconByID = function(id) return QN_ITEMS and QN_ITEMS[id] and QN_ITEMS[id].icon end
	C_Item.GetItemInfo = function(id) local it = QN_ITEMS and QN_ITEMS[id] if it then return it.name, nil, it.quality, nil, nil, nil, nil, it.stack end end
	C_Spell.GetSpellTexture = function(id) return 136000 + id end
	C_QuestLog = { GetQuestDifficultyLevel = function(id) return 12 end }
	function ColorPickerFrame:SetupColorPickerAndShow(info) self._info = info end
	function ColorPickerFrame:GetColorRGB() return unpack(self._rgb or { 1, 1, 1 }) end
	-- wie ColorPickerFrameMixin: GetPreviousValues liefert Einzelwerte, OnCancel übergibt die Tabelle
	function ColorPickerFrame:GetPreviousValues() local i = self._info return i.r, i.g, i.b, i.a end
	function ColorPickerFrame:Cancel() local i = self._info if i.cancelFunc then i.cancelFunc({ r = i.r, g = i.g, b = i.b, a = i.a }) end end
end

-- Tooltipdaten einer Einheit wie in Forever: Name, (Gilde), (NSC-Titel), Stufe, (Fraktion, PvP)
function UnitTooltipData(unit)
	local d = QN_UNITS[UNIT_RESOLVE(unit)]
	local lines = { { type = Enum.TooltipDataLineType.UnitName, leftText = d.pvpName or d.name } }
	if d.guild then lines[#lines + 1] = { type = 0, leftText = d.guild[1] } end
	if d.title then lines[#lines + 1] = { type = 0, leftText = "<" .. d.title .. ">" } end
	-- Forever: Stufenzeile ohne Zeilentyp (levelType = true: mit Typ UnitLevel), Klasse in eigener Zeile
	local levelText = TOOLTIP_UNIT_LEVEL:format(tostring(d.level)) .. (d.isPlayer and (" " .. tostring(d.raceName) .. " (" .. PLAYER .. ")") or "")
	lines[#lines + 1] = { type = d.levelType and Enum.TooltipDataLineType.UnitLevel or 0, leftText = levelText }
	if d.isPlayer then lines[#lines + 1] = { type = 0, leftText = d.className } end
	if d.isPlayer then lines[#lines + 1] = { type = 0, leftText = d.factionName } end
	if d.pvp then lines[#lines + 1] = { type = 0, leftText = PVP } end
	for _, extra in ipairs(d.extra or {}) do lines[#lines + 1] = { type = 0, leftText = extra } end
	return { type = Enum.TooltipDataType.Unit, guid = d.guid, lines = lines, healthGUID = d.guid }
end
