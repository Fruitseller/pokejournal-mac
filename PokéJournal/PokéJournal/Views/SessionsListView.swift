//
//  SessionsListView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct SessionsListView: View {
    let game: Game
    @State private var selectedSession: Session?

    private var allSessions: [(date: Date, isOld: Bool, session: Any)] {
        var combined: [(date: Date, isOld: Bool, session: Any)] = []

        for session in game.sessions {
            combined.append((session.date, false, session))
        }

        for oldSession in game.oldSessions {
            combined.append((oldSession.date, true, oldSession))
        }

        return combined.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions (\(allSessions.count))")
                .font(.headline)

            LazyVStack(spacing: 8) {
                ForEach(Array(allSessions.enumerated()), id: \.offset) { _, item in
                    SessionRowView(
                        date: item.date,
                        isOld: item.isOld,
                        hasTeam: hasTeam(item.session)
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func hasTeam(_ session: Any) -> Bool {
        if let s = session as? Session {
            return s.hasTeam
        }
        if let o = session as? OldSession {
            return o.hasTeam
        }
        return false
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
    return SessionsListView(game: game)
        .modelContainer(for: Game.self, inMemory: true)
}
