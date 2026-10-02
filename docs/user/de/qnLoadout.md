# qnLoadout – fertige Makro- und Ziffernblock-Sätze pro Klasse

qnLoadout lädt mit einem Klick einen vorbereiteten Satz für deine Klasse: Es legt die Makros des Satzes an oder aktualisiert sie (nur Makros, deren Name mit „qn“ beginnt) und legt Zauber und Makros auf die Tasten der qnNumKeyPad-Leiste, einschließlich ihres Strg-Sets. Außerdem kann es die aktuelle Ziffernblock-Belegung und die qn-Makros deines Charakters als neuen Satz exportieren. Zauber- und Gegenstandsnamen stehen in den Sätzen auf Englisch; qnLoadout übersetzt sie beim Laden in die Sprache deines Clients.

## Funktionen

- Sätze pro Klasse, auswählbar auf einer Optionsseite, mit kurzer Zusammenfassung (Beschreibung, Anzahl Makros und Ziffernblocktasten)
- Laden mit Rückfrage: legt qn-Makros an oder ändert sie, belegt oder leert die im Satz aufgeführten Ziffernblocktasten (normale Aktionen und Strg-Set)
- Sicher: andere Makros bleiben unberührt, nichts wird gelöscht, nicht aufgeführte Ziffernblocktasten bleiben unverändert
- Vorhandene qn-Makros werden geändert statt neu angelegt und behalten so ihre Plätze auf deinen Aktionsleisten
- Funktioniert auf deutschen und englischen Clients: Zauber- und Gegenstandsnamen werden automatisch übersetzt
- Genauer Bericht im Chat: angelegte, geänderte, belegte, geleerte und übersprungene Einträge mit Grund
- Export des aktuellen Stands deines Charakters als Satz (JSON-Text zum Kopieren)
- Mitgelieferte Sätze (alle für die Logitech-G502-Einrichtung von qnNumKeyPad): Druide, Jäger, Magier, Priester, Krieger

## Erste Schritte

qnLoadout benötigt qnCore und qnNumKeyPad. Öffne *Optionen → Addons → qnLoadout* oder gib `/qnloadout` ein. Es gibt eine Seite, **qnLoadout**.

1. Wähle unter **Satz:** einen Satz aus (es erscheinen nur Sätze deiner aktuellen Klasse).
2. Lies die Zusammenfassung unter der Auswahl.
3. Klicke auf **Satz laden** und bestätige mit **Laden**.

Speicherung: qnLoadout hat keine Profile. Der zuletzt gewählte Satz wird pro Klasse gemerkt, Exporte werden accountweit gespeichert. Die geladenen Makros und Aktionsplätze speichert WoW (Charakter-Makros und Aktionsplätze pro Charakter, Account-Makros für alle Charaktere).

## Optionen

### qnLoadout

**Laden**

- Infozeile „Sätze für <Klasse>:“ – oder ein Hinweis, wenn es für deine Klasse keinen Satz gibt.
- **Satz:** – Auswahl unter den Sätzen deiner Klasse. Standard: der zuletzt für diese Klasse gewählte Satz, sonst der erste.
- Zusammenfassung – Die Beschreibung des Satzes (falls vorhanden) und „<n> Makros, <n> Ziffernblocktasten“.
- **Satz laden** – Fragt nach („qn-Makros werden angelegt oder geändert und die Ziffernblocktasten des Satzes für diesen Charakter belegt“) und lädt dann den Satz:
  - **Makros:** Ein qn-Makro mit gleichem Namen und gleicher Art (Account oder Charakter) wird geändert, sonst angelegt. Übersprungen, wenn der Name nicht mit „qn“ beginnt, wenn ein Makro dieses Namens als die andere Art existiert oder wenn kein Makroplatz frei ist.
  - **Ziffernblocktasten:** Jede im Satz aufgeführte Taste bekommt ihren Zauber oder ihr Makro oder wird geleert. Übersprungen, wenn die Taste beim aktuellen Tastaturlayout nicht auf der Leiste ist, wenn das Strg-Set in qnNumKeyPad ausgeschaltet ist, bei Tasten ab 13 im Strg-Set oder wenn dein Charakter den Zauber nicht kennt bzw. das Makro nicht gefunden wird.
  - Das Ergebnis erscheint im Chat, jeder übersprungene Eintrag in einer eigenen Zeile.

**Exportieren**

Speichert die Ziffernblock-Belegung dieses Charakters (normale Aktionen und das eingeschaltete Strg-Set) und seine qn-Makros als Satz: Zauber per Name oder ID, Makros per Name. Exportiert werden alle qn-Charakter-Makros und die qn-Account-Makros, die auf der Leiste liegen. Gegenstände, Reittiere und anderer Inhalt auf der Leiste werden ausgelassen.

- **Name:** – Name des Exports. Standard: „<Klasse> <Charaktername>“.
- **Exportieren** – Erstellt den Export (auch mit Enter im Namensfeld). Der Satz erscheint als JSON-Text in einem Feld darunter, bereits markiert zum Kopieren (Strg+C). Der Chat nennt Zauber, die per ID exportiert wurden, Gegenstandsnamen, die nicht übersetzt werden konnten, und wie viele Plätze mit anderem Inhalt ausgelassen wurden.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qnloadout` (auch `config`, `options`) | Optionen öffnen |
| `/qnloadout list` | Sätze für deine Klasse im Chat auflisten |
| anderer Text | Liste der Befehle anzeigen |

## Tipps & Hinweise

- **Nicht im Kampf:** Sätze können im Kampf nicht geladen werden. Auch solange etwas am Mauszeiger hängt, lädt qnLoadout nicht – zuerst ablegen oder fallen lassen.
- **Account-Makros:** Enthält ein Satz Account-Makros, ändert das Laden sie für alle deine Charaktere.
- **Platzhalter:** Einige Makros der mitgelieferten Sätze enthalten Platzhalter wie `<your healing potion>`. Bearbeite diese Makros danach im Makrofenster und trage deinen eigenen Gegenstand ein.
- **Noch nicht erlernte Zauber** werden übersprungen und im Chat gemeldet; lade den Satz später einfach erneut (bereits belegte Tasten und Makros werden nur aktualisiert).
- **Strg-Set:** Einträge für Strg + Taste werden nur geladen, wenn das Strg-Set in qnNumKeyPad eingeschaltet ist (Seite *Aktionsplätze*).
- **Tastaturlayout:** Die Tasten eines Satzes sind Ziffernblocktasten; ist eine Taste beim aktuellen qnNumKeyPad-Layout nicht auf der Leiste, wird sie übersprungen.
- **Gegenstandsnamen** werden nach dem Einloggen im Hintergrund geladen; fehlt ein Name noch, bleibt er im Makro englisch und der Chat meldet das.
- Namen und Beschreibungen der Sätze erscheinen so, wie sie im Satz stehen (englisch).
- Für Fortgeschrittene: Exporte landen in den gespeicherten Variablen; nach dem Ausloggen oder `/reload` macht das Entwicklerwerkzeug `tools\Convert-QnLoadout.ps1 -Import` aus dem Repository daraus Satzdateien, die nach einer Umwandlung und `/reload` im Spiel erscheinen.

[← Übersicht](README.md)
