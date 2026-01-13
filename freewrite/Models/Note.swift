//
//  Note.swift
//  Flowstate
//
//  Core data model for notes
//

import Foundation
import GRDB

struct Note: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var wordCount: Int
    var isPinned: Bool
    var isArchived: Bool

    init(
        id: String = UUID().uuidString,
        title: String = "Untitled",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        wordCount: Int = 0,
        isPinned: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.wordCount = wordCount
        self.isPinned = isPinned
        self.isArchived = isArchived
    }

    // Auto-generate title from first non-empty line
    mutating func updateTitle() {
        let lines = content.components(separatedBy: .newlines)
        if let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            // Remove markdown heading syntax if present
            let cleaned = firstLine
                .replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            title = String(cleaned.prefix(50))
        } else {
            title = "Untitled"
        }
    }

    // Update word count from content
    mutating func updateWordCount() {
        wordCount = content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    // Preview text for sidebar (first 30 chars)
    var previewText: String {
        let trimmed = content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ""
        }
        return trimmed.count > 30 ? String(trimmed.prefix(30)) + "..." : trimmed
    }

    // Formatted date for display
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: createdAt)
    }
}

// MARK: - GRDB Conformance

extension Note: FetchableRecord, PersistableRecord {
    static let databaseTableName = "notes"

    // Define column mappings
    enum Columns: String, ColumnExpression {
        case id, title, content, createdAt, updatedAt, wordCount, isPinned, isArchived
    }

    // Custom encoding for database
    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["title"] = title
        container["content"] = content
        container["createdAt"] = createdAt
        container["updatedAt"] = updatedAt
        container["wordCount"] = wordCount
        container["isPinned"] = isPinned ? 1 : 0
        container["isArchived"] = isArchived ? 1 : 0
    }

    // Custom decoding from database
    init(row: Row) throws {
        id = row["id"]
        title = row["title"]
        content = row["content"]
        createdAt = row["createdAt"]
        updatedAt = row["updatedAt"]
        wordCount = row["wordCount"]
        isPinned = row["isPinned"] == 1
        isArchived = row["isArchived"] == 1
    }
}
