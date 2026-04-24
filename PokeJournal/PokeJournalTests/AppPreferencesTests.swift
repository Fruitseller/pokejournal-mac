//
//  AppPreferencesTests.swift
//  PokéJournalTests
//

import SwiftUI
import Testing
@testable import PokeJournal

struct AppPreferencesTests {
    @Test func appTheme_mapsToColorScheme() {
        #expect(AppTheme.system.colorScheme == nil)
        #expect(AppTheme.light.colorScheme == .light)
        #expect(AppTheme.dark.colorScheme == .dark)
    }

    @Test func spriteStyle_buildsExpectedAssetNames() {
        #expect(SpriteStyle.official.assetName(forPokemonID: 25) == "pokemon_25")
        #expect(SpriteStyle.pixel.assetName(forPokemonID: 25) == "pixel_pokemon_25")
    }
}
