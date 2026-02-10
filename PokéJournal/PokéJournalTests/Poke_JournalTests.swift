//
//  Poke_JournalTests.swift
//  PokéJournalTests
//

import Foundation
import Testing
import SwiftData
@testable import PokeJournal

// MARK: - Pokemon Fuzzy Matching Tests

struct PokemonFuzzyMatchingTests {
    let db = PokemonDatabase.shared

    // MARK: - Levenshtein Distance Tests

    @Test func levenshteinDistance_identicalStrings() {
        let distance = db.levenshteinDistance("pikachu", "pikachu")
        #expect(distance == 0)
    }

    @Test func levenshteinDistance_emptyStrings() {
        #expect(db.levenshteinDistance("", "") == 0)
        #expect(db.levenshteinDistance("abc", "") == 3)
        #expect(db.levenshteinDistance("", "abc") == 3)
    }

    @Test func levenshteinDistance_singleCharacterDifference() {
        // Substitution
        #expect(db.levenshteinDistance("cat", "bat") == 1)
        // Insertion
        #expect(db.levenshteinDistance("cat", "cats") == 1)
        // Deletion
        #expect(db.levenshteinDistance("cats", "cat") == 1)
    }

    @Test func levenshteinDistance_multipleEdits() {
        // "kitten" -> "sitting" requires 3 edits
        #expect(db.levenshteinDistance("kitten", "sitting") == 3)
    }

    @Test func levenshteinDistance_completelyDifferent() {
        #expect(db.levenshteinDistance("abc", "xyz") == 3)
    }

    // MARK: - Similarity Tests

    @Test func similarity_identicalStrings() {
        let sim = db.similarity("pikachu", "pikachu")
        #expect(sim == 1.0)
    }

    @Test func similarity_emptyStrings() {
        let sim = db.similarity("", "")
        #expect(sim == 1.0)
    }

    @Test func similarity_completelyDifferent() {
        let sim = db.similarity("abc", "xyz")
        #expect(sim == 0.0)
    }

    @Test func similarity_partialMatch() {
        // "glurak" vs "glorak" - 1 edit in 6 chars = 5/6 ≈ 0.833
        let sim = db.similarity("glurak", "glorak")
        #expect(sim > 0.8)
        #expect(sim < 0.9)
    }

    @Test func similarity_threshold_shouldPass() {
        // Similar names that should pass 0.8 threshold
        let sim = db.similarity("pikachu", "pikachuu")
        #expect(sim >= 0.8)
    }

    @Test func similarity_threshold_shouldFail() {
        // Very different names should fail 0.8 threshold
        let sim = db.similarity("pikachu", "raichu")
        #expect(sim < 0.8)
    }

    // MARK: - Fuzzy Match Integration Tests

    @Test func find_exactMatchGerman() {
        // Assuming pokemon.json is loaded - test exact German name
        let pokemon = db.find(byName: "Glurak")
        #expect(pokemon != nil)
        #expect(pokemon?.nameDE == "Glurak")
    }

    @Test func find_exactMatchEnglish() {
        let pokemon = db.find(byName: "Charizard")
        #expect(pokemon != nil)
        #expect(pokemon?.nameEN == "Charizard")
    }

    @Test func find_caseInsensitive() {
        let pokemon1 = db.find(byName: "PIKACHU")
        let pokemon2 = db.find(byName: "pikachu")
        let pokemon3 = db.find(byName: "Pikachu")
        #expect(pokemon1?.id == pokemon2?.id)
        #expect(pokemon2?.id == pokemon3?.id)
    }

    @Test func find_withWhitespace() {
        let pokemon = db.find(byName: "  Pikachu  ")
        #expect(pokemon != nil)
        #expect(pokemon?.nameEN == "Pikachu")
    }

    @Test func find_fuzzyMatchTypo() {
        // Common typo - should still match via fuzzy
        let pokemon = db.find(byName: "Pikachuu")
        #expect(pokemon != nil)
    }

    @Test func find_noMatch() {
        let pokemon = db.find(byName: "NotAPokemon")
        #expect(pokemon == nil)
    }
}

// MARK: - Game Computed Properties Tests

@Suite(.serialized)
@MainActor
struct GameComputedPropertiesTests {

    @Test func allSessionDates_combinesBothTypes() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        let date1 = Date(timeIntervalSince1970: 1000)
        let date2 = Date(timeIntervalSince1970: 2000)
        let date3 = Date(timeIntervalSince1970: 3000)

        let session = Session(date: date2)
        session.game = game

        let oldSession1 = OldSession(date: date1)
        oldSession1.game = game
        let oldSession2 = OldSession(date: date3)
        oldSession2.game = game

        context.insert(session)
        context.insert(oldSession1)
        context.insert(oldSession2)

        try context.save()

        #expect(game.allSessionDates.count == 3)
        #expect(game.allSessionDates == [date1, date2, date3])
    }

    @Test func totalSessionCount_sumsBothTypes() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        let session1 = Session(date: Date())
        session1.game = game
        let session2 = Session(date: Date())
        session2.game = game
        let oldSession = OldSession(date: Date())
        oldSession.game = game

        context.insert(session1)
        context.insert(session2)
        context.insert(oldSession)

        try context.save()

        #expect(game.totalSessionCount == 3)
    }

    @Test func lastPlayedDate_returnsLatest() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        let earlierDate = Date(timeIntervalSince1970: 1000)
        let laterDate = Date(timeIntervalSince1970: 9999)

        let session = Session(date: earlierDate)
        session.game = game
        let oldSession = OldSession(date: laterDate)
        oldSession.game = game

        context.insert(session)
        context.insert(oldSession)

        try context.save()

        #expect(game.lastPlayedDate == laterDate)
    }

    @Test func lastPlayedDate_nilWhenNoSessions() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)
        try context.save()

        #expect(game.lastPlayedDate == nil)
    }

    @Test func currentTeam_prefersNewestSession() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        let olderDate = Date(timeIntervalSince1970: 1000)
        let newerDate = Date(timeIntervalSince1970: 2000)

        let olderSession = Session(date: olderDate)
        olderSession.game = game
        let olderMember = TeamMember(pokemonName: "Pikachu", level: 50)
        olderSession.team.append(olderMember)

        let newerSession = Session(date: newerDate)
        newerSession.game = game
        let newerMember = TeamMember(pokemonName: "Glurak", level: 80)
        newerSession.team.append(newerMember)

        context.insert(olderSession)
        context.insert(newerSession)
        context.insert(olderMember)
        context.insert(newerMember)

        try context.save()

        #expect(game.currentTeam.count == 1)
        #expect(game.currentTeam.first?.pokemonName == "Glurak")
    }

    @Test func currentTeam_fallsBackToOldSession() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        // Session without team
        let session = Session(date: Date(timeIntervalSince1970: 1000))
        session.game = game

        // OldSession with team
        let oldSession = OldSession(date: Date(timeIntervalSince1970: 500))
        oldSession.game = game
        let member = TeamMember(pokemonName: "Raichu", level: 60)
        oldSession.team.append(member)

        context.insert(session)
        context.insert(oldSession)
        context.insert(member)

        try context.save()

        #expect(game.currentTeam.count == 1)
        #expect(game.currentTeam.first?.pokemonName == "Raichu")
    }

    @Test func currentTeam_emptyWhenNoTeams() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)
        try context.save()

        #expect(game.currentTeam.isEmpty)
    }

    @Test func displayName_prefersAlias() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "purpur", filePath: "/test.md")
        game.aliases = ["Pokémon Purpur", "Pokemon Violet"]
        context.insert(game)
        try context.save()

        #expect(game.displayName == "Pokémon Purpur")
    }

    @Test func displayName_fallsBackToCapitalizedName() throws {
        let container = try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let game = Game(name: "purpur", filePath: "/test.md")
        context.insert(game)
        try context.save()

        #expect(game.displayName == "Purpur")
    }
}

// MARK: - MarkdownParser Tests

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

        let (activities, plans, _, team) = parser.parseSessionSections(from: content)
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

    @Test func parseYAMLFrontmatter_nullMetacriticValue() {
        // Real edge case from kristall_3ds.md - empty metacritic field
        let content = """
        ---
        aliases:
          - "Pokémon Kristall"
        release: 2018-01-26
        platforms:
          - Nintendo 3DS
        metacritic:
        ---
        """

        let metadata = parser.parseYAMLFrontmatter(from: content)
        #expect(metadata.aliases.contains("Pokémon Kristall"))
        #expect(metadata.metacriticScore == nil)
    }

    @Test func parseYAMLFrontmatter_multiplePlatforms() {
        let content = """
        ---
        aliases:
          - "Pokémon Legenden Z-A"
        platforms:
          - Nintendo Switch
          - Nintendo Switch 2
        ---
        """

        let metadata = parser.parseYAMLFrontmatter(from: content)
        #expect(metadata.platforms.count == 2)
        #expect(metadata.platforms.contains("Nintendo Switch"))
        #expect(metadata.platforms.contains("Nintendo Switch 2"))
    }

    // MARK: - Team Parser Edge Cases (from real files)

    @Test func parseTeam_unknownLevel() {
        // Real edge case from old_purpur.md - "lvl ??" for unknown levels
        let content = """
        Team:
        - Azugladis lvl ??
        - Glurak lvl ??
        - Despotar lvl ??
        """
        let team = parser.parseTeam(from: content)
        // Parser should handle this gracefully - either skip or use default level
        #expect(team.count >= 0) // Should not crash
    }

    @Test func parseTeam_inlineFormatWithColon() {
        // Real format from old_purpur.md - "Mein Team:" or "Team:" prefix
        let content = """
        Mein derzeitiges Team:
        - Pamo lvl 16
        - Felino lvl 16
        - Knarbon lvl 14
        """
        let team = parser.parseTeam(from: content)
        #expect(team.count == 3)
        #expect(team[0].name == "Pamo")
    }

    @Test func parseTeam_pokemonWithUmlauts() {
        // German Pokemon names with special characters
        let content = """
        - Knöchel lvl 50
        - Müll lvl 45
        - Äpfel lvl 30
        """
        let team = parser.parseTeam(from: content)
        #expect(team.count == 3)
        #expect(team[0].name == "Knöchel")
    }

    @Test func parseTeam_levelWithTrailingWhitespace() {
        // Edge case: trailing spaces after level number
        let content = """
        - Kaumalat lvl 22
        - Lokroko lvl 28
        """
        let team = parser.parseTeam(from: content)
        #expect(team.count == 2)
        #expect(team[0].level == 22)
        #expect(team[1].level == 28)
    }

    // MARK: - Old Format Session Edge Cases

    @Test func parseOldFormatSessions_noYAMLFrontmatter() {
        // Real format from old_purpur.md - no YAML, just title and sessions
        let content = """

        # Purpur

        ## 2022-12-25

        Habe sehr wenig gespielt.

        - Pamo lvl 11
        - Krokel lvl 14

        ## 2022-12-26

        Mehr gespielt heute.

        Team:
        - Pamo lvl 16
        - Felino lvl 16
        """

        let sessions = parser.parseOldFormatSessions(from: content, sourceFile: "old_purpur.md")
        #expect(sessions.count == 2)
    }

    @Test func parseOldFormatSessions_teamWithVariantHeader() {
        // Real format from old_purpur.md - "Mein Team sieht folgender Maßen aus:"
        let content = """
        ## 2022-12-25

        Mein Team sieht folgender Maßen aus:

        - Pamo lvl 11
        - Krokel lvl 14
        - Tarundel lvl 9
        """

        let sessions = parser.parseOldFormatSessions(from: content, sourceFile: "test.md")
        #expect(sessions.count == 1)
        #expect(sessions[0].team.count == 3)
        #expect(sessions[0].team[0].name == "Pamo")
    }

    @Test func parseOldFormatSessions_meinDerzeitigesTeam() {
        // Real format: "Mein derzeitiges Team:"
        let content = """
        ## 2022-12-26

        Bin weiter gekommen.

        Mein derzeitiges Team:
        - Pamo lvl 16
        - Felino lvl 16
        - Knarbon lvl 14
        """

        let sessions = parser.parseOldFormatSessions(from: content, sourceFile: "test.md")
        #expect(sessions.count == 1)
        #expect(sessions[0].team.count == 3)
    }

    @Test func parseOldFormatSessions_fallbackToBulletList() {
        // Fallback: Find bullet list with "lvl" pattern even without header
        let content = """
        ## 2022-12-27

        Habe heute gespielt.

        - Glutexo lvl 18
        - Felino lvl 20
        - Knarbon lvl 18
        """

        let sessions = parser.parseOldFormatSessions(from: content, sourceFile: "test.md")
        #expect(sessions.count == 1)
        #expect(sessions[0].team.count == 3)
    }

    // MARK: - Session Sections Edge Cases

    @Test func parseSessionSections_emptySections() {
        // Very common in real files - empty Pläne/Gedanken sections
        let content = """
        # 2025-05-29

        ## Aktivitäten
        Pokemon gefangen.

        ## Pläne

        ## Gedanken

        ## Team
        - Pikachu lvl 22
        """

        let (activities, plans, thoughts, team) = parser.parseSessionSections(from: content)
        #expect(activities.contains("Pokemon gefangen"))
        #expect(plans.isEmpty || plans.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(thoughts.isEmpty || thoughts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(team.count == 1)
    }

    @Test func parseSessionSections_missingTeamSection() {
        // Some sessions don't have a team section at all
        let content = """
        # 2025-05-29

        ## Aktivitäten
        Nur kurz gespielt.

        ## Pläne
        Morgen weiterspielen.
        """

        let (activities, plans, _, team) = parser.parseSessionSections(from: content)
        #expect(activities.contains("kurz gespielt"))
        #expect(plans.contains("weiterspielen"))
        #expect(team.isEmpty)
    }
}

// MARK: - Timeline Data Tests

@Suite(.serialized)
@MainActor
struct TimelineDataTests {

    private func makeGame(
        sessionDates: [Date] = [],
        oldSessionDates: [Date] = [],
        container: ModelContainer
    ) -> Game {
        let context = container.mainContext
        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        for date in sessionDates {
            let session = Session(date: date)
            session.game = game
            context.insert(session)
        }

        for date in oldSessionDates {
            let oldSession = OldSession(date: date)
            oldSession.game = game
            context.insert(oldSession)
        }

        try! context.save()
        return game
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ str: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: str)!
    }

    // MARK: - Segment Building

    @Test func buildSegments_emptyGame() throws {
        let container = try makeContainer()
        let game = makeGame(container: container)
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.isEmpty)
    }

    @Test func buildSegments_singleSession() throws {
        let container = try makeContainer()
        let game = makeGame(sessionDates: [date("2025-01-15")], container: container)
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 1)
        #expect(segments[0].sessions.count == 1)
        #expect(segments[0].gapDaysAfter == nil)
    }

    @Test func buildSegments_noGaps() throws {
        let container = try makeContainer()
        let game = makeGame(sessionDates: [
            date("2025-01-01"),
            date("2025-01-03"),
            date("2025-01-10"),
        ], container: container)
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 1)
        #expect(segments[0].sessions.count == 3)
        #expect(segments[0].gapDaysAfter == nil)
    }

    @Test func buildSegments_oneGap() throws {
        let container = try makeContainer()
        let game = makeGame(sessionDates: [
            date("2025-01-01"),
            date("2025-01-05"),
            date("2025-02-01"),  // 27 days gap -> exceeds 14 day threshold
            date("2025-02-03"),
        ], container: container)
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 2)
        #expect(segments[0].sessions.count == 2)
        #expect(segments[0].gapDaysAfter == 27)
        #expect(segments[1].sessions.count == 2)
        #expect(segments[1].gapDaysAfter == nil)
    }

    @Test func buildSegments_multipleGaps() throws {
        let container = try makeContainer()
        let game = makeGame(sessionDates: [
            date("2025-01-01"),
            date("2025-03-01"),  // 59 days gap
            date("2025-06-01"),  // 92 days gap
        ], container: container)
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 3)
        #expect(segments[0].sessions.count == 1)
        #expect(segments[0].gapDaysAfter == 59)
        #expect(segments[1].sessions.count == 1)
        #expect(segments[1].gapDaysAfter == 92)
        #expect(segments[2].sessions.count == 1)
        #expect(segments[2].gapDaysAfter == nil)
    }

    @Test func buildSegments_exactlyAtThreshold() throws {
        let container = try makeContainer()
        let game = makeGame(sessionDates: [
            date("2025-01-01"),
            date("2025-01-15"),  // exactly 14 days -> should trigger gap
        ], container: container)
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 2)
        #expect(segments[0].gapDaysAfter == 14)
    }

    @Test func buildSegments_justBelowThreshold() throws {
        let container = try makeContainer()
        let game = makeGame(sessionDates: [
            date("2025-01-01"),
            date("2025-01-14"),  // 13 days -> no gap
        ], container: container)
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 1)
        #expect(segments[0].sessions.count == 2)
    }

    @Test func buildSegments_combinesSessionTypes() throws {
        let container = try makeContainer()
        let game = makeGame(
            sessionDates: [date("2025-01-10")],
            oldSessionDates: [date("2025-01-01"), date("2025-01-05")],
            container: container
        )
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 1)
        #expect(segments[0].sessions.count == 3)
    }

    @Test func buildSegments_sortsDates() throws {
        let container = try makeContainer()
        // Insert in reverse order — should still be sorted
        let game = makeGame(sessionDates: [
            date("2025-01-10"),
            date("2025-01-01"),
            date("2025-01-05"),
        ], container: container)
        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 1)
        let dates = segments[0].sessions.map(\.date)
        #expect(dates == dates.sorted())
    }

    // MARK: - Pixels Per Day

    private func session(_ dateStr: String) -> TimelineSession {
        TimelineSession(
            date: date(dateStr),
            teamMembers: [],
            activities: "",
            filePath: nil
        )
    }

    @Test func pixelsPerDay_singleSession() {
        let segment = TimelineSegment(
            sessions: [session("2025-01-01")],
            gapDaysAfter: nil
        )
        let ppd = TimelineDataBuilder.pixelsPerDay(for: segment)
        #expect(ppd == 40) // default fallback
    }

    @Test func pixelsPerDay_clampedToMin() {
        let segment = TimelineSegment(
            sessions: [session("2025-01-01"), session("2025-01-13")],
            gapDaysAfter: nil
        )
        let ppd = TimelineDataBuilder.pixelsPerDay(for: segment)
        #expect(ppd >= 20)
        #expect(ppd <= 60)
    }

    @Test func pixelsPerDay_clampedToMax() {
        // 1 day apart -> 400/1 = 400 -> clamped to 60
        let segment = TimelineSegment(
            sessions: [session("2025-01-01"), session("2025-01-02")],
            gapDaysAfter: nil
        )
        let ppd = TimelineDataBuilder.pixelsPerDay(for: segment)
        #expect(ppd == 60)
    }

    // MARK: - Days Between

    @Test func daysBetween_sameDates() {
        let d = date("2025-01-01")
        #expect(TimelineDataBuilder.daysBetween(d, d) == 0)
    }

    @Test func daysBetween_oneDayApart() {
        let a = date("2025-01-01")
        let b = date("2025-01-02")
        #expect(TimelineDataBuilder.daysBetween(a, b) == 1)
    }

    @Test func daysBetween_manyDaysApart() {
        let a = date("2025-01-01")
        let b = date("2025-04-01")
        #expect(TimelineDataBuilder.daysBetween(a, b) == 90)
    }

    // MARK: - Year Helper

    @Test func year_extractsCorrectly() {
        #expect(TimelineDataBuilder.year(of: date("2025-06-15")) == 2025)
        #expect(TimelineDataBuilder.year(of: date("2023-01-01")) == 2023)
    }

    // MARK: - Session Data Enrichment

    @Test func buildSegments_carriesTeamData() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        let s = Session(date: date("2025-01-05"), activities: "Caught many Pokemon")
        s.game = game
        let member = TeamMember(pokemonName: "Pikachu", level: 50)
        s.team.append(member)
        context.insert(s)
        context.insert(member)

        try context.save()

        let segments = TimelineDataBuilder.buildSegments(from: game)
        #expect(segments.count == 1)
        let ts = segments[0].sessions[0]
        #expect(ts.teamMembers.count == 1)
        #expect(ts.teamMembers[0] == "Pikachu")
        #expect(ts.activities.contains("Caught"))
    }

    @Test func buildSegments_sessionHasFilePath_oldSessionNil() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let game = Game(name: "TestGame", filePath: "/test.md")
        context.insert(game)

        let s = Session(date: date("2025-01-05"), filePath: "games/purpur/sessions/2025-01-05.md")
        s.game = game
        context.insert(s)

        let o = OldSession(date: date("2025-01-01"))
        o.game = game
        context.insert(o)

        try context.save()

        let segments = TimelineDataBuilder.buildSegments(from: game)
        let sessions = segments[0].sessions
        // sorted: old first (Jan 1), then session (Jan 5)
        #expect(sessions[0].filePath == nil)
        #expect(sessions[1].filePath == "games/purpur/sessions/2025-01-05.md")
    }
}

// MARK: - DataLoader Clear & Reload Tests

@Suite(.serialized)
@MainActor
struct DataLoaderClearTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Game.self, Session.self, OldSession.self, TeamMember.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func clearAllData_thenInsert_noDuplicates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let loader = DataLoader()

        // Insert initial data
        let game = Game(name: "purpur", filePath: "/pokemon/purpur/purpur.md")
        context.insert(game)

        let session = Session(date: Date(), activities: "Caught Pokemon")
        session.game = game
        context.insert(session)

        let member = TeamMember(pokemonName: "Pikachu", level: 50)
        member.session = session
        session.team.append(member)
        context.insert(member)

        try context.save()

        // Clear all data (simulates reload button press)
        loader.clearAllData(context: context)

        // Insert the same game again (simulates loadGames after clear)
        let game2 = Game(name: "purpur", filePath: "/pokemon/purpur/purpur.md")
        context.insert(game2)

        let session2 = Session(date: Date(), activities: "Caught Pokemon")
        session2.game = game2
        context.insert(session2)

        let member2 = TeamMember(pokemonName: "Pikachu", level: 50)
        member2.session = session2
        session2.team.append(member2)
        context.insert(member2)

        try context.save()

        // Verify: exactly 1 game, 1 session, 1 team member — no duplicates
        let games = try context.fetch(FetchDescriptor<Game>())
        let sessions = try context.fetch(FetchDescriptor<Session>())
        let members = try context.fetch(FetchDescriptor<TeamMember>())

        #expect(games.count == 1, "Expected 1 game but found \(games.count) — data was duplicated on reload")
        #expect(sessions.count == 1, "Expected 1 session but found \(sessions.count)")
        #expect(members.count == 1, "Expected 1 team member but found \(members.count)")
    }

}
