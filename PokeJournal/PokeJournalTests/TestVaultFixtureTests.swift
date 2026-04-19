//
//  TestVaultFixtureTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
@testable import PokeJournal

struct TestVaultFixtureTests {

    private func makeTempURL() -> URL {
        let base = FileManager.default.temporaryDirectory
        return base.appendingPathComponent("TestVaultFixture-\(UUID().uuidString)")
    }

    @Test func materialize_createsPokemonFolder() throws {
        let root = makeTempURL()
        defer { try? FileManager.default.removeItem(at: root) }

        try TestVaultFixture.materialize(into: root)

        let pokemon = root.appendingPathComponent("hobbies/videospiele/pokemon")
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: pokemon.path, isDirectory: &isDir))
        #expect(isDir.boolValue)
    }

    @Test func materialize_createsNewFormatGameFile() throws {
        let root = makeTempURL()
        defer { try? FileManager.default.removeItem(at: root) }

        try TestVaultFixture.materialize(into: root)

        let gameFile = root.appendingPathComponent("hobbies/videospiele/pokemon/testrot/testrot.md")
        #expect(FileManager.default.fileExists(atPath: gameFile.path))

        let content = try String(contentsOf: gameFile, encoding: .utf8)
        let metadata = MarkdownParser.shared.parseYAMLFrontmatter(from: content)
        #expect(metadata.aliases.contains(where: { $0.contains("Test") }))
        #expect(metadata.genre == "RPG")
    }

    @Test func materialize_createsThreeSessionFiles() throws {
        let root = makeTempURL()
        defer { try? FileManager.default.removeItem(at: root) }

        try TestVaultFixture.materialize(into: root)

        let sessions = root.appendingPathComponent("hobbies/videospiele/pokemon/testrot/sessions")
        let contents = try FileManager.default.contentsOfDirectory(
            at: sessions,
            includingPropertiesForKeys: nil
        )
        let markdownFiles = contents.filter { $0.pathExtension == "md" }
        #expect(markdownFiles.count == 3)
    }

    @Test func materialize_sessionFileHasParseableTeam() throws {
        let root = makeTempURL()
        defer { try? FileManager.default.removeItem(at: root) }

        try TestVaultFixture.materialize(into: root)

        let sessions = root.appendingPathComponent("hobbies/videospiele/pokemon/testrot/sessions")
        let firstSession = try FileManager.default
            .contentsOfDirectory(at: sessions, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "md" }
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            .first!

        let content = try String(contentsOf: firstSession, encoding: .utf8)
        let (_, _, _, team) = MarkdownParser.shared.parseSessionSections(from: content)
        #expect(!team.isEmpty)
    }

    @Test func materialize_createsOldFormatGame() throws {
        let root = makeTempURL()
        defer { try? FileManager.default.removeItem(at: root) }

        try TestVaultFixture.materialize(into: root)

        let oldFile = root.appendingPathComponent("hobbies/videospiele/pokemon/testlegacy.md")
        #expect(FileManager.default.fileExists(atPath: oldFile.path))

        let content = try String(contentsOf: oldFile, encoding: .utf8)
        let sessions = MarkdownParser.shared.parseOldFormatSessions(from: content, sourceFile: oldFile.path)
        #expect(sessions.count >= 2)
    }

    @Test func materialize_isIdempotent() throws {
        let root = makeTempURL()
        defer { try? FileManager.default.removeItem(at: root) }

        try TestVaultFixture.materialize(into: root)
        try TestVaultFixture.materialize(into: root)

        let gameFile = root.appendingPathComponent("hobbies/videospiele/pokemon/testrot/testrot.md")
        #expect(FileManager.default.fileExists(atPath: gameFile.path))
    }
}

struct VaultManagerTestVaultModeTests {

    @Test func testVaultURL_nilWithoutArgument() {
        let root = URL(fileURLWithPath: "/tmp/app-support")
        let url = VaultManager.testVaultURL(from: ["path/to/app"], containerRoot: root)
        #expect(url == nil)
    }

    @Test func testVaultURL_nilWhenValueIsNo() {
        let root = URL(fileURLWithPath: "/tmp/app-support")
        let url = VaultManager.testVaultURL(from: ["app", "-UseTestVault", "NO"], containerRoot: root)
        #expect(url == nil)
    }

    @Test func testVaultURL_nilWhenMissingValue() {
        let root = URL(fileURLWithPath: "/tmp/app-support")
        let url = VaultManager.testVaultURL(from: ["app", "-UseTestVault"], containerRoot: root)
        #expect(url == nil)
    }

    @Test func testVaultURL_returnsContainerRootSubfolder() {
        let root = URL(fileURLWithPath: "/tmp/app-support")
        let url = VaultManager.testVaultURL(from: ["app", "-UseTestVault", "YES"], containerRoot: root)
        #expect(url == root.appendingPathComponent("TestVault"))
    }

    @Test @MainActor func testVaultInit_setsFlagsAndURL() {
        let url = URL(fileURLWithPath: "/tmp/fake-test-vault")
        let manager = VaultManager(testVaultURL: url)
        #expect(manager.isTestVault)
        #expect(manager.vaultURL == url)
        #expect(manager.hasVaultAccess)
    }

    @Test @MainActor func startAccessingVault_testVault_returnsTrueWithoutSecurityScope() {
        let url = URL(fileURLWithPath: "/tmp/fake-test-vault")
        let manager = VaultManager(testVaultURL: url)

        let ok = manager.startAccessingVault()

        #expect(ok)
        #expect(manager.isAccessingVault)
    }

    @Test @MainActor func stopAccessingVault_testVault_clearsAccessingFlag() {
        let url = URL(fileURLWithPath: "/tmp/fake-test-vault")
        let manager = VaultManager(testVaultURL: url)
        _ = manager.startAccessingVault()

        manager.stopAccessingVault()

        #expect(!manager.isAccessingVault)
    }

    @Test @MainActor func stopAccessingVault_noop_whenNotAccessing() {
        let url = URL(fileURLWithPath: "/tmp/fake-test-vault")
        let manager = VaultManager(testVaultURL: url)

        manager.stopAccessingVault()

        #expect(!manager.isAccessingVault)
    }

    // MARK: - Bootstrap integration (tryBootstrapTestVault via init)

    @Test @MainActor func bootstrap_withTestVaultArg_setsFlagAndURL() {
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent("VaultBootstrap-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: container) }

        var materializedURL: URL?
        let manager = VaultManager(
            arguments: ["app", "-UseTestVault", "YES"],
            containerRoot: container,
            materializer: { url in materializedURL = url }
        )

        #expect(manager.isTestVault)
        #expect(manager.vaultURL == container.appendingPathComponent("TestVault"))
        #expect(materializedURL == container.appendingPathComponent("TestVault"))
    }

    @Test @MainActor func bootstrap_withoutTestVaultArg_leavesFlagFalse() {
        let container = FileManager.default.temporaryDirectory
        let manager = VaultManager(
            arguments: ["app"],
            containerRoot: container,
            materializer: { _ in Issue.record("materializer should not be called") }
        )

        #expect(!manager.isTestVault)
        #expect(manager.vaultURL == nil)
    }

    @Test @MainActor func bootstrap_whenMaterializerThrows_leavesFlagFalse() {
        struct BoomError: Error {}
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent("VaultBootstrap-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: container) }

        let manager = VaultManager(
            arguments: ["app", "-UseTestVault", "YES"],
            containerRoot: container,
            materializer: { _ in throw BoomError() }
        )

        #expect(!manager.isTestVault)
        #expect(manager.vaultURL == nil)
    }
}
