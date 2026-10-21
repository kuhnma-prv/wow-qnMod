-- Scenario 13: qnBuffMod 0.1.3 - target change during the aura restriction (combat): the auras of
-- the previous target are not shown any longer; after the restriction the new target is read
local guids = { player = "Player-1", target = "Creature-A" }
function UnitGUID(unit) return guids[unit] end

LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E = bm.enum

local function Buff(name)
	return { name = name, icon = 1, applications = 0, duration = 600, expirationTime = 1500, sourceUnit = "player", spellId = #name, cancelable = true }
end
AURAS.player = { Buff("Arkane Intelligenz") }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

local function Has(name)
	local n = 0
	for _, group in pairs(E.group) do
		for _, rec in ipairs(bm.Auras.List("target", group)) do
			if rec.name == name then n = n + 1 end
		end
	end
	return n
end

SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
Check(bm.Auras.IsWatched("target"), "target watched")
AURAS.target = { Buff("Zielsegen") }
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
Check(Has("Zielsegen") > 0, "auras of target A read")

-- restriction: aura changes of the same target keep the frozen list
QN_AURAS_SECRET = true
FireEvent("UNIT_AURA", "target") RunTimers()
Check(Has("Zielsegen") > 0, "restriction: list of the same target stays")

-- target change during the restriction: the old auras are gone
guids.target = "Creature-B"
AURAS.target = {}
local ok, err = pcall(function() FireEvent("PLAYER_TARGET_CHANGED") RunTimers() end)
Check(ok, "target change during the restriction without errors: " .. tostring(err))
local stale = Has("Zielsegen")
Check(stale == 0, "auras of the previous target not shown: " .. stale)

-- restriction over: the new target is read
AURAS.target = { Buff("Neuer Segen") }
QN_AURAS_SECRET = false
FireEvent("ADDON_RESTRICTION_STATE_CHANGED") RunTimers()
Check(Has("Neuer Segen") > 0, "after the restriction: auras of the new target")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
