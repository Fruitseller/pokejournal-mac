# Typ-Matchup-Rechner

## Kontext

Die App trackt Pokémon-Teams pro Session, analysiert aber nicht die Typ-Effektivität. Ein Matchup-Rechner zeigt Schwächen und Stärken des aktuellen Teams — mit generationsabhängigem Type Chart (Gen 1, Gen 2–5, Gen 6+).

## Architektur

### Neue Dateien

1. **`Services/TypeChart.swift`** — Reine Logik, kein UI:
   - `TypeChartGeneration` Enum (`.gen1`, `.gen2to5`, `.gen6plus`)
   - Statische Effektivitäts-Matrix pro Generation (Gen 1: 15 Typen, Gen 2–5: 17, Gen 6+: 18)
   - `TypeChart.effectiveness(attacker:defender:generation:) -> Double`
   - `TypeChart.teamDefensiveProfile(types:generation:) -> [String: Double]` — pro Angriffs-Typ der schlimmste Multiplikator übers Team
   - `TypeChart.coverageGaps(teamTypes:generation:) -> [String]` — Angriffs-Typen die kein Team-Mitglied superstark trifft
   - `TypeChart.recommendation(teamTypes:generation:) -> [String]` — Typen die die meisten Lücken füllen

2. **`Views/TypeMatchupView.swift`** — Sheet-UI:
   - Header: Spielname + erkannte Generation als Badge
   - **Defensiv-Übersicht**: Grid aller Angriffs-Typen, farbkodiert (rot = schwach, grün = resistent, grau = neutral). Zeigt Multiplikator und betroffene Team-Mitglieder
   - **Abdeckungs-Lücken**: Welche Typen kann das Team nicht superstark treffen?
   - **Empfehlung**: "Ein Wasser-Pokémon würde 3 Schwächen abdecken"

3. **`Tests/TypeChartTests.swift`** — Unit-Tests für:
   - Alle 5 historischen Matchup-Änderungen
   - Dual-Type-Berechnungen (z.B. Feuer/Flug vs Gestein = 4x)
   - Team-Defensivprofil-Aggregation
   - Abdeckungs-Lücken-Erkennung

### Geänderte Dateien

4. **`Models/Game.swift`** — Computed Property `generation: TypeChartGeneration`:
   - `< 2000` → `.gen1`
   - `2000–2013` → `.gen2to5`
   - `>= 2013` → `.gen6plus`
   - Remakes nutzen zeitgenössische Mechaniken → Release-Datum funktioniert korrekt
   - Bei fehlendem `releaseDate` → Default `.gen6plus`

5. **`Views/GameDetailView.swift`** — Button in `CurrentTeamView` öffnet Matchup-Sheet

### Type Chart Unterschiede

**Gen 1 (15 Typen, kein Unlicht/Stahl/Fee):**
- Geist → Psycho: **0x** (Bug im Originalspiel)
- Gift → Käfer: **2x**, Käfer → Gift: **2x**

**Gen 2–5 (17 Typen, +Unlicht/Stahl):**
- Geist → Psycho: **2x** (gefixt)
- Gift → Käfer: **1x**, Käfer → Gift: **1x** (generft)
- Geist → Stahl: **0.5x**, Unlicht → Stahl: **0.5x**

**Gen 6+ (18 Typen, +Fee):**
- Geist → Stahl: **1x**, Unlicht → Stahl: **1x** (Stahl verliert Resistenz)
- Komplette Fee-Zeile/Spalte hinzugefügt

### Dual-Type-Berechnung

Defensiv-Multiplikator gegen Angreifer-Typ X bei Pokémon mit Typen [A, B]:
`effectiveness(X → A) × effectiveness(X → B)` → ergibt 0x, 0.25x, 0.5x, 1x, 2x, 4x

### Wiederverwendete Komponenten

- `PokemonDatabase.shared.find(byName:)?.types` — Typen auflösen
- `PokemonTypeColor.color(for:)` — Typ-Farben
- `PokemonSpriteView` — Sprite-Anzeige
- `StatCard` — Zusammenfassungs-Karten
- `.sheet()` Pattern aus ContentView

## Implementierungs-Reihenfolge

1. `TypeChart.swift` + `TypeChartTests.swift` — TDD, Logik zuerst
2. `Game.generation` Computed Property
3. `TypeMatchupView.swift` — UI bauen
4. Button in `CurrentTeamView` verdrahten
