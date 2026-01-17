//
//  MenuBarView.swift
//  ProjectOrganizer
//

import SwiftUI

struct MenuBarView: View {
    @Bindable var store: WorkstationStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Workstations")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if store.workstations.isEmpty {
                VStack(spacing: 8) {
                    Text("No workstations yet")
                        .foregroundStyle(.secondary)
                    Button("Add Workstation") {
                        openSettings()
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Workstation list
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(store.workstations) { workstation in
                            WorkstationRow(
                                workstation: workstation,
                                isActive: store.activeWorkstationId == workstation.id,
                                isLaunched: store.isLaunched(workstation),
                                onLaunch: {
                                    store.setActive(workstation)
                                    if store.isLaunched(workstation) {
                                        // Already launched - just switch to space
                                        if let spaceNumber = workstation.spaceNumber {
                                            WorkstationLauncher.switchToSpace(spaceNumber)
                                        }
                                    } else {
                                        // First launch
                                        WorkstationLauncher.launch(workstation, spaceNumber: workstation.spaceNumber)
                                        store.markLaunched(workstation)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Footer buttons
            HStack {
                Button {
                    openSettings()
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("Settings")

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }
}

struct WorkstationRow: View {
    let workstation: Workstation
    let isActive: Bool
    let isLaunched: Bool
    let onLaunch: () -> Void

    var body: some View {
        Button(action: onLaunch) {
            HStack(spacing: 10) {
                Circle()
                    .fill(workstation.color)
                    .frame(width: 10, height: 10)
                    .overlay {
                        if isLaunched {
                            Circle()
                                .stroke(workstation.color, lineWidth: 2)
                                .frame(width: 16, height: 16)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(workstation.name)
                        .fontWeight(isActive ? .semibold : .regular)

                    Text(workstation.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                if isLaunched {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .padding(.horizontal, 4)
    }
}

#Preview {
    MenuBarView(store: {
        let store = WorkstationStore()
        store.workstations = [Workstation.example]
        return store
    }())
}
