//
//  TeamAnalysisView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct TeamAnalysisView: View {
    let game: Game

    private var pokemonUsage: [(name: String, count: Int, maxLevel: Int)] {
        var usage: [String: (count: Int, maxLevel: Int)] = [:]

        for session in game.sessions {
            for member in session.orderedTeam {
                let key = member.displayName
                let current = usage[key] ?? (0, 0)
                usage[key] = (current.count + 1, max(current.maxLevel, member.level))
            }
        }

        for oldSession in game.oldSessions {
            for member in oldSession.orderedTeam {
                let key = member.displayName
                let current = usage[key] ?? (0, 0)
                usage[key] = (current.count + 1, max(current.maxLevel, member.level))
            }
        }

        return usage.map { (name: $0.key, count: $0.value.count, maxLevel: $0.value.maxLevel) }
            .sorted { $0.count > $1.count }
    }

    private var hallOfFame: [(name: String, count: Int)] {
        Array(pokemonUsage.prefix(6))
            .map { (name: $0.name, count: $0.count) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !hallOfFame.isEmpty {
                HallOfFameSection(pokemon: hallOfFame)
            }

            if !pokemonUsage.isEmpty {
                UsageStatsSection(usage: pokemonUsage)
            }

            if pokemonUsage.isEmpty {
                Text("Keine Team-Daten vorhanden")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
    }
}

struct HallOfFameSection: View {
    let pokemon: [(name: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hall of Fame", systemImage: "trophy")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(pokemon.enumerated()), id: \.offset) { index, poke in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(medalColor(for: index).opacity(0.2))
                                .frame(width: 70, height: 70)

                            PokemonSpriteView(pokemonName: poke.name, size: 56)

                            if index < 3 {
                                Image(systemName: "medal.fill")
                                    .foregroundStyle(medalColor(for: index))
                                    .offset(x: 25, y: -25)
                            }
                        }

                        Text(poke.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Text("\(poke.count) Sessions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .clear
        }
    }
}

struct UsageStatsSection: View {
    let usage: [(name: String, count: Int, maxLevel: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pokémon-Nutzung", systemImage: "chart.bar")
                .font(.headline)

            ForEach(Array(usage.enumerated()), id: \.offset) { _, poke in
                HStack {
                    Text(poke.name)
                        .frame(width: 120, alignment: .leading)

                    GeometryReader { geometry in
                        let maxCount = usage.first?.count ?? 1
                        let width = (CGFloat(poke.count) / CGFloat(maxCount)) * geometry.size.width

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.6))
                            .frame(width: max(width, 4), height: 20)
                    }
                    .frame(height: 20)

                    Text("\(poke.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)

                    Text("Lvl \(poke.maxLevel)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
    }
}

#Preview {
    let game = Game(name: "test", filePath: "")
    return TeamAnalysisView(game: game)
        .modelContainer(for: Game.self, inMemory: true)
}
