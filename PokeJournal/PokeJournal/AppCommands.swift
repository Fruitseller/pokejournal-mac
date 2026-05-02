//
//  AppCommands.swift
//  PokéJournal
//

import SwiftUI

// MARK: - Tabs

enum AppTab: Int, CaseIterable, Identifiable {
    case sessions, timeline, heatmap, hallOfFame, teamEvolution, teamCheck

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sessions:       return "Sessions"
        case .timeline:       return "Timeline"
        case .heatmap:        return "Heatmap"
        case .hallOfFame:     return "Hall of Fame"
        case .teamEvolution:  return "Team-Entwicklung"
        case .teamCheck:      return "Team-Check"
        }
    }

    /// The Cmd-N shortcut for jumping to this tab. Tabs are 1-indexed in the menu.
    var shortcut: KeyEquivalent {
        KeyEquivalent(Character(String(rawValue + 1)))
    }
}

// MARK: - Focused Values

extension FocusedValues {
    @Entry var selectedTab: Binding<AppTab>? = nil
    @Entry var reloadAction: (() -> Void)? = nil
}

// MARK: - Commands

struct AppCommands: Commands {
    @FocusedValue(\.selectedTab) var selectedTabBinding: Binding<AppTab>?
    @FocusedValue(\.reloadAction) var reloadAction: (() -> Void)?

    var body: some Commands {
        CommandGroup(replacing: .newItem) { }

        CommandMenu("Ansicht") {
            Button("Aktualisieren") { reloadAction?() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(reloadAction == nil)

            Divider()

            ForEach(AppTab.allCases) { tab in
                Button(tab.title) { selectedTabBinding?.wrappedValue = tab }
                    .keyboardShortcut(tab.shortcut, modifiers: .command)
                    .disabled(selectedTabBinding == nil)
            }
        }
    }
}
