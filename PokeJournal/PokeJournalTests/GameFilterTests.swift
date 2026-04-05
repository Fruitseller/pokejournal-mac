//
//  GameFilterTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

// MARK: - Genre Filter Tests

struct GameGenreFilterTests {

    @Test func nilGenre_isRPG() {
        #expect(Game.isRPGGenre(nil) == true)
    }

    @Test func rollenspiel_isRPG() {
        #expect(Game.isRPGGenre("Rollenspiel") == true)
    }

    @Test func rpg_isRPG() {
        #expect(Game.isRPGGenre("RPG") == true)
    }

    @Test func jrpg_isRPG() {
        #expect(Game.isRPGGenre("JRPG") == true)
    }

    @Test func actionRPG_isRPG() {
        #expect(Game.isRPGGenre("Action-RPG") == true)
    }

    @Test func caseInsensitive() {
        #expect(Game.isRPGGenre("rollenspiel") == true)
        #expect(Game.isRPGGenre("rpg") == true)
        #expect(Game.isRPGGenre("ROLLENSPIEL") == true)
    }

    @Test func nonRPG_genres() {
        #expect(Game.isRPGGenre("Strategie") == false)
        #expect(Game.isRPGGenre("Puzzle") == false)
        #expect(Game.isRPGGenre("Action") == false)
        #expect(Game.isRPGGenre("MOBA") == false)
    }

    @Test func emptyString_treatedAsNoGenre() {
        #expect(Game.isRPGGenre("") == true)
    }
}

// MARK: - Visibility Filter Tests

@Suite(.serialized)
@MainActor
struct GameVisibilityFilterTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func isHidden_defaultsFalse() throws {
        let container = try makeContainer()
        let game = Game(name: "test", filePath: "/test.md")
        container.mainContext.insert(game)
        try container.mainContext.save()
        #expect(game.isHidden == false)
    }

    @Test func filter_excludesHiddenGames() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let visible = Game(name: "visible", filePath: "/visible.md")
        let hidden = Game(name: "hidden", filePath: "/hidden.md")
        hidden.isHidden = true
        ctx.insert(visible)
        ctx.insert(hidden)
        try ctx.save()

        let filtered = [visible, hidden].filter { !$0.isHidden && Game.isRPGGenre($0.genre) }
        #expect(filtered.count == 1)
        #expect(filtered[0].name == "visible")
    }

    @Test func filter_excludesNonRPGGenre() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let rpg = Game(name: "rpg", filePath: "/rpg.md")
        rpg.genre = "Rollenspiel"
        let puzzle = Game(name: "puzzle", filePath: "/puzzle.md")
        puzzle.genre = "Puzzle"
        let noGenre = Game(name: "old", filePath: "/old.md")

        ctx.insert(rpg)
        ctx.insert(puzzle)
        ctx.insert(noGenre)
        try ctx.save()

        let filtered = [rpg, puzzle, noGenre].filter { !$0.isHidden && Game.isRPGGenre($0.genre) }
        #expect(filtered.count == 2)
        #expect(filtered.contains(where: { $0.name == "rpg" }))
        #expect(filtered.contains(where: { $0.name == "old" }))
    }

    @Test func unhide_gameReappearsInFilteredList() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let game = Game(name: "test", filePath: "/test.md")
        game.genre = "Rollenspiel"
        game.isHidden = true
        ctx.insert(game)
        try ctx.save()

        // Hidden: excluded from filtered list
        var filtered = [game].filter { !$0.isHidden && Game.isRPGGenre($0.genre) }
        #expect(filtered.isEmpty)

        // Unhide: reappears
        game.isHidden = false
        filtered = [game].filter { !$0.isHidden && Game.isRPGGenre($0.genre) }
        #expect(filtered.count == 1)
        #expect(filtered[0].name == "test")
    }

    @Test func filter_hiddenAndNonRPG_bothExcluded() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let hiddenRPG = Game(name: "hiddenRPG", filePath: "/a.md")
        hiddenRPG.genre = "RPG"
        hiddenRPG.isHidden = true

        let visiblePuzzle = Game(name: "puzzle", filePath: "/b.md")
        visiblePuzzle.genre = "Puzzle"

        let visibleRPG = Game(name: "visibleRPG", filePath: "/c.md")
        visibleRPG.genre = "Rollenspiel"

        ctx.insert(hiddenRPG)
        ctx.insert(visiblePuzzle)
        ctx.insert(visibleRPG)
        try ctx.save()

        let all = [hiddenRPG, visiblePuzzle, visibleRPG]
        let filtered = all.filter { !$0.isHidden && Game.isRPGGenre($0.genre) }
        #expect(filtered.count == 1)
        #expect(filtered[0].name == "visibleRPG")
    }
}

// MARK: - Hidden State Preservation Tests

@Suite(.serialized)
@MainActor
struct HiddenStatePreservationTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func hiddenPaths_surviveClearAndReinsert() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let loader = DataLoader()

        let visible = Game(name: "visible", filePath: "/pokemon/visible/visible.md")
        let hidden = Game(name: "hidden", filePath: "/pokemon/hidden/hidden.md")
        hidden.isHidden = true
        ctx.insert(visible)
        ctx.insert(hidden)
        try ctx.save()

        let hiddenPaths = loader.hiddenGamePaths(context: ctx)
        #expect(hiddenPaths.count == 1)
        #expect(hiddenPaths.contains("/pokemon/hidden/hidden.md"))

        // Clear and re-insert
        loader.clearAllData(context: ctx)

        let visible2 = Game(name: "visible", filePath: "/pokemon/visible/visible.md")
        let hidden2 = Game(name: "hidden", filePath: "/pokemon/hidden/hidden.md")
        ctx.insert(visible2)
        ctx.insert(hidden2)
        try ctx.save()

        loader.restoreHiddenState(hiddenPaths: hiddenPaths, context: ctx)

        let reloaded = try ctx.fetch(FetchDescriptor<Game>())
        let stillHidden = reloaded.filter(\.isHidden)
        #expect(stillHidden.count == 1)
        #expect(stillHidden[0].name == "hidden")
    }
}
