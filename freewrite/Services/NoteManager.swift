//
//  NoteManager.swift
//  Flowstate
//
//  CRUD operations for notes with auto-save functionality
//

import Foundation
import GRDB
import Combine

@MainActor
class NoteManager: ObservableObject {
    static let shared = NoteManager()

    @Published var notes: [Note] = []
    @Published var currentNote: Note?

    private let db = DatabaseManager.shared
    private var autoSaveTask: Task<Void, Never>?
    private let autoSaveDelay: UInt64 = 3_000_000_000 // 3 seconds in nanoseconds

    private init() {
        loadNotes()
    }

    // MARK: - CRUD Operations

    func loadNotes() {
        do {
            notes = try db.read { db in
                try Note
                    .filter(Note.Columns.isArchived == false)
                    .order(Note.Columns.updatedAt.desc)
                    .fetchAll(db)
            }
            print("Loaded \(notes.count) notes")
        } catch {
            print("Error loading notes: \(error)")
            notes = []
        }
    }

    func save(_ note: Note) throws {
        var noteToSave = note
        noteToSave.updatedAt = Date()
        noteToSave.updateTitle()
        noteToSave.updateWordCount()

        try db.write { db in
            try noteToSave.save(db)
        }

        // Update local array
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = noteToSave
        } else {
            notes.insert(noteToSave, at: 0)
        }

        // Re-sort by updated date
        notes.sort { $0.updatedAt > $1.updatedAt }

        // Update current note if it's the one we saved
        if currentNote?.id == note.id {
            currentNote = noteToSave
        }
    }

    func createNote(withContent content: String = "") -> Note {
        var note = Note()
        note.content = content
        note.updateTitle()
        note.updateWordCount()

        do {
            try save(note)
            currentNote = note
            print("Created new note: \(note.id)")
        } catch {
            print("Error creating note: \(error)")
        }

        return note
    }

    func delete(_ note: Note) throws {
        try db.write { db in
            _ = try Note.deleteOne(db, key: note.id)
        }

        // Remove from local array
        notes.removeAll { $0.id == note.id }

        // If deleted note was current, select another
        if currentNote?.id == note.id {
            currentNote = notes.first
        }

        print("Deleted note: \(note.id)")
    }

    func getNote(id: String) -> Note? {
        return notes.first { $0.id == id }
    }

    func getLastEditedNote() -> Note? {
        return notes.first
    }

    // MARK: - Auto-Save

    func scheduleAutoSave(for note: Note) {
        autoSaveTask?.cancel()

        autoSaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: autoSaveDelay)
                if !Task.isCancelled {
                    try save(note)
                    print("Auto-saved note: \(note.id)")
                }
            } catch {
                if !(error is CancellationError) {
                    print("Auto-save error: \(error)")
                }
            }
        }
    }

    func saveImmediately(_ note: Note) {
        autoSaveTask?.cancel()
        do {
            try save(note)
            print("Immediately saved note: \(note.id)")
        } catch {
            print("Error saving note: \(error)")
        }
    }

    // MARK: - Stats Tracking

    func trackNoteCreated() {
        updateDailyStats { stats in
            stats.notesCreated += 1
        }
    }

    func trackWordsWritten(_ count: Int) {
        updateDailyStats { stats in
            stats.wordsWritten += count
        }
    }

    private func updateDailyStats(_ update: (inout DailyStats) -> Void) {
        let today = DailyStats(date: Date())

        do {
            try db.write { db in
                var stats = try DailyStats.fetchOne(db, key: today.date) ?? today
                update(&stats)
                try stats.save(db)
            }
        } catch {
            print("Error updating daily stats: \(error)")
        }
    }
}
