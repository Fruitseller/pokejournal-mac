//
//  Poke_JournalTests.swift
//  PokéJournalTests
//

import Testing
@testable import Poke_Journal

struct MarkdownParserTests {
    let parser = MarkdownParser.shared

    // MARK: - Date From Filename Tests

    @Test func parseDateFromFilename_simpleFormat() {
        let date = parser.parseDateFromFilename("2026-01-26.md")
        #expect(date != nil)
    }

    @Test func parseDateFromFilename_withGameName() {
        // Real format: 2026-01-26_purpur.md
        let date = parser.parseDateFromFilename("2026-01-26_purpur.md")
        #expect(date != nil)
    }

    // MARK: - Team Parser Tests

    @Test func parseTeam_realFormat() {
        let content = """
        - Kapilz lvl 96
        - Libelldra lvl 97
        - Donarion lvl 85
        """
        let team = parser.parseTeam(from: content)
        #expect(team.count == 3)
        #expect(team[0].name == "Kapilz")
        #expect(team[0].level == 96)
    }

    @Test func parseTeam_withVariant() {
        let content = "- Aloha Raichu lvl 60"
        let team = parser.parseTeam(from: content)
        #expect(team.count == 1)
        #expect(team[0].variant == "Aloha")
        #expect(team[0].name == "Raichu")
        #expect(team[0].level == 60)
    }

    @Test func parseTeam_oldFormatWithoutDash() {
        // Old format from karmesin.md
        let content = """
        Team:
        - Panflam lvl 8
        - Trasla lvl 8
        """
        let team = parser.parseTeam(from: content)
        #expect(team.count == 2)
    }

    // MARK: - Session Sections Tests

    @Test func parseSessionSections_realSession() {
        let content = """
        # 2026-01-26

        ## Aktivitäten
        Habe ganz viele Pokemon gefangen.

        ## Pläne
        Ich habe 2 Pokemon die lvl 100 sind.

        ## Gedanken

        ## Team
        - Kapilz lvl 96
        - Libelldra lvl 97
        """

        let (activities, plans, thoughts, team) = parser.parseSessionSections(from: content)
        #expect(activities.contains("Pokemon gefangen"))
        #expect(plans.contains("lvl 100"))
        #expect(team.count == 2)
    }

    // MARK: - Old Format Sessions Tests

    @Test func parseOldFormatSessions_inlineFormat() {
        // Format from karmesin.md - sessions inline with ## YYYY-MM-DD
        let content = """
        ---
        aliases:
          - Pokemon Karmesin
        ---

        ## 2023-10-17

        Erste Session text.

        Team:
        - Panflam lvl 8
        - Trasla lvl 8

        ## 2023-10-18

        Zweite Session text.

        Team:
        - Panflam lvl 13
        """

        let sessions = parser.parseOldFormatSessions(from: content, sourceFile: "test.md")
        #expect(sessions.count == 2)
        #expect(sessions[0].team.count == 2)
        #expect(sessions[1].team.count == 1)
    }

    // MARK: - YAML Frontmatter Tests

    @Test func parseYAMLFrontmatter_realFormat() {
        let content = """
        ---
        aliases:
          - "Pokémon Purpur"
        release: 2022-11-18
        platforms:
          - Nintendo Switch
        genre: Rollenspiel
        developer: Game Freak
        metacritic: 71
        ---
        """

        let metadata = parser.parseYAMLFrontmatter(from: content)
        #expect(metadata.aliases.contains("Pokémon Purpur"))
        #expect(metadata.releaseDate == "2022-11-18")
        #expect(metadata.platforms.contains("Nintendo Switch"))
        #expect(metadata.metacriticScore == 71)
    }
}
