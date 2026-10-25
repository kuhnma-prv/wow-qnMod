-- Scenario 3: qnMarkers - hide Blizzard's raid manager (opt-in): off by default, manager loaded
-- later, only its own regions, panel and tab (the raid frames stay), combat lock, restoring,
-- profiles, both variants of the tab (Classic toggleButton, Mainline toggleButtonForward/Back).

qnCoreCharDB = { layout = "preset:1" }
qnMarkersDB = { settingsVersion = "1.1", profiles = { ["preset:1"] = {} } }

EnableRestrictedEnvironment()
LoadAddon("qnCore")
local mk = LoadAddon("qnMarkers")
FireEvent("PLAYER_LOGIN")
SetEditModeLayout(1)

local function Set(value) SETTINGS.QNMARKERS_HIDERAIDMANAGER:SetValue(value) end

Check(qnMarkersDB.settingsVersion == "1.3" and mk.db.hideRaidManager == false, "current settings version, off by default")
Set(true)
Check(true, "on before the manager exists: no error")

-- Blizzard_CompactRaidFrames loads (Classic variant: raid frames parented to the manager)
local manager = CreateFrame("Frame", "CompactRaidFrameManager", UIParent)
local bg, border = manager:CreateTexture(), manager:CreateTexture()
function manager:GetRegions() return bg, border end
manager:EnableMouse(true)
local display = CreateFrame("Frame", nil, manager)
local option = CreateFrame("Button", nil, display)
option:EnableMouse(true)
function display:GetChildren() return option end
manager.displayFrame = display
local toggle = CreateFrame("Button", nil, manager)
toggle:EnableMouse(true)
manager.toggleButton = toggle
local container = CreateFrame("Frame", "CompactRaidFrameContainer", manager)
container:SetAlpha(0.8)
FireEvent("ADDON_LOADED", "Blizzard_CompactRaidFrames")

Check(bg:GetAlpha() == 0 and border:GetAlpha() == 0, "own regions of the manager transparent")
Check(display:GetAlpha() == 0 and toggle:GetAlpha() == 0, "panel and tab transparent")
Check(not manager:IsMouseEnabled() and not toggle:IsMouseEnabled() and not option:IsMouseEnabled(), "manager, tab and buttons in the panel ignore the mouse")
Check(manager:GetAlpha() == 1 and container:GetAlpha() == 0.8 and manager:IsShown(), "manager alpha and raid frames untouched, nothing hidden")

-- Blizzard sets an alpha again: applied anew on the next group change
toggle:SetAlpha(1)
FireEvent("GROUP_ROSTER_UPDATE")
Check(toggle:GetAlpha() == 0, "applied again after a group change")

-- Combat
QN_COMBAT = true
Set(false)
Check(bg:GetAlpha() == 0 and not toggle:IsMouseEnabled(), "in combat: unchanged")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(bg:GetAlpha() == 1 and toggle:GetAlpha() == 1 and toggle:IsMouseEnabled() and manager:IsMouseEnabled() and option:IsMouseEnabled(),
	"off after combat: alpha and mouse restored")

-- Mainline variant of the tab
manager.toggleButton = nil
local forward, back = CreateFrame("Button", nil, manager), CreateFrame("Button", nil, manager)
forward:EnableMouse(true)
manager.toggleButtonForward, manager.toggleButtonBack = forward, back
Set(true)
Check(forward:GetAlpha() == 0 and back:GetAlpha() == 0 and not forward:IsMouseEnabled(), "Mainline tab buttons hidden too")

-- Profiles: a profile without the option shows the manager
SetEditModeLayout(3)
Check(mk.db.hideRaidManager == true and forward:GetAlpha() == 0, "new layout: copy, still hidden")
Set(false)
Check(forward:GetAlpha() == 1 and forward:IsMouseEnabled(), "off in the new profile: restored")
SetEditModeLayout(1)
Check(forward:GetAlpha() == 0, "back to the first profile: hidden again")
Check(INITIALIZERS.QNMARKERS_HIDERAIDMANAGER ~= nil, "option on the page")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
