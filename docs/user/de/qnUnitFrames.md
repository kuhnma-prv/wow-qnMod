# qnUnitFrames – Klickzauber und Reichweitensymbol

qnUnitFrames bringt Klickzauber auf Blizzards eigene Gruppen- und Schlachtzugsrahmen, ähnlich wie
HealBot: Ein Klick mit einer Maustaste und optional einer Zusatztaste wirkt einen Zauber oder ein
Makro auf das angeklickte Gruppenmitglied. Die Belegung legst du je Klasse fest, sie liegt im
aktiven Profil (Layout des Bearbeitungsmodus). Außerdem kann qnUnitFrames ein kleines
Reichweitensymbol neben dem Ziel- und dem Fokusrahmen zeigen.

## Funktionen

- Klickzauber auf Blizzards Gruppenrahmen im Schlachtzugsstil, den Schlachtzugsrahmen, den
  klassischen Gruppenrahmen und den Begleiterrahmen.
- 5 Maustasten × 8 Zusatztasten-Kombinationen (ohne, UMSCHALT, STRG, ALT und ihre Kombinationen).
- Aktionen: Zauber (aus dem Zauberbuch oder per Name/Zauber-ID), Makrotext, Ziel, Menü,
  Fokus setzen, Assistieren – oder Blizzards Verhalten beibehalten.
- Auf Wunsch eine Liste der Belegung unter dem Tooltip eines belegten Rahmens.
- Belegung je Klasse und je Profil; ein anderes Layout des Bearbeitungsmodus kann eine andere
  Belegung haben.
- Reichweitensymbol rechts neben dem Ziel- und/oder Fokusrahmen: zeigt das Symbol deiner
  einsetzbaren Fernkampfaktion mit der größten Reichweite, solange die Einheit in ihrer Reichweite
  ist, und in Nahkampfreichweite das Symbol des automatischen Angriffs.
- Änderungen im Kampf werden nach dem Kampf automatisch übernommen.

## Erste Schritte

Öffne *Optionen → Addons → qnUnitFrames* oder gib `/qnuf` ein. Die Seite **Klickbelegung**
darunter enthält die eigentliche Belegung (`/qnuf clicks`).

Alle Einstellungen gehören zum aktiven Profil, also zum aktiven Layout des Bearbeitungsmodus
(Profile verwaltest du auf der Seite **Profile** von qnCore). Die Klickbelegung liegt im Profil
zusätzlich je Klasse.

## Optionen

### qnUnitFrames

**Allgemein**

- **Klickzauber aktiv** – schaltet die Klickzauber ein oder aus. Aus hebt alle Belegungen von
  qnUnitFrames auf; die Rahmen verhalten sich wie ohne Addon. Standard: an.
- **Klickbelegung** – die Schaltfläche **Bearbeiten …** öffnet die Seite Klickbelegung.
- **Belegung im Tooltip zeigen** – zeigt unter dem Tooltip eines belegten Rahmens, welcher Klick
  was bewirkt (z. B. „UMSCHALT+Linke Maustaste – Blitzheilung“). Standard: an.

**Rahmen** – welche Rahmen die Belegung erhalten:

- **Rahmen im Schlachtzugsstil** – Blizzards Schlachtzugsfenster und die Gruppenrahmen mit der
  Einstellung „Gruppen wie Schlachtzüge anzeigen“. Standard: an.
- **Klassische Gruppenrahmen** – die Gruppenrahmen ohne diese Einstellung. Standard: an.
- **Begleiterrahmen** – auch die Rahmen der Begleiter von Gruppenmitgliedern belegen.
  Standard: an.

**Reichweitensymbol** – ein Block je Rahmen:

- **Am Zielrahmen** / **Am Fokusrahmen** – zeigt das Reichweitensymbol rechts neben dem Rahmen.
  Standard: aus.
- **Symbolgröße** – 12 bis 64, Standard 24.
- **Horizontaler Versatz** – Abstand vom rechten Rand des Rahmens (−200 bis 200, Standard 0);
  negative Werte verschieben das Symbol nach links.
- **Vertikaler Versatz** – Abstand von der vertikalen Mitte des Rahmens (−200 bis 200,
  Standard 0); positive Werte verschieben das Symbol nach oben.

Größe und Versatz lassen sich nur ändern, solange das Symbol am jeweiligen Rahmen eingeschaltet ist.

So entscheidet das Reichweitensymbol, was es zeigt (Prüfung etwa fünfmal pro Sekunde):

- **Nahkampfreichweite:** Das Symbol des automatischen Angriffs erscheint, wenn keiner deiner
  prüfbaren Nahkampfzauber „außer Reichweite“ meldet. Hast du keinen prüfbaren Nahkampfzauber
  (z. B. als Druide ohne Tiergestalt), entscheidet die Duell-Entfernung (etwa 10 Meter).
- **Sonst:** Es erscheint das Symbol deines gerade einsetzbaren schädlichen Fernkampfzaubers aus
  dem Zauberbuch mit der größten Reichweite, sobald die Einheit in seiner Reichweite ist. Fehlendes
  Mana, Wut oder Energie blendet es nicht aus.
- Kein Symbol, wenn du die Einheit nicht angreifen kannst (z. B. freundliche Einheiten), wenn sie
  außerhalb der Reichweite all dieser Zauber ist oder sich die Reichweite nicht prüfen lässt.

### Klickbelegung

Oben steht, für welche Klasse und welches Profil die Belegung gilt
(„Belegung für Priester im Profil …“).

- **Maustaste:** – wählt die Maustaste, die du bearbeitest (Linke Maustaste, Rechte Maustaste,
  Mittlere Maustaste, Maustaste 4, Maustaste 5). Standard: Linke Maustaste.
- **Alle löschen** – löscht nach einer Rückfrage alle Klickbelegungen der eigenen Klasse im
  aktiven Profil (alle Maustasten).
- Eine Zeile je Zusatztaste (**Ohne Zusatztaste**, **UMSCHALT**, **STRG**, **ALT**,
  **STRG+UMSCHALT**, **ALT+UMSCHALT**, **ALT+STRG**, **ALT+STRG+UMSCHALT**), jeweils mit einer
  Auswahl der Aktion:
  - **Blizzard-Standard** – nichts wird geändert (Linksklick: Ziel auswählen, Rechtsklick: Menü).
    Das ist die Vorgabe für jede Zeile.
  - **Zauber** – eine zweite Auswahl **Zauber wählen …** listet die aktiven Zauber deines
    Zauberbuchs. **Anderer Zauber …** öffnet ein Eingabefeld für einen Zaubernamen oder eine
    Zauber-ID (z. B. für noch nicht erlernte Zauber).
  - **Makro** – **Bearbeiten …** öffnet den Makro-Editor unten auf der Seite; die Zeile zeigt den
    Anfang des Makrotexts. Das Makro wirkt nicht automatisch auf die angeklickte Einheit: Nutze
    `[@mouseover]`, z. B. `/cast [@mouseover] Heilen`. Bis zu 255 Zeichen; Leerzeilen werden
    entfernt. **Annehmen** speichert, **Abbrechen** verwirft.
  - **Ziel**, **Menü**, **Fokus setzen**, **Assistieren** – die entsprechende Aktion auf die
    angeklickte Einheit.

Hinweis: Belegst du Linksklick ohne Zusatztaste mit einem Zauber, wählst du mit diesem Klick kein
Ziel mehr aus.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qnuf`, `/qnunitframes` (auch `config`, `options`) | Optionen öffnen |
| `/qnuf clicks` | Seite Klickbelegung öffnen |
| `/qnuf on` | Klickzauber einschalten |
| `/qnuf off` | Klickzauber ausschalten |
| `/qnuf` + etwas anderes | Liste der Befehle zeigen |

## Tipps & Hinweise

- Blizzard erlaubt im Kampf keine Änderung der Belegung an den Rahmen. Änderungen im Kampf
  (auch ein Profilwechsel) greifen automatisch nach dem Kampf; eine Chatmeldung weist darauf hin.
- Die Belegung gilt je Klasse: Priester und Druide im selben Profil haben jeweils eine eigene.
  Ein Wechsel des Layouts im Bearbeitungsmodus wechselt das Profil und damit die Belegung.
- Belegt werden nur Blizzards Gruppen- und Schlachtzugsrahmen, keine Namensplaketten, nicht der
  Zielrahmen und keine Rahmen anderer Addons.
- Das Reichweitensymbol berücksichtigt nur schädliche Zauber aus deinem Zauberbuch, keine
  Heilzauber.
- Benötigt qnCore.

[← Übersicht](README.md)
