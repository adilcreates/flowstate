//
//  MigrationService.swift
//  Flowstate
//
//  Migrates existing freewrite markdown files to SQLite database
//

import Foundation
import GRDB

class MigrationService {
    private let db = DatabaseManager.shared
    private let fileManager = FileManager.default

    // Old Freewrite documents directory
    private var freewriteDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("Freewrite")
    }

    // Archive directory for migrated files
    private var archiveDirectory: URL {
        return freewriteDirectory.appendingPathComponent("archived")
    }

    // MARK: - Migration Check

    /// Check if migration from file system is needed
    func needsMigration() -> Bool {
        // Check if Freewrite directory exists and has .md files
        guard fileManager.fileExists(atPath: freewriteDirectory.path) else {
            return false
        }

        do {
            let files = try fileManager.contentsOfDirectory(at: freewriteDirectory, includingPropertiesForKeys: nil)
            let mdFiles = files.filter { $0.pathExtension == "md" }

            // Check if database is empty
            let noteCount = try db.read { db in
                try Note.fetchCount(db)
            }

            // Need migration if we have MD files but no notes in DB
            return !mdFiles.isEmpty && noteCount == 0
        } catch {
            print("Error checking migration status: \(error)")
            return false
        }
    }

    // MARK: - Migration

    /// Migrate all markdown files from Freewrite directory to SQLite
    func migrateFromFileSystem() async throws -> Int {
        print("Starting migration from file system...")

        guard fileManager.fileExists(atPath: freewriteDirectory.path) else {
            print("Freewrite directory does not exist")
            return 0
        }

        // Get all .md files
        let fileURLs = try fileManager.contentsOfDirectory(at: freewriteDirectory, includingPropertiesForKeys: nil)
        let mdFiles = fileURLs.filter { $0.pathExtension == "md" }

        print("Found \(mdFiles.count) markdown files to migrate")

        var migratedCount = 0

        for fileURL in mdFiles {
            do {
                let note = try parseMarkdownFile(at: fileURL)
                try db.write { db in
                    try note.save(db)
                }
                migratedCount += 1
                print("Migrated: \(fileURL.lastPathComponent)")

                // Archive the original file
                try archiveFile(at: fileURL)
            } catch {
                print("Error migrating \(fileURL.lastPathComponent): \(error)")
            }
        }

        print("Migration complete. Migrated \(migratedCount) notes.")
        return migratedCount
    }

    // MARK: - File Parsing

    /// Parse a markdown file into a Note
    private func parseMarkdownFile(at url: URL) throws -> Note {
        let filename = url.lastPathComponent
        let content = try String(contentsOf: url, encoding: .utf8)

        // Extract UUID and date from filename pattern: [UUID]-[yyyy-MM-dd-HH-mm-ss].md
        var noteId = UUID().uuidString
        var createdAt = Date()

        // Try to extract UUID from filename
        if let uuidMatch = filename.range(of: "\\[([A-F0-9-]+)\\]", options: .regularExpression) {
            let uuidString = String(filename[uuidMatch]).dropFirst().dropLast()
            if let uuid = UUID(uuidString: String(uuidString)) {
                noteId = uuid.uuidString
            }
        }

        // Try to extract date from filename
        if let dateMatch = filename.range(of: "\\[(\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{2})\\]", options: .regularExpression) {
            let dateString = String(filename[dateMatch]).dropFirst().dropLast()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            if let date = dateFormatter.date(from: String(dateString)) {
                createdAt = date
            }
        }

        // If no date in filename, use file modification date
        if createdAt == Date() {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let modDate = attributes[.modificationDate] as? Date {
                createdAt = modDate
            }
        }

        var note = Note(
            id: noteId,
            content: content,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        note.updateTitle()
        note.updateWordCount()

        return note
    }

    /// Archive a migrated file
    private func archiveFile(at url: URL) throws {
        // Create archive directory if needed
        if !fileManager.fileExists(atPath: archiveDirectory.path) {
            try fileManager.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
        }

        let destinationURL = archiveDirectory.appendingPathComponent(url.lastPathComponent)

        // If file already exists in archive, add timestamp
        var finalDestination = destinationURL
        if fileManager.fileExists(atPath: destinationURL.path) {
            let timestamp = Int(Date().timeIntervalSince1970)
            let newFilename = url.deletingPathExtension().lastPathComponent + "_\(timestamp).md"
            finalDestination = archiveDirectory.appendingPathComponent(newFilename)
        }

        try fileManager.moveItem(at: url, to: finalDestination)
        print("Archived: \(url.lastPathComponent) -> \(finalDestination.lastPathComponent)")
    }

    // MARK: - Rollback (if needed)

    /// Restore archived files back to original location
    func restoreArchivedFiles() throws {
        guard fileManager.fileExists(atPath: archiveDirectory.path) else {
            print("No archive directory found")
            return
        }

        let archivedFiles = try fileManager.contentsOfDirectory(at: archiveDirectory, includingPropertiesForKeys: nil)
        let mdFiles = archivedFiles.filter { $0.pathExtension == "md" }

        for fileURL in mdFiles {
            let destinationURL = freewriteDirectory.appendingPathComponent(fileURL.lastPathComponent)
            try fileManager.moveItem(at: fileURL, to: destinationURL)
            print("Restored: \(fileURL.lastPathComponent)")
        }

        print("Restored \(mdFiles.count) files from archive")
    }
}
