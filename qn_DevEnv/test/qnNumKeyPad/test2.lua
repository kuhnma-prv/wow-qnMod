-- Szenario 2: qnNumKeyPad – Ziehsperre sicher umhüllt (kein SetScript auf Blizzards OnDragStart,
-- Sperre auch im Kampf), Ankerwechsel im Kampf (Leiste springt nach dem Kampf nicht), Ausblenden
-- setzt die Deckkraft nur bei Änderung, kein eigener UpdateFlyout-Aufruf.

EnableRestrictedEnvironment()
SpellFlyout = CreateFrame("Frame", "SpellFlyout")
SpellFlyout:Hide()

-- Tasten wie ActionBarButtonTemplate: geschützt (erbt SecureActionButtonTemplate), Blizzards
-- OnDragStart nimmt die Aktion auf; eigene SetScript-Aufrufe und UpdateFlyout mitschreiben
local picked, setScripts, flyoutUpdates = {}, {}, 0
local created = {}
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
	local f = create(kind, name, parent, template, ...)
	created[#created + 1] = f
	if template == "ActionBarButtonTemplate" then
		f._protected = true
		f._scripts.OnDragStart = function(self) picked[#picked + 1] = self:GetName() end
		f.UpdateFlyout = function() flyoutUpdates = flyoutUpdates + 1 end
		local setScript = f.SetScript
		f.SetScript = function(self, s, fn)
			setScripts[#setScripts + 1] = s
			setScript(self, s, fn)
		end
	end
	return f
end
QN_MODIFIED = false
function IsModifiedClick(what) return what == "PICKUPACTION" and QN_MODIFIED end
function UnitAffectingCombat(unit) return unit == "player" and QN_COMBAT or false end

local core = LoadAddon("qnCore")
local nkp = LoadAddon("qnNumKeyPad")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local bar = nkp.bar
local function Set(key, value)
	SETTINGS["QNNKP_" .. key:upper()]:SetValue(value)
end
local function Combat(on)
	QN_COMBAT = on
	FireEvent(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
end

---------------------------------------------------------------------------
-- Befund 1: Ziehsperre
---------------------------------------------------------------------------
local b1 = qnNumKeyPadButton1
local function Drag()
	picked = {}
	b1:GetScript("OnDragStart")(b1, "LeftButton")
	return #picked == 1
end
local hasSetScript = false
for _, s in ipairs(setScripts) do
	if s == "OnDragStart" then hasSetScript = true end
end
Check(not hasSetScript, "kein SetScript(\"OnDragStart\") auf den Tasten")
Check(WRAPPED[b1] and WRAPPED[b1].OnDragStart and WRAPPED[b1].OnDragStart.header == bar, "OnDragStart sicher umhüllt, Kopf = Leiste")
Check(nkp.db.lockActions == false and nkp.db.lockInCombat == true, "Vorgaben: nur im Kampf gesperrt")
Check(Drag(), "außerhalb des Kampfes: Blizzards Handler nimmt auf")
Combat(true)
Check(not Drag(), "im Kampf: gesperrt")
QN_MODIFIED = true
Check(Drag(), "im Kampf mit Taste für 'Aktion aufnehmen': Blizzards Handler nimmt auf")
QN_MODIFIED = false
Set("lockInCombat", false)   -- im Kampf aufgeschoben (Attribut der Leiste)
Check(not Drag(), "Änderung im Kampf wirkt erst nach dem Kampf")
Combat(false)
Combat(true)
Check(Drag(), "lockInCombat aus: im Kampf frei")
Combat(false)
Set("lockActions", true)
Check(not Drag(), "lockActions: außerhalb des Kampfes gesperrt")
QN_MODIFIED = true
Check(Drag(), "lockActions mit Taste für 'Aktion aufnehmen': frei")
QN_MODIFIED = false
Set("lockActions", false)
Set("lockInCombat", true)
Check(Drag(), "zurückgesetzt: außerhalb des Kampfes frei")

---------------------------------------------------------------------------
-- Befund 3: Ankerwechsel im Kampf
---------------------------------------------------------------------------
bar.GetLeft = function() return 100 end
bar.GetBottom = function() return 200 end
Set("point", "TOPLEFT")
Check(nkp.db.x == 100 and nkp.db.y == -643, ("außerhalb des Kampfes sofort umgerechnet (%s, %s)"):format(nkp.db.x, nkp.db.y))
local placed = {}
local setPoint = bar.SetPoint
bar.SetPoint = function(self, p, rel, rp, x, y)
	placed[#placed + 1] = { p, x, y }
	return setPoint(self, p, rel, rp, x, y)
end
Combat(true)
Set("scale", 1.1)            -- wartet vor dem Ankerwechsel (ns.Apply)
Set("point", "BOTTOMRIGHT")
Check(#placed == 0 and nkp.db.x == 100 and nkp.db.y == -643, "im Kampf: Leiste unberührt, Versätze noch alt")
Combat(false)
local jumped = false
for _, p in ipairs(placed) do
	if p[1] == "BOTTOMRIGHT" and p[2] == 100 then jumped = true end
end
local last = placed[#placed]
Check(not jumped, "nach dem Kampf nicht mit neuem Anker und alten Versätzen gesetzt")
-- SetPoint in Einheiten der Leiste (Skalierung 1.1): Versätze durch die Skalierung geteilt
Check(nkp.db.x == -1629 and nkp.db.y == 200 and last and last[1] == "BOTTOMRIGHT"
	and math.abs(last[2] - -1629 / 1.1) < 1e-6 and math.abs(last[3] - 200 / 1.1) < 1e-6,
	("nach dem Kampf umgerechnet und gesetzt (%s, %s)"):format(nkp.db.x, nkp.db.y))
Set("scale", 1)
nkp.ResetPosition()

---------------------------------------------------------------------------
-- Befund 6: Ausblenden, UpdateFlyout
---------------------------------------------------------------------------
local fader
for _, f in ipairs(created) do
	if f:GetScript("OnUpdate") and f:GetParent() == nil and f:GetScript("OnShow") then
		fader = f
	end
end
Check(fader ~= nil, "Ausblend-Rahmen gefunden")
local alphas = {}
local setAlpha = bar.SetAlpha
bar.SetAlpha = function(self, a)
	alphas[#alphas + 1] = a
	setAlpha(self, a)
end
Set("locked", true)
Set("fadeAlpha", 0.25)
Set("fade", true)
alphas = {}
local tick = fader:GetScript("OnUpdate")
for _ = 1, 5 do
	AdvanceTime(0.1)
	tick(fader, 0.1)
end
Check(#alphas == 1 and alphas[1] == 0.25, "Deckkraft nur einmal gesetzt: " .. #alphas)
Set("fadeAlpha", 0.5)
alphas = {}
tick(fader, 0.1)
tick(fader, 0.1)
Check(#alphas == 1 and alphas[1] == 0.5, "neuer Wert: einmal gesetzt")
Set("fade", false)
Check(bar:GetAlpha() == 1, "ohne Ausblenden volle Deckkraft")
Set("fade", true)
alphas = {}
tick(fader, 0.1)
Check(#alphas == 1 and alphas[1] == 0.5, "nach erneutem Einschalten wieder gesetzt")

flyoutUpdates = 0
Set("flyout", "DOWN")
nkp.ApplyAll()
Check(flyoutUpdates == 0 and b1:GetAttribute("flyoutDirection") == "DOWN", "kein eigener UpdateFlyout-Aufruf, Richtung als Attribut")
Check(b1.Border:IsShown() == false, "UpdateLook ohne action-Prüfung")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
