-- Scenario 7: qnBuffMod – tooltips, mouse (drag, lock, Alt-click), window titles
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
-- aura tooltip, caster, footer, side (criterion 42)
---------------------------------------------------------------------------
GetCursorPosition = function() return 100, 500 end
local b = Entry("Segen")
b._scripts.OnEnter(b)
local win = bm.GetWindow(1)
Check(TOOLTIP.owner == b and TOOLTIP.anchor == "ANCHOR_RIGHT", "left half of the screen: tooltip on the right")
Check(TOOLTIP.aura and TOOLTIP.aura[1] == "player" and TOOLTIP.aura[2] == 1 and TOOLTIP.aura[3] == "HELPFUL|CANCELABLE", "Blizzard's aura tooltip with unit, index, filter")
local l1, last = TOOLTIP.lines[1], TOOLTIP.lines[#TOOLTIP.lines]
Check(l1.text == "Tester" and l1.r == 0.78 and l1.g == 0.61, "caster in class color")
Check(last.text == L["Spell ID: %d"]:format(19740) and last.right == L["/qnbuff for options"], "footer: spell ID and /qnbuff: " .. Texts())
Check(TOOLTIP.minWidth == 180, "at least 180 wide")
-- refreshed every 0.5 s
local before = TOOLTIP
b._scripts.OnUpdate(b, 0.3)
Check(TOOLTIP == before, "not refreshed before 0.5 s")
b._scripts.OnUpdate(b, 0.3)
Check(TOOLTIP ~= before and TOOLTIP.owner == b, "refreshed after 0.5 s")
b._scripts.OnLeave(b)
Check(TOOLTIP.hidden and TOOLTIP.minWidth == 0 and b._scripts.OnUpdate == nil, "leave: tooltip gone, minimum width reset")
GetCursorPosition = function() return 1500, 500 end
b = Entry("Knurren")
b._scripts.OnEnter(b)
Check(TOOLTIP.anchor == "ANCHOR_LEFT", "right half of the screen: tooltip on the left")
Check(TOOLTIP.lines[1].text == "Wuffi" and TOOLTIP.lines[2].text == "<Tester>" and TOOLTIP.lines[2].r == 0.78, "pet: owner in the owner's class color: " .. Texts())
b._scripts.OnLeave(b)
b = Entry("Fremd")
b._scripts.OnEnter(b)
Check(TOOLTIP.lines[1].text == "Gegner" and TOOLTIP.lines[1].r == 0.82 and TOOLTIP.lines[1].g == 1 and TOOLTIP.lines[1].b == 0, "without class: default color")
Check(TOOLTIP.lines[#TOOLTIP.lines].text == " ", "without spell ID: no ID line")
b._scripts.OnLeave(b)
Check(bm.Tooltip.OwnerOf("vehicle") == "player" and bm.Tooltip.OwnerOf("partypet2") == "party2" and bm.Tooltip.OwnerOf("raidpet12") == "raid12"
	and bm.Tooltip.OwnerOf("target") == nil, "owners of pets/vehicles")
b = Entry("Sofortgift")
b._scripts.OnEnter(b)
Check(TOOLTIP.item and TOOLTIP.item[1] == "player" and TOOLTIP.item[2] == 16 and TOOLTIP.aura == nil, "weapon: item tooltip")
b._scripts.OnLeave(b)

---------------------------------------------------------------------------
-- open window page: titles, window line, background (criteria 42, 55)
---------------------------------------------------------------------------
clicks[ADD]()
local win2 = bm.GetWindow(2)
Check(not win.title:IsShown() and not win2.title:IsShown(), "no titles without an open window page")
local current = cats[L["Window"]]
SettingsPanel.GetCurrentCategory = function() return current end
SettingsPanel:Show()
EventRegistry:TriggerEvent("Settings.CategoryChanged")
Check(win.title:IsShown() and win.title:GetText() == L["Window %d"]:format(1) and win2.title:IsShown(), "title above every window")
Check(win2.title._textColor[1] == 1 and win2.title._textColor[3] == 1 and win.title._textColor[3] == 0, "selected window white, others gold")
b = Entry("Segen")
b._scripts.OnEnter(b)
Check(TOOLTIP.lines[#TOOLTIP.lines].text == L["Window %d (Alt-click: select the window in the options.)"]:format(1), "window line instead of footer: " .. Texts())
b._scripts.OnLeave(b)
win.bg._scripts.OnEnter(win.bg)
Check(TOOLTIP.owner == win.bg and TOOLTIP.anchor == "ANCHOR_CURSOR" and TOOLTIP.lines[1].text == L["Window %d"]:format(1)
	and TOOLTIP.lines[2].text == L["Alt-click: select the window in the options."], "background: window tooltip at the cursor")
win.bg._scripts.OnLeave(win.bg)
-- disableTooltips
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(1)
SETTINGS.QNBUFFMOD_W_DISABLETOOLTIPS:SetValue(true)
b = Entry("Segen")
b._scripts.OnEnter(b)
Check(TOOLTIP.aura == nil and TOOLTIP.lines[1].text == L["Window %d"]:format(1) and TOOLTIP.lines[2].text == L["Alt-click: select the window in the options."],
	"disableTooltips with open window page: window tooltip only")
b._scripts.OnLeave(b)
current = cats[APPEARANCE_LABEL]
EventRegistry:TriggerEvent("Settings.CategoryChanged")
Check(win.title:IsShown(), "other window pages show the titles too")
current = nil
EventRegistry:TriggerEvent("Settings.CategoryChanged")
Check(not win.title:IsShown() and not win2.title:IsShown(), "other page: titles gone")
TOOLTIP = { lines = {} }
b._scripts.OnEnter(b)
Check(TOOLTIP.owner == nil, "disableTooltips without window page: no tooltip")
SETTINGS.QNBUFFMOD_W_DISABLETOOLTIPS:SetValue(false)

---------------------------------------------------------------------------
-- dragging and locking (criterion 54)
---------------------------------------------------------------------------
local f = win.frame
Check(win.bg:IsMouseEnabled(), "unlocked: background takes the mouse")
win.bg._scripts.OnMouseDown(win.bg, "LeftButton")
Check(f._moving, "dragging by the background")
f.GetLeft = function() return 300 end
f.GetBottom = function() return 200 end
win.bg._scripts.OnMouseUp(win.bg, "LeftButton")
local pos = bm.db.windows[1].position
Check(not f._moving and pos[1] == "TOPLEFT" and pos[3] == "BOTTOMLEFT" and pos[4] == 300 and pos[5] == 200 + f._h, "release: re-anchored and saved")
b = Entry("Segen")
b._scripts.OnMouseDown(b, "LeftButton")
Check(f._moving, "dragging by the entry")
b._scripts.OnMouseUp(b, "LeftButton")
SETTINGS.QNBUFFMOD_W_LOCKWINDOW:SetValue(true)
Check(not win.bg:IsMouseEnabled() and b:IsMouseEnabled(), "locked, options closed: background without mouse, entries with")
b._scripts.OnMouseDown(b, "LeftButton")
Check(not f._moving, "locked: no dragging by the entry")
current = cats[L["Window"]]
EventRegistry:TriggerEvent("Settings.CategoryChanged")
Check(win.bg:IsMouseEnabled(), "locked, window page open: background takes the mouse")
win.bg._scripts.OnMouseDown(win.bg, "LeftButton")
Check(not f._moving, "locked: no dragging even with options open")
SETTINGS.QNBUFFMOD_W_LOCKWINDOW:SetValue(false)

---------------------------------------------------------------------------
-- Alt-click (criterion 55)
---------------------------------------------------------------------------
IsAltKeyDown = function() return true end
LOG = {}
printed = {}
b = Entry("Segen")
b._scripts.OnMouseDown(b, "LeftButton")
Check(bm.SelectedID() == 1 and printed[1] == L["%s selected."]:format(L["Window %d"]:format(1)) and not f._moving, "Alt-click selects the window and reports it")
local opened = false
for _, line in ipairs(LOG) do if line == "Öffne " .. current.name then opened = true end end
Check(opened, "Alt-click opens the Window page")
Check(SETTINGS.QNBUFFMOD_EDITWINDOW:GetValue() == 1, "selection in the options")
win2.bg._scripts.OnMouseDown(win2.bg, "LeftButton")
Check(bm.SelectedID() == 2 and win2.title._textColor[3] == 1 and win.title._textColor[3] == 0, "Alt-click on the background; title colors follow")
IsAltKeyDown = function() return false end
SettingsPanel:Hide()
Check(not win.title:IsShown(), "settings window closed: titles gone")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
