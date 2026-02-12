//
//  GameListView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct GameListView: View {
    @Query(sort: \Game.name) private var games: [Game]
    @Binding var selectedGame: Game?

    var body: some View {
        List(selection: $selectedGame) {
            ForEach(games) { game in
                GameRowView(game: game)
                    .tag(game)
                    .accessibilityIdentifier("gameRow_\(game.name)")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Spiele")
        .accessibilityIdentifier("gameList")
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
