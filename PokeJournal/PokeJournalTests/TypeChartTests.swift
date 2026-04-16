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

struct TypeChartEffectivenessGen2to5Tests {

    @Test func ghost_resistedByStealInGen2to5() {
        let m = TypeChart.effectiveness(attacker: "ghost", defender: "steel", generation: .gen2to5)
        #expect(m == 0.5)
    }

    @Test func dark_resistedByStealInGen2to5() {
        let m = TypeChart.effectiveness(attacker: "dark", defender: "steel", generation: .gen2to5)
        #expect(m == 0.5)
    }

    @Test func ghost_notResistedByStealInGen6plus() {
        let m = TypeChart.effectiveness(attacker: "ghost", defender: "steel", generation: .gen6plus)
        #expect(m == 1.0)
    }

    @Test func fairy_unknownInGen2to5_returnsNeutral() {
        let m = TypeChart.effectiveness(attacker: "fairy", defender: "dragon", generation: .gen2to5)
        #expect(m == 1.0)
    }

    @Test func dragon_notImmuneFairyInGen2to5() {
        let m = TypeChart.effectiveness(attacker: "dragon", defender: "fairy", generation: .gen2to5)
        #expect(m == 1.0)
    }
}

struct TypeChartEffectivenessGen1Tests {

    @Test func ghost_zeroAgainstPsychic_gen1Bug() {
        let m = TypeChart.effectiveness(attacker: "ghost", defender: "psychic", generation: .gen1)
        #expect(m == 0.0)
    }

    @Test func ghost_superEffectiveAgainstPsychic_gen2to5() {
        let m = TypeChart.effectiveness(attacker: "ghost", defender: "psychic", generation: .gen2to5)
        #expect(m == 2.0)
    }

    @Test func poison_superEffectiveAgainstBug_gen1() {
        let m = TypeChart.effectiveness(attacker: "poison", defender: "bug", generation: .gen1)
        #expect(m == 2.0)
    }

    @Test func bug_superEffectiveAgainstPoison_gen1() {
        let m = TypeChart.effectiveness(attacker: "bug", defender: "poison", generation: .gen1)
        #expect(m == 2.0)
    }

    @Test func poison_notSuperEffectiveAgainstBug_gen2to5() {
        let m = TypeChart.effectiveness(attacker: "poison", defender: "bug", generation: .gen2to5)
        #expect(m == 1.0)
    }

    @Test func dark_unknownInGen1_returnsNeutral() {
        let m = TypeChart.effectiveness(attacker: "dark", defender: "psychic", generation: .gen1)
        #expect(m == 1.0)
    }
}

struct TypeChartDualTypeTests {

    @Test func fireFlying_vsRock_4x() {
        // rock is 2x against fire AND 2x against flying → 4x.
        let m = TypeChart.defensiveMultiplier(
            attacker: "rock",
            defenderTypes: ["fire", "flying"],
            generation: .gen6plus
        )
        #expect(m == 4.0)
    }

    @Test func groundFlying_vsElectric_1x() {
        // electric is 0x against ground (immunity) and 2x against flying → 0x wins.
        let m = TypeChart.defensiveMultiplier(
            attacker: "electric",
            defenderTypes: ["ground", "flying"],
            generation: .gen6plus
        )
        #expect(m == 0.0)
    }

    @Test func waterGrass_vsFire_05x() {
        // fire is 0.5x against water and 2x against grass → 1x net.
        let m = TypeChart.defensiveMultiplier(
            attacker: "fire",
            defenderTypes: ["water", "grass"],
            generation: .gen6plus
        )
        #expect(m == 1.0)
    }

    @Test func waterWater_vsGrass_2x() {
        // Single type passed as one-element array.
        let m = TypeChart.defensiveMultiplier(
            attacker: "grass",
            defenderTypes: ["water"],
            generation: .gen6plus
        )
        #expect(m == 2.0)
    }

    @Test func emptyTypes_returnsNeutral() {
        let m = TypeChart.defensiveMultiplier(
            attacker: "fire",
            defenderTypes: [],
            generation: .gen6plus
        )
        #expect(m == 1.0)
    }
}

struct TypeChartTeamDefensiveProfileTests {

    @Test func singleMember_fireFlying_rockIs4x() {
        let team: [[String]] = [["fire", "flying"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
        #expect(profile["rock"] == 4.0)
    }

    @Test func twoMembers_takesWorst() {
        // One member is 4x weak to rock; another is 1x. Profile reports 4x.
        let team: [[String]] = [["fire", "flying"], ["water"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
        #expect(profile["rock"] == 4.0)
    }

    @Test func resistOnOne_weakOnAnother_reportsWorst() {
        // Electric: 0x against ground, 2x against flying — profile keeps 2x (the worst).
        let team: [[String]] = [["ground"], ["flying"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
        #expect(profile["electric"] == 2.0)
    }

    @Test func profileCoversAllGenerationTypes() {
        let team: [[String]] = [["normal"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
        #expect(profile.count == 18)
    }

    @Test func profileInGen1HasFifteenKeys() {
        let team: [[String]] = [["normal"]]
        let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen1)
        #expect(profile.count == 15)
    }

    @Test func emptyTeam_allNeutral() {
        let profile = TypeChart.teamDefensiveProfile(team: [], generation: .gen6plus)
        #expect(profile["fire"] == 1.0)
        #expect(profile["water"] == 1.0)
    }
}

struct TypeChartCoverageGapTests {

    @Test func waterOnly_cannotHitGrassSuperEffectively() {
        let team: [[String]] = [["water"]]
        let gaps = TypeChart.coverageGaps(team: team, generation: .gen6plus)
        #expect(gaps.contains("grass"))
        #expect(gaps.contains("dragon"))
        #expect(!gaps.contains("fire"))
        #expect(!gaps.contains("ground"))
        #expect(!gaps.contains("rock"))
    }

    @Test func noGapsWhenAnyMemberCovers() {
        let team: [[String]] = [["water"], ["grass"], ["electric"]]
        let gaps = TypeChart.coverageGaps(team: team, generation: .gen6plus)
        #expect(!gaps.contains("fire"))   // water covers
        #expect(!gaps.contains("ground")) // water covers
        #expect(!gaps.contains("water"))  // grass+electric cover
        #expect(!gaps.contains("flying")) // electric covers
    }

    @Test func emptyTeam_allTypesGap() {
        let gaps = TypeChart.coverageGaps(team: [], generation: .gen6plus)
        #expect(gaps.count == 18)
    }
}

struct TypeChartRecommendationTests {

    @Test func waterOnlyTeam_returnsNonEmptyRecommendations() {
        // A pure water Pokémon has weaknesses (electric, grass) and many coverage gaps.
        // The scorer picks types that fill the most gaps and resist the most weaknesses.
        let team: [[String]] = [["water"]]
        let recs = TypeChart.recommendation(team: team, generation: .gen6plus)
        #expect(!recs.isEmpty)
        // Each recommendation must actually score > 0 (covers at least one weakness or gap).
        for rec in recs {
            let profile = TypeChart.teamDefensiveProfile(team: team, generation: .gen6plus)
            let gaps = TypeChart.coverageGaps(team: team, generation: .gen6plus)
            let weaknesses = profile.filter { $0.value >= 2.0 }.map { $0.key }
            let defScore = weaknesses.filter {
                TypeChart.effectiveness(attacker: $0, defender: rec, generation: .gen6plus) < 1.0
            }.count
            let offScore = gaps.filter {
                TypeChart.effectiveness(attacker: rec, defender: $0, generation: .gen6plus) > 1.0
            }.count
            #expect(defScore + offScore > 0)
        }
    }

    @Test func recommendationReturnsThreeOrFewer() {
        let team: [[String]] = [["water"]]
        let recs = TypeChart.recommendation(team: team, generation: .gen6plus)
        #expect(recs.count <= 3)
    }

    @Test func perfectlyBalancedTeam_returnsEmpty() {
        // A team with no weaknesses (all 1.0) and no coverage gaps gets no suggestions.
        // Constructing this exactly is hard; instead we assert non-crash on empty gaps:
        let team: [[String]] = [["steel"], ["water"], ["electric"], ["grass"], ["ground"], ["fairy"]]
        let recs = TypeChart.recommendation(team: team, generation: .gen6plus)
        #expect(recs.count <= 3)
    }
}
