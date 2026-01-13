//
//  DatabaseManager.swift
//  Flowstate
//
//  SQLite database wrapper using GRDB with FTS5 full-text search
//

import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue?

    private init() {
        do {
            try setup()
        } catch {
            print("Failed to setup database: \(error)")
        }
    }

    // MARK: - Setup

    private func setup() throws {
        let fileManager = FileManager.default

        // Get Application Support directory
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        // Create Flowstate folder
        let appFolder = appSupport.appendingPathComponent("Flowstate", isDirectory: true)
        try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)

        // Database path
        let dbPath = appFolder.appendingPathComponent("flowstate.sqlite").path
        print("Database path: \(dbPath)")

        // Open database
        dbQueue = try DatabaseQueue(path: dbPath)

        // Run migrations
        try migrator.migrate(dbQueue!)
    }

    // MARK: - Migrations

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        // Erase database on schema change during development
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // v1: Initial schema
        migrator.registerMigration("v1_initial") { db in
            // Notes table
            try db.create(table: "notes") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull().defaults(to: "")
                t.column("content", .text).notNull().defaults(to: "")
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("wordCount", .integer).notNull().defaults(to: 0)
                t.column("isPinned", .integer).notNull().defaults(to: 0)
                t.column("isArchived", .integer).notNull().defaults(to: 0)
            }

            // Index for sorting by updated date
            try db.create(index: "idx_notes_updated", on: "notes", columns: ["updatedAt"])

            // FTS5 virtual table for full-text search
            try db.execute(sql: """
                CREATE VIRTUAL TABLE notes_fts USING fts5(
                    title,
                    content,
                    content='notes',
                    content_rowid='rowid'
                )
            """)

            // Triggers to keep FTS in sync
            try db.execute(sql: """
                CREATE TRIGGER notes_ai AFTER INSERT ON notes BEGIN
                    INSERT INTO notes_fts(rowid, title, content)
                    VALUES (new.rowid, new.title, new.content);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER notes_ad AFTER DELETE ON notes BEGIN
                    INSERT INTO notes_fts(notes_fts, rowid, title, content)
                    VALUES('delete', old.rowid, old.title, old.content);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER notes_au AFTER UPDATE ON notes BEGIN
                    INSERT INTO notes_fts(notes_fts, rowid, title, content)
                    VALUES('delete', old.rowid, old.title, old.content);
                    INSERT INTO notes_fts(rowid, title, content)
                    VALUES (new.rowid, new.title, new.content);
                END
            """)

            // Daily stats table (for future heatmap)
            try db.create(table: "daily_stats") { t in
                t.column("date", .text).primaryKey()
                t.column("wordsWritten", .integer).notNull().defaults(to: 0)
                t.column("notesCreated", .integer).notNull().defaults(to: 0)
                t.column("notesUpdated", .integer).notNull().defaults(to: 0)
                t.column("activeMinutes", .integer).notNull().defaults(to: 0)
                t.column("aiActionsUsed", .integer).notNull().defaults(to: 0)
            }
        }

        return migrator
    }

    // MARK: - Database Access

    func write<T>(_ updates: (Database) throws -> T) throws -> T {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        return try dbQueue.write(updates)
    }

    func read<T>(_ value: (Database) throws -> T) throws -> T {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        return try dbQueue.read(value)
    }

    enum DatabaseError: Error {
        case notInitialized
    }
}
