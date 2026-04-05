//
//  GameListView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct GameListView: View {
    @Query(sort: \Game.name) private var games: [Game]
    @Binding var selectedGame: Game?

    private var filteredGames: [Game] {
        games.filter { !$0.isHidden && Game.isRPGGenre($0.genre) }
    }

    var body: some View {
        List(selection: $selectedGame) {
            ForEach(filteredGames) { game in
                GameRowView(game: game)
                    .tag(game)
                    .accessibilityIdentifier("gameRow_\(game.name)")
                    .contextMenu {
                        Button("Ausblenden") {
                            game.isHidden = true
                            if selectedGame == game {
                                selectedGame = nil
                            }
                        }
                        .accessibilityIdentifier("hideGame_\(game.name)")
                    }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if filteredGames.isEmpty {
                ContentUnavailableView(
                    "Keine Spiele",
                    systemImage: "gamecontroller",
                    description: Text("Alle Spiele sind ausgeblendet oder keine RPGs vorhanden.")
                )
            }
        }
        .navigationTitle("Spiele")
        .accessibilityIdentifier("gameList")
        .onChange(of: filteredGames) {
            if let selectedGame, !filteredGames.contains(selectedGame) {
                self.selectedGame = nil
            }
        }
    }
}

struct GameRowView: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(game.displayName)
                .font(.headline)

            HStack(spacing: 8) {
                Label("\(game.totalSessionCount)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let lastPlayed = game.lastPlayedDate {
                    Text(lastPlayed, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GameListView(selectedGame: .constant(nil))
        .modelContainer(for: Game.self, inMemory: true)
}
