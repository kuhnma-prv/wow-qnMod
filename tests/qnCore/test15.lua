-- Scenario 15: qnCore.UI.Page – uniform options pages (canvas) like Blizzard's vertical pages
--   * header, divider, content in a ScrollFrameTemplate (scrollbar), description as first anchor
--   * "Defaults" button only with defaults
--   * Fit measures the content height
--   * every canvas page of the qn addons is built with UI.Page

EnableTooltips()   -- for qnTooltip (part 4)
LoadAddon("qnCore")
local UI = qnCore.UI

-- 1. without description and without "Defaults"
local a = UI.Page("Seite A")
Check(a.panel and a.content and a.top and a.Fit, "fields present")
Check(a.title._text == "Seite A", "header = page name")
Check(a.defaults == nil, "no 'Defaults' button without defaults")
Check(a.scroll._template == "ScrollFrameTemplate" and a.scroll._parent == a.panel and a.content._parent == a.scroll,
	"content in the scroll area with scrollbar")
Check(a.top._parent == a.content and a.top._points[1][1] == "TOPLEFT" and a.top._points[1][2] == a.padLeft,
	"first anchor top left in the content")

-- 2. with description and "Defaults"
local clicked
local b = UI.Page("Seite B", { desc = "Beschreibung", defaults = function() clicked = true end })
Check(b.top._text == "Beschreibung" and b.top._parent == b.content, "description in the content")
Check(b.defaults and b.defaults._text == SETTINGS_DEFAULTS, "'Defaults' button with Blizzard's text")
b.defaults._scripts.OnClick(b.defaults)
Check(clicked, "'Defaults' calls defaults")

-- 3. Fit: height from the top of the content to the lowest visible element
local low = CreateFrame("Frame", nil, b.content)
function low:GetBottom() return -200 end
local mid = CreateFrame("Frame", nil, b.content)
function mid:GetBottom() return -50 end
b.content.GetChildren = function() return low, mid end
function b.content:GetTop() return 0 end   -- dummy: otherwise GetTop follows the set height
b.Fit()
Check(b.content._h == 200 + b.padTop, ("Fit: height %s"):format(tostring(b.content._h)))
low:Hide()
b.Fit()
Check(b.content._h == 50 + b.padTop, "Fit: hidden elements do not count")

-- 4. all canvas pages of the addons via UI.Page
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
Check(canvas >= 6, ("canvas pages registered: %d"):format(canvas))
Check(#bad == 0, "all canvas pages built with UI.Page" .. (#bad > 0 and (": missing for " .. table.concat(bad, ", ")) or ""))

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
