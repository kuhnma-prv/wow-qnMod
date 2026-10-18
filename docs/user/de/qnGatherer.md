# qnGatherer

Sammel-Datenbank für Kräuter, Erz, Angeln und Schätze – **in Entwicklung**.

Zurück zur [Übersicht](README.md) · English: [English](../en/qnGatherer.md)

qnGatherer zeichnet die Sammelpunkte auf, die du findest, und zeigt sie auf Weltkarte und
Minikarte. Es bringt keine Daten mit: Die Karten füllen sich beim Sammeln, durch Import aus
GatherMate2 oder GatherTogether oder von einem anderen qnGatherer-Nutzer (ein Austausch mit der Gilde
ist geplant).

## Aufzeichnen

- **Sammelpunkte**, wenn du sie abbaust: Kräuter (Kräuterkunde), Erz (Bergbau) und Truhen (Öffnen,
  Schlossknacken). Die Position ist die Stelle, an der du beim Sammeln stehst. Punkte derselben
  Ressource dicht beieinander (Zusammenfassungsradius, 15 Meter) zählen als ein Punkt.
- **Punkte, die du noch nicht abbauen kannst**: Meldet das Spiel „Benötigt Bergbau 175“ oder ist die
  Truhe verschlossen, wird der Punkt mit seinem Namen und der benötigten Fertigkeit gespeichert.
  Baust du ihn später ab, wird er zu einem normalen Punkt.
- **Angeln**: Jeder geangelte Gegenstand wird pro Charakter und Zone gezählt (auch Müll). Fische
  werden als **Angelgebiete** um die Stelle gespeichert, an der du die Angel auswirfst; nahe
  Würfe ergänzen dasselbe Gebiet (höchstens 30 gelernte Gebiete pro Zone). Angelst du in einem
  **Fischschwarm**, wird auch der Schwarm etwa 15 Meter vor dir gespeichert.
- Kürschnerei wird nicht aufgezeichnet (Tiere haben keinen festen Ort).

## Weltkarte

- Jeder Punkt erscheint mit dem Symbol seines Gegenstands. Der Tooltip zeigt den Namen, die
  benötigte Fertigkeit (falls bekannt) und die Herkunft („Gefunden von …“, „Importiert aus …“);
  mehrere Punkte unter der Maus werden zusammen aufgelistet.
- **Rechtsklick** auf einen Punkt: **Löschen: <Name>** (der Punkt kommt auch über Gilde oder Import
  nicht wieder), **Wegpunkt setzen** (Blizzards Kartenmarkierung) und mit TomTom
  **TomTom-Wegpunkt hinzufügen**. Rechtsklick auf freie Kartenfläche zoomt weiter heraus.
- Angelgebiete lassen sich als farbige Ellipsen anzeigen.

## Minikarte

- Punkte in deiner Nähe erscheinen mit ihrem Symbol; innerhalb der **Verfolgungsdistanz** wird das
  Symbol zu einem **Ring** in der Farbe der Art (Kräuter grün, Erz rot, Fische gelb, Schätze lila).
- Punkte außerhalb des Ausschnitts gleiten am Rand der Minikarte entlang und verblassen mit der
  Entfernung.
- Funktioniert mit drehender Minikarte und mit eckigen oder anderen Minikartenformen von
  Minikarten-Addons.
- Maus über einem Symbol zeigt den Tooltip; Linksklick pingt die Minikarte an dieser Stelle.

## Nachschlagefenster

`/qngatherer` oder Linksklick auf den Minikarten-Knopf öffnet das Nachschlagefenster:

- Oben die **Art** (Auswahlliste); der Titel zeigt deine Fertigkeit mit Bonus, z. B. „Angeln 150 (+25)“.
- Links die **Zonen** mit Daten dieser Art, mit ihrem Fertigkeitsbereich (falls bekannt) oder der
  Zahl der Punkte. Die **Suche** findet Zonen über den Zonennamen oder den Namen einer Ressource;
  **Aktuelle Zone** springt zur Zone, in der du bist.
- Rechts eine **Vorschau der Zonenkarte** (vollständig mit den erkundeten Bereichen deines Accounts)
  mit den Punkten und Gebieten; Maus darüber zeigt den Tooltip.
- Darunter die **Ressourcen** der Zone: Symbol, Name, benötigte Fertigkeit, Zahl der Punkte, deine
  Fänge. Maus darüber zeigt den Gegenstands-Tooltip; ein Klick auf eine Ressource zeigt nur ihre
  Punkte und Gebiete in der Vorschau, ein weiterer Klick wieder alle.

Das Nachschlagefenster enthält nur, was aufgezeichnet, importiert oder von der Gilde erhalten wurde.

## Infofenster

Ein kleines Fenster, das sich beim **Angeln** öffnet (auf Wunsch auch beim Sammeln): deine
Fertigkeit, die Zone mit ihrem Fertigkeitsbereich und die Ressourcen der Zone mit benötigter
Fertigkeit und deinen Fängen; beim Angeln steht dort „Auf das Platschen achten …“. Es schließt sich
einige Sekunden nach dem Wurf. **Offen halten** (oder `/qngatherer mini`) heftet es an; schließt du
es mit dem X, ist es wieder gelöst. **Nachschlagen** öffnet das Nachschlagefenster auf dieser Zone.

## Optionen

*Optionen → Addons → qnGatherer*. Alle Seiten außer **Daten** und dem Minikarten-Knopf gehören zum
aktiven Profil (Layout des Bearbeitungsmodus).

### qnGatherer

| Option | Standard | Bedeutung |
|---|---|---|
| **Angezeigte Punkte**: Kräuterkunde, Bergbau, Angeln, Schätze | Mit dem Beruf (Schätze: Immer) | **Immer**, **Mit dem Beruf** (nur wenn dieser Charakter ihn hat), **Beim Aufspüren** (nur solange Kräutersuche, Mineraliensuche … aktiv ist), **Nie** (ausgeblendet, wird weiter aufgezeichnet) |
| Von der Gilde gefundene Punkte anzeigen | an | |
| Importierte Punkte anzeigen | an | |
| Minikarten-Knopf anzeigen | an | account-weit |

### Weltkarte

| Option | Standard |
|---|---|
| Symbole auf der Weltkarte anzeigen | an |
| Symbole anklickbar (Tooltip und Rechtsklick-Menü) | an |
| Symbolgröße | 100 % |
| Deckkraft der Symbole | 100 % |
| Angelgebiete anzeigen | aus |

### Minikarte

| Option | Standard |
|---|---|
| Symbole auf der Minikarte anzeigen | an |
| Tooltips auf der Minikarte | an |
| Punkte am Rand anzeigen | an |
| Symbolgröße | 75 % |
| Deckkraft der Symbole | 100 % |
| Verfolgungsring anzeigen | Immer |
| Verfolgungsdistanz (Meter) | 100 |
| Farbe je Art | grün, rot, gelb, lila |

### Filter

Ein Kontrollkästchen je bekannter Ressource (gesammelt, importiert oder von der Gilde erhalten),
nach Art gruppiert, mit **Alle** und **Keine**. Ausgeblendete Ressourcen werden weiter
aufgezeichnet. „Standard“ blendet alles wieder ein.

### Angeln

| Option | Standard | Bedeutung |
|---|---|---|
| Lautstärke beim Angeln anheben | aus | Effektgeräusche beim Angeln an und auf volle Lautstärke; deine Einstellungen werden am Ende des Wurfs wiederhergestellt (auch nach dem Ausloggen oder einem Absturz) |
| **Infofenster**: Beim Angeln öffnen | an | |
| Beim Sammeln öffnen | aus | Kräuter, Erz, Truhen |
| Schließen nach (Sekunden) | 8 | außer „Offen halten“ ist angehakt |

### Daten (account-weit)

- **Zusammenfassungsradius (Meter)** je Art (Standard 15) und **Datenbank bereinigen**: fasst
  Punkte innerhalb des Radius erneut zusammen, z. B. nach einer Änderung.
- **Datenbanksperre** je Art: Für eine gesperrte Art wird nichts hinzugefügt, gelöscht, bereinigt
  oder importiert.
- **Löschen**: Art wählen, dann **In der aktuellen Zone löschen** (diese Punkte kommen auch über
  Gilde oder Import nicht wieder) oder **Alle Punkte der Art löschen**; **Gildendaten entfernen**,
  **Importierte Daten entfernen**. Jeweils mit Rückfrage.

### Importieren (account-weit)

- **Importart**: **Zusammenführen** (fügt Neues hinzu; von dir gelöschte Punkte bleiben gelöscht)
  oder **Ersetzen** (entfernt zuerst alles, was vorher aus diesem Addon importiert wurde).
- **GatherMate2**, **GatherTogether**: importiert die Daten des Addons, solange es geladen ist.
  GatherMate2: seine Punkte (über den Namen den dir bekannten Ressourcen zugeordnet; andere
  erscheinen mit ihrem Namen, bis du sie abbaust). GatherTogether: Kräuter- und Erzgebiete,
  Angelgebiete (gemeldet, Schwärme, seine gelernten Stellen), Fertigkeitsbereiche und Fischlisten
  der Zonen, seine Fänge, die Kartenüberlagerungen (das Nachschlagefenster zeigt dann ganze Zonen)
  und die Stufenbereiche der Kürschnerei (Eintrag **Kürschnerei** im Nachschlagefenster).
- **Automatisch importieren** (aus): importiert beim Einloggen erneut aus einem geladenen Addon,
  dessen Version sich geändert hat.
- **Eigene Punkte exportieren** / **Exporttext importieren**: deine eigenen Punkte und Angelgebiete
  als Text für einen anderen qnGatherer-Nutzer (kopieren mit Strg+C, einfügen mit Strg+V).

Importierte Daten sind mit „Importiert aus …“ gekennzeichnet und lassen sich ausblenden (Seite
qnGatherer) oder entfernen (Seite Daten).

### Offline-Import

Für ein Addon, das auf Forever nicht lädt (z. B. GatherMate2) oder nicht installiert ist: Spiel
beenden und im Repository ausführen:

```
pwsh tools\Convert-QnGatherer.ps1 -SavedVariables '<WoW>\_classic_beta_\WTF\Account\<ACCOUNT>\SavedVariables' -GatherMate2 '<Ordner von GatherMate2>' -GatherTogether '<Ordner von GatherTogether>'
```

Es liest die gespeicherten Daten und Dateien dieser Addons und legt die Datensätze in den
gespeicherten Variablen von qnGatherer ab (Sicherung `qnGatherer.lua.bak`); qnGatherer importiert
sie beim nächsten Einloggen und meldet das Ergebnis im Chat. `-Locale` (Standard deDE) bestimmt die
Sprache der Punktnamen von GatherMate2.

## Minikarten-Knopf und Titan Panel

- **Minikarten-Knopf**: Linksklick Nachschlagefenster, Umschalt-Linksklick Minikartensymbole
  an/aus, Strg-Linksklick Weltkartensymbole an/aus, Rechtsklick Optionen; per Ziehen am Rand der
  Minikarte verschieben.
- **Titan Panel** (optional): Plugin **qnGatherer** mit der Zahl der angezeigten Punkte in der
  aktuellen Zone; Tooltip mit Punkten je Art (Zone / gesamt); Klicks wie beim Minikarten-Knopf,
  Rechtsklick-Menü mit Nachschlagefenster, den Schaltern und den Optionen.

## Slash-Befehle und Tastenbelegungen

| Befehl | Wirkung |
|---|---|
| `/qngatherer`, `/qng` | Nachschlagefenster öffnen/schließen |
| `/qngatherer options` | Optionen öffnen |
| `/qngatherer mini` | Infofenster: offen halten an/aus |
| `/qngatherer minimap` | Minikartensymbole an/aus |
| `/qngatherer worldmap` | Weltkartensymbole an/aus |
| `/qngatherer sound` | Lautstärke beim Angeln an/aus |
| `/qngatherer cleanup` | Datenbank bereinigen |
| `/qngatherer help` | Liste der Befehle |

Tastenbelegungen (*Optionen → Tastaturbelegung → Addons → qnGatherer*): **Nachschlagefenster
öffnen/schließen**, **Minikartensymbole an/aus**, **Weltkartensymbole an/aus**.

## Gespeicherte Daten

Alle gesammelten Daten gelten account-weit (für alle Charaktere gemeinsam); Fänge werden pro
Charakter gespeichert.

Als Nächstes geplant: ein abschaltbarer Datenaustausch mit der Gilde.
