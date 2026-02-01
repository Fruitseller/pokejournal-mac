//
//  Pokemon.swift
//  PokéJournal
//

import Foundation

struct Pokemon: Codable, Identifiable, Hashable {
    let id: Int
    let nameDE: String
    let nameEN: String
    let types: [String]
    let spriteURL: String?
    let spritePixelURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nameDE = "name_de"
        case nameEN = "name_en"
        case types
        case spriteURL = "sprite_url"
        case spritePixelURL = "sprite_pixel_url"
    }

    var primaryType: String {
        types.first ?? "normal"
    }
}

class PokemonDatabase {
    static let shared = PokemonDatabase()

    private var pokemon: [Pokemon] = []
    private var nameLookup: [String: Pokemon] = [:]

    private init() {
        loadPokemonData()
    }

    private func loadPokemonData() {
        guard let url = Bundle.main.url(forResource: "pokemon", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Pokemon].self, from: data) else {
            return
        }

        pokemon = decoded

        for poke in pokemon {
            nameLookup[poke.nameDE.lowercased()] = poke
            nameLookup[poke.nameEN.lowercased()] = poke
        }
    }

    func find(byName name: String) -> Pokemon? {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)

        if let exact = nameLookup[normalizedName] {
            return exact
        }

        return fuzzyMatch(name: normalizedName)
    }

    private func fuzzyMatch(name: String) -> Pokemon? {
        let threshold = 0.8

        for (key, poke) in nameLookup {
            if similarity(name, key) >= threshold {
                return poke
            }
        }

        return nil
    }

    private func similarity(_ s1: String, _ s2: String) -> Double {
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1

        if longer.isEmpty {
            return 1.0
        }

        let distance = levenshteinDistance(shorter, longer)
        return (Double(longer.count) - Double(distance)) / Double(longer.count)
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m {
            matrix[i][0] = i
        }
        for j in 0...n {
            matrix[0][j] = j
        }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[m][n]
    }

    func allPokemon() -> [Pokemon] {
        pokemon
    }

    func pokemon(byId id: Int) -> Pokemon? {
        pokemon.first { $0.id == id }
    }
}
