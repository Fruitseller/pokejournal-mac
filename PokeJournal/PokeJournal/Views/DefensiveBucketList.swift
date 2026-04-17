//
//  DefensiveBucketList.swift
//  PokéJournal
//

import SwiftUI

struct DefensiveBucketList: View {
    let profile: [String: Double]
    let generation: TypeChartGeneration
    let affectedMembers: (String) -> [String]

    @AppStorage("typMatchup.neutralExpanded") private var neutralExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Defensiv-Übersicht")
                .font(.headline)

            VStack(spacing: 0) {
                bucketSection(
                    title: "Kritisch",
                    symbol: "exclamationmark.octagon.fill",
                    tint: .red,
                    entries: critical
                )
                bucketSection(
                    title: "Schwach",
                    symbol: "exclamationmark.triangle.fill",
                    tint: .orange,
                    entries: weak
                )
                neutralSection
                bucketSection(
                    title: "Resistent",
                    symbol: "shield.lefthalf.filled",
                    tint: .blue,
                    entries: resistant
                )
                bucketSection(
                    title: "Immun",
                    symbol: "checkmark.seal.fill",
                    tint: .green,
                    entries: immune
                )
            }
            .padding(12)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: bucket partitions

    private var sortedEntries: [(type: String, multiplier: Double)] {
        generation.allTypes.map { ($0, profile[$0] ?? 1.0) }
    }

    private var critical: [(type: String, multiplier: Double)] {
        sortedEntries.filter { $0.multiplier >= 4.0 }
    }
    private var weak: [(type: String, multiplier: Double)] {
        sortedEntries.filter { $0.multiplier == 2.0 }
    }
    private var neutral: [(type: String, multiplier: Double)] {
        sortedEntries.filter { $0.multiplier == 1.0 }
    }
    private var resistant: [(type: String, multiplier: Double)] {
        sortedEntries.filter { $0.multiplier > 0.0 && $0.multiplier < 1.0 }
    }
    private var immune: [(type: String, multiplier: Double)] {
        sortedEntries.filter { $0.multiplier == 0.0 }
    }

    // MARK: rendering

    @ViewBuilder
    private func bucketSection(
        title: String,
        symbol: String,
        tint: Color,
        entries: [(type: String, multiplier: Double)]
    ) -> some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                bucketHeader(title: title, symbol: symbol, tint: tint, count: entries.count)
                ForEach(entries, id: \.type) { entry in
                    defensiveRow(type: entry.type, multiplier: entry.multiplier)
                }
            }
            .padding(.vertical, 6)
            Divider().opacity(0.5)
        }
    }

    @ViewBuilder
    private var neutralSection: some View {
        if !neutral.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                DisclosureGroup(isExpanded: $neutralExpanded) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 90), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(neutral, id: \.type) { entry in
                            neutralChip(type: entry.type)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    bucketHeader(
                        title: "Neutral",
                        symbol: "equal.circle",
                        tint: .secondary,
                        count: neutral.count
                    )
                }
            }
            .padding(.vertical, 6)
            Divider().opacity(0.5)
        }
    }

    private func bucketHeader(
        title: String,
        symbol: String,
        tint: Color,
        count: Int
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func defensiveRow(type: String, multiplier: Double) -> some View {
        let members = affectedMembers(type)
        return HStack(spacing: 10) {
            PokemonTypeIcon.image(for: type, size: 18)
            Text(PokemonTypeLabel.german(for: type))
                .font(.subheadline)
            Text(multiplierLabel(multiplier))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            if !members.isEmpty {
                Text(members.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel(type: type, multiplier: multiplier, members: members))
    }

    private func neutralChip(type: String) -> some View {
        HStack(spacing: 4) {
            PokemonTypeIcon.image(for: type, size: 14)
            Text(PokemonTypeLabel.german(for: type))
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.fill.quaternary, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(PokemonTypeLabel.german(for: type)), neutral")
    }

    private func multiplierLabel(_ multiplier: Double) -> String {
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

    private func rowAccessibilityLabel(type: String, multiplier: Double, members: [String]) -> String {
        let typeLabel = PokemonTypeLabel.german(for: type)
        let mult: String
        switch multiplier {
        case 0:    mult = "immun"
        case 0.25: mult = "ein Viertel Schaden"
        case 0.5:  mult = "halber Schaden"
        case 2:    mult = "doppelter Schaden"
        case 4:    mult = "vierfacher Schaden"
        default:   mult = "\(multiplier)-fach Schaden"
        }
        if members.isEmpty {
            return "\(typeLabel), \(mult)"
        }
        return "\(typeLabel), \(mult), betrifft \(members.joined(separator: ", "))"
    }
}
