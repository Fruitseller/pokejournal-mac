//
//  TypeMatchupView.swift
//  PokéJournal
//

import SwiftUI

struct TypeMatchupView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    @State private var cachedAnalyses: [TeamMemberAnalysis] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    Divider()
                    TeamCheckSection(analyses: cachedAnalyses)
                    Divider()
                    DefensiveBucketList(
                        profile: defensiveProfile,
                        generation: game.generation,
                        affectedMembers: weakMembers(against:)
                    )
                    offensiveSection
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
        .frame(minWidth: 520)
        .onAppear(perform: recomputeAnalyses)
        .onChange(of: game.currentTeam.map(\.pokemonName)) { _, _ in
            recomputeAnalyses()
        }
        .onChange(of: game.generation) { _, _ in
            recomputeAnalyses()
        }
    }

    // MARK: Header

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
            case .gen1:    return "Gen 1"
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

    // MARK: Analyses caching

    private func recomputeAnalyses() {
        let members: [TeamCheckAnalyzer.Member] = game.currentTeam.compactMap { member in
            guard let types = PokemonDatabase.shared.find(byName: member.pokemonName)?.types else {
                return nil
            }
            return .init(name: member.displayName, types: types)
        }
        cachedAnalyses = TeamCheckAnalyzer.analyze(team: members, generation: game.generation)
    }

    // MARK: Offensive grid (flat, generation-aware)

    private var offensiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Offensiv-Übersicht")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(game.generation.allTypes, id: \.self) { type in
                    OffensiveMatchupCell(
                        type: type,
                        multiplier: offensiveProfile[type] ?? 1.0,
                        relatedMembers: strongMembers(against: type)
                    )
                }
            }
        }
    }

    // MARK: Profiles & affected members

    private var defensiveProfile: [String: Double] {
        TypeChart.teamDefensiveProfile(team: teamTypes, generation: game.generation)
    }

    private var offensiveProfile: [String: Double] {
        TypeChart.teamOffensiveProfile(team: teamTypes, generation: game.generation)
    }

    private var teamTypes: [[String]] {
        game.currentTeam.compactMap { member in
            PokemonDatabase.shared.find(byName: member.pokemonName)?.types
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
}

private struct OffensiveMatchupCell: View {
    let type: String
    let multiplier: Double
    let relatedMembers: [String]

    @State private var hoverShowsPopover = false

    var body: some View {
        VStack(spacing: 4) {
            PokemonTypeIcon.image(for: type, size: 24)
            Text(PokemonTypeLabel.german(for: type))
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(multiplierLabel)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(outlineColor, lineWidth: outlineWidth)
        )
        .opacity(multiplier == 1.0 ? 0.4 : 1.0)
        .contentShape(Rectangle())
        .onHover { hovering in
            hoverShowsPopover = hovering && !relatedMembers.isEmpty
        }
        .popover(isPresented: $hoverShowsPopover, arrowEdge: .top) {
            attackerPopover
        }
        .help(tooltip)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var attackerPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                PokemonTypeIcon.image(for: type, size: 14)
                Text("Trifft \(PokemonTypeLabel.german(for: type)) mit \(multiplierLabel)")
                    .font(.caption.weight(.semibold))
            }
            Divider()
            ForEach(relatedMembers, id: \.self) { name in
                HStack(spacing: 8) {
                    PokemonSpriteView(pokemonName: name, size: 28)
                    Text(name)
                        .font(.subheadline)
                }
            }
        }
        .padding(12)
    }

    private var multiplierLabel: String {
        switch multiplier {
        case 0:    return "×0"
        case 0.25: return "×¼"
        case 0.5:  return "×½"
        case 1:    return "×1"
        case 2:    return "×2"
        case 4:    return "×4"
        default:   return String(format: "×%.2f", multiplier)
        }
    }

    private var outlineColor: Color {
        if multiplier > 1.0 { return .green.opacity(0.6) }
        if multiplier < 1.0 { return .red.opacity(0.5) }
        return .clear
    }

    private var outlineWidth: CGFloat {
        multiplier == 1.0 ? 0 : 1
    }

    private var tooltip: String {
        let label = PokemonTypeLabel.german(for: type)
        if relatedMembers.isEmpty { return label }
        return "\(label): \(relatedMembers.joined(separator: ", "))"
    }

    private var accessibilityText: String {
        "\(PokemonTypeLabel.german(for: type)), \(multiplierLabel) offensiv"
    }
}
