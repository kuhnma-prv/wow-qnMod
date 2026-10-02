# qnMod – Benutzerhandbuch

qnMod ist eine Sammlung kleiner, spezialisierter Addons für **World of Warcraft Classic Forever**.
Alle bauen auf **qnCore** auf und werden in Blizzards eigenem Einstellungsfenster eingerichtet:
*Optionen → Addons → <Addon>*. Die meisten Einstellungen gehören zu einem **Profil**, und das aktive
Profil ist das aktive **Layout des Bearbeitungsmodus**: Wechselst du das Layout, wechseln die
Einstellungen aller qn-Addons mit (Profile verwaltest du auf der Seite **Profile** von qnCore).

English version: [English](../en/README.md) · Änderungen: [CHANGELOG](../../../CHANGELOG.md)

## Installation

1. Lade `qnMod-<Version>.zip` vom
   [neuesten Release](https://github.com/kuhnma-prv/wow-qnMod/releases/latest) herunter.
2. Entpacke die gewünschten `qn*`-Ordner nach `World of Warcraft\_classic_beta_\Interface\AddOns\`.
   **qnCore wird immer benötigt**; qnLoadout braucht zusätzlich qnNumKeyPad.
3. Starte das Spiel oder gib `/reload` ein.

Sprache: Deutsche Clients zeigen deutsche Texte, alle anderen Clients englische.

## Addons

| Addon | Was es macht | Slash-Befehle |
|---|---|---|
| [qnCore](qnCore.md) | Kern aller qn-Addons (Pflicht): ein Einstellungsprofil je Layout des Bearbeitungsmodus (Kopieren, Löschen, Zurücksetzen), öffnet und schließt die Taschen automatisch an Auktionshaus, Bank, Händler und ähnlichen Orten, merkt sich die Verfolgung an der Minikarte, Schrift der Questzielverfolgung unter 12. | `/qncore`, `/qnc` |
| [qnThreatMeter](qnThreatMeter.md) | Bedrohungsanzeige für die Gruppe gegen das aktuelle Ziel im Stil der eingebauten Schadensanzeige: Wert, TPS, Prozent, Balken „Aggro ziehen“, Warnung bei hoher Bedrohung. | `/qnm`, `/qnthreatmeter` |
| [qnNumKeyPad](qnNumKeyPad.md) | Aktionsleiste in Form eines Ziffernblocks (6 Tastaturlayouts) mit automatischer Tastenbelegung, Strg-Set, Haltungswechsel und Unterstützung für die Logitech G502 (Maustaste → Ziffernblocktaste, Zauber und Makros auf Maustasten). | `/qnnkp`, `/qnnumkeypad`, `/numpad` |
| [qnLoadout](qnLoadout.md) | Lädt fertige Sätze pro Klasse: legt `qn`-Makros an oder ändert sie und belegt die qnNumKeyPad-Tasten (auch das Strg-Set); exportiert den aktuellen Stand als Satz. | `/qnloadout` |
| [qnViewPort](qnViewPort.md) | Kleinerer 3D-Bereich mit Randfarbe und -muster; Mehrmonitor-Modus (3D-Welt auf dem Hauptmonitor, Taschen, Karten und Uhr auf einem gewählten Monitor, Tooltips bleiben auf ihrem Monitor); Titan-Leisten je Monitor. | `/qnvp`, `/qnviewport`, `/viewport` |
| [qnInventory](qnInventory.md) | Merkt sich Taschen, Bank, Post und Gold aller Charaktere (auch die Accountbank), Bestand je Charakter im Tooltip, Taschen/Bank/Post jedes Charakters überall, Titan-Panel-Plugins für Plätze und Gold. | `/qninv`, `/qninventory` |
| [qnBuffMod](qnBuffMod.md) | Bis zu 10 frei gestaltbare Fenster für Stärkungs- und Schwächungszauber von Spieler, Fahrzeug, Begleiter, Ziel oder Fokus: Symbol mit Balken oder nur Symbol, Gruppierung, Sortierung, Sichtbarkeitsbedingungen, Warnung vor Ablauf, Taste „Stärkungszauber erneuern“. | `/qnbuff`, `/qnbuffmod`, `/qnaura` |
| [qnUnitFrames](qnUnitFrames.md) | Klickzauber auf Blizzards Gruppen-, Schlachtzugs- und Begleiterrahmen (wie HealBot), je Klasse und Profil; optional ein Reichweitensymbol am Ziel- und Fokusrahmen. | `/qnuf`, `/qnunitframes` |
| [qnTooltip](qnTooltip.md) | Anpassbare Tooltips: Hintergrund, Rahmen, Schriften, Skalierung, Position auf Wunsch, Lebensbalken, Kopfzeilen von Einheiten aus Bausteinen, Ziel und „Anvisiert von“, 3D-Modell, Gegenstandsstufe, IDs. | `/qntt`, `/qntooltip` |
| [qnSkins](qnSkins.md) | Schmückende Bilder (Band mit Kordel, Kästen, 3D-Figur) um Aktionsleisten, Statusleisten und Mikromenü; gibt diesen Elementen auf Wunsch eine vordefinierte Position und Skalierung auf einem gewählten Monitor. | `/qnskins` |

## Optionale Addons

- [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0): weitere Schriften,
  Texturen und Rahmen für qnThreatMeter und qnTooltip.
- [Titan Panel](https://www.curseforge.com/wow/addons/titan-panel): Leisten je Monitor (qnViewPort),
  Bank- und Gold-Plugins (qnInventory).

## Allgemeine Hinweise

- Blizzard sperrt manche Änderungen im Kampf (Tastenbelegung, Klickzauber, Verschieben geschützter
  Rahmen). Die qn-Addons übernehmen solche Änderungen automatisch nach dem Kampf.
- Kampfinformationen, die das Spiel vor Addons verbirgt (Secret Values), werden angezeigt, soweit das
  Spiel es erlaubt; manche Anzeigen arbeiten dann eingeschränkt.
