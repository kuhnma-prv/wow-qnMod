Blizzard-GlobalStrings von WoW Classic Forever (deDE, enUS), aus
https://github.com/Ketho/BlizzardInterfaceResources, Zweig forever, Resources/GlobalStrings.
Die Dateien deDE.lua und enUS.lua liegen nicht im Repo: run.mjs und gs.mjs laden fehlende
automatisch (globalstrings.mjs). Die Testattrappe lädt die Datei der eingestellten Sprache
(QN_LOCALE, Vorgabe deDE).
Aktualisieren: node globalstrings.mjs --update
