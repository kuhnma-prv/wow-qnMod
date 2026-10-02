# qnCore – Kern der qn-Addons: Profile, Taschen-Automatik, Verfolgung

qnCore wird von allen anderen qn-Addons benötigt. Es verwaltet die Einstellungsprofile aller
qn-Addons (ein Profil je Layout des Bearbeitungsmodus), öffnet und schließt deine Taschen automatisch
am Auktionshaus, an der Bank, beim Händler und an anderen Orten, merkt sich deine Verfolgung an der
Minikarte über Einloggen, Tod und /reload hinweg und kann die Schrift der Questzielverfolgung unter
Blizzards Minimum von 12 verkleinern.

## Funktionen

- **Profile je Layout des Bearbeitungsmodus** für alle qn-Addons: Wechselst du im
  Bearbeitungsmodus das Layout, wechseln die Einstellungen aller qn-Addons mit. Charakterspezifische
  Layouts haben eigene Profile.
- Ein neues Layout startet mit einer Kopie des bisher aktiven Profils.
- **Seite „Profile“**: gespeichertes Profil ins aktive kopieren, Profile löschen, aktives Profil
  zurücksetzen – für alle qn-Addons auf einmal oder für ein einzelnes Addon.
- **Taschen-Automatik**: was mit deinen Taschen passiert, wenn Auktionshaus, Bank, Gildenbank,
  Händler, Handelsfenster oder Briefkasten auf- und zugehen – eine Einstellung für alle Orte oder
  eine je Ort.
- Wahlweise bleiben Berufstaschen (Kräuter-, Verzauberertasche …, Reagenzientasche) zu, wenn alle
  Taschen aufgehen.
- **Verfolgung merken**: stellt die Auswahl im Verfolgungsmenü der Minikarte (z. B. Kräutersuche,
  Mineraliensuche) nach dem Einloggen, /reload, Zonenwechsel und der Wiederbelebung wieder her.
- **Schriftgröße der Questzielverfolgung** 8–11 (unter Blizzards Minimum), je Profil.

## Erste Schritte

Öffne *Optionen → Addons → qnCore* (Esc → Optionen → Reiter Addons). qnCore hat drei Seiten:

- **qnCore** – Profil-Schaltfläche, Minikarte, Questzielverfolgung
- **Taschen-Automatik**
- **Profile**

`/qncore` (oder `/qnc`) öffnet die Hauptseite, `/qncore profile` die Seite „Profile“.

## Optionen

### qnCore

**Profil**

- **Einstellungsprofile** – die Schaltfläche **Profile …** öffnet die Seite „Profile“.

**Minikarte**

- **Verfolgung merken** – merkt sich je Charakter, was im Verfolgungsmenü der Minikarte an- oder
  abgewählt ist, und stellt es nach dem Einloggen, /reload, Zonenwechsel und der Wiederbelebung
  wieder her. Was du selbst änderst (Menü, Verfolgungszauber aus der Aktionsleiste oder dem
  Zauberbuch), wird gemerkt; was WoW verliert (Tod, Reload), wird zurückgeholt. Beim Einschalten
  wird die aktuelle Auswahl übernommen. Standard: an. Der Schalter gilt accountweit, die gemerkte
  Auswahl je Charakter.

**Questzielverfolgung**

- **Schriftgröße** – Schriftgröße der Questzielverfolgung unter Blizzards Minimum:
  **Wie im Bearbeitungsmodus**, 8, 9, 10 oder 11 (Überschriften 2 größer). Bei „Wie im
  Bearbeitungsmodus“ gilt Blizzards Regler. Standard: Wie im Bearbeitungsmodus. Gilt je Profil
  (= je Layout des Bearbeitungsmodus).

### Taschen-Automatik

Alle Taschen-Einstellungen gelten accountweit (für alle Charaktere und alle Profile).

**Allgemein**

- **Taschen-Automatik aktiv** – schaltet die gesamte Taschen-Automatik ein oder aus. Schalte sie aus,
  wenn ein anderes Taschen-Addon das Öffnen und Schließen übernimmt. Standard: an.
- **Berufstaschen mit öffnen** – beim Öffnen aller eigenen Taschen (Taste B, Händler, Bank …) gehen
  auch Berufstaschen wie Kräuter- oder Verzauberertasche und die Reagenzientasche auf. Aus: sie
  bleiben zu; einzeln angeklickt öffnen sie sich weiterhin. Bei zusammengefassten Taschen wirkt das
  nur auf die Reagenzientasche. Standard: an.
- **An allen Orten gleich** – an: eine Einstellung gilt für jeden Ort. Aus: jeder Ort wird einzeln
  eingestellt. Standard: aus.
- **Überall: beim Öffnen** – was mit den Taschen passiert, wenn einer der Orte geöffnet wird (nur mit
  „An allen Orten gleich“ nutzbar). Auswahl: **Nichts tun**, **Alle Taschen öffnen**,
  **Nur den Rucksack öffnen**, **Alle Taschen schließen**. Standard: Alle Taschen öffnen.
- **Überall: beim Schließen alle Taschen schließen** – schließt alle Taschen, wenn der Ort wieder
  zugeht (nur mit „An allen Orten gleich“ nutzbar). Standard: an.

**Auktionshaus, Bank, Gildenbank, Händler, Handel mit Spielern, Briefkasten**

Je Ort ein Abschnitt (nur nutzbar, solange „An allen Orten gleich“ aus ist):

- **<Ort>: beim Öffnen** – Auswahl wie oben. Standard: Alle Taschen öffnen.
- **<Ort>: beim Schließen alle Taschen schließen** – Standard: an.

### Profile

Zeigt das aktive Profil und alle gespeicherten Profile. Die Profilnamen nennen das Layout und seine
Art: „(Blizzard-Vorgabe)“, „(Konto)“ oder „(charakterspezifisch, <Charakter>)“.

- **Aktives Profil:** – das gerade benutzte Profil (= aktives Layout des Bearbeitungsmodus).
- **Gilt für:** – Auswahl: **Alle qn-Addons** oder ein einzelnes qn-Addon. Die Liste und alle
  Schaltflächen dieser Seite wirken nur auf die gewählten Addons.
- **Aktives Profil zurücksetzen** – setzt die Einstellungen des aktiven Profils auf die
  Standardwerte (nach Rückfrage).
- **Gespeicherte Profile** – eine Zeile je Profil; fährst du mit der Maus darüber, siehst du, bei
  welchen Addons das Profil vorhanden ist („Vorhanden bei: …“).
  - **In aktives Profil kopieren** – ersetzt die Einstellungen des aktiven Profils durch die dieses
    Profils (nach Rückfrage). Beim aktiven Profil selbst nicht verfügbar.
  - **Löschen** – löscht dieses Profil (nach Rückfrage). Das aktive Profil kann nicht gelöscht werden.

Im Kampf werden Kopieren und Zurücksetzen erst nach dem Kampf angewendet (eine Chatmeldung weist
darauf hin).

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qncore`, `/qnc` (oder `/qncore config`) | Öffnet die Optionen von qnCore |
| `/qncore profile` | Öffnet die Seite „Profile“ |
| `/qncore status` | Zeigt im Chat die Version von qnCore, das aktive Profil und die Anzahl der Profile je qn-Addon |
| `/qncore locale` | Deutscher Client: listet Texte, die in dieser Sitzung ohne Übersetzung angezeigt wurden |
| `/qncore <sonstiges>` | Zeigt eine kurze Hilfe im Chat |

## Tipps & Hinweise

- qnCore muss für jedes andere qn-Addon installiert und aktiviert sein.
- Für unterschiedliche Einstellungen legst du im Bearbeitungsmodus (Esc → Bearbeitungsmodus) Layouts
  an oder wechselst sie. Beim Profilwechsel erscheint im Chat „Profil gewechselt: …“. Bis das Layout
  nach dem Einloggen bekannt ist, gilt das Profil der letzten Sitzung dieses Charakters.
- Kopieren in das aktive Profil überschreibt dessen bisherige Einstellungen.
- Die Taschen-Automatik greift einen Frame nach Blizzards eigenen Fenstern und hat damit das letzte
  Wort. Nutzt du ein anderes Taschen-Addon, schalte **Taschen-Automatik aktiv** aus.
- Beim Wiederherstellen der Verfolgung werden Verfolgungszauber nacheinander gewirkt (mit kurzer Pause
  für die globale Abklingzeit); im Kampf oder solange du tot bist, wartet qnCore damit.
- Nach einer Änderung der Schriftgröße passt Blizzard die Zeilenabstände beim nächsten eigenen
  Neuaufbau der Questzielverfolgung an (Questfortschritt, Zonenwechsel, spätestens /reload).
- Ist LibSharedMedia installiert, meldet qnCore seine Hintergrundmuster dort als „qn …“ an
  (z. B. „qn Stripes“), sodass andere Addons sie nutzen können.

[← Übersicht](README.md)
