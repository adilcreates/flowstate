//
//  MainView.swift
//  Flowstate
//
//  Root container view
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var editorViewModel = EditorViewModel()

    private let navHeight: CGFloat = 68

    var body: some View {
        ZStack {
            // Main content
            HStack(spacing: 0) {
                // Editor area
                ZStack {
                    Color(appState.colorScheme == .light ? .white : .black)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        // Editor
                        EditorView()
                            .padding(.bottom, editorViewModel.bottomNavOpacity > 0 ? navHeight : 0)

                        // Bottom toolbar
                        BottomToolbar(viewModel: editorViewModel)
                            .frame(height: navHeight)
                    }
                }

                // Sidebar
                if appState.showingSidebar {
                    Divider()
                    SidebarView()
                }
            }

            // Note Switcher overlay
            if appState.showingNoteSwitcher {
                noteSwitcherOverlay
            }
        }
        .frame(minWidth: 1100, minHeight: 600)
        .animation(.easeInOut(duration: 0.2), value: appState.showingSidebar)
        .preferredColorScheme(appState.colorScheme)
        .onAppear {
            setupGlobalShortcuts()
            setupFullscreenNotifications()
        }
    }

    // MARK: - Note Switcher Overlay

    @ViewBuilder
    private var noteSwitcherOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    appState.showingNoteSwitcher = false
                }

            // Switcher panel
            NoteSwitcherView()
        }
    }

    // MARK: - Global Shortcuts

    private func setupGlobalShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Cmd+O - Note Switcher
            if event.modifierFlags.contains(.command) && event.keyCode == 31 { // O
                appState.showingNoteSwitcher.toggle()
                return nil
            }

            // Cmd+N - New Note
            if event.modifierFlags.contains(.command) && event.keyCode == 45 { // N
                editorViewModel.createNewNote()
                return nil
            }

            // Escape - Close overlays
            if event.keyCode == 53 { // Escape
                if appState.showingNoteSwitcher {
                    appState.showingNoteSwitcher = false
                    return nil
                }
            }

            return event
        }
    }

    // MARK: - Fullscreen Notifications

    private func setupFullscreenNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.willEnterFullScreenNotification,
            object: nil,
            queue: .main
        ) { _ in
            appState.isFullscreen = true
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.willExitFullScreenNotification,
            object: nil,
            queue: .main
        ) { _ in
            appState.isFullscreen = false
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState.shared)
}
