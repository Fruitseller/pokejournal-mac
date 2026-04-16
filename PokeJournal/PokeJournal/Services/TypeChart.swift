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

enum TypeChart {

    /// Gen 6+ canonical offensive multipliers. Only non-neutral (≠1.0) entries are listed.
    /// Format: attacker → [defender: multiplier]
    private static let gen6Matrix: [String: [String: Double]] = [
        "normal":   ["rock": 0.5, "ghost": 0.0, "steel": 0.5],
        "fire":     ["fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 2.0,
                     "bug": 2.0, "rock": 0.5, "dragon": 0.5, "steel": 2.0],
        "water":    ["fire": 2.0, "water": 0.5, "grass": 0.5, "ground": 2.0,
                     "rock": 2.0, "dragon": 0.5],
        "electric": ["water": 2.0, "electric": 0.5, "grass": 0.5, "ground": 0.0,
                     "flying": 2.0, "dragon": 0.5],
        "grass":    ["fire": 0.5, "water": 2.0, "grass": 0.5, "poison": 0.5,
                     "ground": 2.0, "flying": 0.5, "bug": 0.5, "rock": 2.0,
                     "dragon": 0.5, "steel": 0.5],
        "ice":      ["fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 0.5,
                     "ground": 2.0, "flying": 2.0, "dragon": 2.0, "steel": 0.5],
        "fighting": ["normal": 2.0, "ice": 2.0, "poison": 0.5, "flying": 0.5,
                     "psychic": 0.5, "bug": 0.5, "rock": 2.0, "ghost": 0.0,
                     "dark": 2.0, "steel": 2.0, "fairy": 0.5],
        "poison":   ["grass": 2.0, "poison": 0.5, "ground": 0.5, "rock": 0.5,
                     "ghost": 0.5, "steel": 0.0, "fairy": 2.0],
        "ground":   ["fire": 2.0, "electric": 2.0, "grass": 0.5, "poison": 2.0,
                     "flying": 0.0, "bug": 0.5, "rock": 2.0, "steel": 2.0],
        "flying":   ["electric": 0.5, "grass": 2.0, "fighting": 2.0, "bug": 2.0,
                     "rock": 0.5, "steel": 0.5],
        "psychic":  ["fighting": 2.0, "poison": 2.0, "psychic": 0.5, "dark": 0.0, "steel": 0.5],
        "bug":      ["fire": 0.5, "grass": 2.0, "fighting": 0.5, "poison": 0.5,
                     "flying": 0.5, "psychic": 2.0, "ghost": 0.5, "dark": 2.0,
                     "steel": 0.5, "fairy": 0.5],
        "rock":     ["fire": 2.0, "ice": 2.0, "fighting": 0.5, "ground": 0.5,
                     "flying": 2.0, "bug": 2.0, "steel": 0.5],
        "ghost":    ["normal": 0.0, "psychic": 2.0, "ghost": 2.0, "dark": 0.5],
        "dragon":   ["dragon": 2.0, "steel": 0.5, "fairy": 0.0],
        "dark":     ["fighting": 0.5, "psychic": 2.0, "ghost": 2.0, "dark": 0.5, "fairy": 0.5],
        "steel":    ["fire": 0.5, "water": 0.5, "electric": 0.5, "ice": 2.0,
                     "rock": 2.0, "steel": 0.5, "fairy": 2.0],
        "fairy":    ["fire": 0.5, "fighting": 2.0, "poison": 0.5, "dragon": 2.0,
                     "dark": 2.0, "steel": 0.5]
    ]

    /// Offensive effectiveness multiplier for a single attacker type against a single defender type.
    /// Returns 1.0 for unknown types or unspecified neutral matchups.
    static func effectiveness(attacker: String, defender: String, generation: TypeChartGeneration) -> Double {
        let matrix = matrixFor(generation)
        guard let row = matrix[attacker], let value = row[defender] else {
            return 1.0
        }
        return value
    }

    private static let gen2to5Matrix: [String: [String: Double]] = {
        var m = gen6Matrix
        // Drop fairy row entirely (type doesn't exist).
        m.removeValue(forKey: "fairy")
        // Drop fairy entries from every remaining row.
        for key in m.keys {
            m[key]?.removeValue(forKey: "fairy")
        }
        // Steel resisted ghost and dark pre-Gen 6.
        m["ghost"]?["steel"] = 0.5
        m["dark"]?["steel"] = 0.5
        // Dragon isn't countered by fairy in these gens; fairy entry already removed above.
        m["dragon"]?.removeValue(forKey: "fairy")
        return m
    }()

    private static func matrixFor(_ generation: TypeChartGeneration) -> [String: [String: Double]] {
        switch generation {
        case .gen6plus:
            return gen6Matrix
        case .gen2to5:
            return gen2to5Matrix
        case .gen1:
            // Filled in by Task 4.
            return gen2to5Matrix
        }
    }
}
