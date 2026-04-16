//
//  GameGenerationTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

struct GameGenerationTests {

    @Test func releaseBefore2000_returnsGen1() {
        let game = Game(name: "red", filePath: "red.md")
        game.releaseDate = "1998-09-28"
        #expect(game.generation == .gen1)
    }

    @Test func release1999_returnsGen1() {
        let game = Game(name: "gelb", filePath: "gelb.md")
        game.releaseDate = "1999"
        #expect(game.generation == .gen1)
    }

    @Test func release2000_returnsGen2to5() {
        let game = Game(name: "gold", filePath: "gold.md")
        game.releaseDate = "2000-10-14"
        #expect(game.generation == .gen2to5)
    }

    @Test func release2012_returnsGen2to5() {
        let game = Game(name: "black2", filePath: "black2.md")
        game.releaseDate = "2012-06-23"
        #expect(game.generation == .gen2to5)
    }

    @Test func release2013_returnsGen6plus() {
        let game = Game(name: "x", filePath: "x.md")
        game.releaseDate = "2013-10-12"
        #expect(game.generation == .gen6plus)
    }

    @Test func release2022_returnsGen6plus() {
        let game = Game(name: "purpur", filePath: "purpur.md")
        game.releaseDate = "2022-11-18"
        #expect(game.generation == .gen6plus)
    }

    @Test func missingReleaseDate_defaultsToGen6plus() {
        let game = Game(name: "unknown", filePath: "unknown.md")
        game.releaseDate = nil
        #expect(game.generation == .gen6plus)
    }

    @Test func unparseableReleaseDate_defaultsToGen6plus() {
        let game = Game(name: "weird", filePath: "weird.md")
        game.releaseDate = "soon"
        #expect(game.generation == .gen6plus)
    }
}
