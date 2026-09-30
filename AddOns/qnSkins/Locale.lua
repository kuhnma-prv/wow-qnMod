-- qnSkins: German texts (deDE clients only). Key = English text in the code.

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if not qnCore.GERMAN then return end

-- Core.lua
L["None"] = "Keiner"
L["Skin applied."] = "Skin angewendet."
L["Usage: /qnskins camera <artwork> <zoom> [sideways] [height]"] = "Aufruf: /qnskins camera <Bild> <Zoom> [seitlich] [Höhe]"
L["Usage: /qnskins model <artwork> <creature ID | d:display ID> [animation] [rotation]"] = "Aufruf: /qnskins model <Bild> <Kreatur-ID | d:Display-ID> [Animation] [Drehung]"
L["Commands: /qnskins [config | apply | list | frames | model | camera]\n  config – open options    apply – apply the skin again\n  list – list the skins    frames – list elements and figures\n  model <artwork> <creature ID | d:display ID> [animation] [rotation] – try out a figure until the next reload\n  camera <artwork> <zoom> [sideways] [height] – zoom and move a figure (also on the page Figures)"] = "Befehle: /qnskins [config | apply | list | frames | model | camera]\n  config – Optionen öffnen    apply – Skin erneut anwenden\n  list – Skins auflisten    frames – Elemente und Figuren auflisten\n  model <Bild> <Kreatur-ID | d:Display-ID> [Animation] [Drehung] – Figur bis zum nächsten Neuladen ausprobieren\n  camera <Bild> <Zoom> [seitlich] [Höhe] – Figur zoomen und verschieben (auch auf der Seite Figuren)"

-- Skins.lua
L["Dragon's Lair"] = "Drachenhort"
L["Stone Frame"] = "Steinrahmen"
L["Warrior"] = "Krieger"

-- Layout.lua
L["shown"] = "sichtbar"
L["hidden"] = "ausgeblendet"
L["%s = %s: not found"] = "%s = %s: nicht gefunden"

-- Art.lua
L["%s: figure, %s, %s, model file %s, display %s"] = "%s: Figur, %s, %s, Modelldatei %s, Display %s"
L["%s: model %s, animation %s, rotation %s"] = "%s: Modell %s, Animation %s, Drehung %s"
L["%s: zoom %s, sideways %s, height %s"] = "%s: Zoom %s, seitlich %s, Höhe %s"

-- Options.lua
L["Automatic (monitor with the 3D view)"] = "Automatisch (Monitor mit der 3D-Ansicht)"
L["Monitor %d"] = "Monitor %d"
L["Skin"] = "Skin"
L["Artwork around the action bars, status bars and micro menu. It lies below the elements, so bars shown later (pet bar, vehicle button) cover it."] = "Bilder um Aktionsleisten, Statusleisten und Mikromenü. Sie liegen unter den Elementen, später eingeblendete Leisten (Haustierbalken, Fahrzeug-verlassen-Knopf) verdecken sie also."
L["Position elements"] = "Elemente positionieren"
L["Moves and scales the elements to the skin's positions and keeps them there, also after the Edit Mode. Without this option the artwork follows the elements wherever they are. Switching it off keeps the current positions until /reload."] = "Verschiebt und skaliert die Elemente auf die Positionen des Skins und hält sie dort, auch nach dem Bearbeitungsmodus. Ohne diese Option folgen die Bilder den Elementen, wo immer sie stehen. Nach dem Ausschalten bleiben die aktuellen Positionen bis /reload erhalten."
L["The elements keep their positions until /reload."] = "Die Elemente behalten ihre Positionen bis /reload."
L["Monitor the skin is placed on. Automatic: the monitor with the 3D view (qnViewPort), otherwise the largest."] = "Monitor, auf dem der Skin liegt. Automatisch: der Monitor mit der 3D-Ansicht (qnViewPort), sonst der größte."
L["Horizontal offset"] = "Horizontaler Versatz"
L["Vertical offset"] = "Vertikaler Versatz"
L["Scale"] = "Skalierung"
L["Scale of the artwork and - with 'Position elements' - of the elements."] = "Skalierung der Bilder und – mit „Elemente positionieren“ – der Elemente."
L["Pause figures in combat"] = "Figuren im Kampf anhalten"
L["The 3D figures of the skin stand still while you are in combat."] = "Die 3D-Figuren des Skins stehen still, solange du im Kampf bist."
L["Figures"] = "Figuren"
L["Zoom"] = "Zoom"
L["Distance of the camera: larger values show the figure smaller."] = "Abstand der Kamera: größere Werte zeigen die Figur kleiner."
L["Sideways"] = "Seitlich"
L["Height"] = "Höhe"
L["Moves the figure up or down within its area. Parts outside the area are cut off."] = "Verschiebt die Figur innerhalb ihres Bereichs nach oben oder unten. Teile außerhalb des Bereichs werden abgeschnitten."
L["Rotation"] = "Drehung"
L["Area below"] = "Bereich unten"
L["Area above"] = "Bereich oben"
L["Extends the area of the figure downwards (UI units). The figure is cut off at its area; a larger area usually shows it larger - correct with Zoom."] = "Erweitert den Bereich der Figur nach unten (UI-Einheiten). Die Figur wird an ihrem Bereich abgeschnitten; ein größerer Bereich zeigt sie meist größer – mit Zoom ausgleichen."
L["Extends the area of the figure upwards (UI units). The figure is cut off at its area; a larger area usually shows it larger - correct with Zoom."] = "Erweitert den Bereich der Figur nach oben (UI-Einheiten). Die Figur wird an ihrem Bereich abgeschnitten; ein größerer Bereich zeigt sie meist größer – mit Zoom ausgleichen."
L["Number of the animation (0 = standing). Which number lets a figure lie or sleep depends on the model - try it out."] = "Nummer der Animation (0 = stehend). Welche Nummer eine Figur liegen oder schlafen lässt, hängt vom Modell ab – ausprobieren."
L["Apply again"] = "Erneut anwenden"
L["Apply"] = "Anwenden"
L["Places the elements and the artwork again now (/qnskins apply)."] = "Setzt die Elemente und die Bilder jetzt erneut (/qnskins apply)."
