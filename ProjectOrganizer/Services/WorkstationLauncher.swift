//
//  WorkstationLauncher.swift
//  ProjectOrganizer
//

import Foundation
import Carbon.HIToolbox
import AppKit

class WorkstationLauncher {

    static func launch(_ workstation: Workstation, spaceNumber: Int? = nil) {
        // Run on background thread to not block UI, but AppleScript calls will sync to main
        DispatchQueue.global(qos: .userInitiated).async {
            // If a space is specified, switch to it first
            if let space = spaceNumber {
                switchToSpace(space)
                // Give macOS time to complete the space switch
                Thread.sleep(forTimeInterval: 0.5)
            }

            // Launch apps sequentially with delays to prevent space-switching race conditions
            launchiTerm(workstation)
            Thread.sleep(forTimeInterval: 0.3)

            if let url = workstation.chromeURL, !url.isEmpty {
                launchChrome(url)
                Thread.sleep(forTimeInterval: 0.3)
            }

            if workstation.cursorEnabled {
                launchCursor(workstation.path)
                Thread.sleep(forTimeInterval: 0.5)
            }

            if workstation.simulatorEnabled {
                launchSimulator(workstation.simulatorDevice)
                Thread.sleep(forTimeInterval: 0.3)
            }

            // Final switch back to target space in case any app pulled focus elsewhere
            if let space = spaceNumber {
                Thread.sleep(forTimeInterval: 0.5)
                switchToSpace(space)
            }
        }
    }

    // MARK: - Space Management

    static func switchToSpace(_ number: Int) {
        // Use keyboard shortcut Ctrl+Number to switch spaces
        // This requires "Keyboard Shortcuts > Mission Control > Switch to Desktop X" to be enabled
        let script = """
        tell application "System Events"
            key code \(17 + number) using control down
        end tell
        """
        runAppleScript(script)
    }

    static func createNewSpace() {
        // Opens Mission Control and clicks the + button to add a space
        let script = """
        tell application "System Events"
            -- Open Mission Control
            key code 160
            delay 0.5

            -- Find and click the "add desktop" button
            tell process "Dock"
                set addButton to button 1 of group 2 of group 1 of group 1
                click addButton
            end tell

            delay 0.3

            -- Close Mission Control
            key code 53
        end tell
        """
        runAppleScript(script)
    }

    static func getSpaceCount() -> Int {
        // This is tricky - we'll estimate based on what shortcuts work
        // For now, return a default
        return 4
    }

    private static func launchiTerm(_ workstation: Workstation) {
        let tabScripts = workstation.terminalTabs.enumerated().map { index, tab in
            if index == 0 {
                // First tab uses the current session
                return """
                        tell current session
                            set name to "\(tab.name)"
                            write text "cd \(escapePath(workstation.path))"
                            \(tab.command.map { "write text \"\($0)\"" } ?? "")
                        end tell
                """
            } else {
                // Additional tabs
                return """
                        set newTab to (create tab with default profile)
                        tell current session of newTab
                            set name to "\(tab.name)"
                            write text "cd \(escapePath(workstation.path))"
                            \(tab.command.map { "write text \"\($0)\"" } ?? "")
                        end tell
                """
            }
        }.joined(separator: "\n")

        // Launch iTerm without activate to keep it on current space
        // First ensure iTerm is running, then create window
        let script = """
        tell application "iTerm"
            set newWindow to (create window with default profile)
            tell newWindow
        \(tabScripts)
            end tell
        end tell
        """

        runAppleScript(script)
    }

    private static func launchCursor(_ path: String) {
        // Use open with --args to pass --new-window flag to Cursor
        let expandedPath = expandPath(path)
        let escapedPath = expandedPath.replacingOccurrences(of: "'", with: "'\\''")
        let script = """
        do shell script "open -na 'Cursor' --args --new-window '\(escapedPath)'"
        """
        runAppleScript(script)
    }

    private static func launchChrome(_ url: String) {
        // Use open command with --new-window to create window on current space
        // without activating existing Chrome windows
        let script = """
        do shell script "open -na 'Google Chrome' --args --new-window '\(url)'"
        """
        runAppleScript(script)
    }

    private static func launchSimulator(_ device: String) {
        // Use -g to open without bringing to foreground (stays on current space)
        let script = """
        do shell script "open -g -a Simulator"
        delay 1
        do shell script "xcrun simctl boot '\(device)' 2>/dev/null || true"
        """
        runAppleScript(script)
    }

    private static func expandPath(_ path: String) -> String {
        // Expand ~ to home directory
        if path.hasPrefix("~") {
            return (path as NSString).expandingTildeInPath
        }
        return path
    }

    private static func escapePath(_ path: String) -> String {
        // Expand tilde and escape for shell/AppleScript
        let expanded = expandPath(path)
        return "'" + expanded.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    @discardableResult
    private static func runAppleScript(_ source: String) -> Bool {
        // Run on main thread to allow authorization dialogs to appear
        var success = false
        let execute = {
            if let script = NSAppleScript(source: source) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                if let error = error {
                    print("AppleScript error: \(error)")
                } else {
                    success = true
                }
            }
        }

        if Thread.isMainThread {
            execute()
        } else {
            DispatchQueue.main.sync {
                execute()
            }
        }
        return success
    }
}
