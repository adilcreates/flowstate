//
//  EditorView.swift
//  Flowstate
//
//  Main text editor view
//

import SwiftUI

struct EditorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = EditorViewModel()

    var body: some View {
        ZStack {
            // Background
            Color(appState.colorScheme == .light ? .white : .black)
                .ignoresSafeArea()

            // Text Editor
            TextEditor(text: $viewModel.text)
                .background(Color(appState.colorScheme == .light ? .white : .black))
                .font(.custom(appState.selectedFont, size: CGFloat(appState.fontSize)))
                .foregroundColor(appState.colorScheme == .light ?
                    Color(red: 0.20, green: 0.20, blue: 0.20) :
                    Color(red: 0.9, green: 0.9, blue: 0.9))
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .lineSpacing(appState.lineHeight)
                .frame(maxWidth: 650)
                .id("\(appState.selectedFont)-\(appState.fontSize)-\(appState.colorScheme)")
                .colorScheme(appState.colorScheme)
                .overlay(
                    placeholderOverlay,
                    alignment: .topLeading
                )
        }
        .onAppear {
            viewModel.loadCurrentNote()
            setupKeyboardMonitor()
        }
        .onChange(of: appState.currentNote?.id) { _ in
            viewModel.loadCurrentNote()
        }
    }

    // MARK: - Placeholder

    @ViewBuilder
    private var placeholderOverlay: some View {
        if viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(viewModel.placeholderText)
                .font(.custom(appState.selectedFont, size: CGFloat(appState.fontSize)))
                .foregroundColor(appState.colorScheme == .light ?
                    .gray.opacity(0.5) :
                    .gray.opacity(0.6))
                .allowsHitTesting(false)
                .offset(x: 5, y: CGFloat(appState.fontSize) / 2)
        }
    }

    // MARK: - Keyboard Monitor

    private func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Block backspace if disabled
            if viewModel.backspaceDisabled && (event.keyCode == 51 || event.keyCode == 117) {
                return nil
            }
            return event
        }
    }
}
