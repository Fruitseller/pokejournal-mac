//
//  TeamEvolutionView.swift
//  PokéJournal
//

import SwiftUI
import Charts

struct TeamEvolutionView: View {
    let game: Game

    private var timelines: [PokemonTimeline] {
        TeamEvolutionDataBuilder.buildTimelines(from: game)
    }

    @State private var hiddenPokemon: Set<String> = []
    @State private var highlightedPokemon: String?
    @State private var pinnedPokemon: String?

    var body: some View {
        if timelines.isEmpty {
            ContentUnavailableView(
                "Keine Team-Daten",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Sessions mit Team-Daten werden hier als Level-Verlauf angezeigt.")
            )
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("Team-Entwicklung")
                    .font(.headline)

                TeamEvolutionChart(
                    timelines: timelines,
                    hiddenPokemon: hiddenPokemon,
                    highlightedPokemon: $highlightedPokemon,
                    pinnedPokemon: $pinnedPokemon
                )

                FilterBar(
                    timelines: timelines,
                    currentTeamNames: Set(game.currentTeam.map(\.displayName)),
                    hiddenPokemon: $hiddenPokemon
                )

                LegendView(
                    timelines: timelines,
                    hiddenPokemon: $hiddenPokemon,
                    highlightedPokemon: $highlightedPokemon,
                    pinnedPokemon: $pinnedPokemon
                )
            }
            .padding()
        }
    }
}

// MARK: - Filter Bar

struct FilterBar: View {
    let timelines: [PokemonTimeline]
    let currentTeamNames: Set<String>
    @Binding var hiddenPokemon: Set<String>

    var body: some View {
        HStack(spacing: 8) {
            Button("Alle anzeigen") {
                hiddenPokemon.removeAll()
            }
            .buttonStyle(.borderless)
            .disabled(hiddenPokemon.isEmpty)

            Button("Aktuelles Team") {
                let allNames = Set(timelines.map(\.displayName))
                hiddenPokemon = allNames.subtracting(currentTeamNames)
            }
            .buttonStyle(.borderless)

            Button("Keine") {
                hiddenPokemon = Set(timelines.map(\.displayName))
            }
            .buttonStyle(.borderless)
            .disabled(hiddenPokemon.count == timelines.count)

            Spacer()

            Text("\(timelines.count - hiddenPokemon.count)/\(timelines.count) sichtbar")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Chart

struct TeamEvolutionChart: View {
    let timelines: [PokemonTimeline]
    let hiddenPokemon: Set<String>
    @Binding var highlightedPokemon: String?
    @Binding var pinnedPokemon: String?

    @State private var zoomLevel: CGFloat = 1.0
    @State private var zoomBeforeGesture: CGFloat = 1.0
    @State private var hoveredPoint: HoveredDataPoint?

    private let baseHeight: CGFloat = 300
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 5.0

    private var visibleTimelines: [PokemonTimeline] {
        timelines.filter { !hiddenPokemon.contains($0.displayName) }
    }

    struct HoveredDataPoint {
        let pokemonName: String
        let pokemonID: Int?
        let typeColor: Color
        let level: Int
        let date: Date
        let location: CGPoint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Zoom controls
            HStack(spacing: 8) {
                Spacer()
                Button(action: { setZoom(max(minZoom, zoomLevel - 0.5)) }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .disabled(zoomLevel <= minZoom)

                Text("\(Int(zoomLevel * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 40)

                Button(action: { setZoom(min(maxZoom, zoomLevel + 0.5)) }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .disabled(zoomLevel >= maxZoom)

                Button(action: { setZoom(1.0) }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)
                .disabled(zoomLevel == 1.0)
            }

            // Scrollable + zoomable chart
            ScrollView([.horizontal, .vertical]) {
                chartContent
                    .frame(
                        width: max(400, 800 * zoomLevel),
                        height: baseHeight * zoomLevel
                    )
                    .padding(.trailing, 40)
            }
            .frame(minHeight: min(baseHeight * zoomLevel, 500))
            .scrollIndicators(.automatic)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let newZoom = zoomBeforeGesture * value.magnification
                        zoomLevel = min(maxZoom, max(minZoom, newZoom))
                    }
                    .onEnded { _ in
                        zoomBeforeGesture = zoomLevel
                    }
            )
        }
    }

    private func setZoom(_ value: CGFloat) {
        withAnimation {
            zoomLevel = value
            zoomBeforeGesture = value
        }
    }

    /// The effective highlight: pinned takes priority, then hover.
    private var effectiveHighlight: String? {
        pinnedPokemon ?? highlightedPokemon
    }

    private func opacity(for timeline: PokemonTimeline) -> Double {
        guard let highlighted = effectiveHighlight else { return 1.0 }
        return timeline.displayName == highlighted ? 1.0 : 0.12
    }

    private func lineWidth(for timeline: PokemonTimeline) -> CGFloat {
        guard let highlighted = effectiveHighlight else { return 2.5 }
        return timeline.displayName == highlighted ? 4.0 : 1.5
    }

    private var chartContent: some View {
        Chart {
            ForEach(visibleTimelines) { timeline in
                ForEach(timeline.segments) { segment in
                    ForEach(segment.dataPoints) { point in
                        LineMark(
                            x: .value("Datum", point.date),
                            y: .value("Level", point.level),
                            series: .value("Pokémon", timeline.displayName)
                        )
                        .foregroundStyle(timeline.typeColor.opacity(opacity(for: timeline)))
                        .lineStyle(StrokeStyle(lineWidth: lineWidth(for: timeline)))
                        .interpolationMethod(.stepEnd)

                        PointMark(
                            x: .value("Datum", point.date),
                            y: .value("Level", point.level)
                        )
                        .foregroundStyle(timeline.typeColor.opacity(opacity(for: timeline)))
                        .symbolSize(30)
                    }
                }
            }

            if let hp = hoveredPoint {
                RuleMark(x: .value("Hover", hp.date))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxisLabel("Level")
        .chartXAxisLabel("Datum")
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            let point = findClosestPoint(at: location, proxy: proxy, geo: geo)
                            hoveredPoint = point
                            if pinnedPokemon == nil {
                                highlightedPokemon = point?.pokemonName
                            }
                        case .ended:
                            hoveredPoint = nil
                            if pinnedPokemon == nil {
                                highlightedPokemon = nil
                            }
                        }
                    }
                    .onTapGesture {
                        if let hovered = hoveredPoint?.pokemonName {
                            if pinnedPokemon == hovered {
                                // Unpin
                                pinnedPokemon = nil
                                highlightedPokemon = hovered
                            } else {
                                pinnedPokemon = hovered
                            }
                        } else {
                            // Click on empty area → unpin
                            pinnedPokemon = nil
                            highlightedPokemon = nil
                        }
                    }

                // Sprites at line ends
                spriteAnnotations(proxy: proxy, geo: geo)

                if let hp = hoveredPoint {
                    tooltipView(for: hp, in: geo)
                }
            }
        }
    }

    // MARK: - Sprite Annotations at Line Ends

    @ViewBuilder
    private func spriteAnnotations(proxy: ChartProxy, geo: GeometryProxy) -> some View {
        let plotFrame = geo[proxy.plotFrame!]

        ForEach(visibleTimelines) { timeline in
            if let lastSegment = timeline.segments.last,
               let lastPoint = lastSegment.dataPoints.last,
               let xPos = proxy.position(forX: lastPoint.date),
               let yPos = proxy.position(forY: lastPoint.level) {
                let screenX = plotFrame.origin.x + xPos
                let screenY = plotFrame.origin.y + yPos
                let spriteOpacity = opacity(for: timeline)

                Group {
                    if let pokemonID = timeline.pokemonID,
                       let nsImage = NSImage(named: "pokemon_\(pokemonID)") {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    } else {
                        Circle()
                            .fill(timeline.typeColor)
                            .frame(width: 8, height: 8)
                    }
                }
                .opacity(spriteOpacity)
                .position(x: screenX + 14, y: screenY)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    private func tooltipView(for hp: HoveredDataPoint, in geo: GeometryProxy) -> some View {
        let tooltipWidth: CGFloat = 180
        let tooltipHeight: CGFloat = 56
        let x = min(max(hp.location.x + 12, 0), geo.size.width - tooltipWidth)
        let y = max(hp.location.y - tooltipHeight - 8, 0)

        HStack(spacing: 8) {
            if let pokemonID = hp.pokemonID,
               let nsImage = NSImage(named: "pokemon_\(pokemonID)") {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else {
                Circle()
                    .fill(hp.typeColor)
                    .frame(width: 12, height: 12)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(hp.pokemonName)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Lvl \(hp.level)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(hp.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 4)
        .position(x: x + tooltipWidth / 2, y: y + tooltipHeight / 2)
        .allowsHitTesting(false)
    }

    // MARK: - Hit Testing

    private func findClosestPoint(
        at location: CGPoint,
        proxy: ChartProxy,
        geo: GeometryProxy
    ) -> HoveredDataPoint? {
        let plotFrame = geo[proxy.plotFrame!]

        guard plotFrame.contains(location) else { return nil }

        var closest: HoveredDataPoint?
        var closestDistance: CGFloat = .greatestFiniteMagnitude
        let maxHitDistance: CGFloat = 30

        for timeline in visibleTimelines {
            for segment in timeline.segments {
                for point in segment.dataPoints {
                    guard let xPos = proxy.position(forX: point.date),
                          let yPos = proxy.position(forY: point.level) else { continue }

                    let pointLocation = CGPoint(
                        x: plotFrame.origin.x + xPos,
                        y: plotFrame.origin.y + yPos
                    )
                    let dx = location.x - pointLocation.x
                    let dy = location.y - pointLocation.y
                    let dist = sqrt(dx * dx + dy * dy)

                    if dist < closestDistance && dist < maxHitDistance {
                        closestDistance = dist
                        closest = HoveredDataPoint(
                            pokemonName: timeline.displayName,
                            pokemonID: timeline.pokemonID,
                            typeColor: timeline.typeColor,
                            level: point.level,
                            date: point.date,
                            location: location
                        )
                    }
                }
            }
        }

        if closest == nil {
            guard let cursorDate: Date = proxy.value(atX: location.x - plotFrame.origin.x) else {
                return nil
            }
            closest = findNearestLineAtDate(cursorDate, cursorY: location.y, proxy: proxy, plotFrame: plotFrame, cursorLocation: location)
        }

        return closest
    }

    private func findNearestLineAtDate(
        _ date: Date,
        cursorY: CGFloat,
        proxy: ChartProxy,
        plotFrame: CGRect,
        cursorLocation: CGPoint
    ) -> HoveredDataPoint? {
        var closest: HoveredDataPoint?
        var closestYDist: CGFloat = .greatestFiniteMagnitude

        for timeline in visibleTimelines {
            for segment in timeline.segments {
                guard let interpolatedLevel = interpolateLevel(at: date, in: segment) else { continue }

                guard let yPos = proxy.position(forY: interpolatedLevel) else { continue }
                let screenY = plotFrame.origin.y + yPos
                let dist = abs(cursorY - screenY)

                if dist < closestYDist && dist < 20 {
                    closestYDist = dist
                    closest = HoveredDataPoint(
                        pokemonName: timeline.displayName,
                        pokemonID: timeline.pokemonID,
                        typeColor: timeline.typeColor,
                        level: Int(interpolatedLevel),
                        date: date,
                        location: cursorLocation
                    )
                }
            }
        }

        return closest
    }

    private func interpolateLevel(at date: Date, in segment: PokemonTimeline.TimelineSegment) -> Double? {
        let points = segment.dataPoints
        guard let first = points.first, let last = points.last else { return nil }
        guard date >= first.date && date <= last.date else { return nil }

        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]

            if date >= p1.date && date <= p2.date {
                let totalTime = p2.date.timeIntervalSince(p1.date)
                guard totalTime > 0 else { return Double(p1.level) }
                let elapsed = date.timeIntervalSince(p1.date)
                let fraction = elapsed / totalTime
                return Double(p1.level) + fraction * Double(p2.level - p1.level)
            }
        }

        return nil
    }
}

// MARK: - Legend

struct LegendView: View {
    let timelines: [PokemonTimeline]
    @Binding var hiddenPokemon: Set<String>
    @Binding var highlightedPokemon: String?
    @Binding var pinnedPokemon: String?

    private var effectiveHighlight: String? {
        pinnedPokemon ?? highlightedPokemon
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(timelines) { timeline in
                let isHidden = hiddenPokemon.contains(timeline.displayName)
                let isPinned = pinnedPokemon == timeline.displayName
                let isDimmed = {
                    if let highlighted = effectiveHighlight {
                        return timeline.displayName != highlighted
                    }
                    return false
                }()

                legendItem(for: timeline, isHidden: isHidden, isPinned: isPinned, isDimmed: isDimmed)
            }
        }
    }

    private func legendItem(for timeline: PokemonTimeline, isHidden: Bool, isPinned: Bool, isDimmed: Bool) -> some View {
        HStack(spacing: 4) {
            if let pokemonID = timeline.pokemonID,
               let nsImage = NSImage(named: "pokemon_\(pokemonID)") {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            } else {
                Circle()
                    .fill(timeline.typeColor)
                    .frame(width: 8, height: 8)
            }

            Text(timeline.displayName)
                .font(.caption2)

            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(timeline.typeColor)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            isHidden ? .clear : timeline.typeColor.opacity(isPinned ? 0.3 : 0.15),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isHidden ? Color.gray.opacity(0.2) : timeline.typeColor.opacity(isPinned ? 0.8 : 0.4),
                    lineWidth: isPinned ? 2 : 1
                )
        )
        .opacity(isHidden ? 0.4 : (isDimmed ? 0.4 : 1.0))
        .onTapGesture(count: 1) {
            if isHidden {
                hiddenPokemon.remove(timeline.displayName)
            } else {
                hiddenPokemon.insert(timeline.displayName)
                if pinnedPokemon == timeline.displayName {
                    pinnedPokemon = nil
                }
            }
        }
        .onHover { hovering in
            if !isHidden && pinnedPokemon == nil {
                highlightedPokemon = hovering ? timeline.displayName : nil
            }
        }
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
