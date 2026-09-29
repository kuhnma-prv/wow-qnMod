-- qnCore: core and library of the qn addons (qnThreatMeter, qnNumKeyPad, qnViewPort, qnInventory, qnBuffMod, qnUnitFrames).
-- Library: shared helper functions, globally reachable as qnCore.
--
-- The qn addons (qnCore itself included) call
--   qnCore.NewAddon(ns, ADDON)
-- when loading. This sets ns.version, ns.L, ns.Print, ns.IsSecret, ns.Plain, ns.AnySecret, ns.events and
-- ns.OnLoad.
-- The other qnCore files reach the library through the global qnCore.

local ADDON, ns = ...

local lib = {}
_G.qnCore = lib

-- Names of the registered addons per namespace (only within qnCore, e.g. Profiles.Register)
ns.addonNames = setmetatable({}, { __mode = "k" })

local function Meta(addon, field)
	return C_AddOns.GetAddOnMetadata(addon, field) or "?"
end

lib.version = Meta(ADDON, "Version")

---------------------------------------------------------------------------
-- Secret values
-- On clients with the Midnight engine, API return values can be "secret". Addon
-- code may neither do arithmetic with such values, nor compare them, nor
-- test them for truth. Only passing them to certain widgets is allowed
-- (SetText, SetFormattedText, StatusBar:SetValue, AbbreviateLargeNumbers).
---------------------------------------------------------------------------

lib.IsSecret = issecretvalue
local IsSecret = lib.IsSecret

-- Returns v, or fallback if v is secret.
function lib.Plain(v, fallback)
	if IsSecret(v) then
		return fallback
	end
	return v
end

-- true if one of the values is secret (nil values may appear in between)
function lib.AnySecret(...)
	for i = 1, select("#", ...) do
		if IsSecret((select(i, ...))) then
			return true
		end
	end
	return false
end

-- true if one of the values of table t is secret
function lib.AnySecretIn(t)
	for _, v in pairs(t) do
		if IsSecret(v) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- Class colors
---------------------------------------------------------------------------

-- Class color (RAID_CLASS_COLORS, fields r, g, b) for a class name like "WARRIOR";
-- nil if the class is missing, unknown or secret.
function lib.ClassColor(classFile)
	if IsSecret(classFile) or classFile == nil then
		return nil
	end
	return RAID_CLASS_COLORS[classFile]
end

-- Name in class color; without class color in fallback (color with r, g, b), without fallback
-- uncolored. A secret name is returned unchanged (only suitable for SetText).
function lib.ClassColoredName(name, classFile, fallback)
	if IsSecret(name) then
		return name
	end
	local c = lib.ClassColor(classFile) or fallback
	if not c then
		return name
	end
	local function Byte(v)
		return math.floor(v * 255 + 0.5)
	end
	return ("|cff%02x%02x%02x%s|r"):format(Byte(c.r), Byte(c.g), Byte(c.b), name)
end

---------------------------------------------------------------------------
-- Localization
-- The key is the English text. Non-German clients show it unchanged, German
-- clients the German translation from the addon's Locale.lua
-- (in the TOC before all files that use texts):
--   local ADDON, ns = ...
--   local L = qnCore.NewLocale(ns, ADDON)
--   if not qnCore.GERMAN then return end
--   L["English text"] = "Deutscher Text"
-- If a translation is missing, the English text appears; /qncore locale lists
-- such keys. If Blizzard has a matching text (GlobalStrings like CANCEL,
-- DELETE), it is used instead of an own key.
---------------------------------------------------------------------------

lib.GERMAN = GetLocale() == "deDE"
lib.missing = {}   -- [Addon] = { [key] = true }: shown without translation

function lib.NewLocale(addonNS, name)
	if addonNS.L then
		return addonNS.L
	end
	local L = setmetatable({}, { __index = function(_, key)
		if lib.GERMAN and key ~= nil then
			local list = lib.missing[name or "?"] or {}
			lib.missing[name or "?"] = list
			list[key] = true
		end
		return key
	end })
	addonNS.L = L
	return L
end

---------------------------------------------------------------------------
-- Tables
---------------------------------------------------------------------------

-- Fills in missing keys from the defaults. Lists ({ 1, 2, 3 }) are taken over as
-- a whole, tables with keys ({ r = 1, ... }) are filled in recursively.
-- If the default is a table but the saved value is not (corrupted or old
-- format), the default is copied.
function lib.MergeDefaults(db, defaults)
	for k, v in pairs(defaults) do
		if db[k] == nil or (type(v) == "table" and type(db[k]) ~= "table") then
			db[k] = type(v) == "table" and CopyTable(v) or v
		elseif type(v) == "table" and v[1] == nil then
			lib.MergeDefaults(db[k], v)
		end
	end
	return db
end

-- Deletes obsolete keys from t; "dual.uiOnMain" stands for t.dual.uiOnMain.
function lib.RemoveKeys(t, keys)
	for _, path in ipairs(keys) do
		local parts = {}
		for part in path:gmatch("[^.]+") do
			parts[#parts + 1] = part
		end
		local parent = t
		for i = 1, #parts - 1 do
			parent = type(parent) == "table" and parent[parts[i]] or nil
		end
		if type(parent) == "table" then
			parent[parts[#parts]] = nil
		end
	end
	return t
end

---------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------

-- Returns a print function with prefix. With further arguments, fmt is filled in
-- via string.format, otherwise printed unchanged. Multi-line texts
-- (a key with \n) appear as separate chat lines, each with prefix.
function lib.NewPrinter(name)
	local prefix = "|cff33ff99" .. name .. "|r: "
	return function(fmt, ...)
		local msg = select("#", ...) > 0 and tostring(fmt):format(...) or tostring(fmt)
		if not msg:find("\n", 1, true) then
			DEFAULT_CHAT_FRAME:AddMessage(prefix .. msg)
			return
		end
		for line in msg:gmatch("[^\n]+") do
			DEFAULT_CHAT_FRAME:AddMessage(prefix .. line)
		end
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

-- Small dispatcher: hub.Register(event, fn) calls fn(event, ...); several
-- functions per event possible.
function lib.NewEventHub()
	local frame = CreateFrame("Frame")
	local handlers = {}
	local hub = { frame = frame }
	function hub.Register(event, fn)
		if not handlers[event] then
			frame:RegisterEvent(event)
			handlers[event] = {}
		end
		table.insert(handlers[event], fn)
	end
	frame:SetScript("OnEvent", function(_, event, ...)
		local list = handlers[event]
		if list then
			for i = 1, #list do
				list[i](event, ...)
			end
		end
	end)
	return hub
end

---------------------------------------------------------------------------
-- Position of frames relative to UIParent
-- All calculations use the effective scale; UIParent may be moved or shrunk
-- (qnViewPort: UI on the main monitor).
---------------------------------------------------------------------------

-- Share of an anchor point in width and height: TOPLEFT = 0, 1; CENTER = 0.5, 0.5; BOTTOMRIGHT = 1, 0
function lib.AnchorFactors(point)
	local fx = point:find("LEFT") and 0 or point:find("RIGHT") and 1 or 0.5
	local fy = point:find("TOP") and 1 or point:find("BOTTOM") and 0 or 0.5
	return fx, fy
end

-- Position of point of frame in units at effective scale 1 (x, y) or nil
local function PointAbs(frame, point)
	local l, b = frame:GetLeft(), frame:GetBottom()
	if not (l and b) then
		return nil
	end
	local fx, fy = lib.AnchorFactors(point)
	local s = frame:GetEffectiveScale()
	return (l + fx * frame:GetWidth()) * s, (b + fy * frame:GetHeight()) * s
end

-- Offsets for frame:SetPoint(point, UIParent, relPoint, x, y) that keep frame where it is.
-- inParentUnits: in UIParent units (independent of the frame's scale; divide by
-- frame:GetScale() when setting), otherwise in frame units. nil as long as frame has no position.
function lib.PointOffset(frame, point, relPoint, inParentUnits)
	local px, py = PointAbs(frame, point)
	local rx, ry = PointAbs(UIParent, relPoint)
	if not (px and rx) then
		return nil
	end
	local s = inParentUnits and UIParent:GetEffectiveScale() or frame:GetEffectiveScale()
	return (px - rx) / s, (py - ry) / s
end

-- Corner of UIParent closest to point of frame (default CENTER), e.g. "TOPRIGHT".
function lib.NearestCorner(frame, point)
	local px, py = PointAbs(frame, point or "CENTER")
	local cx, cy = PointAbs(UIParent, "CENTER")
	if not (px and cx) then
		return "BOTTOMLEFT"
	end
	return (py > cy and "TOP" or "BOTTOM") .. (px > cx and "RIGHT" or "LEFT")
end

-- Anchor points for selection (dropdown): { { "TOPLEFT", "Top left" }, ... }, all nine or only the
-- four corners. Texts from qnCore's locale (read only at runtime).
function lib.PointEntries(cornersOnly)
	local L = ns.L
	if cornersOnly then
		return {
			{ "TOPLEFT", L["Top left"] }, { "TOPRIGHT", L["Top right"] },
			{ "BOTTOMLEFT", L["Bottom left"] }, { "BOTTOMRIGHT", L["Bottom right"] },
		}
	end
	return {
		{ "TOPLEFT", L["Top left"] }, { "TOP", L["Top center"] }, { "TOPRIGHT", L["Top right"] },
		{ "LEFT", L["Left center"] }, { "CENTER", L["Center"] }, { "RIGHT", L["Right center"] },
		{ "BOTTOMLEFT", L["Bottom left"] }, { "BOTTOM", L["Bottom center"] }, { "BOTTOMRIGHT", L["Bottom right"] },
	}
end

---------------------------------------------------------------------------
-- Combat and timing
---------------------------------------------------------------------------

local deferred, deferredSet = {}, {}   -- to be called after combat (order, set)

-- In combat: queue fn for after combat (each function at most once) and return
-- true. Outside combat false - then the caller acts immediately:
--   if qnCore.DeferInCombat(Apply) then return end
function lib.DeferInCombat(fn)
	if not InCombatLockdown() then
		return false
	end
	if not deferredSet[fn] then
		deferredSet[fn] = true
		deferred[#deferred + 1] = fn
	end
	return true
end

-- one shared handler for all queued functions; an error does not stop the others
lib.NewEventHub().Register("PLAYER_REGEN_ENABLED", function()
	local list = deferred
	deferred, deferredSet = {}, {}
	for _, fn in ipairs(list) do
		local ok, err = pcall(fn)
		if not ok then
			geterrorhandler()(err)
		end
	end
end)

-- Returns a function that calls fn after delay seconds (default 0 = in the next frame).
-- Further calls until then are merged; arguments are not passed on.
function lib.Debounce(fn, delay)
	local queued = false
	return function()
		if queued then
			return
		end
		queued = true
		C_Timer.After(delay or 0, function()
			queued = false
			fn()
		end)
	end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

-- Registers slash commands: id = key in SlashCmdList (e.g. "QNTHREATMETER"), commands = { "/qnm", ... }.
-- handler(cmd, rest, msg): cmd = first word in lower case ("" without input), rest = everything
-- after it as typed, msg = the whole input; all without surrounding whitespace.
function lib.RegisterSlash(id, commands, handler)
	for i, command in ipairs(commands) do
		_G["SLASH_" .. id .. i] = command
	end
	SlashCmdList[id] = function(msg)
		msg = strtrim(msg or "")
		local cmd, rest = msg:match("^(%S*)%s*(.-)$")
		handler(cmd:lower(), rest, msg)
	end
end

---------------------------------------------------------------------------
-- Settings window
---------------------------------------------------------------------------

function lib.OpenCategory(category)
	Settings.OpenToCategory(category:GetID())
end

---------------------------------------------------------------------------
-- Registration of a qn addon
---------------------------------------------------------------------------

function lib.NewAddon(addonNS, name)
	ns.addonNames[addonNS] = name
	addonNS.version = Meta(name, "Version")
	addonNS.IsSecret = IsSecret
	addonNS.Plain = lib.Plain
	addonNS.AnySecret = lib.AnySecret
	addonNS.Print = lib.NewPrinter(name)
	-- one event dispatcher for all files of the addon
	addonNS.events = lib.NewEventHub()
	-- fn() once on this addon's ADDON_LOADED (saved variables are loaded by then)
	function addonNS.OnLoad(fn)
		local done = false
		addonNS.events.Register("ADDON_LOADED", function(_, loaded)
			if loaded == name and not done then
				done = true
				fn()
			end
		end)
	end
	lib.NewLocale(addonNS, name)
	return addonNS
end
