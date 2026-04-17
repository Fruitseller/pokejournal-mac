//
//  PokemonTypeIcon.swift
//  PokéJournal
//

import SwiftUI

/// Loads the partywhale type icon for a given type identifier.
/// Icons are stored in `Assets.xcassets/TypeIcons/<type>` with their baked-in
/// type colors — no template tinting needed.
enum PokemonTypeIcon {

    static func image(for type: String, size: CGFloat = 16) -> some View {
        Image(type.lowercased(), bundle: .main)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .accessibilityLabel(Self.accessibilityLabel(for: type))
    }

    private static func accessibilityLabel(for type: String) -> String {
        "\(PokemonTypeLabel.german(for: type))-Typ"
    }
}

#Preview("All 18 type icons") {
    let types = [
        "normal", "fire", "water", "electric", "grass", "ice",
        "fighting", "poison", "ground", "flying", "psychic", "bug",
        "rock", "ghost", "dragon", "dark", "steel", "fairy"
    ]
    return LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
        ForEach(types, id: \.self) { t in
            VStack(spacing: 4) {
                PokemonTypeIcon.image(for: t, size: 32)
                Text(PokemonTypeLabel.german(for: t))
                    .font(.caption)
            }
        }
    }
    .padding()
    .frame(width: 400, height: 320)
}

/// German display label for a type identifier.
enum PokemonTypeLabel {
    static func german(for type: String) -> String {
        switch type.lowercased() {
        case "normal":   return "Normal"
        case "fire":     return "Feuer"
        case "water":    return "Wasser"
        case "electric": return "Elektro"
        case "grass":    return "Pflanze"
        case "ice":      return "Eis"
        case "fighting": return "Kampf"
        case "poison":   return "Gift"
        case "ground":   return "Boden"
        case "flying":   return "Flug"
        case "psychic":  return "Psycho"
        case "bug":      return "Käfer"
        case "rock":     return "Gestein"
        case "ghost":    return "Geist"
        case "dragon":   return "Drache"
        case "dark":     return "Unlicht"
        case "steel":    return "Stahl"
        case "fairy":    return "Fee"
        default:         return type.capitalized
        }
    }
}
