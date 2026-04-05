//
//  AppCommands.swift
//  PokéJournal
//

import SwiftUI

// MARK: - Focused Values

extension FocusedValues {
    @Entry var selectedTab: Binding<Int>? = nil
    @Entry var reloadAction: (() -> Void)? = nil
}

// MARK: - Commands

struct AppCommands: Commands {
    @FocusedSceneValue(\.selectedTab) var selectedTabBinding: Binding<Int>?
    @FocusedSceneValue(\.reloadAction) var reloadAction: (() -> Void)?

    var body: some Commands {
        // Remove "New Window" from File menu — we handle it ourselves via context menu
        CommandGroup(replacing: .newItem) { }

        CommandMenu("Ansicht") {
            Button("Aktualisieren") { reloadAction?() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(reloadAction == nil)

            Divider()

            Button("Sessions") { selectedTabBinding?.wrappedValue = 0 }
                .keyboardShortcut("1", modifiers: .command)
                .disabled(selectedTabBinding == nil)

            Button("Timeline") { selectedTabBinding?.wrappedValue = 1 }
                .keyboardShortcut("2", modifiers: .command)
                .disabled(selectedTabBinding == nil)

            Button("Heatmap") { selectedTabBinding?.wrappedValue = 2 }
                .keyboardShortcut("3", modifiers: .command)
                .disabled(selectedTabBinding == nil)

            Button("Team-Analyse") { selectedTabBinding?.wrappedValue = 3 }
                .keyboardShortcut("4", modifiers: .command)
                .disabled(selectedTabBinding == nil)

            Button("Team-Entwicklung") { selectedTabBinding?.wrappedValue = 4 }
                .keyboardShortcut("5", modifiers: .command)
                .disabled(selectedTabBinding == nil)
        }
    }
}
