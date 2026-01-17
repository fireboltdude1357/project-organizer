//
//  HotkeyManager.swift
//  ProjectOrganizer
//
//  Note: Global hotkey functionality removed due to macOS compatibility issues.
//  Users can use macOS built-in Ctrl+1, Ctrl+2, etc. to switch spaces.
//

import AppKit
import Carbon

@Observable
class HotkeyManager {
    static let shared = HotkeyManager()

    var onHotkeyTriggered: ((UUID) -> Void)?

    private init() {}

    func start(with workstations: [Workstation]) {
        // Hotkey functionality disabled
    }

    func stop() {
        // Hotkey functionality disabled
    }

    func updateWorkstations(_ workstations: [Workstation]) {
        // Hotkey functionality disabled
    }
}

// Check if accessibility permissions are granted
extension HotkeyManager {
    static var hasAccessibilityPermissions: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
