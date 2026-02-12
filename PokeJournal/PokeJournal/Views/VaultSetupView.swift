//
//  VaultSetupView.swift
//  PokéJournal
//

import SwiftUI

struct VaultSetupView: View {
    @Bindable var vaultManager = VaultManager.shared

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Willkommen bei PokéJournal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityIdentifier("welcomeTitle")

            Text("Um deine Pokémon-Sessions anzuzeigen, wähle bitte deinen Obsidian Vault aus.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button(action: {
                vaultManager.selectVault()
            }) {
                Label("Vault auswählen", systemImage: "folder")
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("selectVaultButton")

            Text("Der Pfad zum Pokémon-Ordner sollte sein:\n[Vault]/hobbies/videospiele/pokemon/")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VaultSetupView()
}
