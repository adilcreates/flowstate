//
//  DailyStats.swift
//  Flowstate
//
//  Model for tracking daily writing statistics (for future heatmap)
//

import Foundation
import GRDB

struct DailyStats: Identifiable, Codable, Equatable {
    var id: String { date }
    let date: String  // YYYY-MM-DD format
    var wordsWritten: Int
    var notesCreated: Int
    var notesUpdated: Int
    var activeMinutes: Int
    var aiActionsUsed: Int

    init(
        date: Date = Date(),
        wordsWritten: Int = 0,
        notesCreated: Int = 0,
        notesUpdated: Int = 0,
        activeMinutes: Int = 0,
        aiActionsUsed: Int = 0
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.string(from: date)
        self.wordsWritten = wordsWritten
        self.notesCreated = notesCreated
        self.notesUpdated = notesUpdated
        self.activeMinutes = activeMinutes
        self.aiActionsUsed = aiActionsUsed
    }

    init(
        dateString: String,
        wordsWritten: Int = 0,
        notesCreated: Int = 0,
        notesUpdated: Int = 0,
        activeMinutes: Int = 0,
        aiActionsUsed: Int = 0
    ) {
        self.date = dateString
        self.wordsWritten = wordsWritten
        self.notesCreated = notesCreated
        self.notesUpdated = notesUpdated
        self.activeMinutes = activeMinutes
        self.aiActionsUsed = aiActionsUsed
    }

    // Activity level for heatmap (0-4)
    var activityLevel: Int {
        switch wordsWritten {
        case 0: return 0
        case 1...100: return 1
        case 101...500: return 2
        case 501...1000: return 3
        default: return 4
        }
    }
}

// MARK: - GRDB Conformance

extension DailyStats: FetchableRecord, PersistableRecord {
    static let databaseTableName = "daily_stats"

    enum Columns: String, ColumnExpression {
        case date, wordsWritten, notesCreated, notesUpdated, activeMinutes, aiActionsUsed
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["date"] = date
        container["wordsWritten"] = wordsWritten
        container["notesCreated"] = notesCreated
        container["notesUpdated"] = notesUpdated
        container["activeMinutes"] = activeMinutes
        container["aiActionsUsed"] = aiActionsUsed
    }

    init(row: Row) throws {
        date = row["date"]
        wordsWritten = row["wordsWritten"]
        notesCreated = row["notesCreated"]
        notesUpdated = row["notesUpdated"]
        activeMinutes = row["activeMinutes"]
        aiActionsUsed = row["aiActionsUsed"]
    }
}
