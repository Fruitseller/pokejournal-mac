//
//  DataLoader.swift
//  PokéJournal
//

import Foundation
import SwiftData

@Observable
final class DataLoader {
    private let parser = MarkdownParser.shared
    private let vaultManager = VaultManager.shared

    var isLoading = false
    var error: String?

    func loadGames(into context: ModelContext) async {
        guard vaultManager.startAccessingVault() else {
            error = "Kein Zugriff auf Vault"
            return
        }

        defer { vaultManager.stopAccessingVault() }

        guard let pokemonFolder = vaultManager.pokemonFolderURL else {
            error = "Pokemon-Ordner nicht gefunden"
            return
        }

        isLoading = true
        error = nil

        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(
                at: pokemonFolder,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for item in contents {
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory)

                if isDirectory.boolValue {
                    // New format: pokemon/[gamename]/[gamename].md
                    let gameName = item.lastPathComponent
                    let gameFile = item.appendingPathComponent("\(gameName).md")

                    if fileManager.fileExists(atPath: gameFile.path) {
                        try await loadGame(from: gameFile, named: gameName, in: pokemonFolder, context: context)
                    }
                } else if item.pathExtension == "md" {
                    // Old format: pokemon/[gamename].md with inline sessions
                    let filename = item.deletingPathExtension().lastPathComponent

                    if filename.hasPrefix("old_") {
                        continue
                    }

                    try await loadGameOldFormat(from: item, named: filename, in: pokemonFolder, context: context)
                }
            }

            try context.save()
        } catch {
            self.error = "Fehler beim Laden: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // New format: Game in subdirectory with separate session files
    private func loadGame(from url: URL, named name: String, in folder: URL, context: ModelContext) async throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let metadata = parser.parseYAMLFrontmatter(from: content)

        let game = Game(name: name, filePath: url.path)
        game.aliases = metadata.aliases
        game.releaseDate = metadata.releaseDate
        game.platforms = metadata.platforms
        game.genre = metadata.genre
        game.developer = metadata.developer
        game.metacriticScore = metadata.metacriticScore

        context.insert(game)

        // Load sessions from sessions/ subfolder
        let sessionsFolder = folder.appendingPathComponent("\(name)/sessions")
        if FileManager.default.fileExists(atPath: sessionsFolder.path) {
            try loadSessions(for: game, from: sessionsFolder, context: context)
        }

        // Load old sessions from old_[gamename].md file
        let oldSessionsFile = folder.appendingPathComponent("old_\(name).md")
        if FileManager.default.fileExists(atPath: oldSessionsFile.path) {
            try loadOldSessions(for: game, from: oldSessionsFile, context: context)
        }
    }

    // Old format: Game .md file directly in pokemon folder with inline sessions
    private func loadGameOldFormat(from url: URL, named name: String, in folder: URL, context: ModelContext) async throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let metadata = parser.parseYAMLFrontmatter(from: content)

        let game = Game(name: name, filePath: url.path)
        game.aliases = metadata.aliases
        game.releaseDate = metadata.releaseDate
        game.platforms = metadata.platforms
        game.genre = metadata.genre
        game.developer = metadata.developer
        game.metacriticScore = metadata.metacriticScore

        context.insert(game)

        // Parse inline sessions from the game file itself (## YYYY-MM-DD format)
        let parsedSessions = parser.parseOldFormatSessions(from: content, sourceFile: url.path)

        for parsed in parsedSessions {
            let oldSession = OldSession(
                date: parsed.date,
                activities: parsed.activities,
                plans: parsed.plans,
                thoughts: parsed.thoughts,
                sourceFile: url.path
            )
            oldSession.game = game

            for (index, member) in parsed.team.enumerated() {
                let teamMember = TeamMember(
                    pokemonName: member.name,
                    level: member.level,
                    variant: member.variant
                )
                teamMember.order = index
                teamMember.oldSession = oldSession
                oldSession.team.append(teamMember)
                context.insert(teamMember)
            }

            game.oldSessions.append(oldSession)
            context.insert(oldSession)
        }
    }

    private func loadSessions(for game: Game, from folder: URL, context: ModelContext) throws {
        let contents = try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for file in contents where file.pathExtension == "md" {
            guard let date = parser.parseDateFromFilename(file.lastPathComponent) else {
                continue
            }

            let content = try String(contentsOf: file, encoding: .utf8)
            let (activities, plans, thoughts, teamMembers) = parser.parseSessionSections(from: content)

            let session = Session(
                date: date,
                activities: activities,
                plans: plans,
                thoughts: thoughts,
                filePath: file.path
            )
            session.game = game

            for (index, member) in teamMembers.enumerated() {
                let teamMember = TeamMember(
                    pokemonName: member.name,
                    level: member.level,
                    variant: member.variant
                )
                teamMember.order = index
                teamMember.session = session
                session.team.append(teamMember)
                context.insert(teamMember)
            }

            game.sessions.append(session)
            context.insert(session)
        }
    }

    private func loadOldSessions(for game: Game, from file: URL, context: ModelContext) throws {
        let content = try String(contentsOf: file, encoding: .utf8)
        let parsedSessions = parser.parseOldFormatSessions(from: content, sourceFile: file.path)

        for parsed in parsedSessions {
            let oldSession = OldSession(
                date: parsed.date,
                activities: parsed.activities,
                plans: parsed.plans,
                thoughts: parsed.thoughts,
                sourceFile: file.path
            )
            oldSession.game = game

            for (index, member) in parsed.team.enumerated() {
                let teamMember = TeamMember(
                    pokemonName: member.name,
                    level: member.level,
                    variant: member.variant
                )
                teamMember.order = index
                teamMember.oldSession = oldSession
                oldSession.team.append(teamMember)
                context.insert(teamMember)
            }

            game.oldSessions.append(oldSession)
            context.insert(oldSession)
        }
    }

    func clearAllData(context: ModelContext) {
        do {
            let games = try context.fetch(FetchDescriptor<Game>())
            for game in games {
                context.delete(game)
            }
        } catch {
            self.error = "Fehler beim Löschen: \(error.localizedDescription)"
        }
    }

    func reloadData(context: ModelContext) async {
        let hiddenPaths = hiddenGamePaths(context: context)
        clearAllData(context: context)
        await loadGames(into: context)
        restoreHiddenState(hiddenPaths: hiddenPaths, context: context)
    }

    func hiddenGamePaths(context: ModelContext) -> Set<String> {
        do {
            let games = try context.fetch(FetchDescriptor<Game>())
            return Set(games.filter(\.isHidden).map(\.filePath))
        } catch {
            return []
        }
    }

    func restoreHiddenState(hiddenPaths: Set<String>, context: ModelContext) {
        guard !hiddenPaths.isEmpty else { return }
        do {
            let games = try context.fetch(FetchDescriptor<Game>())
            for game in games where hiddenPaths.contains(game.filePath) {
                game.isHidden = true
            }
        } catch {
            // Non-critical: hidden state lost on reload is acceptable
        }
    }
}
