-- Szenario 1: qnViewPort-Hintergrundmuster (Dropdown, Deckkraft, Profilwechsel, LSM)
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

-- LibSharedMedia-Ersatz mit einem Muster
local lsmData = { ["Mein Muster"] = "Interface\\AddOns\\X\\muster", None = "" }
LibStub = function(name, silent)
	if name ~= "LibSharedMedia-3.0" then return nil end
	return {
		List = function(_, kind) return { "Mein Muster", "None" } end,
		IsValid = function(_, kind, n) return lsmData[n] ~= nil end,
		Fetch = function(_, kind, n) return lsmData[n] end,
	}
end

local core = LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)

local function Patterns()
	local list = {}
	for _, t in ipairs(textures) do if t._wrap == "REPEAT" then list[#list + 1] = t end end
	return list
end

Check(vp.db.pattern == "none" and vp.db.patternAlpha == 0.5, "Vorgaben: kein Muster, 50 %")
local L = vp.L
local dd, slider
for _, d in ipairs(dropdowns) do if d._text == L["Kein Muster (nur Farbe)"] then dd = d end end
for _, s in ipairs(sliders) do if s._value == 50 then slider = s end end
print("Dropdowns/Regler:", #dropdowns, #sliders)
Check(dd and slider, "Dropdown und Regler angelegt")
-- Einträge: kein Muster + 8 Blizzard + 1 LSM (None ausgelassen)
Check(#dd._radios == 10, "10 Einträge im Dropdown (" .. #dd._radios .. ")")
Check(dd._text == L["Kein Muster (nur Farbe)"], "Anzeige: kein Muster")
dd:PickRadio(2)
Check(vp.db.pattern == "rock", "Fels gewählt")
Check(dd._text == L["Fels"], "Anzeige: Fels")
local p = Patterns()
Check(#p == 4 and p[1]._file == "Interface\\FrameGeneral\\UI-Background-Rock" and p[1]._wrap == "REPEAT", "vier Randflächen gekachelt mit Fels")
Check(slider._enabled == true, "Regler aktiv")
slider:SetValue(30)
Check(vp.db.patternAlpha == 0.3 and p[1]._alpha == 0.3, "Deckkraft 30 %")
dd:PickRadio(10)
Check(vp.db.pattern == "lsm:Mein Muster" and p[1]._file == "Interface\\AddOns\\X\\muster", "LSM-Muster")
-- Profilwechsel: neues Layout = Kopie; zurück zeigt alte Werte
SetEditModeLayout(4)
Check(vp.db.pattern == "lsm:Mein Muster", "Kopie übernimmt Muster")
dd:PickRadio(1)
Check(vp.db.pattern == "none" and slider._enabled == false, "kein Muster: Regler aus")
SetEditModeLayout(3)
vp.RefreshOptions()
Check(vp.db.pattern == "lsm:Mein Muster" and vp.db.patternAlpha == 0.3, "zurück: Muster des Profils")
-- unbekanntes Muster (LSM-Addon fehlt): kein Fehler, Muster verborgen
vp.db.pattern = "lsm:Gibt es nicht"
vp.UpdateBorderLook()
Check(true, "fehlendes Muster ohne Fehler")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
