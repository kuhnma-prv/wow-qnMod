-- Szenario 10: Lage relativ zu UIParent in den Addons (qnCore.PointOffset/NearestCorner):
-- qnMeter speichert in Einheiten von UIParent (einmalige Umrechnung alter Profile, kein Sprung beim
-- Ändern der Skalierung), qnBuffMod verankert richtig bei verschobenem UIParent.

qnCoreCharDB = { layout = "account:Raid" }
qnMeterDB = { global = {}, profiles = {
	["account:Raid"] = { scale = 1.5, point = { "TOPLEFT", "BOTTOMLEFT", 100, 600 } },
	["preset:1"] = { scale = 2, point = { "TOPLEFT", "BOTTOMLEFT", 10, 20 }, pointInParentUnits = true },
} }

LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
local bm = LoadAddon("qnBuffMod")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)

---------------------------------------------------------------------------
-- qnMeter
---------------------------------------------------------------------------
local raid = qnMeterDB.profiles["account:Raid"]
Check(raid.pointInParentUnits == true and raid.point[3] == 150 and raid.point[4] == 900,
	("altes Profil einmal umgerechnet (× 1.5): %s, %s"):format(raid.point[3], raid.point[4]))
local pre = qnMeterDB.profiles["preset:1"]
Check(pre.point[3] == 10 and pre.point[4] == 20, "Profil mit Kennzeichen nicht erneut umgerechnet")
local f = meter.Threat.frame
local function LastPoint()
	return f._points[#f._points]
end
local p = LastPoint()
Check(p[1] == "TOPLEFT" and p[2] == UIParent and p[3] == "BOTTOMLEFT" and math.abs(p[4] - 100) < 1e-9 and math.abs(p[5] - 600) < 1e-9,
	("gleiche Lage wie vorher (Einheiten des Fensters 100, 600): %s, %s"):format(p[4], p[5]))
SETTINGS.QNMETER_SCALE:SetValue(2)
p = LastPoint()
Check(math.abs(p[4] - 75) < 1e-9 and math.abs(p[5] - 450) < 1e-9 and raid.point[3] == 150,
	("Skalierung 2: Ecke bleibt (75, 450 in Einheiten des Fensters): %s, %s"):format(p[4], p[5]))
-- Speichern nach dem Ziehen: Einheiten von UIParent
f.GetLeft = function() return 50 end
f.GetBottom = function() return 100 end
f.GetHeight = function() return 100 end
f.GetEffectiveScale = function() return 2 end
meter.Window.SavePosition(f)
Check(raid.point[3] == 100 and raid.point[4] == 400, ("SavePosition in Einheiten von UIParent: %s, %s"):format(raid.point[3], raid.point[4]))
Check(meter.store:NewProfileTable().pointInParentUnits == true, "neues Profil trägt das Kennzeichen")

---------------------------------------------------------------------------
-- qnBuffMod: verschobenes UIParent (qnViewPort: Oberfläche auf dem Hauptmonitor)
---------------------------------------------------------------------------
local win = bm.GetWindow(1)
local af = win.frame
af.GetLeft = function() return 150 end
af.GetBottom = function() return 110 end
af.GetWidth = function() return 40 end
af.GetHeight = function() return 40 end
UIParent.GetLeft = function() return 100 end
UIParent.GetBottom = function() return 50 end
win:Reanchor(false)
local ap = af._points[#af._points]
Check(ap[1] == "TOPLEFT" and ap[2] == UIParent and ap[3] == "BOTTOMLEFT" and ap[4] == 50 and ap[5] == 100,
	("Anker relativ zum verschobenen UIParent: %s %s %s"):format(tostring(ap[3]), tostring(ap[4]), tostring(ap[5])))
-- oben rechts: Versatz zur Ecke TOPRIGHT von UIParent (100 + 1920, 50 + 1080)
af.GetLeft = function() return 1900 end
af.GetBottom = function() return 1000 end
win:Reanchor(false)
ap = af._points[#af._points]
Check(ap[3] == "TOPRIGHT" and ap[4] == 1900 - 2020 and ap[5] == 1040 - 1130,
	("Ecke oben rechts: %s %s %s"):format(tostring(ap[3]), tostring(ap[4]), tostring(ap[5])))
win:Reanchor(true)
ap = af._points[#af._points]
Check(ap[4] == -120 and ap[5] == -90, "im Bild: bleibt, wenn der Ankerpunkt schon innen liegt")
-- Ankerpunkt rechts außerhalb von UIParent: mit Bildschirmhaltung an den Rand geholt
af.GetLeft = function() return 2100 end
win:Reanchor(true)
ap = af._points[#af._points]
Check(ap[3] == "TOPRIGHT" and ap[4] == 0 and ap[5] == -90, ("außerhalb: Ankerpunkt an den Rand: %s %s"):format(tostring(ap[4]), tostring(ap[5])))
win:SavePosition()
local pos = bm.db.windows[1].position
Check(pos[1] == "TOPLEFT" and pos[2] == "UIParent" and pos[3] == "TOPRIGHT" and pos[4] == 0 and pos[5] == -90 and pos[6] == 40, "Position gespeichert")
UIParent.GetLeft, UIParent.GetBottom = nil, nil

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
