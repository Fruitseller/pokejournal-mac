//
//  TeamDiffCalculator.swift
//  PokéJournal
//

import Foundation

struct TeamDiff {
    struct LevelChange {
        let member: TeamMember
        let delta: Int
    }

    struct Evolution {
        let from: TeamMember
        let to: TeamMember
        let levelDelta: Int
    }

    let added: [TeamMember]
    let removed: [TeamMember]
    let levelChanges: [LevelChange]
    let evolutions: [Evolution]

    var hasChanges: Bool {
        !added.isEmpty || !removed.isEmpty || !levelChanges.isEmpty || !evolutions.isEmpty
    }

    var changeCount: Int {
        added.count + removed.count + levelChanges.count + evolutions.count
    }
}

func teamDiff(current: [TeamMember], previous: [TeamMember]) -> TeamDiff {
    let currentByName = Dictionary(
        current.map { ($0.pokemonName.lowercased(), $0) },
        uniquingKeysWith: { first, _ in first }
    )
    let previousByName = Dictionary(
        previous.map { ($0.pokemonName.lowercased(), $0) },
        uniquingKeysWith: { first, _ in first }
    )

    var added = current.filter { previousByName[$0.pokemonName.lowercased()] == nil }
    var removed = previous.filter { currentByName[$0.pokemonName.lowercased()] == nil }

    let db = PokemonDatabase.shared
    var evolutions: [TeamDiff.Evolution] = []
    var matchedAdded: Set<String> = []
    var matchedRemoved: Set<String> = []

    for addedMember in added {
        for removedMember in removed {
            if matchedRemoved.contains(removedMember.pokemonName.lowercased()) { continue }
            if db.sameEvolutionLine(addedMember.pokemonName, removedMember.pokemonName) {
                evolutions.append(.init(
                    from: removedMember,
                    to: addedMember,
                    levelDelta: addedMember.level - removedMember.level
                ))
                matchedAdded.insert(addedMember.pokemonName.lowercased())
                matchedRemoved.insert(removedMember.pokemonName.lowercased())
                break
            }
        }
    }

    added.removeAll { matchedAdded.contains($0.pokemonName.lowercased()) }
    removed.removeAll { matchedRemoved.contains($0.pokemonName.lowercased()) }

    var levelChanges: [TeamDiff.LevelChange] = []
    for member in current {
        if let prev = previousByName[member.pokemonName.lowercased()] {
            let delta = member.level - prev.level
            if delta != 0 {
                levelChanges.append(.init(member: member, delta: delta))
            }
        }
    }

    return TeamDiff(added: added, removed: removed, levelChanges: levelChanges, evolutions: evolutions)
}
