# qnTooltip – anpassbare Tooltips

qnTooltip verändert das Aussehen der Tooltips im Spiel und ergänzt Informationen: eigener
Hintergrund und Rahmen, Schriften und Skalierung, auf Wunsch eine andere Position, Kopfzeilen von
Einheiten aus frei anordenbaren Bausteinen, ein gestalteter Lebensbalken mit Werten, das Ziel der
Einheit, „Anvisiert von“, ein 3D-Modell, die Gegenstandsstufe von Spielern sowie IDs von
Gegenständen, Zaubern und Quests. Alle Einstellungen liegen im aktiven Profil (Layout des
Bearbeitungsmodus).

## Funktionen

- Eigener Hintergrund (Blizzard-Texturen, Muster von qnCore, Hintergründe aus LibSharedMedia),
  Hintergrund- und Rahmenfarbe, Rahmenstil, Skalierung, heller Verlauf über der Kopfzeile,
  Schriften für Kopfzeile und Text.
- Gestaltet auf Wunsch auch Link-, Vergleichs- und Freundes-Tooltips.
- Position nur auf Wunsch: am Mauszeiger, rechts davon oder an einem festen Punkt; getrennt für
  Spieler und NSC; auf Wunsch im Kampf oder über Einheitenrahmen wieder an Blizzards Stelle.
- Tooltips im Kampf ausblenden und mit einer Zusatztaste trotzdem zeigen.
- Lebensbalken: Lage, Höhe, Textur, Farbmodus, Lebenspunkte und Prozent.
- Einheiten-Tooltips: Kopfzeilen von Spielern und NSC aus Bausteinen (Name, Titel, Gilde, Stufe,
  Klasse, Symbole …) mit Zeile, Reihenfolge, Farbe, Format und Filter je Baustein.
- Rahmen-/Hintergrundfarbe je Einheitenart (Klasse, Reaktion, Stufe …), Tote in Grau, großes
  Fraktionswappen.
- Ziel der Einheit („>>IHR<<“, wenn sie dich anvisiert), Gruppenmitglieder, die die Einheit
  anvisieren, 3D-Modell.
- Gegenstandsstufe anderer Spieler (per Betrachten) und des eigenen Charakters.
- Gegenstände, Zauber, Quests: Rahmen in Qualitäts-/Schwierigkeitsfarbe, Symbol vor dem Namen,
  Gegenstands-/Zauber-/Quest-/Symbol-IDs, Stapelgröße.
- Tooltips beim Überfahren von Links im Chat.

## Erste Schritte

Öffne *Optionen → Addons → qnTooltip* oder gib `/qntt` ein. Unter der Hauptseite liegen die
Seiten **Darstellung**, **Position**, **Lebensbalken**, **Spieler**, **NSC**,
**Gegenstände & Zauber**, **Zeilen: Spieler** und **Zeilen: NSC**.

Alle Einstellungen gehören zum aktiven Profil, also zum aktiven Layout des Bearbeitungsmodus
(Profile verwaltest du auf der Seite **Profile** von qnCore).

## Optionen

### qnTooltip

**Allgemein**

- **Auch Link-, Vergleichs- und Freundes-Tooltips gestalten** – überträgt das Aussehen auch auf
  die Tooltips von Chat-Links, die Vergleichs-Tooltips von Gegenständen und den Tooltip der
  Freundesliste. Beim Abschalten behalten diese Tooltips ihr Aussehen bis zum nächsten `/reload`.
  Standard: an.
- **Hinweis zum Rechtsklick an Einheitenrahmen entfernen** – entfernt die Zeile
  „<Mit Rechtsklick die Rahmen-Einstellungen aufrufen>“ aus den Tooltips der Einheitenrahmen.
  Standard: an.
- **Tooltip beim Überfahren von Chat-Links** – zeigt beim Überfahren von Gegenstands-, Zauber-,
  Verzauberungs-, Quest-, Talent-, Erfolgs- und Währungslinks im Chat deren Tooltip am
  Mauszeiger. Standard: an.
- **Mit Alt oder Strg alle Bausteine zeigen** – solange Alt oder Strg gedrückt ist, zeigen
  Einheiten-Tooltips auch abgeschaltete und gefilterte Bausteine. Standard: an.

### Darstellung

**Anzeige**

- **Skalierung** – Größe der Tooltips, 0,50 bis 2,00. Standard: 1,00.
- **Hintergrund** – Fels, Marmor, Dunkel, Durchscheinend, Flach, dazu die Muster von qnCore und
  die Hintergründe aus LibSharedMedia (falls installiert). Standard: Fels.
- **Hintergrundfarbe** / **Deckkraft des Hintergrunds** – Standard schwarz, 70 %.
- **Rahmen** – Standard (Blizzards Tooltip-Rahmen), Eckig (dünne, durchgehende Linie) oder
  Nichts. Standard: Standard.
- **Rahmenbreite (eckig)** – 1 bis 8, nur für „Eckig“. Standard: 1.
- **Rahmenfarbe** / **Deckkraft des Rahmens** – Standard grau, 80 %.
- **Heller Verlauf über der Kopfzeile** – Standard: an.

**Schriften** – jeweils für **Kopfzeile** (erste Zeile) und **Textzeilen**:

- **Schriftart: …** – Standard oder eine Schriftart aus LibSharedMedia. Standard: Standard.
- **Schriftgröße: …** – 0 bis 24; 0 (angezeigt als „Standard“) = Blizzards Größe. Standard: 0.
- **Umriss: …** – Standard, Ohne Umriss, Dünner Umriss, Umriss, Dicker Umriss.
  Standard: Standard.

### Position

qnTooltip versetzt nur Tooltips, die Blizzard an seine Standardstelle setzt (Einheiten in der
Welt, Einheitenrahmen, Aktionsleisten …), und nur, wenn nicht „Blizzard-Standard“ gewählt ist.

**Position**

- **Position** – Blizzard-Standard (Bearbeitungsmodus), Am Mauszeiger, Rechts vom Mauszeiger,
  Fester Punkt. Standard: Blizzard-Standard (Bearbeitungsmodus).
- **Fester Punkt: Anker** – Bildschirmpunkt für „Fester Punkt“ (Oben links … Unten rechts).
  Standard: Unten rechts.
- **Fester Punkt: X-Versatz** / **Fester Punkt: Y-Versatz** – −1000 bis 1000.
  Standard: −60 / 120.
- **Position für Spieler** / **Position für NSC** – eigene Position für Einheiten-Tooltips von
  Spielern bzw. NSC, oder „Wie allgemein eingestellt“. Standard: Wie allgemein eingestellt.
- **Im Kampf an Blizzards Stelle** – im Kampf bleibt der Tooltip an Blizzards Stelle.
  Standard: an.
- **Über Einheitenrahmen an Blizzards Stelle** – über Einheitenrahmen bleibt der Tooltip an
  Blizzards Stelle. Standard: aus.

**Kampf**

- **Tooltip im Kampf ausblenden** – blendet Tooltips an Blizzards Standardstelle im Kampf aus.
  Standard: aus.
- **Mit dieser Taste trotzdem zeigen** – Nichts, ALT-Taste, STRG-Taste, Umschalttaste. Solange die
  Taste im Kampf gedrückt ist, erscheint der Tooltip trotzdem; drückst du sie über einer Einheit,
  erscheint deren Tooltip. Standard: Nichts.

### Lebensbalken

**Lebensbalken**

- **Lebensbalken ausblenden** – Standard: aus.
- **Höhe** – 1 bis 20. Standard: 4.
- **Lage** – Auf dem unteren Rand, Auf dem oberen Rand, Unter dem Tooltip (Blizzard).
  Standard: Auf dem unteren Rand.
- **Seitlicher Abstand** – 0 bis 30; 0 (angezeigt als „Standard“) = passend zum Rahmen.
  Standard: 0.
- **Textur** – Blizzard, Flach, Schlachtzug, dazu die Balkentexturen aus LibSharedMedia.
  Standard: Blizzard.
- **Farbe** – Blizzard (grün), Klassen- bzw. Auswahlfarbe (Spieler in Klassenfarbe, andere in der
  Auswahlfarbe), Nach Gesundheit (grün – gelb – rot). Standard: Klassen- bzw. Auswahlfarbe.

**Text**

- **Lebenspunkte anzeigen** – „aktuell / maximal“. Standard: an.
- **Prozent anzeigen** – Standard: an. Bei toten Einheiten erscheint „<Tot>“.
- **Schriftart: Lebensbalken**, **Schriftgröße: Lebensbalken**, **Umriss: Lebensbalken** – wie auf
  der Seite Darstellung. Standard: Standard, 10, Dünner Umriss.

### Spieler und NSC

Beide Seiten haben dieselben Einstellungen; sie gelten für die Einheiten-Tooltips von Spielern
bzw. NSC.

- **Rahmenfarbe** – Standard, Klassenfarbe, Farbe der Stufe, Farbe der Reaktion, Farbe der
  Fraktion, Farbe der Auswahl. Standard: Klassenfarbe (Spieler), Farbe der Reaktion (NSC).
- **Hintergrundfarbe** – dieselbe Auswahl; „Standard“ nimmt die allgemeine Hintergrundfarbe.
  Standard: Klassenfarbe (Spieler), Standard (NSC).
- **Deckkraft des Hintergrunds** – Standard 90 %.
- **Ziel anzeigen** – ergänzt eine Zeile „Ziel: …“ mit dem Ziel der Einheit, laufend
  aktualisiert; „>>IHR<<“, wenn sie dich anvisiert. Standard: an.
- **'Anvisiert von' anzeigen** – Gruppen- und Schlachtzugsmitglieder, die die Einheit anvisieren.
  Bei NSC im Schlachtzug erscheint nur ihre Anzahl. Standard: an.
- **3D-Modell anzeigen** – Modell der Einheit über dem Tooltip; mit gedrückter Strg- oder Alt-Taste
  dreht es sich. Standard: an.
- **Tote grau darstellen** – Standard: aus.
- **Großes Fraktionswappen** – Wappen der Allianz/Horde oben rechts im Tooltip.
  Standard: an (Spieler), aus (NSC).
- **Zeilen** – die Schaltfläche **Zeilen bearbeiten …** öffnet die Seite Zeilen: Spieler bzw.
  Zeilen: NSC.

### Zeilen: Spieler und Zeilen: NSC

Die Kopfzeilen eines Einheiten-Tooltips bestehen aus diesen Bausteinen. Die Liste zeigt sie in der
Reihenfolge, in der sie im Tooltip erscheinen. Je Zeile:

- Kontrollkästchen – Baustein an/aus,
- **Zeile** – Tooltip-Zeile 1 bis 8 (der Baustein kommt ans Ende dieser Zeile),
- **Reihenfolge** – Pfeile verschieben den Baustein innerhalb seiner Zeile,
- **Vorschau** – Beispielwert in seiner Farbe und seinem Format (dein eigener Charakter bzw. auf
  der NSC-Seite der anvisierte NSC),
- Stift (**Bearbeiten**) – öffnet den Dialog **Baustein: …**:
  - **Farbe** – Standard, Klassenfarbe, Farbe der Stufe, Farbe der Reaktion, Farbe der Fraktion,
    Farbe der Auswahl oder **Eigene Farbe …** (Farbwähler).
  - **Filter** – Nichts, oder „nur …“/„nicht …“ in einer Gruppe, im Schlachtzug, im Kampf, in
    einer Instanz, auf einem Schlachtfeld, in der Arena, vom eigenen Realm, aus der eigenen Gilde,
    Ruf ab freundlich, Ruf ab wohlwollend.
  - **Format** – Text um den Wert mit genau einem `%s` (bei Zahlen auch `%d`); ein Prozentzeichen
    schreibst du als `%%`. Farbcodes wie `|cffff0000rot|r` färben einen Teil. Eine Vorschau zeigt
    das Ergebnis; die Beispiele darunter übernimmst du per Klick.
  - **OK** übernimmt, **Abbrechen** (oder Schließen) stellt die vorherigen Werte wieder her.

  Symbole haben weder Farbe noch Format – für sie gilt nur der Filter.

Oben zeigt **Vorschau** den echten Tooltip deines eigenen Charakters (Spieler) bzw. des
anvisierten NSC. **Standard** setzt nach einer Rückfrage alle Bausteine dieser Seite auf die
Vorgaben zurück.

Bausteine und ihre Vorgabe:

| Baustein (Spieler) | Vorgabe |
|---|---|
| Freundes-Symbol, Zielmarkierung, Rollen-Symbol, PvP-Symbol (Jeder gegen jeden), Fraktions-Symbol, Klassen-Symbol, Titel, Name, Nachname, Realm, AFK, DND, Offline | Zeile 1, an |
| Gilde, Rang, Realm der Gilde | Zeile 2, an |
| Gildenrang-Nummer | Zeile 2, aus |
| Stufe, Fraktion, Volk, Klasse | Zeile 3, an |
| Geschlecht, Spieler, Rolle, Bewegungstempo | Zeile 3, aus |
| Gegenstandsstufe | Zeile 4, an |
| Zone (nur Schlachtzugsmitglieder) | Zeile 5, aus |

| Baustein (NSC) | Vorgabe |
|---|---|
| Zielmarkierung, Quest-Symbol, Name | Zeile 1, an |
| Klassen-Symbol | Zeile 1, aus |
| Titel (immer in Blizzards Titelzeile, z. B. „<Gastwirt>“; nur Farbe und Format) | an |
| Stufe, Boss, Elite, Selten, Kreaturtyp | Zeile 2, an |
| Ruf (Filter: nur Ruf ab wohlwollend) | Zeile 2, an |
| Bewegungstempo | Zeile 2, aus |

Die Gegenstandsstufe deines eigenen Charakters stammt aus der angelegten Ausrüstung; bei anderen
Spielern wird sie außerhalb des Kampfes per Betrachten abgefragt und zeigt „??“, bis sie bekannt ist.

### Gegenstände & Zauber

**Gegenstände**

- **Rahmen in der Farbe der Qualität** – Standard: an.
- **Symbol vor dem Namen** – Standard: an.
- **Gegenstands-ID**, **Symbol-ID**, **Stapelgröße** (nur bei stapelbaren Gegenständen) –
  Standard: an.

**Zauber**

- **Symbol vor dem Namen**, **Zauber-ID**, **Symbol-ID** – Standard: an. Zauber-ID und Symbol-ID
  erscheinen auch in den Tooltips von Stärkungs- und Schwächungszaubern.
- **Hintergrundfarbe** / **Deckkraft des Hintergrunds** – für Zauber-Tooltips. Standard schwarz,
  80 %.
- **Rahmenfarbe** / **Deckkraft des Rahmens** – für Zauber-Tooltips. Standard grau, 80 %.

**Quests**

- **Rahmen in der Farbe der Schwierigkeit** – Standard: an.
- **Quest-ID** – Standard: an.

**IDs**

- **IDs nur mit gedrückter Umschalt-, Strg- oder Alt-Taste** – Standard: aus.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qntt`, `/qntooltip` (auch `config`, `options`) | Optionen öffnen |
| `/qntt reset` | Alle Einstellungen des aktiven Profils zurücksetzen |
| `/qntt` + etwas anderes | Liste der Befehle zeigen |

## Tipps & Hinweise

- Optional: [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) ergänzt
  die Auswahllisten um weitere Hintergründe, Schriftarten und Balkentexturen.
- Viele Werte von Einheiten kann das Spiel in manchen Situationen verbergen (z. B. in Instanzen
  oder im Kampf). qnTooltip zeigt sie dann ohne Klassen-/Stufenfarbe oder lässt Bausteine weg,
  deren Wert oder Filter sich nicht lesen lässt.
- Die Gegenstandsstufe anderer Spieler wird nur außerhalb des Kampfes und nicht bei geöffnetem
  Betrachten-Fenster von Blizzard abgefragt; bekannte Werte merkt sich qnTooltip 10 Minuten lang.
- „Mit Alt oder Strg alle Bausteine zeigen“ wirkt beim Aufbau des Tooltips: Halte die Taste,
  bevor du über die Einheit fährst.
- Benötigt qnCore.

[← Übersicht](README.md)
