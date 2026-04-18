//
//  TeamAnalysisData.swift
//  PokéJournal
//

import Foundation

struct PokemonUsageEntry {
    let name: String
    let pokemonName: String
    let variant: String?
    let count: Int
    let maxLevel: Int
}

enum TeamAnalysisDataBuilder {

    static func buildUsage(from game: Game) -> [PokemonUsageEntry] {
        let db = PokemonDatabase.shared
        var usage: [String: (count: Int, maxLevel: Int, displayName: String, pokemonName: String, variant: String?, highestID: Int)] = [:]

        let allSessions: [[TeamMember]] =
            game.sessions.map(\.orderedTeam) + game.oldSessions.map(\.orderedTeam)

        for team in allSessions {
            var seenLines: Set<String> = []

            for member in team {
                let resolved = db.find(byName: member.pokemonName)
                let lineKey = db.evolutionLineKey(for: member.pokemonName, variant: member.variant)

                let resolvedID = resolved?.id ?? 0
                let current = usage[lineKey]

                let bestName: String
                let bestPokemon: String
                let bestVariant: String?
                let bestID: Int
                if let current, current.highestID >= resolvedID {
                    bestName = current.displayName
                    bestPokemon = current.pokemonName
                    bestVariant = current.variant
                    bestID = current.highestID
                } else {
                    bestName = member.displayName
                    bestPokemon = member.pokemonName
                    bestVariant = member.variant
                    bestID = resolvedID
                }

                let sessionIncrement = seenLines.insert(lineKey).inserted ? 1 : 0
                usage[lineKey] = (
                    count: (current?.count ?? 0) + sessionIncrement,
                    maxLevel: max(current?.maxLevel ?? 0, member.level),
                    displayName: bestName,
                    pokemonName: bestPokemon,
                    variant: bestVariant,
                    highestID: bestID
                )
            }
        }

        return usage.map {
            PokemonUsageEntry(
                name: $0.value.displayName,
                pokemonName: $0.value.pokemonName,
                variant: $0.value.variant,
                count: $0.value.count,
                maxLevel: $0.value.maxLevel
            )
        }
        .sorted { $0.count > $1.count }
    }
}
