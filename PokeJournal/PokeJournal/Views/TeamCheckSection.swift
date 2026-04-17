//
//  TeamCheckSection.swift
//  PokéJournal
//

import SwiftUI

struct TeamCheckSection: View {
    let analyses: [TeamMemberAnalysis]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team-Check")
                .font(.headline)

            if analyses.isEmpty {
                Text("Füge erst Pokémon zu deinem Team hinzu, um Matchup-Empfehlungen zu erhalten.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                if allKernstueck {
                    Text("Dein Team ist ausgewogen — keine Ersetzungs-Empfehlung.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 8) {
                    ForEach(analyses, id: \.memberName) { analysis in
                        TeamCheckRow(analysis: analysis)
                    }
                }
            }
        }
    }

    private var allKernstueck: Bool {
        analyses.allSatisfy { $0.category == .kernstueck }
    }
}

private struct TeamCheckRow: View {
    let analysis: TeamMemberAnalysis

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PokemonSpriteView(pokemonName: analysis.memberName, size: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.memberName)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    ForEach(analysis.types, id: \.self) { type in
                        PokemonTypeIcon.image(for: type, size: 12)
                    }
                }
            }

            Spacer()

            statusColumn
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var statusColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            statusHeadline
            if let reason = analysis.reason {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var statusHeadline: some View {
        switch analysis.category {
        case .kernstueck:
            Label("Kernstück", systemImage: "star.fill")
                .foregroundStyle(.yellow)
                .font(.subheadline.weight(.semibold))
        case .ausgewogen:
            Label("Ausgewogen", systemImage: "circle")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        case .verzichtbar(let ersatzTyp):
            HStack(spacing: 4) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.orange)
                Text("Ersetzen durch")
                    .font(.subheadline)
                PokemonTypeIcon.image(for: ersatzTyp, size: 14)
                Text(PokemonTypeLabel.german(for: ersatzTyp))
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var accessibilityText: String {
        let categoryText: String
        switch analysis.category {
        case .kernstueck:
            categoryText = "Kernstück"
        case .ausgewogen:
            categoryText = "Ausgewogen"
        case .verzichtbar(let ersatzTyp):
            categoryText = "Verzichtbar, Vorschlag \(PokemonTypeLabel.german(for: ersatzTyp))-Typ"
        }
        if let reason = analysis.reason {
            return "\(analysis.memberName), \(categoryText), \(reason)"
        }
        return "\(analysis.memberName), \(categoryText)"
    }
}
