//
//  FlowstateApp.swift
//  Flowstate
//
//  Main application entry point
//

import SwiftUI

@main
struct FlowstateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    init() {
        // Register Lato font
        if let fontURL = Bundle.main.url(forResource: "Lato-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }

        // Check for migration from file system
        let migrationService = MigrationService()
        if migrationService.needsMigration() {
            Task {
                do {
                    let count = try await migrationService.migrateFromFileSystem()
                    print("Migrated \(count) notes from file system")
                } catch {
                    print("Migration error: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .toolbar(.hidden, for: .windowToolbar)
                .preferredColorScheme(appState.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 600)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    appState.createNewNote()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Quick Open") {
                    appState.showingNoteSwitcher = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            // Ensure window starts in windowed mode
            if window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }

            // Center the window on the screen
            window.center()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save any pending changes before quitting
        AppState.shared.saveCurrentNote()
    }
}
