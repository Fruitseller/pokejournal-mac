//
//  TeamCheckAnalyzer.swift
//  PokéJournal
//

import Foundation

struct TeamMemberAnalysis: Equatable, Sendable {
    let memberID: String
    let memberName: String
    let pokemonName: String
    let variant: String?
    let types: [String]
    let category: Category
    let reason: String?

    init(
        memberID: String? = nil,
        memberName: String,
        pokemonName: String? = nil,
        variant: String? = nil,
        types: [String],
        category: Category,
        reason: String?
    ) {
        self.memberID = memberID ?? pokemonName ?? memberName
        self.memberName = memberName
        self.pokemonName = pokemonName ?? memberName
        self.variant = variant
        self.types = types
        self.category = category
        self.reason = reason
    }

    enum Category: Equatable, Sendable {
        case kernstueck
        case ausgewogen
        case verzichtbar(ersatzTyp: String)
    }
}

enum TeamCheckAnalyzer {

    struct Member: Equatable, Sendable {
        let id: String
        let name: String
        let pokemonName: String
        let variant: String?
        let types: [String]

        init(
            name: String,
            types: [String],
            pokemonName: String? = nil,
            variant: String? = nil,
            id: String? = nil
        ) {
            self.id = id ?? pokemonName ?? name
            self.name = name
            self.pokemonName = pokemonName ?? name
            self.variant = variant
            self.types = types
        }
    }

    static func analyze(
        team: [Member],
        generation: TypeChartGeneration
    ) -> [TeamMemberAnalysis] {
        guard !team.isEmpty else { return [] }

        if team.count == 1 {
            let m = team[0]
            return [TeamMemberAnalysis(
                memberID: m.id,
                memberName: m.name,
                pokemonName: m.pokemonName,
                variant: m.variant,
                types: m.types,
                category: .kernstueck,
                reason: "Einziges Team-Mitglied"
            )]
        }

        return team.enumerated().map { idx, _ in
            categorize(at: idx, in: team, generation: generation)
        }
    }

    /// Categorize a team member via uniqueContribution + leaveOneOut.
    private static func categorize(
        at index: Int,
        in team: [Member],
        generation: TypeChartGeneration
    ) -> TeamMemberAnalysis {
        let member = team[index]
        let others = team.enumerated()
            .filter { $0.offset != index }
            .map { $0.element }

        let uDef = uniqueDefense(memberTypes: member.types, others: others, generation: generation)
        let uOff = uniqueOffense(memberTypes: member.types, others: others, generation: generation)
        let delta = leaveOneOutDelta(
            fullTeam: team.map(\.types),
            reducedTeam: others.map(\.types),
            generation: generation
        )

        let hasUniqueBeitrag = (uDef + uOff) >= 1
        let removalHurtsTeam = (delta.newGaps >= 1 || delta.newWeaknesses >= 1)

        if hasUniqueBeitrag && removalHurtsTeam {
            return TeamMemberAnalysis(
                memberID: member.id,
                memberName: member.name,
                pokemonName: member.pokemonName,
                variant: member.variant,
                types: member.types,
                category: .kernstueck,
                reason: kernstueckReason(uDef: uDef, uOff: uOff)
            )
        }

        let isVerzichtbar = !hasUniqueBeitrag && !removalHurtsTeam
        if isVerzichtbar {
            let recommendations = TypeChart.recommendation(
                team: others.map(\.types),
                generation: generation
            )
            if let ersatz = recommendations.first {
                let partner = overlapPartner(memberTypes: member.types, others: others)
                let reason = partner.map { "Redundant mit \($0.name)" }
                    ?? "Kein einzigartiger Beitrag"
                return TeamMemberAnalysis(
                    memberID: member.id,
                    memberName: member.name,
                    pokemonName: member.pokemonName,
                    variant: member.variant,
                    types: member.types,
                    category: .verzichtbar(ersatzTyp: ersatz),
                    reason: reason
                )
            }
            // No recommendation possible — reduced team already has no weaknesses or gaps.
            return TeamMemberAnalysis(
                memberID: member.id,
                memberName: member.name,
                pokemonName: member.pokemonName,
                variant: member.variant,
                types: member.types,
                category: .ausgewogen,
                reason: nil
            )
        }

        return TeamMemberAnalysis(
            memberID: member.id,
            memberName: member.name,
            pokemonName: member.pokemonName,
            variant: member.variant,
            types: member.types,
            category: .ausgewogen,
            reason: nil
        )
    }

    /// Count of attacker types where this member is the only one resistant (<1×) or immune (0×).
    private static func uniqueDefense(
        memberTypes: [String],
        others: [Member],
        generation: TypeChartGeneration
    ) -> Int {
        generation.allTypes.filter { attacker in
            let memberMultiplier = TypeChart.defensiveMultiplier(
                attacker: attacker,
                defenderTypes: memberTypes,
                generation: generation
            )
            guard memberMultiplier < 1.0 else { return false }
            let othersAlsoResist = others.contains { other in
                TypeChart.defensiveMultiplier(
                    attacker: attacker,
                    defenderTypes: other.types,
                    generation: generation
                ) < 1.0
            }
            return !othersAlsoResist
        }.count
    }

    /// Count of defender types where this member is the only one that can attack with >1×.
    private static func uniqueOffense(
        memberTypes: [String],
        others: [Member],
        generation: TypeChartGeneration
    ) -> Int {
        generation.allTypes.filter { defender in
            let memberBest = memberTypes.map {
                TypeChart.effectiveness(attacker: $0, defender: defender, generation: generation)
            }.max() ?? 1.0
            guard memberBest > 1.0 else { return false }
            let othersAlsoHit = others.contains { other in
                other.types.contains { attacker in
                    TypeChart.effectiveness(attacker: attacker, defender: defender, generation: generation) > 1.0
                }
            }
            return !othersAlsoHit
        }.count
    }

    /// Delta when removing a member: count of newly-introduced team-wide ≥×2 weaknesses
    /// and new offensive gaps. A "new weakness" means the full team still had at least
    /// one non-weak member (<×2), but every remaining member becomes weak after removal.
    private static func leaveOneOutDelta(
        fullTeam: [[String]],
        reducedTeam: [[String]],
        generation: TypeChartGeneration
    ) -> (newWeaknesses: Int, newGaps: Int) {
        let fullGaps = Set(TypeChart.coverageGaps(team: fullTeam, generation: generation))
        let reducedGaps = Set(TypeChart.coverageGaps(team: reducedTeam, generation: generation))

        let newWeaknesses = generation.allTypes.filter { attacker in
            let beforeHasNonWeakMember = fullTeam.contains { defenderTypes in
                TypeChart.defensiveMultiplier(
                    attacker: attacker,
                    defenderTypes: defenderTypes,
                    generation: generation
                ) < 2.0
            }
            let afterAllWeak = !reducedTeam.isEmpty && reducedTeam.allSatisfy { defenderTypes in
                TypeChart.defensiveMultiplier(
                    attacker: attacker,
                    defenderTypes: defenderTypes,
                    generation: generation
                ) >= 2.0
            }
            return beforeHasNonWeakMember && afterAllWeak
        }.count

        let newGaps = reducedGaps.subtracting(fullGaps).count

        return (newWeaknesses, newGaps)
    }

    /// Returns the first other team member that shares at least one type, if any.
    private static func overlapPartner(
        memberTypes: [String],
        others: [Member]
    ) -> Member? {
        let memberSet = Set(memberTypes)
        return others.first { !memberSet.isDisjoint(with: Set($0.types)) }
    }

    private static func kernstueckReason(uDef: Int, uOff: Int) -> String {
        if uDef > 0 && uOff > 0 {
            return "Deckt \(uDef) Schwächen und trifft \(uOff) Typen einzigartig"
        }
        if uDef > 0 {
            return uDef == 1 ? "Deckt 1 Schwäche allein ab" : "Deckt \(uDef) Schwächen allein ab"
        }
        return uOff == 1 ? "Einzige offensive Antwort gegen 1 Typ" : "Einzige offensive Antwort gegen \(uOff) Typen"
    }
}
