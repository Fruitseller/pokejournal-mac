//
//  HeatmapView.swift
//  PokéJournal
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - Main View

struct HeatmapView: View {
    let game: Game

    private static let cellSize: CGFloat = 12
    private static let cellSpacing: CGFloat = 2
    private static let stride: CGFloat = 14 // cellSize + cellSpacing
    private static let weekdayLabelWidth: CGFloat = 24
    private static let weekdayLabels = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    @State private var grid = HeatmapGrid(weeks: [], monthLabels: [])
    @State private var hoveredCell: (week: Int, day: Int)?
    @State private var popoverCell: (week: Int, day: Int)?
    @State private var showPopover = false

    private static let tooltipFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heatmap")
                .font(.headline)

            if grid.weeks.isEmpty {
                Text("Keine Sessions gefunden")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        monthLabelsRow

                        HStack(alignment: .top, spacing: Self.cellSpacing) {
                            VStack(spacing: Self.cellSpacing) {
                                ForEach(0..<7, id: \.self) { i in
                                    Text(Self.weekdayLabels[i])
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .frame(
                                            width: Self.weekdayLabelWidth,
                                            height: Self.cellSize,
                                            alignment: .trailing
                                        )
                                }
                            }

                            gridCanvas
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                legendView
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            grid = HeatmapDataBuilder.buildGrid(from: game)
        }
    }

    // MARK: - Canvas Grid

    private var gridCanvas: some View {
        let gridWidth = CGFloat(grid.weeks.count) * Self.stride - Self.cellSpacing
        let gridHeight = 7 * Self.stride - Self.cellSpacing

        return Canvas { context, _ in
            for (weekIdx, week) in grid.weeks.enumerated() {
                for (dayIdx, day) in week.enumerated() {
                    let isHov = hoveredCell?.week == weekIdx
                        && hoveredCell?.day == dayIdx
                        && day.sessionCount > 0
                    let s = isHov ? Self.cellSize * 1.3 : Self.cellSize
                    let inset = (Self.cellSize - s) / 2

                    let x = CGFloat(weekIdx) * Self.stride + inset
                    let y = CGFloat(dayIdx) * Self.stride + inset
                    let rect = CGRect(x: x, y: y, width: s, height: s)
                    let path = Path(roundedRect: rect, cornerRadius: 2)
                    context.fill(path, with: .color(Self.colorForLevel(day.intensityLevel)))
                }
            }
        }
        .frame(width: gridWidth, height: gridHeight)
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                let w = Int(location.x / Self.stride)
                let d = Int(location.y / Self.stride)
                if w >= 0, w < grid.weeks.count, d >= 0, d < 7 {
                    hoveredCell = (w, d)
                } else {
                    hoveredCell = nil
                }
            case .ended:
                hoveredCell = nil
            }
        }
        .onTapGesture { location in
            let w = Int(location.x / Self.stride)
            let d = Int(location.y / Self.stride)
            if w >= 0, w < grid.weeks.count, d >= 0, d < 7,
               grid.weeks[w][d].sessionCount > 0 {
                popoverCell = (w, d)
                showPopover = true
            }
        }
        .popover(isPresented: $showPopover, attachmentAnchor: .point(popoverAnchor), arrowEdge: .bottom) {
            if let cell = popoverCell {
                HeatmapPopoverView(
                    day: grid.weeks[cell.week][cell.day],
                    vaultName: VaultManager.shared.vaultName
                )
            }
        }
        .help(hoveredTooltip)
    }

    private var popoverAnchor: UnitPoint {
        guard let cell = popoverCell, !grid.weeks.isEmpty else { return .center }
        let gridWidth = CGFloat(grid.weeks.count) * Self.stride - Self.cellSpacing
        let gridHeight = 7 * Self.stride - Self.cellSpacing
        let x = (CGFloat(cell.week) * Self.stride + Self.cellSize / 2) / gridWidth
        let y = (CGFloat(cell.day) * Self.stride + Self.cellSize / 2) / gridHeight
        return UnitPoint(x: x, y: y)
    }

    private var hoveredTooltip: String {
        guard let cell = hoveredCell,
              cell.week >= 0, cell.week < grid.weeks.count,
              cell.day >= 0, cell.day < 7 else { return "" }
        let day = grid.weeks[cell.week][cell.day]
        if day.sessionCount == 0 {
            return "\(Self.tooltipFmt.string(from: day.date)) – Keine Session"
        }
        let sessions = day.sessionCount == 1 ? "1 Session" : "\(day.sessionCount) Sessions"
        return "\(Self.tooltipFmt.string(from: day.date)) – \(sessions), \(day.textLength) Zeichen"
    }

    // MARK: - Month Labels

    private var monthLabelsRow: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: Self.weekdayLabelWidth + Self.cellSpacing)

            ForEach(Array(monthSpans.enumerated()), id: \.offset) { _, span in
                let spanWidth = CGFloat(span.weekCount) * Self.stride
                if span.weekCount >= 2 {
                    Text(span.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: spanWidth, alignment: .leading)
                } else {
                    Color.clear
                        .frame(width: spanWidth)
                }
            }
        }
    }

    private var monthSpans: [(name: String, weekCount: Int)] {
        let labels = grid.monthLabels
        guard !labels.isEmpty else { return [] }

        var spans: [(name: String, weekCount: Int)] = []
        for i in 0..<labels.count {
            let nextWeekIndex = i + 1 < labels.count ? labels[i + 1].weekIndex : grid.weeks.count
            spans.append((name: labels[i].name, weekCount: nextWeekIndex - labels[i].weekIndex))
        }
        return spans
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: 4) {
            Spacer()
            Text("Weniger")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Self.colorForLevel(level))
                    .frame(width: Self.cellSize, height: Self.cellSize)
            }

            Text("Mehr")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Colors

    static func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color.secondary.opacity(0.1)
        case 1: return Color.green.opacity(0.25)
        case 2: return Color.green.opacity(0.50)
        case 3: return Color.green.opacity(0.75)
        default: return Color.green.opacity(1.0)
        }
    }
}

// MARK: - Popover View

struct HeatmapPopoverView: View {
    let day: HeatmapDay
    let vaultName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.date, format: .dateTime.day().month(.wide).year())
                .font(.headline)

            let sessions = day.sessionCount == 1 ? "1 Session" : "\(day.sessionCount) Sessions"
            Text("\(sessions) · \(day.textLength) Zeichen")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !day.activities.isEmpty {
                Divider()
                Text(day.activities.prefix(200))
                    .font(.callout)
                    .lineLimit(4)
            }

            if let vaultName, let filePath = day.filePath, !filePath.isEmpty {
                Divider()
                Button {
                    let encoded = filePath.replacingOccurrences(of: " ", with: "%20")
                    if let url = URL(string: "obsidian://open?vault=\(vaultName)&file=\(encoded)") {
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

// MARK: - Preview

#Preview {
    HeatmapView(game: Game(name: "test", filePath: ""))
        .modelContainer(for: Game.self, inMemory: true)
}
