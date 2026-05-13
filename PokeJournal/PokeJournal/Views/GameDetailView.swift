//
//  GameDetailView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct GameDetailView: View {
    let game: Game
    @SceneStorage("selectedTab") private var selectedTab: AppTab = .sessions

    var body: some View {
        GameDetailContent(game: game, selectedTab: $selectedTab)
        .navigationTitle(game.displayName)
        .focusedSceneValue(\.selectedTab, $selectedTab)
    }
}


/// Shared content used by both the split-view detail pane and standalone game windows.
struct GameDetailContent: View {
    let game: Game
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CompactGameHeaderView(game: game)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Picker("Ansicht", selection: $selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    Text(tab.title)
                        .tag(tab)
                        .accessibilityIdentifier("tabSegment_\(tab.rawValue)")
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("tabPicker")
            .padding(.horizontal)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                switch selectedTab {
                case .sessions:      SessionsListView(game: game)
                case .timeline:      TimelineView(game: game)
                case .heatmap:       HeatmapView(game: game)
                case .hallOfFame:    TeamAnalysisView(game: game)
                case .teamEvolution: TeamEvolutionView(game: game)
                case .teamCheck:     TypeMatchupView(game: game)
                }
            }
            .scrollIndicators(.never)
        }
    }
}

struct CompactGameHeaderView: View {
    let game: Game

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            titleAndFacts
                .frame(minWidth: 260, maxWidth: .infinity, alignment: .leading)

            currentTeam
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var titleAndFacts: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 6) {
                    if let release = game.releaseDate {
                        Text(release)
                    }
                    if let developer = game.developer {
                        Text(developer)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            HStack(spacing: 6) {
                GameInfoPill(systemImage: "calendar", text: "\(game.totalSessionCount)")
                GameInfoPill(systemImage: "person.3", text: "\(game.currentTeam.count)")
                if let lastPlayed = game.lastPlayedDate {
                    GameInfoPill(
                        systemImage: "clock",
                        text: lastPlayed.formatted(date: .abbreviated, time: .omitted)
                    )
                }
                if let metacritic = game.metacriticScore {
                    GameInfoPill(text: "\(metacritic)", tint: metacriticColor(score: metacritic))
                }
                ForEach(game.platforms.prefix(2), id: \.self) { platform in
                    PlatformBadge(platform: platform)
                }
            }
        }
    }

    @ViewBuilder
    private var currentTeam: some View {
        if !game.currentTeam.isEmpty {
            CompactCurrentTeamView(team: game.currentTeam)
        }
    }

    private func metacriticColor(score: Int) -> Color {
        switch score {
        case 75...: return .green
        case 50..<75: return .yellow
        default: return .red
        }
    }
}

struct GameInfoPill: View {
    var systemImage: String?
    let text: String
    var tint: Color?

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
                .lineLimit(1)
        }
        .font(.caption)
        .fontWeight(tint == nil ? .regular : .semibold)
        .foregroundStyle(tint ?? .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((tint ?? Color.secondary).opacity(tint == nil ? 0.08 : 0.16), in: Capsule())
    }
}

struct PlatformBadge: View {
    let platform: String

    var body: some View {
        Text(platform)
            .font(.caption)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}

struct CompactCurrentTeamView: View {
    let team: [TeamMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aktuelles Team")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                ForEach(team.prefix(6), id: \.pokemonName) { member in
                    VStack(spacing: 2) {
                        PokemonSpriteView(pokemonName: member.pokemonName, variant: member.variant, size: 54)
                        Text("\(member.level)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 62)
                    .help("\(member.displayName), Level \(member.level)")
                }
            }
        }
        .padding(.leading, 18)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.separator.opacity(0.35))
                .frame(width: 1)
        }
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
