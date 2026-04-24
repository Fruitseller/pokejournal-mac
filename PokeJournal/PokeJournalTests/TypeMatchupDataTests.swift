//
//  TypeMatchupDataTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
@testable import PokeJournal

struct TypeMatchupDataTests {

    @Test func build_resolvesEachTeamMemberOnce() {
        var resolveCalls: [String] = []
        let members: [TypeMatchupTeamMember] = [
            .init(id: "0-glurak", displayName: "Glurak", pokemonName: "Glurak", variant: nil),
            .init(id: "1-turtok", displayName: "Turtok", pokemonName: "Turtok", variant: nil)
        ]

        let data = TypeMatchupDataBuilder.build(
            team: members,
            generation: .gen6plus
        ) { pokemonName, _ in
            resolveCalls.append(pokemonName)
            switch pokemonName {
            case "Glurak": return ["fire", "flying"]
            case "Turtok": return ["water"]
            default: return nil
            }
        }

        #expect(resolveCalls == ["Glurak", "Turtok"])
        #expect(data.analyses.map(\.memberName) == ["Glurak", "Turtok"])
        #expect(data.defensiveProfile["rock"] == 4.0)
        #expect(data.offensiveProfile["grass"] == 2.0)
        #expect(data.weakMembersByAttacker["rock"] == ["Glurak"])
        #expect(data.strongMembersByDefender["grass"]?.map(\.displayName) == ["Glurak"])
    }

    @Test func build_skipsMembersWithUnresolvedTypes() {
        let members: [TypeMatchupTeamMember] = [
            .init(id: "0-known", displayName: "Known", pokemonName: "Known", variant: nil),
            .init(id: "1-missing", displayName: "Missing", pokemonName: "Missing", variant: nil)
        ]

        let data = TypeMatchupDataBuilder.build(
            team: members,
            generation: .gen6plus
        ) { pokemonName, _ in
            pokemonName == "Known" ? ["electric"] : nil
        }

        #expect(data.analyses.count == 1)
        #expect(data.analyses.first?.memberName == "Known")
        #expect(data.weakMembersByAttacker["ground"] == ["Known"])
        #expect(data.strongMembersByDefender["water"]?.map(\.displayName) == ["Known"])
    }
}
