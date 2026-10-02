# qnSkins – Bilder rund um deine Aktionsleisten

qnSkins zeichnet schmückende Bilder – Hintergründe, umrahmte Kästen, eine leuchtende Kordel und
3D-Figuren – um Aktionsleisten, Statusleisten und Mikromenü am unteren Bildschirmrand. Normalerweise
folgen die Bilder den Elementen, wo immer du sie hingestellt hast. Auf Wunsch gibt qnSkins den
Elementen auch eine vordefinierte Position und Skalierung, auf dem Monitor deiner Wahl.

## Funktionen

- Zwei Skins:
  - **Drachenhort** – ein dunkles Felsband über die ganze Breite des Monitors, oben abgeschlossen
    von einer rot-goldenen Kordel knapp über allen Elementen am unteren Rand; Kästen mit dünnem
    Rand um die Leistengruppe, qnThreatMeter und qnNumKeyPad; ein stehender 3D-Krieger (eine
    Stadtwache deiner Fraktion) am rechten Ende der Statusleisten.
  - **Steinrahmen** – eine Marmorfläche um die Leistengruppe.
- Die Bilder liegen unter den Elementen und fangen keine Mausklicks ab.
- Opt-in **Elemente positionieren**: verschiebt und skaliert die Elemente auf die Anordnung des
  Skins und hält sie dort, auch nach dem Bearbeitungsmodus.
- Skalierung und Versatz des ganzen Skins, Wahl des Monitors (mit qnViewPort).
- Jede 3D-Figur einstellbar: Zoom, seitlich, Höhe, Drehung, Animation und Größe ihres Bereichs.
- Figuren können im Kampf stillstehen.

## Erste Schritte

Öffne *Optionen → Addons → qnSkins* oder gib `/qnskins` ein. Wähle unter **Skin** einen Skin. Auf
der Unterseite **Figuren** stellst du die 3D-Figuren ein.

Alle Einstellungen gehören zum aktiven Profil, also zum aktiven Layout des Bearbeitungsmodus
(siehe [qnCore](qnCore.md)).

## Optionen

### qnSkins (Hauptseite)

Abschnitt **Skin**:

- **Skin**: **Keiner** (Standard), **Drachenhort** oder **Steinrahmen**. Bilder um Aktionsleisten,
  Statusleisten und Mikromenü.
- **Elemente positionieren**: verschiebt und skaliert die Elemente auf die Positionen des Skins und
  hält sie dort, auch nach dem Bearbeitungsmodus. Ohne diese Option folgen die Bilder den Elementen,
  wo immer sie stehen. Nach dem Ausschalten bleiben die aktuellen Positionen bis `/reload` erhalten.
  Standard: aus.
- **Monitor**: Monitor, auf dem der Skin liegt – **Automatisch (Monitor mit der 3D-Ansicht)**
  (Standard; mit qnViewPort der Monitor mit der 3D-Welt, sonst der größte) oder **Monitor 1**,
  **Monitor 2** … von links gezählt. Nur mit **Elemente positionieren**.
- **Horizontaler Versatz**: verschiebt den ganzen Skin, −800 bis 800 UI-Einheiten, Standard 0. Nur
  mit **Elemente positionieren**.
- **Vertikaler Versatz**: −400 bis 400, Standard 0. Nur mit **Elemente positionieren**.
- **Skalierung**: 0,5–2, Standard 1. Skalierung der Bilder und – mit **Elemente positionieren** –
  der Elemente.
- **Figuren im Kampf anhalten**: Die 3D-Figuren stehen still, solange du im Kampf bist. Standard: an.
- **Erneut anwenden** – **Anwenden**: setzt die Elemente und die Bilder jetzt erneut (wie
  `/qnskins apply`).

Mit **Elemente positionieren** ordnen beide Skins die Elemente am unteren Rand des Monitors an:
Statusleiste 1 unten in der Mitte, Statusleiste 2 darüber, darüber das Mikromenü, Aktionsleiste 2
rechts vom Mikromenü, Aktionsleiste 1 über Aktionsleiste 2, der Haustierbalken über Aktionsleiste 1
(rechtsbündig) und der Fahrzeug-verlassen-Knopf über Aktionsleiste 1 (linksbündig). qnThreatMeter
kommt links neben qnNumKeyPad und behält seine eigene Skalierung. Die rechten Aktionsleisten (4 und
5) bleiben unberührt.

### Figuren

Ein Abschnitt je 3D-Figur jedes Skins, überschrieben mit „Skin – Figur“ (derzeit **Drachenhort –
Krieger**). Die Werte wirken sofort.

- **Zoom**: Abstand der Kamera; größere Werte zeigen die Figur kleiner. 0,2–4, Standard 1.
- **Seitlich**: −10 bis 10, Standard 0.
- **Höhe**: verschiebt die Figur innerhalb ihres Bereichs nach oben oder unten; Teile außerhalb des
  Bereichs werden abgeschnitten. −10 bis 10, Standard 0.
- **Drehung**: −3,15 bis 3,15, Standard −0,4 beim Krieger.
- **Animation**: Nummer der Animation, 0 = stehend (Standard). Welche Nummer eine Figur liegen oder
  schlafen lässt, hängt vom Modell ab – ausprobieren. 0–250.
- **Bereich unten** / **Bereich oben**: erweitert den Bereich der Figur nach unten bzw. oben
  (UI-Einheiten, −100 bis 400, Standard 0). Die Figur wird an ihrem Bereich abgeschnitten; ein
  größerer Bereich zeigt sie meist größer – mit **Zoom** ausgleichen.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/qnskins`, `/qnskins config`, `/qnskins options` | Optionen öffnen |
| `/qnskins apply` | Skin erneut anwenden |
| `/qnskins list` | Skins auflisten (der aktive ist mit `>` markiert) |
| `/qnskins frames` | Elemente (Name im Bearbeitungsmodus, sichtbar/ausgeblendet, Größe, Position) und die Bildteile des aktiven Skins auflisten |
| `/qnskins model <Bild> <Kreatur-ID \| d:Display-ID> [Animation] [Drehung]` | Anderes Modell für eine Figur bis zum nächsten Neuladen ausprobieren; Animation und Drehung werden gespeichert |
| `/qnskins camera <Bild> <Zoom> [seitlich] [Höhe]` | Zoom und Lage einer Figur setzen (gespeichert wie auf der Seite **Figuren**) |
| `/qnskins help` | Befehlsliste anzeigen |

`<Bild>` ist der Schlüssel einer Figur des aktiven Skins, z. B. `warrior` bei Drachenhort (siehe
`/qnskins frames`).

## Tipps & Hinweise

- Die Bilder liegen unter den Elementen; später eingeblendete Leisten (Haustierbalken,
  Fahrzeug-verlassen-Knopf) verdecken sie also.
- Ausgeblendete Elemente zählen dort, wo sie erscheinen würden, sofern das im unteren Teil des
  Bildschirms liegt – so lässt das Band auch Platz für Leisten, die nur manchmal zu sehen sind.
- **Elemente positionieren** wirkt nicht, solange der Bearbeitungsmodus offen ist; danach werden die
  Positionen des Skins wieder gesetzt. Verschiebt Blizzard oder ein anderes Addon ein Element, setzt
  qnSkins es zurück.
- Im Kampf lassen sich geschützte Elemente nicht verschieben; die Positionierung folgt dann direkt
  nach dem Kampf.
- Bei Drachenhort läuft die Kordel knapp über dem höchsten der unteren Elemente: Aktionsleisten 1
  und 2, Haustierbalken, Fahrzeug-verlassen-Knopf, Mikromenü, Statusleisten, Besitzbalken,
  Zusatzfähigkeiten, Zonenkarte, qnThreatMeter und qnNumKeyPad. Lass diese am
  unteren Bildschirmrand, sonst reicht das Band bis zu ihnen hinauf. qnThreatMeter und qnNumKeyPad
  bekommen eigene Kästen, wenn sie geladen sind.
- Optionale Abhängigkeit qnViewPort: Bei mehreren Monitoren nutzt der Skin dessen Monitorbereiche;
  ohne qnViewPort zählt das ganze Fenster als ein Monitor.

[← Übersicht](README.md)
