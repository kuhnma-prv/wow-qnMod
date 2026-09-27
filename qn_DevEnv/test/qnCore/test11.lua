-- Szenario 11: Rahmen in den sichtbaren Bereich holen über qnCore.Visible in den Addons:
-- qnViewPort als Anbieter des Bereichs, qnMeter und qnNumKeyPad (Knopf/Slash, autoVisible,
-- Kampfsperre), qnViewPort-Liste (Rahmen des Bearbeitungsmodus), einheitliche Meldungen.

local chat = {}
local oldAdd = DEFAULT_CHAT_FRAME.AddMessage
function DEFAULT_CHAT_FRAME:AddMessage(msg)
	chat[#chat + 1] = tostring(msg)
	oldAdd(self, msg)
end
local function ChatHas(text)
	for _, m in ipairs(chat) do
		if m:find(text, 1, true) then return true end
	end
	return false
end
SpellFlyout = CreateFrame("Frame", "SpellFlyout")

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
local nkp = LoadAddon("qnNumKeyPad")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local V = qnCore.Visible
local CL = core.L

-- Rahmen mit Lage l, b, w, h (UIParent bei 0,0, Skalierung 1); SetPoint verschiebt ihn
local function Place(f, l, b, w, h)
	f.GetLeft = function() return l end
	f.GetBottom = function() return b end
	f.GetWidth = function() return w end
	f.GetHeight = function() return h end
	f.SetPoint = function(self, p, rel, rp, px, py)
		self._points = self._points or {}
		self._points[#self._points + 1] = { p, rel, rp, px, py }
		local fx, fy = qnCore.AnchorFactors(p)
		local rx, ry = qnCore.AnchorFactors(rp)
		l, b = rx * 1920 + px - fx * w, ry * 1080 + py - fy * h
	end
	return function() return l, b end
end

---------------------------------------------------------------------------
-- qnViewPort liefert den Bereich; keine eigene Schnittstelle mehr
---------------------------------------------------------------------------
local mine, theirs = V.Area(), vp.Layout.GetVisibleAbs()
Check(#mine == #theirs and mine[1].l == theirs[1].l and mine[1].r == theirs[1].r, "Bereich kommt von qnViewPort (Monitore)")
Check(vp.MoveIntoVisible == nil and vp.RegisterLayoutCallback == nil and vp.Layout.MoveIntoVisible == nil and vp.Layout.Notify == nil,
	"qnViewPort: MoveIntoVisible/RegisterLayoutCallback entfallen")
-- Für die folgenden Prüfungen: Bereich = 1920 × 1080
V.SetAreaProvider(function() return { { l = 0, r = 1920, b = 0, t = 1080 } } end)

---------------------------------------------------------------------------
-- qnMeter
---------------------------------------------------------------------------
local mf = meter.Threat.frame
local mpos = Place(mf, 1900, 500, 220, 150)
chat = {}
SlashCmdList.QNMETER("visible")
local l = mpos()
Check(l == 1700 and ChatHas(CL["%s in den sichtbaren Bereich verschoben."]:format(meter.L["Fenster"])), "/qnm visible: verschoben, Meldung: " .. tostring(l))
Check(meter.db.point[3] == 1700 and meter.db.point[4] == 650, ("Lage gespeichert: %s, %s"):format(meter.db.point[3], meter.db.point[4]))
chat = {}
SlashCmdList.QNMETER("visible")
Check(ChatHas(CL["%s liegt bereits im sichtbaren Bereich."]:format(meter.L["Fenster"])), "/qnm visible: schon sichtbar")
-- autoVisible: bei Änderung des Bereichs (qnViewPort) und neuer Fenstergröße
mpos = Place(mf, 1900, 500, 220, 150)
V.Notify() RunTimers()
Check(mpos() == 1900, "autoVisible aus: bleibt")
meter.store:Set("autoVisible", true)
RunTimers()
mpos = Place(mf, 1900, 500, 220, 150)
mf:GetScript("OnDragStop")(mf)
Check(meter.db.point[3] == 1900, "nach dem Ziehen zuerst die gezogene Lage gespeichert")
RunTimers()
Check(mpos() == 1700 and meter.db.point[3] == 1700, "autoVisible: nach dem Ziehen geholt und gespeichert")
mpos = Place(mf, 1900, 500, 220, 150)
vp.ApplyGeometry() RunTimers()
Check(mpos() == 1700, "autoVisible: nach Änderung der Anordnung (qnViewPort meldet)")
mpos = Place(mf, 1900, 500, 220, 150)
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
Check(mpos() == 1700, "autoVisible: nach neuer Fenstergröße")
meter.store:Set("autoVisible", false)

---------------------------------------------------------------------------
-- qnNumKeyPad: geschützte Leiste
---------------------------------------------------------------------------
local bar = nkp.bar
Check(bar:IsProtected(), "Leiste ist geschützt (SecureHandlerStateTemplate)")
local bpos = Place(bar, 1850, 500, 191, 237)
chat = {}
QN_COMBAT = true
SlashCmdList.QNNUMKEYPAD("visible")
QN_COMBAT = false
Check(bpos() == 1850 and ChatHas(CL["%s ist geschützt – im Kampf nicht verschiebbar."]:format(nkp.L["Leiste"])), "/qnnkp visible im Kampf: nicht verschoben, Meldung")
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
chat = {}
SlashCmdList.QNNUMKEYPAD("visible")
l = bpos()
Check(math.abs(l - (1920 - 191)) <= 0.5 and ChatHas(CL["%s in den sichtbaren Bereich verschoben."]:format(nkp.L["Leiste"])), "/qnnkp visible: verschoben: " .. tostring(l))
Check(nkp.db.point == "CENTER" and nkp.db.x == math.floor(1729 + 95.5 - 960 + 0.5), "Lage am eingestellten Anker gespeichert: " .. tostring(nkp.db.x))
nkp.store:Set("autoVisible", true)
RunTimers()
bpos = Place(bar, 1850, 500, 191, 237)
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(math.abs(bpos() - 1729) <= 0.5, "autoVisible: Leiste nach dem Laden geholt (gespeicherter Versatz ganzzahlig)")
bpos = Place(bar, 1850, 500, 191, 237)
QN_COMBAT = true
V.Notify() RunTimers()
Check(bpos() == 1850, "autoVisible im Kampf: nicht angefasst")
QN_COMBAT = false
V.Notify() RunTimers()
Check(math.abs(bpos() - 1729) <= 0.5, "autoVisible nach dem Kampf beim nächsten Anlass")
nkp.store:Set("autoVisible", false)

---------------------------------------------------------------------------
-- qnViewPort: Liste der Rahmen außerhalb, Rahmen des Bearbeitungsmodus
---------------------------------------------------------------------------
local em = CreateFrame("Frame", "TestEditModeFrame", UIParent)
em.system = 1
local epos = Place(em, 1900, 500, 100, 100)
chat = {}
vp.Layout.MoveFrame(em)
Check(epos() == 1820 and ChatHas(CL["%s in den sichtbaren Bereich verschoben."]:format("TestEditModeFrame"))
	and ChatHas(vp.L["Rahmen des Bearbeitungsmodus: gilt bis /reload bzw. bis das Layout neu geladen wird. Dauerhaft: im Bearbeitungsmodus verschieben."]),
	"MoveFrame: verschoben, Hinweis für den Bearbeitungsmodus")
chat = {}
vp.Layout.MoveFrame(em)
Check(#chat == 1 and ChatHas(CL["%s liegt bereits im sichtbaren Bereich."]:format("TestEditModeFrame")), "MoveFrame: schon sichtbar, kein Hinweis")

V.SetAreaProvider(vp.Layout.GetVisibleAbs)
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
