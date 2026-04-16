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

struct TypeChartEffectivenessGen6Tests {

    @Test func water_superEffectiveAgainstFire() {
        let m = TypeChart.effectiveness(attacker: "water", defender: "fire", generation: .gen6plus)
        #expect(m == 2.0)
    }

    @Test func fire_notVeryEffectiveAgainstWater() {
        let m = TypeChart.effectiveness(attacker: "fire", defender: "water", generation: .gen6plus)
        #expect(m == 0.5)
    }

    @Test func ground_immuneFromElectric() {
        let m = TypeChart.effectiveness(attacker: "electric", defender: "ground", generation: .gen6plus)
        #expect(m == 0.0)
    }

    @Test func normal_neutralAgainstGrass() {
        let m = TypeChart.effectiveness(attacker: "normal", defender: "grass", generation: .gen6plus)
        #expect(m == 1.0)
    }

    @Test func dragon_superEffectiveAgainstDragon() {
        let m = TypeChart.effectiveness(attacker: "dragon", defender: "dragon", generation: .gen6plus)
        #expect(m == 2.0)
    }

    @Test func fairy_superEffectiveAgainstDragon() {
        let m = TypeChart.effectiveness(attacker: "fairy", defender: "dragon", generation: .gen6plus)
        #expect(m == 2.0)
    }

    @Test func dragon_noEffectAgainstFairy() {
        let m = TypeChart.effectiveness(attacker: "dragon", defender: "fairy", generation: .gen6plus)
        #expect(m == 0.0)
    }

    @Test func unknownType_returnsNeutral() {
        let m = TypeChart.effectiveness(attacker: "unknown", defender: "fire", generation: .gen6plus)
        #expect(m == 1.0)
    }
}
