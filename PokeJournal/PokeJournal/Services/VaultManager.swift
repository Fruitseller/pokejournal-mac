//
//  VaultManager.swift
//  PokéJournal
//

import Foundation
import AppKit
import OSLog

@Observable
final class VaultManager {
    static let shared = VaultManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "io.github.fruitseller.pokejournal",
        category: "VaultManager"
    )
    private let bookmarkKey = "vaultBookmarkData"
    private let pokemonSubpath = "hobbies/videospiele/pokemon"

    private(set) var vaultURL: URL?
    private(set) var isAccessingVault = false

    var pokemonFolderURL: URL? {
        vaultURL?.appendingPathComponent(pokemonSubpath)
    }

    var hasVaultAccess: Bool {
        vaultURL != nil
    }

    var vaultName: String? {
        vaultURL?.lastPathComponent
    }

    private init() {
        restoreBookmark()
    }

    func selectVault() {
        let panel = NSOpenPanel()
        panel.title = "Obsidian Vault auswählen"
        panel.message = "Bitte wähle deinen Obsidian Vault-Ordner aus"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            saveBookmark(for: url)
            vaultURL = url
        }
    }

    private func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
        } catch {
            logger.error("Failed to create bookmark: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func restoreBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                saveBookmark(for: url)
            }

            vaultURL = url
        } catch {
            logger.error("Failed to resolve bookmark: \(error.localizedDescription, privacy: .public)")
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }

    func startAccessingVault() -> Bool {
        guard let url = vaultURL else { return false }

        if url.startAccessingSecurityScopedResource() {
            isAccessingVault = true
            return true
        }
        return false
    }

    func stopAccessingVault() {
        guard isAccessingVault, let url = vaultURL else { return }
        url.stopAccessingSecurityScopedResource()
        isAccessingVault = false
    }

    func clearVault() {
        stopAccessingVault()
        vaultURL = nil
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    /// Converts an absolute file path to a vault-relative path for use in Obsidian URLs.
    static func vaultRelativePath(absolutePath: String, vaultPath: String) -> String {
        let normalized = vaultPath.hasSuffix("/") ? String(vaultPath.dropLast()) : vaultPath
        guard absolutePath.hasPrefix(normalized) else { return absolutePath }
        var relative = String(absolutePath.dropFirst(normalized.count))
        if relative.hasPrefix("/") {
            relative = String(relative.dropFirst())
        }
        return relative
    }

    static func obsidianURL(vaultName: String, filePath: String, vaultPath: String) -> URL? {
        let relativePath = vaultRelativePath(absolutePath: filePath, vaultPath: vaultPath)
        var components = URLComponents()
        components.scheme = "obsidian"
        components.host = "open"
        components.queryItems = [
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "file", value: relativePath)
        ]
        return components.url
    }

    func obsidianURL(forFilePath filePath: String) -> URL? {
        guard let vaultName, let vaultPath = vaultURL?.path else { return nil }
        return Self.obsidianURL(vaultName: vaultName, filePath: filePath, vaultPath: vaultPath)
    }
}
