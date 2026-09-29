-- Scenario 1: qnViewPort background patterns (dropdown, opacity, profile switch, LSM)
local textures, sliders, dropdowns = {}, {}, {}
local origCreateFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
	local f = origCreateFrame(kind, name, parent, template)
	if template == "MinimalSliderWithSteppersTemplate" then sliders[#sliders + 1] = f end
	if template == "WowStyle1DropdownTemplate" then dropdowns[#dropdowns + 1] = f end
	local ct = f.CreateTexture
	f.CreateTexture = function(self, ...)
		local t = ct(self, ...)
		t.SetTexture = function(s, file, h, v) s._file, s._wrap = file, h end
		t.SetAlpha = function(s, a) s._alpha = a end
		textures[#textures + 1] = t
		return t
	end
	return f
end

-- LibSharedMedia stand-in: an own pattern, a copy of a Blizzard pattern (different spelling),
-- a full-screen overlay and pure white; loaded only after qnCore (as with Titan)
local lsmNames, lsmData = {}, {}
local lsm = {
	Register = function(_, kind, n, file)
		if lsmData[n] == nil then lsmNames[#lsmNames + 1] = n end
		lsmData[n] = file
	end,
	List = function(_, kind) return lsmNames end,
	IsValid = function(_, kind, n) return lsmData[n] ~= nil end,
	Fetch = function(_, kind, n) return lsmData[n] end,
}
lsm:Register("background", "Mein Muster", "Interface\\AddOns\\X\\muster")
lsm:Register("background", "None", "")
lsm:Register("background", "Blizzard Rock", "Interface/FrameGeneral/UI-Background-ROCK")
lsm:Register("background", "Blizzard Low Health", "Interface\\FullScreenTextures\\LowHealth")
lsm:Register("background", "Solid", "Interface\\Buttons\\WHITE8X8")
local lsmReady = false
LibStub = function(name, silent)
	return name == "LibSharedMedia-3.0" and lsmReady and lsm or nil
end

local core = LoadAddon("qnCore")
local qnCount = #qnCore.Patterns
Check(qnCount == 10 and lsmData["qn Stripes"] == nil, "qnCore: 10 own patterns, LSM not there yet")
lsmReady = true
local vp = LoadAddon("qnViewPort")
Check(lsmData["qn Stripes"] == "Interface\\AddOns\\qnCore\\Media\\Patterns\\Stripes"
	and lsmData["qn Grain"] ~= nil, "qnCore patterns registered with LSM (ADDON_LOADED)")
Check(#vp.PATTERNS == 8 + qnCount, "qnViewPort: 8 Blizzard + qnCore patterns")
-- files of the own patterns present
for _, p in ipairs(qnCore.Patterns) do
	local path = ADDONS .. "/" .. p[3]:gsub("^Interface\\AddOns\\", ""):gsub("\\", "/") .. ".tga"
	if not READFILE(path) then Check(false, "file missing: " .. path) end
end
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)

local function Patterns()
	local list = {}
	for _, t in ipairs(textures) do if t._wrap == "REPEAT" then list[#list + 1] = t end end
	return list
end

Check(vp.db.pattern == "none" and vp.db.patternAlpha == 0.5, "defaults: no pattern, 50 %")
local L = vp.L
local dd, slider
for _, d in ipairs(dropdowns) do if d._text == L["No pattern (color only)"] then dd = d end end
for _, s in ipairs(sliders) do if s._value == 50 then slider = s end end
print("Dropdowns/sliders:", #dropdowns, #sliders)
Check(dd and slider, "dropdown and slider created")
-- entries: no pattern + own list + 1 LSM (None, copies of Rock and qnCore patterns,
-- full-screen and white left out)
local lsmIndex = 1 + #vp.PATTERNS + 1
Check(#dd._radios == lsmIndex, lsmIndex .. " entries in the dropdown (" .. #dd._radios .. ")")
Check(dd._text == L["No pattern (color only)"], "display: no pattern")
dd:PickRadio(2)
Check(vp.db.pattern == "rock", "Rock selected")
Check(dd._text == L["Rock"], "display: Rock")
local p = Patterns()
Check(#p == 4 and p[1]._file == "Interface\\FrameGeneral\\UI-Background-Rock" and p[1]._wrap == "REPEAT", "four border areas tiled with Rock")
Check(slider._enabled == true, "slider enabled")
slider:SetValue(30)
Check(vp.db.patternAlpha == 0.3 and p[1]._alpha == 0.3, "opacity 30 %")
dd:PickRadio(10)
Check(vp.db.pattern == "qnStripes" and p[1]._file == qnCore.Patterns[1][3], "qnCore pattern Stripes")
Check(dd._text == qnCore.Patterns[1][2], "display: Stripes")
dd:PickRadio(lsmIndex)
Check(vp.db.pattern == "lsm:Mein Muster" and p[1]._file == "Interface\\AddOns\\X\\muster", "LSM pattern")
-- profile switch: new layout = copy; switching back shows old values
SetEditModeLayout(4)
Check(vp.db.pattern == "lsm:Mein Muster", "copy takes over the pattern")
dd:PickRadio(1)
Check(vp.db.pattern == "none" and slider._enabled == false, "no pattern: slider disabled")
SetEditModeLayout(3)
vp.RefreshOptions()
Check(vp.db.pattern == "lsm:Mein Muster" and vp.db.patternAlpha == 0.3, "back: the profile's pattern")
-- unknown pattern (LSM addon missing): no error, pattern hidden
vp.db.pattern = "lsm:Gibt es nicht"
vp.UpdateBorderLook()
Check(true, "missing pattern without error")
-- previously selected LSM copies become the own entry (otherwise not findable in the dropdown)
vp.db.pattern = "lsm:Blizzard Rock"
vp.UpdateBorderLook()
Check(vp.db.pattern == "rock", "lsm:Blizzard Rock -> rock")
vp.db.pattern = "lsm:qn Dots"
vp.UpdateBorderLook()
Check(vp.db.pattern == "qnDots" and p[1]._file == qnCore.Patterns[4][3], "lsm:qn Dots -> qnDots")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
