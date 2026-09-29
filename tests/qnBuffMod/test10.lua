-- Scenario 10: qnBuffMod – cleanup on load (sanitize), window management, position,
-- disabled windows, no duplicate display
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end

-- profiles in the current flat format (db.windows) with invalid values
qnCoreCharDB = { layout = "preset:1" }
qnBuffModDB = { settingsVersion = "1.0", global = {}, profiles = {
	["preset:1"] = {
		bgColorBUFF = "rot", flashTime = 500, enableExpiration = 1, expirationTime2 = -5,
		windows = {
			[1] = {
				lockWindow = 1, clampWindow = 0, sortSeq1 = 3, sortSeq2 = 3, sortSeq3 = 6, buffSize1 = 99, buffSize2 = 3,
				windowBackgroundColor = { 1, 2 }, unitType = 9, layoutType = 1.5, detailWidth1 = 600,
				position = { "TOPLEFT", "UIParent", "BOTTOMLEFT", 100, 200, 265, 80 },
			},
			[3] = { disableWindow = 1, unitType = 4, position = { "TOPLEFT", 5 } },
			[4] = "broken",
			name = { buffSize1 = 30 },
		},
	},
	["account:Raid"] = { windows = { [2] = { buffSize1 = 25 } } },
} }

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, L = bm.enum, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end

---------------------------------------------------------------------------
-- cleanup on load (criterion 59)
---------------------------------------------------------------------------
local db = qnBuffModDB.profiles["preset:1"]
Check(bm.db == db, "character's last profile active")
local w1 = db.windows[1]
Check(w1 and w1.lockWindow == true and w1.clampWindow == false, "booleans 1/0 taken over as true/false")
Check(w1.sortSeq1 == 3 and w1.sortSeq2 == E.group.NONE and w1.sortSeq3 == 6, "duplicate group: the later slot becomes none")
Check(w1.buffSize1 == 45 and w1.buffSize2 == 15 and w1.detailWidth1 == 400, "icon size and bar width clamped")
Check(w1.windowBackgroundColor == nil and w1.unitType == nil and w1.layoutType == nil, "invalid color and selection values → default")
Check(w1.position and w1.position[4] == 100 and w1.position[5] == 200, "valid position kept")
Check(db.windows[3].disableWindow == true and db.windows[3].unitType == 4 and db.windows[3].position == nil, "further window cleaned up (invalid position removed)")
Check(type(db.windows[4]) == "table" and next(db.windows[4]) == nil and db.windows.name == nil, "invalid window entries: non-table → empty window, non-numeric ID removed")
Check(type(db.bgColorBUFF) == "table" and db.bgColorBUFF[3] == bm.defaults.bgColorBUFF[3], "invalid general color → default")
Check(db.flashTime == 60 and db.expirationTime2 == 0 and db.enableExpiration == true, "general values clamped, booleans taken over")
Check(qnBuffModDB.profiles["account:Raid"].windows[2].buffSize1 == 25, "valid profile unchanged")
-- a second pass changes nothing anymore
bm.store:Prepare(db)
Check(db.windows[1].buffSize1 == 45 and db.windows[1].sortSeq2 == E.group.NONE and db.windows[1].lockWindow == true,
	"cleanup repeatable without effect")

-- position before the first arrangement: saved position
local points = {}
local origOffset = qnCore.PointOffset
qnCore.PointOffset = function(frame, point, rel, ...)
	local p = frame._points and frame._points[#frame._points]
	points[#points + 1] = p and { unpack(p) }
	return origOffset(frame, point, rel, ...)
end
AURAS.player = {
	{ name = "Arkane Intelligenz", icon = 1, applications = 0, duration = 1800, expirationTime = 2800, sourceUnit = "player", spellId = 1, cancelable = true },
	{ name = "Bärenform", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "player", spellId = 2 },
}
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(points[1] and points[1][1] == "TOPLEFT" and points[1][3] == "BOTTOMLEFT" and points[1][4] == 100 and points[1][5] == 200, "saved position restored")

---------------------------------------------------------------------------
-- disabled window (criterion 62)
---------------------------------------------------------------------------
local ids = bm.WindowIDs()
Check(#ids == 3 and ids[1] == 1 and ids[2] == 3 and ids[3] == 4, "windows 1, 3, 4 (IDs not contiguous)")
local w3 = bm.GetWindow(3)
Check(w3.frame == nil and not bm.Auras.IsWatched("target"), "disabled: no frames, unit not watched")
AURAS.target = { { name = "Zielsegen", icon = 5, applications = 0, duration = 300, expirationTime = 1200, spellId = 9 } }
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
FireEvent("UNIT_AURA", "target") RunTimers()
RunTickers()
Check(w3.frame == nil and #bm.GetEntries(3) == 0 and bm.Auras.units.target == nil, "disabled: reacts to no events and ticks")
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(3)
Check(SETTINGS.QNBUFFMOD_W_UNITTYPE:GetValue() == E.unit.TARGET, "disabled: settings stay, window selectable")
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(false)
Check(w3.frame ~= nil and bm.Auras.IsWatched("target") and #bm.GetEntries(3) == 1, "enabled again: display with entries")
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(true)

---------------------------------------------------------------------------
-- no duplicate display (decision 1)
---------------------------------------------------------------------------
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(1)
SETTINGS.QNBUFFMOD_G_SORTSEQ1:SetValue(E.group.ALLBUFFS)
SETTINGS.QNBUFFMOD_G_SORTSEQ2:SetValue(E.group.CANCELABLE)
local names = {}
for _, e in ipairs(bm.GetEntries(1)) do names[#names + 1] = e.name .. "@" .. e.rec.filter end
Check(table.concat(names, ",") == "Arkane Intelligenz@HELPFUL,Bärenform@HELPFUL", "each spell once, in the first matching slot: " .. table.concat(names, ","))
SETTINGS.QNBUFFMOD_G_SORTSEQ1:SetValue(E.group.CANCELABLE)
SETTINGS.QNBUFFMOD_G_SORTSEQ2:SetValue(E.group.ALLBUFFS)
names = {}
for _, e in ipairs(bm.GetEntries(1)) do names[#names + 1] = e.name .. "@" .. e.rec.filter end
Check(table.concat(names, ",") == "Arkane Intelligenz@HELPFUL|CANCELABLE,Bärenform@HELPFUL", "order of the slots decides: " .. table.concat(names, ","))

---------------------------------------------------------------------------
-- window management (criteria 56, 57)
---------------------------------------------------------------------------
points = {}
clicks[ADD]()
Check(bm.SelectedID() == 2 and printed[#printed] == L["Window %d added."]:format(2), "smallest free ID, message, selected")
Check(points[1] and points[1][1] == "CENTER" and points[1][2] == UIParent and points[1][3] == "CENTER", "new window in the screen center")
Check(bm.db.windows[2].position ~= nil, "position of the new window saved")
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(33)
points = {}
clicks[L["Clone"]]()
Check(bm.SelectedID() == 5 and bm.db.windows[5].buffSize1 == 33 and printed[#printed] == L["Window %d added, copying settings from window %d."]:format(5, 2), "clone with settings")
Check(points[1] and points[1][1] == "CENTER", "clone in the screen center")
-- reset
bm.GetWindow(5).frame.GetLeft = function() return 1500 end
points = {}
clicks[RESET]()
Check(points[1] and points[1][1] == "CENTER" and points[1][3] == "CENTER", "reset: screen center")
-- refused in combat
QN_COMBAT = true
printed = {}
clicks[ADD]()
clicks[L["Clone"]]()
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
QN_COMBAT = false
Check(#printed == 3 and printed[1] == L["Not possible in combat."] and printed[3] == L["Not possible in combat."] and #bm.WindowIDs() == 5, "create, clone, delete refused in combat")
-- at most 10 windows
for _ = 1, 5 do clicks[ADD]() end
Check(#bm.WindowIDs() == 10, "ten windows")
printed = {}
clicks[ADD]()
Check(#bm.WindowIDs() == 10 and printed[1] == L["No more than %d windows are possible."]:format(10), "eleventh refused")
-- delete: selection at the same list position
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(4)
clicks[L["Delete …"]]()
Check(LAST_POPUP.which == "QNBUFFMOD_DELETE_WINDOW" and LAST_POPUP.a1 == L["Window %d"]:format(4), "confirmation with window name")
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
Check(bm.db.windows[4] == nil and bm.SelectedID() == 5 and printed[#printed] == L["Window %d deleted."]:format(4), "deleted, next one at the same position selected")
-- delete all: the last one immediately creates a new one
for _ = 1, 20 do
	if #bm.WindowIDs() == 1 then break end
	StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
end
local last = bm.WindowIDs()[1]
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
ids = bm.WindowIDs()
Check(#ids == 1 and printed[#printed] == L["No window left – window %d added."]:format(ids[1]) and bm.GetWindow(ids[1]).o.buffSize1 == bm.windowDefaults.buffSize1,
	"last one deleted: new one with defaults (" .. tostring(last) .. " → " .. tostring(ids[1]) .. ")")

-- position saved after dragging and restored on rebuild (profile switch)
local win = bm.GetWindow(ids[1])
win.frame.GetLeft = function() return 400 end
win.frame.GetBottom = function() return 300 end
win.bg._scripts.OnMouseDown(win.bg, "LeftButton")
win.bg._scripts.OnMouseUp(win.bg, "LeftButton")
local pos = CopyTable(bm.db.windows[ids[1]].position)
SetEditModeLayout(3)
SetEditModeLayout(1)
points = {}
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(ids[1])
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(true)
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(false)
local p = points[1]
Check(p and p[1] == pos[1] and p[3] == pos[3] and p[4] == pos[4] and p[5] == pos[5], "position saved after dragging and restored")
-- profile switch in combat: only afterwards; the old profile stays unchanged (criterion 58)
local function Same(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not Same(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end
local before = CopyTable(bm.db)
local oldDB = bm.db
QN_COMBAT = true
SetEditModeLayout(3)
Check(bm.db == oldDB, "in combat: still the old profile")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(bm.db == qnBuffModDB.profiles["account:Raid"] and bm.WindowIDs()[1] == 2 and bm.GetWindow(2).o.buffSize1 == 25, "switched after combat, windows of the new profile")
Check(Same(before, oldDB), "teardown does not change the old profile")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
