# qnNumKeyPad – eine Aktionsleiste in Form deines Ziffernblocks

qnNumKeyPad fügt eine Aktionsleiste hinzu, deren Tasten wie der Ziffernblock deiner Tastatur (oder die Seitentasten einer Gaming-Maus) angeordnet sind. Jede Taste der Leiste ist mit ihrer Ziffernblocktaste belegt: Ziffernblock 1 … 9, 0, +, -, * oder / lösen die Aktion auf der passenden Taste aus. Optional gibt es die Enter-Taste, den Navigationsblock, Haltungswechsel, ein Strg-Set (zweite Belegung, solange Strg gehalten wird) und Unterstützung für eine Logitech G502, deren Tasten Ziffernblocktasten senden – samt einer Seite, auf der du Zauber und Makros direkt auf die Maustasten legst.

## Funktionen

- Leiste in Form eines Ziffernblocks mit sechs Tastaturlayouts: Windows, Microsoft Office, Natural Multimedia, Natural Elite, Macintosh, Razer Naga
- Die Ziffernblocktasten werden automatisch belegt, solange die Leiste aktiv und sichtbar ist; auf Wunsch auch Umschalt+Taste
- Optional Enter-Taste und Navigationstasten (Einfg, Pos1, Bild auf/ab, Entf, Ende)
- Frei wählbare Aktionsleisten-Seiten für die Tastengruppen, mit Warnung im Chat, wenn eine Seite doppelt oder auch von einer eingeblendeten Blizzard-Leiste benutzt wird
- Haltungswechsel: Tasten 1–12 folgen der Haltungs-/Gestaltleiste wie die Hauptleiste
- Strg-Set: Solange Strg gehalten wird, zeigen die Tasten 1–12 die Aktionen einer anderen Seite und lösen sie aus
- Schutz gegen versehentliches Herausziehen von Aktionen (immer oder nur im Kampf)
- Darstellung: Skalierung, Abstände, Deckkraft, Hintergrund, Tastenbeschriftung, Schriftgröße, Symbolzoom, Richtung von Aufklappmenüs, Mausklicks durchlassen
- Sichtbarkeit: Ausblenden ohne Maus, Verbergen im Kampf/Fahrzeug/in Verstohlenheit/Haltung/mit oder ohne Begleiter oder per eigener Makrobedingung
- Position per Ziehen oder exakten Werten, Zentrieren, Zurücksetzen, automatisch im sichtbaren Bereich halten (mit qnViewPort auch bei mehreren Monitoren)
- Gaming-Maus (Logitech G502): Zuordnung Maustaste → Ziffernblocktaste und eine Seite, um Zauber und Makros auf die Maustasten zu legen

## Erste Schritte

Öffne *Optionen → Addons → qnNumKeyPad* oder gib `/qnnkp` ein. Das Addon hat diese Seiten: **qnNumKeyPad** (Allgemein und Tastatur), **Darstellung**, **Position**, **Sichtbarkeit**, **Aktionsplätze**, **Maus** und **Maustasten**.

Nach dem ersten Einloggen ist die Leiste entsperrt: Sie zeigt eine grüne Fläche mit der Aufschrift „qnNumKeyPad“. Zieh sie mit der linken Maustaste an ihren Platz, ein Rechtsklick öffnet die Optionen. Wenn du fertig bist, sperrst du sie mit `/qnnkp lock` (oder **Position sperren**). Danach ziehst du Zauber, Makros oder Gegenstände auf die Tasten wie bei jeder Aktionsleiste.

Speicherung: Alle Einstellungen außer den Seiten **Maus** und **Maustasten** gehören zum aktiven Profil. Ein Profil ist das aktive Layout des Bearbeitungsmodus (verwaltet von qnCore, Seite *qnCore → Profile*); wechselst du das Layout, wechseln auch die Einstellungen. Die Seite **Maus** gilt accountweit. Die Aktionen auf den Tasten selbst sind normale Aktionsplätze von WoW und werden von WoW pro Charakter gespeichert.

## Optionen

### qnNumKeyPad

**Allgemein**

- **Ziffernblock aktiv** – Aus: Leiste ausgeblendet und alle Tastenbelegungen des Ziffernblocks aufgehoben. Standard: an.
- **Position sperren** – Verhindert versehentliches Verschieben. Entsperrt zeigt die Leiste eine grüne Fläche zum Ziehen (Rechtsklick darauf öffnet die Optionen), leere Tasten werden angezeigt und die Leiste ist immer sichtbar. Standard: aus.
- **Aktionen immer sperren** – Aktionen lassen sich nur mit gehaltener Taste für „Aktion aufnehmen“ (Standard: Umschalt) herausziehen. Wirkt zusätzlich zur Blizzard-Einstellung „Aktionsleisten sperren“. Standard: aus.
- **Aktionen im Kampf sperren** – Derselbe Schutz, aber nur im Kampf. Standard: an.

**Tastatur**

- **Tastaturlayout** – Anordnung der Tasten: Windows, Microsoft Office, Natural Multimedia, Natural Elite, Macintosh, Razer Naga. Macintosh enthält zusätzlich die Tasten = und Clear des Mac-Ziffernblocks; Razer Naga zeigt die 12 Seitentasten (1–12). Standard: Windows.
- **Enter-Taste anzeigen** – Fügt die Enter-Taste hinzu. Achtung: belegt Enter und hebt damit „Chat öffnen“ auf, solange der Ziffernblock aktiv ist. Standard: aus.
- **Navigationstasten anzeigen** – Fügt Einfg, Pos1, Bild auf/ab, Entf und Ende hinzu (bei Microsoft Office auch Tab). Überschreibt deren bisherige Belegung (Chat-Bildlauf, Kamera). Standard: aus.
- **Pfeiltasten anzeigen** – Vorerst nicht verfügbar (ausgegraut): Die Pfeiltasten bräuchten Seite 15, die das Strg-Set benutzt.
- **Auch mit Umschalttaste belegen** – Umschalt+Taste löst dieselbe Aktion aus. Verhindert, dass Umschalt+Ziffernblock die Standardbelegung (z. B. Leistenwechsel) auslöst. Standard: an.
- **Haltungswechsel** – Tasten 1–12 folgen der Haltungs-/Gestaltleiste wie die Hauptleiste (z. B. Kampfhaltung, Katzengestalt, Verstohlenheit). Ohne Haltung gelten die eigenen Plätze der Leiste. Standard: aus.

### Darstellung

**Größe und Abstände**

- **Skalierung** – 0,30 bis 2,00. Standard: 1,00.
- **Abstand waagerecht** / **Abstand senkrecht** – Abstand zwischen den Tasten, 0 bis 30. Standard: 1.
- **Abstand zum Zusatzblock** – Zusätzlicher Abstand zwischen Ziffernblock und Navigationstasten, 0 bis 80. Standard: 0.

**Anzeige**

- **Deckkraft** – Deckkraft der ganzen Leiste. Standard: 100 %.
- **Deckkraft des Hintergrunds** – Schwarzer Hintergrund hinter der Leiste. Standard: 0 %.
- **Leere Tasten anzeigen** – Aus: Tasten ohne Aktion werden ausgeblendet (entsperrt und beim Ziehen einer Aktion erscheinen sie trotzdem). Standard: an.
- **Tastenbeschriftung** – **Kurz (1, 2, +, …)**, **Tastenname (Num 1, …)** oder **Keine**. Standard: Kurz.
- **Schriftgröße der Beschriftung** – 0 bis 24; 0 = **Standard**. Standard: Standard.
- **Makrotext ausblenden** – Blendet den Makronamen auf den Tasten aus. Standard: aus.
- **Rahmen für ausgerüstete Gegenstände ausblenden** – Blendet den grünen Rahmen ausgerüsteter Gegenstände aus. Standard: aus.
- **Symbole zoomen** – Schneidet den Rand der Symbole ab. Standard: aus.
- **Richtung von Aufklappmenüs** – **Oben**, **Unten**, **Links**, **Rechts**. Standard: Oben.
- **Mausklicks durchlassen** – Die Tasten reagieren nicht auf die Maus; nur die Tastatur löst sie aus. Standard: aus.

### Position

- **Position sperren** – Dieselbe Einstellung wie auf der Hauptseite.
- **Anker** – Bezugspunkt am Bildschirm und an der Leiste (Oben links … Unten rechts). Beim Wechsel bleibt die Leiste an ihrem Platz. Standard: Mitte.
- **X-Versatz** / **Y-Versatz** – Position relativ zum Anker, -3000 bis 3000. Standard: 300 / -100.
- **Waagerecht zentrieren** / **Senkrecht zentrieren** – Die Schaltfläche **Zentrieren** zentriert die Leiste in dieser Richtung.
- **Position zurücksetzen** – Die Schaltfläche **Zurücksetzen** stellt die Standardposition wieder her.
- **Automatisch im sichtbaren Bereich halten** – Holt die Leiste nach dem Verschieben, beim Einloggen und bei Änderungen der Monitoranordnung auf einen Monitor zurück. Mit qnViewPort und dessen Monitordaten zählen nur Bereiche, die wirklich auf einem Monitor zu sehen sind. Standard: aus.
- **Leiste suchen** – Die Schaltfläche **In sichtbaren Bereich holen** verschiebt die Leiste sofort auf den nächsten sichtbaren Monitor (wie `/qnnkp visible`).

### Sichtbarkeit

**Ausblenden**

- **Ausblenden ohne Maus** – Blendet die Leiste auf die unten eingestellte Deckkraft ab, solange die Maus nicht darüber ist (nur bei gesperrter Position). Standard: aus.
- **Deckkraft ausgeblendet** – Standard: 25 %. Nur einstellbar, wenn das Ausblenden an ist.
- **Verzögerung** – Wartezeit bis zum Ausblenden, 0 bis 3 s. Standard: 0,2 s. Nur einstellbar, wenn das Ausblenden an ist.

**Verbergen**

- **Eigene Bedingung verwenden** – Ersetzt alle folgenden Schalter durch eine eigene Makrobedingung. Standard: aus.
- **Im Fahrzeug / bei Übernahme verbergen** – Standard: an.
- **Im Kampf verbergen**, **Außerhalb des Kampfes verbergen**, **Mit Begleiter verbergen**, **Ohne Begleiter verbergen**, **In Verstohlenheit verbergen**, **In Haltung/Gestalt verbergen** – Standard: aus.
- **Eigene Bedingung** – Die Schaltfläche **Bearbeiten …** öffnet ein Textfeld für eine Makrobedingung mit show/hide. Standard: `[combat] show; [mod:alt] show; hide`.

Solange die Leiste verborgen ist, sind auch ihre Tastenbelegungen aufgehoben – die Tasten haben dann ihre normale Funktion. Bei entsperrter Position ist die Leiste immer sichtbar.

### Aktionsplätze

**Aktionsplätze**

Die Tasten benutzen die Plätze normaler Aktionsleisten-Seiten (je 12 Plätze). Eine Blizzard-Leiste, die dieselbe Seite benutzt, zeigt dieselben Aktionen – blende sie im Bearbeitungsmodus aus. Im Chat erscheint eine Warnung, wenn eine Seite für mehrere Tastengruppen eingestellt ist oder auch von einer eingeblendeten Blizzard-Leiste benutzt wird (Seite 1 gehört immer zur Hauptleiste).

- **Tasten 1–12** – Seite für die ersten 12 Tasten des Layouts (bei Windows: Ziffernblock 1–9, 0, Komma und +). Standard: Seite 13 – Aktionsleiste 6.
- **Tasten 13–24** – Seite für die übrigen Tasten (bei Windows: -, *, /, Enter und die Navigationstasten). Standard: Seite 14 – Aktionsleiste 7.
- **Tasten 25–28** – Nur für die Pfeiltasten; vorerst nicht verfügbar (ausgegraut).

Wählbare Seiten: 1–6 (Aktionsleiste 1 mit zweiter Seite, Aktionsleisten 2–5), 7–10 (Haltung/Gestalt 1–4) und 13–15 (Aktionsleisten 6–8).

**Modifier-Sets**

- **Strg-Set** – Solange Strg gehalten wird, zeigen die Tasten 1–12 die Aktionen einer anderen Seite und lösen sie aus (Tastatur und Maus). Tasten ab 13 wechseln nicht. Mit Strg und Alt zusammen gelten die normalen Aktionen. Standard: an.
- **Strg-Set: Seite** – Seite des Strg-Sets. Standard: Seite 15 – Aktionsleiste 8.
- **Alt-Set** / **Alt-Set: Seite** – Vorerst nicht verfügbar (ausgegraut).

### Maus

Accountweit: gilt für alle Charaktere und Profile.

- **Maus** – Gaming-Maus, deren Tasten Ziffernblocktasten senden: **Keine** oder **Logitech G502**. Standard: Keine.
- **Tastenbelegung – Logitech G502** – Pro Maustaste (G3 … G11) eine Auswahl mit der Ziffernblocktaste, die deine Maussoftware (z. B. Logitech G HUB) dieser Taste zuweist; zur Wahl stehen **Keine** und die Ziffernblocktasten. G1 (Linksklick) und G2 (Rechtsklick) sind nicht änderbar. Nur einstellbar, wenn die G502 ausgewählt ist. Standard: G3 = Ziffernblock 3, G4 = Ziffernblock 7, G5 = Ziffernblock 8, G6 = Ziffernblock 9, G7 = Ziffernblock 5, G8 = Ziffernblock 4, G9 = Ziffernblock 6, G10 = Ziffernblock 2, G11 = Ziffernblock 1.

Diese Zuordnung stellt nicht die Maus ein – sie sagt qnNumKeyPad nur, welche Taste jede Maustaste sendet. Die Maus selbst richtest du in ihrer eigenen Software ein.

### Maustasten

Legt einen Zauber oder ein Makro in den Aktionsplatz der Ziffernblocktaste, die eine Maustaste sendet; die Leiste zeigt ihn sofort an. WoW speichert diese Plätze pro Charakter. Im Kampf nicht möglich, ebenso nicht, solange etwas am Mauszeiger hängt.

- **Set:** – **Normale Aktionen** oder **Strg-Set** (Aktionen für Strg + Maustaste; nur aufgeführt, solange das Strg-Set an ist).
- Pro Maustaste eine Zeile, z. B. „G3 (Ziffernblock 3)“, mit einer Auswahl für die Art der Aktion: **Leer** (leert den Platz), **Zauber** oder **Makro**; danach **Zauber wählen …** (aktive Zauber aus deinem Zauberbuch) bzw. **Makro wählen …** (deine Account- und Charakter-Makros). **Anderes** erscheint, wenn im Platz etwas anderes liegt (Gegenstand, Reittier …).
- Hinweise in einer Zeile: keine Ziffernblocktaste zugewiesen (Seite **Maus**), Taste beim aktuellen Tastaturlayout nicht auf der Leiste, oder Tasten ab 13 wechseln nicht mit Strg.

Ohne ausgewählte Maus bittet die Seite dich, auf der Seite **Maus** eine auszuwählen. Mit Haltungswechsel benutzen die Tasten 1–12 in einer Haltung die Plätze der Haltungsleiste – diese Seite setzt die eigenen Plätze der Leiste.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qnnkp` (auch `/qnnumkeypad`, `/numpad`; `config`, `options`) | Optionen öffnen |
| `/qnnkp lock` | Position sperren |
| `/qnnkp unlock` | Position entsperren (grüne Fläche zum Ziehen) |
| `/qnnkp on` (oder `show`) | Ziffernblock einschalten |
| `/qnnkp off` (oder `hide`) | Ziffernblock ausschalten (Leiste ausgeblendet, Tastenbelegungen aufgehoben) |
| `/qnnkp reset` | Position zurücksetzen |
| `/qnnkp visible` | Leiste in den sichtbaren Bereich holen |
| anderer Text | Liste der Befehle anzeigen |

## Tipps & Hinweise

- **Kampf:** Änderungen an den Einstellungen im Kampf werden nach dem Kampf übernommen (der Chat meldet das). Im Kampf lässt sich die Leiste nicht verschieben, die grüne Fläche ist ausgeblendet, und die Seite **Maustasten** kann keine Plätze ändern. Sichtbarkeit, Haltungswechsel und Strg-Set funktionieren auch im Kampf.
- **Seiten:** Blende Blizzard-Leisten, die dieselbe Seite wie der Ziffernblock benutzen (mit den Standardwerten Aktionsleiste 6–8), im Bearbeitungsmodus aus – sonst zeigen beide dieselben Aktionen und der Chat warnt.
- **Tastenbelegung:** Die Ziffernblocktasten (und Umschalt+ bzw. Strg+ für die Tasten 1–12) belegt das Addon, solange die Leiste aktiv und sichtbar ist; deine eigenen Belegungen dieser Tasten gelten in dieser Zeit nicht.
- **qnLoadout** benutzt qnNumKeyPad, um ganze Sätze aus Ziffernblock-Belegungen und qn-Makros pro Klasse zu laden.
- **qnViewPort** (optional): Mit dessen Monitordaten benutzen „Automatisch im sichtbaren Bereich halten“ und „In sichtbaren Bereich holen“ die wirklich sichtbaren Monitore.
- Profile folgen dem Layout des Bearbeitungsmodus (qnCore); ein neues Layout beginnt als Kopie des zuvor aktiven Profils.

[← Übersicht](README.md)
