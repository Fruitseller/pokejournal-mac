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
}
