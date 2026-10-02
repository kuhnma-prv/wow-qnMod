# qnInventory – Taschen, Bank, Post und Gold aller deiner Charaktere

qnInventory merkt sich Taschen, Bank, Briefkasten und Gold jedes Charakters, mit dem du dich
einloggst. Der Item-Tooltip zeigt, wie viele Exemplare jeder Charakter besitzt, und du kannst
Taschen, Bank und Briefkasten jedes deiner Charaktere überall öffnen – in Fenstern wie denen von
Blizzard, mit einer Charakterauswahl darüber. Mit Titan Panel kommen zwei Plugins für belegte
Bank-/Taschenplätze und für Gold dazu.

## Funktionen

- Erfasst Taschen, Bank (Bankfächer des Charakters), Briefkasten und Gold jedes Charakters sowie
  die Accountbank (Gold jederzeit, Inhalt beim Bankier).
- Item-Tooltip: Bestand je Charakter als **Taschen/Bank/Post**, die Accountbank und eine Summe.
- Berücksichtigt deinen Realm und die mit ihm verbundenen Realms (angezeigt als „Name-Realm“).
- Ansichten von Taschen, Bank und Briefkasten jedes gespeicherten Charakters, auch fern von Bank
  und Briefkasten.
- Leiste über Blizzards kombinierten Taschen, dem Bankfenster und dem Briefkasten:
  Charakterauswahl und Knöpfe für die beiden anderen Ansichten.
- Post an deine eigenen Charaktere wird sofort deren Briefkasten gutgeschrieben.
- `/qninv gold`: Gold aller Charaktere des Realms im Chat.
- Titan Panel (optional): Plugins **qnInventory Bank/Taschen** und **qnInventory Gold**.
- Gespeicherte Daten von Charakteren löschen, die du nicht mehr spielst.

### Item-Tooltip

Unter dem Item-Tooltip (auch bei Item-Links im Chat) ergänzt qnInventory:

- eine Kopfzeile **Charakter – Taschen/Bank/Post**,
- eine Zeile je Charakter, der das Item besitzt, z. B. `3/10/0`; dein aktueller Charakter ist mit
  **(ich)** markiert,
- **Accountbank** mit ihrem Bestand,
- **Gesamt**, wenn mehr als eine Zeile erscheint.

`?` bedeutet: Bank bzw. Briefkasten dieses Charakters wurden nie geöffnet. `+` hinter der Post
heißt: Der Briefkasten ist nur teilweise bekannt (mehr als 50 Briefe oder nur deine eigenen Briefe
an einen Charakter, dessen Briefkasten nie geöffnet wurde). Items per Nachnahme zählen nicht mit.

### Ansichten

Über Blizzards kombinierten Taschen, dem Bankfenster und dem Briefkasten sowie über den eigenen
Fenstern von qnInventory hängt eine Leiste mit einer Charakterauswahl und Knöpfen für die beiden
anderen Ansichten (**Taschen**, **Bank**, **Post**).

- **Taschen** – deine eigenen Taschen öffnen sich in Blizzards Fenster; die Taschen anderer
  Charaktere in einem Nachbau des **Kombinierten Rucksacks** mit ihrem Gold unten. Reagenzientasche
  und Schlüsselbund erscheinen nicht (Blizzards kombinierter Rucksack zeigt sie auch nicht).
- **Bank** – der zuletzt gespeicherte Stand der Bank jedes Charakters, auch des eingeloggten fern
  der Bank: alle Fächer, Seitenreiter rechts, Taschenplätze und der Preis des nächsten Fachs.
  Sortieren und Kaufen sind hier gesperrt (geht nur beim Bankier).
- **Post** – der gespeicherte **Posteingang**, 7 Briefe pro Seite, Restzeit, Nachnahme-Kennzeichen.
  Ein Klick auf einen Brief öffnet ein Fenster mit Absender, Betreff, Anhängen und Gold bzw.
  Nachnahmebetrag. Der Brieftext erscheint nicht (ihn zu lesen würde den Brief als gelesen
  markieren).

Taschen- und Bankansicht haben ein Suchfeld, das nicht passende Items abdunkelt. Item-Tooltips
funktionieren wie gewohnt, Umschalt-/Strg-Klick fügt einen Chat-Link ein bzw. öffnet die
Anprobe. Die Fenster lassen sich per Ziehen verschieben und mit Escape schließen. Ist für einen
Charakter noch nichts erfasst, steht ein Hinweis im Fenster.

### Titan-Panel-Plugins

Nur vorhanden, wenn Titan Panel installiert ist. Beide Plugins stehen in Titans Kategorie
„Informationen“ und unterstützen Titans übliche Optionen (Symbol, Beschriftung, farbiger Text,
rechte Seite).

**qnInventory Bank/Taschen**

- Knopf: **Bank:** belegte/vorhandene Plätze und **Taschen:** belegte/vorhandene Plätze des
  eingeloggten Charakters (`?` = noch nicht erfasst). Mit *Farbigen Text anzeigen* werden die
  Zahlen je nach Füllstand weiß, gelb, orange oder rot (unter 50 %, 75 %, 90 %, darüber).
  Taschen zählen Rucksack, Taschen 1–4 und Reagenzientasche, nicht den Schlüsselbund.
- Tooltip: **Bank und Taschen**, je Fraktion ein Block (**Belegte Plätze auf** <Fraktion>) mit
  jedem Charakter und einer Summe, danach die Accountbank.
- Linksklick: Taschenansicht, Umschalt-Linksklick: Bankansicht.
- Rechtsklick-Menü: **Taschen**, **Bank**, **Optionen**.

**qnInventory Gold**

- Knopf: **Gold:** Gold aller Charaktere samt Accountbank oder nur des aktuellen Charakters
  (Rechtsklick-Menü: **Gold aller Charaktere** / **Zeige Spielercharakter-Gold**; Standard: alle
  Charaktere).
- Tooltip wie bei TitanGold: je Fraktion ein Block mit jedem Charakter und **Gesamtes Gold**,
  danach Accountbank und Gesamtsumme sowie die Sitzungsstatistik (Startgold, gewonnen bzw.
  verloren, pro Stunde).
- Rechtsklick-Menü: **Sitzung zurücksetzen**, **Optionen**.

## Erste Schritte

Logge dich mit jedem Charakter einmal ein. Bank und Briefkasten eines Charakters sind bekannt,
sobald du sie mit ihm einmal geöffnet hast.

Optionen: *Optionen → Addons → qnInventory* oder der Eintrag **Optionen** im Rechtsklick-Menü
eines der Titan-Plugins. Einen Slash-Befehl zum Öffnen der Optionen gibt es nicht: `/qninv` allein
zeigt die Goldliste im Chat.

## Optionen

Alle Optionen von qnInventory gelten **accountweit**. Sie wechseln nicht mit dem Layout des
Bearbeitungsmodus (Profil).

### qnInventory

**Fraktionen**

- **Tooltips: Allianz und Horde** – die Tooltips der Titan-Plugins (Bank/Taschen und Gold) zeigen
  die Charaktere beider Fraktionen. Aus: nur die der Fraktion des eingeloggten Charakters.
  Standard: aus.
- **Taschen, Bank und Post: auch die andere Fraktion** – die Charakterauswahl der Ansichten
  Taschen, Bank und Post enthält auch die Charaktere der anderen Fraktion. Aus: nur die der
  Fraktion des eingeloggten Charakters. Standard: aus.

Die Fraktion eines Charakters ist bekannt, sobald er einmal mit der aktuellen Version eingeloggt
war; bis dahin erscheint er immer. Der Item-Tooltip zeigt immer alle Charaktere.

**Charakter löschen**

- **Charakter** – der Charakter, dessen gespeicherte Daten (Taschen, Bank, Post, Gold) gelöscht
  werden sollen. Enthält alle gespeicherten Charaktere beider Fraktionen (dein Realm und
  verbundene Realms) außer dem eingeloggten. Standard: **Nichts**.
- **Ausgewählten Charakter löschen** (Knopf **Löschen**) – löscht nach einer Rückfrage die
  gespeicherten Daten des gewählten Charakters.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qninv` oder `/qninv gold` | Listet das Gold aller Charaktere dieses Realms (mit Gold im Briefkasten) und die Summe |
| `/qninv bags [Name]` | Öffnet/schließt die Taschenansicht (des genannten Charakters dieses Realms, sonst des zuletzt gewählten) |
| `/qninv bank [Name]` | Öffnet/schließt die Bankansicht |
| `/qninv mail [Name]` | Öffnet/schließt die Postansicht |
| `/qninv delete <Name>` | Löscht die gespeicherten Daten eines Charakters dieses Realms (nicht des eingeloggten) |

`/qninventory` funktioniert genauso wie `/qninv`. Groß-/Kleinschreibung der Namen spielt keine
Rolle.

## Tipps & Hinweise

- Die Bank ist nur lesbar, solange das Bankfenster offen ist, der Briefkasten nur, solange er
  offen ist. Sonst gilt der zuletzt gespeicherte Stand.
- Der Inhalt der Accountbank wird nur beim Bankier erfasst und nur, wenn dein Charakter sie
  einsehen darf.
- Die Leiste der Taschenansicht sitzt über Blizzards **kombinierten** Taschen.
- Post an eigene Charaktere zählt, sobald sie erfolgreich verschickt wurde. Items in
  Nachnahme-Briefen zählen erst nach der Bezahlung.
- `/qninv gold` und `/qninv delete` betreffen nur den aktuellen Realm; Optionsseite und Ansichten
  enthalten auch verbundene Realms.
- Gold im Briefkasten erscheint bei `/qninv gold`, nicht im Gold-Plugin von Titan.
- Mit qnViewPort bleiben die Item-Tooltips der Ansichten auf dem Monitor des Fensters.
- Titan Panel ist optional; ohne Titan gibt es einfach keine Plugins.

[← Übersicht](README.md)
