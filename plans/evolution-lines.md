# Entwicklungslinien als Einheit behandeln

**Status:** Geplant

## Übersicht

Bisher wird jedes Pokemon (Glumanda, Glutexo, Glurak) als eigenständig behandelt. Die Entwicklungslinie soll als Einheit gelten:
- **Team-Analyse**: Glumanda + Glutexo + Glurak zusammen zählen
- **Team-Entwicklung (Level-Chart)**: Linie geht weiter wenn sich ein Pokemon entwickelt
- **Session-Detail**: Entwicklung als "Entwickelt" anzeigen statt "Neu"/"Entfernt"

## Ansatz

PokéAPI's `pokemon_species.csv` enthält `evolution_chain_id` — alle Pokemon derselben Entwicklungslinie teilen die gleiche ID. Dieses Feld wird in `pokemon.json` aufgenommen und als Gruppierungsschlüssel verwendet.

## Dateien

| Datei | Änderung |
|-------|----------|
| `scripts/fetch_pokemon_data.py` | `pokemon_species.csv` laden, `evolution_chain_id` in JSON |
| `Models/Pokemon.swift` | Struct-Feld + DB-Methoden (`evolutionLine`, `sameEvolutionLine`) |
| `Services/TeamEvolutionData.swift` | Gruppierung nach Entwicklungslinie statt `displayName` |
| `Views/TeamEvolutionView.swift` | Tooltip mit per-Punkt Pokemon-Name, Legende |
| `Views/SessionDetailView.swift` | `TeamDiff` erkennt Entwicklungen, "Entwickelt"-Badge |
| `Views/TeamAnalysisView.swift` | Aggregation nach Entwicklungslinie |
| `PokeJournalTests/Poke_JournalTests.swift` | Evolution-Line-Tests |
| `PokeJournalTests/TeamEvolutionDataTests.swift` | Merged-Timeline-Tests |

## Änderungen

### 1. Python-Script (`scripts/fetch_pokemon_data.py`)

- `pokemon_species.csv` zusätzlich laden (1 neuer CSV-Fetch)
- Daraus `evolution_chain_id` pro Pokemon extrahieren (Schlüssel: `species_id`)
- Neues Feld `"evolution_chain_id"` in die JSON-Ausgabe aufnehmen

### 2. Pokemon-Struct + PokemonDatabase (`Models/Pokemon.swift`)

**Pokemon struct** — neues optionales Feld:
```swift
let evolutionChainID: Int?  // CodingKey: "evolution_chain_id"
```

**PokemonDatabase** — neue Datenstruktur + Methoden:
- `chainLookup: [Int: [Pokemon]]` — Chain-ID -> sortierte Members (nach Pokemon-ID)
- `evolutionLine(for: Pokemon) -> [Pokemon]` — alle Pokemon der Linie
- `sameEvolutionLine(_ name1: String, _ name2: String) -> Bool` — Hilfsfunktion

### 3. TeamEvolutionDataBuilder (`Services/TeamEvolutionData.swift`)

Kernänderung: Gruppierung nach Entwicklungslinie statt `displayName`.

- Gruppierungsschlüssel = Base-Form-Name der Linie (oder `displayName` als Fallback)
- Glumanda Session 1 + Glutexo Session 2 = selbe Timeline, keine Unterbrechung
- `PokemonTimeline.pokemonName`/`pokemonID` = **zuletzt gesehene Form**
- Varianten-Pokemon (z.B. "Alola Raichu") bleiben separat

**DataPoint erweitern** um per-Punkt Pokemon-Identity:
```swift
struct DataPoint {
    let date: Date
    let level: Int
    let pokemonName: String?  // Name zum Zeitpunkt
    let pokemonID: Int?       // Sprite-ID zum Zeitpunkt
}
```

### 4. TeamEvolutionView (`Views/TeamEvolutionView.swift`)

- **Tooltip**: Pokemon-Name des jeweiligen Datenpunkts
- **Legende**: Aktuellster Name + Sprite der Linie
- **"Aktuelles Team"-Filter**: Matcht über Entwicklungslinien

### 5. SessionDetailView (`Views/SessionDetailView.swift`)

**`TeamDiff` erweitern:**
```swift
struct Evolution {
    let from: TeamMember    // Glumanda lvl 15 (vorherige Session)
    let to: TeamMember      // Glutexo lvl 25 (aktuelle Session)
    let levelDelta: Int     // +10
}
var evolutions: [Evolution]
```

**`teamDiff()` Logik:**
1. `added`/`removed` berechnen
2. Paare (added, removed) prüfen ob `sameEvolutionLine`
3. Match -> aus `added`/`removed` entfernen, als `Evolution` erfassen

**UI:** "Entwickelt"-Badge (lila Capsule) statt "Neu", Vorstufe nicht als "Entfernt"

### 6. TeamAnalysisView (`Views/TeamAnalysisView.swift`)

- Gruppierung nach Entwicklungslinie statt `displayName`
- Pro Session: Linie maximal 1x zählen (Deduplizierung)
- Anzeigename + Sprite = höchste gesehene Entwicklungsstufe

### 7. Tests

- Evolution-Line-Lookup (vollständige Kette, single-stage, sameEvolutionLine)
- Merged Timelines (Glumanda->Glutexo = 1 Timeline)
- TeamDiff Evolution-Erkennung
- Bestehende Tests weiterhin grün

## Edge Case: Eevee

Eevee hat 8+ Entwicklungen mit gleicher `evolution_chain_id`. Für Team-Analyse passt die Gruppierung. Für das Level-Chart in der Praxis selten problematisch. Falls nötig: Follow-up mit `evolves_from_species_id`.
