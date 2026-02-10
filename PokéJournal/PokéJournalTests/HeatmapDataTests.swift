//
//  HeatmapDataTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

// MARK: - Heatmap Data Builder Tests

struct HeatmapThresholdTests {

    @Test func calculateThresholds_fourValues() {
        let sorted = [10, 20, 30, 40]
        let t = HeatmapDataBuilder.calculateThresholds(from: sorted)
        #expect(t.p25 == 20)
        #expect(t.p50 == 30)
        #expect(t.p75 == 40)
    }

    @Test func calculateThresholds_singleValue() {
        let t = HeatmapDataBuilder.calculateThresholds(from: [100])
        #expect(t.p25 == 100)
        #expect(t.p50 == 100)
        #expect(t.p75 == 100)
    }

    @Test func calculateThresholds_empty() {
        let t = HeatmapDataBuilder.calculateThresholds(from: [])
        #expect(t.p25 == 0)
        #expect(t.p50 == 0)
        #expect(t.p75 == 0)
    }

    @Test func intensityLevel_noText_returnsMinimum() {
        let t = (p25: 10, p50: 20, p75: 30)
        #expect(HeatmapDataBuilder.intensityLevel(for: 0, thresholds: t) == 1)
    }

    @Test func intensityLevel_belowP25() {
        let t = (p25: 10, p50: 20, p75: 30)
        #expect(HeatmapDataBuilder.intensityLevel(for: 5, thresholds: t) == 1)
    }

    @Test func intensityLevel_betweenP25andP50() {
        let t = (p25: 10, p50: 20, p75: 30)
        #expect(HeatmapDataBuilder.intensityLevel(for: 15, thresholds: t) == 2)
    }

    @Test func intensityLevel_betweenP50andP75() {
        let t = (p25: 10, p50: 20, p75: 30)
        #expect(HeatmapDataBuilder.intensityLevel(for: 25, thresholds: t) == 3)
    }

    @Test func intensityLevel_aboveP75() {
        let t = (p25: 10, p50: 20, p75: 30)
        #expect(HeatmapDataBuilder.intensityLevel(for: 50, thresholds: t) == 4)
    }

    @Test func intensityLevel_singleSession_getsBrightest() {
        // When all thresholds are equal, the single value should get level 4
        let t = (p25: 100, p50: 100, p75: 100)
        #expect(HeatmapDataBuilder.intensityLevel(for: 100, thresholds: t) == 4)
    }
}

// MARK: - Weekday Index Tests

struct HeatmapWeekdayTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ str: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: str)!
    }

    @Test func weekdayIndex_monday() {
        // 2025-01-06 is a Monday
        #expect(HeatmapDataBuilder.weekdayIndex(for: date("2025-01-06"), calendar: calendar) == 0)
    }

    @Test func weekdayIndex_sunday() {
        // 2025-01-12 is a Sunday
        #expect(HeatmapDataBuilder.weekdayIndex(for: date("2025-01-12"), calendar: calendar) == 6)
    }

    @Test func weekdayIndex_wednesday() {
        // 2025-01-08 is a Wednesday
        #expect(HeatmapDataBuilder.weekdayIndex(for: date("2025-01-08"), calendar: calendar) == 2)
    }

    @Test func mondayOfWeek_fromWednesday() {
        let wed = date("2025-01-08")
        let monday = HeatmapDataBuilder.mondayOfWeek(for: wed, calendar: calendar)
        let expected = date("2025-01-06")
        #expect(calendar.isDate(monday, inSameDayAs: expected))
    }

    @Test func mondayOfWeek_alreadyMonday() {
        let mon = date("2025-01-06")
        let monday = HeatmapDataBuilder.mondayOfWeek(for: mon, calendar: calendar)
        #expect(calendar.isDate(monday, inSameDayAs: mon))
    }

    @Test func sundayOfWeek_fromWednesday() {
        let wed = date("2025-01-08")
        let sunday = HeatmapDataBuilder.sundayOfWeek(for: wed, calendar: calendar)
        let expected = date("2025-01-12")
        #expect(calendar.isDate(sunday, inSameDayAs: expected))
    }
}

// MARK: - Grid Building Tests

@Suite(.serialized)
@MainActor
struct HeatmapGridTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ str: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: str)!
    }

    @Test func buildGrid_emptyGame() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)
        try context.save()

        let grid = HeatmapDataBuilder.buildGrid(from: game)
        #expect(grid.weeks.isEmpty)
        #expect(grid.monthLabels.isEmpty)
    }

    @Test func buildGrid_singleSession_oneWeek() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        // 2025-01-08 is a Wednesday
        let session = Session(date: date("2025-01-08"), activities: "Played today")
        session.game = game
        context.insert(session)
        try context.save()

        let grid = HeatmapDataBuilder.buildGrid(from: game)
        #expect(grid.weeks.count == 1) // One full week
        #expect(grid.weeks[0].count == 7) // Always 7 days per week

        // Wednesday is index 2 (Mon=0)
        #expect(grid.weeks[0][2].sessionCount == 1)
        #expect(grid.weeks[0][2].intensityLevel > 0)

        // Other days should be empty
        #expect(grid.weeks[0][0].sessionCount == 0)
        #expect(grid.weeks[0][0].intensityLevel == 0)
    }

    @Test func buildGrid_twoSessionsSameDay_merged() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: date("2025-01-08"), activities: "Morning session")
        s1.game = game
        let s2 = Session(date: date("2025-01-08"), activities: "Evening session")
        s2.game = game
        context.insert(s1)
        context.insert(s2)
        try context.save()

        let grid = HeatmapDataBuilder.buildGrid(from: game)
        let wednesday = grid.weeks[0][2]
        #expect(wednesday.sessionCount == 2)
        #expect(wednesday.textLength == "Morning session".count + "Evening session".count)
    }

    @Test func buildGrid_combinesBothSessionTypes() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        // 2025-01-06 Monday (new session) and 2025-01-07 Tuesday (old session)
        let session = Session(date: date("2025-01-06"), activities: "New format")
        session.game = game
        let oldSession = OldSession(date: date("2025-01-07"), activities: "Old format")
        oldSession.game = game
        context.insert(session)
        context.insert(oldSession)
        try context.save()

        let grid = HeatmapDataBuilder.buildGrid(from: game)
        #expect(grid.weeks.count == 1)
        #expect(grid.weeks[0][0].sessionCount == 1) // Monday
        #expect(grid.weeks[0][1].sessionCount == 1) // Tuesday
    }

    @Test func buildGrid_acrossWeeks_multipleWeeks() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        // Two sessions 2 weeks apart
        let s1 = Session(date: date("2025-01-06"), activities: "Week 1")
        s1.game = game
        let s2 = Session(date: date("2025-01-20"), activities: "Week 3")
        s2.game = game
        context.insert(s1)
        context.insert(s2)
        try context.save()

        let grid = HeatmapDataBuilder.buildGrid(from: game)
        #expect(grid.weeks.count >= 3) // At least 3 weeks span
    }

    @Test func buildGrid_everyWeekHasSevenDays() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: date("2025-01-08"), activities: "A")
        s1.game = game
        let s2 = Session(date: date("2025-02-15"), activities: "B")
        s2.game = game
        context.insert(s1)
        context.insert(s2)
        try context.save()

        let grid = HeatmapDataBuilder.buildGrid(from: game)
        for week in grid.weeks {
            #expect(week.count == 7, "Every week must have exactly 7 days")
        }
    }

    @Test func buildGrid_monthLabels_present() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        // Sessions spanning Jan and Feb
        let s1 = Session(date: date("2025-01-15"), activities: "Jan")
        s1.game = game
        let s2 = Session(date: date("2025-02-15"), activities: "Feb")
        s2.game = game
        context.insert(s1)
        context.insert(s2)
        try context.save()

        let grid = HeatmapDataBuilder.buildGrid(from: game)
        let monthNames = grid.monthLabels.map(\.name)
        #expect(monthNames.contains("Jan"))
        #expect(monthNames.contains("Feb"))
    }
}
