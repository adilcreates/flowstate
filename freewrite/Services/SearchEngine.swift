//
//  SearchEngine.swift
//  Flowstate
//
//  FTS5-powered full-text search for notes
//

import Foundation
import GRDB

class SearchEngine {
    private let db = DatabaseManager.shared

    // MARK: - Search

    /// Search notes using FTS5 full-text search
    /// - Parameter query: The search query
    /// - Returns: Array of matching notes, sorted by relevance
    func search(query: String) -> [Note] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return recentNotes(limit: 20)
        }

        do {
            return try db.read { db in
                // Use FTS5 match query
                // Adding * for prefix matching (e.g., "hel" matches "hello")
                let ftsQuery = query
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                    .map { "\($0)*" }
                    .joined(separator: " ")

                let sql = """
                    SELECT notes.*
                    FROM notes
                    JOIN notes_fts ON notes.rowid = notes_fts.rowid
                    WHERE notes_fts MATCH ?
                    AND notes.isArchived = 0
                    ORDER BY bm25(notes_fts) DESC
                    LIMIT 50
                """

                return try Note.fetchAll(db, sql: sql, arguments: [ftsQuery])
            }
        } catch {
            print("Search error: \(error)")
            // Fall back to simple LIKE search
            return simpleSearch(query: query)
        }
    }

    /// Simple LIKE-based search as fallback
    private func simpleSearch(query: String) -> [Note] {
        do {
            return try db.read { db in
                let pattern = "%\(query)%"
                return try Note
                    .filter(Note.Columns.isArchived == false)
                    .filter(
                        Note.Columns.title.like(pattern) ||
                        Note.Columns.content.like(pattern)
                    )
                    .order(Note.Columns.updatedAt.desc)
                    .limit(50)
                    .fetchAll(db)
            }
        } catch {
            print("Simple search error: \(error)")
            return []
        }
    }

    /// Get recent notes
    /// - Parameter limit: Maximum number of notes to return
    /// - Returns: Array of most recently updated notes
    func recentNotes(limit: Int = 20) -> [Note] {
        do {
            return try db.read { db in
                try Note
                    .filter(Note.Columns.isArchived == false)
                    .order(Note.Columns.updatedAt.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        } catch {
            print("Error fetching recent notes: \(error)")
            return []
        }
    }

    /// Get notes created on a specific date
    /// - Parameter date: The date to filter by
    /// - Returns: Array of notes created on that date
    func notesForDate(_ date: Date) -> [Note] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        do {
            return try db.read { db in
                try Note
                    .filter(Note.Columns.createdAt >= startOfDay)
                    .filter(Note.Columns.createdAt < endOfDay)
                    .filter(Note.Columns.isArchived == false)
                    .order(Note.Columns.createdAt.desc)
                    .fetchAll(db)
            }
        } catch {
            print("Error fetching notes for date: \(error)")
            return []
        }
    }
}
