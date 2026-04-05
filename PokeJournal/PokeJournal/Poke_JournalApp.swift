//
//  Poke_JournalApp.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

@main
struct Poke_JournalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self,
            Session.self,
            OldSession.self,
            TeamMember.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            AppCommands()
        }

        // Standalone game windows opened via context menu
        WindowGroup("Spiel", id: "game", for: String.self) { $gameName in
            if let name = gameName {
                GameWindowView(gameName: name)
                    .modelContainer(sharedModelContainer)
            }
        }
        .defaultSize(width: 960, height: 720)

        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
    }
}
