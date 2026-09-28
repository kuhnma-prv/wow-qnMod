-- Szenario 15: qnCore.UI.Page – einheitliche Optionsseiten (Canvas) wie Blizzards senkrechte Seiten
--   * Überschrift, Trennlinie, Inhalt in einem ScrollFrameTemplate (Scrollbar), Beschreibung als erster Anker
--   * Knopf „Standard“ nur mit defaults
--   * Fit misst die Höhe des Inhalts
--   * jede Canvas-Seite der qn-Addons ist mit UI.Page gebaut

EnableTooltips()   -- für qnTooltip (Teil 4)
LoadAddon("qnCore")
local UI = qnCore.UI

-- 1. ohne Beschreibung und ohne „Standard“
local a = UI.Page("Seite A")
Check(a.panel and a.content and a.top and a.Fit, "Felder vorhanden")
Check(a.title._text == "Seite A", "Überschrift = Name der Seite")
Check(a.defaults == nil, "ohne defaults kein Knopf „Standard“")
Check(a.scroll._template == "ScrollFrameTemplate" and a.scroll._parent == a.panel and a.content._parent == a.scroll,
	"Inhalt im Bildlaufbereich mit Scrollbar")
Check(a.top._parent == a.content and a.top._points[1][1] == "TOPLEFT" and a.top._points[1][2] == a.padLeft,
	"erster Anker oben links im Inhalt")

-- 2. mit Beschreibung und „Standard“
local clicked
local b = UI.Page("Seite B", { desc = "Beschreibung", defaults = function() clicked = true end })
Check(b.top._text == "Beschreibung" and b.top._parent == b.content, "Beschreibung im Inhalt")
Check(b.defaults and b.defaults._text == SETTINGS_DEFAULTS, "Knopf „Standard“ mit Blizzards Text")
b.defaults._scripts.OnClick(b.defaults)
Check(clicked, "„Standard“ ruft defaults auf")

-- 3. Fit: Höhe von der Oberkante des Inhalts bis zum untersten sichtbaren Element
local low = CreateFrame("Frame", nil, b.content)
function low:GetBottom() return -200 end
local mid = CreateFrame("Frame", nil, b.content)
function mid:GetBottom() return -50 end
b.content.GetChildren = function() return low, mid end
function b.content:GetTop() return 0 end   -- Attrappe: sonst folgt GetTop der gesetzten Höhe
b.Fit()
Check(b.content._h == 200 + b.padTop, ("Fit: Höhe %s"):format(tostring(b.content._h)))
low:Hide()
b.Fit()
Check(b.content._h == 50 + b.padTop, "Fit: verborgene Elemente zählen nicht")

-- 4. alle Canvas-Seiten der Addons über UI.Page
local panels = {}
local origPage = UI.Page
function UI.Page(...)
	local p = origPage(...)
	panels[p.panel] = true
	return p
end
local canvas, bad = 0, {}
local function Watch(name)
	local orig = Settings[name]
	Settings[name] = function(...)
		local args = { ... }
		local frame, title = args[#args - 1], args[#args]
		canvas = canvas + 1
		if not panels[frame] then bad[#bad + 1] = title end
		return orig(...)
	end
end
Watch("RegisterCanvasLayoutCategory")
Watch("RegisterCanvasLayoutSubcategory")
LoadAddon("qnViewPort")
LoadAddon("qnUnitFrames")
LoadAddon("qnTooltip")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(canvas >= 6, ("Canvas-Seiten angemeldet: %d"):format(canvas))
Check(#bad == 0, "alle Canvas-Seiten mit UI.Page gebaut" .. (#bad > 0 and (": fehlt bei " .. table.concat(bad, ", ")) or ""))

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
