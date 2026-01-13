//
//  NoteSwitcherViewModel.swift
//  Flowstate
//
//  View model for the Cmd+O note switcher
//

import SwiftUI
import Combine

@MainActor
class NoteSwitcherViewModel: ObservableObject {
    @Published var searchQuery: String = "" {
        didSet {
            search()
        }
    }
    @Published var filteredNotes: [Note] = []
    @Published var selectedIndex: Int = 0

    private let searchEngine = SearchEngine()
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadRecentNotes()
    }

    // MARK: - Search

    func loadRecentNotes() {
        filteredNotes = searchEngine.recentNotes(limit: 20)
        selectedIndex = 0
    }

    func search() {
        if searchQuery.isEmpty {
            loadRecentNotes()
        } else {
            filteredNotes = searchEngine.search(query: searchQuery)
            selectedIndex = 0
        }
    }

    // MARK: - Navigation

    func selectNext() {
        if selectedIndex < filteredNotes.count - 1 {
            selectedIndex += 1
        }
    }

    func selectPrevious() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func openSelected() {
        guard selectedIndex < filteredNotes.count else { return }
        let note = filteredNotes[selectedIndex]
        AppState.shared.selectNote(note)
    }

    // MARK: - Helpers

    var selectedNote: Note? {
        guard selectedIndex < filteredNotes.count else { return nil }
        return filteredNotes[selectedIndex]
    }

    func isSelected(_ note: Note) -> Bool {
        return selectedNote?.id == note.id
    }
}
