//
//  TimelineView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    let game: Game

    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []

        for session in game.sessions {
            items.append(TimelineItem(
                date: session.date,
                hasTeam: session.hasTeam,
                teamCount: session.team.count,
                isOld: false
            ))
        }

        for oldSession in game.oldSessions {
            items.append(TimelineItem(
                date: oldSession.date,
                hasTeam: oldSession.hasTeam,
                teamCount: oldSession.team.count,
                isOld: true
            ))
        }

        return items.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)

            if timelineItems.isEmpty {
                Text("Keine Sessions gefunden")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(timelineItems.enumerated()), id: \.offset) { index, item in
                            TimelinePoint(
                                item: item,
                                gap: index > 0 ? daysBetween(timelineItems[index - 1].date, item.date) : 0
                            )
                        }
                    }
                    .padding()
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

struct TimelineItem: Identifiable {
    let id = UUID()
    let date: Date
    let hasTeam: Bool
    let teamCount: Int
    let isOld: Bool
}

struct TimelinePoint: View {
    let item: TimelineItem
    let gap: Int

    var gapColor: Color {
        switch gap {
        case 0...7: return .green
        case 8...30: return .yellow
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            if gap > 0 {
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(gapColor.opacity(0.5))
                        .frame(width: CGFloat(min(gap, 60)), height: 2)
                }
            }

            Circle()
                .fill(item.hasTeam ? Color.accentColor : Color.secondary.opacity(0.5))
                .frame(width: 16, height: 16)
                .overlay {
                    if item.isOld {
                        Circle()
                            .stroke(Color.orange, lineWidth: 2)
                    }
                }

            Text(item.date, format: .dateTime.month(.abbreviated).day())
                .font(.caption2)
                .foregroundStyle(.secondary)

            if gap > 30 {
                Text("+\(gap)d")
                    .font(.caption2)
                    .foregroundStyle(gapColor)
            }
        }
    }
}

#Preview {
    let game = Game(name: "test", filePath: "")
    return TimelineView(game: game)
        .modelContainer(for: Game.self, inMemory: true)
}
