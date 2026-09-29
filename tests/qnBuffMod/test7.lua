-- Szenario 7: qnBuffMod – Tooltips, Maus (Ziehen, Sperren, Alt-Klick), Fenstertitel
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local core = LoadAddon("qnCore")
local cats = {}
local origSub = Settings.RegisterVerticalLayoutSubcategory
Settings.RegisterVerticalLayoutSubcategory = function(p, name)
	local c, l = origSub(p, name)
	cats[name] = c
	return c, l
end
local bm = LoadAddon("qnBuffMod")
local E, L = bm.enum, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end

UnitName = function(u)
	if u == "pet" then return "Wuffi" elseif u == "target" then return "Gegner" end
	return "Tester"
end
UnitClass = function(u)
	if u == "target" then return nil, nil end
	return "Krieger", "WARRIOR"
end
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
AURAS.player = {
	{ name = "Segen", icon = 1, applications = 0, duration = 600, expirationTime = 1500, sourceUnit = "player", spellId = 19740, cancelable = true },
	{ name = "Knurren", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "pet", spellId = 2649 },
	{ name = "Fremd", icon = 3, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "target" },
}
ENCHANTS[16] = { remainingTimeMs = 600000, chargesRemaining = 0 }
QN_TOOLTIP[16] = { "Sofortgift (10 Min)" }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local function Entry(name, id)
	for _, e in ipairs(bm.GetEntries(id or 1)) do
		if e.name == name then return e.entry end
	end
end
local function Texts()
	local out = {}
	for _, l in ipairs(TOOLTIP.lines) do out[#out + 1] = tostring(l.text) .. (l.right and ("|" .. l.right) or "") end
	return table.concat(out, " / ")
end

---------------------------------------------------------------------------
-- Aurentooltip, Wirker, Fußzeile, Seite (Kriterium 42)
---------------------------------------------------------------------------
GetCursorPosition = function() return 100, 500 end
local b = Entry("Segen")
b._scripts.OnEnter(b)
local win = bm.GetWindow(1)
Check(TOOLTIP.owner == b and TOOLTIP.anchor == "ANCHOR_RIGHT", "linke Bildschirmhälfte: Tooltip rechts")
Check(TOOLTIP.aura and TOOLTIP.aura[1] == "player" and TOOLTIP.aura[2] == 1 and TOOLTIP.aura[3] == "HELPFUL|CANCELABLE", "Blizzards Aurentooltip mit Einheit, Index, Filter")
local l1, last = TOOLTIP.lines[1], TOOLTIP.lines[#TOOLTIP.lines]
Check(l1.text == "Tester" and l1.r == 0.78 and l1.g == 0.61, "Wirker in Klassenfarbe")
Check(last.text == L["Spell ID: %d"]:format(19740) and last.right == L["/qnbuff for options"], "Fußzeile: Zauber-ID und /qnbuff: " .. Texts())
Check(TOOLTIP.minWidth == 180, "mindestens 180 breit")
-- alle 0,5 s erneuert
local before = TOOLTIP
b._scripts.OnUpdate(b, 0.3)
Check(TOOLTIP == before, "vor 0,5 s nicht erneuert")
b._scripts.OnUpdate(b, 0.3)
Check(TOOLTIP ~= before and TOOLTIP.owner == b, "nach 0,5 s erneuert")
b._scripts.OnLeave(b)
Check(TOOLTIP.hidden and TOOLTIP.minWidth == 0 and b._scripts.OnUpdate == nil, "Verlassen: Tooltip weg, Mindestbreite zurück")
GetCursorPosition = function() return 1500, 500 end
b = Entry("Knurren")
b._scripts.OnEnter(b)
Check(TOOLTIP.anchor == "ANCHOR_LEFT", "rechte Bildschirmhälfte: Tooltip links")
Check(TOOLTIP.lines[1].text == "Wuffi" and TOOLTIP.lines[2].text == "<Tester>" and TOOLTIP.lines[2].r == 0.78, "Begleiter: Besitzer in dessen Klassenfarbe: " .. Texts())
b._scripts.OnLeave(b)
b = Entry("Fremd")
b._scripts.OnEnter(b)
Check(TOOLTIP.lines[1].text == "Gegner" and TOOLTIP.lines[1].r == 0.82 and TOOLTIP.lines[1].g == 1 and TOOLTIP.lines[1].b == 0, "ohne Klasse: Vorgabefarbe")
Check(TOOLTIP.lines[#TOOLTIP.lines].text == " ", "ohne Zauber-ID: keine ID-Zeile")
b._scripts.OnLeave(b)
Check(bm.Tooltip.OwnerOf("vehicle") == "player" and bm.Tooltip.OwnerOf("partypet2") == "party2" and bm.Tooltip.OwnerOf("raidpet12") == "raid12"
	and bm.Tooltip.OwnerOf("target") == nil, "Besitzer von Begleitern/Fahrzeugen")
b = Entry("Sofortgift")
b._scripts.OnEnter(b)
Check(TOOLTIP.item and TOOLTIP.item[1] == "player" and TOOLTIP.item[2] == 16 and TOOLTIP.aura == nil, "Waffe: Tooltip des Gegenstands")
b._scripts.OnLeave(b)

---------------------------------------------------------------------------
-- offene Fensterseite: Titel, Fensterzeile, Hintergrund (Kriterien 42, 55)
---------------------------------------------------------------------------
clicks[ADD]()
local win2 = bm.GetWindow(2)
Check(not win.title:IsShown() and not win2.title:IsShown(), "ohne offene Fensterseite keine Titel")
local current = cats[L["Window"]]
SettingsPanel.GetCurrentCategory = function() return current end
SettingsPanel:Show()
EventRegistry:TriggerEvent("Settings.CategoryChanged")
Check(win.title:IsShown() and win.title:GetText() == L["Window %d"]:format(1) and win2.title:IsShown(), "Titel über jedem Fenster")
Check(win2.title._textColor[1] == 1 and win2.title._textColor[3] == 1 and win.title._textColor[3] == 0, "ausgewähltes Fenster weiß, andere gold")
b = Entry("Segen")
b._scripts.OnEnter(b)
Check(TOOLTIP.lines[#TOOLTIP.lines].text == L["Window %d (Alt-click: select the window in the options.)"]:format(1), "Fensterzeile statt Fußzeile: " .. Texts())
b._scripts.OnLeave(b)
win.bg._scripts.OnEnter(win.bg)
Check(TOOLTIP.owner == win.bg and TOOLTIP.anchor == "ANCHOR_CURSOR" and TOOLTIP.lines[1].text == L["Window %d"]:format(1)
	and TOOLTIP.lines[2].text == L["Alt-click: select the window in the options."], "Hintergrund: Fenstertooltip am Mauszeiger")
win.bg._scripts.OnLeave(win.bg)
-- disableTooltips
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(1)
SETTINGS.QNBUFFMOD_W_DISABLETOOLTIPS:SetValue(true)
b = Entry("Segen")
b._scripts.OnEnter(b)
Check(TOOLTIP.aura == nil and TOOLTIP.lines[1].text == L["Window %d"]:format(1) and TOOLTIP.lines[2].text == L["Alt-click: select the window in the options."],
	"disableTooltips bei offener Fensterseite: nur Fenstertooltip")
b._scripts.OnLeave(b)
current = cats[APPEARANCE_LABEL]
EventRegistry:TriggerEvent("Settings.CategoryChanged")
Check(win.title:IsShown(), "auch andere Fensterseiten zeigen die Titel")
current = nil
EventRegistry:TriggerEvent("Settings.CategoryChanged")
Check(not win.title:IsShown() and not win2.title:IsShown(), "andere Seite: Titel weg")
TOOLTIP = { lines = {} }
b._scripts.OnEnter(b)
Check(TOOLTIP.owner == nil, "disableTooltips ohne Fensterseite: kein Tooltip")
SETTINGS.QNBUFFMOD_W_DISABLETOOLTIPS:SetValue(false)

---------------------------------------------------------------------------
-- Ziehen und Sperren (Kriterium 54)
---------------------------------------------------------------------------
local f = win.frame
Check(win.bg:IsMouseEnabled(), "entsperrt: Hintergrund nimmt die Maus")
win.bg._scripts.OnMouseDown(win.bg, "LeftButton")
Check(f._moving, "Ziehen am Hintergrund")
f.GetLeft = function() return 300 end
f.GetBottom = function() return 200 end
win.bg._scripts.OnMouseUp(win.bg, "LeftButton")
local pos = bm.db.windows[1].position
Check(not f._moving and pos[1] == "TOPLEFT" and pos[3] == "BOTTOMLEFT" and pos[4] == 300 and pos[5] == 200 + f._h, "Loslassen: neu verankert und gespeichert")
b = Entry("Segen")
b._scripts.OnMouseDown(b, "LeftButton")
Check(f._moving, "Ziehen am Eintrag")
b._scripts.OnMouseUp(b, "LeftButton")
SETTINGS.QNBUFFMOD_W_LOCKWINDOW:SetValue(true)
Check(not win.bg:IsMouseEnabled() and b:IsMouseEnabled(), "gesperrt, Optionen zu: Hintergrund ohne Maus, Einträge mit")
b._scripts.OnMouseDown(b, "LeftButton")
Check(not f._moving, "gesperrt: kein Ziehen am Eintrag")
current = cats[L["Window"]]
EventRegistry:TriggerEvent("Settings.CategoryChanged")
Check(win.bg:IsMouseEnabled(), "gesperrt, Fensterseite offen: Hintergrund nimmt die Maus")
win.bg._scripts.OnMouseDown(win.bg, "LeftButton")
Check(not f._moving, "gesperrt: auch bei offenen Optionen kein Ziehen")
SETTINGS.QNBUFFMOD_W_LOCKWINDOW:SetValue(false)

---------------------------------------------------------------------------
-- Alt-Klick (Kriterium 55)
---------------------------------------------------------------------------
IsAltKeyDown = function() return true end
LOG = {}
printed = {}
b = Entry("Segen")
b._scripts.OnMouseDown(b, "LeftButton")
Check(bm.SelectedID() == 1 and printed[1] == L["%s selected."]:format(L["Window %d"]:format(1)) and not f._moving, "Alt-Klick wählt das Fenster und meldet es")
local opened = false
for _, line in ipairs(LOG) do if line == "Öffne " .. current.name then opened = true end end
Check(opened, "Alt-Klick öffnet die Seite Fenster")
Check(SETTINGS.QNBUFFMOD_EDITWINDOW:GetValue() == 1, "Auswahl in den Optionen")
win2.bg._scripts.OnMouseDown(win2.bg, "LeftButton")
Check(bm.SelectedID() == 2 and win2.title._textColor[3] == 1 and win.title._textColor[3] == 0, "Alt-Klick am Hintergrund; Titelfarben folgen")
IsAltKeyDown = function() return false end
SettingsPanel:Hide()
Check(not win.title:IsShown(), "Einstellungsfenster zu: Titel weg")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
