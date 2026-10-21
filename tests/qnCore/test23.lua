-- Scenario 23: qnCore 0.2.3 - Profiles.Register with a stored major newer than the addon (going back
-- to an older addon version): the saved variable stays untouched, the session works on a copy

LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
SetEditModeLayout(3)   -- active layout: account "Raid"
local P = qnCore.Profiles

QN_TEST23_SV = {
	settingsVersion = "3.0",
	profiles = {
		["account:Raid"] = { size = 5, newKey = "x", dropped = true, mode = "future" },
	},
	global = { seen = true },
}
local out = {}
local ns = qnCore.NewAddon({}, "qnTest23")
ns.Print = function(msg) out[#out + 1] = msg end
local store = P.Register({
	ns = ns,
	sv = "QN_TEST23_SV",
	settingsVersion = "2.0",
	defaults = { size = 1, color = "white", mode = "normal" },
	migrations = { [2] = function() error("must not run") end },
	obsolete = { "dropped" },
	sanitize = function(db)
		if db.mode ~= "normal" then db.mode = nil end
	end,
})

local saved = QN_TEST23_SV.profiles["account:Raid"]
Check(QN_TEST23_SV.settingsVersion == "3.0", "stored version untouched")
Check(saved.dropped == true and saved.mode == "future" and saved.color == nil, "saved profile untouched (no obsolete, sanitize, defaults)")
Check(store.sv ~= QN_TEST23_SV and store.sv.profiles["account:Raid"] ~= saved, "the session works on a copy")
Check(store.db and store.db.size == 5 and store.db.color == "white" and store.db.mode == "normal", "the copy is prepared and usable")
store.db.size = 9
Check(saved.size == 5, "changes in the session do not reach the saved variable")
Check(#out == 2 and out[2] == ns.L["Changes to the settings of %s in this session are not saved."]:format("qnTest23"),
	"warning plus note that nothing is saved: " .. tostring(out[2]))

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
