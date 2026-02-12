//
//  Session.swift
//  PokéJournal
//

import Foundation
import SwiftData

@Model
final class Session {
    var date: Date
    var activities: String
    var plans: String
    var thoughts: String
    var filePath: String

    @Relationship(deleteRule: .cascade)
    var team: [TeamMember] = []

    @Relationship(inverse: \Game.sessions)
    var game: Game?

    init(date: Date, activities: String = "", plans: String = "", thoughts: String = "", filePath: String = "") {
        self.date = date
        self.activities = activities
        self.plans = plans
        self.thoughts = thoughts
        self.filePath = filePath
    }

    var formattedDate: String {
        date.formatted(date: .long, time: .omitted)
    }

    var hasTeam: Bool {
        !team.isEmpty
    }
}
