//
//  TypeMatchupView.swift
//  PokéJournal
//

import SwiftUI

struct TypeMatchupView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss

    private var defensiveProfile: [String: Double] {
        TypeChart.teamDefensiveProfile(team: teamTypes, generation: game.generation)
    }

    private var offensiveProfile: [String: Double] {
        TypeChart.teamOffensiveProfile(team: teamTypes, generation: game.generation)
    }

    private var defensiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Defensiv-Übersicht")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(game.generation.allTypes, id: \.self) { type in
                    MatchupCell(
                        type: type,
                        multiplier: defensiveProfile[type] ?? 1.0,
                        highIsGood: false,
                        relatedMembers: weakMembers(against: type)
                    )
                }
            }
        }
    }

    private var offensiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Offensiv-Übersicht")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(game.generation.allTypes, id: \.self) { type in
                    MatchupCell(
                        type: type,
                        multiplier: offensiveProfile[type] ?? 1.0,
                        highIsGood: true,
                        relatedMembers: strongMembers(against: type)
                    )
                }
            }
        }
    }

    private func weakMembers(against attacker: String) -> [String] {
        game.currentTeam.compactMap { member in
            guard let types = PokemonDatabase.shared.find(byName: member.pokemonName)?.types else {
                return nil
            }
            let m = TypeChart.defensiveMultiplier(
                attacker: attacker,
                defenderTypes: types,
                generation: game.generation
            )
            return m > 1.0 ? member.displayName : nil
        }
    }

    private func strongMembers(against defender: String) -> [String] {
        game.currentTeam.compactMap { member in
            guard let types = PokemonDatabase.shared.find(byName: member.pokemonName)?.types else {
                return nil
            }
            let best = types.map {
                TypeChart.effectiveness(attacker: $0, defender: defender, generation: game.generation)
            }.max() ?? 1.0
            return best > 1.0 ? member.displayName : nil
        }
    }

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
                    defensiveSection
                    offensiveSection

                    coverageGapsSection
                    recommendationSection
                }
                .padding()
            }
            .navigationTitle("Typ-Matchup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("typMatchupDoneButton")
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

    private var coverageGapsSection: some View {
        let gaps = TypeChart.coverageGaps(team: teamTypes, generation: game.generation)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Abdeckungs-Lücken")
                .font(.headline)
            if gaps.isEmpty {
                Text("Dein Team kann alle Typen effektiv treffen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Diese Typen kann dein Team nicht super-effektiv treffen:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 8) {
                    ForEach(gaps, id: \.self) { type in
                        Text(PokemonTypeLabel.german(for: type))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.2), in: Capsule())
                    }
                }
            }
        }
    }

    private var recommendationSection: some View {
        let recs = TypeChart.recommendation(team: teamTypes, generation: game.generation)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Empfehlung")
                .font(.headline)
            if recs.isEmpty {
                Text("Dein Team ist gut aufgestellt — keine Empfehlungen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recs, id: \.self) { type in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(PokemonTypeColor.color(for: type))
                            .frame(width: 12, height: 12)
                        Text("Ein \(PokemonTypeLabel.german(for: type))-Pokémon würde dein Team abrunden.")
                            .font(.subheadline)
                    }
                }
            }
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

private struct MatchupCell: View {
    let type: String
    let multiplier: Double
    /// When true, higher multipliers are colored green (good); when false, higher is red (bad).
    let highIsGood: Bool
    let relatedMembers: [String]

    var body: some View {
        VStack(spacing: 4) {
            Text(PokemonTypeLabel.german(for: type))
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(multiplierLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(background, in: RoundedRectangle(cornerRadius: 8))
        .help(tooltip)
    }

    private var multiplierLabel: String {
        switch multiplier {
        case 0: return "0×"
        case 0.25: return "¼×"
        case 0.5: return "½×"
        case 1: return "1×"
        case 2: return "2×"
        case 4: return "4×"
        default: return String(format: "%.2f×", multiplier)
        }
    }

    private var background: AnyShapeStyle {
        if multiplier == 1 { return AnyShapeStyle(.fill.quaternary) }
        let isGood = (multiplier > 1) == highIsGood
        return AnyShapeStyle(isGood ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
    }

    private var tooltip: String {
        if relatedMembers.isEmpty {
            return PokemonTypeLabel.german(for: type)
        }
        return "\(PokemonTypeLabel.german(for: type)): \(relatedMembers.joined(separator: ", "))"
    }
}

