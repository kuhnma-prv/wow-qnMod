# qnBuffMod – frei gestaltbare Fenster für Stärkungs- und Schwächungszauber

qnBuffMod ersetzt Blizzards Fenster für Stärkungs- und Schwächungszauber durch bis zu 10 eigene
Fenster. Jedes Fenster zeigt die Auren einer Einheit (Spieler, Fahrzeug, Begleiter, Ziel oder
Fokus), als Symbole mit Balken oder als reine Symbole, gruppiert und sortiert nach deinen Wünschen.
Es kann dich im Chat warnen, bevor ein Stärkungszauber abläuft, und bietet eine Taste zum
Erneuern.

## Funktionen

- Bis zu 10 Aurenfenster, jedes mit eigener Einheit, Darstellung, Anordnung, Gruppierung und
  Sortierung.
- Zwei Knopfstile: Symbol mit Balken (Name, Restzeit, Zeitbalken) oder nur Symbol.
- Gruppen: Schwächungszauber, aufhebbare Stärkungszauber, nicht aufhebbare Stärkungszauber, alle
  Stärkungszauber, Waffenverzauberungen (Waffenhand und Schildhand).
- Eigene Zauber und Zauber ohne Ablaufzeit getrennt einordnen, ausblenden oder nur diese zeigen.
- Farben für Schwächungszauber nach Typ (Fluch, Krankheit, Magie, Gift, andere) für Rahmen,
  Balken und Namen.
- Sichtbarkeit je Fenster: immer, einfache Bedingungen (Kampf, Fahrzeug) oder eine eigene
  Makrobedingung.
- Symbole blinken kurz vor Ablauf; Warnung im Chat, wahlweise mit Ton.
- Tastenbelegung **Stärkungszauber erneuern**, um einen bald ablaufenden Zauber neu zu wirken.
- Rechtsklick auf einen eigenen Zauber entfernt ihn (außerhalb des Kampfes).
- Verbirgt Blizzards Fenster für Stärkungs- und Schwächungszauber (abschaltbar).
- Einstellungen je Profil (Layout des Bearbeitungsmodus).

## Erste Schritte

Optionen: *Optionen → Addons → qnBuffMod* mit den Unterseiten **Fenster**, **Darstellung**,
**Knöpfe** und **Gruppierung**. `/qnbuff` öffnet die Optionen.

Nach dem ersten Einloggen gibt es ein Fenster (**Fenster 1**) in der Bildschirmmitte mit deinen
Stärkungszaubern. Zieh es mit der linken Maustaste an die gewünschte Stelle.

- **Alt-Klick** auf ein Fenster wählt es in den Optionen aus und öffnet die Seite **Fenster**.
- Solange eine der Fensterseiten offen ist, zeigt jedes Fenster seinen Namen darüber; das
  gewählte weiß, die anderen golden.
- Die vier Fensterseiten zeigen immer die Einstellungen des Fensters, das oben auf jeder Seite
  unter **Fenster bearbeiten** gewählt ist.

## Optionen

Alle Einstellungen von qnBuffMod – die allgemeinen und alle Fenster samt Positionen – werden
**je Profil** gespeichert, also je Layout des Bearbeitungsmodus (siehe qnCore, Seite **Profile**).
Ein anderes Layout hat seinen eigenen Satz Fenster.

### qnBuffMod

**Blizzard-Fenster**

- **Blizzards Zauberfenster verbergen** – verbirgt Blizzards Fenster für Stärkungs- und
  Schwächungszauber. Standard: an.

**Farben** (jeweils Farbfeld und Regler für die Deckkraft)

- **Fensterhintergrund** – Hintergrund aller Fenster ohne eigene Farbe. Standard: schwarz, 25 %
  Deckkraft.
- **Stärkungszauber** – Balkenfarbe von Stärkungszaubern mit Dauer. Standard: blau, 50 %.
- **Auren** – Balkenfarbe von Stärkungszaubern ohne Dauer. Standard: grün, 50 %.
- **Schwächungszauber** – Balkenfarbe von Schwächungszaubern. Standard: rot, 85 %.
- **Waffenverzauberungen** – Balkenfarbe von Waffenverzauberungen. Standard: violett, 75 %.

**Ablauf**

- **Symbol vor Ablauf blinken lassen** – das Symbol blinkt in den letzten Sekunden (0–60 s,
  0 = Aus). Standard: 15 s.
- **Warnung im Chat** – meldet im Chat, dass ein Stärkungszauber bald abläuft. Standard: an.
  - **Nur Zauber, die du selbst wirken kannst** – nur bei Zaubern warnen, die du selbst wirken
    kannst. Standard: aus.
  - **Ton abspielen** – ein Ton bei jeder Warnung. Standard: an.
  - **Warnen bei Dauer 2:00 – 10:00** – Vorwarnzeit für Zauber mit 2 bis 10 Minuten Dauer
    (0–60 s, 0 = Aus). Standard: 15 s.
  - **Warnen bei Dauer 10:01 – 30:00** – für Zauber mit 10 bis 30 Minuten Dauer (0–180 s).
    Standard: 1 min.
  - **Warnen bei Dauer ab 30:01** – für längere Zauber (0–300 s). Standard: 3 min.

Die Warnungen gelten für die Stärkungszauber aller Einheiten, die ein Fenster zeigt, und für
deine Waffenverzauberungen. Zauber unter 2 Minuten Dauer werden nie gemeldet. Jede Anwendung
wird nur einmal gemeldet.

### Fenster

**Fenster**

- **Fenster bearbeiten** – das Fenster, dessen Einstellungen diese Seiten zeigen (**Fenster 1**,
  **Fenster 2** …).
- **Neues Fenster** (**Hinzufügen**) – neues Fenster mit Standardeinstellungen.
- **Fenster kopieren** (**Duplizieren**) – neues Fenster mit den Einstellungen des gewählten
  Fensters.
- **Fenster löschen** (**Löschen …**) – löscht nach einer Rückfrage das gewählte Fenster samt
  Einstellungen. War es das letzte, wird ein neues angelegt.
- **Position zurücksetzen** (**Zurücksetzen**) – verschiebt das Fenster in die Bildschirmmitte.
- **Fenster suchen** (**In sichtbaren Bereich holen**) – verschiebt das Fenster nur so weit, bis
  es vollständig sichtbar ist; die übrige Position bleibt erhalten.

**Allgemein**

- **Fenster deaktivieren** – das Fenster wird nicht angezeigt; seine Einstellungen bleiben
  erhalten. Standard: aus.
- **Keine Tooltips an den Symbolen** – Standard: aus.
- **Fenster sperren** – verhindert das Verschieben. Standard: aus.
- **Im Bildschirm halten** – das Fenster lässt sich nicht aus dem Bildschirm schieben.
  Standard: an.

**Einheit**

- **Zauber zeigen für** – **Spieler**, **Fahrzeug**, **Begleiter**, **Ziel** oder **Fokus**.
  Standard: **Spieler**.
- **Im Fahrzeug dessen Zauber zeigen** – (nur bei **Spieler**) solange du in einem Fahrzeug
  sitzt, zeigt das Fenster dessen Auren. Standard: an.

**Sichtbarkeit**

- **Anzeigen** – **Immer anzeigen**, **Standardbedingungen** oder **Eigene Bedingung**.
  Standard: **Immer anzeigen**.
- Bei **Standardbedingungen**: **Im Kampf verbergen**, **Außerhalb des Kampfes verbergen**,
  **Im Fahrzeug verbergen**, **Außerhalb von Fahrzeugen verbergen** (alle standardmäßig aus).
- Bei **Eigene Bedingung**:
  - **Eigene Bedingung** (**Bearbeiten …**) – Makrobedingung mit den Aktionen `show`/`hide`,
    z. B. `[vehicleui] hide; [combat] hide; show`. Zeilenumbrüche zählen als `;`. Leer = immer
    anzeigen.
  - **Bedingung prüfen** (**Testen**) – zeigt im Chat, was die gespeicherte Bedingung gerade
    bewirkt.

### Darstellung

**Hintergrund**

- **Hintergrund anzeigen** – Hintergrund hinter dem Fenster. Standard: an.
- **Eigene Farbe für dieses Fenster** – eigene Farbe statt **Fensterhintergrund** von der
  Hauptseite. Standard: aus.
  - **Hintergrundfarbe** und **Deckkraft des Hintergrunds** – Standard: schwarz, 25 %.

**Rahmen**

- **Rahmen anzeigen** – Rahmen um das Fenster. Standard: aus.
- **Rand links**, **Rand rechts**, **Rand oben**, **Rand unten** – zusätzlicher Abstand zwischen
  den Symbolen und dem Fensterrand (0–100). Standard: 0.

**Anordnung**

- **Richtung** – in welche Richtung sich die Einträge aufreihen und umbrechen: *Oben nach unten,
  Spalten nach rechts* / *nach links*, *Unten nach oben, Spalten nach rechts* / *nach links*,
  *Links nach rechts, Zeilen nach unten* / *nach oben*, *Rechts nach links, Zeilen nach unten* /
  *nach oben*. Oben/unten: Einträge in Spalten; links/rechts: Einträge in Zeilen. Standard:
  **Links nach rechts, Zeilen nach unten** (mit 1 pro Zeile ergibt das eine Spalte, die nach
  unten wächst).
- **Zauber pro Zeile bzw. Spalte** – 1–50. Standard: 1.
- **Anzahl Zeilen bzw. Spalten** – 0–50, **0 = wächst automatisch**; mit Begrenzung erscheinen
  überzählige Einträge nicht. Standard: automatisch.
- **Abstand zwischen Zaubern** – 0–200. Standard: 0.
- **Abstand zwischen Zeilen bzw. Spalten** – 0–200. Standard: 0.

**Schrift**

- **Schriftgröße** – **Normal**, **Kleiner** oder **Größer**. Standard: **Normal**.

### Knöpfe

- **Stil** – **Stil 1 (Symbol und Balken)** oder **Stil 2 (nur Symbol)**. Standard: Stil 1. Die
  Einstellungen des jeweils anderen Stils sind ausgegraut.

**Stil 1 (Symbol und Balken)**

- **Symbolgröße** – 15–45. Standard: 20.
- **Symbolposition** – **Standard** (auf der Seite, von der aus das Fenster wächst), **Links**
  oder **Rechts**.
- **Rahmen von Schwächungszaubern einfärben** – Rahmen (und ein Symbol) in der Farbe des
  Schwächungstyps. Standard: aus.
- **Standard-Symbolrahmen** – zeigt das ganze Symbol samt seinem eigenen Rand, statt es an den
  Kanten zu beschneiden. Standard: aus.
- **Balkenbreite** – 0–400 (0 = kein Balken). Standard: 245.
- **Balkenhintergrund einfärben** – farbiger Balken hinter Name und Zeit (Farben von der
  Hauptseite). Standard: an.
- **Balken von Schwächungszaubern einfärben** – Balken in der Farbe des Schwächungstyps.
  Standard: aus.
- **Namen anzeigen** – Standard: an.
- **Namen von Schwächungszaubern einfärben** – Namen in der Farbe des Schwächungstyps.
  Standard: aus.
- **Name ausrichten (neben der Zeit)** / **Name ausrichten (ohne Zeit)** – **Standard**,
  **Links**, **Rechts**, **Mittig**.
- **Restzeit als Text** – Standard: an.
- **Zeitformat** – *1 Stunde / 22 Minuten*, *1 Stunde / 22 Min*, *1h / 22m*, *1h 11m / 22m 22s*,
  *1:11h / 22:22*. Standard: *1 Stunde / 22 Minuten*.
- **Tage anzeigen, wenn über 24 Stunden** – Standard: an.
- **Platz der Restzeit** – **Standard**, **Links vom Namen**, **Rechts vom Namen**, **Über dem
  Namen**, **Unter dem Namen**.
- **Zeit ausrichten (ohne Namen)** – **Standard**, **Links**, **Rechts**, **Mittig**.
- **Restzeit als Balken** – der Balken schrumpft mit der Restzeit. Standard: an.
- **Hintergrund des Balkens** – dunklerer Hintergrund hinter dem schrumpfenden Balken.
  Standard: an.
- **Textabstand links** / **Textabstand rechts** – 0–50. Standard: 0.

Farben der Schwächungszauber: violett = Fluch, braun = Krankheit, blau = Magie, grün = Gift,
rot = andere (z. B. körperlich).

**Stil 2 (nur Symbol)**

- **Symbolgröße** – 15–45. Standard: 20.
- **Rahmen von Schwächungszaubern einfärben**, **Standard-Symbolrahmen** – wie bei Stil 1.
  Standard: aus.
- **Restzeit als Text** – Standard: an.
- **Zeitformat**, **Tage anzeigen, wenn über 24 Stunden** – wie bei Stil 1.
- **Platz der Restzeit** – **Links**, **Rechts**, **Darüber**, **Darunter** oder **Mittig** (auf
  dem Symbol). Standard: **Darunter**.
- **Abstand zum Symbol** – 0–50, ohne Wirkung bei **Mittig**. Standard: 0.

### Gruppierung

**Gruppierung (vor der Sortierung)**

- **Reihenfolge der Gruppierungen** – in welcher Reihenfolge nach Filter (den Gruppen unten),
  eigenen und nicht ablaufenden Zaubern gruppiert wird, z. B. *Filter > Eigene > Nicht
  ablaufende*. Standard: *Filter > Eigene > Nicht ablaufende*.
- **Eigene Zauber** – **Vor denen anderer Spieler**, **Nach denen anderer Spieler** oder
  **Zusammen mit denen anderer Spieler**. Standard: **Zusammen mit denen anderer Spieler**.
- **Zauber ohne Ablaufzeit** – **Vor den anderen**, **Nach den anderen**, **Zusammen mit den
  anderen**, **Ausblenden** oder **Nur diese anzeigen**. Standard: **Zusammen mit den anderen**.
- **Gruppe 1** … **Gruppe 5** – welche Auren das Fenster zeigt und in welcher Reihenfolge:
  **Keine**, **Schwächungszauber**, **Aufhebbare Stärkungszauber**, **Nicht aufhebbare
  Stärkungszauber**, **Alle Stärkungszauber**, **Waffenverzauberungen**. Standard:
  Schwächungszauber, Waffenverzauberungen, Aufhebbare Stärkungszauber, Nicht aufhebbare
  Stärkungszauber, Keine. Jeder Typ lässt sich nur einmal verwenden; wählst du ihn erneut, wird
  die andere Gruppe auf **Keine** gesetzt. Eine Aura, die zu mehreren Gruppen passt, erscheint
  nur in der ersten.

**Sortierung (nach der Gruppierung)**

- **Sortieren nach** – **Name**, **Restzeit** oder **Reihenfolge** (Reihenfolge des Spiels).
  Standard: **Name**.
- **Reihenfolge umkehren** – Standard: aus.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qnbuff` | Öffnet die Optionen |
| `/qnbuffmod` | Wie `/qnbuff` |
| `/qnaura` | Wie `/qnbuff` |

## Tipps & Hinweise

- **Stärkungszauber erneuern**: Leg unter *Tastaturbelegung → Addons → qnBuffMod* eine Taste
  fest. Wird ein eigener Zauber gemeldet, den du wirken kannst, nennt die Chat-Meldung die Taste;
  ein Druck darauf wirkt den zuletzt gemeldeten Zauber neu, sonst deinen eigenen Zauber mit der
  kürzesten Restzeit. Nutze sie außerhalb des Kampfes.
- Im Kampf hält der Client Aurendaten zurück. Die Fenster zeigen dann den letzten bekannten Stand
  und aktualisieren sich nach dem Kampf; eine Chat-Meldung weist einmal darauf hin. Betroffene
  Zauber erscheinen eventuell ohne Restzeit oder mit Fragezeichen.
- Fenster anlegen und löschen geht im Kampf nicht. Änderungen der Sichtbarkeit im Kampf greifen
  nach dem Kampf.
- Rechtsklick entfernt nur eigene Stärkungszauber, nur in einem Fenster für den Spieler und nur
  außerhalb des Kampfes.
- Waffenverzauberungen erscheinen nur in Fenstern für den Spieler.
- Beim Überfahren eines Symbols erscheint der Tooltip der Aura mit dem Zaubernden in
  Klassenfarbe und der Zauber-ID.
- Nach einem Profilwechsel (anderes Layout des Bearbeitungsmodus) erscheinen die Fenster dieses
  Profils.

[← Übersicht](README.md)
