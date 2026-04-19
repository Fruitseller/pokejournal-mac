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

    static let files: [File] = {
        var all: [File] = [
            File(
                relativePath: "\(pokemonSubpath)/testrot/testrot.md",
                content: TestVaultRot.game
            ),
            File(
                relativePath: "\(pokemonSubpath)/testrot/sessions/2024-01-10_testrot.md",
                content: TestVaultRot.session1
            ),
            File(
                relativePath: "\(pokemonSubpath)/testrot/sessions/2024-01-25_testrot.md",
                content: TestVaultRot.session2
            ),
            File(
                relativePath: "\(pokemonSubpath)/testrot/sessions/2024-03-05_testrot.md",
                content: TestVaultRot.session3
            ),
            File(
                relativePath: "\(pokemonSubpath)/testlegacy.md",
                content: TestVaultLegacy.oldFormat
            ),
        ]
        all.append(contentsOf: TestVaultSmaragd.files)
        all.append(contentsOf: TestVaultMond.files)
        all.append(contentsOf: TestVaultPurpur.files)
        return all
    }()

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
}

// MARK: - Rot (gen6+ bucket, minimal)

private enum TestVaultRot {
    static let game = """
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

    static let session1 = """
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

    static let session2 = """
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

    static let session3 = """
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
}

// MARK: - Legacy (old format)

private enum TestVaultLegacy {
    static let oldFormat = """
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

// MARK: - Smaragd (gen2to5 bucket, Hoenn, moderate density)

private enum TestVaultSmaragd {
    static let subpath = "\(TestVaultFixture.pokemonSubpath)/testsmaragd"

    static let files: [TestVaultFixture.File] = [
        .init(relativePath: "\(subpath)/testsmaragd.md", content: game),
        .init(relativePath: "\(subpath)/sessions/2025-01-12_testsmaragd.md", content: s1),
        .init(relativePath: "\(subpath)/sessions/2025-01-19_testsmaragd.md", content: s2),
        .init(relativePath: "\(subpath)/sessions/2025-01-26_testsmaragd.md", content: s3),
        .init(relativePath: "\(subpath)/sessions/2025-02-02_testsmaragd.md", content: s4),
        .init(relativePath: "\(subpath)/sessions/2025-02-09_testsmaragd.md", content: s5),
        .init(relativePath: "\(subpath)/sessions/2025-02-23_testsmaragd.md", content: s6),
        .init(relativePath: "\(subpath)/sessions/2025-03-08_testsmaragd.md", content: s7),
        .init(relativePath: "\(subpath)/sessions/2025-03-15_testsmaragd.md", content: s8),
        .init(relativePath: "\(subpath)/sessions/2025-04-05_testsmaragd.md", content: s9),
        .init(relativePath: "\(subpath)/sessions/2025-04-20_testsmaragd.md", content: s10),
    ]

    static let game = """
    ---
    aliases:
      - "Test Pokémon Smaragd"
    release: 2005-10-21
    platforms:
      - Game Boy Advance
    genre: RPG
    developer: Test Freak
    metacritic: 82
    ---

    # Test Smaragd

    Hoenn-Abenteuer im Debug-Vault.
    """

    static let s1 = """
    # 2025-01-12

    ## Aktivitäten
    Abenteuer in Wurzelheim gestartet. Geckarbor als Starter, Zigzachs als erstes gefangenes Pokémon.

    ## Pläne
    Route 103 erkunden, ersten Arenakampf planen.

    ## Gedanken
    Grashund fühlt sich solider an als erwartet.

    ## Team
    - Geckarbor lvl 5
    - Zigzachs lvl 3
    """

    static let s2 = """
    # 2025-01-19

    ## Aktivitäten
    Ersten Arenakampf gewonnen. Wingull gefangen, Zigzachs entwickelt sich zu Geradaks.

    ## Pläne
    Richtung Metarost-Stadt.

    ## Gedanken

    ## Team
    - Reptain lvl 16
    - Geradaks lvl 14
    - Wingull lvl 12
    """

    static let s3 = """
    # 2025-01-26

    ## Aktivitäten
    Shnebedeck auf Route 114 gefangen. Gegen Rockettenboss gewonnen.

    ## Pläne
    Zweiter Arenakampf in Faustauhaven.

    ## Gedanken
    Team wirkt recht typenlastig, brauche Elektro.

    ## Team
    - Reptain lvl 20
    - Geradaks lvl 18
    - Wingull lvl 17
    - Shnebedeck lvl 16
    """

    static let s4 = """
    # 2025-02-02

    ## Aktivitäten
    Magnetilo und Frizelbliz gefangen. Faustauhaven-Arena besiegt.

    ## Pläne
    Neue Orde und Schatzsucher im Trassenkuppel-Wald.

    ## Gedanken
    Elektro-Abdeckung hilft enorm.

    ## Team
    - Reptain lvl 24
    - Geradaks lvl 22
    - Frizelbliz lvl 20
    - Shnebedeck lvl 20
    - Magnetilo lvl 19
    """

    static let s5 = """
    # 2025-02-09

    ## Aktivitäten
    Reptain entwickelt sich zu Gewaldro. Shnebedeck zu Lepumentas.

    ## Pläne
    Seegrasuferstadt-Arena.

    ## Gedanken

    ## Team
    - Gewaldro lvl 32
    - Geradaks lvl 26
    - Frizelbliz lvl 24
    - Lepumentas lvl 25
    - Magnetilo lvl 22
    """

    static let s6 = """
    # 2025-02-23

    ## Aktivitäten
    Zwei Wochen Pause. Wieder eingestiegen, Kampf gegen Rivalen in Graphitport.

    ## Pläne
    Gut trainieren vor der nächsten Arena.

    ## Gedanken
    Pause war ok, Team noch gut im Kopf.

    ## Team
    - Gewaldro lvl 34
    - Geradaks lvl 28
    - Frizelbliz lvl 28
    - Lepumentas lvl 28
    - Magnetilo lvl 26
    """

    static let s7 = """
    # 2025-03-08

    ## Aktivitäten
    Wingull aus der Box geholt und zu Pelipper entwickelt. Magnetilo zu Magneton.

    ## Pläne
    Endlich Tauros-Höhle.

    ## Gedanken

    ## Team
    - Gewaldro lvl 38
    - Pelipper lvl 32
    - Frizelbliz lvl 32
    - Lepumentas lvl 32
    - Magneton lvl 30
    """

    static let s8 = """
    # 2025-03-15

    ## Aktivitäten
    Arenakampf in Bad Lavastadt, knapp gewonnen. Frizelbliz zu Voltenso.

    ## Pläne
    Jahrmarkt-Stadt als nächstes.

    ## Gedanken

    ## Team
    - Gewaldro lvl 44
    - Pelipper lvl 38
    - Voltenso lvl 36
    - Lepumentas lvl 36
    - Magneton lvl 34
    """

    static let s9 = """
    # 2025-04-05

    ## Aktivitäten
    Pokémon-Liga erreicht. Erste Top Vier besiegt, gegen Glazio verloren.

    ## Pläne
    Mehr Training, bessere Items.

    ## Gedanken
    Zu wenig Eis-Abdeckung.

    ## Team
    - Gewaldro lvl 52
    - Pelipper lvl 48
    - Voltenso lvl 46
    - Lepumentas lvl 46
    - Magneton lvl 44
    - Geradaks lvl 42
    """

    static let s10 = """
    # 2025-04-20

    ## Aktivitäten
    Champion besiegt. Hall of Fame erreicht.

    ## Pläne
    Post-Game Content erkunden.

    ## Gedanken
    Gewaldro war der MVP. Nächstes Mal mehr Variation.

    ## Team
    - Gewaldro lvl 58
    - Pelipper lvl 55
    - Voltenso lvl 54
    - Lepumentas lvl 53
    - Magneton lvl 51
    - Geradaks lvl 50
    """
}

// MARK: - Mond (gen6+ bucket, Alola, high density, regional forms)

private enum TestVaultMond {
    static let subpath = "\(TestVaultFixture.pokemonSubpath)/testmond"

    static let files: [TestVaultFixture.File] = [
        .init(relativePath: "\(subpath)/testmond.md", content: game),
        .init(relativePath: "\(subpath)/sessions/2025-05-03_testmond.md", content: s01),
        .init(relativePath: "\(subpath)/sessions/2025-05-10_testmond.md", content: s02),
        .init(relativePath: "\(subpath)/sessions/2025-05-17_testmond.md", content: s03),
        .init(relativePath: "\(subpath)/sessions/2025-05-24_testmond.md", content: s04),
        .init(relativePath: "\(subpath)/sessions/2025-05-31_testmond.md", content: s05),
        .init(relativePath: "\(subpath)/sessions/2025-06-07_testmond.md", content: s06),
        .init(relativePath: "\(subpath)/sessions/2025-06-14_testmond.md", content: s07),
        .init(relativePath: "\(subpath)/sessions/2025-06-21_testmond.md", content: s08),
        .init(relativePath: "\(subpath)/sessions/2025-07-05_testmond.md", content: s09),
        .init(relativePath: "\(subpath)/sessions/2025-07-12_testmond.md", content: s10),
        .init(relativePath: "\(subpath)/sessions/2025-07-19_testmond.md", content: s11),
        .init(relativePath: "\(subpath)/sessions/2025-08-02_testmond.md", content: s12),
        .init(relativePath: "\(subpath)/sessions/2025-08-16_testmond.md", content: s13),
        .init(relativePath: "\(subpath)/sessions/2025-08-30_testmond.md", content: s14),
        .init(relativePath: "\(subpath)/sessions/2025-09-13_testmond.md", content: s15),
        .init(relativePath: "\(subpath)/sessions/2025-09-27_testmond.md", content: s16),
        .init(relativePath: "\(subpath)/sessions/2025-10-18_testmond.md", content: s17),
        .init(relativePath: "\(subpath)/sessions/2025-11-08_testmond.md", content: s18),
        .init(relativePath: "\(subpath)/sessions/2025-12-06_testmond.md", content: s19),
        .init(relativePath: "\(subpath)/sessions/2026-01-10_testmond.md", content: s20),
    ]

    static let game = """
    ---
    aliases:
      - "Test Pokémon Mond"
    release: 2017-11-17
    platforms:
      - Nintendo 3DS
    genre: RPG
    developer: Test Freak
    metacritic: 87
    ---

    # Test Mond

    Alola-Abenteuer mit Inselprüfungen im Debug-Vault.
    """

    static let s01 = """
    # 2025-05-03

    ## Aktivitäten
    Abenteuer in Hauholi City gestartet. Bauz als Starter gewählt.

    ## Pläne
    Inselwanderung Melemele beginnen.

    ## Gedanken

    ## Team
    - Bauz lvl 5
    """

    static let s02 = """
    # 2025-05-10

    ## Aktivitäten
    Alola Mauzi und Kokowaru auf Route 1 gefangen.

    ## Pläne
    Erste Inselprüfung.

    ## Gedanken
    Alola-Formen sehen stark aus.

    ## Team
    - Bauz lvl 10
    - Alola Mauzi lvl 8
    - Kokowaru lvl 7
    """

    static let s03 = """
    # 2025-05-17

    ## Aktivitäten
    Erste Inselprüfung bestanden. Alola Rattfratz gefangen.

    ## Pläne
    Akala-Insel.

    ## Gedanken

    ## Team
    - Bauz lvl 15
    - Alola Mauzi lvl 13
    - Kokowaru lvl 12
    - Alola Rattfratz lvl 11
    """

    static let s04 = """
    # 2025-05-24

    ## Aktivitäten
    Akala erreicht. Alola Vulpix und Pikachu gefangen.

    ## Pläne
    Kiawes Prüfung.

    ## Gedanken
    Eis-Vulpix ist wunderschön.

    ## Team
    - Bauz lvl 20
    - Alola Mauzi lvl 17
    - Alola Vulpix lvl 15
    - Pikachu lvl 14
    - Alola Rattfratz lvl 14
    """

    static let s05 = """
    # 2025-05-31

    ## Aktivitäten
    Kiawes Prüfung geschafft. Bauz entwickelt sich zu Arboretoss.

    ## Pläne
    Malies Friedhof.

    ## Gedanken

    ## Team
    - Arboretoss lvl 24
    - Alola Mauzi lvl 20
    - Alola Vulpix lvl 18
    - Pikachu lvl 17
    - Alola Rattfratz lvl 17
    """

    static let s06 = """
    # 2025-06-07

    ## Aktivitäten
    Alola Rattfratz zu Alola Rattikarl entwickelt. Pikachu zu Alola Raichu.

    ## Pläne
    Totemkampf gegen Mimigma.

    ## Gedanken
    Alola Raichu auf einem Surfbrett. Stark.

    ## Team
    - Arboretoss lvl 28
    - Alola Mauzi lvl 24
    - Alola Vulpix lvl 22
    - Alola Raichu lvl 22
    - Alola Rattikarl lvl 22
    """

    static let s07 = """
    # 2025-06-14

    ## Aktivitäten
    Totemkampf Mimigma nach vier Versuchen gewonnen.

    ## Pläne
    Ulaula-Insel per Charizard-Ritt.

    ## Gedanken
    Mimigma ist unfair.

    ## Team
    - Arboretoss lvl 32
    - Alola Mauzi lvl 28
    - Alola Vulpix lvl 26
    - Alola Raichu lvl 26
    - Alola Rattikarl lvl 25
    """

    static let s08 = """
    # 2025-06-21

    ## Aktivitäten
    Ulaula erreicht. Alola Sandan gefangen.

    ## Pläne
    Inselprüfung bei Lektros Arena.

    ## Gedanken

    ## Team
    - Arboretoss lvl 35
    - Alola Mauzi lvl 31
    - Alola Vulpix lvl 30
    - Alola Raichu lvl 30
    - Alola Sandan lvl 28
    """

    static let s09 = """
    # 2025-07-05

    ## Aktivitäten
    Alola Vulpix zu Alola Vulnona entwickelt. Prüfung bestanden.

    ## Pläne
    Aether Paradise erkunden.

    ## Gedanken

    ## Team
    - Arboretoss lvl 40
    - Alola Mauzi lvl 36
    - Alola Vulnona lvl 36
    - Alola Raichu lvl 34
    - Alola Sandan lvl 32
    """

    static let s10 = """
    # 2025-07-12

    ## Aktivitäten
    Aether Paradise: Story-Twist. Alola Mauzi zu Snobilikat entwickelt.

    ## Pläne
    Poni-Insel.

    ## Gedanken
    Story-Wendungen sind dick.

    ## Team
    - Arboretoss lvl 44
    - Snobilikat lvl 40
    - Alola Vulnona lvl 40
    - Alola Raichu lvl 38
    - Alola Sandan lvl 36
    """

    static let s11 = """
    # 2025-07-19

    ## Aktivitäten
    Poni-Insel Canyon erkundet. Alola Sandan zu Alola Sandamer.

    ## Pläne
    Pokémon-Liga vorbereiten.

    ## Gedanken

    ## Team
    - Silvarro lvl 50
    - Snobilikat lvl 44
    - Alola Vulnona lvl 44
    - Alola Raichu lvl 42
    - Alola Sandamer lvl 40
    """

    static let s12 = """
    # 2025-08-02

    ## Aktivitäten
    Zwei Wochen Pause. Poni-Insel weiter, Totem-Krebscorps.

    ## Pläne
    Training für die Liga.

    ## Gedanken

    ## Team
    - Silvarro lvl 52
    - Snobilikat lvl 48
    - Alola Vulnona lvl 48
    - Alola Raichu lvl 46
    - Alola Sandamer lvl 44
    - Alola Rattikarl lvl 42
    """

    static let s13 = """
    # 2025-08-16

    ## Aktivitäten
    Pokémon-Liga zum ersten Mal betreten. Gegen Malih verloren.

    ## Pläne
    Mehr Level.

    ## Gedanken
    Malih ist brutal.

    ## Team
    - Silvarro lvl 55
    - Snobilikat lvl 52
    - Alola Vulnona lvl 52
    - Alola Raichu lvl 50
    - Alola Sandamer lvl 48
    - Alola Rattikarl lvl 46
    """

    static let s14 = """
    # 2025-08-30

    ## Aktivitäten
    Liga wieder angetreten. Top Vier durch, gegen Champion verloren.

    ## Pläne
    Eine Runde weiter trainieren.

    ## Gedanken
    Knapp.

    ## Team
    - Silvarro lvl 58
    - Snobilikat lvl 55
    - Alola Vulnona lvl 55
    - Alola Raichu lvl 53
    - Alola Sandamer lvl 51
    - Alola Rattikarl lvl 49
    """

    static let s15 = """
    # 2025-09-13

    ## Aktivitäten
    Champion besiegt. Hall of Fame.

    ## Pläne
    Post-Game.

    ## Gedanken
    Geil.

    ## Team
    - Silvarro lvl 62
    - Snobilikat lvl 58
    - Alola Vulnona lvl 58
    - Alola Raichu lvl 56
    - Alola Sandamer lvl 54
    - Alola Rattikarl lvl 52
    """

    static let s16 = """
    # 2025-09-27

    ## Aktivitäten
    Ultraraum erkundet. Nihilego und Zygarde-Zellen gesammelt.

    ## Pläne
    Weitere UBs fangen.

    ## Gedanken

    ## Team
    - Silvarro lvl 65
    - Snobilikat lvl 62
    - Alola Vulnona lvl 62
    - Alola Raichu lvl 60
    - Alola Sandamer lvl 58
    - Nihilego lvl 55
    """

    static let s17 = """
    # 2025-10-18

    ## Aktivitäten
    Mehr UBs: Masskito und Anego gefangen.

    ## Pläne
    Nekrozma-Kampf.

    ## Gedanken

    ## Team
    - Silvarro lvl 68
    - Snobilikat lvl 65
    - Alola Vulnona lvl 65
    - Masskito lvl 60
    - Anego lvl 60
    - Nihilego lvl 58
    """

    static let s18 = """
    # 2025-11-08

    ## Aktivitäten
    Nekrozma besiegt und gefangen.

    ## Pläne
    Battle Tree ausprobieren.

    ## Gedanken
    Nekrozma-Formen sind overpowered.

    ## Team
    - Silvarro lvl 72
    - Nekrozma lvl 68
    - Alola Vulnona lvl 66
    - Masskito lvl 62
    - Anego lvl 62
    - Snobilikat lvl 65
    """

    static let s19 = """
    # 2025-12-06

    ## Aktivitäten
    Battle Tree Superkette. 30 Siege in Folge.

    ## Pläne
    50 knacken.

    ## Gedanken

    ## Team
    - Silvarro lvl 75
    - Nekrozma lvl 72
    - Alola Vulnona lvl 70
    - Masskito lvl 68
    - Anego lvl 68
    - Alola Raichu lvl 70
    """

    static let s20 = """
    # 2026-01-10

    ## Aktivitäten
    Zuchttag. Alola-Rihorn und Lapras geschlüpft, komplettes Team erneuert.

    ## Pläne
    Nächstes Mal wieder Hoenn.

    ## Gedanken
    Gutes Spiel.

    ## Team
    - Silvarro lvl 78
    - Lapras lvl 60
    - Alola Vulnona lvl 72
    - Alola Raichu lvl 72
    - Masskito lvl 70
    - Nekrozma lvl 75
    """
}

// MARK: - Purpur (gen6+ bucket, Paldea, recent, shorter run)

private enum TestVaultPurpur {
    static let subpath = "\(TestVaultFixture.pokemonSubpath)/testpurpur"

    static let files: [TestVaultFixture.File] = [
        .init(relativePath: "\(subpath)/testpurpur.md", content: game),
        .init(relativePath: "\(subpath)/sessions/2026-02-07_testpurpur.md", content: s1),
        .init(relativePath: "\(subpath)/sessions/2026-02-14_testpurpur.md", content: s2),
        .init(relativePath: "\(subpath)/sessions/2026-02-21_testpurpur.md", content: s3),
        .init(relativePath: "\(subpath)/sessions/2026-02-28_testpurpur.md", content: s4),
        .init(relativePath: "\(subpath)/sessions/2026-03-07_testpurpur.md", content: s5),
        .init(relativePath: "\(subpath)/sessions/2026-03-14_testpurpur.md", content: s6),
        .init(relativePath: "\(subpath)/sessions/2026-03-28_testpurpur.md", content: s7),
        .init(relativePath: "\(subpath)/sessions/2026-04-11_testpurpur.md", content: s8),
    ]

    static let game = """
    ---
    aliases:
      - "Test Pokémon Purpur"
    release: 2022-11-18
    platforms:
      - Nintendo Switch
    genre: RPG
    developer: Test Freak
    metacritic: 72
    ---

    # Test Purpur

    Offene Paldea-Region im Debug-Vault.
    """

    static let s1 = """
    # 2026-02-07

    ## Aktivitäten
    Abenteuer in Mesalona gestartet. Krokel als Starter.

    ## Pläne
    Schule besuchen, erste Aufgaben.

    ## Gedanken
    Offene Welt fühlt sich gut an.

    ## Team
    - Krokel lvl 6
    """

    static let s2 = """
    # 2026-02-14

    ## Aktivitäten
    Ersten Titan bezwungen. Hefel und Paldea Tauros gefangen.

    ## Pläne
    Zweiten Titan suchen.

    ## Gedanken

    ## Team
    - Krokel lvl 14
    - Hefel lvl 12
    - Paldea Tauros lvl 15
    """

    static let s3 = """
    # 2026-02-21

    ## Aktivitäten
    Nördlicher Titan besiegt. Haspiror und Felori gefangen.

    ## Pläne
    Team Star angehen.

    ## Gedanken

    ## Team
    - Crocalor lvl 22
    - Hefel lvl 20
    - Paldea Tauros lvl 22
    - Haspiror lvl 18
    - Felori lvl 18
    """

    static let s4 = """
    # 2026-02-28

    ## Aktivitäten
    Zwei Team Star Basen geräumt. Felori zu Floragato entwickelt.

    ## Pläne
    Arenaleiter Arturo.

    ## Gedanken

    ## Team
    - Crocalor lvl 28
    - Hefel lvl 26
    - Paldea Tauros lvl 28
    - Haspiror lvl 24
    - Floragato lvl 24
    """

    static let s5 = """
    # 2026-03-07

    ## Aktivitäten
    Arturos Arena gewonnen. Crocalor zu Skelabra.

    ## Pläne
    Nächste Arena.

    ## Gedanken

    ## Team
    - Skelabra lvl 36
    - Hefel lvl 32
    - Paldea Tauros lvl 34
    - Haspiror lvl 30
    - Floragato lvl 30
    """

    static let s6 = """
    # 2026-03-14

    ## Aktivitäten
    Zwei weitere Arenen, Team Star fertig.

    ## Pläne
    Finalen Titan.

    ## Gedanken

    ## Team
    - Skelabra lvl 42
    - Hefel lvl 38
    - Paldea Tauros lvl 40
    - Haspiror lvl 36
    - Floragato lvl 36
    """

    static let s7 = """
    # 2026-03-28

    ## Aktivitäten
    Finaler Titan besiegt. Alle drei Wege fast durch.

    ## Pläne
    Pokémon-Liga.

    ## Gedanken

    ## Team
    - Skelabra lvl 52
    - Hefel lvl 48
    - Paldea Tauros lvl 50
    - Haspiror lvl 46
    - Floragato lvl 46
    """

    static let s8 = """
    # 2026-04-11

    ## Aktivitäten
    Champion-Prüfung bestanden. Top.

    ## Pläne
    Zero-Areal-Postgame.

    ## Gedanken
    Gutes Ende.

    ## Team
    - Skelabra lvl 58
    - Hefel lvl 54
    - Paldea Tauros lvl 56
    - Haspiror lvl 52
    - Maskagato lvl 52
    """
}
