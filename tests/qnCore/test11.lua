-- Scenario 11: pulling frames into the visible area via qnCore.Visible in the addons:
-- qnViewPort as area provider, qnMeter and qnNumKeyPad (button/slash, autoVisible,
-- combat lockdown), qnViewPort list (Edit Mode frames), uniform messages.

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

-- frame at position l, b, w, h (UIParent at 0,0, scale 1); SetPoint moves it
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
-- qnViewPort provides the area; no own interface anymore
---------------------------------------------------------------------------
local mine, theirs = V.Area(), vp.Layout.GetVisibleAbs()
Check(#mine == #theirs and mine[1].l == theirs[1].l and mine[1].r == theirs[1].r, "area comes from qnViewPort (monitors)")
Check(vp.MoveIntoVisible == nil and vp.RegisterLayoutCallback == nil and vp.Layout.MoveIntoVisible == nil and vp.Layout.Notify == nil,
	"qnViewPort: MoveIntoVisible/RegisterLayoutCallback removed")
-- for the following checks: area = 1920 × 1080
V.SetAreaProvider(function() return { { l = 0, r = 1920, b = 0, t = 1080 } } end)

---------------------------------------------------------------------------
-- qnMeter
---------------------------------------------------------------------------
local mf = meter.Threat.frame
local mpos = Place(mf, 1900, 500, 220, 150)
chat = {}
SlashCmdList.QNMETER("visible")
local l = mpos()
Check(l == 1700 and ChatHas(CL["%s moved into the visible area."]:format(meter.L["Window"])), "/qnm visible: moved, message: " .. tostring(l))
Check(meter.db.point[3] == 1700 and meter.db.point[4] == 650, ("position saved: %s, %s"):format(meter.db.point[3], meter.db.point[4]))
chat = {}
SlashCmdList.QNMETER("visible")
Check(ChatHas(CL["%s is already in the visible area."]:format(meter.L["Window"])), "/qnm visible: already visible")
-- autoVisible: on area change (qnViewPort) and new window size
mpos = Place(mf, 1900, 500, 220, 150)
V.Notify() RunTimers()
Check(mpos() == 1900, "autoVisible off: stays")
meter.store:Set("autoVisible", true)
RunTimers()
mpos = Place(mf, 1900, 500, 220, 150)
mf:GetScript("OnDragStop")(mf)
Check(meter.db.point[3] == 1900, "after dragging the dragged position is saved first")
RunTimers()
Check(mpos() == 1700 and meter.db.point[3] == 1700, "autoVisible: pulled in and saved after dragging")
mpos = Place(mf, 1900, 500, 220, 150)
vp.ApplyGeometry() RunTimers()
Check(mpos() == 1700, "autoVisible: after arrangement change (qnViewPort notifies)")
mpos = Place(mf, 1900, 500, 220, 150)
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
Check(mpos() == 1700, "autoVisible: after new window size")
meter.store:Set("autoVisible", false)

---------------------------------------------------------------------------
-- qnNumKeyPad: protected bar
---------------------------------------------------------------------------
local bar = nkp.bar
Check(bar:IsProtected(), "bar is protected (SecureHandlerStateTemplate)")
local bpos = Place(bar, 1850, 500, 191, 237)
chat = {}
QN_COMBAT = true
SlashCmdList.QNNUMKEYPAD("visible")
QN_COMBAT = false
Check(bpos() == 1850 and ChatHas(CL["%s is protected – cannot be moved in combat."]:format(nkp.L["Bar"])), "/qnnkp visible in combat: not moved, message")
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
chat = {}
SlashCmdList.QNNUMKEYPAD("visible")
l = bpos()
Check(math.abs(l - (1920 - 191)) <= 0.5 and ChatHas(CL["%s moved into the visible area."]:format(nkp.L["Bar"])), "/qnnkp visible: moved: " .. tostring(l))
Check(nkp.db.point == "CENTER" and nkp.db.x == math.floor(1729 + 95.5 - 960 + 0.5), "position saved at the configured anchor: " .. tostring(nkp.db.x))
nkp.store:Set("autoVisible", true)
RunTimers()
bpos = Place(bar, 1850, 500, 191, 237)
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(math.abs(bpos() - 1729) <= 0.5, "autoVisible: bar pulled in after loading (saved offset is an integer)")
bpos = Place(bar, 1850, 500, 191, 237)
QN_COMBAT = true
V.Notify() RunTimers()
Check(bpos() == 1850, "autoVisible in combat: not touched")
QN_COMBAT = false
V.Notify() RunTimers()
Check(math.abs(bpos() - 1729) <= 0.5, "autoVisible after combat on the next occasion")
nkp.store:Set("autoVisible", false)

---------------------------------------------------------------------------
-- qnViewPort: list of frames outside, Edit Mode frames
---------------------------------------------------------------------------
local em = CreateFrame("Frame", "TestEditModeFrame", UIParent)
em.system = 1
local epos = Place(em, 1900, 500, 100, 100)
chat = {}
vp.Layout.MoveFrame(em)
Check(epos() == 1820 and ChatHas(CL["%s moved into the visible area."]:format("TestEditModeFrame"))
	and ChatHas(vp.L["Edit Mode frame: lasts until /reload or until the layout is reloaded. To keep it: move it in Edit Mode."]),
	"MoveFrame: moved, hint for Edit Mode")
chat = {}
vp.Layout.MoveFrame(em)
Check(#chat == 1 and ChatHas(CL["%s is already in the visible area."]:format("TestEditModeFrame")), "MoveFrame: already visible, no hint")

V.SetAreaProvider(vp.Layout.GetVisibleAbs)
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
