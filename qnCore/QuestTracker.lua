-- qnCore: kleinere Schrift in der Questzielverfolgung, je Profil (= Layout des Bearbeitungsmodus).
--
-- Blizzards Regler im Bearbeitungsmodus reicht von 12 bis 20: ObjectiveTrackerManager:SetTextSize
-- lehnt kleinere Werte ab, Schriftvorlagen gibt es erst ab ObjectiveTrackerFont12. qnCore setzt
-- deshalb die Größe der beiden Schriften ObjectiveTrackerLineFont und ObjectiveTrackerHeaderFont
-- direkt (Überschrift wie bei Blizzard 2 größer). Blizzards Regler bleibt unangetastet.
-- Setzt Blizzard die Schrift neu (Layoutwechsel, Regler), stellt ein Hook auf SetFontObject die
-- eigene Größe wieder her – noch vor Blizzards Neuaufbau der Verfolgung. Nach einer Änderung in
-- qnCore wird die Verfolgung außerhalb des Kampfes neu aufgebaut (im Kampf danach).

local _, ns = ...
local lib = qnCore

local QT = {}
ns.QuestTracker = QT

QT.SIZES = { 8, 9, 10, 11 }   -- Auswahl unterhalb von Blizzards Minimum

local LINE_BASE, HEADER_BASE = 12, 14   -- Vorlagen, von denen Datei und Höhe stammen
local HEADER_EXTRA = 2                  -- wie headerExtraSize in Blizzard_ObjectiveTrackerManager.lua

-- zuletzt von Blizzard gesetzte Schriftvorlagen (Vorgabe aus Blizzard_ObjectiveTrackerFonts.xml)
local blizzLine, blizzHeader = "ObjectiveTrackerFont12", "ObjectiveTrackerFont14"
local applied = 0   -- zurzeit von qnCore gesetzte Größe, 0 = Blizzards Schrift
local hooked = false

local function Wanted()
	return ns.db and ns.db.questTextSize or 0
end

-- font auf size setzen. Datei und Höhe kommen aus Blizzards Vorlage der Größe base: je Alphabet
-- andere Datei und Höhe (z. B. Chinesisch 15 bei Größe 12), deshalb im Verhältnis umrechnen.
local function SetSize(font, base, size)
	local template = _G["ObjectiveTrackerFont" .. base]
	local path, height, flags = template:GetFont()
	if not path or not height then
		return
	end
	font:SetFont(path, height * size / base, flags or "")
end

local function Override(size)
	SetSize(ObjectiveTrackerLineFont, LINE_BASE, size)
	SetSize(ObjectiveTrackerHeaderFont, HEADER_BASE, size + HEADER_EXTRA)
end

local Relayout
Relayout = function()
	if lib.DeferInCombat(Relayout) then
		return
	end
	ObjectiveTrackerManager:UpdateAll()
end

-- Blizzard hat eine Schriftvorlage gesetzt: merken und die eigene Größe wiederherstellen
local function OnLineFont(_, font)
	blizzLine = font
	if applied > 0 then
		SetSize(ObjectiveTrackerLineFont, LINE_BASE, applied)
	end
end

local function OnHeaderFont(_, font)
	blizzHeader = font
	if applied > 0 then
		SetSize(ObjectiveTrackerHeaderFont, HEADER_BASE, applied + HEADER_EXTRA)
	end
end

local function Hook()
	if hooked or not ObjectiveTrackerManager then
		return false
	end
	hooked = true
	hooksecurefunc(ObjectiveTrackerLineFont, "SetFontObject", OnLineFont)
	hooksecurefunc(ObjectiveTrackerHeaderFont, "SetFontObject", OnHeaderFont)
	return true
end

-- Größe des aktiven Profils anwenden (Option, Profilwechsel, Start)
function QT.Apply()
	if not hooked then
		return
	end
	local size = Wanted()
	if size == applied then
		return
	end
	applied = size
	if size > 0 then
		Override(size)
	else
		ObjectiveTrackerLineFont:SetFontObject(blizzLine)
		ObjectiveTrackerHeaderFont:SetFontObject(blizzHeader)
	end
	Relayout()
end

function QT.Init()
	if Hook() then
		QT.Apply()
		return
	end
	-- Blizzard_ObjectiveTracker lädt vor den Addons; falls nicht, beim eigenen ADDON_LOADED
	ns.events.Register("ADDON_LOADED", function(_, name)
		if name == "Blizzard_ObjectiveTracker" and Hook() then
			QT.Apply()
		end
	end)
end
