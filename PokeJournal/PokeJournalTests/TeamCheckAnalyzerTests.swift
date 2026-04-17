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
