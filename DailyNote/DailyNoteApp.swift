// DailyNoteApp.swift
// Main entry point for DailyNote macOS app

import SwiftUI

@main
struct DailyNoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
