# qnGatherer

Sammel-Datenbank für Kräuter, Erz, Angeln und Schätze – **in Entwicklung**.

Zurück zur [Übersicht](README.md) · English: [English](../en/qnGatherer.md)

## Aktueller Stand (0.3.0)

qnGatherer zeichnet beim Spielen Sammelpunkte auf und zeigt sie auf Weltkarte und Minikarte. Eine
Optionsseite und einen Slash-Befehl gibt es noch nicht; die Einstellungen unten gelten mit ihren
Standardwerten.

## Aufzeichnen

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

## Weltkarte

- Jeder Punkt erscheint mit dem Symbol seines Gegenstands. Der Tooltip zeigt den Namen, die
  benötigte Fertigkeit (falls bekannt) und die Herkunft („Gefunden von …“, „Importiert aus …“);
  mehrere Punkte unter der Maus werden zusammen aufgelistet.
- **Rechtsklick** auf einen Punkt: **Löschen: <Name>** (der Punkt kommt auch über Gilde oder Import
  nicht wieder), **Wegpunkt setzen** (Blizzards Kartenmarkierung) und mit TomTom
  **TomTom-Wegpunkt hinzufügen**.
- Angelgebiete lassen sich als farbige Ellipsen anzeigen (standardmäßig aus).

## Minikarte

- Punkte in deiner Nähe erscheinen mit ihrem Symbol; innerhalb der **Verfolgungsdistanz**
  (100 Meter) wird das Symbol zu einem **Ring** in der Farbe der Art (Kräuter grün, Erz rot, Fische
  gelb, Schätze lila).
- Punkte außerhalb des Ausschnitts gleiten am Rand der Minikarte entlang und verblassen mit der
  Entfernung.
- Funktioniert mit drehender Minikarte und mit eckigen oder anderen Minikartenformen von
  Minikarten-Addons.
- Maus über einem Symbol zeigt den Tooltip; Linksklick pingt die Minikarte an dieser Stelle.

## Was angezeigt wird (Standard)

| Art | Angezeigt |
|---|---|
| Kräuter, Erz, Fische | nur wenn dein Charakter den Beruf hat |
| Schätze | immer |

Weitere Standardwerte: Weltkartensymbole Größe 100 %, voll deckend, anklickbar; Minikartensymbole
Größe 75 %, Tooltips und Rand an; von der Gilde gefundene und importierte Punkte werden angezeigt.
Diese Einstellungen werden in einer späteren Version auf der Optionsseite einstellbar.

## Lautstärke beim Angeln

qnGatherer kann beim Angeln die Effektgeräusche einschalten und auf volle Lautstärke stellen,
damit das Platschen gut zu hören ist, und stellt deine Einstellungen am Ende des Wurfs wieder her
(auch nach dem Ausloggen oder einem Absturz). **Standardmäßig aus**; die Option kommt mit der
Optionsseite.

Als Nächstes geplant: Optionsseite, ein Nachschlagefenster mit Angel- und Sammelinformationen,
Import aus anderen Sammel-Addons und ein abschaltbarer Datenaustausch mit der Gilde.

## Gespeicherte Daten

Alle gesammelten Daten gelten account-weit (für alle Charaktere gemeinsam); Fänge werden pro
Charakter gespeichert. Anzeige-Einstellungen gehören wie bei den anderen qn-Addons zum aktiven
Profil (Layout des Bearbeitungsmodus).
