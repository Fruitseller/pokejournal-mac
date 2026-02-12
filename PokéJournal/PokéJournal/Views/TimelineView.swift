//
//  TimelineView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - Data Model

struct TimelineSegment: Identifiable {
    let id = UUID()
    let sessions: [TimelineSession]
    let gapDaysAfter: Int?
}

struct TimelineSession: Identifiable {
    let id = UUID()
    let date: Date
    let teamMembers: [String]
    let activities: String
    let filePath: String?
}

// MARK: - Segment Builder

enum TimelineDataBuilder {
    static let gapThreshold = 14

    static func buildSegments(from game: Game) -> [TimelineSegment] {
        var allSessions: [TimelineSession] = []

        for s in game.sessions {
            allSessions.append(TimelineSession(
                date: s.date,
                teamMembers: s.team.map(\.displayName),
                activities: s.activities,
                filePath: s.filePath
            ))
        }

        for o in game.oldSessions {
            allSessions.append(TimelineSession(
                date: o.date,
                teamMembers: o.team.map(\.displayName),
                activities: o.activities,
                filePath: nil
            ))
        }

        allSessions.sort { $0.date < $1.date }
        guard !allSessions.isEmpty else { return [] }

        var segments: [TimelineSegment] = []
        var current: [TimelineSession] = [allSessions[0]]

        for i in 1..<allSessions.count {
            let gap = daysBetween(allSessions[i - 1].date, allSessions[i].date)

            if gap >= gapThreshold {
                segments.append(TimelineSegment(sessions: current, gapDaysAfter: gap))
                current = []
            }

            current.append(allSessions[i])
        }

        segments.append(TimelineSegment(sessions: current, gapDaysAfter: nil))
        return segments
    }

    static func pixelsPerDay(for segment: TimelineSegment) -> CGFloat {
        guard segment.sessions.count >= 2,
              let first = segment.sessions.first?.date,
              let last = segment.sessions.last?.date else {
            return 40
        }

        let totalDays = max(
            1,
            Calendar.current.dateComponents([.day], from: first, to: last).day ?? 1
        )

        let availableWidth: CGFloat = 400
        let raw = availableWidth / CGFloat(totalDays)
        return min(max(raw, 20), 60)
    }

    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        Calendar.current.dateComponents([.day], from: a, to: b).day ?? 0
    }

    static func year(of date: Date) -> Int {
        Calendar.current.component(.year, from: date)
    }
}

// MARK: - Timeline View

struct TimelineView: View {
    let game: Game

    private var segments: [TimelineSegment] {
        TimelineDataBuilder.buildSegments(from: game)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)

            if segments.isEmpty {
                Text("Keine Sessions gefunden")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                            let prevDate = index > 0
                                ? segments[index - 1].sessions.last?.date
                                : nil

                            TimelineSegmentView(
                                segment: segment,
                                previousDate: prevDate,
                                vaultName: VaultManager.shared.vaultName
                            )

                            if let gapDays = segment.gapDaysAfter {
                                let fromYear = TimelineDataBuilder.year(
                                    of: segment.sessions.last!.date
                                )
                                let toYear = TimelineDataBuilder.year(
                                    of: segments[index + 1].sessions.first!.date
                                )
                                TimelineGapView(
                                    days: gapDays,
                                    yearChange: fromYear != toYear ? toYear : nil
                                )
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Layout Constants

private enum TimelineLayout {
    static let dotRadius: CGFloat = 6
    static let lineY: CGFloat = 24
    static let yearLabelY: CGFloat = 6
    static let dateLabelY: CGFloat = lineY + 20
    static let totalHeight: CGFloat = dateLabelY + 16
}

// MARK: - Segment View

struct TimelineSegmentView: View {
    let segment: TimelineSegment
    let previousDate: Date?
    let vaultName: String?

    private var ppd: CGFloat {
        TimelineDataBuilder.pixelsPerDay(for: segment)
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d. MMM"
        return f
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Connecting line
            if segment.sessions.count >= 2 {
                Path { path in
                    path.move(to: CGPoint(x: TimelineLayout.dotRadius, y: TimelineLayout.lineY))
                    path.addLine(to: CGPoint(x: totalWidth - TimelineLayout.dotRadius, y: TimelineLayout.lineY))
                }
                .stroke(Color.secondary.opacity(0.4), lineWidth: 2)
            }

            // Year labels (positioned above the line)
            ForEach(Array(segment.sessions.enumerated()), id: \.element.id) { i, session in
                if shouldShowYear(at: i) {
                    Text(String(TimelineDataBuilder.year(of: session.date)))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .position(x: xPosition(for: i), y: TimelineLayout.yearLabelY)
                }
            }

            // Session dots
            ForEach(Array(segment.sessions.enumerated()), id: \.element.id) { i, session in
                TimelineDotView(session: session, vaultName: vaultName)
                    .position(x: xPosition(for: i), y: TimelineLayout.lineY)
            }

            // Date labels
            ForEach(labelIndices, id: \.self) { i in
                Text(Self.dateFmt.string(from: segment.sessions[i].date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .position(x: xPosition(for: i), y: TimelineLayout.dateLabelY)
            }
        }
        .frame(width: totalWidth, height: TimelineLayout.totalHeight)
    }

    private func shouldShowYear(at index: Int) -> Bool {
        let currentYear = TimelineDataBuilder.year(of: segment.sessions[index].date)
        if index == 0 {
            guard let prev = previousDate else { return true }
            return TimelineDataBuilder.year(of: prev) != currentYear
        }
        return TimelineDataBuilder.year(of: segment.sessions[index - 1].date) != currentYear
    }

    private var totalWidth: CGFloat {
        guard segment.sessions.count >= 2 else { return TimelineLayout.dotRadius * 2 }

        var width: CGFloat = 0
        for i in 1..<segment.sessions.count {
            let days = TimelineDataBuilder.daysBetween(
                segment.sessions[i - 1].date,
                segment.sessions[i].date
            )
            width += max(CGFloat(days) * ppd, 20)
        }
        return width + TimelineLayout.dotRadius * 2
    }

    private func xPosition(for index: Int) -> CGFloat {
        guard index > 0 else { return TimelineLayout.dotRadius }

        var x: CGFloat = TimelineLayout.dotRadius
        for i in 1...index {
            let days = TimelineDataBuilder.daysBetween(
                segment.sessions[i - 1].date,
                segment.sessions[i].date
            )
            x += max(CGFloat(days) * ppd, 20)
        }
        return x
    }

    private var labelIndices: [Int] {
        guard !segment.sessions.isEmpty else { return [] }
        if segment.sessions.count == 1 { return [0] }

        var indices: Set<Int> = [0, segment.sessions.count - 1]

        if segment.sessions.count > 2 {
            var lastLabelDate = segment.sessions[0].date
            for i in 1..<(segment.sessions.count - 1) {
                let daysSinceLabel = TimelineDataBuilder.daysBetween(
                    lastLabelDate,
                    segment.sessions[i].date
                )
                if daysSinceLabel >= 7 {
                    indices.insert(i)
                    lastLabelDate = segment.sessions[i].date
                }
            }
        }

        return indices.sorted()
    }
}

// MARK: - Dot View (interactive)

struct TimelineDotView: View {
    let session: TimelineSession
    let vaultName: String?

    @State private var isHovered = false
    @State private var showPopover = false

    private static let tooltipFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: 12, height: 12)
            .scaleEffect(isHovered ? 1.4 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                showPopover = true
            }
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                SessionPopoverView(
                    session: session,
                    vaultName: vaultName
                )
            }
            .help(Self.tooltipFmt.string(from: session.date))
    }
}

// MARK: - Session Popover

struct SessionPopoverView: View {
    let session: TimelineSession
    let vaultName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(session.date, format: .dateTime.day().month(.wide).year())
                .font(.headline)

            if !session.teamMembers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Team (\(session.teamMembers.count))", systemImage: "person.3")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(session.teamMembers.joined(separator: ", "))
                        .font(.callout)
                }
            }

            if !session.activities.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Aktivitäten", systemImage: "gamecontroller")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(session.activities.prefix(200))
                        .font(.callout)
                        .lineLimit(4)
                }
            }

            if let filePath = session.filePath, !filePath.isEmpty {
                Divider()

                Button {
                    if let url = VaultManager.shared.obsidianURL(forFilePath: filePath) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("In Obsidian öffnen", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.link)
            }
        }
        .padding()
        .frame(minWidth: 200, maxWidth: 320)
    }
}

// MARK: - Gap View (Zigzag cut)

struct TimelineGapView: View {
    let days: Int
    let yearChange: Int?

    var body: some View {
        ZStack {
            // Year label above the line
            if let year = yearChange {
                Text(String(year))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .position(x: 30, y: TimelineLayout.yearLabelY)
            }

            // Zigzag line at the same Y as dots
            Canvas { context, size in
                let midY = TimelineLayout.lineY
                var path = Path()

                let zigzagWidth: CGFloat = 8
                let zigzagHeight: CGFloat = 6
                let count = Int(size.width / zigzagWidth)

                path.move(to: CGPoint(x: 0, y: midY))
                for i in 0..<count {
                    let x = CGFloat(i) * zigzagWidth
                    let peak = i.isMultiple(of: 2) ? midY - zigzagHeight : midY + zigzagHeight
                    path.addLine(to: CGPoint(x: x + zigzagWidth, y: peak))
                }

                context.stroke(path, with: .color(.secondary.opacity(0.4)), lineWidth: 1.5)
            }

            // Days label below the line
            Text("\(days)d")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .position(x: 30, y: TimelineLayout.dateLabelY)
        }
        .frame(width: 60, height: TimelineLayout.totalHeight)
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    TimelineView(game: Game(name: "test", filePath: ""))
        .modelContainer(for: Game.self, inMemory: true)
}
