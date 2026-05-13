//
//  TeamDiffCalculatorTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

// MARK: - TeamDiff Evolution Detection Tests

@Suite(.serialized)
@MainActor
struct TeamDiffEvolutionTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func teamDiff_detectsEvolution() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let prev = TeamMember(pokemonName: "Glumanda", level: 15)
        let current = TeamMember(pokemonName: "Glutexo", level: 25)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])

        #expect(diff.evolutions.count == 1)
        #expect(diff.evolutions[0].from.pokemonName == "Glumanda")
        #expect(diff.evolutions[0].to.pokemonName == "Glutexo")
        #expect(diff.added.isEmpty)
        #expect(diff.removed.isEmpty)
    }

    @Test func teamDiff_evolutionHasLevelDelta() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let prev = TeamMember(pokemonName: "Glumanda", level: 15)
        let current = TeamMember(pokemonName: "Glutexo", level: 25)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])
        #expect(diff.evolutions[0].levelDelta == 10)
    }

    @Test func teamDiff_evolutionWithZeroLevelDelta() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Stone evolution: same level
        let prev = TeamMember(pokemonName: "Pikachu", level: 30)
        let current = TeamMember(pokemonName: "Raichu", level: 30)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])
        #expect(diff.evolutions.count == 1)
        #expect(diff.evolutions[0].levelDelta == 0)
        #expect(diff.added.isEmpty)
        #expect(diff.removed.isEmpty)
    }

    @Test func teamDiff_nonEvolutionSwapStillTracked() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Pikachu swapped for Glurak — not same evolution line
        let prev = TeamMember(pokemonName: "Pikachu", level: 30)
        let current = TeamMember(pokemonName: "Glurak", level: 50)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])
        #expect(diff.evolutions.isEmpty)
        #expect(diff.added.count == 1)
        #expect(diff.removed.count == 1)
    }

    @Test func teamDiff_mixedEvolutionAndNewPokemon() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Previous: Glumanda + Pikachu
        // Current: Glutexo + Pikachu + Lapras
        let prevGlumanda = TeamMember(pokemonName: "Glumanda", level: 15)
        let prevPikachu = TeamMember(pokemonName: "Pikachu", level: 25)
        let curGlutexo = TeamMember(pokemonName: "Glutexo", level: 25)
        let curPikachu = TeamMember(pokemonName: "Pikachu", level: 30)
        let curLapras = TeamMember(pokemonName: "Lapras", level: 40)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prevGlumanda.session = s1
        prevPikachu.session = s1
        context.insert(prevGlumanda)
        context.insert(prevPikachu)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        curGlutexo.session = s2
        curPikachu.session = s2
        curLapras.session = s2
        context.insert(curGlutexo)
        context.insert(curPikachu)
        context.insert(curLapras)
        try context.save()

        let diff = teamDiff(current: [curGlutexo, curPikachu, curLapras],
                           previous: [prevGlumanda, prevPikachu])

        #expect(diff.evolutions.count == 1) // Glumanda→Glutexo
        #expect(diff.added.count == 1) // Lapras
        #expect(diff.added[0].pokemonName == "Lapras")
        #expect(diff.removed.isEmpty) // Glumanda not "removed" — it evolved
        #expect(diff.levelChanges.count == 1) // Pikachu level change
    }

    @Test func teamDiff_matchKey_isCaseInsensitive() throws {
        // Pins the contract: TeamMember.matchKey lowercases pokemonName, so case-only
        // differences across previous/current must NOT produce add/remove churn.
        let container = try makeContainer()
        let context = container.mainContext
        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        let prev = TeamMember(pokemonName: "PIKACHU", level: 10)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        let current = TeamMember(pokemonName: "Pikachu", level: 12)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])

        #expect(diff.added.isEmpty)
        #expect(diff.removed.isEmpty)
        #expect(diff.evolutions.isEmpty)
        #expect(diff.levelChanges.count == 1)
        #expect(diff.levelChanges[0].delta == 2)
    }
}

// MARK: - TeamDiff plain add/remove/level tests

@Suite(.serialized)
@MainActor
struct TeamDiffPlainTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// Inserts a member into the given context so SwiftData-managed property access is safe.
    private func makeMember(_ name: String, _ level: Int, in context: ModelContext) -> TeamMember {
        let m = TeamMember(pokemonName: name, level: level)
        context.insert(m)
        return m
    }

    @Test func teamDiff_added_whenPreviousIsEmpty() throws {
        let container = try makeContainer()
        let pikachu = makeMember("Pikachu", 5, in: container.mainContext)
        let diff = teamDiff(current: [pikachu], previous: [])
        #expect(diff.added.count == 1)
        #expect(diff.added[0].pokemonName == "Pikachu")
        #expect(diff.removed.isEmpty)
        #expect(diff.levelChanges.isEmpty)
        #expect(diff.evolutions.isEmpty)
    }

    @Test func teamDiff_removed_whenCurrentIsEmpty() throws {
        let container = try makeContainer()
        let pikachu = makeMember("Pikachu", 5, in: container.mainContext)
        let diff = teamDiff(current: [], previous: [pikachu])
        #expect(diff.removed.count == 1)
        #expect(diff.removed[0].pokemonName == "Pikachu")
        #expect(diff.added.isEmpty)
        #expect(diff.levelChanges.isEmpty)
        #expect(diff.evolutions.isEmpty)
    }

    @Test func teamDiff_bothEmpty_returnsEmptyDiff() {
        let diff = teamDiff(current: [], previous: [])
        #expect(diff.added.isEmpty)
        #expect(diff.removed.isEmpty)
        #expect(diff.levelChanges.isEmpty)
        #expect(diff.evolutions.isEmpty)
    }

    @Test func teamDiff_unchangedMember_atSameLevel_producesNoChanges() throws {
        let container = try makeContainer()
        let prev = makeMember("Pikachu", 5, in: container.mainContext)
        let current = makeMember("Pikachu", 5, in: container.mainContext)
        let diff = teamDiff(current: [current], previous: [prev])
        #expect(diff.added.isEmpty)
        #expect(diff.removed.isEmpty)
        #expect(diff.levelChanges.isEmpty)
        #expect(diff.evolutions.isEmpty)
    }

    @Test func teamDiff_levelDecrease_isCapturedAsNegativeDelta() throws {
        // Possible after a softreset or correction; the calculator must not
        // silently drop negative deltas.
        let container = try makeContainer()
        let prev = makeMember("Pikachu", 10, in: container.mainContext)
        let current = makeMember("Pikachu", 7, in: container.mainContext)
        let diff = teamDiff(current: [current], previous: [prev])
        #expect(diff.levelChanges.count == 1)
        #expect(diff.levelChanges[0].delta == -3)
    }
}

// MARK: - TeamDiff computed properties

@Suite(.serialized)
@MainActor
struct TeamDiffPropertiesTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeMember(_ name: String, _ level: Int, in context: ModelContext) -> TeamMember {
        let m = TeamMember(pokemonName: name, level: level)
        context.insert(m)
        return m
    }

    @Test func hasChanges_true_whenAddedNonEmpty() throws {
        let container = try makeContainer()
        let diff = TeamDiff(
            added: [makeMember("Pikachu", 5, in: container.mainContext)],
            removed: [],
            levelChanges: [],
            evolutions: []
        )
        #expect(diff.hasChanges)
        #expect(diff.changeCount == 1)
    }

    @Test func hasChanges_true_whenRemovedNonEmpty() throws {
        let container = try makeContainer()
        let diff = TeamDiff(
            added: [],
            removed: [makeMember("Pikachu", 5, in: container.mainContext)],
            levelChanges: [],
            evolutions: []
        )
        #expect(diff.hasChanges)
        #expect(diff.changeCount == 1)
    }

    @Test func hasChanges_true_whenLevelChangesNonEmpty() throws {
        let container = try makeContainer()
        let member = makeMember("Pikachu", 6, in: container.mainContext)
        let diff = TeamDiff(
            added: [],
            removed: [],
            levelChanges: [TeamDiff.LevelChange(member: member, delta: 1)],
            evolutions: []
        )
        #expect(diff.hasChanges)
        #expect(diff.changeCount == 1)
    }

    @Test func hasChanges_true_whenEvolutionsNonEmpty() throws {
        let container = try makeContainer()
        let from = makeMember("Glumanda", 14, in: container.mainContext)
        let to = makeMember("Glutexo", 16, in: container.mainContext)
        let diff = TeamDiff(
            added: [],
            removed: [],
            levelChanges: [],
            evolutions: [TeamDiff.Evolution(from: from, to: to, levelDelta: 2)]
        )
        #expect(diff.hasChanges)
        #expect(diff.changeCount == 1)
    }

    @Test func hasChanges_false_whenAllCategoriesEmpty() {
        let diff = TeamDiff(added: [], removed: [], levelChanges: [], evolutions: [])
        #expect(!diff.hasChanges)
        #expect(diff.changeCount == 0)
    }

    @Test func changeCount_sumsAllCategories() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let m = makeMember("Pikachu", 6, in: context)
        let from = makeMember("Glumanda", 14, in: context)
        let to = makeMember("Glutexo", 16, in: context)
        let diff = TeamDiff(
            added: [makeMember("Lapras", 30, in: context),
                    makeMember("Snorlax", 25, in: context)],
            removed: [makeMember("Zubat", 12, in: context)],
            levelChanges: [TeamDiff.LevelChange(member: m, delta: 1)],
            evolutions: [TeamDiff.Evolution(from: from, to: to, levelDelta: 2)]
        )
        #expect(diff.changeCount == 5)
    }
}
