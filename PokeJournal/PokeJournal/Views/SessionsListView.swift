//
//  SessionsListView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct SessionsListView: View {
    let game: Game

    var body: some View {
        let sessions = game.allSessions.reversed() as [AnySession]
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions (\(sessions.count))")
                .font(.headline)

            LazyVStack(spacing: 8) {
                ForEach(sessions) { session in
                    NavigationLink(value: session) {
                        SessionRowView(
                            date: session.date,
                            isOld: session.isOld,
                            hasTeam: session.hasTeam
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .navigationDestination(for: AnySession.self) { session in
            let previousTeam = previousTeam(for: session)
            SessionDetailView(session: session, game: game, previousTeam: previousTeam)
        }
    }

    private func previousTeam(for session: AnySession) -> [TeamMember]? {
        let ascending = game.allSessions
        guard let index = ascending.firstIndex(of: session), index > 0 else {
            return nil
        }
        let previous = ascending[index - 1]
        guard !previous.team.isEmpty else { return nil }
        return previous.team
    }
}

struct SessionRowView: View {
    let date: Date
    let isOld: Bool
    let hasTeam: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(date, style: .date)
                    .font(.headline)

                HStack(spacing: 8) {
                    if isOld {
                        Text("Altes Format")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2), in: Capsule())
                    }

                    if hasTeam {
                        Label("Team", systemImage: "person.3")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}

#Preview {
    let game = Game(name: "test", filePath: "")
    return NavigationStack {
        SessionsListView(game: game)
    }
    .modelContainer(for: Game.self, inMemory: true)
}
