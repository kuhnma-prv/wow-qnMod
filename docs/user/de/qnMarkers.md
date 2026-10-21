# qnMarkers – Markierungsleiste

qnMarkers fügt eine kleine, verschiebbare Leiste zum Markieren hinzu: Ein Knopf je Schlachtzugs-
markierung setzt die Bodenmarkierung (Linksklick) oder die Zielmarkierung auf dein aktuelles Ziel
(Rechtsklick). Weitere Knöpfe starten einen Bereitschaftscheck oder einen Pull-Timer, löschen die
Markierungen oder verlassen die Gruppe.

## Funktionen

- Acht Markierungsknöpfe (Totenschädel, Mond, Kreis, Stern, Kreuz, Diamant, Dreieck, Quadrat).
  - **Linksklick**: setzt die Bodenmarkierung dieses Symbols. Gesetzte Bodenmarkierungen leuchten
    auf der Leiste, auch die anderer Gruppenmitglieder.
  - **Rechtsklick**: setzt die Zielmarkierung auf dein aktuelles Ziel.
  - Ohne Bodenmarkierungen (der Client meldet sie als nicht verfügbar) setzen beide Klicks die
    Zielmarkierung.
- Hilfsknöpfe, jeder abschaltbar: **Bereitschaft**, **Pull-Timer 5 und 10 Sekunden**,
  **Bodenmarkierungen löschen**, **Zielmarkierung löschen**, **Gruppe verlassen** (fragt vorher;
  standardmäßig aus).
- Der **Griff** (erster Knopf, „-“/„+“): ziehen verschiebt die Leiste, Linksklick minimiert/klappt
  auf, Rechtsklick löscht alle Bodenmarkierungen und die Markierung deines Ziels.
- Horizontal oder vertikal, schwebend (ohne Hintergrund und Rahmen), Skalierung, Symbolgröße,
  Knopfabstand, Rahmen- und Hintergrundfarbe.
- Sichtbarkeit: immer, in einer Gruppe oder im Schlachtzug – wechselt auch im Kampf. Wahlweise nur
  als Gruppenleiter oder Schlachtzugsassistent.
- Funktioniert auch mit Tastenbelegungen: Die Knöpfe heißen `qnMarkersBarMarker1` …
  `qnMarkersBarMarker8` (Reihenfolge der Leiste), `qnMarkersBarClearWorld`,
  `qnMarkersBarClearTarget`, `qnMarkersBarGrip`; ein Makro wie
  `/click qnMarkersBarMarker1 RightButton` setzt den Totenschädel auf dein Ziel.

## Erste Schritte

Die Leiste erscheint nach dem Einloggen in der oberen Bildschirmhälfte. Zieh sie am Griff an die
gewünschte Stelle. Die Optionen öffnest du mit `/qnmarkers` oder unter *Optionen → Addons →
qnMarkers*.

Bereitschaftscheck, Pull-Timer und Markierungen in einer Gruppe brauchen Leiter- oder
Assistentenrechte; das entscheidet das Spiel, die Leiste bietet nur die Knöpfe an.

## Optionen

Alle Einstellungen werden pro Profil gespeichert (= pro Layout des Bearbeitungsmodus, siehe qnCore).

### qnMarkers

**Markierungsleiste**

- **Leiste anzeigen** – zeigt die Leiste. Standard: an.
- **Sichtbarkeit** – **Immer**, **In einer Gruppe** (Gruppe oder Schlachtzug) oder **Im
  Schlachtzug**. Gilt auch im Kampf. Standard: Immer.
- **Nur als Leiter oder Assistent** – blendet die Leiste aus, solange du weder Gruppenleiter noch
  Schlachtzugsassistent bist. Wird nach dem Kampf neu geprüft. Standard: aus.
- **Position sperren** – verhindert das Verschieben der Leiste an ihrem Griff. Standard: aus.
- **Tooltips anzeigen** – Tooltips an den Knöpfen. Standard: an.

**Knöpfe**

- **Bereitschaft**, **Pull-Timer: 5 Sekunden**, **Pull-Timer: 10 Sekunden**,
  **Bodenmarkierungen löschen**, **Zielmarkierung löschen** – Standard: an.
- **Gruppe verlassen** – fragt vorher nach. Standard: aus.

**Darstellung**

- **Ausrichtung** – **Horizontal** oder **Vertikal**. Standard: Horizontal.
- **Schwebend** – ohne Hintergrund und Rahmen: nur die Knöpfe sind sichtbar. Standard: aus.
- **Skalierung** – 50–200 %. Standard: 100 %.
- **Symbolgröße** – Größe der Knöpfe, 20–42. Standard: 28.
- **Knopfabstand** – 0–8. Standard: 2 (der Rand der Leiste wächst mit).
- **Randfarbe** – Farbe des Rahmens von Leiste und Knöpfen. Nicht im schwebenden Modus.
- **Hintergrundfarbe** und **Deckkraft des Hintergrunds** – Hintergrund der Leiste. Nicht im
  schwebenden Modus.

**Position**

- **Automatisch im sichtbaren Bereich halten** – holt die Leiste nach dem Verschieben, beim
  Einloggen und bei geänderter Monitoranordnung zurück auf einen Monitor. Mit qnViewPort und
  Monitordaten zählen nur Bereiche, die auf einem Monitor wirklich sichtbar sind. Standard: aus.
- **Leiste suchen** – Knopf **In sichtbaren Bereich holen** holt die Leiste sofort auf den nächsten
  sichtbaren Monitor (wie `/qnmarkers visible`).
- **Position zurücksetzen** – setzt die Leiste an ihre Standardposition zurück.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qnmarkers` (oder `/qnmk`, `/qnmarkers config`, `/qnmarkers options`) | Öffnet die Optionen |
| `/qnmarkers show` / `hide` / `toggle` | Blendet die Leiste ein oder aus |
| `/qnmarkers lock` / `unlock` | Sperrt oder entsperrt die Position |
| `/qnmarkers reset` | Setzt die Position zurück |
| `/qnmarkers visible` | Holt die Leiste in den sichtbaren Bereich |
| `/qnmarkers <sonstiges>` | Zeigt die Befehlshilfe im Chat |

## Tipps & Hinweise

- Benötigt qnCore.
- Im Kampf sperrt das Spiel Änderungen an der Leiste: geänderte Optionen, Minimieren und die Prüfung
  „nur als Leiter oder Assistent“ werden nach dem Kampf übernommen. Die Sichtbarkeit nach Gruppe und
  Schlachtzug wechselt auch im Kampf.
- Eine Bodenmarkierung wird erst gesetzt, wenn du auf den Boden klickst; das Leuchten folgt kurz danach.
- Ist die Leiste verschwunden, prüfe **Sichtbarkeit** und **Nur als Leiter oder Assistent** oder gib
  `/qnmarkers show` ein.

[← Übersicht](README.md)
