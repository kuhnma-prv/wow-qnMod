-- qnCore: builder for options pages in Blizzard's settings window (Settings API).
--
-- The settings are proxy settings: they always read from and write to
-- the table of the active profile. After a profile switch, Refresh() re-reads all
-- controls without triggering the callbacks - applying is done by the
-- profile's onSwitch.
--
--   local B = qnCore.Settings.New({ store = ns.store, prefix = "QNMETER_", apply = Apply })
--   B:Checkbox(category, "shown", "Show window")
--
-- A choice among several options always goes through B:Dropdown: a button with
-- a drop-down list that shows the active choice.

local _, ns = ...
local lib = qnCore

local S = {}
lib.Settings = S

local Builder = {}
Builder.__index = Builder

-- opts.store     profile object (qnCore.Profiles.Register)
-- opts.prefix    unique prefix for the variable names, e.g. "QNMETER_"
-- opts.apply     default callback after a change (optional)
-- opts.source    function() -> table; default: store.db (optional)
-- opts.defaults  defaults for this table; default: store.defaults (optional)
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

-- Main page of an addon in the settings window. Without canvas a vertical list:
-- build(category, layout); with canvas (frame) a freely designed page: build(category, canvas).
-- Subpages are created by build. Sets addonNS.category and addonNS.OpenOptions; registration in the
-- settings window (RegisterAddOnCategory) follows after build.
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

-- Creates the setting for key. callback(setting, value) replaces opts.apply.
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

-- Attach the callback (not during Refresh) and remember the setting.
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

-- Re-read the controls (after a profile switch or swapping the source table).
function Builder:Refresh()
	self.quiet = true
	local ok, err = pcall(function()
		for _, setting in ipairs(self.list) do
			setting:NotifyUpdate()
		end
	end)
	self.quiet = false   -- also after an error, otherwise all callbacks would stay silent
	if not ok then
		geterrorhandler()(err)
	end
end

-- Sets a value so that the settings window shows it too. Without a control
-- it is written directly and opts.apply is called like a callback: apply(nil, value).
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

-- Sets key via the first builder in the list that has a control for it; true if one
-- had it (otherwise everything stays unchanged).
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
-- Controls
-- Checkbox, Slider and Dropdown return the initializer (for S.Depends); the setting
-- is in B.settings[key].
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

-- Dropdown for an existing setting (also one that appears on several pages).
-- entries: { { value, text[, tooltip] }, ... } or a function that returns this list
-- (re-read every time the list opens).
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

-- entries as for S.Dropdown
function Builder:Dropdown(cat, key, name, entries, tooltip, varType, callback)
	local setting = self:Register(cat, key, name, varType, callback)
	return S.Dropdown(cat, setting, entries, tooltip)
end

-- Color as a list { r, g, b, a } (values 0-1). Blizzard's color swatch has no opacity;
-- with alphaName there is a separate slider for it below (setting key .. "_alpha").
-- Returns the initializers of the color swatch and of the slider (nil without alphaName).
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

-- Control only usable if predicate() is true (indented under parent).
function S.Depends(initializer, parent, predicate)
	initializer:SetParentInitializer(parent, predicate)
	return initializer
end
