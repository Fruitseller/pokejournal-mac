//
//  VaultManager.swift
//  PokéJournal
//

import Foundation
import AppKit

@Observable
final class VaultManager {
    static let shared = VaultManager()

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
            print("Failed to create bookmark: \(error)")
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
            print("Failed to resolve bookmark: \(error)")
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
}
