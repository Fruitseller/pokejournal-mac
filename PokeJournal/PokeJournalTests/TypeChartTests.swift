//
//  TypeChartTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
@testable import PokeJournal

struct TypeChartGenerationTests {

    @Test func gen1_hasFifteenTypes() {
        #expect(TypeChartGeneration.gen1.allTypes.count == 15)
    }

    @Test func gen2to5_hasSeventeenTypes() {
        #expect(TypeChartGeneration.gen2to5.allTypes.count == 17)
    }

    @Test func gen6plus_hasEighteenTypes() {
        #expect(TypeChartGeneration.gen6plus.allTypes.count == 18)
    }

    @Test func gen1_excludesDarkSteelFairy() {
        let types = TypeChartGeneration.gen1.allTypes
        #expect(!types.contains("dark"))
        #expect(!types.contains("steel"))
        #expect(!types.contains("fairy"))
    }

    @Test func gen2to5_includesDarkSteel_excludesFairy() {
        let types = TypeChartGeneration.gen2to5.allTypes
        #expect(types.contains("dark"))
        #expect(types.contains("steel"))
        #expect(!types.contains("fairy"))
    }

    @Test func gen6plus_includesAllEighteen() {
        let types = TypeChartGeneration.gen6plus.allTypes
        #expect(types.contains("dark"))
        #expect(types.contains("steel"))
        #expect(types.contains("fairy"))
    }
}
