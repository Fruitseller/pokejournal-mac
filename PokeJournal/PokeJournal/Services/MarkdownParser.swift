//
//  MarkdownParser.swift
//  PokéJournal
//

import Foundation

struct ParsedGameMetadata {
    var aliases: [String] = []
    var releaseDate: String?
    var platforms: [String] = []
    var genre: String?
    var developer: String?
    var metacriticScore: Int?
}

struct ParsedSession {
    var date: Date
    var activities: String = ""
    var plans: String = ""
    var thoughts: String = ""
    var team: [ParsedTeamMember] = []
}

struct ParsedTeamMember {
    var name: String
    var level: Int
    var variant: String?
}

final class MarkdownParser {
    static let shared = MarkdownParser()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private init() {}

    // MARK: - YAML Frontmatter Parser

    func parseYAMLFrontmatter(from content: String) -> ParsedGameMetadata {
        var metadata = ParsedGameMetadata()

        guard content.hasPrefix("---") else { return metadata }

        let lines = content.components(separatedBy: .newlines)
        var inFrontmatter = false
        var frontmatterLines: [String] = []

        for line in lines {
            if line == "---" {
                if inFrontmatter {
                    break
                } else {
                    inFrontmatter = true
                    continue
                }
            }

            if inFrontmatter {
                frontmatterLines.append(line)
            }
        }

        for line in frontmatterLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                switch key.lowercased() {
                case "aliases":
                    metadata.aliases = parseYAMLArray(value, lines: frontmatterLines, startingFrom: line)
                case "release":
                    metadata.releaseDate = value.isEmpty ? nil : value
                case "platforms":
                    metadata.platforms = parseYAMLArray(value, lines: frontmatterLines, startingFrom: line)
                case "genre":
                    metadata.genre = value.isEmpty ? nil : value
                case "developer":
                    metadata.developer = value.isEmpty ? nil : value
                case "metacritic":
                    metadata.metacriticScore = Int(value)
                default:
                    break
                }
            }
        }

        return metadata
    }

    private func parseYAMLArray(_ inlineValue: String, lines: [String], startingFrom startLine: String) -> [String] {
        if inlineValue.hasPrefix("[") && inlineValue.hasSuffix("]") {
            let inner = String(inlineValue.dropFirst().dropLast())
            return inner.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) }
                .filter { !$0.isEmpty }
        }

        var results: [String] = []
        var foundStart = false

        for line in lines {
            if line == startLine {
                foundStart = true
                continue
            }

            if foundStart {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("- ") {
                    let item = String(trimmed.dropFirst(2)).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    results.append(item)
                } else if !trimmed.isEmpty && !trimmed.hasPrefix("-") {
                    break
                }
            }
        }

        return results
    }

    // MARK: - Session Parser

    func parseSessionSections(from content: String) -> (activities: String, plans: String, thoughts: String, team: [ParsedTeamMember]) {
        var activities = ""
        var plans = ""
        var thoughts = ""
        var team: [ParsedTeamMember] = []

        let sections = extractSections(from: content)

        if let activitiesContent = sections["aktivitäten"] ?? sections["activities"] {
            activities = activitiesContent
        }

        if let plansContent = sections["pläne"] ?? sections["plans"] {
            plans = plansContent
        }

        if let thoughtsContent = sections["gedanken"] ?? sections["thoughts"] {
            thoughts = thoughtsContent
        }

        if let teamContent = sections["team"] {
            team = parseTeam(from: teamContent)
        }

        // Fallback: Also look for "Team:" without heading (old inline format)
        if team.isEmpty {
            team = parseTeamFromInlineFormat(content)
        }

        return (activities, plans, thoughts, team)
    }

    // Parse team from various inline formats without ## heading
    private func parseTeamFromInlineFormat(_ content: String) -> [ParsedTeamMember] {
        // Try multiple patterns for team headers:
        // 1. "Team:" or "Mein Team:" or "Mein derzeitiges Team:" etc.
        // 2. Any line ending with "Team:" followed by bullet list
        let teamHeaderPatterns = [
            #"(?:Mein\s+)?(?:derzeitiges\s+)?Team[:\s]*\n((?:- .+\n?)+)"#,
            #"Team sieht folgender Maßen aus:\s*\n+((?:- .+\n?)+)"#,
        ]

        for pattern in teamHeaderPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            if let match = regex?.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
               let teamRange = Range(match.range(at: 1), in: content) {
                let teamContent = String(content[teamRange])
                let team = parseTeam(from: teamContent)
                if !team.isEmpty {
                    return team
                }
            }
        }

        // Fallback: Find any bullet list that looks like Pokemon team entries
        // (lines starting with "- " followed by name and "lvl")
        let fallbackPattern = #"((?:^- \w+.*lvl.*$\n?)+)"#
        let fallbackRegex = try? NSRegularExpression(pattern: fallbackPattern, options: [.caseInsensitive, .anchorsMatchLines])

        if let match = fallbackRegex?.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
           let teamRange = Range(match.range(at: 1), in: content) {
            let teamContent = String(content[teamRange])
            return parseTeam(from: teamContent)
        }

        return []
    }

    private func extractSections(from content: String) -> [String: String] {
        var sections: [String: String] = [:]
        let lines = content.components(separatedBy: .newlines)

        var currentSection: String?
        var currentContent: [String] = []

        let sectionPattern = #"^#{1,3}\s+(.+)$"#
        let sectionRegex = try? NSRegularExpression(pattern: sectionPattern, options: .caseInsensitive)

        for line in lines {
            if let match = sectionRegex?.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range(at: 1), in: line) {
                if let section = currentSection {
                    sections[section.lowercased()] = currentContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                }

                currentSection = String(line[range])
                currentContent = []
            } else if currentSection != nil {
                currentContent.append(line)
            }
        }

        if let section = currentSection {
            sections[section.lowercased()] = currentContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return sections
    }

    // MARK: - Team Parser

    func parseTeam(from content: String) -> [ParsedTeamMember] {
        var members: [ParsedTeamMember] = []

        let pattern = #"^-\s+(?:(\w+)\s+)?(\w+)\s+lvl\s+(\d+)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines])

        let range = NSRange(content.startIndex..., in: content)
        let matches = regex?.matches(in: content, options: [], range: range) ?? []

        for match in matches {
            var variant: String?
            var name: String
            var level: Int

            if match.range(at: 1).location != NSNotFound,
               let variantRange = Range(match.range(at: 1), in: content) {
                variant = String(content[variantRange])
            }

            guard let nameRange = Range(match.range(at: 2), in: content),
                  let levelRange = Range(match.range(at: 3), in: content),
                  let levelInt = Int(content[levelRange]) else {
                continue
            }

            name = String(content[nameRange])
            level = levelInt

            members.append(ParsedTeamMember(name: name, level: level, variant: variant))
        }

        return members
    }

    // MARK: - Old Format Parser

    func parseOldFormatSessions(from content: String, sourceFile: String) -> [ParsedSession] {
        var sessions: [ParsedSession] = []

        let datePattern = #"^##\s+(\d{4}-\d{2}-\d{2})"#
        let dateRegex = try? NSRegularExpression(pattern: datePattern, options: .anchorsMatchLines)

        let lines = content.components(separatedBy: .newlines)
        var currentDate: Date?
        var currentContent: [String] = []

        for line in lines {
            if let match = dateRegex?.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
               let dateRange = Range(match.range(at: 1), in: line),
               let date = dateFormatter.date(from: String(line[dateRange])) {

                if let prevDate = currentDate {
                    let sessionContent = currentContent.joined(separator: "\n")
                    var (activities, plans, thoughts, team) = parseSessionSections(from: sessionContent)

                    // Old format has no section headers → use raw content as activities
                    if activities.isEmpty && plans.isEmpty && thoughts.isEmpty {
                        activities = sessionContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    sessions.append(ParsedSession(
                        date: prevDate,
                        activities: activities,
                        plans: plans,
                        thoughts: thoughts,
                        team: team
                    ))
                }

                currentDate = date
                currentContent = []
            } else if currentDate != nil {
                currentContent.append(line)
            }
        }

        if let lastDate = currentDate {
            let sessionContent = currentContent.joined(separator: "\n")
            var (activities, plans, thoughts, team) = parseSessionSections(from: sessionContent)

            if activities.isEmpty && plans.isEmpty && thoughts.isEmpty {
                activities = sessionContent.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            sessions.append(ParsedSession(
                date: lastDate,
                activities: activities,
                plans: plans,
                thoughts: thoughts,
                team: team
            ))
        }

        return sessions
    }

    // MARK: - Session Filename Parser

    func parseDateFromFilename(_ filename: String) -> Date? {
        let pattern = #"(\d{4}-\d{2}-\d{2})"#
        let regex = try? NSRegularExpression(pattern: pattern)

        guard let match = regex?.firstMatch(in: filename, options: [], range: NSRange(filename.startIndex..., in: filename)),
              let range = Range(match.range(at: 1), in: filename) else {
            return nil
        }

        return dateFormatter.date(from: String(filename[range]))
    }
}
