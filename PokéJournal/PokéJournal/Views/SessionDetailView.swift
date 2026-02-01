//
//  SessionDetailView.swift
//  PokéJournal
//

import SwiftUI
import AppKit
import SwiftData

struct SessionDetailView: View {
    let session: Session
    let game: Game

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.formattedDate)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(game.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("In Obsidian öffnen") {
                        openInObsidian()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                if !session.team.isEmpty {
                    TeamGridView(team: session.team)
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

    private func openInObsidian() {
        guard let vaultName = VaultManager.shared.vaultName else { return }

        let filePath = session.filePath
            .replacingOccurrences(of: " ", with: "%20")

        if let url = URL(string: "obsidian://open?vault=\(vaultName)&file=\(filePath)") {
            NSWorkspace.shared.open(url)
        }
    }
}

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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let game = Game(name: "test", filePath: "")
    let session = Session(date: Date(), activities: "Test", plans: "Plans", thoughts: "Thoughts")

    return SessionDetailView(session: session, game: game)
        .modelContainer(for: Game.self, inMemory: true)
}
