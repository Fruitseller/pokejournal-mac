//
//  GameDetailView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct GameDetailView: View {
    let game: Game
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GameHeaderView(game: game)

                StatsCardsView(game: game)

                if !game.currentTeam.isEmpty {
                    CurrentTeamView(team: game.currentTeam)
                }

                Picker("Ansicht", selection: $selectedTab) {
                    Text("Sessions").tag(0)
                    Text("Timeline").tag(1)
                    Text("Heatmap").tag(2)
                    Text("Team-Analyse").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedTab {
                case 0:
                    SessionsListView(game: game)
                case 1:
                    TimelineView(game: game)
                case 2:
                    HeatmapView(game: game)
                case 3:
                    TeamAnalysisView(game: game)
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .navigationTitle(game.displayName)
    }
}

struct GameHeaderView: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let release = game.releaseDate {
                        Text("Release: \(release)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let developer = game.developer {
                        Text(developer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let metacritic = game.metacriticScore {
                    MetacriticBadge(score: metacritic)
                }
            }

            if !game.platforms.isEmpty {
                HStack(spacing: 8) {
                    ForEach(game.platforms, id: \.self) { platform in
                        PlatformBadge(platform: platform)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MetacriticBadge: View {
    let score: Int

    var color: Color {
        switch score {
        case 75...: return .green
        case 50..<75: return .yellow
        default: return .red
        }
    }

    var body: some View {
        Text("\(score)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(color, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct PlatformBadge: View {
    let platform: String

    var body: some View {
        Text(platform)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}

struct StatsCardsView: View {
    let game: Game

    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Sessions",
                value: "\(game.totalSessionCount)",
                icon: "calendar"
            )

            StatCard(
                title: "Team-Größe",
                value: "\(game.currentTeam.count)",
                icon: "person.3"
            )

            if let lastPlayed = game.lastPlayedDate {
                StatCard(
                    title: "Zuletzt gespielt",
                    value: lastPlayed.formatted(date: .abbreviated, time: .omitted),
                    icon: "clock"
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CurrentTeamView: View {
    let team: [TeamMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aktuelles Team")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
            ], spacing: 12) {
                ForEach(team, id: \.pokemonName) { member in
                    TeamMemberCard(member: member)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct TeamMemberCard: View {
    let member: TeamMember

    var body: some View {
        VStack(spacing: 8) {
            PokemonSpriteView(pokemonName: member.pokemonName, size: 64)

            Text(member.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Text("Lvl \(member.level)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let game = Game(name: "purpur", filePath: "")
    game.aliases = ["Pokémon Purpur"]
    game.releaseDate = "2022-11-18"
    game.platforms = ["Nintendo Switch"]
    game.metacriticScore = 72

    return NavigationStack {
        GameDetailView(game: game)
    }
    .modelContainer(for: Game.self, inMemory: true)
}
