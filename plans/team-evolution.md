# PLAN: Team-Entwicklung (Pokémon Level-Chart)

## Ziel

Ein neuer Tab "Team-Entwicklung" in GameDetailView, der ein Liniendiagramm zeigt:
- **X-Achse:** Session-Daten (Zeitverlauf)
- **Y-Achse:** Pokémon-Level (0–100)
- Jedes Pokémon im Team bekommt eine eigene farbige Linie
- Sprites erscheinen an der jeweiligen Linie
- Man erkennt auf einen Blick: Wann kam ein Pokémon ins Team, wann ging es, wie haben sich die Level entwickelt?

## Datengrundlage

Bereits vorhanden — keine Modelländerungen nötig:
- `Game.sessions` + `Game.oldSessions` → nach Datum sortieren
- Jede Session hat `team: [TeamMember]` mit `pokemonName`, `level`, `variant`
- `PokemonDatabase.shared.find(byName:)` für Sprites und Typ-Farben

## Datenaufbereitung

Neues ViewModel/Helper, z.B. `TeamEvolutionData`:

```
struct PokemonTimeline {
    let pokemonName: String       // display name
    let variant: String?
    let pokemonID: Int?           // für Sprite aus Asset Catalog
    let typeColor: Color          // Linienfarbe basierend auf Pokémon-Typ
    let dataPoints: [(date: Date, level: Int)]  // Sortiert nach Datum
    let firstAppearance: Date
    let lastAppearance: Date
}
```

**Logik:**
1. Alle Sessions (Session + OldSession) nach Datum sortieren
2. Für jede Session: TeamMembers durchgehen
3. Pro Pokémon (identifiziert über `displayName`): Datenpunkte (Datum, Level) sammeln
4. `firstAppearance` / `lastAppearance` bestimmen
5. Pokémon, die in einer Session fehlen aber später wiederkommen: Linie unterbrechen (gestrichelt oder gar nicht zeichnen)

## UI-Design

### Chart-Bereich (Swift Charts)

```
┌─────────────────────────────────────────────────────┐
│ 100 ─┤                                              │
│      │                              🔥 ── ── ── 97 │
│  80 ─┤               ⚡─────────────────────── 96   │
│      │        🐉──────────────────────────── 87     │
│  60 ─┤   💀───────────────── 41                     │
│      │  🌊────────────── 84                         │
│  40 ─┤ 🌸──────── 85                                │
│      │                                              │
│  20 ─┤                                              │
│      │                                              │
│   0 ─┼──────────────────────────────────────────────│
│      Dez 23   Jan 24    Feb 24    Mär 24            │
└─────────────────────────────────────────────────────┘
        ● Libelldra  ● Bailonda  ● Azugladis
        ● Skelokrok  ● Donarion  ● Kapilz
```

- **Linien:** Farbig nach Pokémon-Typ (z.B. Feuer=rot, Wasser=blau)
- **Sprites:** Kleine Sprite-Icons (20x20) am Ende jeder Linie oder bei erstem/letztem Datenpunkt
- **Legende:** Unter dem Chart mit farbigen Punkten + Namen
- **Interaktion:** Hover/Tap zeigt Tooltip mit genauem Level + Datum

### Verhalten bei Team-Wechseln

- Pokémon, das in Session N da ist, aber in Session N+1 fehlt: Linie endet
- Pokémon kehrt zurück: neue Linie beginnt (gleiche Farbe, kein Verbindungsstrich)
- Alternativ: gestrichelte Linie in der Abwesenheitszeit (dezent, grau)

## Implementierungsschritte

### 1. TeamEvolutionData erstellen
- **Datei:** `Services/TeamEvolutionData.swift` (neu)
- Datenaufbereitung wie oben beschrieben
- Reine Logik, gut testbar

### 2. TeamEvolutionView erstellen
- **Datei:** `Views/TeamEvolutionView.swift` (neu)
- Swift Charts Framework (`import Charts`)
- `Chart { ForEach(pokemonTimelines) { LineMark(...) } }`
- `chartOverlay` für Sprite-Annotations
- Legende unten

### 3. In GameDetailView einbinden
- **Datei:** `Views/GameDetailView.swift` (ändern)
- Neuen Tab "Team-Entwicklung" zum Picker hinzufügen
- `case teamEvolution` zum Tab-Enum

### 4. Tests
- **Datei:** `Tests/TeamEvolutionDataTests.swift` (neu)
- Team-Wechsel korrekt erkannt
- Datenpunkte korrekt sortiert
- Pokémon-Identifikation über displayName
- Leere Sessions / Sessions ohne Team

## Technische Hinweise

- **Swift Charts** ist bereits als Apple-Framework verfügbar (macOS 14+), keine externe Dependency
- **Sprites** aus Asset Catalog laden via `PokemonSpriteView` (existiert bereits)
- **Typ-Farben** existieren bereits in `PokemonSpriteView.typeColor(for:)`
- Für die Annotation von Sprites auf dem Chart: `AnnotationMark` oder `chartOverlay` mit manueller Positionierung
