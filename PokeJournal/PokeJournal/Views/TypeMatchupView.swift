//
//  TypeMatchupView.swift
//  PokéJournal
//

import SwiftUI

struct TypeMatchupView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss

    private var teamTypes: [[String]] {
        game.currentTeam.compactMap { member in
            PokemonDatabase.shared.find(byName: member.pokemonName)?.types
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    Divider()
                    Text("Defensiv-Übersicht")
                        .font(.headline)
                    // Filled in by Task 11.

                    Text("Abdeckungs-Lücken")
                        .font(.headline)
                    // Filled in by Task 12.

                    Text("Empfehlung")
                        .font(.headline)
                    // Filled in by Task 12.
                }
                .padding()
            }
            .navigationTitle("Typ-Matchup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 560)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(game.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            generationBadge
        }
    }

    private var generationBadge: some View {
        let label: String = {
            switch game.generation {
            case .gen1: return "Gen 1"
            case .gen2to5: return "Gen 2–5"
            case .gen6plus: return "Gen 6+"
            }
        }()
        return Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.fill.quaternary, in: Capsule())
    }
}
