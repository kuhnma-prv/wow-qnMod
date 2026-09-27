-- Szenario 1: qnNumKeyPad – Layouts, Größe, Aktionsplätze, Seitenwarnungen, Position,
-- Zieh-Fläche nach dem Kampf, Rahmen ausgerüsteter Gegenstände, hintShown kontoweit.

-- Stand von Layouts.lua vor dem Umbau auf gemeinsame Bausteine (Reihenfolge = Aktionsplätze).
local OLD_LAYOUTS = [==[
-- qnNumKeyPad: Tastaturlayouts.
--
-- row/col: Lage der Taste in Tastenbreiten, 1/1 = oben links im Ziffernblock.
-- Negative Spalten liegen links davon (Navigations- und Pfeilblock).
-- type: Numeric = immer sichtbar, Enter/Nav/Arrow = zuschaltbar.
-- Die Position einer Taste in der Liste bestimmt ihren Aktionsplatz;
-- deshalb darf die Reihenfolge nicht geändert werden.

local _, ns = ...

local function Numpad(extra)
	local keys = {
		{ row = 4, col = 1, type = "Numeric", label = "1", binding = "NUMPAD1" },
		{ row = 4, col = 2, type = "Numeric", label = "2", binding = "NUMPAD2" },
		{ row = 4, col = 3, type = "Numeric", label = "3", binding = "NUMPAD3" },
		{ row = 3, col = 1, type = "Numeric", label = "4", binding = "NUMPAD4" },
		{ row = 3, col = 2, type = "Numeric", label = "5", binding = "NUMPAD5" },
		{ row = 3, col = 3, type = "Numeric", label = "6", binding = "NUMPAD6" },
		{ row = 2, col = 1, type = "Numeric", label = "7", binding = "NUMPAD7" },
		{ row = 2, col = 2, type = "Numeric", label = "8", binding = "NUMPAD8" },
		{ row = 2, col = 3, type = "Numeric", label = "9", binding = "NUMPAD9" },
		{ row = 5, col = 1.5, type = "Numeric", label = "0", binding = "NUMPAD0" },
		{ row = 5, col = 3, type = "Numeric", label = ".", binding = "NUMPADDECIMAL" },
		{ row = 2.5, col = 4, type = "Numeric", label = "+", binding = "NUMPADPLUS" },
		{ row = 1, col = 4, type = "Numeric", label = "-", binding = "NUMPADMINUS" },
		{ row = 1, col = 3, type = "Numeric", label = "*", binding = "NUMPADMULTIPLY" },
		{ row = 1, col = 2, type = "Numeric", label = "/", binding = "NUMPADDIVIDE" },
		{ row = 4.5, col = 4, type = "Enter", label = "E", binding = "ENTER" },
	}
	for _, key in ipairs(extra) do
		keys[#keys + 1] = key
	end
	return keys
end

local ARROWS = {
	{ row = 4, col = 2 - 3.3, type = "Arrow", label = "^", binding = "UP" },
	{ row = 5, col = 1 - 3.3, type = "Arrow", label = "<", binding = "LEFT" },
	{ row = 5, col = 2 - 3.3, type = "Arrow", label = "v", binding = "DOWN" },
	{ row = 5, col = 3 - 3.3, type = "Arrow", label = ">", binding = "RIGHT" },
}

local ARROWS_LOW = {
	{ row = 4.3, col = 2 - 3.3, type = "Arrow", label = "^", binding = "UP" },
	{ row = 5.3, col = 1 - 3.3, type = "Arrow", label = "<", binding = "LEFT" },
	{ row = 5.3, col = 2 - 3.3, type = "Arrow", label = "v", binding = "DOWN" },
	{ row = 5.3, col = 3 - 3.3, type = "Arrow", label = ">", binding = "RIGHT" },
}

local function Join(...)
	local list = {}
	for i = 1, select("#", ...) do
		for _, key in ipairs((select(i, ...))) do
			list[#list + 1] = key
		end
	end
	return list
end

ns.LAYOUTS = {
	{
		id = "Windows", name = "Windows",
		keys = Numpad(Join({
			{ row = 1, col = 1 - 3.3, type = "Nav", label = "I", binding = "INSERT" },
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2, col = 1 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 2, col = 2 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
		}, ARROWS)),
	},
	{
		id = "MicrosoftOffice", name = "Microsoft Office",
		keys = Numpad(Join({
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2.5, col = 2 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 3, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
			-- Zusatztaste der Office-Tastatur, liegt im Ziffernblock
			{ row = 1, col = 1, type = "Nav", label = "T", binding = "TAB" },
		}, ARROWS_LOW)),
	},
	{
		id = "NaturalMultimedia", name = "Natural Multimedia",
		keys = Numpad(Join({
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2.5, col = 2 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 3, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
		}, ARROWS_LOW)),
	},
	{
		id = "NaturalElite", name = "Natural Elite",
		keys = Numpad({
			{ row = 1, col = 1 - 2.6, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 2 - 2.6, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2, col = 1 - 2.6, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 2 - 2.6, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
			{ row = 3, col = 1 - 2.6, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 3, col = 2 - 2.6, type = "Nav", label = "I", binding = "INSERT" },
			{ row = 4.3, col = 2 - 3.1, type = "Arrow", label = "^", binding = "UP" },
			{ row = 4.8, col = 1 - 3.1, type = "Arrow", label = "<", binding = "LEFT" },
			{ row = 5.3, col = 2 - 3.1, type = "Arrow", label = "v", binding = "DOWN" },
			{ row = 4.8, col = 3 - 3.1, type = "Arrow", label = ">", binding = "RIGHT" },
		}),
	},
	{
		id = "Macintosh", name = "Macintosh",
		keys = Join({
			{ row = 4, col = 1, type = "Numeric", label = "1", binding = "NUMPAD1" },
			{ row = 4, col = 2, type = "Numeric", label = "2", binding = "NUMPAD2" },
			{ row = 4, col = 3, type = "Numeric", label = "3", binding = "NUMPAD3" },
			{ row = 3, col = 1, type = "Numeric", label = "4", binding = "NUMPAD4" },
			{ row = 3, col = 2, type = "Numeric", label = "5", binding = "NUMPAD5" },
			{ row = 3, col = 3, type = "Numeric", label = "6", binding = "NUMPAD6" },
			{ row = 2, col = 1, type = "Numeric", label = "7", binding = "NUMPAD7" },
			{ row = 2, col = 2, type = "Numeric", label = "8", binding = "NUMPAD8" },
			{ row = 2, col = 3, type = "Numeric", label = "9", binding = "NUMPAD9" },
			{ row = 5, col = 1.5, type = "Numeric", label = "0", binding = "NUMPAD0" },
			{ row = 5, col = 3, type = "Numeric", label = ".", binding = "NUMPADDECIMAL" },
			{ row = 3, col = 4, type = "Numeric", label = "+", binding = "NUMPADPLUS" },
			{ row = 2, col = 4, type = "Numeric", label = "-", binding = "NUMPADMINUS" },
			{ row = 1, col = 4, type = "Numeric", label = "*", binding = "NUMPADMULTIPLY" },
			{ row = 1, col = 3, type = "Numeric", label = "/", binding = "NUMPADDIVIDE" },
			-- Zusatztasten der Mac-Tastatur
			{ row = 1, col = 2, type = "Numeric", label = "=", binding = "NUMPADEQUALS" },
			{ row = 1, col = 1, type = "Numeric", label = "C", binding = "NUMLOCK" },
			{ row = 4.5, col = 4, type = "Enter", label = "E", binding = "ENTER" },
			{ row = 1, col = 1 - 3.3, type = "Nav", label = "H?", binding = "INSERT" },
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2, col = 1 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 2, col = 2 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
		}, ARROWS),
	},
	{
		id = "Naga", name = "Razer Naga",
		keys = Join({
			{ row = 4, col = 1, type = "Numeric", label = "7", binding = "NUMPAD7" },
			{ row = 4, col = 2, type = "Numeric", label = "8", binding = "NUMPAD8" },
			{ row = 4, col = 3, type = "Numeric", label = "9", binding = "NUMPAD9" },
			{ row = 3, col = 1, type = "Numeric", label = "4", binding = "NUMPAD4" },
			{ row = 3, col = 2, type = "Numeric", label = "5", binding = "NUMPAD5" },
			{ row = 3, col = 3, type = "Numeric", label = "6", binding = "NUMPAD6" },
			{ row = 2, col = 1, type = "Numeric", label = "1", binding = "NUMPAD1" },
			{ row = 2, col = 2, type = "Numeric", label = "2", binding = "NUMPAD2" },
			{ row = 2, col = 3, type = "Numeric", label = "3", binding = "NUMPAD3" },
			{ row = 5, col = 1, type = "Numeric", label = "10", binding = "NUMPAD0" },
			{ row = 5, col = 2, type = "Numeric", label = "11", binding = "NUMPADMINUS" },
			{ row = 5, col = 3, type = "Numeric", label = "12", binding = "NUMPADPLUS" },
			{ row = 1, col = 1 - 3.3, type = "Nav", label = "I", binding = "INSERT" },
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2, col = 1 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 2, col = 2 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
		}, ARROWS),
	},
}

ns.MAX_BUTTONS = 0
for _, layout in ipairs(ns.LAYOUTS) do
	ns.MAX_BUTTONS = math.max(ns.MAX_BUTTONS, #layout.keys)
end

function ns.GetLayout(id)
	for _, layout in ipairs(ns.LAYOUTS) do
		if layout.id == id then
			return layout
		end
	end
end
]==]

-- alle Rahmen merken (die Zieh-Fläche hat keinen Namen)
local created = {}
local createFrame = CreateFrame
CreateFrame = function(...)
	local f = createFrame(...)
	created[#created + 1] = f
	return f
end
StaticPopup_StandardEditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end
SpellFlyout = CreateFrame("Frame", "SpellFlyout")
SpellFlyout:Hide()

-- Chatausgabe mitschreiben
local chat = {}
function DEFAULT_CHAT_FRAME:AddMessage(msg)
	chat[#chat + 1] = msg
	print("  [Chat] " .. tostring(msg):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end
local function Count(text)
	local n = 0
	for _, msg in ipairs(chat) do
		if msg:find(text, 1, true) then
			n = n + 1
		end
	end
	return n
end

-- Profil aus Version 1.1.0: Hinweis schon gezeigt (hintShown je Profil)
qnNumKeyPadProfiles = { version = 1, global = {}, profiles = { ["account:Alt"] = { hintShown = true, scale = 1 } } }

local core = LoadAddon("qnCore")
local nkp = LoadAddon("qnNumKeyPad")
local L = nkp.L

---------------------------------------------------------------------------
-- Layouts: neue Tabellen feldweise gleich den alten
---------------------------------------------------------------------------
local old = {}
assert(load(OLD_LAYOUTS, "=Layouts.alt"))("qnNumKeyPad", old)
local same, why = #old.LAYOUTS == #nkp.LAYOUTS, "Anzahl Layouts"
for li, lay in ipairs(old.LAYOUTS) do
	local new = nkp.LAYOUTS[li]
	if not new or new.id ~= lay.id or new.name ~= lay.name or #new.keys ~= #lay.keys then
		same, why = false, "Layout " .. lay.id
	else
		for ki, key in ipairs(lay.keys) do
			local nk = new.keys[ki]
			for field, v in pairs(key) do
				if nk[field] ~= v then same, why = false, ("%s Taste %d Feld %s"):format(lay.id, ki, field) end
			end
			for field in pairs(nk) do
				if key[field] == nil then same, why = false, ("%s Taste %d Zusatzfeld %s"):format(lay.id, ki, field) end
			end
		end
	end
end
Check(same, "Layouts unverändert (Reihenfolge, Lage, Typ, Beschriftung, Belegung): " .. why)
Check(nkp.MAX_BUTTONS == 28 and old.MAX_BUTTONS == 28, "28 Tasten höchstens")
Check(nkp.GetLayout("Macintosh").keys[19].label == "H?", "Mac-Beschriftung H? unverändert")

---------------------------------------------------------------------------
-- hintShown kontoweit
---------------------------------------------------------------------------
Check(qnNumKeyPadProfiles.global.hintShown == true, "hintShown aus dem Profil nach global übernommen")
Check(qnNumKeyPadProfiles.profiles["account:Alt"].hintShown == nil, "hintShown im Profil entfernt")
Check(_G.qnNumKeyPad == nil and nkp.Slot == nil and nkp.settings == nil, "keine globale Tabelle, kein ns.Slot, kein ns.settings")
Check(StaticPopupDialogs.QNNUMKEYPAD_CUSTOM.EditBoxOnEscapePressed == StaticPopup_StandardEditBoxOnEscapePressed, "Escape im Eingabefeld: Blizzard-Standard")

-- Hinweis beim Einloggen: einmal je Konto
local HINT = L["Leiste mit der linken Maustaste verschieben, Rechtsklick öffnet die Optionen. Sperren mit /qnnkp lock."]
local WARN_BLIZZ = L["Warnung: Seite %d wird auch von einer eingeblendeten Blizzard-Leiste benutzt."]
local WARN_MULTI = L["Warnung: Seite %d ist für mehrere Tastengruppen eingestellt."]
qnNumKeyPadProfiles.global.hintShown = nil
nkp.db.page1 = 1   -- Seite der Hauptleiste: Warnung
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(Count(HINT) == 1 and qnNumKeyPadProfiles.global.hintShown == true, "Hinweis einmal gezeigt, kontoweit gemerkt")
Check(Count(WARN_BLIZZ:format(1)) == 1, "Warnung Seite 1 beim Einloggen")
SetEditModeLayout(3)
SetEditModeLayout(4)
Check(nkp.db == qnNumKeyPadProfiles.profiles["char:Tester-Realm:Solo"], "Profilwechsel auf char-Layout")
Check(Count(WARN_BLIZZ:format(1)) == 1, "gleiche Warnung nach Profilwechsel nicht wiederholt")
Check(Count(HINT) == 1, "Hinweis nicht wiederholt")

---------------------------------------------------------------------------
-- Größe nach Layout, Aktionsplätze
---------------------------------------------------------------------------
local applies = 0
local applyAll = nkp.ApplyAll
nkp.ApplyAll = function(...)
	applies = applies + 1
	return applyAll(...)
end
local function Set(key, value)
	SETTINGS["QNNKP_" .. key:upper()]:SetValue(value)
end
local function Near(a, b)
	return math.abs(a - b) < 0.01
end

Set("page1", 13)
local bar = nkp.bar
local w, h = bar:GetSize()
Check(w == 191 and h == 237, ("Windows ohne Zusatztasten: 4x5 Tasten (%s x %s)"):format(w, h))
Check(not qnNumKeyPadButton16:IsShown() and qnNumKeyPadButton15:IsShown(), "Enter-Taste verborgen, Taste 15 sichtbar")
Set("showNav", true)
Set("showArrow", true)
w, h = bar:GetSize()
Check(Near(w, 342.8) and h == 237, ("mit Navigations- und Pfeiltasten breiter (%s x %s)"):format(w, h))
Set("blockGap", 10)
Check(Near(bar:GetWidth(), 352.8), "Abstand zum Zusatzblock verbreitert: " .. bar:GetWidth())
Set("blockGap", 0)
Set("padH", 5)
Check(Near(bar:GetWidth(), 342.8 + 3 * 4 + 3.3 * 4), "waagerechter Abstand: " .. bar:GetWidth())
Set("padH", 1)
Set("layout", "Macintosh")
Check(qnNumKeyPadButton28:IsShown() and not qnNumKeyPadButton18:IsShown(), "Mac: 28 Tasten, Enter verborgen")

local function Own(i)
	return _G["qnNumKeyPadButton" .. i]:GetAttribute("qn-own")
end
Check(Own(1) == 145 and Own(12) == 156 and Own(13) == 157 and Own(24) == 168 and Own(25) == 169 and Own(28) == 172,
	"Plätze: Seiten 13/14/15 je 12 Tasten")
Set("page1", 3)
Set("page3", 6)
Check(Own(1) == 25 and Own(12) == 36 and Own(13) == 157 and Own(25) == 61 and Own(28) == 64, "Plätze nach Seitenwechsel")

---------------------------------------------------------------------------
-- Seitenwarnungen
---------------------------------------------------------------------------
Set("page1", 13)
Set("page3", 15)
Set("layout", "Windows")
Set("showNav", false)
Set("showArrow", false)
chat = {}
local mb6 = CreateFrame("Frame", "MultiBar6")   -- Blizzard-Leiste auf Seite 14
Set("showEnter", true)
Check(Count(WARN_BLIZZ:format(14)) == 1, "Enter-Taste an: Seiten neu geprüft, Blizzard-Leiste auf Seite 14")
Set("showNav", true)
Check(Count(WARN_BLIZZ:format(14)) == 1, "gleiche Warnung nicht wiederholt")
Set("page1", 14)
Check(Count(WARN_MULTI:format(14)) == 1 and Count(WARN_BLIZZ:format(14)) == 2, "zwei Gruppen auf Seite 14: je eine Warnung")
chat = {}
Set("showArrow", true)   -- Tasten 25/26 benutzen jetzt Seite 3 (15)
Check(#chat == 0, "unveränderte Warnungen nicht wiederholt")
mb6:Hide()
Set("page3", 14)
Check(Count(WARN_MULTI:format(14)) == 1 and Count(WARN_BLIZZ:format(14)) == 0, "drei Gruppen auf Seite 14: nur eine Warnung")
mb6:Show()
Set("page1", 13)
Set("page3", 13)
Set("showArrow", false)
chat = {}
Set("showArrow", true)
Check(Count(WARN_MULTI:format(13)) == 1, "Pfeiltasten an: Gruppe 3 teilt Seite 13 mit Gruppe 1")
chat = {}
Set("layout", "Naga")
Check(Count(WARN_MULTI:format(13)) == 0 and Count(WARN_BLIZZ:format(14)) == 1, "Layoutwechsel prüft neu (Naga benutzt Gruppe 3 nicht)")
chat = {}
QN_COMBAT = true
Set("layout", "Windows")
Check(Count(WARN_MULTI:format(13)) == 1, "Prüfung liest die Einstellungen, auch im Kampf")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
mb6:Hide()
Set("page3", 15)
Set("showNav", false)
Set("showArrow", false)
Set("showEnter", false)

---------------------------------------------------------------------------
-- Position: SavePosition (Ankerwechsel), CenterBar, ResetPosition – je ein Apply
---------------------------------------------------------------------------
bar.GetLeft = function() return 100 end
bar.GetBottom = function() return 200 end
applies = 0
Set("point", "TOPLEFT")
Check(nkp.db.x == 100 and nkp.db.y == -643 and applies == 1, ("TOPLEFT: x/y umgerechnet (%s, %s), %d Apply"):format(nkp.db.x, nkp.db.y, applies))
Check(SETTINGS.QNNKP_X:GetValue() == 100 and SETTINGS.QNNKP_Y:GetValue() == -643, "Einstellungsfenster zeigt neue Werte")
Set("point", "BOTTOMRIGHT")
Check(nkp.db.x == -1629 and nkp.db.y == 200, ("BOTTOMRIGHT: (%s, %s)"):format(nkp.db.x, nkp.db.y))
Set("point", "TOPLEFT")
nkp.CenterBar(true)
Check(nkp.db.x == 865 and nkp.db.y == -643, "waagerecht zentriert (TOPLEFT): " .. nkp.db.x)
Set("point", "CENTER")
nkp.CenterBar(false)
Check(nkp.db.y == 0, "senkrecht zentriert (CENTER): " .. nkp.db.y)
applies = 0
nkp.ResetPosition()
Check(nkp.db.point == "CENTER" and nkp.db.x == 300 and nkp.db.y == -100 and applies == 1, "zurückgesetzt mit einem Apply: " .. applies)
Check(SETTINGS.QNNKP_POINT:GetValue() == "CENTER" and SETTINGS.QNNKP_X:GetValue() == 300, "Einstellungsfenster nach Zurücksetzen")

---------------------------------------------------------------------------
-- Zieh-Fläche nach dem Kampf
---------------------------------------------------------------------------
local overlay
for _, f in ipairs(created) do
	if f:GetParent() == bar and f:GetScript("OnDragStart") then
		overlay = f
	end
end
Check(overlay ~= nil, "Zieh-Fläche gefunden")
Set("locked", false)
Check(overlay:IsShown(), "entsperrt: Zieh-Fläche sichtbar")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
Check(not overlay:IsShown(), "im Kampf verborgen")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(overlay:IsShown(), "nach dem Kampf wieder sichtbar (ohne aufgeschobene Änderung)")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
Set("scale", 1.2)   -- aufgeschoben
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(overlay:IsShown(), "nach dem Kampf wieder sichtbar (mit aufgeschobener Änderung)")
-- Ziehen: Position speichern
applies = 0
overlay:GetScript("OnDragStop")()
Check(nkp.db.x == math.floor(100 + 95.5 - 960 + 0.5) and applies == 1, "nach dem Ziehen gespeichert: " .. nkp.db.x)
Set("locked", true)
Check(not overlay:IsShown(), "gesperrt: Zieh-Fläche verborgen")

---------------------------------------------------------------------------
-- Rahmen ausgerüsteter Gegenstände
---------------------------------------------------------------------------
C_ActionBar.IsEquippedAction = function(action) return action == 145 end
local b1 = qnNumKeyPadButton1
b1.action = 145
nkp.ApplyCosmetic()
Check(b1.Border:IsShown(), "ausgerüstet: Rahmen sichtbar")
Set("hideBorder", true)
Check(not b1.Border:IsShown(), "Rahmen ausgeblendet")
Set("hideBorder", false)
Check(b1.Border:IsShown(), "Rahmen nach dem Zurückschalten wieder sichtbar")
Check(not qnNumKeyPadButton2.Border:IsShown(), "nicht ausgerüstet: kein Rahmen")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
