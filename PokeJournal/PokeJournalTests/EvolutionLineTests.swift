//
//  EvolutionLineTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

// MARK: - Evolution Line Lookup Tests

struct EvolutionLineLookupTests {
    let db = PokemonDatabase.shared

    @Test func evolutionLine_bulbasaurFamily() {
        // Bisasam (Bulbasaur) id=1, Bisaknosp (Ivysaur) id=2, Bisaflor (Venusaur) id=3
        // All share evolution_chain_id = 1
        let bisasam = db.find(byName: "Bisasam")!
        let line = db.evolutionLine(for: bisasam)
        #expect(line.count == 3)
        #expect(line.map(\.id) == [1, 2, 3])
    }

    @Test func evolutionLine_charmanderFamily() {
        // Glumanda (Charmander) id=4, Glutexo (Charmeleon) id=5, Glurak (Charizard) id=6
        let glumanda = db.find(byName: "Glumanda")!
        let line = db.evolutionLine(for: glumanda)
        #expect(line.count == 3)
        #expect(line.map(\.id) == [4, 5, 6])
    }

    @Test func evolutionLine_singleStagePokemon() {
        // Pokemon without evolutions should return just themselves
        let pokemon = db.find(byName: "Tauros")
        if let pokemon {
            let line = db.evolutionLine(for: pokemon)
            #expect(line.count == 1)
            #expect(line[0].id == pokemon.id)
        }
    }

    @Test func sameEvolutionLine_glumandaAndGlurak() {
        #expect(db.sameEvolutionLine("Glumanda", "Glurak") == true)
    }

    @Test func sameEvolutionLine_glumandaAndGlutexo() {
        #expect(db.sameEvolutionLine("Glumanda", "Glutexo") == true)
    }

    @Test func sameEvolutionLine_differentLines() {
        #expect(db.sameEvolutionLine("Glumanda", "Pikachu") == false)
    }

    @Test func sameEvolutionLine_unknownName_returnsFalse() {
        #expect(db.sameEvolutionLine("Glumanda", "UnknownMon") == false)
    }

    @Test func sameEvolutionLine_samePokemon() {
        #expect(db.sameEvolutionLine("Glurak", "Glurak") == true)
    }

    @Test func evolutionChainID_presentInData() {
        let bisasam = db.find(byName: "Bisasam")!
        #expect(bisasam.evolutionChainID != nil)
        #expect(bisasam.evolutionChainID == 1)
    }

    @Test func evolutionLineKey_unresolvedName_fallsBackToName() {
        let key = db.evolutionLineKey(for: "UnknownPokemon", variant: nil)
        #expect(key == "UnknownPokemon")
    }

    @Test func evolutionLineKey_resolvedName_returnsBaseName() {
        // Glutexo (Charmeleon) should return base form "Glumanda"
        let key = db.evolutionLineKey(for: "Glutexo", variant: nil)
        #expect(key == "Glumanda")
    }

    @Test func evolutionLineKey_variantReturnsDisplayName() {
        let key = db.evolutionLineKey(for: "Raichu", variant: "Alola")
        #expect(key == "Alola Raichu")
    }
}

// MARK: - TeamDiff Evolution Detection Tests

@Suite(.serialized)
@MainActor
struct TeamDiffEvolutionTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func teamDiff_detectsEvolution() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Previous team: Glumanda lvl 15
        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let prev = TeamMember(pokemonName: "Glumanda", level: 15)
        let current = TeamMember(pokemonName: "Glutexo", level: 25)

        // Insert into sessions so they persist
        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])

        // Glumanda→Glutexo should be an evolution, not added/removed
        #expect(diff.evolutions.count == 1)
        #expect(diff.evolutions[0].from.pokemonName == "Glumanda")
        #expect(diff.evolutions[0].to.pokemonName == "Glutexo")
        #expect(diff.added.isEmpty)
        #expect(diff.removed.isEmpty)
    }

    @Test func teamDiff_evolutionHasLevelDelta() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let prev = TeamMember(pokemonName: "Glumanda", level: 15)
        let current = TeamMember(pokemonName: "Glutexo", level: 25)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])
        #expect(diff.evolutions[0].levelDelta == 10)
    }

    @Test func teamDiff_evolutionWithZeroLevelDelta() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Stone evolution: same level
        let prev = TeamMember(pokemonName: "Pikachu", level: 30)
        let current = TeamMember(pokemonName: "Raichu", level: 30)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])
        #expect(diff.evolutions.count == 1)
        #expect(diff.evolutions[0].levelDelta == 0)
        #expect(diff.added.isEmpty)
        #expect(diff.removed.isEmpty)
    }

    @Test func teamDiff_nonEvolutionSwapStillTracked() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Pikachu swapped for Glurak — not same evolution line
        let prev = TeamMember(pokemonName: "Pikachu", level: 30)
        let current = TeamMember(pokemonName: "Glurak", level: 50)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prev.session = s1
        context.insert(prev)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        current.session = s2
        context.insert(current)
        try context.save()

        let diff = teamDiff(current: [current], previous: [prev])
        #expect(diff.evolutions.isEmpty)
        #expect(diff.added.count == 1)
        #expect(diff.removed.count == 1)
    }

    @Test func teamDiff_mixedEvolutionAndNewPokemon() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Previous: Glumanda + Pikachu
        // Current: Glutexo + Pikachu + Lapras
        let prevGlumanda = TeamMember(pokemonName: "Glumanda", level: 15)
        let prevPikachu = TeamMember(pokemonName: "Pikachu", level: 25)
        let curGlutexo = TeamMember(pokemonName: "Glutexo", level: 25)
        let curPikachu = TeamMember(pokemonName: "Pikachu", level: 30)
        let curLapras = TeamMember(pokemonName: "Lapras", level: 40)

        let s1 = Session(date: Date(), activities: "A")
        s1.game = game
        context.insert(s1)
        prevGlumanda.session = s1
        prevPikachu.session = s1
        context.insert(prevGlumanda)
        context.insert(prevPikachu)

        let s2 = Session(date: Date(), activities: "B")
        s2.game = game
        context.insert(s2)
        curGlutexo.session = s2
        curPikachu.session = s2
        curLapras.session = s2
        context.insert(curGlutexo)
        context.insert(curPikachu)
        context.insert(curLapras)
        try context.save()

        let diff = teamDiff(current: [curGlutexo, curPikachu, curLapras],
                           previous: [prevGlumanda, prevPikachu])

        #expect(diff.evolutions.count == 1) // Glumanda→Glutexo
        #expect(diff.added.count == 1) // Lapras
        #expect(diff.added[0].pokemonName == "Lapras")
        #expect(diff.removed.isEmpty) // Glumanda not "removed" — it evolved
        #expect(diff.levelChanges.count == 1) // Pikachu level change
    }
}

// MARK: - Merged Evolution Timelines Tests

@Suite(.serialized)
@MainActor
struct MergedEvolutionTimelineTests {

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

    @Test func glumandaEvolvesToGlutexo_sameTimeline() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        // Session 1: Glumanda lvl 10
        let s1 = Session(date: date("2025-01-01"), activities: "Start")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Glumanda", level: 10)
        m1.session = s1
        context.insert(m1)

        // Session 2: Glutexo lvl 20 (evolved)
        let s2 = Session(date: date("2025-01-02"), activities: "Evolved")
        s2.game = game
        context.insert(s2)
        let m2 = TeamMember(pokemonName: "Glutexo", level: 20)
        m2.session = s2
        context.insert(m2)

        // Session 3: Glurak lvl 36
        let s3 = Session(date: date("2025-01-03"), activities: "Evolved again")
        s3.game = game
        context.insert(s3)
        let m3 = TeamMember(pokemonName: "Glurak", level: 36)
        m3.session = s3
        context.insert(m3)

        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)

        // Should be 1 timeline (merged), not 3 separate ones
        #expect(timelines.count == 1)

        let timeline = timelines[0]
        // pokemonName should be the latest form
        #expect(timeline.pokemonName == "Glurak")
        // 1 continuous segment
        #expect(timeline.segments.count == 1)
        // 3 data points
        #expect(timeline.segments[0].dataPoints.count == 3)

        let levels = timeline.segments[0].dataPoints.map(\.level)
        #expect(levels == [10, 20, 36])
    }

    @Test func mergedTimeline_dataPointsCarryPokemonIdentity() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let m1 = TeamMember(pokemonName: "Glumanda", level: 10)
        m1.session = s1
        context.insert(m1)

        let s2 = Session(date: date("2025-01-02"), activities: "B")
        s2.game = game
        context.insert(s2)
        let m2 = TeamMember(pokemonName: "Glutexo", level: 20)
        m2.session = s2
        context.insert(m2)

        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        let points = timelines[0].segments[0].dataPoints

        // Each data point should know which specific pokemon form it represents
        #expect(points[0].pokemonName == "Glumanda")
        #expect(points[1].pokemonName == "Glutexo")
    }

    @Test func variantPokemon_notMergedWithBaseForm() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "Test", filePath: "/test.md")
        context.insert(game)

        let s1 = Session(date: date("2025-01-01"), activities: "A")
        s1.game = game
        context.insert(s1)
        let normal = TeamMember(pokemonName: "Raichu", level: 40)
        normal.session = s1
        let alola = TeamMember(pokemonName: "Raichu", level: 35, variant: "Alola")
        alola.session = s1
        context.insert(normal)
        context.insert(alola)
        try context.save()

        let timelines = TeamEvolutionDataBuilder.buildTimelines(from: game)
        #expect(timelines.count == 2) // Still separate
    }
}
