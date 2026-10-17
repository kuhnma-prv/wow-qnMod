# qnGatherer

Sammel-Datenbank für Kräuter, Erz, Angeln und Schätze – **in Entwicklung**.

Zurück zur [Übersicht](README.md) · English: [English](../en/qnGatherer.md)

## Aktueller Stand (0.2.0)

qnGatherer zeichnet beim Spielen auf, **zeigt aber noch nichts an**: keine Kartensymbole, kein
Fenster, keine Optionsseite und kein Slash-Befehl.

Was aufgezeichnet wird:

- **Sammelpunkte**, wenn du sie abbaust: Kräuter (Kräuterkunde), Erz (Bergbau) und Truhen (Öffnen,
  Schlossknacken). Die Position ist die Stelle, an der du beim Sammeln stehst. Punkte derselben Art
  dicht beieinander (15 Meter) zählen als ein Punkt.
- **Punkte, die du noch nicht abbauen kannst**: Meldet das Spiel „Benötigt Bergbau 175“ oder ist die
  Truhe verschlossen, wird der Punkt mit seinem Namen und der benötigten Fertigkeit gespeichert.
  Baust du ihn später ab, wird er zu einem normalen Punkt.
- **Angeln**: Jeder geangelte Gegenstand wird pro Charakter und Zone gezählt (auch Müll). Fische
  werden als **Angelgebiete** um die Stelle gespeichert, an der du die Angel auswirfst; nahe
  Würfe ergänzen dasselbe Gebiet (höchstens 30 gelernte Gebiete pro Zone). Angelst du in einem
  **Fischschwarm**, wird auch der Schwarm etwa 15 Meter vor dir gespeichert.

### Lautstärke beim Angeln

qnGatherer kann beim Angeln die Effektgeräusche einschalten und auf volle Lautstärke stellen,
damit das Platschen gut zu hören ist, und stellt deine Einstellungen am Ende des Wurfs wieder her
(auch nach dem Ausloggen oder einem Absturz). **Standardmäßig aus**; die Option kommt mit der
Optionsseite in einer späteren Version.

Als Nächstes geplant: Symbole auf Weltkarte und Minikarte, ein Nachschlagefenster mit Angel- und
Sammelinformationen, Optionen, Import aus anderen Sammel-Addons und ein abschaltbarer
Datenaustausch mit der Gilde.

## Gespeicherte Daten

Alle gesammelten Daten gelten account-weit (für alle Charaktere gemeinsam); Fänge werden pro
Charakter gespeichert. Anzeige-Einstellungen gehören künftig wie bei den anderen qn-Addons zum
aktiven Profil (Layout des Bearbeitungsmodus).
