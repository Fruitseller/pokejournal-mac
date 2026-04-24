//
//  GameContentSignatureTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
@testable import PokeJournal

struct GameContentSignatureTests {
    @Test func build_differsForDifferentGames() {
        let gameA = Game(name: "alpha", filePath: "alpha.md")
        let gameB = Game(name: "beta", filePath: "beta.md")

        #expect(GameContentSignatureBuilder.build(from: gameA) != GameContentSignatureBuilder.build(from: gameB))
    }

    @Test func build_capturesSessionTextChanges() {
        let game = Game(name: "alpha", filePath: "alpha.md")
        let session = Session(date: Date(timeIntervalSince1970: 0), filePath: "alpha/sessions/one.md")
        session.activities = "short"
        game.sessions = [session]

        let before = GameContentSignatureBuilder.build(from: game)
        session.activities = "much longer"
        let after = GameContentSignatureBuilder.build(from: game)

        #expect(before != after)
    }

    @Test func build_capturesTeamChanges() {
        let game = Game(name: "alpha", filePath: "alpha.md")
        let session = Session(date: Date(timeIntervalSince1970: 0), filePath: "alpha/sessions/one.md")
        let member = TeamMember(pokemonName: "Glurak", level: 36)
        member.order = 0
        session.team = [member]
        game.sessions = [session]

        let before = GameContentSignatureBuilder.build(from: game)
        session.team[0].level = 37
        let after = GameContentSignatureBuilder.build(from: game)

        #expect(before != after)
    }
}
