//
//  PokemonTypeIcon.swift
//  PokéJournal
//

import SwiftUI

/// Loads the partywhale type icon for a given type identifier.
/// Icons are stored in `Assets.xcassets/TypeIcons/<type>` as template images
/// so they inherit `.foregroundStyle(...)` tint.
enum PokemonTypeIcon {

    /// Tinted icon for the given type, sized 16×16 by default.
    static func image(for type: String, size: CGFloat = 16) -> some View {
        Image(type.lowercased())
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundStyle(PokemonTypeColor.color(for: type))
            .accessibilityLabel(Self.accessibilityLabel(for: type))
    }

    private static func accessibilityLabel(for type: String) -> String {
        "\(PokemonTypeLabel.german(for: type))-Typ"
    }
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
