# qnMarkers – Markierungsleiste und Symbole über Namensplaketten

qnMarkers fügt eine kleine, verschiebbare Leiste zum Markieren hinzu: Ein Knopf je Schlachtzugs-
markierung setzt die Bodenmarkierung (Linksklick) oder die Zielmarkierung auf dein aktuelles Ziel
(Rechtsklick). Weitere Knöpfe starten einen Bereitschaftscheck oder einen Pull-Timer, löschen die
Markierungen oder verlassen die Gruppe. Wahlweise zeigt es ein Symbol über Namensplaketten – Klasse,
Rolle, Freund oder Gildenmitglied auf einen Blick.

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
- **Symbole über Namensplaketten** (standardmäßig aus): ein Symbol über den Namensplaketten von
  freundlichen Spielern, Gruppenmitgliedern, gegnerischen Spielern, Spielern mit PvP-Markierung, NSCs
  oder Begleitern – du wählst, welche.
  - Symbol je Einheit: **Klassen**symbol, **Rollen**symbol (Gruppenmitglieder) oder eine **Textur**
    (Pfeil, Herz, Schild, Punkt, Totenschädel, Stern oder eigene), mit einer zweiten Symbolart als
    Ersatz.
  - Herzen für Freunde (Freundesliste und Battle.net), Schilde für Gildenmitglieder, Porträts für
    Begleiter.
  - Größe, Versatz, quadratisch oder rund, Hintergrund, Rahmen in Klassenfarbe – getrennt für
    freundliche und feindliche Einheiten. Wahlweise Leuchten um das Symbol deines Ziels, Ausblenden
    mit der Namensplakette, nur in Arenen.

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

### Symbole über Namensplaketten

- **Symbole über Namensplaketten anzeigen** – ein Symbol über der Namensplakette der unten gewählten
  Einheiten. Die Namensplaketten müssen im Spiel eingeschaltet sein. Standard: aus. Alle anderen
  Optionen dieser Seite und der Seiten **Freundliche Symbole** und **Feindliche Symbole** sind nur
  bei eingeschalteten Symbolen nutzbar.

**Filter** – welche Einheiten ein Symbol bekommen:

- **Freundliche Spieler** – Standard: an.
- **Gruppenmitglieder** – Standard: an.
- **Gegnerische Spieler** – Werte von Feinden kann das Spiel im Kampf verbergen; dann bekommen sie
  kein Symbol. Standard: aus.
- **Spieler mit PvP-Markierung** – Standard: aus.
- **NSCs** – Standard: aus.
- **Begleiter** – Begleiter anderer Spieler, kleiner, mit ihrem Porträt. Standard: aus.
- **Dein Begleiter** – auch wenn die Option für Begleiter aus ist. Standard: aus.
- **Nur in Arenen** – Standard: aus.

Totems und deine eigene Namensplakette bekommen nie ein Symbol.

**Rollen** – **Tanks**, **Heiler**, **Schadensverursacher** (Standard: an). Gefiltert werden nur
Gruppenmitglieder mit zugewiesener Rolle; alle anderen sind nicht betroffen.

**Besondere Symbole**

- **Freunde** – ein Herz für deine Freunde (Freundesliste und Battle.net). Standard: an.
- **Gilde** – ein Schild für Mitglieder deiner Gilde. Standard: an.

**Darstellung**

- **Klassenfarben** – Rollen- und Textursymbole in der Klassenfarbe der Einheit. Standard: an.
- **Symbole entsättigen** – Rollen- und Textursymbole vor dem Einfärben grau. Standard: an.
- **Feinde in Rot** – Rollen- und Textursymbole von Feinden in Rot. Standard: an.
- **Mit der Namensplakette ausblenden** – das Symbol wird so durchsichtig wie seine Namensplakette
  (Entfernung, nicht anvisiert). Standard: aus.
- **Leuchten am Ziel** – ein Leuchten um das Symbol deines aktuellen Ziels, mit **Farbe**.
  Standard: aus, weiß.
- **Textur** – Symbol der Symbolart „Textur“: **Pfeil**, **Herz**, **Schild**, **Punkt**,
  **Totenschädel**, **Stern** oder **Eigene Textur**. Standard: Pfeil.
- **Eigene Textur** – Knopf **Bearbeiten …** legt die Datei oder den Atlas der „Eigenen Textur“ fest
  (z. B. `Interface\Icons\INV_Misc_QuestionMark`).
- **Drehung** – der Textur, 0–360°. Standard: 0°.
- **Größe der Begleiter** – Größe der Begleiter anderer Spieler, 25–100 %. Standard: 50 %.

### Freundliche Symbole / Feindliche Symbole

Dieselben Optionen, einmal für freundliche Einheiten (auch neutrale und alle Gruppenmitglieder) und
einmal für feindliche:

- **Symbolart** – **Klasse** (Klassensymbol von Spielern), **Rolle** (Rolle von Gruppenmitgliedern)
  oder **Textur** (die auf der Seite „Symbole über Namensplaketten“ gewählte Textur). Standard: Klasse.
- **Sonst** – Symbolart, wenn die erste nicht verfügbar ist (z. B. keine Rolle oder kein Spieler):
  **Nichts**, **Klasse**, **Rolle** oder **Textur**. Standard: Textur.
- **Symbolgröße** – 16–100. Standard: 40.
- **Horizontaler Versatz**, **Vertikaler Versatz** – Lage über der Namensplakette, −100 bis 100.
  Standard: 0 und 10.
- **Form** – **Quadrat** oder **Rund**. Standard: Quadrat.
- **Hintergrund** – schwarzer Hintergrund hinter dem Symbol, mit **Innenabstand** 0–10.
  Standard: an, 1.
- **Rahmen** – Rahmen in der Klassenfarbe von Spielern. Standard: an.

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
- Die Symbole über Namensplaketten brauchen die Namensplaketten des Spiels (Taste V oder die
  Interface-Optionen). Rollen kennt das Spiel nur für Gruppenmitglieder; gegnerische Spieler bekommen
  daher nie ein Rollensymbol.
- Manche Werte (Klasse, Rolle, PvP-Zustand) kann das Spiel verbergen, meist bei Feinden im Kampf. Dann
  wird die Regel, die den Wert braucht, übersprungen: Statt des Klassensymbols erscheint zum Beispiel
  das Symbol aus „Sonst“, und der Rahmen entfällt.

[← Übersicht](README.md)
