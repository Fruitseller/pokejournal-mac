//
//  Game.swift
//  PokéJournal
//

import Foundation
import SwiftData

@Model
final class Game {
    var name: String
    var filePath: String

    // YAML Frontmatter properties
    var aliases: [String] = []
    var releaseDate: String?
    var platforms: [String] = []
    var genre: String?
    var developer: String?
    var metacriticScore: Int?
    var isHidden: Bool = false

    @Relationship(deleteRule: .cascade)
    var sessions: [Session] = []

    @Relationship(deleteRule: .cascade)
    var oldSessions: [OldSession] = []

    init(name: String, filePath: String) {
        self.name = name
        self.filePath = filePath
    }

    var allSessionDates: [Date] {
        let sessionDates = sessions.map { $0.date }
        let oldSessionDates = oldSessions.map { $0.date }
        return (sessionDates + oldSessionDates).sorted(by: <)
    }

    var totalSessionCount: Int {
        sessions.count + oldSessions.count
    }

    var lastPlayedDate: Date? {
        let latestSession = sessions.max(by: { $0.date < $1.date })?.date
        let latestOldSession = oldSessions.max(by: { $0.date < $1.date })?.date
        return [latestSession, latestOldSession].compactMap { $0 }.max()
    }

    var currentTeam: [TeamMember] {
        if let latestSession = sessions.max(by: { $0.date < $1.date }), !latestSession.team.isEmpty {
            return latestSession.orderedTeam
        }
        if let latestOldSession = oldSessions.max(by: { $0.date < $1.date }) {
            return latestOldSession.orderedTeam
        }
        return []
    }

    static func isRPGGenre(_ genre: String?) -> Bool {
        guard let genre, !genre.isEmpty else { return true }
        let lower = genre.lowercased()
        return lower.contains("rpg") || lower.contains("rollenspiel")
    }

    var displayName: String {
        aliases.first ?? name.capitalized
    }
}
