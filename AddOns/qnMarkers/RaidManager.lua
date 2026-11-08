-- qnMarkers: hide Blizzard's raid manager (opt-in).
--
-- CompactRaidFrameManager (Blizzard_CompactRaidFrames, [Family] variant Classic or Mainline): only its
-- own regions, its panel (displayFrame) and its toggle buttons (toggleButton or
-- toggleButtonForward/Back) become transparent and ignore the mouse. The manager's alpha itself stays,
-- because the Classic variant parents the raid frames (CompactRaidFrameContainer) to it. Nothing is
-- hooked, moved or written into Blizzard's tables; the original values are restored when the option is
-- switched off. The manager tree contains protected buttons: out of combat only.

local _, ns = ...
local lib = qnCore

local PARTS = { "displayFrame", "toggleButton", "toggleButtonForward", "toggleButtonBack" }

local alphas = {}   -- region or frame -> alpha before hiding
local mice = {}     -- frame -> mouse enabled before hiding

local function Transparent(region)
	if alphas[region] == nil then
		alphas[region] = region:GetAlpha()
	end
	region:SetAlpha(0)
end

-- also children created later (checked again on every apply)
local function NoMouse(frame, deep)
	if mice[frame] == nil then
		mice[frame] = frame:IsMouseEnabled()
	end
	frame:EnableMouse(false)
	if deep then
		for _, child in ipairs({ frame:GetChildren() }) do
			NoMouse(child, true)
		end
	end
end

local function Restore()
	for region, alpha in pairs(alphas) do
		region:SetAlpha(alpha)
	end
	for frame, enabled in pairs(mice) do
		frame:EnableMouse(enabled)
	end
	wipe(alphas)
	wipe(mice)
end

function ns.ApplyRaidManager()
	if not ns.db or lib.DeferInCombat(ns.ApplyRaidManager) then
		return
	end
	if not ns.db.hideRaidManager then
		Restore()
		return
	end
	local manager = _G.CompactRaidFrameManager
	if not manager then
		return   -- loaded later (ADDON_LOADED below)
	end
	for _, region in ipairs({ manager:GetRegions() }) do
		Transparent(region)
	end
	NoMouse(manager)
	for _, key in ipairs(PARTS) do
		local part = manager[key]
		if part then
			Transparent(part)
			NoMouse(part, true)
		end
	end
end

local events = ns.events
events.Register("ADDON_LOADED", function(_, name)
	if name == "Blizzard_CompactRaidFrames" then
		ns.ApplyRaidManager()
	end
end)
-- Blizzard may set up the manager anew when the group changes
events.Register("PLAYER_ENTERING_WORLD", function() ns.ApplyRaidManager() end)
events.Register("GROUP_ROSTER_UPDATE", function() ns.ApplyRaidManager() end)
