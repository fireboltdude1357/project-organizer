//
//  WorkstationStore.swift
//  ProjectOrganizer
//

import SwiftUI

@Observable
class WorkstationStore {
    private var isLoading = false

    var workstations: [Workstation] = [] {
        didSet {
            if !isLoading {
                save()
                onWorkstationsChanged?()
            }
        }
    }
    var activeWorkstationId: UUID?
    var onWorkstationsChanged: (() -> Void)?

    // Track which workstations have been launched this session
    private(set) var launchedWorkstationIds: Set<UUID> = []

    func markLaunched(_ workstation: Workstation) {
        launchedWorkstationIds.insert(workstation.id)
    }

    func isLaunched(_ workstation: Workstation) -> Bool {
        launchedWorkstationIds.contains(workstation.id)
    }

    func markClosed(_ workstation: Workstation) {
        launchedWorkstationIds.remove(workstation.id)
    }

    private static var saveFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ProjectOrganizer", isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        return appFolder.appendingPathComponent("workstations.json")
    }

    init() {
        load()
    }

    func add(_ workstation: Workstation) {
        workstations.append(workstation)
        // save() called automatically via didSet
    }

    func update(_ workstation: Workstation) {
        if let index = workstations.firstIndex(where: { $0.id == workstation.id }) {
            workstations[index] = workstation
            // save() called automatically via didSet
        }
    }

    func delete(_ workstation: Workstation) {
        workstations.removeAll { $0.id == workstation.id }
        if activeWorkstationId == workstation.id {
            activeWorkstationId = nil
        }
        // save() called automatically via didSet
    }

    func setActive(_ workstation: Workstation?) {
        activeWorkstationId = workstation?.id
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(workstations)
            try data.write(to: Self.saveFileURL, options: .atomic)
        } catch {
            print("Failed to save workstations: \(error)")
        }
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try Data(contentsOf: Self.saveFileURL)
            workstations = try JSONDecoder().decode([Workstation].self, from: data)
        } catch {
            // File doesn't exist yet or failed to decode - start with empty list
            workstations = []
        }
    }
}
