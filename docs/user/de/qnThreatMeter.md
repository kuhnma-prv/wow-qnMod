# qnThreatMeter – Bedrohungsanzeige für deine Gruppe

qnThreatMeter zeigt die Bedrohung von dir und deiner Gruppe gegen dein aktuelles Ziel in einem Fenster
im Stil der eingebauten Schadensanzeige. Es zeigt Bedrohungswerte, Prozent, Bedrohung pro Sekunde und
einen Balken „Aggro ziehen“ und warnt dich, bevor du die Aggro ziehst. Verbirgt der Client die
Bedrohungswerte (Secret-Values, typischerweise im Kampf), arbeitet das Fenster in einem
eingeschränkten Modus weiter.

## Funktionen

- Balken für jedes Gruppen- oder Schlachtzugsmitglied (wahlweise auch Begleiter) auf der
  Bedrohungsliste deines Ziels, nach Bedrohung sortiert, mit Rang, Klassensymbol und Klassenfarbe.
- Text je Balken wie bei der Schadensanzeige: Wert, Bedrohung pro Sekunde (TPS) und Prozent.
- Prozent relativ zum Tank (100 % = Tank) oder skaliert (100 % = Aggro).
- Balken **Aggro ziehen**: die Bedrohung, ab der du die Aggro bekommst (110 % Nahkampf,
  130 % Fernkampf).
- Dein eigener Balken wird immer gezeigt, auch wenn er nicht mehr ins Fenster passt.
- Warnung bei hoher Bedrohung: Ton, rotes Aufblitzen des Bildschirms und Meldung in der
  Bildschirmmitte.
- Aussehen aus dem Bearbeitungsmodus der eingebauten Schadensanzeige übernommen oder selbst
  eingestellt.
- Sichtbarkeit: immer, nur im Kampf oder nur in Gruppe/Schlachtzug.
- Testmodus mit Beispieldaten zum Einrichten des Fensters.
- **Eingeschränkter Modus** bei Secret-Values: Balken und Texte werden weiter gefüllt, aber ohne
  Sortierung, Ränge, TPS, Balken „Aggro ziehen“ und Warnungen.

## Erste Schritte

Öffne *Optionen → Addons → qnThreatMeter* (Esc → Optionen → Reiter Addons) oder tippe `/qnm config`.
`/qnm` blendet das Fenster ein oder aus, `/qnm test` füllt es mit Beispieldaten.

Das Fenster:

- **Verschieben**: mit der linken Maustaste ziehen.
- **Größe ändern**: mit dem Griff unten rechts (erscheint bei Mausberührung, ausgeblendet, wenn das
  Fenster gesperrt ist).
- **Rechtsklick** auf das Fenster oder Klick auf das Zahnrad in der Titelleiste öffnet ein Menü:
  **Fenster sperren**, **Testmodus**, **Fokusziel bevorzugen**, **Optionen …**, **Ausblenden**.
- Die Titelleiste zeigt „Bedrohung“ und rechts den Namen des Gegners. Ein oranger Name bedeutet
  eingeschränkter Modus (Secret-Values).

## Optionen

Alle Einstellungen gelten je Profil (= je Layout des Bearbeitungsmodus, siehe qnCore).

### qnThreatMeter

**Fenster**

- **Fenster anzeigen** – zeigt das Bedrohungsfenster. Standard: an.
- **Fenster sperren** – verhindert Verschieben und Größenänderung. Standard: aus.
- **Sichtbarkeit** – **Immer**, **Nur im Kampf** oder **Nur in Gruppe oder Schlachtzug**.
  Standard: Immer.
- **Titelleiste anzeigen** – Titelleiste mit Titel, Gegnername und Zahnrad. Standard: an.
- **Skalierung** – Größe des Fensters, 0,50–2,00. Standard: 1,00.
- **Automatisch im sichtbaren Bereich halten** – holt das Fenster nach dem Verschieben, beim
  Einloggen und bei Änderungen der Monitoranordnung auf einen Monitor zurück. Mit qnViewPort und
  Monitordaten zählen nur Bereiche, die wirklich auf einem Monitor zu sehen sind. Standard: aus.
- **Fenster suchen** – die Schaltfläche **In sichtbaren Bereich holen** verschiebt das Fenster jetzt
  auf den nächsten sichtbaren Monitor (wie `/qnm visible`).

**Balken**

- **Einstellungen der Schadensanzeige übernehmen** – übernimmt Stil, Balkenhöhe, Abstand, Textgröße,
  Symbole, Klassenfarben und Transparenz aus dem Bearbeitungsmodus der eingebauten Schadensanzeige
  (und folgt Änderungen dort). Die nächsten sieben Optionen sind nur nutzbar, solange das aus ist.
  Standard: an.
- **Stil** – **Standard**, **Dünn**, **Eingegrenzt** oder **Vollständiger Hintergrund**.
  Standard: Standard.
- **Balkenhöhe** – 8–40. Standard: 24.
- **Balkenabstand** – 0–10. Standard: 2.
- **Schriftgröße** – 0–24; 0 = Standardgröße der Schadensanzeige. Standard: 0.
- **Klassensymbole anzeigen** – Standard: an.
- **Klassenfarben** – färbt die Balken nach Klasse (sonst grau). Standard: an.
- **Deckkraft des Hintergrunds** – 0–100 %. Standard: 50 %.
- **Balkentextur** – **Schadensanzeige**, **Blizzard**, **Flach**, **Raid**, **Fertigkeit** sowie alle
  Balkentexturen von LibSharedMedia, falls installiert. Standard: Schadensanzeige.
- **Rang vor dem Namen** – „1. Name“. Standard: an.
- **Eigenen Balken rot färben** – Standard: aus.
- **Tank-Balken dunkelrot färben** – Standard: aus.

**Inhalt**

- **Bedrohungswert anzeigen** – Standard: an.
- **Prozent anzeigen** – Standard: an.
- **Bedrohung pro Sekunde (TPS) anzeigen** – Zuwachs der Bedrohung pro Sekunde im TPS-Zeitfenster.
  Nur möglich, solange der Client lesbare Werte liefert. Standard: an.
- **TPS-Zeitfenster (Sekunden)** – 3–30. Standard: 10.
- **Prozentbasis** – **Relativ zum Tank (100 % = Tank)** oder **Skaliert (100 % = Aggro)**. Im
  eingeschränkten Modus ist nur „skaliert“ verfügbar. Standard: Relativ zum Tank.
- **Balken 'Aggro ziehen' anzeigen** – zusätzlicher Balken bei der Bedrohung, ab der du die Aggro
  ziehst. Standard: an.
- **Aggro-Schwelle** – **Automatisch (Entfernung, sonst Klasse)**, **Nahkampf (110 %)** oder
  **Fernkampf (130 %)**. Automatisch: außerhalb des Kampfes nach der Entfernung zum Ziel, im Kampf
  nach der Klasse. Im Kampf gelten nur Krieger, Schurken und Paladine als Nahkampf; Druiden in Katzen-
  oder Bärengestalt und Verstärkungsschamanen bekommen dann 130 % – wähle für sie „Nahkampf“.
  Standard: Automatisch.
- **Eigenen Balken immer anzeigen** – passt dein Balken nicht mehr ins Fenster, ersetzt er die letzte
  Zeile (im eingeschränkten Modus steht er ganz oben). Standard: an.
- **Begleiter anzeigen** – zeigt auch Begleiter. Standard: an.
- **Fokusziel bevorzugen** – nimmt deinen Fokus (oder dessen Ziel) vor deinem Ziel. Standard: aus.
- **Spielerbegleiter als Ziel ignorieren** – von Spielern gesteuerte Gegner wie Begleiter zählen
  nicht als Ziel. Standard: an.
- **Aktualisierung (Sekunden)** – 0,05–1,00. Standard: 0,20.

**Warnung**

- **Warnung bei hoher Bedrohung** – warnt, wenn deine Bedrohung relativ zum Tank die Warnschwelle
  erreicht. Nur möglich, solange der Client lesbare Werte liefert. Standard: an.
- **Warnschwelle** – 50–130 %. Standard: 90 %.
- **Ton abspielen** – Schlachtzugswarnungs-Ton. Standard: an.
- **Bildschirm aufblitzen** – kurzes rotes Aufblitzen. Standard: an.
- **Meldung einblenden** – „Bedrohung: xx%“ im Bereich der Schlachtzugswarnungen. Standard: an.
- **Auch ohne Gruppe warnen** – sonst nur in einer Gruppe. Standard: aus.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qnm`, `/qnthreatmeter` (oder `/qnm toggle`) | Blendet das Fenster ein/aus |
| `/qnm lock` | Sperrt/entsperrt das Fenster |
| `/qnm test` | Schaltet den Testmodus (Beispieldaten) ein/aus |
| `/qnm config` (oder `/qnm options`) | Öffnet die Optionen |
| `/qnm check` | API-Prüfung: Client-Build, ob die Bedrohungswerte deines Ziels secret sind, deine eigenen Werte |
| `/qnm visible` | Holt das Fenster in den sichtbaren Bereich |
| `/qnm reset` | Setzt alle Einstellungen des aktiven Profils zurück (im Kampf: nach dem Kampf) |
| `/qnm <sonstiges>` | Zeigt die Befehlshilfe im Chat |

## Tipps & Hinweise

- Benötigt qnCore. Optional: LibSharedMedia-3.0 für weitere Balkentexturen.
- Die Anzeige folgt deinem Ziel; ist dein Ziel freundlich, nimmt sie das Ziel deines Ziels. Spieler
  werden nie als Gegner verwendet.
- Liefert der Client Secret-Values (eingeschränkter Modus), gibt es keine Sortierung, keine Ränge,
  kein TPS, keinen Balken „Aggro ziehen“ und keine Warnung; Prozent ist dann immer der skalierte
  Wert des Clients.
- Warnungen kommen nur, wenn ein echter Tank auf der Bedrohungsliste steht, nie, während du selbst
  tankst, und nicht im Testmodus. Nach einer Warnung kommt die nächste erst, wenn deine Bedrohung
  10 Punkte unter die Schwelle gefallen ist. Warnungen funktionieren auch bei ausgeblendetem Fenster
  (im Kampf).
- Die Aggro-Schwelle nach Entfernung funktioniert nur außerhalb des Kampfes; im Kampf entscheidet
  die Klasse.
- Der TPS-Verlauf wird nach dem Kampf gelöscht.
- Meldet `/qnm`, das Fenster sei aktiviert, aber nicht zu sehen, blendet es gerade die Option
  **Sichtbarkeit** aus.
- Mit qnViewPort und mehreren Monitoren holen **Automatisch im sichtbaren Bereich halten** und
  `/qnm visible` das Fenster auf einen Monitor, der wirklich zu sehen ist.

[← Übersicht](README.md)
