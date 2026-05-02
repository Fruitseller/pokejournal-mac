//
//  TypeMatchupView.swift
//  PokéJournal
//

import SwiftUI

struct TypeMatchupView: View {
    let game: Game
    @State private var cachedData = TypeMatchupData.empty

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Spacer()
                generationBadge
            }
            TeamCheckSection(analyses: cachedData.analyses)
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 32) {
                    defensiveSection
                        .frame(minWidth: 400, maxWidth: .infinity, alignment: .leading)
                    offensiveSection
                        .frame(minWidth: 400, maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 24) {
                    defensiveSection
                    offensiveSection
                }
            }
        }
        .padding()
        .task(id: contentSignature) {
            recomputeAnalyses()
        }
    }

    private var defensiveSection: some View {
        DefensiveBucketList(
            profile: cachedData.defensiveProfile,
            generation: game.generation,
            affectedMembers: { cachedData.weakMembersByAttacker[$0] ?? [] }
        )
    }

    // MARK: Header

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
        let members = game.currentTeam.enumerated().map { index, member in
            TypeMatchupTeamMember(
                id: "team-\(index)-\(member.order)-\(member.displayName)",
                displayName: member.displayName,
                pokemonName: member.pokemonName,
                variant: member.variant
            )
        }
        cachedData = TypeMatchupDataBuilder.build(
            team: members,
            generation: game.generation,
            resolveTypes: PokemonDatabase.shared.resolvedTypes(for:variant:)
        )
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
                        multiplier: cachedData.offensiveProfile[type] ?? 1.0,
                        relatedMembers: cachedData.strongMembersByDefender[type] ?? []
                    )
                }
            }
        }
    }

    private var contentSignature: GameContentSignature {
        GameContentSignatureBuilder.build(from: game)
    }
}

private struct OffensiveMatchupCell: View {
    let type: String
    let multiplier: Double
    let relatedMembers: [TypeMatchupRelatedMember]

    @State private var hoverShowsPopover = false

    var body: some View {
        let dimmed = multiplier == 1.0
        let chromeOpacity: Double = dimmed ? 0.4 : 1.0

        return VStack(spacing: 4) {
            PokemonTypeIcon.image(for: type, size: 24)
                .opacity(chromeOpacity)
            Text(PokemonTypeLabel.german(for: type))
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(dimmed ? .secondary : .primary)
            Text(PokemonTypeMultiplier.label(multiplier))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.fill.quaternary.opacity(chromeOpacity), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(outlineColor, lineWidth: outlineWidth)
                .opacity(chromeOpacity)
        )
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
                Text("Trifft \(PokemonTypeLabel.german(for: type)) mit \(PokemonTypeMultiplier.label(multiplier))")
                    .font(.caption.weight(.semibold))
            }
            Divider()
            ForEach(relatedMembers) { member in
                HStack(spacing: 8) {
                    PokemonSpriteView(pokemonName: member.pokemonName, variant: member.variant, size: 28)
                    Text(member.displayName)
                        .font(.subheadline)
                }
            }
        }
        .padding(12)
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
        let names = relatedMembers.map(\.displayName).joined(separator: ", ")
        return "\(label): \(names)"
    }

    private var accessibilityText: String {
        "\(PokemonTypeLabel.german(for: type)), \(PokemonTypeMultiplier.label(multiplier)) offensiv"
    }
}
