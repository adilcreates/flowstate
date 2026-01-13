//
//  AppState.swift
//  Flowstate
//
//  Global application state
//

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Note State
    @Published var currentNote: Note?
    @Published var notes: [Note] = []

    // MARK: - UI State
    @Published var showingSidebar = false
    @Published var showingNoteSwitcher = false
    @Published var isFullscreen = false

    // MARK: - Theme
    @AppStorage("colorScheme") var colorSchemeString: String = "light"

    var colorScheme: ColorScheme {
        get { colorSchemeString == "dark" ? .dark : .light }
        set { colorSchemeString = newValue == .dark ? "dark" : "light" }
    }

    // MARK: - Editor Settings
    @AppStorage("selectedFont") var selectedFont: String = "Lato-Regular"
    @AppStorage("fontSize") var fontSize: Double = 18
    @Published var currentRandomFont: String = ""

    // MARK: - Timer
    @Published var timeRemaining: Int = 900 // 15 minutes
    @Published var timerIsRunning = false

    // MARK: - Services
    let noteManager = NoteManager.shared
    let searchEngine = SearchEngine()

    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    let availableFonts = NSFontManager.shared.availableFontFamilies
    let standardFonts = ["Lato-Regular", "Arial", ".AppleSystemUIFont", "Times New Roman"]
    let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
    let placeholderOptions = [
        "\n\nBegin writing",
        "\n\nPick a thought and go",
        "\n\nStart typing",
        "\n\nWhat's on your mind",
        "\n\nJust start",
        "\n\nType your first thought",
        "\n\nStart with one sentence",
        "\n\nJust say it"
    ]

    // MARK: - Initialization

    private init() {
        loadNotes()
        setupSubscriptions()
    }

    // MARK: - Note Management

    func loadNotes() {
        noteManager.loadNotes()
        notes = noteManager.notes

        // Load last edited note or create new
        if let lastNote = noteManager.getLastEditedNote() {
            currentNote = lastNote
        } else {
            createNewNote()
        }
    }

    func createNewNote() {
        let note = noteManager.createNote(withContent: "\n\n")
        currentNote = note
        notes = noteManager.notes
    }

    func selectNote(_ note: Note) {
        // Save current note first
        if let current = currentNote {
            noteManager.saveImmediately(current)
        }

        currentNote = note
    }

    func deleteNote(_ note: Note) {
        do {
            try noteManager.delete(note)
            notes = noteManager.notes

            // If deleted current note, select first available
            if currentNote?.id == note.id {
                currentNote = notes.first
                if currentNote == nil {
                    createNewNote()
                }
            }
        } catch {
            print("Error deleting note: \(error)")
        }
    }

    // MARK: - Auto-Save

    func scheduleAutoSave() {
        guard let note = currentNote else { return }
        noteManager.scheduleAutoSave(for: note)
    }

    func saveCurrentNote() {
        guard let note = currentNote else { return }
        noteManager.saveImmediately(note)
        notes = noteManager.notes
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() {
        // Keep notes array in sync
        noteManager.$notes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notes in
                self?.notes = notes
            }
            .store(in: &cancellables)
    }

    // MARK: - Theme

    func toggleTheme() {
        colorScheme = colorScheme == .light ? .dark : .light
    }

    // MARK: - Timer

    func toggleTimer() {
        timerIsRunning.toggle()
    }

    func resetTimer() {
        timeRemaining = 900
        timerIsRunning = false
    }

    func tickTimer() {
        if timerIsRunning && timeRemaining > 0 {
            timeRemaining -= 1
        } else if timeRemaining == 0 {
            timerIsRunning = false
        }
    }

    // MARK: - UI Helpers

    var timerButtonTitle: String {
        if !timerIsRunning && timeRemaining == 900 {
            return "15:00"
        }
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var lineHeight: CGFloat {
        let font = NSFont(name: selectedFont, size: CGFloat(fontSize)) ?? .systemFont(ofSize: CGFloat(fontSize))
        let defaultLineHeight = font.ascender - font.descender + font.leading
        return (CGFloat(fontSize) * 1.5) - defaultLineHeight
    }

    func randomPlaceholder() -> String {
        placeholderOptions.randomElement() ?? "\n\nBegin writing"
    }
}
