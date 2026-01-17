//
//  Workstation.swift
//  ProjectOrganizer
//

import SwiftUI

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
        spaceNumber: 2
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
