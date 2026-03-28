//
//  TeamEvolutionDataTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

// MARK: - Segment Building Tests (pure logic, no SwiftData)

struct TeamEvolutionSegmentTests {

    private func appearance(_ dateStr: String, level: Int, index: Int, name: String = "Test") -> (date: Date, level: Int, sessionIndex: Int, pokemonName: String, pokemonID: Int?) {
        (date: date(dateStr), level: level, sessionIndex: index, pokemonName: name, pokemonID: nil)
    }

    @Test func buildSegments_continuousPresence_oneSeg() {
        let appearances = [
            appearance("2025-01-01", level: 10, index: 0),
            appearance("2025-01-02", level: 15, index: 1),
            appearance("2025-01-03", level: 20, index: 2),
        ]

        let segments = TeamEvolutionDataBuilder.buildSegments(from: appearances, totalSessionCount: 3)
        #expect(segments.count == 1)
        #expect(segments[0].dataPoints.count == 3)
        #expect(segments[0].dataPoints[0].level == 10)
        #expect(segments[0].dataPoints[2].level == 20)
    }

    @Test func buildSegments_gapInMiddle_twoSegments() {
        let appearances = [
            appearance("2025-01-01", level: 10, index: 0),
            appearance("2025-01-02", level: 15, index: 1),
            // Gap: sessionIndex 2 and 3 missing
            appearance("2025-01-05", level: 25, index: 4),
            appearance("2025-01-06", level: 30, index: 5),
        ]

        let segments = TeamEvolutionDataBuilder.buildSegments(from: appearances, totalSessionCount: 6)
        #expect(segments.count == 2)
        #expect(segments[0].dataPoints.count == 2)
        #expect(segments[1].dataPoints.count == 2)
        #expect(segments[0].dataPoints.last!.level == 15)
        #expect(segments[1].dataPoints.first!.level == 25)
    }

    @Test func buildSegments_singleAppearance() {
        let appearances = [
            appearance("2025-01-05", level: 42, index: 3),
        ]

        let segments = TeamEvolutionDataBuilder.buildSegments(from: appearances, totalSessionCount: 10)
        #expect(segments.count == 1)
        #expect(segments[0].dataPoints.count == 1)
        #expect(segments[0].dataPoints[0].level == 42)
    }

    @Test func buildSegments_empty() {
        let appearances: [(date: Date, level: Int, sessionIndex: Int, pokemonName: String, pokemonID: Int?)] = []
        let segments = TeamEvolutionDataBuilder.buildSegments(from: appearances, totalSessionCount: 5)
        #expect(segments.isEmpty)
    }

    @Test func buildSegments_multipleGaps_threeSegments() {
        let appearances = [
            appearance("2025-01-01", level: 10, index: 0),
            // gap
            appearance("2025-01-03", level: 20, index: 2),
            // gap
            appearance("2025-01-05", level: 30, index: 4),
        ]

        let segments = TeamEvolutionDataBuilder.buildSegments(from: appearances, totalSessionCount: 5)
        #expect(segments.count == 3)
        #expect(segments[0].dataPoints[0].level == 10)
        #expect(segments[1].dataPoints[0].level == 20)
        #expect(segments[2].dataPoints[0].level == 30)
    }

    @Test func buildSegments_consecutiveIndices_noGap() {
        // sessionIndex 3,4 are consecutive — no gap
        let appearances = [
            appearance("2025-01-04", level: 50, index: 3),
            appearance("2025-01-05", level: 55, index: 4),
        ]

        let segments = TeamEvolutionDataBuilder.buildSegments(from: appearances, totalSessionCount: 10)
        #expect(segments.count == 1)
    }

    @Test func buildSegments_carriesPokemonIdentity() {
        let appearances = [
            appearance("2025-01-01", level: 10, index: 0, name: "Glumanda"),
            appearance("2025-01-02", level: 20, index: 1, name: "Glutexo"),
        ]

        let segments = TeamEvolutionDataBuilder.buildSegments(from: appearances, totalSessionCount: 2)
        #expect(segments[0].dataPoints[0].pokemonName == "Glumanda")
        #expect(segments[0].dataPoints[1].pokemonName == "Glutexo")
    }

    private func date(_ str: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: str)!
    }
}

// MARK: - Full Pipeline Tests (with SwiftData)

@Suite(.serialized)
@MainActor
struct TeamEvolutionPipelineTests {

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

    @Test func emptyGame_noTimelines() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)
        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines.isEmpty)
    }

    @Test func sessionsWithoutTeam_noTimelines() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let session = Session(date: date("2025-01-01"), activities: "Explored")
        session.game = game
        context.insert(session)
        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines.isEmpty)
    }

    @Test func singleSession_oneDataPointPerPokemon() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let session = Session(date: date("2025-01-01"), activities: "Battle")
        session.game = game
        context.insert(session)

        let m1 = TeamMember(pokemonName: "Glurak", level: 50)
        m1.session = session
        let m2 = TeamMember(pokemonName: "Pikachu", level: 30)
        m2.session = session
        context.insert(m1)
        context.insert(m2)
        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines.count == 2)

        for timeline in timelines {
            #expect(timeline.segments.count == 1)
            #expect(timeline.segments[0].dataPoints.count == 1)
        }
    }

    @Test func levelProgression_trackedOverSessions() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Session 1: Glurak lvl 30
        let s1 = Session(date: date("2025-01-01"), activities: "Start")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Glurak", level: 30)
        m1.session = s1
        context.insert(m1)

        // Session 2: Glurak lvl 45
        let s2 = Session(date: date("2025-01-02"), activities: "Training")
        s2.game = game
        context.insert(s2)
        let m2 = TeamMember(pokemonName: "Glurak", level: 45)
        m2.session = s2
        context.insert(m2)

        // Session 3: Glurak lvl 60
        let s3 = Session(date: date("2025-01-03"), activities: "Arena")
        s3.game = game
        context.insert(s3)
        let m3 = TeamMember(pokemonName: "Glurak", level: 60)
        m3.session = s3
        context.insert(m3)

        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines.count == 1)

        let glurak = timelines[0]
        #expect(glurak.pokemonName == "Glurak")
        #expect(glurak.segments.count == 1)

        let levels = glurak.segments[0].dataPoints.map(\.level)
        #expect(levels == [30, 45, 60])
    }

    @Test func teamChange_createsSegmentGap() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Session 1: Glurak + Pikachu
        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let m1a = TeamMember(pokemonName: "Glurak", level: 30)
        m1a.session = s1
        let m1b = TeamMember(pokemonName: "Pikachu", level: 20)
        m1b.session = s1
        context.insert(m1a)
        context.insert(m1b)

        // Session 2: only Pikachu (Glurak removed)
        let s2 = Session(date: date("2025-01-02"), activities: "B")
        s2.game = game
        context.insert(s2)
        let m2 = TeamMember(pokemonName: "Pikachu", level: 25)
        m2.session = s2
        context.insert(m2)

        // Session 3: Glurak returns + Pikachu
        let s3 = Session(date: date("2025-01-03"), activities: "C")
        s3.game = game
        context.insert(s3)
        let m3a = TeamMember(pokemonName: "Glurak", level: 35)
        m3a.session = s3
        let m3b = TeamMember(pokemonName: "Pikachu", level: 30)
        m3b.session = s3
        context.insert(m3a)
        context.insert(m3b)

        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)

        let glurak = timelines.first { $0.pokemonName == "Glurak" }!
        let pikachu = timelines.first { $0.pokemonName == "Pikachu" }!

        // Glurak was absent in session 2 → 2 segments
        #expect(glurak.segments.count == 2)
        #expect(glurak.segments[0].dataPoints[0].level == 30)
        #expect(glurak.segments[1].dataPoints[0].level == 35)

        // Pikachu was present in all 3 → 1 continuous segment
        #expect(pikachu.segments.count == 1)
        #expect(pikachu.segments[0].dataPoints.count == 3)
    }

    @Test func combinesBothSessionTypes() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // OldSession
        let old = OldSession(date: date("2024-12-01"), activities: "Legacy")
        old.game = game
        context.insert(old)
        let mOld = TeamMember(pokemonName: "Glurak", level: 20)
        mOld.oldSession = old
        context.insert(mOld)

        // Regular Session (later date)
        let session = Session(date: date("2025-01-15"), activities: "New")
        session.game = game
        context.insert(session)
        let mNew = TeamMember(pokemonName: "Glurak", level: 50)
        mNew.session = session
        context.insert(mNew)

        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines.count == 1)

        let glurak = timelines[0]
        // Old and new session are far apart → 2 segments (gap)
        // But both are included
        let allLevels = glurak.segments.flatMap { $0.dataPoints.map(\.level) }
        #expect(allLevels.contains(20))
        #expect(allLevels.contains(50))
        #expect(glurak.firstAppearance == date("2024-12-01"))
        #expect(glurak.lastAppearance == date("2025-01-15"))
    }

    @Test func variantPokemon_trackedSeparately() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let session = Session(date: date("2025-01-01"), activities: "Battle")
        session.game = game
        context.insert(session)

        let normal = TeamMember(pokemonName: "Raichu", level: 40)
        normal.session = session
        let alola = TeamMember(pokemonName: "Raichu", level: 35, variant: "Alola")
        alola.session = session
        context.insert(normal)
        context.insert(alola)
        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines.count == 2)

        let names = timelines.map(\.displayName).sorted()
        #expect(names.contains("Alola Raichu"))
        #expect(names.contains("Raichu"))
    }

    @Test func sortedByFirstAppearance() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Session 1: only Pikachu
        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Pikachu", level: 10)
        m1.session = s1
        context.insert(m1)

        // Session 2: Pikachu + Glurak
        let s2 = Session(date: date("2025-01-02"), activities: "B")
        s2.game = game
        context.insert(s2)
        let m2a = TeamMember(pokemonName: "Pikachu", level: 15)
        m2a.session = s2
        let m2b = TeamMember(pokemonName: "Glurak", level: 30)
        m2b.session = s2
        context.insert(m2a)
        context.insert(m2b)

        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines[0].pokemonName == "Pikachu")
        #expect(timelines[1].pokemonName == "Glurak")
    }

    @Test func mixedSessionsWithAndWithoutTeam_noFalseGap() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Session 1: Glurak lvl 30
        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Glurak", level: 30)
        m1.session = s1
        context.insert(m1)

        // Session 2: no team (should be filtered out, not create a gap)
        let s2 = Session(date: date("2025-01-02"), activities: "Explored only")
        s2.game = game
        context.insert(s2)

        // Session 3: Glurak lvl 35
        let s3 = Session(date: date("2025-01-03"), activities: "C")
        s3.game = game
        context.insert(s3)
        let m3 = TeamMember(pokemonName: "Glurak", level: 35)
        m3.session = s3
        context.insert(m3)

        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines.count == 1)

        let glurak = timelines[0]
        // Session without team is filtered out → indices are consecutive → 1 segment
        #expect(glurak.segments.count == 1)
        #expect(glurak.segments[0].dataPoints.count == 2)
        #expect(glurak.segments[0].dataPoints[0].level == 30)
        #expect(glurak.segments[0].dataPoints[1].level == 35)
    }

    @Test func allSessionsSorted_filtersAndSorts() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Newer session (no team)
        let s1 = Session(date: date("2025-02-01"), activities: "No team")
        s1.game = game
        context.insert(s1)

        // Old session with team (earlier date)
        let old = OldSession(date: date("2024-06-01"), activities: "Old")
        old.game = game
        context.insert(old)
        let mOld = TeamMember(pokemonName: "Pikachu", level: 10)
        mOld.oldSession = old
        context.insert(mOld)

        // Regular session with team (middle date)
        let s2 = Session(date: date("2025-01-01"), activities: "With team")
        s2.game = game
        context.insert(s2)
        let m2 = TeamMember(pokemonName: "Glurak", level: 40)
        m2.session = s2
        context.insert(m2)

        try context.save()

        let sorted = TeamEvolutionDataBuilder.allSessionsSorted(from: game)
        // Only 2 sessions with teams, filtered and sorted chronologically
        #expect(sorted.count == 2)
        #expect(sorted[0].date == date("2024-06-01"))
        #expect(sorted[1].date == date("2025-01-01"))
    }
}
