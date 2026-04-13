//
//  TeamAnalysisDataTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

@Suite(.serialized)
@MainActor
struct TeamAnalysisDataTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ str: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: str)!
    }

    @Test func emptyGame_returnsEmptyUsage() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Empty", filePath: "/empty.md")
        context.insert(game)
        try context.save()

        let usage = TeamAnalysisDataBuilder.buildUsage(from: game)
        #expect(usage.isEmpty)
    }

    @Test func singleSession_countsPokemonOnce() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Pikachu", level: 25)
        m1.session = s1
        context.insert(m1)
        try context.save()

        let usage = TeamAnalysisDataBuilder.buildUsage(from: game)
        #expect(usage.count == 1)
        #expect(usage[0].name == "Pikachu")
        #expect(usage[0].count == 1)
        #expect(usage[0].maxLevel == 25)
    }

    @Test func multipleSessions_countsPerSession() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Pikachu", level: 25)
        m1.session = s1
        context.insert(m1)

        let s2 = Session(date: date("2025-01-02"), activities: "B")
        s2.game = game
        context.insert(s2)
        let m2 = TeamMember(pokemonName: "Pikachu", level: 30)
        m2.session = s2
        context.insert(m2)
        try context.save()

        let usage = TeamAnalysisDataBuilder.buildUsage(from: game)
        #expect(usage.count == 1)
        #expect(usage[0].count == 2)
        #expect(usage[0].maxLevel == 30)
    }

    @Test func evolutionLine_mergedUnderHighestForm() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Glumanda", level: 10)
        m1.session = s1
        context.insert(m1)

        let s2 = Session(date: date("2025-01-02"), activities: "B")
        s2.game = game
        context.insert(s2)
        let m2 = TeamMember(pokemonName: "Glurak", level: 36)
        m2.session = s2
        context.insert(m2)
        try context.save()

        let usage = TeamAnalysisDataBuilder.buildUsage(from: game)
        // Glumanda and Glurak are same evolution line → 1 entry
        #expect(usage.count == 1)
        #expect(usage[0].name == "Glurak")
        #expect(usage[0].count == 2)
        #expect(usage[0].maxLevel == 36)
    }

    @Test func sameEvolutionLine_deduplicatedPerSession() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // One session with both Glumanda and Glutexo (shouldn't happen, but edge case)
        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Glumanda", level: 10)
        m1.session = s1
        let m2 = TeamMember(pokemonName: "Glutexo", level: 20)
        m2.session = s1
        context.insert(m1)
        context.insert(m2)
        try context.save()

        let usage = TeamAnalysisDataBuilder.buildUsage(from: game)
        // Same evolution line in same session → count = 1
        #expect(usage.count == 1)
        #expect(usage[0].count == 1)
    }

    @Test func sortedByCountDescending() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Pikachu in 2 sessions, Lapras in 1
        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let p1 = TeamMember(pokemonName: "Pikachu", level: 25)
        p1.session = s1
        let l1 = TeamMember(pokemonName: "Lapras", level: 40)
        l1.session = s1
        context.insert(p1)
        context.insert(l1)

        let s2 = Session(date: date("2025-01-02"), activities: "B")
        s2.game = game
        context.insert(s2)
        let p2 = TeamMember(pokemonName: "Pikachu", level: 30)
        p2.session = s2
        context.insert(p2)
        try context.save()

        let usage = TeamAnalysisDataBuilder.buildUsage(from: game)
        #expect(usage.count == 2)
        #expect(usage[0].name == "Pikachu")
        #expect(usage[0].count == 2)
        #expect(usage[1].name == "Lapras")
        #expect(usage[1].count == 1)
    }

    @Test func oldSessions_includedInUsage() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let old = OldSession(date: date("2024-01-01"), activities: "Old")
        old.game = game
        context.insert(old)
        let m1 = TeamMember(pokemonName: "Tauros", level: 50)
        m1.oldSession = old
        context.insert(m1)
        try context.save()

        let usage = TeamAnalysisDataBuilder.buildUsage(from: game)
        #expect(usage.count == 1)
        #expect(usage[0].name == "Tauros")
        #expect(usage[0].count == 1)
    }

    @Test func variantPokemon_separateFromBaseForm() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let normal = TeamMember(pokemonName: "Raichu", level: 40)
        normal.session = s1
        let alola = TeamMember(pokemonName: "Raichu", level: 35, variant: "Alola")
        alola.session = s1
        context.insert(normal)
        context.insert(alola)
        try context.save()

        let usage = TeamAnalysisDataBuilder.buildUsage(from: game)
        #expect(usage.count == 2)
        let names = Set(usage.map(\.name))
        #expect(names.contains("Raichu"))
        #expect(names.contains("Alola Raichu"))
    }
}
