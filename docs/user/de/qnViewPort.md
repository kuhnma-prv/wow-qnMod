# qnViewPort – kleinere 3D-Welt und Mehrmonitor-Betrieb

qnViewPort verkleinert den Bereich, in dem die 3D-Welt gezeichnet wird. So kannst du Aktionsleisten,
Chat und andere Fenster neben die Spielwelt legen statt darüber. Die Fläche außerhalb der Welt
bekommt eine Farbe und auf Wunsch ein gekacheltes Muster. Ziehst du das Spielfenster über mehrere
Monitore, hält qnViewPort die 3D-Welt auf dem Hauptmonitor, legt auf Wunsch Taschen, Zonenkarte,
Weltkarte, Uhr- und Talentfenster auf einen Monitor deiner Wahl, hält Tooltips auf ihrem Monitor und verteilt
mit Titan Panel die Titan-Leisten auf einzelne Monitore.

## Funktionen

- Freier Viewport: Versätze links, rechts, oben und unten in Pixeln, einstellbar in einer Vorschau
  mit ziehbaren Kanten oder über Zahlenfelder; neue Werte musst du innerhalb von 20 Sekunden
  bestätigen, sonst werden sie zurückgenommen.
- Farbe (mit Deckkraft) und gekacheltes Hintergrundmuster für die Fläche außerhalb der Welt,
  einschließlich der Muster von qnCore und – falls vorhanden – Hintergründen aus LibSharedMedia.
- Zwei-/Mehrmonitor-Modus: 3D-Welt nur auf dem Hauptmonitor, mit gemessenen Monitordaten
  (PowerShell-Skripte) oder von Hand eingetragenen Werten.
- Platzierung auf Wunsch (Opt-in) von Taschen, Zonenkarte (mit Größe), maximierter Weltkarte,
  „Karte & Questlog“, Uhr- und Talentfenster auf einem gewählten Monitor.
- Extras für die Weltkarte: der aktuellen Zone folgen, beim Einloggen öffnen, beim Laufen nicht
  ausblenden.
- Sichtbarkeitsprüfung: listet Oberflächenelemente, die ganz oder teilweise auf keinem Monitor
  liegen, und holt sie auf Wunsch einzeln in den sichtbaren Bereich.
- Tooltips der Taschenplätze, der Minikarte (Verfolgung, Zonentext, Post, Kalender, Uhr) und das
  Verfolgungsmenü bleiben vollständig auf ihrem Monitor.
- Mit Titan Panel: jede durchgehende Titan-Leiste auf einem gewählten Monitor, Plugin-Tooltips auf
  dem Monitor des Plugins, Skalierung je Monitor.

## Erste Schritte

Öffne *Optionen → Addons → qnViewPort* oder gib `/qnvp` ein. Auf der Hauptseite stellst du den
Viewport ein. Unterseiten: **Monitore**, **Zweiter Monitor**, **Platzierung**, **Karten** und – nur wenn
Titan Panel geladen ist – **Titan Panel**.

Alle Einstellungen gehören zum aktiven Profil, also zum aktiven Layout des Bearbeitungsmodus
(siehe [qnCore](qnCore.md)). Wechselst du das Layout, wechselt das Profil und seine Einstellungen
werden angewendet.

## Optionen

### qnViewPort (Hauptseite)

- **Vorschau**: Der rote Rahmen ist das Spielfenster, die gelbe Fläche **Spielwelt** die 3D-Welt.
  Zieh an ihren Kanten oder Ecken, um die Versätze zu ändern.
- **Oben**, **Unten**, **Links**, **Rechts**: Versätze in Pixeln, mit Enter bestätigen (Tab springt
  zum nächsten Feld). Standard: jeweils 0. Gegenüberliegende Seiten zusammen dürfen höchstens die
  Hälfte des Fensters einnehmen (7/8, wenn das Fenster über mehrere Monitore reicht).
- **Übernehmen**: wendet die Werte an. Es erscheint die Schaltfläche **Einstellung behalten?** mit
  Countdown; klickst du sie nicht innerhalb von 20 Sekunden, kommt der vorherige Viewport zurück.
- **Zurücksetzen**: wieder das ganze Fenster für die Spielwelt (wie `/qnvp 0 0 0 0`).
- Unter den Schaltflächen: Bildschirmauflösung und Größe des eigenen Viewports, jeweils mit
  Seitenverhältnis.
- **Hinweis beim Einloggen unterdrücken**: kein Chat-Hinweis nach dem Einloggen, dass ein eigener
  Viewport aktiv ist. Standard: aus.
- **Farbe der Fläche außerhalb der Welt**: Klick auf das Farbfeld öffnet die Farbauswahl (mit
  Deckkraft). Standard: Schwarz.
- **Hintergrundmuster**: gekacheltes Muster über der Farbe – Fels, Marmor, Holz, Dialog,
  Dialog dunkel, Tooltip, Pergament, Erfolge, die Muster von qnCore und Hintergründe aus
  LibSharedMedia (markiert mit „(LSM)“). Standard: **Kein Muster (nur Farbe)**.
- **Deckkraft des Musters**: 0–100 %, Standard 50 %. Nur verfügbar, wenn ein Muster gewählt ist.

Im Kampf lässt sich die Spielwelt nicht verkleinern; eine Änderung wird dann direkt nach dem Kampf
angewendet.

### Monitore

Zeigt die von den Skripten geschriebenen Monitordaten (siehe
[Mehrmonitor-Einrichtung](#mehrmonitor-einrichtung)): Nummer, Name, Lage und Größe jedes Monitors im
Spielfenster, den Hauptmonitor und ob die Blizzard-Oberfläche gerade über das ganze Fenster oder nur
über den Hauptmonitor reicht.

- **Monitordaten verwenden**: `Monitors.lua` benutzen. Aus: Lage und Größe des 2. Monitors kommen
  von der Seite **Zweiter Monitor**. Standard: an.
- **Übernehmen**: wendet die Monitoranordnung erneut an (bei aktivem Zwei-Monitor-Modus legt es
  auch die 3D-Welt auf den Hauptmonitor).
- **Sichtbarkeit prüfen**: sucht alle eingeblendeten Oberflächenelemente, die ganz oder teilweise
  auf keinem Monitor liegen, und listet sie unter der Monitorliste auf (Name, wie viel sichtbar ist,
  Herkunft, Bearbeitungsmodus, geschützt). Die Prüfung selbst verschiebt nichts.
- **In sichtbaren Bereich holen** (eine Schaltfläche je Element der Liste): verschiebt nur dieses
  Element auf dem kürzesten Weg auf einen Monitor. Fährst du mit der Maus über die Schaltfläche,
  wird die jetzige Fläche des Elements rot markiert. Elemente des Bearbeitungsmodus bleiben so nur
  bis `/reload` bzw. bis das Layout neu geladen wird – dauerhaft verschiebst du sie im
  Bearbeitungsmodus. Geschützte Elemente lassen sich im Kampf nicht verschieben.
- **Oberfläche auf den Hauptmonitor**: legt die ganze Blizzard-Oberfläche (alles, was an UIParent
  hängt: Aktionsleisten, Minikarte, Questliste, Chat …) über den Hauptmonitor. Nur im
  Zwei-Monitor-Modus mit einem Fenster über mehrere Monitore, nicht im Kampf. Gilt bis
  **Zurücksetzen**, `/reload`, dem Ausschalten des Zwei-Monitor-Modus oder dem Wechsel zu einem
  Profil ohne ihn.
- **Zurücksetzen**: Blizzard-Oberfläche wieder über das ganze Spielfenster.

### Zweiter Monitor

Das Spielfenster muss über mehrere Monitore gezogen sein (Fenstermodus, z. B. 5760 × 2160).

- **Zwei-Monitor-Modus aktiv (3D-Welt nur auf dem Hauptmonitor)**: Beim Einschalten liegt die
  3D-Welt sofort auf dem Hauptmonitor (ohne 20-Sekunden-Bestätigung); beim Ausschalten wird der
  Viewport auf das ganze Fenster zurückgesetzt und **Oberfläche auf den Hauptmonitor** aufgehoben.
  Standard: aus.
- **Lage des 2. Monitors**: **Rechts vom Hauptmonitor** (Standard) oder **Links vom Hauptmonitor**.
- **Breite**, **Höhe**, **Abstand von oben**: Größe des 2. Monitors in Pixeln und Abstand seiner
  Oberkante vom oberen Fensterrand. Standard: 1920, 1200, 0.
- **Übernehmen**: wendet diese Werte an (und bei aktivem Modus den Viewport).
- Infozeile: Größe des Spielfensters, 2. Monitor im Fenster, Größe der Welt und eine Warnung, wenn
  das Fenster für beide Monitore zu klein ist.

Mit aktiven Monitordaten sind Lage, Größe und Abstand gemessen und hier nicht änderbar.

### Platzierung

Ohne Haken fasst qnViewPort das jeweilige Fenster nicht an. Den Monitor wählst du in einer
Auswahlliste: **Hauptmonitor** oder einer der nummerierten Monitore (Nummern wie auf der Seite
**Monitore**). Die Abstände zählen in Pixeln vom Rand der gewählten Ecke nach innen.

**Taschen**

- **Taschen beim Öffnen platzieren**: Bei jedem Öffnen wandern die Taschen an die gewählte Ecke,
  senkrecht gestapelt, weitere Spalten zur Monitormitte hin. Standard: aus.
- **Monitor** (Standard: Hauptmonitor), **Ecke** (Standard: **Unten rechts**),
  **Abstand waagerecht** / **senkrecht** (Standard: 130 / 330).

**Uhr**

- **Unter der Uhr öffnen**: Das Uhrfenster (Klick auf die Uhr an der Minikarte) öffnet sich unter der
  Uhr auf deren Monitor statt an der oberen rechten Kante des Spielfensters. Standard: aus.

**Talente**

- **Talentfenster auf** + Monitor: Blizzard platziert das Talentfenster relativ zum ganzen
  Spielfenster, also mittig über alle Monitore. An: dieselbe Position relativ zum gewählten Monitor;
  die Größe bleibt unverändert. Beim Ausschalten kommt Blizzards Position zurück. Standard: aus,
  Hauptmonitor.

**Schaltflächen und Anzeige**

- **Bereiche anzeigen**: rahmt die Bereiche der aktiven Platzierungen ein – blau Taschen, gelb
  Zonenkarte, grün Weltkarte, violett „Karte & Questlog“, rot Talentfenster. Standard: aus.
- **Übernehmen**: platziert alles erneut.

### Karten

Ohne Haken fasst qnViewPort das jeweilige Fenster nicht an. Den Monitor wählst du in einer
Auswahlliste: **Hauptmonitor** oder einer der nummerierten Monitore (Nummern wie auf der Seite
**Monitore**). Die Abstände zählen in Pixeln vom Rand der gewählten Ecke nach innen.

**Weltkarte**

- **Maximierte Weltkarte auf** + Monitor: maximierte Karte und schwarze Fläche nur auf dem gewählten
  Monitor statt über das ganze Fenster. Standard: aus.
- **„Karte & Questlog“ auf** + Monitor: die verkleinerte Karte mit dem Questlog an den linken Rand
  des gewählten Monitors statt an den linken Fensterrand. Standard: aus.
- **Karte folgt der aktuellen Zone**: Bei offener Karte wechselt sie beim Betreten einer neuen Zone
  auf deren Karte. Standard: an.
- **Karte beim Einloggen öffnen**: nur beim Einloggen und nach `/reload`, nicht nach
  Ladebildschirmen. Standard: aus.
- **Karte beim Laufen nicht ausblenden**: setzt die Blizzard-Einstellung `mapFade` auf 0; beim
  Ausschalten kommt der vorherige Wert zurück. Standard: aus.

**Zonenkarte (Umschalt+M)**

- **Zonenkarte anzeigen**: zeigt oder verbirgt Blizzards Zonenkarte (Blizzard merkt sich den
  Zustand selbst).
- **Zonenkarte beim Anzeigen platzieren**: legt die Zonenkarte samt Reiter bei jedem Einblenden an
  die gewählte Ecke; Ziehen am Reiter wirkt dann nur bis zum nächsten Einblenden. Standard: aus.
- **Monitor** (Standard: Hauptmonitor), **Ecke** (Standard: **Oben rechts**),
  **Abstand waagerecht** / **senkrecht** (Standard: 20 / 300).
- **Größe**: Größe der Zonenkarte samt Reiter, 50–200 % in 5-%-Schritten, Standard 100 %. Wirkt
  auch ohne Platzierung.

**Schaltflächen und Anzeige**

- **Übernehmen**: platziert alles erneut.
- **Karte öffnen**: öffnet die Weltkarte (nicht im Kampf).

### Titan Panel

Nur vorhanden, wenn Titan Panel geladen ist. Die Einstellungen gelten je Profil.

- Eine Auswahlliste je durchgehender Titan-Leiste (zwei oben, zwei unten; Namen wie in Titan):
  **Wie Titan (ganze Oberfläche)** (Standard) oder ein Monitor (Nummern wie auf der Seite
  **Monitore**). Die Leiste liegt dann an der oberen bzw. unteren Kante dieses Monitors. Ein- und
  ausgeschaltet werden die Leisten weiter in Titan.
- **Übernehmen**: legt die Leisten erneut an ihre Monitore, z. B. nach einer Änderung der
  Monitoranordnung.
- **Skalierung je Monitor**: ein Schieberegler je Monitor, 50–200 % in 5-%-Schritten, Standard
  100 %. Größe der Leisten, Plugins und Tooltips von Titan auf diesem Monitor, zusätzlich zu Titans
  eigener Skalierung – hilfreich bei Monitoren mit unterschiedlicher Pixeldichte (z. B. etwa 65 %
  für einen Monitor mit 100 % Windows-Skalierung neben einem Hauptmonitor mit 150 %).

Tooltips und Bedienfenster der Titan-Plugins bleiben automatisch auf dem Monitor des Plugins.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qnvp`, `/qnviewport`, `/viewport` | Optionen öffnen |
| `/qnvp L R O U` | Versätze in Pixeln setzen (links, rechts, oben, unten); mit 20-Sekunden-Bestätigung |
| `/qnvp 0 0 0 0` | Viewport zurücksetzen (ganzes Fenster) |
| `/qnvp monitors` | Monitordaten im Chat anzeigen |
| `/qnvp check` | Oberflächenelemente außerhalb der Monitore auflisten (verschiebt nichts) |
| `/qnvp dual` | Seite **Zweiter Monitor** öffnen |
| `/qnvp dual on` / `off` | Zwei-Monitor-Modus ein/aus |
| `/qnvp dual left` / `right` | Lage des 2. Monitors |
| `/qnvp dual B H [Y]` | Größe des 2. Monitors in Pixeln, Y = Abstand von oben (gilt nur ohne Monitordaten) |
| `/qnvp dual guides` | Umrisse der Platzierungsbereiche ein/aus |
| `/qnvp dual map` | Weltkarte öffnen |
| `/qnvp dual zonemap` | Zonenkarte ein-/ausblenden |
| `/qnvp help`, `/qnvp dual help` | Befehlsliste anzeigen |

## Mehrmonitor-Einrichtung

Die Monitoranordnung lässt sich im Spiel nicht auslesen. Zwei PowerShell-7-Skripte in
`qnViewPort\scripts` schreiben sie in `qnViewPort\Monitors.lua`; das Spiel liest sie nach `/reload`.
Ohne diese Datei arbeitet qnViewPort mit den Werten der Seite **Zweiter Monitor**.

1. **Einmalig:** `pwsh Initialize-WowMonitors.ps1`
   Listet alle Monitore (von links nach rechts nummeriert, mit Lage, Auflösung und
   Windows-Skalierung) und fragt, über welche Monitore das WoW-Fenster reichen soll und welcher der
   Hauptmonitor für die 3D-Welt ist. Speichert die Auswahl in `monitors.json` im WoW-Hauptordner
   (gemeinsam für alle installierten Clients) und schreibt `Monitors.lua` für jeden installierten
   Client.
   - `-List` – nur Monitore anzeigen, nichts ändern
   - `-Select 1,2 -Main 1` – Auswahl ohne Rückfragen
   - `-WowRoot <Pfad>`, `-ConfigPath <Datei>` – WoW-Ordner / Ort von `monitors.json`
2. **Nach dem Start von WoW:** `pwsh Set-WowWindow.ps1`
   Wartet auf das WoW-Fenster (bis 180 s), entfernt den Fensterrahmen, zieht das Fenster über die
   ausgewählten Monitore und gleicht `Monitors.lua` des laufenden Clients mit dem genauen
   Fensterinhalt ab. Danach im Spiel `/reload`.
   - `-ProcessName <Name>` – Prozess des Clients (Standard `WowB`)
   - `-KeepBorder` – Titelleiste und Rahmen behalten
   - `-Select 1,2 -Main 1` – andere Auswahl nur für diesen Aufruf
   - `-X -Y -Width -Height` – festes Fensterrechteck ohne Monitorlogik (aktualisiert `Monitors.lua` nicht)
   - `-TimeoutSec <s>`, `-WowRoot <Pfad>`, `-ConfigPath <Datei>`

Die Skripte finden den WoW-Ordner über die Umgebungsvariable `QN_WOW_ROOT`, über ihren eigenen
Ort im AddOns-Ordner des Spiels oder über einen laufenden WoW-Client. Hat sich ein Monitor seit der
Einrichtung geändert, warnt `Set-WowWindow.ps1` und nimmt die aktuellen Werte – führe zur
Bestätigung `Initialize-WowMonitors.ps1` erneut aus.

Sieht qnViewPort eine neue Monitoranordnung zum ersten Mal, legt es die 3D-Welt einmalig auf den
Hauptmonitor und meldet das im Chat; spätere Änderungen am Viewport bleiben, bis sich die Anordnung
ändert. Passt die Größe des Spielfensters nicht zu den Daten (anderes Seitenverhältnis), zeigen das
die Seite **Monitore** und `/qnvp monitors` an – dann `Set-WowWindow.ps1` erneut ausführen.

## Tipps & Hinweise

- qnViewPort verschiebt Blizzard-Fenster nur, wenn du es willst: Platzierungen sind Opt-in,
  **Oberfläche auf den Hauptmonitor** und **In sichtbaren Bereich holen** sind Schaltflächen.
- Oberflächenelemente verschiebst du im Bearbeitungsmodus von Blizzard; mit der Seite **Monitore**
  findest du Elemente, die auf keinem Monitor mehr liegen.
- Im Kampf: Viewport und Platzierung der Weltkarte werden nach dem Kampf angewendet; geschützte
  Elemente und die Blizzard-Oberfläche lassen sich nicht verschieben; die Zonenkarte kann nicht
  geladen werden.
- Die Zonenkarte ist nicht überall verfügbar (z. B. nicht in jeder Instanz).
- Andere qn-Addons nutzen die Monitorbereiche von qnViewPort: qnSkins legt seine Bilder auf einen
  Monitor, die Taschenansichten von qnInventory halten ihre Tooltips auf dem Monitor der Tasche.
  qnThreatMeter, qnNumKeyPad und qnBuffMod holen ihre Fenster (über qnCore) in den sichtbaren
  Bereich.
- Optionale Abhängigkeit: [Titan Panel](https://www.curseforge.com/wow/addons/titan-panel);
  Hintergrundmuster aus LibSharedMedia erscheinen, wenn ein anderes Addon es mitbringt.

[← Übersicht](README.md)
