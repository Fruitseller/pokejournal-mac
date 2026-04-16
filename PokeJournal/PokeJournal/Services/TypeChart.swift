//
//  TypeChart.swift
//  PokéJournal
//

import Foundation

enum TypeChartGeneration {
    case gen1
    case gen2to5
    case gen6plus

    /// Canonical list of type identifiers (lowercase English) for this generation.
    /// Ordering matches the display order used in the matchup UI.
    var allTypes: [String] {
        let base = [
            "normal", "fire", "water", "electric", "grass", "ice",
            "fighting", "poison", "ground", "flying", "psychic", "bug",
            "rock", "ghost", "dragon"
        ]
        switch self {
        case .gen1:
            return base
        case .gen2to5:
            return base + ["dark", "steel"]
        case .gen6plus:
            return base + ["dark", "steel", "fairy"]
        }
    }
}
