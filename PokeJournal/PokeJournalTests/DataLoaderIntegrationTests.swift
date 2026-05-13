//
//  DataLoaderIntegrationTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

@Suite(.serialized)
@MainActor
struct DataLoaderIntegrationTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeTempVaultURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("DataLoaderIntegration-\(UUID().uuidString)")
    }

    /// Writes `content` to `root/relativePath`, creating intermediate directories.
    private func writeFile(_ content: String, at relativePath: String, in root: URL) throws {
        let url = root.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Builds a VaultManager pointing at `root` and a DataLoader wired to it.
    private func makeLoader(rootedAt root: URL) -> (DataLoader, VaultManager) {
        let manager = VaultManager(testVaultURL: root)
        let loader = DataLoader(vaultManager: manager)
        return (loader, manager)
    }

    // MARK: - Happy path: full test vault fixture

    @Test func loadGames_materializedFixture_loadsAllGames() async throws {
        let root = makeTempVaultURL()
        defer { try? FileManager.default.removeItem(at: root) }
        try TestVaultFixture.materialize(into: root)

        let container = try makeContainer()
        let (loader, _) = makeLoader(rootedAt: root)

        await loader.loadGames(into: container.mainContext)

        #expect(loader.error == nil)
        #expect(loader.isLoading == false)

        let games = try container.mainContext.fetch(FetchDescriptor<Game>())
        let names = Set(games.map(\.name))
        #expect(names.contains("testrot"))
        #expect(names.contains("testlegacy"))
        #expect(names.contains("testsmaragd"))
    }

    @Test func loadGames_newFormat_populatesSessionsAndTeam() async throws {
        let root = makeTempVaultURL()
        defer { try? FileManager.default.removeItem(at: root) }
        try TestVaultFixture.materialize(into: root)

        let container = try makeContainer()
        let (loader, _) = makeLoader(rootedAt: root)

        await loader.loadGames(into: container.mainContext)

        let games = try container.mainContext.fetch(FetchDescriptor<Game>())
        let rot = try #require(games.first { $0.name == "testrot" })

        // testrot fixture defines 3 session files
        #expect(rot.sessions.count == 3)
        // YAML frontmatter must have been parsed
        #expect(rot.genre == "RPG")
        #expect(rot.metacriticScore == 85)
        #expect(rot.aliases.contains(where: { $0.contains("Rot") }))
        // Each session should have at least one team member
        #expect(rot.sessions.allSatisfy { !$0.team.isEmpty })
        // filePath points back at a session .md inside the vault
        #expect(rot.sessions.allSatisfy { $0.filePath.contains(root.path) })
    }

    @Test func loadGames_oldFormat_populatesOldSessions() async throws {
        let root = makeTempVaultURL()
        defer { try? FileManager.default.removeItem(at: root) }
        try TestVaultFixture.materialize(into: root)

        let container = try makeContainer()
        let (loader, _) = makeLoader(rootedAt: root)

        await loader.loadGames(into: container.mainContext)

        let games = try container.mainContext.fetch(FetchDescriptor<Game>())
        let legacy = try #require(games.first { $0.name == "testlegacy" })

        // Old-format game uses `## YYYY-MM-DD` headers; fixture defines 2 inline entries
        #expect(legacy.oldSessions.count == 2)
        #expect(legacy.sessions.isEmpty)
        #expect(legacy.oldSessions.allSatisfy { !$0.team.isEmpty })
    }

    // MARK: - Directory layout edge cases

    @Test func loadGames_oldPrefixedFiles_areSkipped() async throws {
        let root = makeTempVaultURL()
        defer { try? FileManager.default.removeItem(at: root) }

        // `old_<game>.md` files at the pokemon folder root are companion files for the
        // new-format game, not standalone games. They must NOT produce their own Game row.
        let subpath = "hobbies/videospiele/pokemon"
        try writeFile("""
        ---
        aliases: [Companion]
        genre: RPG
        ---
        """, at: "\(subpath)/somegame/somegame.md", in: root)
        try writeFile("""
        ---
        aliases: [Old Companion]
        genre: RPG
        ---

        ## 2024-01-01
        Legacy entry.

        Team:
        - Pikachu lvl 5
        """, at: "\(subpath)/old_somegame.md", in: root)

        let container = try makeContainer()
        let (loader, _) = makeLoader(rootedAt: root)

        await loader.loadGames(into: container.mainContext)

        let games = try container.mainContext.fetch(FetchDescriptor<Game>())
        // Exactly one game — `old_somegame.md` did not get its own entry.
        #expect(games.count == 1)
        let game = try #require(games.first)
        #expect(game.name == "somegame")
        // …and the legacy file was loaded as oldSessions on the new-format game.
        #expect(game.oldSessions.count == 1)
    }

    @Test func loadGames_sessionWithoutDateInFilename_isSkipped() async throws {
        let root = makeTempVaultURL()
        defer { try? FileManager.default.removeItem(at: root) }

        let subpath = "hobbies/videospiele/pokemon"
        try writeFile("""
        ---
        genre: RPG
        ---
        """, at: "\(subpath)/datelessgame/datelessgame.md", in: root)
        // Session file without a parseable YYYY-MM-DD in the filename.
        try writeFile("""
        ## Aktivitäten
        Filler.

        ## Team
        - Pikachu lvl 1
        """, at: "\(subpath)/datelessgame/sessions/notes.md", in: root)
        // A second one WITH a date that should still load.
        try writeFile("""
        ## Aktivitäten
        Real.

        ## Team
        - Pikachu lvl 5
        """, at: "\(subpath)/datelessgame/sessions/2024-06-01_notes.md", in: root)

        let container = try makeContainer()
        let (loader, _) = makeLoader(rootedAt: root)

        await loader.loadGames(into: container.mainContext)

        let game = try #require(
            try container.mainContext.fetch(FetchDescriptor<Game>())
                .first { $0.name == "datelessgame" }
        )
        // Only the dated file becomes a Session.
        #expect(game.sessions.count == 1)
    }

    @Test func loadGames_repeatedLoadWithoutClear_duplicatesRows() async throws {
        // Running loadGames twice without clearing is realistic on app foregrounding.
        // We don't currently dedupe — this test pins today's behaviour so the next
        // person to change it sees the contract break.
        let root = makeTempVaultURL()
        defer { try? FileManager.default.removeItem(at: root) }
        try TestVaultFixture.materialize(into: root)

        let container = try makeContainer()
        let (loader, _) = makeLoader(rootedAt: root)

        await loader.loadGames(into: container.mainContext)
        let firstCount = try container.mainContext.fetch(FetchDescriptor<Game>()).count
        #expect(firstCount > 0)

        await loader.loadGames(into: container.mainContext)
        let secondCount = try container.mainContext.fetch(FetchDescriptor<Game>()).count

        // Loading twice in a row without clear duplicates rows — this is the contract
        // that `reloadData` exists to manage. If this changes, reloadData logic likely
        // needs revisiting too.
        #expect(secondCount == firstCount * 2)
    }

    // MARK: - Error paths

    @Test func loadGames_withoutVaultAccess_setsError() async throws {
        // Bootstrap init without `-UseTestVault YES` leaves vaultURL nil, so
        // startAccessingVault() returns false. No global state is touched.
        let manager = VaultManager(
            arguments: ["app"],
            containerRoot: FileManager.default.temporaryDirectory,
            materializer: { _ in }
        )

        let container = try makeContainer()
        let loader = DataLoader(vaultManager: manager)

        await loader.loadGames(into: container.mainContext)

        #expect(loader.error == "Kein Zugriff auf Vault")
        // No games inserted.
        let games = try container.mainContext.fetch(FetchDescriptor<Game>())
        #expect(games.isEmpty)
    }

    @Test func loadGames_missingPokemonFolder_setsError() async throws {
        // Vault root exists but the `hobbies/videospiele/pokemon` subfolder does not.
        let root = makeTempVaultURL()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let container = try makeContainer()
        let (loader, _) = makeLoader(rootedAt: root)

        await loader.loadGames(into: container.mainContext)

        // pokemonFolderURL exists as a path but FileManager.contentsOfDirectory throws.
        #expect(loader.error != nil)
        #expect(loader.error?.contains("Fehler beim Laden") == true)
        let games = try container.mainContext.fetch(FetchDescriptor<Game>())
        #expect(games.isEmpty)
    }

    // MARK: - reloadData preserves hidden state

    @Test func reloadData_preservesHiddenFlag_byFilePath() async throws {
        let root = makeTempVaultURL()
        defer { try? FileManager.default.removeItem(at: root) }
        try TestVaultFixture.materialize(into: root)

        let container = try makeContainer()
        let (loader, _) = makeLoader(rootedAt: root)

        // Initial load
        await loader.loadGames(into: container.mainContext)
        let games = try container.mainContext.fetch(FetchDescriptor<Game>())
        let rot = try #require(games.first { $0.name == "testrot" })
        rot.isHidden = true
        try container.mainContext.save()
        let hiddenFilePath = rot.filePath

        // Full reload: clear + load + restoreHiddenState
        await loader.reloadData(context: container.mainContext)

        let reloaded = try container.mainContext.fetch(FetchDescriptor<Game>())
        let rotAgain = try #require(reloaded.first { $0.filePath == hiddenFilePath })
        #expect(rotAgain.isHidden == true)
        // Other games were not silently hidden.
        let others = reloaded.filter { $0.filePath != hiddenFilePath }
        #expect(others.allSatisfy { !$0.isHidden })
    }

    @Test func hiddenGamePaths_returnsOnlyHiddenFilePaths() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let visible = Game(name: "a", filePath: "/a.md")
        let hidden = Game(name: "b", filePath: "/b.md")
        hidden.isHidden = true
        context.insert(visible)
        context.insert(hidden)
        try context.save()

        let loader = DataLoader(vaultManager: VaultManager(testVaultURL: URL(fileURLWithPath: "/tmp")))
        let paths = loader.hiddenGamePaths(context: context)
        #expect(paths == ["/b.md"])
    }

    @Test func restoreHiddenState_emptySet_noop() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "a", filePath: "/a.md")
        context.insert(game)
        try context.save()

        let loader = DataLoader(vaultManager: VaultManager(testVaultURL: URL(fileURLWithPath: "/tmp")))
        loader.restoreHiddenState(hiddenPaths: [], context: context)

        #expect(game.isHidden == false)
    }
}
