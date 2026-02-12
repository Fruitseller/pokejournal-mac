//
//  SessionsListView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct SessionsListView: View {
    let game: Game

    var allSessions: [AnySession] {
        var combined: [AnySession] = []

        for session in game.sessions {
            combined.append(.regular(session))
        }

        for oldSession in game.oldSessions {
            combined.append(.old(oldSession))
        }

        return combined.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions (\(allSessions.count))")
                .font(.headline)

            let sessions = allSessions
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .navigationDestination(for: AnySession.self) { session in
            let sessions = allSessions
            let previousTeam = previousTeam(for: session, in: sessions)
            SessionDetailView(session: session, game: game, previousTeam: previousTeam)
        }
    }

    private func previousTeam(for session: AnySession, in sessions: [AnySession]) -> [TeamMember]? {
        // sessions is sorted newest-first, so the "previous" session is the next one in the array
        guard let index = sessions.firstIndex(of: session),
              index + 1 < sessions.count else {
            return nil
        }
        let previous = sessions[index + 1]
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
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
