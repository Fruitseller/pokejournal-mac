//
//  AnySession.swift
//  PokéJournal
//

import Foundation
import SwiftData

enum AnySession: Hashable, Identifiable {
    case regular(Session)
    case old(OldSession)

    var id: String {
        switch self {
        case .regular(let s): return "session-\(s.date.timeIntervalSince1970)"
        case .old(let o): return "old-\(o.date.timeIntervalSince1970)"
        }
    }

    var date: Date {
        switch self {
        case .regular(let s): return s.date
        case .old(let o): return o.date
        }
    }

    var activities: String {
        switch self {
        case .regular(let s): return s.activities
        case .old(let o): return o.activities
        }
    }

    var plans: String {
        switch self {
        case .regular(let s): return s.plans
        case .old(let o): return o.plans
        }
    }

    var thoughts: String {
        switch self {
        case .regular(let s): return s.thoughts
        case .old(let o): return o.thoughts
        }
    }

    var team: [TeamMember] {
        switch self {
        case .regular(let s): return s.orderedTeam
        case .old(let o): return o.orderedTeam
        }
    }

    var isOld: Bool {
        switch self {
        case .regular: return false
        case .old: return true
        }
    }

    var filePath: String? {
        switch self {
        case .regular(let s): return s.filePath
        case .old: return nil
        }
    }

    var hasTeam: Bool {
        !team.isEmpty
    }

    var formattedDate: String {
        date.formatted(date: .long, time: .omitted)
    }
}
