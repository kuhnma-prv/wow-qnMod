-- Scenario 4: qnBuffMod core: groups, sorting, weapons, arrangement, styles, vehicle, warning,
-- right-click, create/clone/delete windows
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, K, L = bm.enum, bm.kind, bm.L

-- GetTime() = 1000
AURAS.player = {
	{ name = "Arkane Intelligenz", icon = 1, applications = 0, duration = 1800, expirationTime = 2800, sourceUnit = "player", spellId = 1, cancelable = true },
	{ name = "Bärenform", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "player", spellId = 2 },
	{ name = "Zorn", icon = 3, applications = 3, duration = 600, expirationTime = 1010, sourceUnit = "pet", spellId = 3, cancelable = true },
	{ name = "Fluch", icon = 4, applications = 0, duration = 30, expirationTime = 1020, sourceUnit = "target", spellId = 4, isHarmful = true, dispelName = "Magic" },
}
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end

FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

local win = bm.GetWindow(1)
local function Names(id)
	local out = {}
	for _, e in ipairs(bm.GetEntries(id or 1)) do
		out[#out + 1] = e.weapon and ("W" .. e.slot) or e.name
	end
	return table.concat(out, ",")
end
local function Entry(name, id)
	for _, e in ipairs(bm.GetEntries(id or 1)) do
		if e.name == name then return e end
	end
end

-- groups (debuffs, weapons, cancelable, uncancelable), within them by name
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "groups and name: " .. Names())
Check(Entry("Bärenform").kind == K.AURA, "without expiration = aura")
Check(Entry("Arkane Intelligenz").kind == K.BUFF and Entry("Fluch").kind == K.DEBUFF, "buff/debuff")
Check(Entry("Zorn").countText == 3, "stacks shown")
Check(Entry("Bärenform").time == nil, "aura without time remaining")
Check(Entry("Zorn").time == L["%d seconds"]:format(10), "time remaining format 1: " .. tostring(Entry("Zorn").time))
Check(Entry("Zorn").flashing, "flashes before expiring")
Check(Entry("Arkane Intelligenz").nameText == "Arkane Intelligenz", "name shown")

-- grid: left to right, 1 per row -> stacked, size = icons
local z = Entry("Zorn")
local pt = z.entry._points[1]
Check(z.x == 0 and z.y == -40 and pt[1] == "TOPLEFT" and pt[2] == win.frame and pt[4] == 0 and pt[5] == -40, "third entry at y=-40")
Check(win.frame._w == 265 and win.frame._h == 80, ("icon area 265x80: %sx%s"):format(win.frame._w, win.frame._h))

-- expiration warning (duration 10 min, 10 s left) via the one-second ticker
RunTickers()
local warned = false
for _, m in ipairs(printed) do if m:find("Zorn", 1, true) then warned = true end end
Check(warned, "warning for Zorn")

-- sorting
SETTINGS.QNBUFFMOD_G_SORTMETHOD:SetValue(E.sort.TIME)
Check(Names() == "Fluch,Zorn,Arkane Intelligenz,Bärenform", "by time remaining: " .. Names())
SETTINGS.QNBUFFMOD_G_SORTMETHOD:SetValue(E.sort.NAME)
SETTINGS.QNBUFFMOD_G_SORTDIRECTION:SetValue(true)
Check(Names() == "Fluch,Zorn,Arkane Intelligenz,Bärenform", "name descending: " .. Names())
SETTINGS.QNBUFFMOD_G_SEPARATEOWN:SetValue(E.own.FIRST)
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "own first: " .. Names())
SETTINGS.QNBUFFMOD_G_SEPARATEZERO:SetValue(E.zero.HIDE)
Check(Names() == "Fluch,Arkane Intelligenz,Zorn", "without expiration hidden: " .. Names())
SETTINGS.QNBUFFMOD_G_SEPARATEZERO:SetValue(E.zero.ONLY)
Check(Names() == "Bärenform", "only without expiration: " .. Names())
SETTINGS.QNBUFFMOD_G_SEPARATEZERO:SetValue(E.zero.WITH)
SETTINGS.QNBUFFMOD_G_SEPARATEOWN:SetValue(E.own.WITH)
SETTINGS.QNBUFFMOD_G_SORTDIRECTION:SetValue(false)

-- duplicate group: the other slot becomes "none", its display follows
SETTINGS.QNBUFFMOD_G_SORTSEQ3:SetValue(E.group.DEBUFF)
local o = bm.db.windows[1]
Check(o.sortSeq1 == E.group.NONE and o.sortSeq3 == E.group.DEBUFF and SETTINGS.QNBUFFMOD_G_SORTSEQ1:GetValue() == E.group.NONE, "duplicate group resolved")
Check(Names() == "Fluch,Bärenform", "groups: debuffs, uncancelable: " .. Names())
SETTINGS.QNBUFFMOD_G_SORTSEQ1:SetValue(E.group.DEBUFF)
SETTINGS.QNBUFFMOD_G_SORTSEQ3:SetValue(E.group.CANCELABLE)
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "groups restored: " .. Names())

-- weapon enchant in place of group 2
ENCHANTS[16] = { remainingTimeMs = 1200000, chargesRemaining = 5 }
QN_TOOLTIP[16] = { "Schwert", "Sofortgift (20 Min)" }
FireEvent("WEAPON_ENCHANT_CHANGED")
Check(Names() == "Fluch,W16,Arkane Intelligenz,Zorn,Bärenform", "weapon after the debuffs: " .. Names())
Check(Entry("Sofortgift").countText == 5 and Entry("Sofortgift").kind == K.ITEM, "weapon charges")
ENCHANTS[16] = nil
RunTickers() RunTickers()
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "weapon expired (ticker): " .. Names())

-- appearance: changed button setting is drawn immediately
SETTINGS.QNBUFFMOD_B_DURATIONFORMAT1:SetValue(3)
Check(Entry("Arkane Intelligenz").time == "30m", "format 3 immediately: " .. tostring(Entry("Arkane Intelligenz").time))
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.ICON)
local ai = Entry("Arkane Intelligenz")
Check(ai.nameText == nil and ai.time == L["%d minutes"]:format(30), "style 2: no name, time in format")
Check(ai.entry._w == 20 and ai.entry._h == 20, "style 2: icon size")
SETTINGS.QNBUFFMOD_B_BUFFSIZE2:SetValue(30)
Check(Entry("Arkane Intelligenz").entry._w == 30, "style 2: icon size from buffSize2")
SETTINGS.QNBUFFMOD_B_BUFFSIZE2:SetValue(20)
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.BAR)
SETTINGS.QNBUFFMOD_B_COLORCODEICONS1:SetValue(true)
SETTINGS.QNBUFFMOD_B_COLORCODEBACKGROUND1:SetValue(true)
SETTINGS.QNBUFFMOD_B_COLORCODEDEBUFFS1:SetValue(true)
local fl = Entry("Fluch").entry
Check(fl.border._shown and not Entry("Arkane Intelligenz").entry.border._shown, "color codes: border only on the debuff")

-- style 1: position of the time remaining (above/below/beside the name)
local function Pt(region, i) local q = region._points[i] return q and q[1] end
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.ABOVE)
local b = Entry("Arkane Intelligenz").entry
Check(not b.besideName and Pt(b.timeText, 1) == "BOTTOMLEFT" and Pt(b.nameText, 1) == "TOPLEFT", "time above the name")
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.BELOW)
b = Entry("Arkane Intelligenz").entry
Check(not b.besideName and Pt(b.timeText, 1) == "TOPLEFT" and Pt(b.nameText, 1) == "BOTTOMLEFT", "time below the name")
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.LEFT)
b = Entry("Arkane Intelligenz").entry
Check(b.besideName and Pt(b.timeText, 1) == "LEFT" and Pt(b.nameText, 1) == "RIGHT"
	and b.nameText._points[2][2] == b.timeText, "time left of the name")
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.RIGHT)
b = Entry("Arkane Intelligenz").entry
Check(b.besideName and Pt(b.timeText, 1) == "RIGHT" and Pt(b.nameText, 1) == "LEFT", "time right of the name")
SETTINGS.QNBUFFMOD_B_SHOWNAMES1:SetValue(false)
local e = Entry("Arkane Intelligenz")
b = e.entry
Check(e.nameText == nil and not b.besideName and Pt(b.timeText, 1) == "LEFT" and Pt(b.timeText, 2) == "RIGHT", "only time across the whole bar")
SETTINGS.QNBUFFMOD_B_SHOWNAMES1:SetValue(true)
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.DEFAULT)

-- style 1: without bar color no bar, name stays; bar width 0: neither name nor time
SETTINGS.QNBUFFMOD_B_COLORBUFFS1:SetValue(false)
e = Entry("Fluch")
b = e.entry
Check(not b.bar._shown and not b.spark._shown and not b.barBG._shown and e.nameText ~= nil and e.time ~= nil, "bar color off")
SETTINGS.QNBUFFMOD_B_COLORBUFFS1:SetValue(true)
b = Entry("Fluch").entry
Check(b.bar._shown and b.spark._shown and b.barBG._shown, "bar color on again")
SETTINGS.QNBUFFMOD_B_DETAILWIDTH1:SetValue(0)
e = Entry("Arkane Intelligenz")
Check(e.nameText == nil and e.time == nil and not e.entry.detail._shown and e.entry.detail._w == 0 and e.entry._w == 20, "bar width 0")
SETTINGS.QNBUFFMOD_B_DETAILWIDTH1:SetValue(bm.windowDefaults.detailWidth1)
Check(Entry("Arkane Intelligenz").nameText ~= nil, "bar width back")

-- style 2: time remaining on each side of the icon (spacing 4)
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.ICON)
SETTINGS.QNBUFFMOD_B_SPACINGFROMICON2:SetValue(4)
local SIDES = { { "RIGHT", "LEFT", -4, 0 }, { "LEFT", "RIGHT", 4, 0 }, { "BOTTOM", "TOP", 0, 4 }, { "TOP", "BOTTOM", 0, -4 }, { "CENTER", "CENTER", 0, 0 } }
for side, want in ipairs(SIDES) do
	SETTINGS.QNBUFFMOD_B_DATASIDE2:SetValue(side)
	b = Entry("Arkane Intelligenz").entry
	local q = b.timeText._points[1]
	Check(#b.timeText._points == 1 and q[1] == want[1] and q[2] == b and q[3] == want[2] and q[4] == want[3] and q[5] == want[4],
		("style 2, side %d: %s %s %s/%s"):format(side, tostring(q[1]), tostring(q[3]), tostring(q[4]), tostring(q[5])))
end
SETTINGS.QNBUFFMOD_B_DATASIDE2:SetValue(E.dataSide.BELOW)
SETTINGS.QNBUFFMOD_B_SPACINGFROMICON2:SetValue(0)
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.BAR)

-- arrangement: columns, 2 per column
SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(1)
SETTINGS.QNBUFFMOD_L_WRAPAFTER:SetValue(2)
Check(win.edges.barRight == 245 and win.edges.right == 4 + 245, "bar beside variable columns widens the background")
z = Entry("Zorn")
Check(z.x == 265 and z.y == 0, ("third entry in column 2: %s/%s"):format(z.x, z.y))
Check(win.frame._w == 285 and win.frame._h == 40, ("icon area 285x40: %sx%s"):format(win.frame._w, win.frame._h))
-- at most 1 column: only 2 entries, the rest hidden, area only as large as the column
SETTINGS.QNBUFFMOD_L_MAXWRAPS:SetValue(1)
Check(Names() == "Fluch,Arkane Intelligenz" and win.entries[3]._shown == false and win.entries[4]._shown == false,
	"at most 1 column: " .. Names())
Check(win.frame._w == 265 and win.frame._h == 40, ("icon area 265x40: %sx%s"):format(win.frame._w, win.frame._h))
SETTINGS.QNBUFFMOD_L_MAXWRAPS:SetValue(0)
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform" and win.frame._w == 285, "automatic again: " .. Names())
SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(5)
SETTINGS.QNBUFFMOD_L_WRAPAFTER:SetValue(1)

-- right-click removes buffs (not in combat, not debuffs)
local cancelled = {}
CancelUnitBuff = function(u, i, f) cancelled[#cancelled + 1] = u .. ":" .. i .. ":" .. f end
C_CVar._v.ActionButtonUseKeyDown = "1"
b = Entry("Zorn").entry
b._scripts.OnMouseDown(b, "RightButton")
Check(cancelled[1] == "player:2:HELPFUL|CANCELABLE", "Zorn removed: " .. tostring(cancelled[1]))
QN_COMBAT = true
b._scripts.OnMouseDown(b, "RightButton")
QN_COMBAT = false
b = Entry("Fluch").entry
b._scripts.OnMouseDown(b, "RightButton")
Check(#cancelled == 1, "not in combat, no debuffs")
-- on release (CVar off) only if the mouse is still over the entry
C_CVar._v.ActionButtonUseKeyDown = "0"
b = Entry("Bärenform").entry
b._scripts.OnMouseDown(b, "RightButton")
b._scripts.OnMouseUp(b, "RightButton")
Check(#cancelled == 1, "release outside: nothing")
b.IsMouseOver = function() return true end
b._scripts.OnMouseUp(b, "RightButton")
Check(cancelled[2] == "player:1:HELPFUL|!CANCELABLE", "release over the entry: " .. tostring(cancelled[2]))
b.IsMouseOver = nil

-- vehicle
AURAS.vehicle = { { name = "Panzerung", icon = 8, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "vehicle", spellId = 12 } }
FireEvent("UNIT_ENTERED_VEHICLE", "player")
Check(win.unit == "vehicle" and Names() == "Panzerung", "in a vehicle its spells: " .. Names())
FireEvent("UNIT_EXITED_VEHICLE", "player")
Check(win.unit == "player" and Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "back to the player")

-- second window for the target, then clone and delete
clicks[ADD]()
Check(#bm.WindowIDs() == 2 and bm.SelectedID() == 2, "second window, selected")
local w2 = bm.GetWindow(2)
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
AURAS.target = { { name = "Segen", icon = 5, applications = 0, duration = 300, expirationTime = 1200, sourceUnit = "player", spellId = 9, cancelable = true } }
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
Check(w2.unit == "target" and Names(2) == "Segen", "target window: " .. Names(2))
AURAS.target[2] = { name = "Gift", icon = 6, applications = 0, duration = 10, expirationTime = 1005, spellId = 10, isHarmful = true }
FireEvent("UNIT_AURA", "target") RunTimers()
Check(Names(2) == "Gift,Segen", "UNIT_AURA of the target: " .. Names(2))
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(30)
clicks[L["Clone"]]()
local w3 = bm.GetWindow(3)
Check(w3 and w3.o.buffSize1 == 30 and w3.unit == "target" and bm.SelectedID() == 3, "clone takes over settings")
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
Check(bm.SelectedID() == 2, "after deleting: window at the same list position or the last one")
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
Check(#bm.WindowIDs() == 1 and not bm.db.windows[2] and not bm.db.windows[3], "windows 2 and 3 deleted")
Check(not bm.Auras.IsWatched("target") and bm.Auras.units.target == nil, "target no longer watched")
clicks[ADD]()
Check(bm.GetWindow(2).o.buffSize1 == bm.windowDefaults.buffSize1 and next(bm.db.windows[2]) == "position", "new window with defaults")

-- disable window and enable again
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(1)
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(true)
Check(win.frame == nil and #bm.GetEntries(1) == 0, "disabled: no frames")
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(false)
Check(win.frame ~= nil and Names() ~= "", "enabled again")

-- aura data restriction (combat): no query, last state stays, re-read afterwards
local before = Names()
QN_AURAS_SECRET = true
AURAS.player[5] = { name = "Neu", icon = 7, applications = 0, duration = 60, expirationTime = 1060, sourceUnit = "player", spellId = 11, cancelable = true }
FireEvent("UNIT_AURA", "player") RunTimers()
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
b = Entry("Arkane Intelligenz").entry
b._scripts.OnEnter(b)
Check(Names() == before and TOOLTIP.aura == nil and TOOLTIP.lines[1].text == "Arkane Intelligenz", "restricted: last state, tooltip with name only")
b._scripts.OnLeave(b)
QN_AURAS_SECRET = false
FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 0, 0) RunTimers()
Check(Names():find("Neu", 1, true) ~= nil, "re-read after the restriction: " .. Names())
-- individually locked aura: placeholder instead of abort
AURAS.player[5].locked = true
FireEvent("UNIT_AURA", "player") RunTimers()
Check(Names():find("?", 1, true) ~= nil and Names():find("Neu", 1, true) == nil and Names():find("Zorn", 1, true) ~= nil, "individually locked: placeholder: " .. Names())
AURAS.player[5] = nil
FireEvent("UNIT_AURA", "player") RunTimers()

-- helper functions
Check(bm.buildCondition("[combat] hide\n\n;show;\n") == "[combat] hide;show", "condition: " .. bm.buildCondition("[combat] hide\n\n;show;\n"))
Check(bm.humanizeTime(3700) == "1h 01m" and bm.humanizeTime(59) == "59s", "time format 4")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
