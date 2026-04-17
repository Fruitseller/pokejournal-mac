# Typ-Matchup Actionable Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the passive Typ-Matchup analysis sheet with an actionable Team-Coach — per-member tausch-empfehlung, bucketed defensive view, icon-enhanced offensive grid.

**Architecture:** Pure-logic analyzer (`TeamCheckAnalyzer`) builds on top of existing `TypeChart` service. View layer decomposes `TypeMatchupView` into three sections (Team-Check, Defensiv-Buckets, Offensiv-Grid). Icons from partywhale/pokemon-type-icons (MIT, SVG) via new `PokemonTypeIcon` utility. Categorization is leave-one-out-driven, not overlap-driven.

**Tech Stack:** Swift 6.2, SwiftUI, Swift Testing (`@Test` / `#expect`), `@AppStorage`, SF Symbols, SwiftData (read-only via `@Query`).

**Spec reference:** `docs/superpowers/specs/2026-04-17-type-matchup-actionable-design.md`

---

## File Structure

**New files:**
- `PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift` — pure-logic analyzer, no UI deps
- `PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift` — Swift Testing suite
- `PokeJournal/PokeJournal/Views/PokemonTypeIcon.swift` — icon utility
- `PokeJournal/PokeJournal/Views/TeamCheckSection.swift` — new top-of-sheet section
- `PokeJournal/PokeJournal/Views/DefensiveBucketList.swift` — bucketed List view
- `PokeJournal/PokeJournal/Assets.xcassets/TypeIcons/` — 18 vector assets
- `CREDITS.md` — root-level license attribution

**Modified files:**
- `PokeJournal/PokeJournal/Views/TypeMatchupView.swift` — substantial rewrite (remove Lücken/Empfehlung, integrate new sections, generation-aware grids)

---

## Task 1: Audit `TypeChart.recommendation()` for leave-one-out fitness

**Files:**
- Read: `PokeJournal/PokeJournal/Services/TypeChart.swift:204-234`

- [ ] **Step 1: Read the function**

Open `TypeChart.swift` and read lines 204–234. The function:
1. Computes `profile` (team defensive profile) and `gaps` (offensive gaps) for the input team.
2. Filters types already in the team, so `candidates` is strict additions only.
3. Scores each candidate: `defensiveValue` (how many of the team's ≥×2 weaknesses it resists) + `offensiveValue` (how many gap types it hits >×1).
4. Returns top 3 by score (empty if no weaknesses and no gaps).

- [ ] **Step 2: Confirm fitness for our use case**

For our leave-one-out use: we pass `team = full - oneMember`. That team has its own (possibly new) weaknesses and gaps. The function returns types that best fix them — exactly what we want.

Audit verdict (document in this plan, no code change): **suitable for v1**. If real-world results are unsatisfying, add weighted variant in a follow-up iteration.

Empty-list behaviour: when reduced team has no weaknesses and no gaps, the function returns `[]`. Our analyzer must handle this (we'll demote those cases to `.ausgewogen` in Task 7).

- [ ] **Step 3: No commit — this was pure audit**

---

## Task 2: TeamCheckAnalyzer skeleton + empty-team test

**Files:**
- Create: `PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift`
- Create: `PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift`

- [ ] **Step 1: Write the failing test**

Create `TeamCheckAnalyzerTests.swift`:

```swift
//
//  TeamCheckAnalyzerTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
@testable import PokeJournal

struct TeamCheckAnalyzerTests {

    @Test func emptyTeam_returnsEmptyArray() {
        let result = TeamCheckAnalyzer.analyze(team: [], generation: .gen6plus)
        #expect(result.isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh build`
Expected: build error "Cannot find 'TeamCheckAnalyzer' in scope"

- [ ] **Step 3: Implement skeleton**

Create `TeamCheckAnalyzer.swift`:

```swift
//
//  TeamCheckAnalyzer.swift
//  PokéJournal
//

import Foundation

struct TeamMemberAnalysis: Equatable {
    let memberName: String
    let types: [String]
    let category: Category
    let reason: String?

    enum Category: Equatable {
        case kernstueck
        case ausgewogen
        case verzichtbar(ersatzTyp: String)
    }
}

enum TeamCheckAnalyzer {

    struct Member: Equatable {
        let name: String
        let types: [String]
    }

    static func analyze(
        team: [Member],
        generation: TypeChartGeneration
    ) -> [TeamMemberAnalysis] {
        return []
    }
}
```

- [ ] **Step 4: Run unit tests**

Run: `./scripts/test.sh unit`
Expected: PASS (empty team test passes with empty return).

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift
git commit -m "Add TeamCheckAnalyzer skeleton with empty-team case"
```

---

## Task 3: Single-member team is always Kernstück

**Files:**
- Modify: `PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift`
- Modify: `PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift`

- [ ] **Step 1: Add failing test**

Append to `TeamCheckAnalyzerTests.swift` inside the existing struct:

```swift
    @Test func singleMember_isKernstueck() {
        let result = TeamCheckAnalyzer.analyze(
            team: [.init(name: "Glurak", types: ["fire", "flying"])],
            generation: .gen6plus
        )
        #expect(result.count == 1)
        #expect(result.first?.category == .kernstueck)
        #expect(result.first?.memberName == "Glurak")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh unit`
Expected: FAIL — `result.count` is 0, not 1.

- [ ] **Step 3: Implement single-member branch**

Replace the body of `analyze(team:generation:)` in `TeamCheckAnalyzer.swift`:

```swift
    static func analyze(
        team: [Member],
        generation: TypeChartGeneration
    ) -> [TeamMemberAnalysis] {
        guard !team.isEmpty else { return [] }

        if team.count == 1 {
            let m = team[0]
            return [TeamMemberAnalysis(
                memberName: m.name,
                types: m.types,
                category: .kernstueck,
                reason: "Einziges Team-Mitglied"
            )]
        }

        // Multi-member analysis: filled in subsequent tasks.
        return team.map { m in
            TeamMemberAnalysis(
                memberName: m.name,
                types: m.types,
                category: .ausgewogen,
                reason: nil
            )
        }
    }
```

- [ ] **Step 4: Run unit tests**

Run: `./scripts/test.sh unit`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift
git commit -m "Handle single-member team as Kernstück"
```

---

## Task 4: Add `uniqueDefense` and `uniqueOffense` metrics

**Files:**
- Modify: `PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift`
- Modify: `PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift`

- [ ] **Step 1: Add failing tests**

Append to `TeamCheckAnalyzerTests.swift`:

```swift
    @Test func uniqueDefense_glurakOnlyTeamMemberResistantToGrass() {
        // Glurak (fire/flying) resists grass ×0.25
        // Mew (psychic) is neutral to grass ×1.0
        // → Glurak has ≥1 unique_defense
        let result = TeamCheckAnalyzer.analyze(
            team: [
                .init(name: "Glurak", types: ["fire", "flying"]),
                .init(name: "Mew", types: ["psychic"])
            ],
            generation: .gen6plus
        )
        // With leave-one-out also producing new gaps, Glurak should be Kernstück
        let glurak = result.first { $0.memberName == "Glurak" }
        #expect(glurak?.category == .kernstueck)
    }

    @Test func uniqueOffense_onlyFireMemberHitsSteelSuperEffectively() {
        // Glurak's fire type hits steel ×2
        // Mew's psychic type is neutral vs steel
        // → Glurak has ≥1 unique_offense (steel)
        let result = TeamCheckAnalyzer.analyze(
            team: [
                .init(name: "Glurak", types: ["fire", "flying"]),
                .init(name: "Mew", types: ["psychic"])
            ],
            generation: .gen6plus
        )
        let glurak = result.first { $0.memberName == "Glurak" }
        #expect(glurak?.category == .kernstueck)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./scripts/test.sh unit`
Expected: FAIL — both currently return `.ausgewogen` (from the placeholder branch).

- [ ] **Step 3: Implement metrics as private helpers**

Append to `TeamCheckAnalyzer.swift` inside the enum, AFTER the existing `analyze` function:

```swift
    /// Count of attacker types where this member is the only one resistant (<1×) or immune (0×).
    private static func uniqueDefense(
        memberTypes: [String],
        others: [Member],
        generation: TypeChartGeneration
    ) -> Int {
        generation.allTypes.filter { attacker in
            let memberMultiplier = TypeChart.defensiveMultiplier(
                attacker: attacker,
                defenderTypes: memberTypes,
                generation: generation
            )
            guard memberMultiplier < 1.0 else { return false }
            // Only counts if no other member also resists/is immune.
            let othersAlsoResist = others.contains { other in
                TypeChart.defensiveMultiplier(
                    attacker: attacker,
                    defenderTypes: other.types,
                    generation: generation
                ) < 1.0
            }
            return !othersAlsoResist
        }.count
    }

    /// Count of defender types where this member is the only one that can attack with >1×.
    private static func uniqueOffense(
        memberTypes: [String],
        others: [Member],
        generation: TypeChartGeneration
    ) -> Int {
        generation.allTypes.filter { defender in
            let memberBest = memberTypes.map {
                TypeChart.effectiveness(attacker: $0, defender: defender, generation: generation)
            }.max() ?? 1.0
            guard memberBest > 1.0 else { return false }
            let othersAlsoHit = others.contains { other in
                other.types.contains { attacker in
                    TypeChart.effectiveness(attacker: attacker, defender: defender, generation: generation) > 1.0
                }
            }
            return !othersAlsoHit
        }.count
    }
```

- [ ] **Step 4: Don't run tests yet**

These helpers are private and not yet called. Tests still fail. That's expected — we'll wire them up in Task 6.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift
git commit -m "Add unique_defense/unique_offense helpers with failing tests"
```

---

## Task 5: Add `leaveOneOut` metric

**Files:**
- Modify: `PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift`

No new tests — this is a private helper feeding into the categorization tests of Task 6.

- [ ] **Step 1: Implement helper**

Append inside the `TeamCheckAnalyzer` enum:

```swift
    /// Delta when removing this member: count of newly-introduced ≥×2 weaknesses + new offensive gaps.
    /// `(newWeaknesses, newGaps)`.
    private static func leaveOneOutDelta(
        fullTeam: [[String]],
        reducedTeam: [[String]],
        generation: TypeChartGeneration
    ) -> (newWeaknesses: Int, newGaps: Int) {
        let fullProfile = TypeChart.teamDefensiveProfile(team: fullTeam, generation: generation)
        let reducedProfile = TypeChart.teamDefensiveProfile(team: reducedTeam, generation: generation)
        let fullGaps = Set(TypeChart.coverageGaps(team: fullTeam, generation: generation))
        let reducedGaps = Set(TypeChart.coverageGaps(team: reducedTeam, generation: generation))

        let newWeaknesses = generation.allTypes.filter { attacker in
            let before = fullProfile[attacker] ?? 1.0
            let after = reducedProfile[attacker] ?? 1.0
            return after >= 2.0 && before < 2.0
        }.count

        let newGaps = reducedGaps.subtracting(fullGaps).count

        return (newWeaknesses, newGaps)
    }
```

- [ ] **Step 2: Build to verify compile**

Run: `./scripts/test.sh build`
Expected: clean build.

- [ ] **Step 3: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift
git commit -m "Add leave-one-out delta helper"
```

---

## Task 6: Wire up Kernstück / Verzichtbar / Ausgewogen categorization

**Files:**
- Modify: `PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift`
- Modify: `PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift`

- [ ] **Step 1: Add Ausgewogen test**

Append to `TeamCheckAnalyzerTests.swift`:

```swift
    @Test func twoIdenticalPureGrass_bothVerzichtbar() {
        // Endivie and Meganie are both pure grass.
        // Neither has unique_defense or unique_offense.
        // Removing one: the other still covers grass — no new weaknesses/gaps.
        let result = TeamCheckAnalyzer.analyze(
            team: [
                .init(name: "Endivie", types: ["grass"]),
                .init(name: "Meganie", types: ["grass"])
            ],
            generation: .gen6plus
        )
        for analysis in result {
            if case .verzichtbar = analysis.category {
                // ok
            } else {
                Issue.record("Expected .verzichtbar for \(analysis.memberName), got \(analysis.category)")
            }
        }
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh unit`
Expected: FAIL — both currently return `.ausgewogen` (placeholder branch).

- [ ] **Step 3: Replace the multi-member placeholder with real categorization**

In `TeamCheckAnalyzer.swift`, replace the placeholder `team.map { ... .ausgewogen ... }` in `analyze(team:generation:)` with:

```swift
        return team.enumerated().map { idx, _ in
            categorize(at: idx, in: team, generation: generation)
        }
    }

    private static func categorize(
        at index: Int,
        in team: [Member],
        generation: TypeChartGeneration
    ) -> TeamMemberAnalysis {
        let member = team[index]
        let others = team.enumerated()
            .filter { $0.offset != index }
            .map { $0.element }

        let uDef = uniqueDefense(memberTypes: member.types, others: others, generation: generation)
        let uOff = uniqueOffense(memberTypes: member.types, others: others, generation: generation)
        let delta = leaveOneOutDelta(
            fullTeam: team.map(\.types),
            reducedTeam: others.map(\.types),
            generation: generation
        )

        let hasUniqueBeitrag = (uDef + uOff) >= 1
        let removalHurtsTeam = (delta.newGaps >= 1 || delta.newWeaknesses >= 1)

        if hasUniqueBeitrag && removalHurtsTeam {
            return TeamMemberAnalysis(
                memberName: member.name,
                types: member.types,
                category: .kernstueck,
                reason: nil  // filled in Task 8
            )
        }

        let isVerzichtbar = !hasUniqueBeitrag && !removalHurtsTeam
        if isVerzichtbar {
            return TeamMemberAnalysis(
                memberName: member.name,
                types: member.types,
                category: .verzichtbar(ersatzTyp: "normal"),  // placeholder; filled in Task 7
                reason: nil  // filled in Task 8
            )
        }

        return TeamMemberAnalysis(
            memberName: member.name,
            types: member.types,
            category: .ausgewogen,
            reason: nil
        )
    }
```

- [ ] **Step 4: Run all tests**

Run: `./scripts/test.sh unit`
Expected: PASS — Endivie/Meganie both verzichtbar, Glurak+Mew tests show Glurak as Kernstück.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift
git commit -m "Categorize members via leave-one-out + unique-contribution"
```

---

## Task 7: Real Ersatz-Typ via `TypeChart.recommendation`

**Files:**
- Modify: `PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift`
- Modify: `PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift`

- [ ] **Step 1: Add test**

Append to `TeamCheckAnalyzerTests.swift`:

```swift
    @Test func verzichtbar_hasNonPlaceholderErsatzTyp() {
        // Two pure grass members — recommendation on reduced team ≠ "normal" placeholder.
        let result = TeamCheckAnalyzer.analyze(
            team: [
                .init(name: "Endivie", types: ["grass"]),
                .init(name: "Meganie", types: ["grass"])
            ],
            generation: .gen6plus
        )
        for analysis in result {
            if case .verzichtbar(let ersatz) = analysis.category {
                #expect(ersatz != "normal", "Expected real recommendation, got placeholder")
                // Grass is weak to ice/fire/flying/bug/poison — any of those is plausible.
                #expect(["ice", "fire", "flying", "bug", "poison"].contains(ersatz))
            }
        }
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh unit`
Expected: FAIL — ersatzTyp is currently "normal".

- [ ] **Step 3: Replace the verzichtbar branch in `categorize(...)`**

In `TeamCheckAnalyzer.swift`, replace the `if isVerzichtbar { ... }` block with:

```swift
        if isVerzichtbar {
            let recommendations = TypeChart.recommendation(
                team: others.map(\.types),
                generation: generation
            )
            if let ersatz = recommendations.first {
                return TeamMemberAnalysis(
                    memberName: member.name,
                    types: member.types,
                    category: .verzichtbar(ersatzTyp: ersatz),
                    reason: nil  // filled in Task 8
                )
            }
            // No recommendation possible — reduced team has no weaknesses or gaps.
            // Demote to ausgewogen per spec.
            return TeamMemberAnalysis(
                memberName: member.name,
                types: member.types,
                category: .ausgewogen,
                reason: nil
            )
        }
```

- [ ] **Step 4: Run all tests**

Run: `./scripts/test.sh unit`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift
git commit -m "Compute real Ersatz-Typ via TypeChart.recommendation"
```

---

## Task 8: Begründungs-Halbsätze (`reason` field)

**Files:**
- Modify: `PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift`
- Modify: `PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift`

- [ ] **Step 1: Add reason tests**

Append to `TeamCheckAnalyzerTests.swift`:

```swift
    @Test func verzichtbar_withTypeOverlap_reasonMentionsPartner() {
        // Two pure grass — overlap partner is the other.
        let result = TeamCheckAnalyzer.analyze(
            team: [
                .init(name: "Endivie", types: ["grass"]),
                .init(name: "Meganie", types: ["grass"])
            ],
            generation: .gen6plus
        )
        let endivie = result.first { $0.memberName == "Endivie" }
        #expect(endivie?.reason == "Redundant mit Meganie")
        let meganie = result.first { $0.memberName == "Meganie" }
        #expect(meganie?.reason == "Redundant mit Endivie")
    }

    @Test func kernstueck_reasonMentionsUniqueContribution() {
        // Glurak is the only flying type → unique defense contribution.
        let result = TeamCheckAnalyzer.analyze(
            team: [
                .init(name: "Glurak", types: ["fire", "flying"]),
                .init(name: "Mew", types: ["psychic"])
            ],
            generation: .gen6plus
        )
        let glurak = result.first { $0.memberName == "Glurak" }
        #expect(glurak?.category == .kernstueck)
        #expect(glurak?.reason != nil)
        #expect(!(glurak?.reason ?? "").isEmpty)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./scripts/test.sh unit`
Expected: FAIL — all reasons currently `nil`.

- [ ] **Step 3: Implement overlap finder + reason construction**

Append inside `TeamCheckAnalyzer` enum:

```swift
    /// Returns the first other team member that shares at least one type, if any.
    private static func overlapPartner(
        memberTypes: [String],
        others: [Member]
    ) -> Member? {
        let memberSet = Set(memberTypes)
        return others.first { !memberSet.isDisjoint(with: Set($0.types)) }
    }

    private static func kernstueckReason(uDef: Int, uOff: Int) -> String {
        if uDef > 0 && uOff > 0 {
            return "Deckt \(uDef) Schwächen und trifft \(uOff) Typen einzigartig"
        }
        if uDef > 0 {
            return "Deckt \(uDef) Schwächen allein ab"
        }
        return "Einzige offensive Antwort gegen \(uOff) Typen"
    }
```

Now update `categorize(...)` to use them. Replace the Kernstück branch:

```swift
        if hasUniqueBeitrag && removalHurtsTeam {
            return TeamMemberAnalysis(
                memberName: member.name,
                types: member.types,
                category: .kernstueck,
                reason: kernstueckReason(uDef: uDef, uOff: uOff)
            )
        }
```

And update the Verzichtbar branch to compute reason:

```swift
        if isVerzichtbar {
            let recommendations = TypeChart.recommendation(
                team: others.map(\.types),
                generation: generation
            )
            if let ersatz = recommendations.first {
                let partner = overlapPartner(memberTypes: member.types, others: others)
                let reason = partner.map { "Redundant mit \($0.name)" }
                    ?? "Kein einzigartiger Beitrag"
                return TeamMemberAnalysis(
                    memberName: member.name,
                    types: member.types,
                    category: .verzichtbar(ersatzTyp: ersatz),
                    reason: reason
                )
            }
            return TeamMemberAnalysis(
                memberName: member.name,
                types: member.types,
                category: .ausgewogen,
                reason: nil
            )
        }
```

- [ ] **Step 4: Run tests**

Run: `./scripts/test.sh unit`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Services/TeamCheckAnalyzer.swift PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift
git commit -m "Add Begründungs-Halbsätze for Kernstück and Verzichtbar"
```

---

## Task 9: Generations regression test (Gen 1 vs Gen 6+)

**Files:**
- Modify: `PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift`

- [ ] **Step 1: Add regression test**

Append to `TeamCheckAnalyzerTests.swift`:

```swift
    @Test func categorization_differsByGeneration() {
        // Team: Bisasam (grass/poison) + Arbok (poison).
        // In Gen 1: fairy doesn't exist — poison has no unique offensive niche against fairy.
        // In Gen 6+: poison hits fairy ×2 — an offensive asset that exists in Gen 6 but not Gen 1.
        // Members / category must change between generations.
        let team: [TeamCheckAnalyzer.Member] = [
            .init(name: "Bisasam", types: ["grass", "poison"]),
            .init(name: "Arbok", types: ["poison"])
        ]

        let gen1 = TeamCheckAnalyzer.analyze(team: team, generation: .gen1)
        let gen6 = TeamCheckAnalyzer.analyze(team: team, generation: .gen6plus)

        // Identical input, different generations → at least one member's
        // category OR reason must differ.
        let differs = zip(gen1, gen6).contains { a, b in
            a.category != b.category || a.reason != b.reason
        }
        #expect(differs, "Gen 1 vs Gen 6+ analysis should diverge on identical team")
    }
```

- [ ] **Step 2: Run test**

Run: `./scripts/test.sh unit`
Expected: PASS (regression test should pass with current implementation — type-generation coverage differs, so `uniqueOffense` differs, so categorization/reason differs).

If the test fails, investigate: it's possible both teams end up with identical categorization if the poison-vs-fairy niche doesn't flip anyone. Adjust the team composition until Gen 1 vs Gen 6+ demonstrably differ — try `[("Bisasam", ["grass","poison"]), ("Nidoking", ["poison","ground"])]` or add a third member. Keep the assertion strict; the value is in having a canary that breaks if generations stop propagating correctly.

- [ ] **Step 3: Commit**

```bash
git add PokeJournal/PokeJournalTests/TeamCheckAnalyzerTests.swift
git commit -m "Add Gen 1 vs Gen 6+ regression test"
```

---

## Task 10: Download partywhale icons + Asset Catalog

**Files:**
- Create: `PokeJournal/PokeJournal/Assets.xcassets/TypeIcons/Contents.json`
- Create: `PokeJournal/PokeJournal/Assets.xcassets/TypeIcons/<type>.imageset/` (×18)

- [ ] **Step 1: Fetch the icon repository**

```bash
cd /tmp
rm -rf pokemon-type-icons
git clone --depth 1 https://github.com/partywhale/pokemon-type-icons.git
ls pokemon-type-icons/icons/
```

Expected: 18 SVG files (bug, dark, dragon, electric, fairy, fighting, fire, flying, ghost, grass, ground, ice, normal, poison, psychic, rock, steel, water). Note the exact filenames — they may include suffixes.

- [ ] **Step 2: Create TypeIcons group + imagesets**

Open the Xcode project:

```bash
open "PokeJournal/PokeJournal.xcodeproj"
```

In Xcode's asset catalog navigator (`Assets.xcassets`):
1. Right-click → **New Folder** → name it `TypeIcons`.
2. For each of the 18 types, right-click inside TypeIcons → **Import…** → pick the matching SVG from `/tmp/pokemon-type-icons/icons/`.
3. Name each imageset by the lowercase English type identifier (e.g., `fire`, `water`, `grass`) — **exact match** to `TypeChartGeneration.allTypes` entries.
4. For each imageset, in the Attributes Inspector:
   - Set **Preserves Vector Data** to checked (ON).
   - Set **Scales** to **Single Scale**.
   - Set **Render As** to **Template Image** (so `.foregroundStyle` tints them).

Close Xcode.

- [ ] **Step 3: Verify assets compile**

Run: `./scripts/test.sh build`
Expected: clean build (icons are discoverable but unused).

- [ ] **Step 4: Commit**

```bash
git add PokeJournal/PokeJournal/Assets.xcassets/TypeIcons
git commit -m "Import 18 partywhale type icons into asset catalog"
```

---

## Task 11: CREDITS.md with full MIT license text

**Files:**
- Create: `CREDITS.md`

- [ ] **Step 1: Fetch the license text**

```bash
cat /tmp/pokemon-type-icons/LICENSE
```

Copy the full content.

- [ ] **Step 2: Create CREDITS.md**

Create `CREDITS.md` at the repo root with the following content (replace the LICENSE block with the actual content from step 1):

```markdown
# Credits

## Pokémon Type Icons

Icons in `PokeJournal/PokeJournal/Assets.xcassets/TypeIcons/` are from
[partywhale/pokemon-type-icons](https://github.com/partywhale/pokemon-type-icons),
used under the MIT License.

```
<PASTE LICENSE TEXT FROM STEP 1 HERE — full copyright notice and permission grant>
```

## Pokémon Sprites & Data

Pokémon sprites and type data are fetched from [PokéAPI](https://pokeapi.co/)
at build time via `scripts/fetch_pokemon_data.py`. Pokémon, character
names, and sprite designs are © Nintendo / Creatures Inc. / GAME FREAK Inc.
PokéJournal is a non-commercial personal tool and claims no ownership of
these assets.
```

- [ ] **Step 3: Commit**

```bash
git add CREDITS.md
git commit -m "Add CREDITS.md with icon license attribution"
```

---

## Task 12: `PokemonTypeIcon` utility

**Files:**
- Create: `PokeJournal/PokeJournal/Views/PokemonTypeIcon.swift`

- [ ] **Step 1: Write the utility**

```swift
//
//  PokemonTypeIcon.swift
//  PokéJournal
//

import SwiftUI

/// Loads the partywhale type icon for a given type identifier.
/// Icons are stored in `Assets.xcassets/TypeIcons/<type>` as template images
/// so they inherit `.foregroundStyle(...)` tint.
enum PokemonTypeIcon {

    /// Tinted icon for the given type, sized 16×16 by default.
    static func image(for type: String, size: CGFloat = 16) -> some View {
        Image(type.lowercased())
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundStyle(PokemonTypeColor.color(for: type))
            .accessibilityLabel(Self.accessibilityLabel(for: type))
    }

    private static func accessibilityLabel(for type: String) -> String {
        switch type.lowercased() {
        case "normal":   return "Normal-Typ"
        case "fire":     return "Feuer-Typ"
        case "water":    return "Wasser-Typ"
        case "electric": return "Elektro-Typ"
        case "grass":    return "Pflanzen-Typ"
        case "ice":      return "Eis-Typ"
        case "fighting": return "Kampf-Typ"
        case "poison":   return "Gift-Typ"
        case "ground":   return "Boden-Typ"
        case "flying":   return "Flug-Typ"
        case "psychic":  return "Psycho-Typ"
        case "bug":      return "Käfer-Typ"
        case "rock":     return "Gestein-Typ"
        case "ghost":    return "Geist-Typ"
        case "dragon":   return "Drachen-Typ"
        case "dark":     return "Unlicht-Typ"
        case "steel":    return "Stahl-Typ"
        case "fairy":    return "Feen-Typ"
        default:         return type.capitalized
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `./scripts/test.sh build`
Expected: clean build.

- [ ] **Step 3: Commit**

```bash
git add PokeJournal/PokeJournal/Views/PokemonTypeIcon.swift
git commit -m "Add PokemonTypeIcon utility with accessibility labels"
```

---

## Task 13: Factor `typeLabel` out of TypeMatchupView into shared utility

**Files:**
- Modify: `PokeJournal/PokeJournal/Views/PokemonTypeIcon.swift`
- Modify: `PokeJournal/PokeJournal/Views/TypeMatchupView.swift`

`typeLabel(_:)` is currently a private free function inside `TypeMatchupView.swift:239-261`. New views (TeamCheckSection, DefensiveBucketList) need it too — promote it to a utility.

- [ ] **Step 1: Add to PokemonTypeIcon.swift**

Append to `PokemonTypeIcon.swift`:

```swift
/// German display label for a type identifier.
enum PokemonTypeLabel {
    static func german(for type: String) -> String {
        switch type.lowercased() {
        case "normal":   return "Normal"
        case "fire":     return "Feuer"
        case "water":    return "Wasser"
        case "electric": return "Elektro"
        case "grass":    return "Pflanze"
        case "ice":      return "Eis"
        case "fighting": return "Kampf"
        case "poison":   return "Gift"
        case "ground":   return "Boden"
        case "flying":   return "Flug"
        case "psychic":  return "Psycho"
        case "bug":      return "Käfer"
        case "rock":     return "Gestein"
        case "ghost":    return "Geist"
        case "dragon":   return "Drache"
        case "dark":     return "Unlicht"
        case "steel":    return "Stahl"
        case "fairy":    return "Fee"
        default:         return type.capitalized
        }
    }
}
```

- [ ] **Step 2: Delete the private `typeLabel(_:)` function from `TypeMatchupView.swift`**

Remove lines 239–261 of `TypeMatchupView.swift` (the entire `private func typeLabel(_ type: String) -> String { ... }` block).

- [ ] **Step 3: Replace `typeLabel(...)` call sites in TypeMatchupView.swift**

`typeLabel(type)` appears at:
- Line 136 (coverage gaps capsule)
- Line 163 (recommendation text)
- Line 198 (MatchupCell label)
- Line 233-235 (tooltip)

Replace each `typeLabel(type)` and `typeLabel(self.type)` call with `PokemonTypeLabel.german(for: type)` or `PokemonTypeLabel.german(for: self.type)`.

- [ ] **Step 4: Build and run tests**

Run: `./scripts/test.sh build`
Expected: clean build.

Run: `./scripts/test.sh unit`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Views/PokemonTypeIcon.swift PokeJournal/PokeJournal/Views/TypeMatchupView.swift
git commit -m "Promote typeLabel to shared PokemonTypeLabel utility"
```

---

## Task 14: `TeamCheckSection` view

**Files:**
- Create: `PokeJournal/PokeJournal/Views/TeamCheckSection.swift`

- [ ] **Step 1: Write the view**

```swift
//
//  TeamCheckSection.swift
//  PokéJournal
//

import SwiftUI

struct TeamCheckSection: View {
    let analyses: [TeamMemberAnalysis]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team-Check")
                .font(.headline)

            if analyses.isEmpty {
                Text("Füge erst Pokémon zu deinem Team hinzu, um Matchup-Empfehlungen zu erhalten.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if allKernstueck {
                allBalancedFooter
                analysesList
            } else {
                analysesList
            }
        }
    }

    private var allKernstueck: Bool {
        analyses.allSatisfy { $0.category == .kernstueck }
    }

    private var allBalancedFooter: some View {
        Text("Dein Team ist ausgewogen — keine Ersetzungs-Empfehlung.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var analysesList: some View {
        VStack(spacing: 8) {
            ForEach(analyses, id: \.memberName) { analysis in
                TeamCheckRow(analysis: analysis)
            }
        }
    }
}

private struct TeamCheckRow: View {
    let analysis: TeamMemberAnalysis

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PokemonSpriteView(name: analysis.memberName, size: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.memberName)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    ForEach(analysis.types, id: \.self) { type in
                        PokemonTypeIcon.image(for: type, size: 12)
                    }
                }
            }

            Spacer()

            statusColumn
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var statusColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            statusHeadline
            if let reason = analysis.reason {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var statusHeadline: some View {
        switch analysis.category {
        case .kernstueck:
            Label("Kernstück", systemImage: "star.fill")
                .foregroundStyle(.yellow)
                .font(.subheadline.weight(.semibold))
        case .ausgewogen:
            Label("Ausgewogen", systemImage: "circle")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        case .verzichtbar(let ersatzTyp):
            HStack(spacing: 4) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.orange)
                Text("Ersetzen durch")
                    .font(.subheadline)
                PokemonTypeIcon.image(for: ersatzTyp, size: 14)
                Text(PokemonTypeLabel.german(for: ersatzTyp))
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var accessibilityText: String {
        let categoryText: String
        switch analysis.category {
        case .kernstueck:
            categoryText = "Kernstück"
        case .ausgewogen:
            categoryText = "Ausgewogen"
        case .verzichtbar(let ersatzTyp):
            categoryText = "Verzichtbar, Vorschlag \(PokemonTypeLabel.german(for: ersatzTyp))-Typ"
        }
        if let reason = analysis.reason {
            return "\(analysis.memberName), \(categoryText), \(reason)"
        }
        return "\(analysis.memberName), \(categoryText)"
    }
}
```

- [ ] **Step 2: Build**

Run: `./scripts/test.sh build`
Expected: clean build. If `PokemonSpriteView` init signature differs from `name:size:`, inspect the file and adjust the call.

- [ ] **Step 3: Commit**

```bash
git add PokeJournal/PokeJournal/Views/TeamCheckSection.swift
git commit -m "Add TeamCheckSection view with Kernstück/Ausgewogen/Verzichtbar rows"
```

---

## Task 15: `DefensiveBucketList` view with sections + DisclosureGroup

**Files:**
- Create: `PokeJournal/PokeJournal/Views/DefensiveBucketList.swift`

- [ ] **Step 1: Write the view**

```swift
//
//  DefensiveBucketList.swift
//  PokéJournal
//

import SwiftUI

struct DefensiveBucketList: View {
    let profile: [String: Double]  // attacker-type → worst-team-multiplier
    let generation: TypeChartGeneration
    let affectedMembers: (String) -> [String]  // attacker-type → list of member names

    @AppStorage("typMatchup.neutralExpanded") private var neutralExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Defensiv-Übersicht")
                .font(.headline)

            List {
                bucketSection(title: "Kritisch", symbol: "exclamationmark.octagon.fill", tint: .red, entries: critical)
                bucketSection(title: "Schwach",  symbol: "exclamationmark.triangle.fill", tint: .orange, entries: weak)
                neutralSection
                bucketSection(title: "Resistent", symbol: "shield.lefthalf.filled", tint: .blue, entries: resistant)
                bucketSection(title: "Immun",     symbol: "checkmark.seal.fill",    tint: .green, entries: immune)
            }
            .listStyle(.inset)
            .frame(minHeight: 320)
        }
    }

    // MARK: buckets

    private var sortedEntries: [(type: String, multiplier: Double)] {
        generation.allTypes.map { ($0, profile[$0] ?? 1.0) }
    }

    private var critical: [(type: String, multiplier: Double)]  { sortedEntries.filter { $0.multiplier >= 4.0 } }
    private var weak: [(type: String, multiplier: Double)]      { sortedEntries.filter { $0.multiplier == 2.0 } }
    private var neutral: [(type: String, multiplier: Double)]   { sortedEntries.filter { $0.multiplier == 1.0 } }
    private var resistant: [(type: String, multiplier: Double)] { sortedEntries.filter { $0.multiplier > 0.0 && $0.multiplier < 1.0 } }
    private var immune: [(type: String, multiplier: Double)]    { sortedEntries.filter { $0.multiplier == 0.0 } }

    // MARK: rendering

    @ViewBuilder
    private func bucketSection(title: String, symbol: String, tint: Color, entries: [(type: String, multiplier: Double)]) -> some View {
        if !entries.isEmpty {
            Section {
                ForEach(entries, id: \.type) { entry in
                    defensiveRow(type: entry.type, multiplier: entry.multiplier)
                }
            } header: {
                bucketHeader(title: title, symbol: symbol, tint: tint, count: entries.count)
            }
        }
    }

    @ViewBuilder
    private var neutralSection: some View {
        if !neutral.isEmpty {
            Section {
                DisclosureGroup(isExpanded: $neutralExpanded) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                        ForEach(neutral, id: \.type) { entry in
                            neutralChip(type: entry.type)
                        }
                    }
                    .padding(.vertical, 4)
                } label: {
                    bucketHeader(title: "Neutral", symbol: "equal.circle", tint: .secondary, count: neutral.count)
                }
            }
        }
    }

    private func bucketHeader(title: String, symbol: String, tint: Color, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func defensiveRow(type: String, multiplier: Double) -> some View {
        HStack(spacing: 10) {
            PokemonTypeIcon.image(for: type, size: 18)
            Text(PokemonTypeLabel.german(for: type))
                .font(.subheadline)
            Text(multiplierLabel(multiplier))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            let members = affectedMembers(type)
            if !members.isEmpty {
                Text(members.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.rowAccessibilityLabel(type: type, multiplier: multiplier, members: affectedMembers(type)))
    }

    private func neutralChip(type: String) -> some View {
        HStack(spacing: 4) {
            PokemonTypeIcon.image(for: type, size: 14)
            Text(PokemonTypeLabel.german(for: type))
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.fill.quaternary, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(PokemonTypeLabel.german(for: type)), neutral")
    }

    private func multiplierLabel(_ multiplier: Double) -> String {
        switch multiplier {
        case 0:    return "×0"
        case 0.25: return "×¼"
        case 0.5:  return "×½"
        case 1:    return "×1"
        case 2:    return "×2"
        case 4:    return "×4"
        default:   return String(format: "×%.2f", multiplier)
        }
    }

    private static func rowAccessibilityLabel(type: String, multiplier: Double, members: [String]) -> String {
        let typeLabel = PokemonTypeLabel.german(for: type)
        let mult: String
        switch multiplier {
        case 0:    mult = "immun"
        case 0.25: mult = "ein Viertel Schaden"
        case 0.5:  mult = "halber Schaden"
        case 2:    mult = "doppelter Schaden"
        case 4:    mult = "vierfacher Schaden"
        default:   mult = "\(multiplier)-fach Schaden"
        }
        if members.isEmpty {
            return "\(typeLabel), \(mult)"
        }
        return "\(typeLabel), \(mult), betrifft \(members.joined(separator: ", "))"
    }
}
```

- [ ] **Step 2: Build**

Run: `./scripts/test.sh build`
Expected: clean build.

- [ ] **Step 3: Commit**

```bash
git add PokeJournal/PokeJournal/Views/DefensiveBucketList.swift
git commit -m "Add DefensiveBucketList with 5 buckets + neutral DisclosureGroup"
```

---

## Task 16: Integrate new sections into TypeMatchupView + strip old sections

**Files:**
- Modify: `PokeJournal/PokeJournal/Views/TypeMatchupView.swift`

- [ ] **Step 1: Rewrite the view body and helpers**

Replace the entire `struct TypeMatchupView: View { ... }` (lines 8–187) with:

```swift
struct TypeMatchupView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    @State private var cachedAnalyses: [TeamMemberAnalysis] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    Divider()
                    TeamCheckSection(analyses: cachedAnalyses)
                    Divider()
                    DefensiveBucketList(
                        profile: defensiveProfile,
                        generation: game.generation,
                        affectedMembers: weakMembers(against:)
                    )
                    offensiveSection
                }
                .padding()
            }
            .navigationTitle("Typ-Matchup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("typMatchupDoneButton")
                }
            }
        }
        .frame(minWidth: 520, minHeight: 640)
        .onAppear(perform: recomputeAnalyses)
        .onChange(of: game.currentTeam.map(\.pokemonName)) { _, _ in recomputeAnalyses() }
        .onChange(of: game.generation) { _, _ in recomputeAnalyses() }
    }

    // MARK: Header

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
            case .gen1:    return "Gen 1"
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

    // MARK: Analyses caching

    private func recomputeAnalyses() {
        let members = game.currentTeam.compactMap { member -> TeamCheckAnalyzer.Member? in
            guard let types = PokemonDatabase.shared.find(byName: member.pokemonName)?.types else {
                return nil
            }
            return .init(name: member.displayName, types: types)
        }
        cachedAnalyses = TeamCheckAnalyzer.analyze(team: members, generation: game.generation)
    }

    // MARK: Offensive grid (flat, generation-aware)

    private var offensiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Offensiv-Übersicht")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(game.generation.allTypes, id: \.self) { type in
                    OffensiveMatchupCell(
                        type: type,
                        multiplier: offensiveProfile[type] ?? 1.0,
                        relatedMembers: strongMembers(against: type)
                    )
                }
            }
        }
    }

    // MARK: Profiles

    private var defensiveProfile: [String: Double] {
        TypeChart.teamDefensiveProfile(team: teamTypes, generation: game.generation)
    }

    private var offensiveProfile: [String: Double] {
        TypeChart.teamOffensiveProfile(team: teamTypes, generation: game.generation)
    }

    private var teamTypes: [[String]] {
        game.currentTeam.compactMap { member in
            PokemonDatabase.shared.find(byName: member.pokemonName)?.types
        }
    }

    private func weakMembers(against attacker: String) -> [String] {
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

    private func strongMembers(against defender: String) -> [String] {
        game.currentTeam.compactMap { member in
            guard let types = PokemonDatabase.shared.find(byName: member.pokemonName)?.types else {
                return nil
            }
            let best = types.map {
                TypeChart.effectiveness(attacker: $0, defender: defender, generation: game.generation)
            }.max() ?? 1.0
            return best > 1.0 ? member.displayName : nil
        }
    }
}
```

- [ ] **Step 2: Delete the now-unused `MatchupCell` struct**

The old `private struct MatchupCell` (lines 189–237) is replaced by `OffensiveMatchupCell` (defined in the next step). Delete the `MatchupCell` declaration. If the `PokemonTypeLabel` factor-out from Task 13 already removed the free function, the file should now end after the `TypeMatchupView` struct.

- [ ] **Step 3: Add `OffensiveMatchupCell`**

Append at the end of `TypeMatchupView.swift`:

```swift
private struct OffensiveMatchupCell: View {
    let type: String
    let multiplier: Double
    let relatedMembers: [String]

    var body: some View {
        VStack(spacing: 4) {
            PokemonTypeIcon.image(for: type, size: 24)
            Text(PokemonTypeLabel.german(for: type))
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(multiplierLabel)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(outlineColor, lineWidth: outlineWidth)
        )
        .opacity(multiplier == 1.0 ? 0.4 : 1.0)
        .help(tooltip)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var multiplierLabel: String {
        switch multiplier {
        case 0:    return "×0"
        case 0.25: return "×¼"
        case 0.5:  return "×½"
        case 1:    return "×1"
        case 2:    return "×2"
        case 4:    return "×4"
        default:   return String(format: "×%.2f", multiplier)
        }
    }

    private var outlineColor: Color {
        if multiplier > 1.0 { return .green.opacity(0.6) }
        if multiplier < 1.0 { return .red.opacity(0.5) }
        return .clear
    }

    private var outlineWidth: CGFloat {
        multiplier == 1.0 ? 0 : 1
    }

    private var tooltip: String {
        let label = PokemonTypeLabel.german(for: type)
        if relatedMembers.isEmpty { return label }
        return "\(label): \(relatedMembers.joined(separator: ", "))"
    }

    private var accessibilityText: String {
        let label = PokemonTypeLabel.german(for: type)
        return "\(label), \(multiplierLabel) offensiv"
    }
}
```

- [ ] **Step 4: Build and run tests**

Run: `./scripts/test.sh build`
Expected: clean build. If the compiler complains about `teamTypes` being unused or duplicate, inspect the struct and ensure no duplicate helpers remain.

Run: `./scripts/test.sh unit`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add PokeJournal/PokeJournal/Views/TypeMatchupView.swift
git commit -m "Integrate TeamCheckSection + DefensiveBucketList, strip Lücken/Empfehlung"
```

---

## Task 17: Manual UI verification

**Files:**
- (no code changes — manual testing)

- [ ] **Step 1: Launch the app**

```bash
open "PokeJournal/PokeJournal.xcodeproj"
```

Build and run (⌘R). Open a game with 2–6 team members. Click the Typ-Matchup button.

- [ ] **Step 2: Verify Team-Check**

- [ ] Team-Check section renders at top, below the header.
- [ ] Each team member has a sprite, name, type icons in type colors, and a status badge.
- [ ] If the team has two identical types (e.g. two pure Pflanze), both show ⚠ Ersetzen durch [icon] with a reason.
- [ ] If a single member provides unique defense/offense, it shows ★ Kernstück with a reason.

- [ ] **Step 3: Verify Defensiv-Buckets**

- [ ] Buckets render in order Kritisch / Schwach / Neutral / Resistent / Immun.
- [ ] Empty buckets are hidden.
- [ ] Neutral is collapsed by default.
- [ ] Click Neutral header to expand — chips appear as an adaptive grid.
- [ ] Close and reopen the sheet — Neutral stays expanded (AppStorage persistence).
- [ ] Close the app, relaunch — Neutral stays expanded.
- [ ] Click Neutral again to collapse; close/reopen — stays collapsed.
- [ ] Bucket headers show count badge; icons are tinted red/orange/secondary/blue/green; text labels stay primary (not tinted).
- [ ] Rows show type icon, label, multiplier, affected member names (secondary font).

- [ ] **Step 4: Verify Offensiv-Grid**

- [ ] Grid renders with the correct type count for the game's generation (15/17/18).
- [ ] Cells with ×1 appear dimmed (~40% opacity).
- [ ] Cells with >×1 have a thin green outline.
- [ ] Cells with <×1 have a thin red outline.
- [ ] Type icons render in type colors.

- [ ] **Step 5: Verify Lücken/Empfehlung removal**

- [ ] The sheet no longer shows an "Abdeckungs-Lücken" section.
- [ ] The sheet no longer shows the "Ein X-Pokémon würde dein Team abrunden" text.

- [ ] **Step 6: Verify accessibility**

Enable VoiceOver (⌘F5). Cursor through the sheet:
- [ ] Team-Check row reads like: "Glurak, Kernstück, deckt 3 Schwächen allein ab".
- [ ] Verzichtbar row reads like: "Bisasam, verzichtbar, Vorschlag Wasser-Typ, redundant mit Meganie".
- [ ] Defensiv row reads like: "Eis, vierfacher Schaden, betrifft Glurak".
- [ ] Icons announce as "<Typ>-Typ".

- [ ] **Step 7: Fix any regressions found in the previous steps**

If any check failed, diagnose and fix. Commit each fix separately with a descriptive subject.

---

## Task 18: Final build + test + DoD commit

**Files:**
- (verification only — close out the work)

- [ ] **Step 1: Full build**

Run: `./scripts/test.sh build`
Expected: 0 errors, 0 warnings.

- [ ] **Step 2: Unit tests**

Run: `./scripts/test.sh unit`
Expected: all PASS, including new `TeamCheckAnalyzerTests`.

- [ ] **Step 3: Full test suite (including UI tests)**

Run: `./scripts/test.sh test`
Expected: all PASS. UI tests may need adjustment if they relied on the deleted "Abdeckungs-Lücken" section — if any fail due to missing text, update the UI test to expect the new structure.

- [ ] **Step 4: Verify CREDITS.md renders**

```bash
cat CREDITS.md
```

Expected: full MIT license text for partywhale icons is present.

- [ ] **Step 5: Final commit (if any cleanup was needed)**

```bash
git status
# if clean:
echo "DoD verified — all green."
# if changes remain:
git add -A
git commit -m "DoD cleanup for Typ-Matchup Actionable redesign"
```

---

## Self-Review

**Spec coverage check:**
- Sheet structure (Team-Check / Defensiv-Buckets / Offensiv-Grid, no Lücken/Empfehlung) → Task 16
- Team-Check algorithm (uniqueDefense, uniqueOffense, leaveOneOut, categorization) → Tasks 4–8
- Ersatz-Typ via `TypeChart.recommendation` with empty-list fallback → Task 7
- Begründungs-Halbsätze with overlap partner → Task 8
- Edge cases (empty team, all-Kernstück) → Task 14 (TeamCheckSection view handles both)
- Defensiv buckets (List, 5 Sections, DisclosureGroup for Neutral, @AppStorage) → Task 15
- Bucket-Header pattern (color only in icon, text neutral) → Task 15
- Offensiv-Grid (flat, generation-aware, dimmed ×1, outline for good/bad) → Task 16
- Icons from partywhale (MIT), 18 types, template rendering, type-color tint → Tasks 10, 12
- CREDITS.md with full MIT license text → Task 11
- Generations-Regression test → Task 9
- Audit of `TypeChart.recommendation()` → Task 1
- Caching via `@State` + `.onChange` → Task 16 (`cachedAnalyses` + `.onChange` on team and generation)
- Accessibility (combined elements, spoken labels) → Tasks 14, 15, 16
- Definition of Done → Task 18

**Placeholder scan:** No "TBD"/"implement later"/"add validation" stubs remain. Every code step shows complete code.

**Type consistency:**
- `TeamMemberAnalysis.Category` cases: `.kernstueck`, `.ausgewogen`, `.verzichtbar(ersatzTyp:)` — used consistently across Tasks 2, 3, 6, 7, 8, 14.
- `TeamCheckAnalyzer.Member` struct: `name`, `types` — used in Tasks 2, 6, 7, 8, 16.
- `PokemonTypeIcon.image(for:size:)` signature: used in Tasks 12, 14, 15, 16.
- `PokemonTypeLabel.german(for:)`: used in Tasks 13, 14, 15, 16.

All signatures line up.
