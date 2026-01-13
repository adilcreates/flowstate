//
//  NoteSwitcherView.swift
//  Flowstate
//
//  Spotlight-style note switcher (Cmd+O)
//

import SwiftUI

struct NoteSwitcherView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = NoteSwitcherViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            searchField

            Divider()

            // Results list
            resultsList
        }
        .frame(width: 500, height: 350)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .onAppear {
            isSearchFocused = true
            viewModel.loadRecentNotes()
        }
        .onKeyPress(.escape) {
            appState.showingNoteSwitcher = false
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.selectNext()
            return .handled
        }
        .onKeyPress(.upArrow) {
            viewModel.selectPrevious()
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.openSelected()
            appState.showingNoteSwitcher = false
            return .handled
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            TextField("Search notes...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($isSearchFocused)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.filteredNotes.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.filteredNotes) { note in
                            NoteSwitcherRow(
                                note: note,
                                isSelected: viewModel.isSelected(note)
                            ) {
                                viewModel.openSelected()
                                appState.showingNoteSwitcher = false
                            }
                            .id(note.id)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.selectedIndex) { _ in
                if let selectedNote = viewModel.selectedNote {
                    withAnimation {
                        proxy.scrollTo(selectedNote.id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No notes found")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            if !viewModel.searchQuery.isEmpty {
                Text("Try a different search term")
                    .font(.system(size: 12))
                    .foregroundColor(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Note Switcher Row

struct NoteSwitcherRow: View {
    let note: Note
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                // Note icon
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                // Note content
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(note.displayDate)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.tertiary)

                        Text("\(note.wordCount) words")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Keyboard hint when selected
                if isSelected {
                    Text("↵")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isHovering {
            return Color.primary.opacity(0.05)
        }
        return Color.clear
    }
}
