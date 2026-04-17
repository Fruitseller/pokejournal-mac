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
        for analysis in result {
            if case .verzichtbar = analysis.category {
                // ok
            } else {
                Issue.record("Expected .verzichtbar for \(analysis.memberName), got \(analysis.category)")
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
}
