//
//  SessionDetailView.swift
//  PokéJournal
//

import SwiftUI
import AppKit
import SwiftData

struct SessionDetailView: View {
    let session: AnySession
    let game: Game
    var previousTeam: [TeamMember]?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                if !session.team.isEmpty || previousTeam != nil {
                    let diff: TeamDiff? = if let previousTeam, !previousTeam.isEmpty {
                        teamDiff(current: session.team, previous: previousTeam)
                    } else {
                        nil
                    }
                    TeamSectionView(team: session.team, diff: diff)
                }

                if !session.activities.isEmpty {
                    SectionView(title: "Aktivitäten", content: session.activities, icon: "gamecontroller")
                }

                if !session.plans.isEmpty {
                    SectionView(title: "Pläne", content: session.plans, icon: "list.bullet")
                }

                if !session.thoughts.isEmpty {
                    SectionView(title: "Gedanken", content: session.thoughts, icon: "brain")
                }
            }
            .padding()
        }
        .navigationTitle("Session")
    }

    @ViewBuilder
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.formattedDate)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack(spacing: 8) {
                    Text(game.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if session.isOld {
                        Text("Altes Format")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2), in: Capsule())
                    }
                }
            }

            Spacer()

            if let filePath = session.filePath {
                Button("In Obsidian öffnen") {
                    openInObsidian(filePath: filePath)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func openInObsidian(filePath: String) {
        if let url = VaultManager.shared.obsidianURL(forFilePath: filePath) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Team Diff

struct TeamDiff {
    struct LevelChange {
        let member: TeamMember
        let delta: Int
    }

    struct Evolution {
        let from: TeamMember
        let to: TeamMember
        let levelDelta: Int
    }

    let added: [TeamMember]
    let removed: [TeamMember]
    let levelChanges: [LevelChange]
    let evolutions: [Evolution]

    var hasChanges: Bool {
        !added.isEmpty || !removed.isEmpty || !levelChanges.isEmpty || !evolutions.isEmpty
    }

    var changeCount: Int {
        added.count + removed.count + levelChanges.count + evolutions.count
    }
}

func teamDiff(current: [TeamMember], previous: [TeamMember]) -> TeamDiff {
    let currentByName = Dictionary(
        current.map { ($0.pokemonName.lowercased(), $0) },
        uniquingKeysWith: { first, _ in first }
    )
    let previousByName = Dictionary(
        previous.map { ($0.pokemonName.lowercased(), $0) },
        uniquingKeysWith: { first, _ in first }
    )

    var added = current.filter { previousByName[$0.pokemonName.lowercased()] == nil }
    var removed = previous.filter { currentByName[$0.pokemonName.lowercased()] == nil }

    // Detect evolutions: pair added/removed Pokemon that share an evolution line
    let db = PokemonDatabase.shared
    var evolutions: [TeamDiff.Evolution] = []
    var matchedAdded: Set<String> = []
    var matchedRemoved: Set<String> = []

    for addedMember in added {
        for removedMember in removed {
            if matchedRemoved.contains(removedMember.pokemonName.lowercased()) { continue }
            if db.sameEvolutionLine(addedMember.pokemonName, removedMember.pokemonName) {
                evolutions.append(.init(
                    from: removedMember,
                    to: addedMember,
                    levelDelta: addedMember.level - removedMember.level
                ))
                matchedAdded.insert(addedMember.pokemonName.lowercased())
                matchedRemoved.insert(removedMember.pokemonName.lowercased())
                break
            }
        }
    }

    // Remove matched pairs from added/removed
    added.removeAll { matchedAdded.contains($0.pokemonName.lowercased()) }
    removed.removeAll { matchedRemoved.contains($0.pokemonName.lowercased()) }

    var levelChanges: [TeamDiff.LevelChange] = []
    for member in current {
        if let prev = previousByName[member.pokemonName.lowercased()] {
            let delta = member.level - prev.level
            if delta != 0 {
                levelChanges.append(.init(member: member, delta: delta))
            }
        }
    }

    return TeamDiff(added: added, removed: removed, levelChanges: levelChanges, evolutions: evolutions)
}

// MARK: - Unified Team Section

struct TeamSectionView: View {
    let team: [TeamMember]
    let diff: TeamDiff?

    private var addedNames: Set<String> {
        Set(diff?.added.map { $0.pokemonName.lowercased() } ?? [])
    }

    private var evolvedNames: [String: TeamDiff.Evolution] {
        Dictionary(
            (diff?.evolutions ?? []).map { ($0.to.pokemonName.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private var levelDeltas: [String: Int] {
        Dictionary(
            (diff?.levelChanges ?? []).map { ($0.member.pokemonName.lowercased(), $0.delta) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Label("Team", systemImage: "person.3")
                    .font(.headline)

                if let diff, diff.hasChanges {
                    Text("(\(diff.changeCount) \(diff.changeCount == 1 ? "Änderung" : "Änderungen"))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            let hasAnnotations = diff?.hasChanges == true
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
            ], spacing: 12) {
                // Current team with inline annotations
                ForEach(team, id: \.pokemonName) { member in
                    let key = member.pokemonName.lowercased()
                    let isNew = addedNames.contains(key)
                    let evolution = evolvedNames[key]
                    let delta = levelDeltas[key]
                    AnnotatedTeamMemberCard(
                        member: member,
                        isNew: isNew,
                        evolution: evolution,
                        levelDelta: delta,
                        reserveAnnotationSpace: hasAnnotations
                    )
                }

                // Removed Pokemon at the end
                if let diff {
                    ForEach(diff.removed, id: \.pokemonName) { member in
                        RemovedTeamMemberCard(member: member)
                    }
                }
            }
        }
        .padding()
    }
}

struct AnnotatedTeamMemberCard: View {
    let member: TeamMember
    let isNew: Bool
    var evolution: TeamDiff.Evolution?
    let levelDelta: Int?
    var reserveAnnotationSpace = false

    private var isEvolved: Bool { evolution != nil }

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

            if reserveAnnotationSpace {
                VStack(spacing: 4) {
                    if let evo = evolution, evo.levelDelta != 0 {
                        Text(evo.levelDelta > 0 ? "+\(evo.levelDelta)" : "\(evo.levelDelta)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.purple)
                    } else if let delta = levelDelta {
                        Text(delta > 0 ? "+\(delta)" : "\(delta)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(delta > 0 ? .green : .orange)
                    }

                    if isEvolved {
                        Text("Entwickelt")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.purple, in: Capsule())
                    } else if isNew {
                        Text("Neu")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green, in: Capsule())
                    }
                }
                .frame(height: 20, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if isEvolved {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.purple.opacity(0.4), lineWidth: 1.5)
            } else if isNew {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.green.opacity(0.4), lineWidth: 1.5)
            }
        }
    }
}

struct RemovedTeamMemberCard: View {
    let member: TeamMember

    var body: some View {
        VStack(spacing: 8) {
            PokemonSpriteView(pokemonName: member.pokemonName, size: 64)
                .opacity(0.4)

            Text(member.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(.secondary)

            Text("Lvl \(member.level)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text("Entfernt")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red, in: Capsule())
                .frame(height: 20, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .opacity(0.7)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.red.opacity(0.3), lineWidth: 1.5)
        }
    }
}

// MARK: - Shared Components

struct TeamGridView: View {
    let team: [TeamMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Team", systemImage: "person.3")
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
    }
}

struct SectionView: View {
    let title: String
    let content: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(content)
                .font(.body)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let game = Game(name: "test", filePath: "")
    let session = AnySession.regular(
        Session(date: Date(), activities: "Test", plans: "Plans", thoughts: "Thoughts")
    )

    return NavigationStack {
        SessionDetailView(session: session, game: game)
    }
    .modelContainer(for: Game.self, inMemory: true)
}
