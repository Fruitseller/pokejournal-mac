//
//  GameContentSignature.swift
//  PokéJournal
//

import Foundation

struct GameContentSignature: Equatable {
    let gameName: String
    let generation: TypeChartGeneration
    let sessions: [SessionSignature]
    let oldSessions: [SessionSignature]

    struct SessionSignature: Equatable {
        let date: Date
        let filePath: String?
        let textLength: Int
        let team: [TeamMemberSignature]
    }

    struct TeamMemberSignature: Equatable {
        let order: Int
        let displayName: String
        let pokemonName: String
        let variant: String?
        let level: Int
    }
}

enum GameContentSignatureBuilder {
    static func build(from game: Game) -> GameContentSignature {
        GameContentSignature(
            gameName: game.name,
            generation: game.generation,
            sessions: game.sessions
                .map {
                    GameContentSignature.SessionSignature(
                        date: $0.date,
                        filePath: $0.filePath,
                        textLength: $0.activities.count + $0.plans.count + $0.thoughts.count,
                        team: teamSignature(from: $0.orderedTeam)
                    )
                }
                .sorted { $0.date < $1.date },
            oldSessions: game.oldSessions
                .map {
                    GameContentSignature.SessionSignature(
                        date: $0.date,
                        filePath: nil,
                        textLength: $0.activities.count + $0.plans.count + $0.thoughts.count,
                        team: teamSignature(from: $0.orderedTeam)
                    )
                }
                .sorted { $0.date < $1.date }
        )
    }

    private static func teamSignature(from team: [TeamMember]) -> [GameContentSignature.TeamMemberSignature] {
        team.map {
            GameContentSignature.TeamMemberSignature(
                order: $0.order,
                displayName: $0.displayName,
                pokemonName: $0.pokemonName,
                variant: $0.variant,
                level: $0.level
            )
        }
    }
}
