//
//  TypeMatchupView.swift
//  PokéJournal
//

import SwiftUI

struct TypeMatchupView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss

    private var profile: [String: Double] {
        TypeChart.teamDefensiveProfile(team: teamTypes, generation: game.generation)
    }

    private var defensiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Defensiv-Übersicht")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(game.generation.allTypes, id: \.self) { type in
                    DefensiveCell(
                        type: type,
                        multiplier: profile[type] ?? 1.0,
                        affectedMembers: affectedMembers(for: type)
                    )
                }
            }
        }
    }

    private func affectedMembers(for attacker: String) -> [String] {
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

                    coverageGapsSection
                    recommendationSection
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
                        Text(typeLabel(type))
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
                        Text("Ein \(typeLabel(type))-Pokémon würde dein Team abrunden.")
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

private struct DefensiveCell: View {
    let type: String
    let multiplier: Double
    let affectedMembers: [String]

    var body: some View {
        VStack(spacing: 4) {
            Text(typeLabel(type))
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
        if multiplier > 1 { return AnyShapeStyle(Color.red.opacity(0.2)) }
        if multiplier < 1 { return AnyShapeStyle(Color.green.opacity(0.2)) }
        return AnyShapeStyle(.fill.quaternary)
    }

    private var tooltip: String {
        if affectedMembers.isEmpty {
            return typeLabel(type)
        }
        return "\(typeLabel(type)): \(affectedMembers.joined(separator: ", "))"
    }
}

private func typeLabel(_ type: String) -> String {
    switch type {
    case "normal": return "Normal"
    case "fire": return "Feuer"
    case "water": return "Wasser"
    case "electric": return "Elektro"
    case "grass": return "Pflanze"
    case "ice": return "Eis"
    case "fighting": return "Kampf"
    case "poison": return "Gift"
    case "ground": return "Boden"
    case "flying": return "Flug"
    case "psychic": return "Psycho"
    case "bug": return "Käfer"
    case "rock": return "Gestein"
    case "ghost": return "Geist"
    case "dragon": return "Drache"
    case "dark": return "Unlicht"
    case "steel": return "Stahl"
    case "fairy": return "Fee"
    default: return type.capitalized
    }
}
