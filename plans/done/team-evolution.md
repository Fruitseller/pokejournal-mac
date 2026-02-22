# Team-Entwicklung (Pokémon Level-Chart)

**Status:** Implementiert

## Übersicht

Tab "Team-Entwicklung" in GameDetailView — ein Liniendiagramm (Swift Charts), das den Level-Verlauf aller Pokémon über alle Sessions hinweg zeigt.

## Dateien

| Datei | Typ |
|-------|-----|
| `Services/TeamEvolutionData.swift` | Datenaufbereitung |
| `Views/TeamEvolutionView.swift` | Chart + UI |
| `Views/GameDetailView.swift` | Tab hinzugefügt (tag 4) |
| `PokeJournalTests/TeamEvolutionDataTests.swift` | 16 Unit-Tests |

## Datenmodell

```swift
struct PokemonTimeline {
    let pokemonName: String
    let variant: String?
    let pokemonID: Int?           // Sprite aus Asset Catalog
    let typeColor: Color          // Linienfarbe nach Pokémon-Typ
    let segments: [TimelineSegment]  // Unterbrechungen bei Team-Wechseln
    let firstAppearance: Date
    let lastAppearance: Date
}
```

**Segmentierung:** Pokémon, das in einer Session fehlt → Linie wird unterbrochen. Rückkehr startet ein neues Segment (gleiche Farbe, keine Verbindung).

**Datenquelle:** `Game.sessions` + `Game.oldSessions`, gefiltert auf Sessions mit Team, chronologisch sortiert.

## Features

### Chart
- **Swift Charts** mit `LineMark` + `PointMark` pro Segment
- **Stufenlinien** (`.stepEnd`) — Level steigt in rechten Winkeln, passend zur Spielmechanik
- **Typ-Farben** für Linien via `PokemonTypeColor.color(for:)`
- **Y-Achse:** 0–100 (Level), **X-Achse:** Datum

### Zoom
- **Pinch to Zoom** auf Trackpad (`MagnifyGesture`, 100%–500%)
- **Zoom-Buttons** (+/−/Reset) oben rechts
- Chart in `ScrollView([.horizontal, .vertical])` — scrollbar bei Zoom

### Hover-Tooltip
- `chartOverlay` mit `onContinuousHover` — findet nächsten Datenpunkt oder interpoliert Linie
- Tooltip zeigt: Sprite (32x32), Name, Level, Datum
- Gestrichelte `RuleMark` am Hover-X

### Highlight & Pinning
- **Hover:** Gehoverte Linie wird hervorgehoben (4px, volle Opacity), Rest dimmt auf 12%
- **Klick im Chart:** Pinnt eine Linie — bleibt hervorgehoben auch ohne Hover. Erneuter Klick oder Klick auf leere Fläche löst Pin.
- Pin-State wird in Chart und Legende reflektiert (Pin-Icon, stärkerer Rahmen)

### Sprites am Linienende
- 20x20 Sprite am letzten Datenpunkt jeder sichtbaren Linie
- Reagiert auf Highlight-State (dimmt mit)

### Filter (Legende + Filter-Bar)
- **Legende:** Klick auf Pokémon togglet Sichtbarkeit (ein/aus)
- **Hover über Legende:** Hebt zugehörige Linie im Chart hervor (nur wenn nichts gepinnt)
- **Filter-Bar:** Quick-Filter "Alle anzeigen", "Aktuelles Team", "Keine" + Zähler (z.B. "6/58 sichtbar")

## Tests (16 Tests)

### Segment-Logik (6 Tests, pure Logic ohne SwiftData)
- Kontinuierliche Präsenz → 1 Segment
- Lücke in der Mitte → 2 Segmente
- Einzelne Appearance → 1 Segment
- Leere Appearances → 0 Segmente
- Mehrfache Lücken → 3 Segmente
- Konsekutive Indices → keine falsche Lücke

### Pipeline (10 Tests, mit SwiftData)
- Leeres Game → keine Timelines
- Sessions ohne Team → keine Timelines
- Einzelne Session → ein Datenpunkt pro Pokémon
- Level-Progression über Sessions
- Team-Wechsel erzeugt Segment-Lücke
- Kombiniert Session + OldSession
- Varianten-Pokémon separat getrackt
- Sortierung nach erstem Erscheinen
- Gemischte Sessions (mit/ohne Team) → keine falsche Lücke
- `allSessionsSorted` filtert und sortiert korrekt
