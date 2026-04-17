//
//  TeamCheckAnalyzerTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
@testable import PokeJournal

struct TeamCheckAnalyzerTests {

    private func isVerzichtbar(_ category: TeamMemberAnalysis.Category) -> Bool {
        if case .verzichtbar = category { return true }
        return false
    }

    @Test func emptyTeam_returnsEmptyArray() {
        let result = TeamCheckAnalyzer.analyze(team: [], generation: .gen6plus)
        #expect(result.isEmpty)
    }

    @Test func singleMember_isKernstueck() {
        let result = TeamCheckAnalyzer.analyze(
            team: [.init(name: "Glurak", types: ["fire", "flying"])],
            generation: .gen6plus
        )
        #expect(result.count == 1)
        #expect(result.first?.category == .kernstueck)
        #expect(result.first?.memberName == "Glurak")
    }

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
        // Grass-only teams are weak to ice/fire/flying/bug/poison and have
        // offensive gaps elsewhere — recommendation must suggest one of those
        // or a strong offensive complement.
        let plausibleErsatz: Set<String> = [
            "ice", "fire", "flying", "bug", "poison", "steel", "rock", "ground"
        ]
        for analysis in result {
            #expect(
                isVerzichtbar(analysis.category),
                "Expected .verzichtbar for \(analysis.memberName), got \(analysis.category)"
            )
            if case .verzichtbar(let ersatzTyp) = analysis.category {
                #expect(
                    plausibleErsatz.contains(ersatzTyp),
                    "Expected plausible grass-complement for \(analysis.memberName), got \(ersatzTyp)"
                )
            }
        }
    }

    @Test func glurakWithMew_glurakIsKernstueck() {
        // Glurak (fire/flying) has unique defense (grass ×0.25) and unique offense (steel ×2 via fire).
        // Removing Glurak introduces new gaps/weaknesses.
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

    @Test func uniqueDefenseOnly_canBeKernstueckWhenRemovalMakesTeamWeak() {
        // Normal contributes no unique offense, but it is the only ghost immunity.
        // Removing it from a normal + fire team leaves fire alone, creating new
        // team-wide weaknesses (water/ground/rock) that did not exist before.
        let result = TeamCheckAnalyzer.analyze(
            team: [
                .init(name: "Relaxo", types: ["normal"]),
                .init(name: "Glut", types: ["fire"])
            ],
            generation: .gen6plus
        )
        let relaxo = result.first { $0.memberName == "Relaxo" }
        #expect(relaxo?.category == .kernstueck)
    }

    @Test func uniqueDefenseOnly_withoutTeamWideWeaknesses_isAusgewogen() {
        // Pure fire has uniqueDefense > 0, while fire/ground covers all of its
        // offensive contribution. Removing pure fire does not make the reduced
        // team newly weak across all remaining members.
        let result = TeamCheckAnalyzer.analyze(
            team: [
                .init(name: "Glut", types: ["fire"]),
                .init(name: "Knogga", types: ["fire", "ground"])
            ],
            generation: .gen6plus
        )
        let glut = result.first { $0.memberName == "Glut" }
        #expect(glut?.category == .ausgewogen)
        #expect(glut?.reason == nil)
    }

    @Test func categorization_differsByGeneration() {
        // Bisasam (grass/poison) + Nidoking (poison/ground).
        // In Gen 6+ poison hits fairy ×2 — offensive niche exists.
        // In Gen 1 fairy doesn't exist; steel/dark don't exist either —
        // different type pool → different gaps, weaknesses, ersatz candidates.
        let team: [TeamCheckAnalyzer.Member] = [
            .init(name: "Bisasam", types: ["grass", "poison"]),
            .init(name: "Nidoking", types: ["poison", "ground"])
        ]

        let gen1 = TeamCheckAnalyzer.analyze(team: team, generation: .gen1)
        let gen6 = TeamCheckAnalyzer.analyze(team: team, generation: .gen6plus)

        let differs = zip(gen1, gen6).contains { a, b in
            a.category != b.category || a.reason != b.reason
        }
        #expect(differs, "Gen 1 vs Gen 6+ analysis should diverge on identical team")
    }
}
