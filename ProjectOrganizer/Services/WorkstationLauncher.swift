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
            // Helper to ensure we stay on target space
            let ensureSpace = {
                if let space = spaceNumber {
                    Thread.sleep(forTimeInterval: 0.3)
                    switchToSpace(space)
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }

            // Switch to target space first
            if let space = spaceNumber {
                print("Switching to space \(space) before launch...")
                switchToSpace(space)
                Thread.sleep(forTimeInterval: 1.0)
            }

            // Launch apps sequentially, switching back to target space after each
            // because some apps pull focus to their previously-used space
            print("Launching iTerm...")
            launchiTerm(workstation)
            ensureSpace()

            if let url = workstation.chromeURL, !url.isEmpty {
                print("Launching Chrome...")
                launchChrome(url)
                ensureSpace()
            }

            if workstation.cursorEnabled {
                print("Launching Cursor...")
                launchCursor(workstation.path)
                ensureSpace()
            }

            if workstation.simulatorEnabled {
                print("Launching Simulator...")
                launchSimulator(workstation.simulatorDevice)
                ensureSpace()
            }

            // Final switch to ensure we end on target space
            if let space = spaceNumber {
                Thread.sleep(forTimeInterval: 0.5)
                switchToSpace(space)
            }
        }
    }

    // MARK: - Space Management

    static func switchToSpace(_ number: Int) {
        // Key codes for number keys (they're not sequential on Mac keyboards!)
        let keyCodeMap: [Int: CGKeyCode] = [
            1: 18, 2: 19, 3: 20, 4: 21, 5: 23,
            6: 22, 7: 26, 8: 28, 9: 25
        ]

        guard let keyCode = keyCodeMap[number] else {
            print("Invalid space number: \(number)")
            return
        }

        print("switchToSpace called with number: \(number), keyCode: \(keyCode)")

        // Use CGEvent to post keyboard events directly - more reliable than AppleScript
        let source = CGEventSource(stateID: .hidSystemState)

        // Create key down event with Control modifier
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) else {
            print("Failed to create keyDown event")
            return
        }
        keyDown.flags = .maskControl

        // Create key up event
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            print("Failed to create keyUp event")
            return
        }
        keyUp.flags = .maskControl

        // Post the events
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        print("switchToSpace CGEvent posted")
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
