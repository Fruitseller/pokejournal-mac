# PLAN: Heatmap-Kalender (GitHub-Style)

## Ziel

Ein neuer Tab "Heatmap" in GameDetailView, der alle Sessions als Kalender-Grid zeigt — wie GitHub Contributions:
- Jeder Tag = ein kleines Quadrat
- **Intensität (Helligkeit)** = Textmenge der Session (mehr geschrieben → helleres/kräftigeres Grün)
- Auf einen Blick sieht man: Wann wurde gespielt, wie intensiv, gibt es Muster (z.B. Wochenenden)?

## Datengrundlage

Bereits vorhanden — keine Modelländerungen nötig:
- `Game.sessions` + `Game.oldSessions` → nach Datum gruppieren
- Textmenge pro Session: `activities.count + plans.count + thoughts.count`

## Datenaufbereitung

```
struct HeatmapDay {
    let date: Date
    let sessionCount: Int         // Normalerweise 1, aber theoretisch >1 möglich
    let textLength: Int           // Gesamte Zeichenzahl aller Texte
    let intensityLevel: Int       // 0-4 (wie GitHub: none, light, medium, strong, max)
}
```

**Intensitäts-Berechnung:**
1. Alle Sessions sammeln, Textlängen berechnen
2. Verteilung analysieren (Quartile oder feste Schwellen)
3. Stufen zuweisen:
   - **0** = kein Eintrag (leeres Quadrat)
   - **1** = kurze Session (< 25. Perzentil)
   - **2** = mittlere Session
   - **3** = lange Session
   - **4** = sehr lange Session (> 75. Perzentil)

## UI-Design

### Grid-Layout

```
         Dez          Jan          Feb
Mo  ■ □ □ ■ ■ □ □ ■ ■ ■ □ ■ ■ □ □ ■
Di  □ □ ■ □ □ □ ■ □ □ ■ □ □ □ □ ■ □
Mi  □ ■ □ □ □ ■ □ □ ■ □ □ □ ■ □ □ □
Do  ■ □ □ ■ □ □ □ ■ ■ □ □ ■ □ □ □ ■
Fr  □ □ ■ □ □ □ ■ □ □ ■ □ □ □ □ ■ □
Sa  ■ ■ □ ■ ■ ■ □ ■ ■ ■ ■ □ ■ ■ □ ■
So  ■ □ □ ■ □ ■ □ ■ □ ■ □ □ ■ □ □ □
```

- **Zeilen:** Wochentage (Mo–So)
- **Spalten:** Kalenderwochen
- **Farbe:** Grün mit 4 Intensitätsstufen + Grau für "kein Eintrag"
- **Monats-Labels** oben
- **Scrollbar:** Horizontal scrollbar wenn viele Wochen

### Farb-Schema (Dark Mode optimiert)

| Stufe | Bedeutung | Farbe |
|-------|-----------|-------|
| 0 | Kein Eintrag | `Color.secondary.opacity(0.1)` (dunkelgrau) |
| 1 | Kurze Session | `Color.green.opacity(0.25)` |
| 2 | Mittel | `Color.green.opacity(0.50)` |
| 3 | Lang | `Color.green.opacity(0.75)` |
| 4 | Sehr lang | `Color.green.opacity(1.0)` |

### Interaktion

- **Hover:** Tooltip zeigt Datum + Textlänge + kurze Vorschau
- **Klick:** Navigiert zur Session (oder zeigt Session-Detail popover)

### Legende

Unter dem Grid: `Weniger ░▒▓█ Mehr` — wie bei GitHub

### Zeitraum

- Standard: Letztes Jahr (52 Wochen) oder gesamter Spielzeitraum
- Quadratgröße: ~12x12pt mit 2pt Abstand

## Implementierungsschritte

### 1. HeatmapData erstellen
- **Datei:** `Services/HeatmapData.swift` (neu)
- Sammelt alle Sessions, berechnet Textlängen
- Generiert Kalender-Grid mit Intensitätsstufen
- Bestimmt Zeitraum (erstes bis letztes Datum, aufgefüllt auf volle Wochen)

### 2. HeatmapView erstellen
- **Datei:** `Views/HeatmapView.swift` (neu)
- `LazyHGrid` mit 7 Zeilen (Wochentage)
- Farbige `RoundedRectangle` pro Tag
- Monats-Labels am oberen Rand
- Wochentag-Labels links
- In `ScrollView(.horizontal)` eingebettet
- Legende unten

### 3. In GameDetailView einbinden
- **Datei:** `Views/GameDetailView.swift` (ändern)
- Neuen Tab "Heatmap" zum Picker hinzufügen

### 4. Tests
- **Datei:** `Tests/HeatmapDataTests.swift` (neu)
- Intensitäts-Berechnung korrekt
- Leere Tage werden korrekt eingefügt
- Randfall: nur 1 Session, Sessions am gleichen Tag
- Wochentag-Zuordnung korrekt

## Technische Hinweise

- Kein Swift Charts nötig — einfaches `LazyHGrid` reicht
- Dark Mode: Grüne Quadrate auf dunklem Hintergrund sieht gut aus
- Performance: Selbst bei 365+ Tagen nur ~365 kleine Views → kein Problem
- `Calendar.current` für Wochentag-Berechnung verwenden
