//
//  ProjectOrganizerApp.swift
//  ProjectOrganizer
//

import SwiftUI

@main
struct ProjectOrganizerApp: App {
    @State private var store = WorkstationStore()
    private let hotkeyManager = HotkeyManager.shared

    init() {
        setupHotkeys()
    }

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

    private func setupHotkeys() {
        hotkeyManager.onHotkeyTriggered = { [self] workstationId in
            guard let workstation = store.workstations.first(where: { $0.id == workstationId }) else {
                print("Hotkey triggered but workstation not found: \(workstationId)")
                return
            }

            print("Hotkey triggered for: \(workstation.name), isLaunched: \(store.isLaunched(workstation)), spaceNumber: \(String(describing: workstation.spaceNumber))")

            if store.isLaunched(workstation) {
                // Already launched - just switch to the space
                if let spaceNumber = workstation.spaceNumber {
                    print("Switching to space \(spaceNumber)")
                    WorkstationLauncher.switchToSpace(spaceNumber)
                } else {
                    print("No space number assigned, cannot switch")
                }
            } else {
                // First time - do full launch
                print("First launch for \(workstation.name)")
                WorkstationLauncher.launch(workstation, spaceNumber: workstation.spaceNumber)
                store.markLaunched(workstation)
            }
        }

        // Update hotkeys whenever workstations change
        store.onWorkstationsChanged = { [self] in
            hotkeyManager.updateWorkstations(store.workstations)
        }

        // Start monitoring after a brief delay to ensure store is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            hotkeyManager.start(with: store.workstations)

            // Request accessibility permissions if not granted
            if !HotkeyManager.hasAccessibilityPermissions {
                HotkeyManager.requestAccessibilityPermissions()
            }
        }
    }
}
