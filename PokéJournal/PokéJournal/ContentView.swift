//
//  ContentView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var games: [Game]

    @State private var selectedGame: Game?
    @State private var showSettings = false
    @State private var dataLoader = DataLoader()

    private var vaultManager = VaultManager.shared

    var body: some View {
        Group {
            if vaultManager.hasVaultAccess {
                mainContent
            } else {
                VaultSetupView()
            }
        }
        .task {
            if vaultManager.hasVaultAccess && games.isEmpty {
                await dataLoader.loadGames(into: modelContext)
            }
        }
        .onChange(of: vaultManager.vaultURL) { _, newValue in
            if newValue != nil {
                selectedGame = nil
                Task {
                    await dataLoader.reloadData(context: modelContext)
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        NavigationSplitView {
            GameListView(selectedGame: $selectedGame)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: { showSettings = true }) {
                            Label("Einstellungen", systemImage: "gear")
                        }
                    }

                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            selectedGame = nil
                            Task {
                                await dataLoader.reloadData(context: modelContext)
                            }
                        }) {
                            Label("Aktualisieren", systemImage: "arrow.clockwise")
                        }
                        .disabled(dataLoader.isLoading)
                    }
                }
        } detail: {
            NavigationStack {
                if let game = selectedGame {
                    GameDetailView(game: game)
                } else {
                    ContentUnavailableView(
                        "Kein Spiel ausgewählt",
                        systemImage: "gamecontroller",
                        description: Text("Wähle ein Spiel aus der Seitenleiste")
                    )
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Fertig") {
                                showSettings = false
                            }
                        }
                    }
            }
            .frame(minWidth: 500, minHeight: 400)
        }
        .overlay {
            if dataLoader.isLoading {
                ProgressView("Lade Daten...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Fehler", isPresented: .constant(dataLoader.error != nil)) {
            Button("OK") {
                dataLoader.error = nil
            }
        } message: {
            if let error = dataLoader.error {
                Text(error)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Game.self, inMemory: true)
}
