//
//  EditorViewModel.swift
//  Flowstate
//
//  View model for the main editor view
//

import SwiftUI
import Combine

@MainActor
class EditorViewModel: ObservableObject {
    @Published var text: String = "" {
        didSet {
            onTextChange()
        }
    }
    @Published var wordCount: Int = 0
    @Published var placeholderText: String = ""

    // Hover states
    @Published var isHoveringTimer = false
    @Published var isHoveringFullscreen = false
    @Published var isHoveringChat = false
    @Published var isHoveringSize = false
    @Published var isHoveringNewEntry = false
    @Published var isHoveringClock = false
    @Published var isHoveringThemeToggle = false
    @Published var isHoveringBackspaceToggle = false
    @Published var isHoveringBottomNav = false
    @Published var hoveredFont: String? = nil

    // UI state
    @Published var bottomNavOpacity: Double = 1.0
    @Published var backspaceDisabled = false
    @Published var showingChatMenu = false
    @Published var didCopyPrompt = false

    private weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTask: Task<Void, Never>?

    // AI Prompts
    let aiChatPrompt = """
    below is my journal entry. wyt? talk through it with me like a friend. don't therpaize me and give me a whole breakdown, don't repeat my thoughts with headings. really take all of this, and tell me back stuff truly as if you're an old homie.

    Keep it casual, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it. dont be afraid to say a lot. format with markdown headings if needed.

    do not just go through every single thing i say, and say it back to me. you need to proccess everythikng is say, make connections i don't see it, and deliver it all back to me as a story that makes me feel what you think i wanna feel. thats what the best therapists do.

    ideally, you're style/tone should sound like the user themselves. it's as if the user is hearing their own tone but it should still feel different, because you have different things to say and don't just repeat back they say.

    else, start by saying, "hey, thanks for showing me this. my thoughts:"

    my entry:
    """

    let claudePrompt = """
    Take a look at my journal entry below. I'd like you to analyze it and respond with deep insight that feels personal, not clinical.
    Imagine you're not just a friend, but a mentor who truly gets both my tech background and my psychological patterns. I want you to uncover the deeper meaning and emotional undercurrents behind my scattered thoughts.
    Keep it casual, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it. dont be afraid to say a lot. format with markdown headings if needed.
    Use vivid metaphors and powerful imagery to help me see what I'm really building. Organize your thoughts with meaningful headings that create a narrative journey through my ideas.
    Don't just validate my thoughts - reframe them in a way that shows me what I'm really seeking beneath the surface. Go beyond the product concepts to the emotional core of what I'm trying to solve.
    Be willing to be profound and philosophical without sounding like you're giving therapy. I want someone who can see the patterns I can't see myself and articulate them in a way that feels like an epiphany.
    Start with 'hey, thanks for showing me this. my thoughts:' and then use markdown headings to structure your response.

    Here's my journal entry:
    """

    init(appState: AppState? = nil) {
        self.appState = appState
        self.placeholderText = AppState.shared.randomPlaceholder()
        loadCurrentNote()
    }

    // MARK: - Note Management

    func loadCurrentNote() {
        if let note = appState?.currentNote ?? AppState.shared.currentNote {
            text = note.content
            wordCount = note.wordCount
        }
    }

    func loadNote(_ note: Note) {
        text = note.content
        wordCount = note.wordCount
    }

    private func onTextChange() {
        // Ensure text always starts with two newlines
        if !text.hasPrefix("\n\n") && !text.isEmpty {
            text = "\n\n" + text.trimmingCharacters(in: .newlines)
            return
        }

        updateWordCount()
        scheduleAutoSave()
    }

    private func updateWordCount() {
        wordCount = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    // MARK: - Auto-Save

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()

        autoSaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                if !Task.isCancelled {
                    await saveNote()
                }
            } catch {
                // Task was cancelled, ignore
            }
        }
    }

    func saveNote() {
        guard var note = appState?.currentNote ?? AppState.shared.currentNote else { return }
        note.content = text
        note.updateTitle()
        note.updateWordCount()

        do {
            try NoteManager.shared.save(note)
            AppState.shared.currentNote = note
        } catch {
            print("Error saving note: \(error)")
        }
    }

    // MARK: - Actions

    func createNewNote() {
        saveNote() // Save current first
        AppState.shared.createNewNote()
        loadCurrentNote()
        placeholderText = AppState.shared.randomPlaceholder()
    }

    func toggleFullscreen() {
        if let window = NSApplication.shared.windows.first {
            window.toggleFullScreen(nil)
        }
    }

    // MARK: - AI Chat

    func openChatGPT() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullText = aiChatPrompt + "\n\n" + trimmedText

        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://chat.openai.com/?prompt=" + encodedText) {
            NSWorkspace.shared.open(url)
        }
    }

    func openClaude() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullText = claudePrompt + "\n\n" + trimmedText

        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://claude.ai/new?q=" + encodedText) {
            NSWorkspace.shared.open(url)
        }
    }

    func copyPromptToClipboard() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullText = aiChatPrompt + "\n\n" + trimmedText

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullText, forType: .string)
        didCopyPrompt = true
    }

    // MARK: - UI Helpers

    var isTextTooLongForUrl: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let gptFullText = aiChatPrompt + "\n\n" + trimmedText
        let encodedGptText = gptFullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return encodedGptText.count + "https://chat.openai.com/?m=".count > 6000
    }

    var isTextTooShort: Bool {
        text.count < 350
    }

    var isWelcomeEntry: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("hi. my name is farza.")
    }
}
