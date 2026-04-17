//
//  TeamCheckAnalyzer.swift
//  PokéJournal
//

import Foundation

struct TeamMemberAnalysis: Equatable {
    let memberName: String
    let types: [String]
    let category: Category
    let reason: String?

    enum Category: Equatable {
        case kernstueck
        case ausgewogen
        case verzichtbar(ersatzTyp: String)
    }
}

enum TeamCheckAnalyzer {

    struct Member: Equatable {
        let name: String
        let types: [String]
    }

    static func analyze(
        team: [Member],
        generation: TypeChartGeneration
    ) -> [TeamMemberAnalysis] {
        return []
    }
}
