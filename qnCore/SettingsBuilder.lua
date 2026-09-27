-- qnCore: Baukasten für Optionsseiten im Blizzard-Einstellungsfenster (Settings-API).
--
-- Die Einstellungen sind Proxy-Einstellungen: sie lesen und schreiben immer in
-- die Tabelle des aktiven Profils. Nach einem Profilwechsel liest Refresh() alle
-- Steuerelemente neu ein, ohne die Rückrufe auszulösen – das Anwenden übernimmt
-- onSwitch des Profils.
--
--   local B = qnCore.Settings.New({ store = ns.store, prefix = "QNMETER_", apply = Apply })
--   B:Checkbox(category, "shown", "Fenster anzeigen")
--
-- Auswahl aus mehreren Möglichkeiten immer über B:Dropdown: ein Knopf mit
-- Aufklappliste, der die aktive Auswahl anzeigt.

local _, ns = ...
local lib = qnCore

local S = {}
lib.Settings = S

local Builder = {}
Builder.__index = Builder

-- opts.store     Profilobjekt (qnCore.Profiles.Register)
-- opts.prefix    eindeutiges Präfix für die Variablennamen, z. B. "QNMETER_"
-- opts.apply     Standard-Rückruf nach einer Änderung (optional)
-- opts.source    function() -> Tabelle; Standard: store.db (optional)
-- opts.defaults  Vorgaben für diese Tabelle; Standard: store.defaults (optional)
function S.New(opts)
	local b = setmetatable({
		store = opts.store,
		prefix = opts.prefix,
		apply = opts.apply,
		source = opts.source,
		defaults = opts.defaults,
		settings = {},
		list = {},
	}, Builder)
	if opts.store then
		table.insert(opts.store.builders, b)
	end
	return b
end

-- Hauptseite eines Addons im Einstellungsfenster. Ohne canvas eine senkrechte Liste:
-- build(category, layout); mit canvas (Rahmen) eine frei gestaltete Seite: build(category, canvas).
-- Unterseiten legt build an. Setzt addonNS.category und addonNS.OpenOptions; die Anmeldung im
-- Einstellungsfenster (RegisterAddOnCategory) folgt nach build.
function S.NewCategory(addonNS, title, build, canvas)
	local category, layout
	if canvas then
		category = Settings.RegisterCanvasLayoutCategory(canvas, title)
	else
		category, layout = Settings.RegisterVerticalLayoutCategory(title)
	end
	addonNS.category = category
	function addonNS.OpenOptions()
		lib.OpenCategory(category)
	end
	build(category, layout or canvas)
	Settings.RegisterAddOnCategory(category)
	return category
end

function Builder:Table()
	if self.source then
		return self.source()
	end
	return self.store.db
end

function Builder:Default(key)
	local defaults = self.defaults or (self.store and self.store.defaults) or {}
	return defaults[key]
end

local function VarTypeOf(v)
	local t = type(v)
	if t == "boolean" then
		return Settings.VarType.Boolean
	elseif t == "number" then
		return Settings.VarType.Number
	end
	return Settings.VarType.String
end

-- Legt die Einstellung für key an. callback(setting, value) ersetzt opts.apply.
function Builder:Register(cat, key, name, varType, callback)
	local default = self:Default(key)
	varType = varType or VarTypeOf(default)
	local b = self
	local setting = Settings.RegisterProxySetting(cat, self.prefix .. key:upper(), varType, name, default,
		function()
			local v = b:Table()[key]
			if v == nil then
				return default
			end
			return v
		end,
		function(value)
			b:Table()[key] = value
		end)
	self:Wire(key, setting, callback)
	return setting
end

-- Rückruf anhängen (nicht während Refresh) und die Einstellung merken.
function Builder:Wire(key, setting, callback)
	local b = self
	callback = callback or self.apply
	if callback then
		setting:SetValueChangedCallback(function(s, value)
			if not b.quiet then
				callback(s, value)
			end
		end)
	end
	self.settings[key] = setting
	self.list[#self.list + 1] = setting
end

-- Steuerelemente neu einlesen (nach Profilwechsel oder Tausch der Quelltabelle).
function Builder:Refresh()
	self.quiet = true
	local ok, err = pcall(function()
		for _, setting in ipairs(self.list) do
			setting:NotifyUpdate()
		end
	end)
	self.quiet = false   -- auch nach einem Fehler, sonst blieben alle Rückrufe stumm
	if not ok then
		geterrorhandler()(err)
	end
end

-- Setzt einen Wert so, dass auch das Einstellungsfenster ihn anzeigt. Ohne Steuerelement
-- wird direkt geschrieben und opts.apply wie ein Rückruf aufgerufen: apply(nil, value).
function Builder:Set(key, value)
	local setting = self.settings[key]
	if setting then
		setting:SetValue(value)
	else
		self:Table()[key] = value
		if self.apply then
			self.apply(nil, value)
		end
	end
end

-- Setzt key über den ersten Baukasten der Liste, der dafür ein Steuerelement hat; true, wenn einer
-- es hatte (sonst bleibt alles unverändert).
function S.SetIn(builders, key, value)
	for _, b in ipairs(builders) do
		if b.settings[key] then
			b:Set(key, value)
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- Steuerelemente
-- Checkbox, Slider und Dropdown liefern den Initializer (für S.Depends); die Einstellung
-- steht in B.settings[key].
---------------------------------------------------------------------------

function Builder:Checkbox(cat, key, name, tooltip, callback)
	local setting = self:Register(cat, key, name, Settings.VarType.Boolean, callback)
	return Settings.CreateCheckbox(cat, setting, tooltip)
end

local function IntFormatter(v)
	return ("%d"):format(v)
end
S.IntFormatter = IntFormatter

function S.PercentFormatter(v)
	return ("%d %%"):format(v)
end

function S.FractionFormatter(v)
	return ("%d %%"):format(v * 100 + 0.5)
end

function S.DecimalFormatter(v)
	return ("%.2f"):format(v)
end

function S.SecondsFormatter(v)
	return ("%.1f s"):format(v)
end

function S.FontSizeFormatter(v)
	return v == 0 and DEFAULT or ("%d"):format(v)
end

function Builder:Slider(cat, key, name, minV, maxV, step, formatter, tooltip, callback)
	local setting = self:Register(cat, key, name, Settings.VarType.Number, callback)
	local options = Settings.CreateSliderOptions(minV, maxV, step)
	options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter or IntFormatter)
	return Settings.CreateSlider(cat, setting, options, tooltip)
end

-- Dropdown zu einer vorhandenen Einstellung (auch eine, die auf mehreren Seiten erscheint).
-- entries: { { Wert, Text[, Tooltip] }, … } oder eine Funktion, die diese Liste liefert
-- (wird bei jedem Aufklappen neu gelesen).
function S.Dropdown(cat, setting, entries, tooltip)
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		for _, entry in ipairs(type(entries) == "function" and entries() or entries) do
			container:Add(entry[1], entry[2], entry[3])
		end
		return container:GetData()
	end
	return Settings.CreateDropdown(cat, setting, GetOptions, tooltip)
end

-- entries wie bei S.Dropdown
function Builder:Dropdown(cat, key, name, entries, tooltip, varType, callback)
	local setting = self:Register(cat, key, name, varType, callback)
	return S.Dropdown(cat, setting, entries, tooltip)
end

-- Farbe als Liste { r, g, b, a } (Werte 0–1). Blizzards Farbfeld kennt keine Deckkraft;
-- mit alphaName gibt es dafür einen eigenen Regler darunter (Einstellung key .. "_alpha").
-- Liefert die Initializer des Farbfelds und des Reglers (ohne alphaName nil).
function Builder:Color(cat, key, name, tooltip, callback, alphaName)
	local default = self:Default(key)
	local b = self
	local function Get()
		local t = b:Table()[key]
		if type(t) ~= "table" then
			t = default
		end
		return t
	end
	local function Hex(t)
		return CreateColor(t[1], t[2], t[3]):GenerateHexColor()
	end
	local setting = Settings.RegisterProxySetting(cat, self.prefix .. key:upper(), Settings.VarType.String, name, Hex(default),
		function()
			return Hex(Get())
		end,
		function(hex)
			local c = CreateColorFromHexString(hex)
			local t = Get()
			b:Table()[key] = { c.r, c.g, c.b, t[4] or 1 }
		end)
	self:Wire(key, setting, callback)
	local init = Settings.CreateColorSwatch(cat, setting, tooltip)
	if not alphaName then
		return init
	end
	local alpha = Settings.RegisterProxySetting(cat, self.prefix .. key:upper() .. "_ALPHA", Settings.VarType.Number, alphaName, default[4] or 1,
		function()
			return Get()[4] or 1
		end,
		function(value)
			local t = Get()
			b:Table()[key] = { t[1], t[2], t[3], value }
		end)
	self:Wire(key .. "_alpha", alpha, callback)
	local options = Settings.CreateSliderOptions(0, 1, 0.05)
	options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, S.FractionFormatter)
	local alphaInit = Settings.CreateSlider(cat, alpha, options)
	return init, alphaInit
end

function S.Header(layout, text)
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
end

function S.Button(layout, name, buttonText, onClick, tooltip)
	local init = CreateSettingsButtonInitializer(name, buttonText, onClick, tooltip, true)
	layout:AddInitializer(init)
	return init
end

-- Steuerelement nur bedienbar, wenn predicate() wahr ist (eingerückt unter parent).
function S.Depends(initializer, parent, predicate)
	initializer:SetParentInitializer(parent, predicate)
	return initializer
end
