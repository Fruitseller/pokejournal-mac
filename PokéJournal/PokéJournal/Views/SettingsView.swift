//
//  SettingsView.swift
//  PokéJournal
//

import SwiftUI

enum SpriteStyle: String, CaseIterable {
    case official = "Offizielles Artwork"
    case pixel = "Pixel-Sprites"
}

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Hell"
    case dark = "Dunkel"
}

struct SettingsView: View {
    @Bindable var vaultManager = VaultManager.shared
    @AppStorage("spriteStyle") private var spriteStyle: SpriteStyle = .official
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some View {
        Form {
            Section("Vault") {
                if let vaultURL = vaultManager.vaultURL {
                    LabeledContent("Aktueller Pfad") {
                        Text(vaultURL.path)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    if let pokemonFolder = vaultManager.pokemonFolderURL {
                        LabeledContent("Pokémon-Ordner") {
                            Text(pokemonFolder.path)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }

                    HStack {
                        Button("Vault ändern") {
                            vaultManager.selectVault()
                        }

                        Button("Vault entfernen", role: .destructive) {
                            vaultManager.clearVault()
                        }
                    }
                } else {
                    Text("Kein Vault ausgewählt")
                        .foregroundStyle(.secondary)

                    Button("Vault auswählen") {
                        vaultManager.selectVault()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Darstellung") {
                Picker("Sprite-Stil", selection: $spriteStyle) {
                    ForEach(SpriteStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                Picker("Theme", selection: $appTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
            }

            Section("Über") {
                LabeledContent("Version") {
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Build") {
                    Text("macOS 26")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Einstellungen")
        .frame(minWidth: 400)
    }
}

#Preview {
    SettingsView()
}
