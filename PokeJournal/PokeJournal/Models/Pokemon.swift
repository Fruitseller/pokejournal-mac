//
//  Pokemon.swift
//  PokéJournal
//

import Foundation

struct Pokemon: Codable, Identifiable, Hashable {
    struct Variant: Codable, Hashable {
        let types: [String]
    }

    let id: Int
    let nameDE: String
    let nameEN: String
    let types: [String]
    let spriteURL: String?
    let spritePixelURL: String?
    let evolutionChainID: Int?
    let variants: [String: Variant]?

    enum CodingKeys: String, CodingKey {
        case id
        case nameDE = "name_de"
        case nameEN = "name_en"
        case types
        case spriteURL = "sprite_url"
        case spritePixelURL = "sprite_pixel_url"
        case evolutionChainID = "evolution_chain_id"
        case variants
    }

    var primaryType: String {
        types.first ?? "normal"
    }
}

class PokemonDatabase {
    static let shared = PokemonDatabase()

    private var pokemon: [Pokemon] = []
    private var nameLookup: [String: Pokemon] = [:]
    private var chainLookup: [Int: [Pokemon]] = [:]

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

        // Build evolution chain lookup: chainID -> sorted members (by Pokemon ID)
        var chains: [Int: [Pokemon]] = [:]
        for poke in pokemon {
            if let chainID = poke.evolutionChainID {
                chains[chainID, default: []].append(poke)
            }
        }
        for key in chains.keys {
            chains[key]?.sort { $0.id < $1.id }
        }
        chainLookup = chains
    }

    func find(byName name: String) -> Pokemon? {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)

        if let exact = nameLookup[normalizedName] {
            return exact
        }

        return fuzzyMatch(name: normalizedName)
    }

    func resolvedTypes(for pokemonName: String, variant: String?) -> [String]? {
        guard let pokemon = find(byName: pokemonName) else {
            return nil
        }

        if let region = Self.normalizedVariant(variant),
           let override = pokemon.variants?[region] {
            return override.types
        }

        return pokemon.types
    }

    func fuzzyMatch(name: String) -> Pokemon? {
        let threshold = 0.8

        for (key, poke) in nameLookup {
            if similarity(name, key) >= threshold {
                return poke
            }
        }

        return nil
    }

    func similarity(_ s1: String, _ s2: String) -> Double {
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1

        if longer.isEmpty {
            return 1.0
        }

        let distance = levenshteinDistance(shorter, longer)
        return (Double(longer.count) - Double(distance)) / Double(longer.count)
    }

    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
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

    func evolutionLine(for pokemon: Pokemon) -> [Pokemon] {
        guard let chainID = pokemon.evolutionChainID,
              let members = chainLookup[chainID] else {
            return [pokemon]
        }
        return members
    }

    func sameEvolutionLine(_ name1: String, _ name2: String) -> Bool {
        guard let p1 = find(byName: name1),
              let p2 = find(byName: name2),
              let chain1 = p1.evolutionChainID,
              let chain2 = p2.evolutionChainID else {
            return false
        }
        return chain1 == chain2
    }

    /// Returns a grouping key for a team member based on evolution line.
    /// Variant Pokemon (e.g. "Alola Raichu") get their own key.
    func evolutionLineKey(for pokemonName: String, variant: String?) -> String {
        if let v = variant { return "\(v) \(pokemonName)" }
        if let pokemon = find(byName: pokemonName),
           pokemon.evolutionChainID != nil {
            let line = evolutionLine(for: pokemon)
            if let baseName = line.first?.nameDE { return baseName }
        }
        return pokemonName
    }

    func allPokemon() -> [Pokemon] {
        pokemon
    }

    func pokemon(byId id: Int) -> Pokemon? {
        pokemon.first { $0.id == id }
    }

    private static func normalizedVariant(_ variant: String?) -> String? {
        guard let variant else { return nil }

        switch variant.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "alola", "alolan", "aloha":
            return "alola"
        case "galar", "galarian":
            return "galar"
        case "hisui", "hisuian":
            return "hisui"
        case "paldea", "paldean":
            return "paldea"
        default:
            return nil
        }
    }
}
