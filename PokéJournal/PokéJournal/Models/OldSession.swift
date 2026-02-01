//
//  OldSession.swift
//  PokéJournal
//

import Foundation
import SwiftData

@Model
final class OldSession {
    var date: Date
    var activities: String
    var plans: String
    var thoughts: String
    var sourceFile: String

    @Relationship(deleteRule: .cascade)
    var team: [TeamMember] = []

    @Relationship(inverse: \Game.oldSessions)
    var game: Game?

    init(date: Date, activities: String = "", plans: String = "", thoughts: String = "", sourceFile: String = "") {
        self.date = date
        self.activities = activities
        self.plans = plans
        self.thoughts = thoughts
        self.sourceFile = sourceFile
    }

    var formattedDate: String {
        date.formatted(date: .long, time: .omitted)
    }

    var hasTeam: Bool {
        !team.isEmpty
    }
}
