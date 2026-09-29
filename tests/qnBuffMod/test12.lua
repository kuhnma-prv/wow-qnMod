-- Scenario 12: qnBuffMod – tooltip minimum width, weapon name read later (warning stays),
-- at most one warning per application across a target change
local guids = { player = "Player-1", target = "Creature-A" }
function UnitGUID(unit) return guids[unit] end

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, L = bm.enum, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
local function Count(pattern)
	local n = 0
	for _, m in ipairs(printed) do if m:find(pattern, 1, true) then n = n + 1 end end
	return n
end

-- GetTime() = 1000
local function Buff(name, dur, exp, extra)
	local a = { name = name, icon = 1, applications = 0, duration = dur, expirationTime = exp, sourceUnit = "player", spellId = #name, cancelable = true }
	for k, v in pairs(extra or {}) do a[k] = v end
	return a
end
AURAS.player = { Buff("Arkane Intelligenz", 1800, 2800) }
ENCHANTS[16] = { remainingTimeMs = 600000, chargesRemaining = 0 }
QN_TOOLTIP[16] = { "Klinge" }   -- name of the enchant not readable (yet)
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

---------------------------------------------------------------------------
-- finding 5: reset the minimum width when the tooltip belongs to someone else
---------------------------------------------------------------------------
local e
for _, it in ipairs(bm.GetEntries(1)) do if it.name == "Arkane Intelligenz" then e = it.entry end end
e._scripts.OnEnter(e)
Check(TOOLTIP.owner == e and TOOLTIP.minWidth == 180 and e._scripts.OnUpdate ~= nil, "tooltip on the entry with minimum width")
GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
TOOLTIP.minWidth = 180   -- the game keeps the minimum width across SetOwner
e._scripts.OnUpdate(e, 0.6)
Check(TOOLTIP.minWidth == 0 and e._scripts.OnUpdate == nil, "other owner: minimum width 0, ticker stopped")

---------------------------------------------------------------------------
-- finding 4: weapon enchant name read later – state and warning stay
---------------------------------------------------------------------------
local st = bm.Weapons.slots[16].state
Check(bm.Weapons.slots[16].name == UNKNOWN and not st.known, "name unknown")
SetTime(1590)   -- time remaining 10 s, threshold 15 s
ENCHANTS[16] = { remainingTimeMs = 10000, chargesRemaining = 0 }
FireEvent("WEAPON_ENCHANT_CHANGED")
printed = {}
RunTickers()
Check(Count(UNKNOWN) == 1 and st.warned, "warning under an unknown name")
QN_TOOLTIP[16] = { "Klinge", "Sofortgift (1 Min)" }
ENCHANTS[16] = { remainingTimeMs = 9000, chargesRemaining = 0 }
RunTickers()
local rec = bm.Weapons.slots[16]
Check(rec.name == "Sofortgift" and rec.state == st and st.warned and st.known, "name read later: same state, still warned")
Check(Count("Sofortgift") == 0 and Count(UNKNOWN) == 1, "no second warning for the same enchant")
-- real renewal: warning reset
ENCHANTS[16] = { remainingTimeMs = 600000, chargesRemaining = 0 }
FireEvent("WEAPON_ENCHANT_CHANGED")
Check(not bm.Weapons.slots[16].state.warned, "renewal resets the warning")
ENCHANTS[16] = nil
FireEvent("WEAPON_SLOT_CHANGED")

---------------------------------------------------------------------------
-- finding 2: target change and back – the same application does not warn again
---------------------------------------------------------------------------
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
Check(bm.Auras.IsWatched("target"), "target watched")
local function Target(guid, auras)
	guids.target = guid
	AURAS.target = auras
	FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
end
SetTime(2000)
Target("Creature-A", { Buff("Zielsegen", 600, 2100, { auraInstanceID = 77 }) })
printed = {}
RunTickers()
Check(Count("Zielsegen") == 0, "above the threshold: no warning")
SetTime(2090)
RunTickers()
Check(Count("Zielsegen") == 1, "below the threshold: one warning")
Target("Creature-B", {})
RunTickers()
Target("Creature-A", { Buff("Zielsegen", 600, 2100, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 1, "target change and back: no second warning")
-- likewise without aura instance (key from name, spell ID, caster)
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2100) })
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2100) })
RunTickers()
Check(Count("Zielsegen") == 2, "without instance: first warning of this application, then no further one (" .. Count("Zielsegen") .. ")")
-- a small correction of the expiration is not a new application
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2101, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 2, "correction after target change: no new warning")
-- other unit with the same aura: its own warning
Target("Creature-C", { Buff("Zielsegen", 600, 2100, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 3, "other unit: its own warning")
-- renewed during the absence: new application, warns again below the threshold
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2690, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 3, "renewed: no warning above the threshold")
SetTime(2680)
RunTickers()
Check(Count("Zielsegen") == 4, "renewed application: a warning again")
Target("Creature-B", {})
Target("Creature-A", { Buff("Zielsegen", 600, 2690, { auraInstanceID = 77 }) })
RunTickers()
Check(Count("Zielsegen") == 4, "and no further one after target change")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
