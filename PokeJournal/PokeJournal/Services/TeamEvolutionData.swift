//
//  TeamEvolutionData.swift
//  PokéJournal
//

import Foundation
import SwiftUI

struct PokemonTimeline: Identifiable {
    let id = UUID()
    let pokemonName: String
    let variant: String?
    let pokemonID: Int?
    let typeColor: Color
    let segments: [TimelineSegment]
    let firstAppearance: Date
    let lastAppearance: Date

    var displayName: String {
        if let variant = variant {
            return "\(variant) \(pokemonName)"
        }
        return pokemonName
    }

    /// A continuous segment where the Pokémon was present in the team.
    struct TimelineSegment: Identifiable {
        let id = UUID()
        let dataPoints: [DataPoint]
    }

    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let level: Int
    }
}

enum TeamEvolutionDataBuilder {

    static func buildTimelines(from game: Game) -> [PokemonTimeline] {
        let sessions = allSessionsSorted(from: game)

        guard !sessions.isEmpty else { return [] }

        // Collect data points per Pokémon (keyed by displayName)
        var pokemonData: [String: (
            pokemonName: String,
            variant: String?,
            appearances: [(date: Date, level: Int, sessionIndex: Int)]
        )] = [:]

        for (index, session) in sessions.enumerated() {
            for member in session.team {
                let key = member.displayName
                if pokemonData[key] == nil {
                    pokemonData[key] = (
                        pokemonName: member.pokemonName,
                        variant: member.variant,
                        appearances: []
                    )
                }
                pokemonData[key]?.appearances.append((
                    date: session.date,
                    level: member.level,
                    sessionIndex: index
                ))
            }
        }

        // Build timelines
        return pokemonData.map { (key, data) in
            let pokemon = PokemonDatabase.shared.find(byName: data.pokemonName)
            let typeColor = pokemon.map { PokemonTypeColor.color(for: $0.primaryType) } ?? .gray

            let segments = buildSegments(
                from: data.appearances,
                totalSessionCount: sessions.count
            )

            return PokemonTimeline(
                pokemonName: data.pokemonName,
                variant: data.variant,
                pokemonID: pokemon?.id,
                typeColor: typeColor,
                segments: segments,
                firstAppearance: data.appearances.first!.date,
                lastAppearance: data.appearances.last!.date
            )
        }
        .sorted { $0.firstAppearance < $1.firstAppearance }
    }

    // MARK: - Internal

    static func allSessionsSorted(from game: Game) -> [AnySession] {
        var combined: [AnySession] = []
        for session in game.sessions {
            combined.append(.regular(session))
        }
        for oldSession in game.oldSessions {
            combined.append(.old(oldSession))
        }
        return combined
            .filter { $0.hasTeam }
            .sorted { $0.date < $1.date }
    }

    /// Splits appearances into segments — a gap of >1 session index means the Pokémon left and returned.
    static func buildSegments(
        from appearances: [(date: Date, level: Int, sessionIndex: Int)],
        totalSessionCount: Int
    ) -> [PokemonTimeline.TimelineSegment] {
        guard !appearances.isEmpty else { return [] }

        var segments: [PokemonTimeline.TimelineSegment] = []
        var currentPoints: [PokemonTimeline.DataPoint] = []

        for (i, appearance) in appearances.enumerated() {
            let point = PokemonTimeline.DataPoint(date: appearance.date, level: appearance.level)

            if i > 0 {
                let previousIndex = appearances[i - 1].sessionIndex
                let gap = appearance.sessionIndex - previousIndex

                // Gap > 1 means the Pokémon was absent for at least one session
                if gap > 1 {
                    segments.append(PokemonTimeline.TimelineSegment(dataPoints: currentPoints))
                    currentPoints = []
                }
            }

            currentPoints.append(point)
        }

        if !currentPoints.isEmpty {
            segments.append(PokemonTimeline.TimelineSegment(dataPoints: currentPoints))
        }

        return segments
    }
}
