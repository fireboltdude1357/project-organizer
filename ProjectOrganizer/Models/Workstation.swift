//
//  Workstation.swift
//  ProjectOrganizer
//

import SwiftUI
import AppKit

struct KeyboardShortcut: Codable, Hashable {
    var keyCode: UInt16
    var modifiers: UInt  // NSEvent.ModifierFlags raw value

    var displayString: String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)

        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }

        // Map key code to character
        if let keyString = KeyboardShortcut.keyCodeToString(keyCode) {
            parts.append(keyString)
        }

        return parts.joined()
    }

    static func keyCodeToString(_ keyCode: UInt16) -> String? {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            36: "↩", 48: "⇥", 51: "⌫", 53: "⎋",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        return keyMap[keyCode]
    }
}

struct Workstation: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var path: String
    var colorHex: String
    var terminalTabs: [TerminalTab]
    var cursorEnabled: Bool
    var chromeURL: String?
    var simulatorEnabled: Bool
    var simulatorDevice: String
    var spaceNumber: Int?  // Which Space/Desktop to use (nil = current space)
    var hotkey: KeyboardShortcut?  // Global hotkey to activate this workstation

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    static let example = Workstation(
        name: "My App",
        path: "/Users/tannersharon/Desktop/Personal/my-app",
        colorHex: "#007AFF",
        terminalTabs: [
            TerminalTab(name: "Claude", command: "claude"),
            TerminalTab(name: "Expo", command: "npx expo start"),
            TerminalTab(name: "Convex", command: "npx convex dev"),
            TerminalTab(name: "Git", command: nil)
        ],
        cursorEnabled: true,
        chromeURL: "http://localhost:3000",
        simulatorEnabled: true,
        simulatorDevice: "iPhone 16",
        spaceNumber: 2,
        hotkey: nil
    )
}

struct TerminalTab: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var command: String?
}

// Color hex extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#007AFF"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
