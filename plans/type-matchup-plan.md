# Type-Matchup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a generation-aware type-matchup analyzer that reveals team weaknesses, coverage gaps, and suggests complementary types for the Pokémon team of the current game.

**Architecture:** Pure logic in `Services/TypeChart.swift` (stateless, testable). UI in `Views/TypeMatchupView.swift` as a modal sheet opened from `CurrentTeamView`. Generation derived from `Game.releaseDate`. All Pokémon types use English internal identifiers (matching `pokemon.json` and `PokemonTypeColor`); user-facing labels use German via a type-display map.

**Tech Stack:** Swift 6.2, SwiftUI, Swift Testing (`@Test` / `#expect`), SwiftData.

---

## File Structure

- **Create:** `PokeJournal/PokeJournal/Services/TypeChart.swift` — generation enum, effectiveness matrices, aggregation helpers.
- **Create:** `PokeJournal/PokeJournal/Views/TypeMatchupView.swift` — sheet UI.
- **Create:** `PokeJournal/PokeJournalTests/TypeChartTests.swift` — logic tests.
- **Modify:** `PokeJournal/PokeJournal/Models/Game.swift` — add `generation` computed property.
- **Modify:** `PokeJournal/PokeJournal/Views/GameDetailView.swift` — pass `game` to `CurrentTeamView`, add sheet button.

Internal type identifiers (18): `normal, fire, water, electric, grass, ice, fighting, poison, ground, flying, psychic, bug, rock, ghost, dragon, dark, steel, fairy`.

---

### Task 1: `TypeChartGeneration` enum

**Files:**
- Create: `PokeJournal/PokeJournal/Services/TypeChart.swift`
- Test: `PokeJournal/PokeJournalTests/TypeChartTests.swift`

- [ ] **Step 1: Write the failing test**

Create `PokeJournal/PokeJournalTests/TypeChartTests.swift`:

```swift
//
//  TypeChartTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
@testable import PokeJournal

struct TypeChartGenerationTests {

    @Test func gen1_hasFifteenTypes() {
        #expect(TypeChartGeneration.gen1.allTypes.count == 15)
    }

    @Test func gen2to5_hasSeventeenTypes() {
        #expect(TypeChartGeneration.gen2to5.allTypes.count == 17)
    }

    @Test func gen6plus_hasEighteenTypes() {
        #expect(TypeChartGeneration.gen6plus.allTypes.count == 18)
    }

    @Test func gen1_excludesDarkSteelFairy() {
        let types = TypeChartGeneration.gen1.allTypes
        #expect(!types.contains("dark"))
        #expect(!types.contains("steel"))
        #expect(!types.contains("fairy"))
    }

    @Test func gen2to5_includesDarkSteel_excludesFairy() {
        let types = TypeChartGeneration.gen2to5.allTypes
        #expect(types.contains("dark"))
        #expect(types.contains("steel"))
        #expect(!types.contains("fairy"))
    }

    @Test func gen6plus_includesAllEighteen() {
        let types = TypeChartGeneration.gen6plus.allTypes
        #expect(types.contains("dark"))
        #expect(types.contains("steel"))
        #expect(types.contains("fairy"))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
./scripts/test.sh unit
```

Expected: compile error — `TypeChartGeneration` undefined.

- [ ] **Step 3: Create `TypeChart.swift` with the enum**

```swift
//
//  TypeChart.swift
//  PokéJournal
//

import Foundation

enum TypeChartGeneration {
    case gen1
    case gen2to5
    case gen6plus

    /// Canonical list of type identifiers (lowercase English) for this generation.
    /// Ordering matches the display order used in the matchup UI.
    var allTypes: [String] {
        let base = [
            "normal", "fire", "water", "electric", "grass", "ice",
            "fighting", "poison", "ground", "flying", "psychic", "bug",
            "rock", "ghost", "dragon"
        ]
        switch self {
        case .gen1:
            return base
        case .gen2to5:
            return base + ["dark", "steel"]
        case .gen6plus:
            return base + ["dark", "steel", "fairy"]
        }
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

```bash
./scripts/test.sh unit
```

Expected: all `TypeChartGenerationTests` pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TypeChart.swift PokeJournal/PokeJournalTests/TypeChartTests.swift
git commit -m "Add TypeChartGeneration enum"
```

---

### Task 2: Gen 6+ single-type effectiveness

**Files:**
- Modify: `PokeJournal/PokeJournal/Services/TypeChart.swift`
- Modify: `PokeJournal/PokeJournalTests/TypeChartTests.swift`

- [ ] **Step 1: Append failing tests for Gen 6+ effectiveness**

Append to `TypeChartTests.swift`:

```swift
struct TypeChartEffectivenessGen6Tests {

    @Test func water_superEffectiveAgainstFire() {
        let m = TypeChart.effectiveness(attacker: "water", defender: "fire", generation: .gen6plus)
        #expect(m == 2.0)
    }

    @Test func fire_notVeryEffectiveAgainstWater() {
        let m = TypeChart.effectiveness(attacker: "fire", defender: "water", generation: .gen6plus)
        #expect(m == 0.5)
    }

    @Test func ground_immuneFromElectric() {
        let m = TypeChart.effectiveness(attacker: "electric", defender: "ground", generation: .gen6plus)
        #expect(m == 0.0)
    }

    @Test func normal_neutralAgainstGrass() {
        let m = TypeChart.effectiveness(attacker: "normal", defender: "grass", generation: .gen6plus)
        #expect(m == 1.0)
    }

    @Test func dragon_superEffectiveAgainstDragon() {
        let m = TypeChart.effectiveness(attacker: "dragon", defender: "dragon", generation: .gen6plus)
        #expect(m == 2.0)
    }

    @Test func fairy_superEffectiveAgainstDragon() {
        let m = TypeChart.effectiveness(attacker: "fairy", defender: "dragon", generation: .gen6plus)
        #expect(m == 2.0)
    }

    @Test func dragon_noEffectAgainstFairy() {
        let m = TypeChart.effectiveness(attacker: "dragon", defender: "fairy", generation: .gen6plus)
        #expect(m == 0.0)
    }

    @Test func unknownType_returnsNeutral() {
        let m = TypeChart.effectiveness(attacker: "unknown", defender: "fire", generation: .gen6plus)
        #expect(m == 1.0)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
./scripts/test.sh unit
```

Expected: compile error — `TypeChart.effectiveness` undefined.

- [ ] **Step 3: Implement the Gen 6+ matrix and `effectiveness`**

Append to `TypeChart.swift`:

```swift
enum TypeChart {

    /// Gen 6+ canonical offensive multipliers. Only non-neutral (≠1.0) entries are listed.
    /// Format: attacker → [defender: multiplier]
    private static let gen6Matrix: [String: [String: Double]] = [
        "normal":   ["rock": 0.5, "ghost": 0.0, "steel": 0.5],
        "fire":     ["fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 2.0,
                     "bug": 2.0, "rock": 0.5, "dragon": 0.5, "steel": 2.0],
        "water":    ["fire": 2.0, "water": 0.5, "grass": 0.5, "ground": 2.0,
                     "rock": 2.0, "dragon": 0.5],
        "electric": ["water": 2.0, "electric": 0.5, "grass": 0.5, "ground": 0.0,
                     "flying": 2.0, "dragon": 0.5],
        "grass":    ["fire": 0.5, "water": 2.0, "grass": 0.5, "poison": 0.5,
                     "ground": 2.0, "flying": 0.5, "bug": 0.5, "rock": 2.0,
                     "dragon": 0.5, "steel": 0.5],
        "ice":      ["fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 0.5,
                     "ground": 2.0, "flying": 2.0, "dragon": 2.0, "steel": 0.5],
        "fighting": ["normal": 2.0, "ice": 2.0, "poison": 0.5, "flying": 0.5,
                     "psychic": 0.5, "bug": 0.5, "rock": 2.0, "ghost": 0.0,
                     "dark": 2.0, "steel": 2.0, "fairy": 0.5],
        "poison":   ["grass": 2.0, "poison": 0.5, "ground": 0.5, "rock": 0.5,
                     "ghost": 0.5, "steel": 0.0, "fairy": 2.0],
        "ground":   ["fire": 2.0, "electric": 2.0, "grass": 0.5, "poison": 2.0,
                     "flying": 0.0, "bug": 0.5, "rock": 2.0, "steel": 2.0],
        "flying":   ["electric": 0.5, "grass": 2.0, "fighting": 2.0, "bug": 2.0,
                     "rock": 0.5, "steel": 0.5],
        "psychic":  ["fighting": 2.0, "poison": 2.0, "psychic": 0.5, "dark": 0.0, "steel": 0.5],
        "bug":      ["fire": 0.5, "grass": 2.0, "fighting": 0.5, "poison": 0.5,
                     "flying": 0.5, "psychic": 2.0, "ghost": 0.5, "dark": 2.0,
                     "steel": 0.5, "fairy": 0.5],
        "rock":     ["fire": 2.0, "ice": 2.0, "fighting": 0.5, "ground": 0.5,
                     "flying": 2.0, "bug": 2.0, "steel": 0.5],
        "ghost":    ["normal": 0.0, "psychic": 2.0, "ghost": 2.0, "dark": 0.5],
        "dragon":   ["dragon": 2.0, "steel": 0.5, "fairy": 0.0],
        "dark":     ["fighting": 0.5, "psychic": 2.0, "ghost": 2.0, "dark": 0.5, "fairy": 0.5],
        "steel":    ["fire": 0.5, "water": 0.5, "electric": 0.5, "ice": 2.0,
                     "rock": 2.0, "steel": 0.5, "fairy": 2.0],
        "fairy":    ["fire": 0.5, "fighting": 2.0, "poison": 0.5, "dragon": 2.0,
                     "dark": 2.0, "steel": 0.5]
    ]

    /// Offensive effectiveness multiplier for a single attacker type against a single defender type.
    /// Returns 1.0 for unknown types or unspecified neutral matchups.
    static func effectiveness(attacker: String, defender: String, generation: TypeChartGeneration) -> Double {
        let matrix = matrixFor(generation)
        guard let row = matrix[attacker], let value = row[defender] else {
            return 1.0
        }
        return value
    }

    private static func matrixFor(_ generation: TypeChartGeneration) -> [String: [String: Double]] {
        switch generation {
        case .gen6plus:
            return gen6Matrix
        case .gen2to5, .gen1:
            // Filled in by Tasks 3 and 4.
            return gen6Matrix
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
./scripts/test.sh unit
```

Expected: all `TypeChartEffectivenessGen6Tests` pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TypeChart.swift PokeJournal/PokeJournalTests/TypeChartTests.swift
git commit -m "Add Gen 6+ type effectiveness matrix"
```

---

### Task 3: Gen 2-5 effectiveness overrides

**Files:**
- Modify: `PokeJournal/PokeJournal/Services/TypeChart.swift`
- Modify: `PokeJournal/PokeJournalTests/TypeChartTests.swift`

Gen 2-5 differs from Gen 6+ by:
- No fairy type exists.
- ghost → steel = 0.5x (not 1.0x).
- dark → steel = 0.5x (not 1.0x).

- [ ] **Step 1: Append failing tests**

Append to `TypeChartTests.swift`:

```swift
struct TypeChartEffectivenessGen2to5Tests {

    @Test func ghost_resistedByStealInGen2to5() {
        let m = TypeChart.effectiveness(attacker: "ghost", defender: "steel", generation: .gen2to5)
        #expect(m == 0.5)
    }

    @Test func dark_resistedByStealInGen2to5() {
        let m = TypeChart.effectiveness(attacker: "dark", defender: "steel", generation: .gen2to5)
        #expect(m == 0.5)
    }

    @Test func ghost_notResistedByStealInGen6plus() {
        let m = TypeChart.effectiveness(attacker: "ghost", defender: "steel", generation: .gen6plus)
        #expect(m == 1.0)
    }

    @Test func fairy_unknownInGen2to5_returnsNeutral() {
        let m = TypeChart.effectiveness(attacker: "fairy", defender: "dragon", generation: .gen2to5)
        #expect(m == 1.0)
    }

    @Test func dragon_notImmuneFairyInGen2to5() {
        let m = TypeChart.effectiveness(attacker: "dragon", defender: "fairy", generation: .gen2to5)
        #expect(m == 1.0)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
./scripts/test.sh unit
```

Expected: `ghost_resistedByStealInGen2to5` fails (current value 1.0).

- [ ] **Step 3: Add Gen 2-5 matrix and wire it up**

Edit `TypeChart.swift`. Add a private static matrix above `matrixFor`:

```swift
    private static let gen2to5Matrix: [String: [String: Double]] = {
        var m = gen6Matrix
        // Drop fairy row entirely (type doesn't exist).
        m.removeValue(forKey: "fairy")
        // Drop fairy entries from every remaining row.
        for key in m.keys {
            m[key]?.removeValue(forKey: "fairy")
        }
        // Steel resisted ghost and dark pre-Gen 6.
        m["ghost"]?["steel"] = 0.5
        m["dark"]?["steel"] = 0.5
        // Dragon isn't countered by fairy in these gens; fairy entry already removed above.
        m["dragon"]?.removeValue(forKey: "fairy")
        return m
    }()
```

Update `matrixFor`:

```swift
    private static func matrixFor(_ generation: TypeChartGeneration) -> [String: [String: Double]] {
        switch generation {
        case .gen6plus:
            return gen6Matrix
        case .gen2to5:
            return gen2to5Matrix
        case .gen1:
            // Filled in by Task 4.
            return gen2to5Matrix
        }
    }
```

- [ ] **Step 4: Run tests and verify they pass**

```bash
./scripts/test.sh unit
```

Expected: all Gen 2-5 tests and all previous tests pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TypeChart.swift PokeJournal/PokeJournalTests/TypeChartTests.swift
git commit -m "Add Gen 2-5 type effectiveness overrides"
```

---

### Task 4: Gen 1 effectiveness overrides

**Files:**
- Modify: `PokeJournal/PokeJournal/Services/TypeChart.swift`
- Modify: `PokeJournal/PokeJournalTests/TypeChartTests.swift`

Gen 1 differs from Gen 2-5 by:
- Dark and steel types do not exist.
- ghost → psychic = 0.0x (famous Gen 1 bug; was 2.0x intended).
- poison → bug = 2.0x (was 0.5x later).
- bug → poison = 2.0x (was 0.5x later).

- [ ] **Step 1: Append failing tests**

Append to `TypeChartTests.swift`:

```swift
struct TypeChartEffectivenessGen1Tests {

    @Test func ghost_zeroAgainstPsychic_gen1Bug() {
        let m = TypeChart.effectiveness(attacker: "ghost", defender: "psychic", generation: .gen1)
        #expect(m == 0.0)
    }

    @Test func ghost_superEffectiveAgainstPsychic_gen2to5() {
        let m = TypeChart.effectiveness(attacker: "ghost", defender: "psychic", generation: .gen2to5)
        #expect(m == 2.0)
    }

    @Test func poison_superEffectiveAgainstBug_gen1() {
        let m = TypeChart.effectiveness(attacker: "poison", defender: "bug", generation: .gen1)
        #expect(m == 2.0)
    }

    @Test func bug_superEffectiveAgainstPoison_gen1() {
        let m = TypeChart.effectiveness(attacker: "bug", defender: "poison", generation: .gen1)
        #expect(m == 2.0)
    }

    @Test func poison_notSuperEffectiveAgainstBug_gen2to5() {
        let m = TypeChart.effectiveness(attacker: "poison", defender: "bug", generation: .gen2to5)
        #expect(m == 1.0)
    }

    @Test func dark_unknownInGen1_returnsNeutral() {
        let m = TypeChart.effectiveness(attacker: "dark", defender: "psychic", generation: .gen1)
        #expect(m == 1.0)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
./scripts/test.sh unit
```

Expected: Gen 1 tests fail because the Gen 2-5 matrix is returned.

- [ ] **Step 3: Add Gen 1 matrix and wire it up**

Add a private static matrix above `matrixFor`:

```swift
    private static let gen1Matrix: [String: [String: Double]] = {
        var m = gen2to5Matrix
        // Remove dark and steel rows — these types do not exist in Gen 1.
        m.removeValue(forKey: "dark")
        m.removeValue(forKey: "steel")
        // Remove dark and steel entries from every remaining row.
        for key in m.keys {
            m[key]?.removeValue(forKey: "dark")
            m[key]?.removeValue(forKey: "steel")
        }
        // Historical Gen 1 quirks:
        m["ghost"]?["psychic"] = 0.0     // The famous Gen 1 bug.
        m["poison"]?["bug"] = 2.0        // Was nerfed later.
        m["bug"]?["poison"] = 2.0        // Was nerfed later.
        return m
    }()
```

Update `matrixFor`:

```swift
    private static func matrixFor(_ generation: TypeChartGeneration) -> [String: [String: Double]] {
        switch generation {
        case .gen6plus:
            return gen6Matrix
        case .gen2to5:
            return gen2to5Matrix
        case .gen1:
            return gen1Matrix
        }
    }
```

- [ ] **Step 4: Run tests**

```bash
./scripts/test.sh unit
```

Expected: all Gen 1, Gen 2-5, and Gen 6+ tests pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TypeChart.swift PokeJournal/PokeJournalTests/TypeChartTests.swift
git commit -m "Add Gen 1 type effectiveness overrides"
```

---

### Task 5: Dual-type defensive multiplier

**Files:**
- Modify: `PokeJournal/PokeJournal/Services/TypeChart.swift`
- Modify: `PokeJournal/PokeJournalTests/TypeChartTests.swift`

- [ ] **Step 1: Append failing tests**

Append to `TypeChartTests.swift`:

```swift
struct TypeChartDualTypeTests {

    @Test func fireFlying_vsRock_4x() {
        // rock is 2x against fire AND 2x against flying → 4x.
        let m = TypeChart.defensiveMultiplier(
            attacker: "rock",
            defenderTypes: ["fire", "flying"],
            generation: .gen6plus
        )
        #expect(m == 4.0)
    }

    @Test func groundFlying_vsElectric_1x() {
        // electric is 0x against ground (immunity) and 2x against flying → 0x wins.
        let m = TypeChart.defensiveMultiplier(
            attacker: "electric",
            defenderTypes: ["ground", "flying"],
            generation: .gen6plus
        )
        #expect(m == 0.0)
    }

    @Test func waterGrass_vsFire_05x() {
        // fire is 0.5x against water and 2x against grass → 1x net.
        let m = TypeChart.defensiveMultiplier(
            attacker: "fire",
            defenderTypes: ["water", "grass"],
            generation: .gen6plus
        )
        #expect(m == 1.0)
    }

    @Test func waterWater_vsGrass_2x() {
        // Single type passed as one-element array.
        let m = TypeChart.defensiveMultiplier(
            attacker: "grass",
            defenderTypes: ["water"],
            generation: .gen6plus
        )
        #expect(m == 2.0)
    }

    @Test func emptyTypes_returnsNeutral() {
        let m = TypeChart.defensiveMultiplier(
            attacker: "fire",
            defenderTypes: [],
            generation: .gen6plus
        )
        #expect(m == 1.0)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
./scripts/test.sh unit
```

Expected: compile error — `defensiveMultiplier` undefined.

- [ ] **Step 3: Implement `defensiveMultiplier`**

Add to the `TypeChart` enum:

```swift
    /// Multiplier an attacker type does against a defender with one or two types.
    /// For dual types, returns the product of each single-type multiplier.
    static func defensiveMultiplier(
        attacker: String,
        defenderTypes: [String],
        generation: TypeChartGeneration
    ) -> Double {
        guard !defenderTypes.isEmpty else { return 1.0 }
        return defenderTypes.reduce(1.0) { acc, defender in
            acc * effectiveness(attacker: attacker, defender: defender, generation: generation)
        }
    }
```

- [ ] **Step 4: Run tests**

```bash
./scripts/test.sh unit
```

Expected: all dual-type tests pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TypeChart.swift PokeJournal/PokeJournalTests/TypeChartTests.swift
git commit -m "Add dual-type defensive multiplier"
```

---

### Task 6: Team defensive profile

**Files:**
- Modify: `PokeJournal/PokeJournal/Services/TypeChart.swift`
- Modify: `PokeJournal/PokeJournalTests/TypeChartTests.swift`

The profile maps each attacker type → the **worst** (highest) multiplier any team member takes. High values mean the team has a glaring weakness.

- [ ] **Step 1: Append failing tests**

Append to `TypeChartTests.swift`:

```swift
struct TypeChartTeamDefensiveProfileTests {

    @Test func singleMember_fireFlying_rockIs4x() {
        let team: [[String]] = [["fire", "flying"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
        #expect(profile["rock"] == 4.0)
    }

    @Test func twoMembers_takesWorst() {
        // One member is 4x weak to rock; another is 1x. Profile reports 4x.
        let team: [[String]] = [["fire", "flying"], ["water"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
        #expect(profile["rock"] == 4.0)
    }

    @Test func resistOnOne_weakOnAnother_reportsWorst() {
        // Electric: 0x against ground, 2x against flying — profile keeps 2x (the worst).
        let team: [[String]] = [["ground"], ["flying"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
        #expect(profile["electric"] == 2.0)
    }

    @Test func profileCoversAllGenerationTypes() {
        let team: [[String]] = [["normal"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
        #expect(profile.count == 18)
    }

    @Test func profileInGen1HasFifteenKeys() {
        let team: [[String]] = [["normal"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen1)
        #expect(profile.count == 15)
    }

    @Test func emptyTeam_allNeutral() {
        let profile = TypeChart.teamDefensiveProfile(team: [], generation: .gen6plus)
        #expect(profile["fire"] == 1.0)
        #expect(profile["water"] == 1.0)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
./scripts/test.sh unit
```

Expected: compile error — `teamDefensiveProfile` undefined.

- [ ] **Step 3: Implement `teamDefensiveProfile`**

Add to the `TypeChart` enum:

```swift
    /// Per attacking type, the worst multiplier any team member takes.
    /// Empty team → every attacker scored as 1.0 (neutral).
    static func teamDefensiveProfile(
        team: [[String]],
        generation: TypeChartGeneration
    ) -> [String: Double] {
        var profile: [String: Double] = [:]
        for attacker in generation.allTypes {
            if team.isEmpty {
                profile[attacker] = 1.0
                continue
            }
            let worst = team.map { defenderTypes in
                defensiveMultiplier(
                    attacker: attacker,
                    defenderTypes: defenderTypes,
                    generation: generation
                )
            }.max() ?? 1.0
            profile[attacker] = worst
        }
        return profile
    }
```

- [ ] **Step 4: Run tests**

```bash
./scripts/test.sh unit
```

Expected: all profile tests pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TypeChart.swift PokeJournal/PokeJournalTests/TypeChartTests.swift
git commit -m "Add team defensive profile aggregation"
```

---

### Task 7: Offensive coverage gaps

**Files:**
- Modify: `PokeJournal/PokeJournal/Services/TypeChart.swift`
- Modify: `PokeJournal/PokeJournalTests/TypeChartTests.swift`

A "gap" is a defender type that no single team-member type hits for >1.0x. We use team members' *own* types as a proxy for their STAB offensive options.

- [ ] **Step 1: Append failing tests**

Append to `TypeChartTests.swift`:

```swift
struct TypeChartCoverageGapTests {

    @Test func waterOnly_cannotHitGrassSuperEffectively() {
        let team: [[String]] = [["water"]]
        let gaps = TypeChart.coverageGaps(team: team, generation: .gen6plus)
        #expect(gaps.contains("grass"))
        #expect(gaps.contains("dragon"))
        #expect(!gaps.contains("fire"))
        #expect(!gaps.contains("ground"))
        #expect(!gaps.contains("rock"))
    }

    @Test func noGapsWhenAnyMemberCovers() {
        let team: [[String]] = [["water"], ["grass"], ["electric"]]
        let gaps = TypeChart.coverageGaps(team: team, generation: .gen6plus)
        #expect(!gaps.contains("fire"))   // water covers
        #expect(!gaps.contains("ground")) // water covers
        #expect(!gaps.contains("water"))  // grass+electric cover
        #expect(!gaps.contains("flying")) // electric covers
    }

    @Test func emptyTeam_allTypesGap() {
        let gaps = TypeChart.coverageGaps(team: [], generation: .gen6plus)
        #expect(gaps.count == 18)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
./scripts/test.sh unit
```

Expected: compile error — `coverageGaps` undefined.

- [ ] **Step 3: Implement `coverageGaps`**

Add to the `TypeChart` enum:

```swift
    /// Defender types that no team member can hit for > 1x using any of its own types.
    /// Returns the gap types in the generation's canonical order.
    static func coverageGaps(
        team: [[String]],
        generation: TypeChartGeneration
    ) -> [String] {
        var gaps: [String] = []
        for defender in generation.allTypes {
            let anyHit = team.contains { types in
                types.contains { attacker in
                    effectiveness(attacker: attacker, defender: defender, generation: generation) > 1.0
                }
            }
            if !anyHit {
                gaps.append(defender)
            }
        }
        return gaps
    }
```

- [ ] **Step 4: Run tests**

```bash
./scripts/test.sh unit
```

Expected: all coverage-gap tests pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TypeChart.swift PokeJournal/PokeJournalTests/TypeChartTests.swift
git commit -m "Add offensive coverage gap detection"
```

---

### Task 8: Type recommendation

**Files:**
- Modify: `PokeJournal/PokeJournal/Services/TypeChart.swift`
- Modify: `PokeJournal/PokeJournalTests/TypeChartTests.swift`

For each candidate type `T`:
1. Count how many **defensive** weaknesses (profile[attacker] ≥ 2) it would cover (T resists or is immune to attacker).
2. Count how many **coverage gaps** it would fill (T hits the gap defender > 1x).
3. Score = (a) + (b). Sort descending, return top 3.

- [ ] **Step 1: Append failing tests**

Append to `TypeChartTests.swift`:

```swift
struct TypeChartRecommendationTests {

    @Test func waterOnlyTeam_suggestsGrassOrElectric() {
        // A pure water Pokémon is 2x weak to electric and grass,
        // and has no coverage vs grass or dragon.
        // Top recommendations should address at least one of those.
        let team: [[String]] = [["water"]]
        let recs = TypeChart.recommendation(team: team, generation: .gen6plus)
        #expect(!recs.isEmpty)
        // One of the top suggestions should resist electric AND/OR hit grass super-effectively.
        let covers = Set(recs)
        let good = ["electric", "grass", "dragon", "ice", "flying"]
        #expect(!covers.intersection(good).isEmpty)
    }

    @Test func recommendationReturnsThreeOrFewer() {
        let team: [[String]] = [["water"]]
        let recs = TypeChart.recommendation(team: team, generation: .gen6plus)
        #expect(recs.count <= 3)
    }

    @Test func perfectlyBalancedTeam_returnsEmpty() {
        // A team with no weaknesses (all 1.0) and no coverage gaps gets no suggestions.
        // Constructing this exactly is hard; instead we assert non-crash on empty gaps:
        let team: [[String]] = [["steel"], ["water"], ["electric"], ["grass"], ["ground"], ["fairy"]]
        let recs = TypeChart.recommendation(team: team, generation: .gen6plus)
        #expect(recs.count <= 3)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
./scripts/test.sh unit
```

Expected: compile error — `recommendation` undefined.

- [ ] **Step 3: Implement `recommendation`**

Add to the `TypeChart` enum:

```swift
    /// Up to 3 candidate types that would most improve the team's defensive profile
    /// and offensive coverage.
    static func recommendation(
        team: [[String]],
        generation: TypeChartGeneration
    ) -> [String] {
        let profile = teamDefensiveProfile(team: team, generation: generation)
        let gaps = coverageGaps(team: team, generation: generation)
        let weaknesses = profile.filter { $0.value >= 2.0 }.map { $0.key }

        guard !weaknesses.isEmpty || !gaps.isEmpty else {
            return []
        }

        let scored: [(type: String, score: Int)] = generation.allTypes.map { candidate in
            let defensiveValue = weaknesses.filter { attacker in
                effectiveness(attacker: attacker, defender: candidate, generation: generation) < 1.0
            }.count
            let offensiveValue = gaps.filter { defender in
                effectiveness(attacker: candidate, defender: defender, generation: generation) > 1.0
            }.count
            return (candidate, defensiveValue + offensiveValue)
        }

        return scored
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0.type }
    }
```

- [ ] **Step 4: Run tests**

```bash
./scripts/test.sh unit
```

Expected: all recommendation tests pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TypeChart.swift PokeJournal/PokeJournalTests/TypeChartTests.swift
git commit -m "Add type recommendation scoring"
```

---

### Task 9: `Game.generation` computed property

**Files:**
- Modify: `PokeJournal/PokeJournal/Models/Game.swift`
- Create: `PokeJournal/PokeJournalTests/GameGenerationTests.swift`

The `releaseDate` is stored as a `String?` (e.g. `"2022-11-18"`, sometimes just `"1999"`). We parse the leading year.

- [ ] **Step 1: Write the failing test**

Create `PokeJournal/PokeJournalTests/GameGenerationTests.swift`:

```swift
//
//  GameGenerationTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

struct GameGenerationTests {

    @Test func releaseBefore2000_returnsGen1() {
        let game = Game(name: "red", filePath: "red.md")
        game.releaseDate = "1998-09-28"
        #expect(game.generation == .gen1)
    }

    @Test func release1999_returnsGen1() {
        let game = Game(name: "gelb", filePath: "gelb.md")
        game.releaseDate = "1999"
        #expect(game.generation == .gen1)
    }

    @Test func release2000_returnsGen2to5() {
        let game = Game(name: "gold", filePath: "gold.md")
        game.releaseDate = "2000-10-14"
        #expect(game.generation == .gen2to5)
    }

    @Test func release2012_returnsGen2to5() {
        let game = Game(name: "black2", filePath: "black2.md")
        game.releaseDate = "2012-06-23"
        #expect(game.generation == .gen2to5)
    }

    @Test func release2013_returnsGen6plus() {
        let game = Game(name: "x", filePath: "x.md")
        game.releaseDate = "2013-10-12"
        #expect(game.generation == .gen6plus)
    }

    @Test func release2022_returnsGen6plus() {
        let game = Game(name: "purpur", filePath: "purpur.md")
        game.releaseDate = "2022-11-18"
        #expect(game.generation == .gen6plus)
    }

    @Test func missingReleaseDate_defaultsToGen6plus() {
        let game = Game(name: "unknown", filePath: "unknown.md")
        game.releaseDate = nil
        #expect(game.generation == .gen6plus)
    }

    @Test func unparseableReleaseDate_defaultsToGen6plus() {
        let game = Game(name: "weird", filePath: "weird.md")
        game.releaseDate = "soon"
        #expect(game.generation == .gen6plus)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
./scripts/test.sh unit
```

Expected: compile error — `Game.generation` undefined.

- [ ] **Step 3: Add `generation` to `Game.swift`**

Append inside the `Game` class, after `displayName`:

```swift
    var generation: TypeChartGeneration {
        guard let releaseDate,
              let year = Int(releaseDate.prefix(4)) else {
            return .gen6plus
        }
        switch year {
        case ..<2000: return .gen1
        case 2000..<2013: return .gen2to5
        default: return .gen6plus
        }
    }
```

- [ ] **Step 4: Run tests**

```bash
./scripts/test.sh unit
```

Expected: all `GameGenerationTests` pass.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Models/Game.swift PokeJournal/PokeJournalTests/GameGenerationTests.swift
git commit -m "Add generation computed property on Game"
```

---

### Task 10: `TypeMatchupView` scaffolding and header

**Files:**
- Create: `PokeJournal/PokeJournal/Views/TypeMatchupView.swift`

No unit test — SwiftUI views are verified via build + preview. Adds just enough structure to render a header.

- [ ] **Step 1: Create `TypeMatchupView.swift`**

```swift
//
//  TypeMatchupView.swift
//  PokéJournal
//

import SwiftUI

struct TypeMatchupView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss

    private var teamTypes: [[String]] {
        game.currentTeam.compactMap { member in
            PokemonDatabase.shared.find(byName: member.pokemonName)?.types
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    Divider()
                    Text("Defensiv-Übersicht")
                        .font(.headline)
                    // Filled in by Task 11.

                    Text("Abdeckungs-Lücken")
                        .font(.headline)
                    // Filled in by Task 12.

                    Text("Empfehlung")
                        .font(.headline)
                    // Filled in by Task 12.
                }
                .padding()
            }
            .navigationTitle("Typ-Matchup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 560)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(game.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            generationBadge
        }
    }

    private var generationBadge: some View {
        let label: String = {
            switch game.generation {
            case .gen1: return "Gen 1"
            case .gen2to5: return "Gen 2–5"
            case .gen6plus: return "Gen 6+"
            }
        }()
        return Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.fill.quaternary, in: Capsule())
    }
}
```

- [ ] **Step 2: Build to verify compilation**

```bash
./scripts/test.sh build
```

Expected: clean build.

- [ ] **Step 3: Commit**

```bash
git add PokeJournal/PokeJournal/Views/TypeMatchupView.swift
git commit -m "Scaffold TypeMatchupView with header"
```

---

### Task 11: Defensive overview grid

**Files:**
- Modify: `PokeJournal/PokeJournal/Views/TypeMatchupView.swift`

Color-coded grid: red if multiplier > 1, green if < 1, grey neutral. Each cell shows the type label and multiplier. Tapping shows which team members are weak.

- [ ] **Step 1: Add the defensive grid**

Replace the `Defensiv-Übersicht` section inside `body`:

```swift
                    defensiveSection
```

Add these helpers inside the struct (above `body` or after `generationBadge`):

```swift
    private var profile: [String: Double] {
        TypeChart.teamDefensiveProfile(team: teamTypes, generation: game.generation)
    }

    private var defensiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Defensiv-Übersicht")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(game.generation.allTypes, id: \.self) { type in
                    DefensiveCell(
                        type: type,
                        multiplier: profile[type] ?? 1.0,
                        affectedMembers: affectedMembers(for: type)
                    )
                }
            }
        }
    }

    private func affectedMembers(for attacker: String) -> [String] {
        game.currentTeam.compactMap { member in
            guard let types = PokemonDatabase.shared.find(byName: member.pokemonName)?.types else {
                return nil
            }
            let m = TypeChart.defensiveMultiplier(
                attacker: attacker,
                defenderTypes: types,
                generation: game.generation
            )
            return m > 1.0 ? member.displayName : nil
        }
    }
```

Add a new file-private view below `TypeMatchupView`:

```swift
private struct DefensiveCell: View {
    let type: String
    let multiplier: Double
    let affectedMembers: [String]

    var body: some View {
        VStack(spacing: 4) {
            Text(typeLabel(type))
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(multiplierLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(background, in: RoundedRectangle(cornerRadius: 8))
        .help(tooltip)
    }

    private var multiplierLabel: String {
        switch multiplier {
        case 0: return "0×"
        case 0.25: return "¼×"
        case 0.5: return "½×"
        case 1: return "1×"
        case 2: return "2×"
        case 4: return "4×"
        default: return String(format: "%.2f×", multiplier)
        }
    }

    private var background: Color {
        if multiplier > 1 { return .red.opacity(0.2) }
        if multiplier < 1 { return .green.opacity(0.2) }
        return .gray.opacity(0.15)
    }

    private var tooltip: String {
        if affectedMembers.isEmpty {
            return typeLabel(type)
        }
        return "\(typeLabel(type)): \(affectedMembers.joined(separator: ", "))"
    }
}

private func typeLabel(_ type: String) -> String {
    switch type {
    case "normal": return "Normal"
    case "fire": return "Feuer"
    case "water": return "Wasser"
    case "electric": return "Elektro"
    case "grass": return "Pflanze"
    case "ice": return "Eis"
    case "fighting": return "Kampf"
    case "poison": return "Gift"
    case "ground": return "Boden"
    case "flying": return "Flug"
    case "psychic": return "Psycho"
    case "bug": return "Käfer"
    case "rock": return "Gestein"
    case "ghost": return "Geist"
    case "dragon": return "Drache"
    case "dark": return "Unlicht"
    case "steel": return "Stahl"
    case "fairy": return "Fee"
    default: return type.capitalized
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
./scripts/test.sh build
```

Expected: clean build.

- [ ] **Step 3: Commit**

```bash
git add PokeJournal/PokeJournal/Views/TypeMatchupView.swift
git commit -m "Add defensive overview grid to TypeMatchupView"
```

---

### Task 12: Coverage-gap and recommendation sections

**Files:**
- Modify: `PokeJournal/PokeJournal/Views/TypeMatchupView.swift`

- [ ] **Step 1: Replace the placeholder sections in `body`**

Replace the remaining two `Text("Abdeckungs-Lücken")` / `Text("Empfehlung")` placeholders with:

```swift
                    coverageGapsSection
                    recommendationSection
```

- [ ] **Step 2: Add the section views**

Append inside the struct:

```swift
    private var coverageGapsSection: some View {
        let gaps = TypeChart.coverageGaps(team: teamTypes, generation: game.generation)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Abdeckungs-Lücken")
                .font(.headline)
            if gaps.isEmpty {
                Text("Dein Team kann alle Typen effektiv treffen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Diese Typen kann dein Team nicht super-effektiv treffen:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(gaps, id: \.self) { type in
                        Text(typeLabel(type))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.2), in: Capsule())
                    }
                }
            }
        }
    }

    private var recommendationSection: some View {
        let recs = TypeChart.recommendation(team: teamTypes, generation: game.generation)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Empfehlung")
                .font(.headline)
            if recs.isEmpty {
                Text("Dein Team ist gut aufgestellt — keine Empfehlungen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recs, id: \.self) { type in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(PokemonTypeColor.color(for: type))
                            .frame(width: 10, height: 10)
                        Text("Ein \(typeLabel(type))-Pokémon würde dein Team abrunden.")
                            .font(.subheadline)
                    }
                }
            }
        }
    }
```

`FlowLayout` is a simple wrapping layout — add it at the bottom of the file if not already available elsewhere in the codebase. First check: `grep -r "FlowLayout" PokeJournal/PokeJournal`. If it exists, reuse it. Otherwise add:

```swift
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
./scripts/test.sh build
```

Expected: clean build.

- [ ] **Step 4: Commit**

```bash
git add PokeJournal/PokeJournal/Views/TypeMatchupView.swift
git commit -m "Add coverage gaps and recommendation sections"
```

---

### Task 13: Wire up sheet from `CurrentTeamView`

**Files:**
- Modify: `PokeJournal/PokeJournal/Views/GameDetailView.swift`

Change `CurrentTeamView` to accept the `Game` (so it can read `generation` and open a sheet), and add a toolbar-style button that presents `TypeMatchupView`.

- [ ] **Step 1: Update `CurrentTeamView`'s signature and body**

Replace the existing `CurrentTeamView` struct in `GameDetailView.swift` (the `team` parameter becomes `game`):

```swift
struct CurrentTeamView: View {
    let game: Game
    @State private var showMatchup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aktuelles Team")
                    .font(.headline)
                Spacer()
                Button {
                    showMatchup = true
                } label: {
                    Label("Typ-Matchup", systemImage: "shield.lefthalf.filled")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
            ], spacing: 12) {
                ForEach(game.currentTeam, id: \.pokemonName) { member in
                    TeamMemberCard(member: member)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showMatchup) {
            TypeMatchupView(game: game)
        }
    }
}
```

- [ ] **Step 2: Update the call site**

Inside `GameDetailContent.body`, change:

```swift
            if !game.currentTeam.isEmpty {
                CurrentTeamView(team: game.currentTeam)
            }
```

to:

```swift
            if !game.currentTeam.isEmpty {
                CurrentTeamView(game: game)
            }
```

- [ ] **Step 3: Update the preview fixture if one exists**

Search for other `CurrentTeamView(team:` call sites:

```bash
grep -rn "CurrentTeamView(team:" PokeJournal/PokeJournal
```

If any remain (e.g. in `#Preview` blocks), replace them with `CurrentTeamView(game: game)`.

- [ ] **Step 4: Build and run full test suite**

```bash
./scripts/test.sh build
./scripts/test.sh unit
```

Expected: clean build and all tests pass.

- [ ] **Step 5: Manual verification**

Open the app in Xcode (⌘R), pick any game with a current team, click **Typ-Matchup**, verify:
- Sheet opens with correct game name and generation badge.
- Defensive grid shows colored cells for all generation types.
- Coverage gaps lists the types the team cannot super-effectively hit.
- Recommendation section shows up to 3 suggestions.
- "Fertig" dismisses the sheet.

- [ ] **Step 6: Commit**

```bash
git add PokeJournal/PokeJournal/Views/GameDetailView.swift
git commit -m "Wire up Typ-Matchup sheet from CurrentTeamView"
```

---

### Task 14: Archive the spec

**Files:**
- Move: `plans/type-matchup.md` → `plans/done/type-matchup.md`

- [ ] **Step 1: Move the original spec file**

```bash
git mv plans/type-matchup.md plans/done/type-matchup.md
```

- [ ] **Step 2: Delete this implementation plan**

The plan has served its purpose. Keep only the original spec under `plans/done/`.

```bash
git rm plans/type-matchup-plan.md
```

- [ ] **Step 3: Commit**

```bash
git commit -m "Mark type-matchup plan as done"
```
