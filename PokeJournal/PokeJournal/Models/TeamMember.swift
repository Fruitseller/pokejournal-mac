//
//  TeamMember.swift
//  PokéJournal
//

import Foundation
import SwiftData

@Model
final class TeamMember {
    var pokemonName: String
    var level: Int
    var variant: String?
    var order: Int = 0

    @Relationship(inverse: \Session.team)
    var session: Session?

    @Relationship(inverse: \OldSession.team)
    var oldSession: OldSession?

    init(pokemonName: String, level: Int, variant: String? = nil) {
        self.pokemonName = pokemonName
        self.level = level
        self.variant = variant
    }

    var displayName: String {
        if let variant = variant {
            return "\(variant) \(pokemonName)"
        }
        return pokemonName
    }
}
