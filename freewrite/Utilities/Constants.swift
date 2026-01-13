//
//  Constants.swift
//  Flowstate
//
//  App-wide constants
//

import Foundation

enum Constants {
    // MARK: - App Info
    static let appName = "Flowstate"
    static let bundleIdentifier = "app.humansongs.flowstate"

    // MARK: - Database
    static let databaseName = "flowstate.sqlite"

    // MARK: - UI
    static let defaultWindowWidth: CGFloat = 1100
    static let defaultWindowHeight: CGFloat = 600
    static let maxEditorWidth: CGFloat = 650
    static let sidebarWidth: CGFloat = 200
    static let bottomNavHeight: CGFloat = 68

    // MARK: - Editor
    static let defaultFontSize: CGFloat = 18
    static let minFontSize: CGFloat = 14
    static let maxFontSize: CGFloat = 26
    static let defaultFont = "Lato-Regular"

    // MARK: - Timer
    static let defaultTimerDuration: Int = 900 // 15 minutes in seconds
    static let maxTimerDuration: Int = 2700 // 45 minutes

    // MARK: - Auto-Save
    static let autoSaveDelay: UInt64 = 3_000_000_000 // 3 seconds in nanoseconds

    // MARK: - Search
    static let maxSearchResults = 50
    static let recentNotesLimit = 20

    // MARK: - File Paths
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var freewriteDirectory: URL {
        documentsDirectory.appendingPathComponent("Freewrite")
    }

    static var applicationSupportDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Flowstate")
    }

    static var databasePath: URL {
        applicationSupportDirectory.appendingPathComponent(databaseName)
    }
}
