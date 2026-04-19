//
//  TestVaultFixture.swift
//  PokéJournal
//

import Foundation

enum TestVaultFixture {
    struct File {
        let relativePath: String
        let content: String
    }

    static let pokemonSubpath = "hobbies/videospiele/pokemon"

    static let files: [File] = [
        File(
            relativePath: "\(pokemonSubpath)/testrot/testrot.md",
            content: testrotGame
        ),
        File(
            relativePath: "\(pokemonSubpath)/testrot/sessions/2024-01-10_testrot.md",
            content: session1
        ),
        File(
            relativePath: "\(pokemonSubpath)/testrot/sessions/2024-01-25_testrot.md",
            content: session2
        ),
        File(
            relativePath: "\(pokemonSubpath)/testrot/sessions/2024-03-05_testrot.md",
            content: session3
        ),
        File(
            relativePath: "\(pokemonSubpath)/testlegacy.md",
            content: testlegacyOldFormat
        ),
    ]

    static func materialize(into root: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        for file in files {
            let fileURL = root.appendingPathComponent(file.relativePath)
            try fm.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    private static let testrotGame = """
    ---
    aliases:
      - "Test Pokémon Rot"
    release: 2024-01-01
    platforms:
      - Nintendo Switch
    genre: RPG
    developer: Test Freak
    metacritic: 85
    ---

    # Test Rot

    Fiktiver Test-Eintrag für das Debug-Vault.
    """

    private static let session1 = """
    # 2024-01-10

    ## Aktivitäten
    Abenteuer gestartet. Glumanda als Starter gewählt und Taubsi gefangen.

    ## Pläne
    Richtung erstes Gym.

    ## Gedanken

    ## Team
    - Glumanda lvl 8
    - Taubsi lvl 5
    """

    private static let session2 = """
    # 2024-01-25

    ## Aktivitäten
    Glumanda entwickelt sich zu Glutexo. Pikachu gefangen.

    ## Pläne
    Zweites Gym angehen.

    ## Gedanken
    Entwicklung hat sich gelohnt.

    ## Team
    - Glutexo lvl 18
    - Tauboga lvl 15
    - Pikachu lvl 10
    """

    private static let session3 = """
    # 2024-03-05

    ## Aktivitäten
    Nach langer Pause weitergespielt. Team deutlich aufgelevelt, Mew getauscht.

    ## Pläne
    Liga vorbereiten.

    ## Gedanken

    ## Team
    - Glurak lvl 36
    - Tauboss lvl 35
    - Raichu lvl 33
    - Mew lvl 40
    """

    private static let testlegacyOldFormat = """
    ---
    aliases:
      - "Test Legacy"
    release: 2020-05-15
    platforms:
      - Nintendo DS
    genre: RPG
    developer: Test Freak
    metacritic: 78
    ---

    # Legacy

    ## 2020-06-01

    Erster Legacy-Eintrag. Karpador und Zubat gefangen.

    Team:
    - Karpador lvl 5
    - Zubat lvl 8

    ## 2020-06-14

    Zweiter Legacy-Eintrag. Karpador entwickelt sich zu Garados.

    Team:
    - Garados lvl 22
    - Golbat lvl 18
    """
}
