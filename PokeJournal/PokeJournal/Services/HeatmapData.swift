//
//  HeatmapData.swift
//  PokéJournal
//

import Foundation

struct HeatmapDay {
    let date: Date
    let sessionCount: Int
    let textLength: Int
    let intensityLevel: Int // 0-4
    let activities: String
    let filePath: String?
}

struct HeatmapGrid {
    let weeks: [[HeatmapDay]] // Each inner array has exactly 7 elements (Mon=0 to Sun=6)
    let monthLabels: [(name: String, weekIndex: Int)]
}

enum HeatmapDataBuilder {

    static func buildGrid(from game: Game) -> HeatmapGrid {
        let calendar = Calendar.current

        // Collect session data grouped by calendar day
        var dayMap: [Date: (textLength: Int, count: Int, activities: String, filePath: String?)] = [:]

        for s in game.sessions {
            let key = calendar.startOfDay(for: s.date)
            let textLen = s.activities.count + s.plans.count + s.thoughts.count
            if var existing = dayMap[key] {
                existing.textLength += textLen
                existing.count += 1
                dayMap[key] = existing
            } else {
                dayMap[key] = (textLen, 1, s.activities, s.filePath)
            }
        }

        for o in game.oldSessions {
            let key = calendar.startOfDay(for: o.date)
            let textLen = o.activities.count + o.plans.count + o.thoughts.count
            if var existing = dayMap[key] {
                existing.textLength += textLen
                existing.count += 1
                dayMap[key] = existing
            } else {
                dayMap[key] = (textLen, 1, o.activities, nil)
            }
        }

        guard !dayMap.isEmpty else {
            return HeatmapGrid(weeks: [], monthLabels: [])
        }

        // Calculate intensity thresholds from text lengths
        let textLengths = dayMap.values.map(\.textLength).sorted()
        let thresholds = calculateThresholds(from: textLengths)

        // Determine date range
        let allDates = Array(dayMap.keys)
        let minDate = allDates.min()!
        let maxDate = allDates.max()!

        // Extend to full weeks (Mon-Sun)
        let gridStart = mondayOfWeek(for: minDate, calendar: calendar)
        let gridEnd = sundayOfWeek(for: maxDate, calendar: calendar)

        // Build grid day by day
        var weeks: [[HeatmapDay]] = []
        var weekDays: [HeatmapDay] = []
        var monthLabels: [(name: String, weekIndex: Int)] = []
        var lastMonth: Int = -1
        var date = gridStart

        while date <= gridEnd {
            let month = calendar.component(.month, from: date)

            // Track month boundaries for labels
            if month != lastMonth {
                monthLabels.append((
                    name: calendar.shortMonthSymbols[month - 1],
                    weekIndex: weeks.count
                ))
                lastMonth = month
            }

            if let data = dayMap[date] {
                weekDays.append(HeatmapDay(
                    date: date,
                    sessionCount: data.count,
                    textLength: data.textLength,
                    intensityLevel: intensityLevel(for: data.textLength, thresholds: thresholds),
                    activities: data.activities,
                    filePath: data.filePath
                ))
            } else {
                weekDays.append(HeatmapDay(
                    date: date,
                    sessionCount: 0,
                    textLength: 0,
                    intensityLevel: 0,
                    activities: "",
                    filePath: nil
                ))
            }

            if weekDays.count == 7 {
                weeks.append(weekDays)
                weekDays = []
            }

            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        return HeatmapGrid(weeks: weeks, monthLabels: monthLabels)
    }

    // MARK: - Intensity

    static func calculateThresholds(from sortedLengths: [Int]) -> (p25: Int, p50: Int, p75: Int) {
        guard !sortedLengths.isEmpty else { return (0, 0, 0) }
        let n = sortedLengths.count
        return (
            p25: sortedLengths[n / 4],
            p50: sortedLengths[n / 2],
            p75: sortedLengths[n * 3 / 4]
        )
    }

    static func intensityLevel(for textLength: Int, thresholds: (p25: Int, p50: Int, p75: Int)) -> Int {
        guard textLength > 0 else { return 1 } // Session exists but no text → minimum green
        if textLength < thresholds.p25 { return 1 }
        if textLength < thresholds.p50 { return 2 }
        if textLength < thresholds.p75 { return 3 }
        return 4
    }

    // MARK: - Calendar Helpers

    /// Returns 0=Monday, 6=Sunday for a given date.
    static func weekdayIndex(for date: Date, calendar: Calendar) -> Int {
        let wd = calendar.component(.weekday, from: date) // 1=Sun, 2=Mon, ...
        return (wd + 5) % 7
    }

    static func mondayOfWeek(for date: Date, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        let idx = weekdayIndex(for: day, calendar: calendar)
        return calendar.date(byAdding: .day, value: -idx, to: day)!
    }

    static func sundayOfWeek(for date: Date, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        let idx = weekdayIndex(for: day, calendar: calendar)
        return calendar.date(byAdding: .day, value: 6 - idx, to: day)!
    }
}
