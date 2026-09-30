local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if not qnCore.GERMAN then return end

-- Core
L["No sets for your class."] = "Keine Sätze für deine Klasse."
L["Commands:\n  /qnloadout – open options\n  /qnloadout list – sets for your class"] = "Befehle:\n  /qnloadout – Optionen öffnen\n  /qnloadout list – Sätze für deine Klasse"

-- Load
L["Macro %s: the name must start with \"qn\"."] = "Makro %s: Der Name muss mit „qn“ beginnen."
L["Macro %s: exists as an account macro – the set wants a character macro."] = "Makro %s: existiert als Account-Makro – der Satz will ein Charakter-Makro."
L["Macro %s: exists as a character macro – the set wants an account macro."] = "Makro %s: existiert als Charakter-Makro – der Satz will ein Account-Makro."
L["Macro %s: no free macro place."] = "Makro %s: kein freier Makroplatz."
L["%s: this key is not on the bar with the current keyboard layout."] = "%s: Diese Taste ist beim aktuellen Tastaturlayout nicht auf der Leiste."
L["%s: this set is switched off in qnNumKeyPad."] = "%s: Dieses Set ist in qnNumKeyPad ausgeschaltet."
L["%s: keys 13 and higher do not switch with Ctrl or Alt."] = "%s: Tasten ab 13 wechseln nicht mit Strg oder Alt."
L["%s: spell %s is not known."] = "%s: Zauber %s ist nicht bekannt."
L["%s: macro %s not found."] = "%s: Makro %s nicht gefunden."
L["Sets cannot be loaded in combat."] = "Sätze können im Kampf nicht geladen werden."
L["Something is on the cursor – place or drop it first."] = "Am Mauszeiger hängt etwas – zuerst ablegen oder fallen lassen."
L["Set %s loaded: %d macros created, %d changed, %d numpad keys set, %d cleared."] = "Satz %s geladen: %d Makros angelegt, %d geändert, %d Ziffernblocktasten belegt, %d geleert."
L["Skipped: %s"] = "Übersprungen: %s"

-- Options
L["Sets for %s:"] = "Sätze für %s:"
L["%d macros, %d numpad keys"] = "%d Makros, %d Ziffernblocktasten"
L["No sets for %s. Sets come from AddOns\\qnLoadout\\Sets (JSON, converted with tools\\Convert-QnLoadout.ps1)."] = "Keine Sätze für %s. Sätze kommen aus AddOns\\qnLoadout\\Sets (JSON, umgewandelt mit tools\\Convert-QnLoadout.ps1)."
L["Load set %s?\nqn macros are created or changed and the numpad keys of the set are assigned for this character."] = "Satz %s laden?\nqn-Makros werden angelegt oder geändert und die Ziffernblocktasten des Satzes für diesen Charakter belegt."
L["Load"] = "Laden"
L["Enter a name for the export."] = "Gib einen Namen für den Export ein."
L["%d slots with other content (items, mounts …) were left out."] = "%d Plätze mit anderem Inhalt (Gegenstände, Reittiere …) wurden ausgelassen."
L["Exported as %s. After logging out or /reload, tools\\Convert-QnLoadout.ps1 -Import writes it into Sets as a JSON file."] = "Exportiert als %s. Nach dem Ausloggen oder /reload schreibt tools\\Convert-QnLoadout.ps1 -Import ihn als JSON-Datei nach Sets."
L["Loads a set of qn macros and numpad assignments (qnNumKeyPad) for your class. Only macros whose name starts with \"qn\" are created or changed – other macros stay untouched, nothing is deleted. Numpad keys listed in the set are assigned or cleared, all others stay unchanged. Not possible in combat."] = "Lädt einen Satz aus qn-Makros und Ziffernblock-Belegungen (qnNumKeyPad) für deine Klasse. Nur Makros, deren Name mit „qn“ beginnt, werden angelegt oder geändert – andere Makros bleiben unberührt, nichts wird gelöscht. Im Satz aufgeführte Ziffernblocktasten werden belegt oder geleert, alle anderen bleiben unverändert. Im Kampf nicht möglich."
L["Set:"] = "Satz:"
L["Load set"] = "Satz laden"
L["Export"] = "Exportieren"
L["Saves the numpad assignments of this character (normal actions and the switched-on Ctrl/Alt sets) and its qn macros as a set: spells by ID, macros by name. Items and other content are left out."] = "Speichert die Ziffernblock-Belegung dieses Charakters (normale Aktionen und die eingeschalteten Strg-/Alt-Sets) und seine qn-Makros als Satz: Zauber per ID, Makros per Name. Gegenstände und anderer Inhalt werden ausgelassen."
L["%s: spell %s is not in Spells.json."] = "%s: Zauber %s steht nicht in Spells.json."
L["Spells without English name in Spells.json (exported by ID): %s"] = "Zauber ohne englischen Namen in Spells.json (per ID exportiert): %s"
L["Item %s: name not loaded, stays in English in the macros."] = "Gegenstand %s: Name nicht geladen, bleibt in den Makros englisch."
L["Item names not loaded, not translated into English: %s"] = "Gegenstandsnamen nicht geladen, nicht ins Englische übersetzt: %s"
