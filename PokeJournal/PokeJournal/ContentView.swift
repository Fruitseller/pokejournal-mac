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
    @State private var dataLoader = DataLoader()
    @SceneStorage("selectedGameName") private var selectedGameName: String?

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
                Task { await dataLoader.reloadData(context: modelContext) }
            }
        }
        .onChange(of: selectedGame) { _, game in
            selectedGameName = game?.name
        }
        .onChange(of: games) { _, newGames in
            if selectedGame == nil, let name = selectedGameName {
                selectedGame = newGames.first { $0.name == name }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        NavigationSplitView {
            GameListView(selectedGame: $selectedGame)
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
        .focusedSceneValue(\.reloadAction, reload)
        .overlay {
            if dataLoader.isLoading {
                ProgressView("Lade Daten...")
                    .padding()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
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

    private func reload() {
        selectedGame = nil
        Task { await dataLoader.reloadData(context: modelContext) }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Game.self, inMemory: true)
}
