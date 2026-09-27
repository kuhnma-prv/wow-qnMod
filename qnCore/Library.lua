-- qnCore: Kern und Bibliothek der qn-Addons (qnMeter, qnNumKeyPad, qnViewPort, qnInventory, qnBuffMod, qnUnitFrames).
-- Library: gemeinsame Hilfsfunktionen, global erreichbar als qnCore.
--
-- Die qn-Addons (auch qnCore selbst) rufen beim Laden
--   qnCore.NewAddon(ns, ADDON)
-- auf. Das setzt ns.version, ns.L, ns.Print, ns.IsSecret, ns.Plain, ns.AnySecret, ns.events und
-- ns.OnLoad.
-- Die übrigen Dateien von qnCore erreichen die Bibliothek über das globale qnCore.

local ADDON, ns = ...

local lib = {}
_G.qnCore = lib

-- Namen der angemeldeten Addons je Namensraum (nur innerhalb von qnCore, z. B. Profiles.Register)
ns.addonNames = setmetatable({}, { __mode = "k" })

local function Meta(addon, field)
	return C_AddOns.GetAddOnMetadata(addon, field) or "?"
end

lib.version = Meta(ADDON, "Version")

---------------------------------------------------------------------------
-- Secret-Values
-- Auf Clients mit Midnight-Engine können API-Rückgaben "secret" sein. Mit
-- solchen Werten darf Addon-Code weder rechnen noch vergleichen noch sie
-- auf Wahrheit prüfen. Erlaubt ist nur die Übergabe an bestimmte Widgets
-- (SetText, SetFormattedText, StatusBar:SetValue, AbbreviateLargeNumbers).
---------------------------------------------------------------------------

lib.IsSecret = issecretvalue
local IsSecret = lib.IsSecret

-- Liefert v, oder fallback wenn v secret ist.
function lib.Plain(v, fallback)
	if IsSecret(v) then
		return fallback
	end
	return v
end

-- true, wenn einer der Werte secret ist (nil-Werte dürfen dazwischen stehen)
function lib.AnySecret(...)
	for i = 1, select("#", ...) do
		if IsSecret((select(i, ...))) then
			return true
		end
	end
	return false
end

-- true, wenn einer der Werte der Tabelle t secret ist
function lib.AnySecretIn(t)
	for _, v in pairs(t) do
		if IsSecret(v) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- Klassenfarben
---------------------------------------------------------------------------

-- Klassenfarbe (RAID_CLASS_COLORS, Felder r, g, b) zum Klassennamen wie "WARRIOR";
-- nil, wenn die Klasse fehlt, unbekannt oder secret ist.
function lib.ClassColor(classFile)
	if IsSecret(classFile) or classFile == nil then
		return nil
	end
	return RAID_CLASS_COLORS[classFile]
end

-- Name in Klassenfarbe; ohne Klassenfarbe in fallback (Farbe mit r, g, b), ohne fallback
-- ungefärbt. Ein secret-Name kommt unverändert zurück (nur für SetText geeignet).
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
-- Lokalisierung
-- Schlüssel ist der deutsche Text. Deutsche Clients zeigen ihn unverändert,
-- alle anderen die englische Übersetzung aus der Locale.lua des Addons
-- (in der TOC vor allen Dateien, die Texte verwenden):
--   local ADDON, ns = ...
--   local L = qnCore.NewLocale(ns, ADDON)
--   if qnCore.GERMAN then return end
--   L["Deutscher Text"] = "English text"
-- Fehlt eine Übersetzung, erscheint der deutsche Text; /qncore locale listet
-- solche Schlüssel auf. Hat Blizzard einen passenden Text (GlobalStrings wie
-- CANCEL, DELETE), wird dieser statt eines eigenen Schlüssels verwendet.
---------------------------------------------------------------------------

lib.GERMAN = GetLocale() == "deDE"
lib.missing = {}   -- [Addon] = { [Schlüssel] = true }: ohne Übersetzung angezeigt

function lib.NewLocale(addonNS, name)
	if addonNS.L then
		return addonNS.L
	end
	local L = setmetatable({}, { __index = function(_, key)
		if not lib.GERMAN and key ~= nil then
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
-- Tabellen
---------------------------------------------------------------------------

-- Ergänzt fehlende Schlüssel aus den Vorgaben. Listen ({ 1, 2, 3 }) werden als
-- Ganzes übernommen, Tabellen mit Schlüsseln ({ r = 1, … }) rekursiv ergänzt.
-- Ist die Vorgabe eine Tabelle, der gespeicherte Wert aber keine (beschädigt oder altes
-- Format), wird die Vorgabe kopiert.
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

-- Löscht veraltete Schlüssel aus t; "dual.uiOnMain" steht für t.dual.uiOnMain.
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
-- Ausgabe
---------------------------------------------------------------------------

-- Liefert eine Print-Funktion mit Präfix. Mit weiteren Argumenten wird fmt
-- über string.format ausgefüllt, sonst unverändert ausgegeben. Mehrzeilige Texte
-- (ein Schlüssel mit \n) erscheinen als einzelne Chatzeilen, jede mit Präfix.
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
-- Ereignisse
---------------------------------------------------------------------------

-- Kleiner Verteiler: hub.Register(event, fn) ruft fn(event, ...) auf; mehrere
-- Funktionen je Ereignis möglich.
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
-- Lage von Rahmen relativ zu UIParent
-- Alle Rechnungen über die wirksame Skalierung; UIParent darf verschoben oder verkleinert sein
-- (qnViewPort: Oberfläche auf dem Hauptmonitor).
---------------------------------------------------------------------------

-- Anteil eines Ankerpunkts an Breite und Höhe: TOPLEFT = 0, 1; CENTER = 0.5, 0.5; BOTTOMRIGHT = 1, 0
function lib.AnchorFactors(point)
	local fx = point:find("LEFT") and 0 or point:find("RIGHT") and 1 or 0.5
	local fy = point:find("TOP") and 1 or point:find("BOTTOM") and 0 or 0.5
	return fx, fy
end

-- Lage des Punkts point von frame in Einheiten bei wirksamer Skalierung 1 (x, y) oder nil
local function PointAbs(frame, point)
	local l, b = frame:GetLeft(), frame:GetBottom()
	if not (l and b) then
		return nil
	end
	local fx, fy = lib.AnchorFactors(point)
	local s = frame:GetEffectiveScale()
	return (l + fx * frame:GetWidth()) * s, (b + fy * frame:GetHeight()) * s
end

-- Versätze für frame:SetPoint(point, UIParent, relPoint, x, y), mit denen frame bleibt, wo er ist.
-- inParentUnits: in Einheiten von UIParent (unabhängig von der Skalierung des Rahmens; beim Setzen
-- durch frame:GetScale() teilen), sonst in Einheiten des Rahmens. nil, solange frame keine Lage hat.
function lib.PointOffset(frame, point, relPoint, inParentUnits)
	local px, py = PointAbs(frame, point)
	local rx, ry = PointAbs(UIParent, relPoint)
	if not (px and rx) then
		return nil
	end
	local s = inParentUnits and UIParent:GetEffectiveScale() or frame:GetEffectiveScale()
	return (px - rx) / s, (py - ry) / s
end

-- Ecke von UIParent, die dem Punkt point von frame (Vorgabe CENTER) am nächsten liegt, z. B. "TOPRIGHT".
function lib.NearestCorner(frame, point)
	local px, py = PointAbs(frame, point or "CENTER")
	local cx, cy = PointAbs(UIParent, "CENTER")
	if not (px and cx) then
		return "BOTTOMLEFT"
	end
	return (py > cy and "TOP" or "BOTTOM") .. (px > cx and "RIGHT" or "LEFT")
end

---------------------------------------------------------------------------
-- Kampf und Zeitsteuerung
---------------------------------------------------------------------------

local deferred, deferredSet = {}, {}   -- nach dem Kampf aufzurufen (Reihenfolge, Menge)

-- Im Kampf: fn für die Zeit nach dem Kampf vormerken (jede Funktion höchstens einmal) und true
-- liefern. Außerhalb des Kampfes false – dann handelt der Aufrufer sofort:
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

-- ein gemeinsamer Handler für alle vorgemerkten Funktionen; ein Fehler hält die übrigen nicht auf
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

-- Liefert eine Funktion, die fn nach delay Sekunden (Vorgabe 0 = im nächsten Frame) aufruft.
-- Weitere Aufrufe bis dahin werden zusammengefasst; Argumente werden nicht weitergereicht.
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
-- Slash-Befehle
---------------------------------------------------------------------------

-- Meldet Slash-Befehle an: id = Schlüssel in SlashCmdList (z. B. "QNMETER"), commands = { "/qnm", … }.
-- handler(cmd, rest, msg): cmd = erstes Wort in Kleinbuchstaben ("" ohne Eingabe), rest = alles
-- danach in der eingegebenen Schreibweise, msg = die ganze Eingabe; alle ohne Leerzeichen am Rand.
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
-- Einstellungsfenster
---------------------------------------------------------------------------

function lib.OpenCategory(category)
	Settings.OpenToCategory(category:GetID())
end

---------------------------------------------------------------------------
-- Anmeldung eines qn-Addons
---------------------------------------------------------------------------

function lib.NewAddon(addonNS, name)
	ns.addonNames[addonNS] = name
	addonNS.version = Meta(name, "Version")
	addonNS.IsSecret = IsSecret
	addonNS.Plain = lib.Plain
	addonNS.AnySecret = lib.AnySecret
	addonNS.Print = lib.NewPrinter(name)
	-- ein Ereignisverteiler für alle Dateien des Addons
	addonNS.events = lib.NewEventHub()
	-- fn() einmal beim ADDON_LOADED dieses Addons (gespeicherte Variablen sind dann geladen)
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
