//
//  TypeMatchupData.swift
//  PokéJournal
//

import Foundation

struct TypeMatchupTeamMember: Equatable, Sendable {
    let id: String
    let displayName: String
    let pokemonName: String
    let variant: String?
}

struct TypeMatchupRelatedMember: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let pokemonName: String
    let variant: String?
}

struct TypeMatchupData: Equatable, Sendable {
    static let empty = TypeMatchupData(
        analyses: [],
        defensiveProfile: [:],
        offensiveProfile: [:],
        weakMembersByAttacker: [:],
        strongMembersByDefender: [:]
    )

    let analyses: [TeamMemberAnalysis]
    let defensiveProfile: [String: Double]
    let offensiveProfile: [String: Double]
    let weakMembersByAttacker: [String: [String]]
    let strongMembersByDefender: [String: [TypeMatchupRelatedMember]]
}

enum TypeMatchupDataBuilder {
    typealias TypeResolver = (_ pokemonName: String, _ variant: String?) -> [String]?

    private struct ResolvedMember {
        let source: TypeMatchupTeamMember
        let types: [String]
    }

    static func build(
        team: [TypeMatchupTeamMember],
        generation: TypeChartGeneration,
        resolveTypes: TypeResolver
    ) -> TypeMatchupData {
        let resolvedTeam = team.compactMap { member -> ResolvedMember? in
            guard let types = resolveTypes(member.pokemonName, member.variant) else {
                return nil
            }
            return ResolvedMember(source: member, types: types)
        }
        let teamTypes = resolvedTeam.map(\.types)
        let analyzerMembers = resolvedTeam.map { member in
            TeamCheckAnalyzer.Member(
                name: member.source.displayName,
                types: member.types,
                pokemonName: member.source.pokemonName,
                variant: member.source.variant,
                id: member.source.id
            )
        }

        return TypeMatchupData(
            analyses: TeamCheckAnalyzer.analyze(team: analyzerMembers, generation: generation),
            defensiveProfile: TypeChart.teamDefensiveProfile(team: teamTypes, generation: generation),
            offensiveProfile: TypeChart.teamOffensiveProfile(team: teamTypes, generation: generation),
            weakMembersByAttacker: weakMembersByAttacker(
                resolvedTeam: resolvedTeam,
                generation: generation
            ),
            strongMembersByDefender: strongMembersByDefender(
                resolvedTeam: resolvedTeam,
                generation: generation
            )
        )
    }

    private static func weakMembersByAttacker(
        resolvedTeam: [ResolvedMember],
        generation: TypeChartGeneration
    ) -> [String: [String]] {
        var result: [String: [String]] = [:]
        for attacker in generation.allTypes {
            let members = resolvedTeam.compactMap { member in
                let multiplier = TypeChart.defensiveMultiplier(
                    attacker: attacker,
                    defenderTypes: member.types,
                    generation: generation
                )
                return multiplier > 1.0 ? member.source.displayName : nil
            }
            if !members.isEmpty {
                result[attacker] = members
            }
        }
        return result
    }

    private static func strongMembersByDefender(
        resolvedTeam: [ResolvedMember],
        generation: TypeChartGeneration
    ) -> [String: [TypeMatchupRelatedMember]] {
        var result: [String: [TypeMatchupRelatedMember]] = [:]
        for defender in generation.allTypes {
            let members = resolvedTeam.compactMap { member -> TypeMatchupRelatedMember? in
                let best = member.types.map {
                    TypeChart.effectiveness(attacker: $0, defender: defender, generation: generation)
                }.max() ?? 1.0
                guard best > 1.0 else { return nil }
                return TypeMatchupRelatedMember(
                    id: member.source.id,
                    displayName: member.source.displayName,
                    pokemonName: member.source.pokemonName,
                    variant: member.source.variant
                )
            }
            if !members.isEmpty {
                result[defender] = members
            }
        }
        return result
    }
}
