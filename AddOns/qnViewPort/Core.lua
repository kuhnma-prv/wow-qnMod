-- qnViewPort: shrinks the area in which the 3D world is rendered.
-- For WoW Classic Forever; profiles and helper functions from qnCore.
-- Core: settings, applying to WorldFrame, border color and pattern, slash commands.

local ADDON, ns = ...
_G.qnViewPort = ns

local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

-- Offsets in screen pixels: left, right, top, bottom
ns.defaults = {
	viewport = { 0, 0, 0, 0 },
	color = { 0, 0, 0, 1 },
	pattern = "none",      -- background pattern over the color: "none", key from ns.PATTERNS or "lsm:<name>"
	patternAlpha = 0.5,    -- pattern opacity (0–1)
	suppressMessage = false,
	-- Second monitor (SecondScreen.lua); sizes in screen pixels
	dual = {
		enabled = false,
		side = "RIGHT",        -- position of the 2nd monitor next to the main monitor: "RIGHT" or "LEFT"
		width = 1920,
		height = 1200,
		offsetY = 0,           -- distance of the 2nd monitor's top edge from the window's top edge
		bags = false,          -- move bags to a monitor corner when opened
		bagsMonitor = 0,       -- 0 = main monitor, otherwise the number as on the "Monitors" page
		bagsPoint = "BOTTOMRIGHT",
		bagsOffsetX = 130,     -- distance from the vertical edge of the corner (pixels)
		bagsOffsetY = 330,     -- distance from the horizontal edge of the corner (pixels), e.g. room for bars
		zoneMap = false,       -- move the Zone Map (BattlefieldMapFrame) to a monitor corner when shown
		zoneMapMonitor = 0,
		zoneMapPoint = "TOPRIGHT",
		zoneMapOffsetX = 20,
		zoneMapOffsetY = 300,
		zoneMapScale = 1,      -- size of the Zone Map including its tab (1 = 100 %, then qnViewPort leaves it alone)
		worldMap = false,      -- put the maximized World Map on one monitor (instead of across the whole window)
		worldMapMonitor = 0,
		questLog = false,      -- put the minimized World Map ("Map & Quest Log") on one monitor
		questLogMonitor = 0,
		mapFollowZone = true,
		mapAutoOpen = false,
		mapNoFade = false,     -- mapFade = 0; the previous value is then kept in ns.global.mapFadeSaved
		clock = false,         -- open the clock window (TimeManagerFrame) below the clock on its monitor
		guides = false,
		useMonitorData = true, -- use Monitors.lua (scripts\) instead of the values above
	},
	-- Titan Panel (Titan.lua): monitor per full-width bar, 0 = as Titan (entire UI)
	titan = {
		Bar = 0,
		Bar2 = 0,
		AuxBar = 0,
		AuxBar2 = 0,
		scale = {},   -- [monitor number] = factor (1 = 100 %)
	},
}

-- Account-wide (qnViewPortDB.global, ns.global), not per profile: belongs to the computer or the client.
local GLOBAL_DEFAULTS = {
	layoutKey = "",        -- monitor layout last applied automatically (Layout.Refresh)
	-- mapFadeSaved: value of the CVar mapFade before "Do not fade the map while moving" (nil = nothing saved)
}

-- Dual monitor mode settings in the active profile (Layout.lua, SecondScreen.lua)
function ns.DualDB()
	return ns.db.dual
end

-- Version of the settings (see qnCore.Migrate)
local SETTINGS_VERSION = "1.1"

---------------------------------------------------------------------------
-- Screen size
---------------------------------------------------------------------------

ns.screen = { 1920, 1080 }

-- Frame without a parent covering the whole game window, scale 1. Reference for all
-- conversions – UIParent no longer works for that because Layout.lua may shrink it.
local screenRef = CreateFrame("Frame")
screenRef:SetAllPoints()
ns.screenRef = screenRef

-- Units per screen pixel at effective scale 1 (x, y)
function ns.UnitsPerPixel()
	local w, h = screenRef:GetWidth(), screenRef:GetHeight()
	if not (w and h and w > 0 and h > 0) then
		-- not laid out yet: UIParent has not been shrunk at this point
		w, h = UIParent:GetWidth() * UIParent:GetScale(), UIParent:GetHeight() * UIParent:GetScale()
	end
	return w / ns.screen[1], h / ns.screen[2]
end

-- Size of the game window; before the first draw it can still be 0, then the screen size.
function ns.UpdateScreenSize()
	local size = C_VideoOptions.GetCurrentGameWindowSize()
	if size and size.x > 0 and size.y > 0 then
		ns.screen = { size.x, size.y }
		return
	end
	local x, y = GetPhysicalScreenSize()
	if x > 0 and y > 0 then
		ns.screen = { x, y }
	end
end

-- Clamps the offsets: each side >= 0, opposite sides together
-- at most half the screen width or height (several monitors: 7/8, see below).
-- changedH/changedV = side changed last per axis (1/2 or 3/4); it is cut first.
function ns.Clamp(v, changedH, changedV)
	local w, h = ns.screen[1], ns.screen[2]
	local out = {}
	for i = 1, 4 do
		out[i] = math.max(0, math.floor((tonumber(v[i]) or 0) + 0.5))
	end
	local function Pair(a, b, limit, changed)
		local excess = out[a] + out[b] - limit
		if excess > 0 then
			local first = (changed == b) and b or a
			local second = (first == a) and b or a
			local cut = math.min(excess, out[first])
			out[first] = out[first] - cut
			out[second] = out[second] - (excess - cut)
		end
	end
	-- Across several monitors (dual monitor mode or monitor data; Layout.Refresh then puts the world
	-- on the main monitor even without the mode) the world may be narrower than half the window width
	-- (e.g. small main monitor, large second monitor); at least 1/8 remains.
	local data = ns.Layout.Active()
	local wide = ns.db.dual.enabled or (data and #data.monitors > 1)
	Pair(1, 2, wide and math.floor(w * 7 / 8) or math.floor(w / 2), changedH)
	Pair(3, 4, wide and math.floor(h * 7 / 8) or math.floor(h / 2), changedV)
	return out
end

---------------------------------------------------------------------------
-- Border areas outside the world
---------------------------------------------------------------------------

local border = CreateFrame("Frame")
border:SetFrameStrata("BACKGROUND")
border:SetFrameLevel(0)
border:SetAllPoints()
border:Hide()

-- One color area per edge, with a tiled pattern area on top at the same points
local edges, patterns = {}, {}
for i = 1, 4 do
	edges[i] = border:CreateTexture(nil, "BACKGROUND", nil, -7)
	patterns[i] = border:CreateTexture(nil, "BACKGROUND", nil, -6)
	patterns[i]:SetAllPoints(edges[i])
	patterns[i]:Hide()
end
local eLeft, eRight, eTop, eBottom = edges[1], edges[2], edges[3], edges[4]
eLeft:SetPoint("RIGHT", WorldFrame, "LEFT")
eLeft:SetPoint("TOP", WorldFrame)
eLeft:SetPoint("BOTTOM", WorldFrame)
eRight:SetPoint("LEFT", WorldFrame, "RIGHT")
eRight:SetPoint("TOP", WorldFrame)
eRight:SetPoint("BOTTOM", WorldFrame)
eTop:SetPoint("LEFT", eLeft)
eTop:SetPoint("RIGHT", eRight)
eTop:SetPoint("BOTTOM", WorldFrame, "TOP")
eBottom:SetPoint("LEFT", eLeft)
eBottom:SetPoint("RIGHT", eRight)
eBottom:SetPoint("TOP", WorldFrame, "BOTTOM")

function ns.SetBorderColor(c)
	c = c or ns.defaults.color
	for _, tex in ipairs(edges) do
		tex:SetColorTexture(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1)
	end
end

-- Tileable Blizzard textures (used with horizTile/vertTile in the Forever source)
ns.PATTERNS = {
	{ "rock", L["Rock"], "Interface\\FrameGeneral\\UI-Background-Rock" },
	{ "marble", L["Marble"], "Interface\\FrameGeneral\\UI-Background-Marble" },
	{ "wood", L["Wood"], "Interface\\BlackMarket\\BlackMarketBackground-Tile" },
	{ "dialog", L["Dialog"], "Interface\\DialogFrame\\UI-DialogBox-Background" },
	{ "dialogDark", L["Dialog (dark)"], "Interface\\DialogFrame\\UI-DialogBox-Background-Dark" },
	{ "tooltip", L["Tooltip"], "Interface\\Tooltips\\UI-Tooltip-Background" },
	{ "parchment", L["Parchment"], "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal" },
	{ "achievement", ACHIEVEMENTS, "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground" },
}
-- followed by our own patterns from qnCore
for _, p in ipairs(lib.Patterns) do
	ns.PATTERNS[#ns.PATTERNS + 1] = { p[1], p[2], p[3] }
end

local function LSM()
	return LibStub and LibStub("LibSharedMedia-3.0", true)
end

-- Comparable file path: case and separators make no difference to WoW
local function FileKey(file)
	return type(file) == "string" and file:lower():gsub("/", "\\") or nil
end

-- LSM backgrounds that are useless as tiled patterns: fullscreen overlays and plain white
-- (the color is chosen separately)
local function Unsuitable(fileKey)
	return fileKey == "" or fileKey:find("^interface\\fullscreentextures\\")
		or fileKey == "interface\\buttons\\white8x8"
end

-- Choice list for the dropdown: { key, text }; patterns from LibSharedMedia (if present)
-- after that, without files that are already in the list
function ns.PatternChoices()
	local list = { { "none", L["No pattern (color only)"] } }
	local seen = {}
	for _, p in ipairs(ns.PATTERNS) do
		list[#list + 1] = { p[1], p[2] }
		seen[FileKey(p[3])] = true
	end
	local lsm = LSM()
	if lsm then
		for _, name in ipairs(lsm:List("background")) do
			local key = FileKey(lsm:Fetch("background", name))
			if key and not seen[key] and not Unsuitable(key) then
				seen[key] = true
				list[#list + 1] = { "lsm:" .. name, name .. " |cff999999(LSM)|r" }
			end
		end
	end
	return list
end

local function PatternFile(key)
	for _, p in ipairs(ns.PATTERNS) do
		if p[1] == key then
			return p[3]
		end
	end
	local name = type(key) == "string" and key:match("^lsm:(.+)$")
	local lsm = name and LSM()
	return lsm and lsm:IsValid("background", name) and lsm:Fetch("background", name) or nil
end

function ns.SetBorderPattern(key, alpha)
	local file = PatternFile(key)
	for _, tex in ipairs(patterns) do
		if file then
			tex:SetTexture(file, "REPEAT", "REPEAT")
			tex:SetHorizTile(true)
			tex:SetVertTile(true)
			tex:SetAlpha(alpha or ns.defaults.patternAlpha)
			tex:Show()
		else
			tex:Hide()
		end
	end
end

-- Color and pattern of the active profile
function ns.UpdateBorderLook()
	ns.SetBorderColor(ns.db.color)
	ns.SetBorderPattern(ns.db.pattern, ns.db.patternAlpha)
end

local function UpdateBorder(l, t, r, b)
	if l > 0 or t > 0 or r > 0 or b > 0 then
		eLeft:SetPoint("LEFT", WorldFrame, -l, 0)
		eRight:SetPoint("RIGHT", WorldFrame, r, 0)
		eTop:SetPoint("TOP", WorldFrame, 0, t)
		eBottom:SetPoint("BOTTOM", WorldFrame, 0, -b)
		border:Show()
	else
		border:Hide()
	end
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------

-- Methods of the widget class, not WorldFrame's (hooked) fields.
-- That way our own calls do not trigger the hooks again.
local dummy = CreateFrame("Frame")
local FrameClearAllPoints, FrameSetPoint = dummy.ClearAllPoints, dummy.SetPoint
ns.FrameClearAllPoints, ns.FrameSetPoint = FrameClearAllPoints, FrameSetPoint

local current   -- last applied (clamped) offsets; may differ from the saved value
local Reapply

-- Sets WorldFrame to the offsets v (screen pixels) without saving.
-- In combat (WorldFrame protected) only afterwards, with the value current at that time.
function ns.SetWorldFrame(v)
	if WorldFrame:IsProtected() and lib.DeferInCombat(Reapply) then
		return
	end
	-- WorldFrame has no parent; its units match screenRef (scale 1).
	local ux, uy = ns.UnitsPerPixel()
	local l, r = v[1] * ux, v[2] * ux
	local t, b = v[3] * uy, v[4] * uy
	FrameClearAllPoints(WorldFrame)
	FrameSetPoint(WorldFrame, "TOPLEFT", l, -t)
	FrameSetPoint(WorldFrame, "BOTTOMRIGHT", -r, b)
	UpdateBorder(l, t, r, b)
end

-- Applies the offsets clamped without saving them (load, window size, profile switch):
-- that way the saved value is kept even if the window is temporarily smaller.
function ns.ShowViewport(v)
	current = ns.Clamp(v)
	ns.SetWorldFrame(current)
	ns.OnViewportChanged(current)
	return current
end

-- Player input: apply clamped and save.
function ns.ApplyViewport(v)
	ns.db.viewport = ns.ShowViewport(v)
end

-- Applied offsets (for the options page)
function ns.GetViewport()
	return current or ns.db.viewport
end

Reapply = function()
	if current then
		ns.SetWorldFrame(current)
	end
end

-- Reapply viewport, interface and placement areas (load, window size, profile switch).
-- Only a newly applied monitor layout is saved in the process (Layout.Refresh).
function ns.ApplyGeometry()
	ns.UpdateScreenSize()
	if ns.db.dual.enabled and not ns.Layout.Active() then
		-- without monitor data: compute the viewport from the manual settings
		ns.ShowViewport(ns.Dual.GetViewport())
	else
		ns.ShowViewport(ns.db.viewport)
	end
	ns.Layout.Refresh()
	-- recompute the explicitly chosen interface constraint for the new size or scale
	ns.Layout.ReapplyUI()
	ns.Dual.ApplyAll()
end

-- After a profile switch (qnCore): apply all settings of the new profile.
-- Moves Blizzard frames only if the profile explicitly asks for it (bags, zoneMap).
function ns.ApplyProfile()
	ns.EndKeep()
	ns.UpdateBorderLook()
	-- The interface constraint only applies in dual monitor mode
	if not ns.db.dual.enabled then
		ns.Layout.ReleaseUI()
	end
	ns.ApplyGeometry()
	ns.Dual.ApplyMapFade()
	ns.Dual.RefreshOptions()
	ns.RefreshOptions()
	ns.Titan.Apply()
end

function ns.IsActive()
	local v = ns.db.viewport
	return v[1] ~= 0 or v[2] ~= 0 or v[3] ~= 0 or v[4] ~= 0
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

-- msg unshortened: it contains the four offsets as raw numbers
lib.RegisterSlash("QNVIEWPORT", { "/qnvp", "/qnviewport", "/viewport" }, function(cmd, rest, msg)
	local l, r, t, b = msg:match("^(%d+%.?%d*)%s+(%d+%.?%d*)%s+(%d+%.?%d*)%s+(%d+%.?%d*)$")
	if l then
		local v = { tonumber(l), tonumber(r), tonumber(t), tonumber(b) }
		if v[1] + v[2] + v[3] + v[4] > 0 then
			ns.OpenOptions()
			ns.ApplyWithConfirm(v)
		else
			ns.EndKeep()
			ns.ApplyViewport(v)
			ns.Print(L["Viewport reset."])
		end
	elseif msg == "" then
		ns.OpenOptions()
	elseif cmd == "dual" then
		ns.Dual.Slash(rest)
	elseif not ns.Layout.Slash(msg:lower()) then
		-- one key; Print outputs each line as its own chat line
		ns.Print(L["/qnvp – open options\n/qnvp 0 0 0 0 – reset viewport\n/qnvp L R T B – set offsets in pixels (left, right, top, bottom)\n/qnvp dual – second monitor (/qnvp dual help)\n/qnvp monitors – show monitor data\n/qnvp check – find frames outside the monitors (to move them: Options → Monitors)"])
	end
end)

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

local events = ns.events

ns.OnLoad(function()
	-- Settings per profile (= Edit Mode layout, qnCore); ns.db is always the active profile.
	local store = lib.Profiles.Register({
		ns = ns,
		sv = "qnViewPortDB",
		settingsVersion = SETTINGS_VERSION,
		defaults = ns.defaults,
		onSwitch = ns.ApplyProfile,
	})
	ns.global = lib.MergeDefaults(store.global, GLOBAL_DEFAULTS)
	ns.UpdateBorderLook()

	-- Blizzard resets WorldFrame e.g. during cinematics; reapply afterwards.
	hooksecurefunc(WorldFrame, "ClearAllPoints", Reapply)
	hooksecurefunc(WorldFrame, "SetAllPoints", Reapply)
	hooksecurefunc(WorldFrame, "SetPoint", Reapply)

	ns.InitOptions()
	ns.InitSecondScreen()
	-- Titan creates its anchors right away: it needs the real window size (otherwise the default above)
	ns.UpdateScreenSize()
	ns.InitTitan()
	ns.Layout.Init()
	ns.ApplyGeometry()

	-- from here on ns.db is set
	events.Register("PLAYER_LOGIN", function()
		-- LibSharedMedia patterns of other addons are only reliably registered now
		ns.UpdateBorderLook()
		if ns.IsActive() and not ns.db.suppressMessage then
			C_Timer.After(8, function()
				ns.Print(L["Custom viewport is active. /qnvp to adjust, /qnvp 0 0 0 0 to reset."])
			end)
		end
	end)
	-- New layout (e.g. Set-WowWindow.ps1 after login): viewport from the main monitor
	events.Register("DISPLAY_SIZE_CHANGED", ns.ApplyGeometry)
	events.Register("UI_SCALE_CHANGED", ns.ApplyGeometry)
end)
