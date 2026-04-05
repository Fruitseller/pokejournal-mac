//
//  GameWindowView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

/// Standalone window that shows a single game's detail view.
/// Opened via context menu "In neuem Fenster öffnen".
struct GameWindowView: View {
    let gameName: String

    @Query private var games: [Game]

    private var game: Game? {
        games.first { $0.name == gameName }
    }

    var body: some View {
        NavigationStack {
            if let game {
                GameDetailView(game: game)
            } else {
                ContentUnavailableView(
                    "Spiel nicht gefunden",
                    systemImage: "questionmark.circle",
                    description: Text(gameName)
                )
            }
        }
    }

    init(gameName: String) {
        self.gameName = gameName
        _games = Query(filter: #Predicate { $0.name == gameName })
    }
}
