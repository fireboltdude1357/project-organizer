//
//  ProjectOrganizerApp.swift
//  ProjectOrganizer
//

import SwiftUI

@main
struct ProjectOrganizerApp: App {
    @State private var store = WorkstationStore()

    var body: some Scene {
        // Menu bar app
        MenuBarExtra("Projects", systemImage: "folder.fill") {
            MenuBarView(store: store)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView(store: store)
        }
    }
}
