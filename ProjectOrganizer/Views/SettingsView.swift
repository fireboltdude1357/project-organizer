//
//  SettingsView.swift
//  ProjectOrganizer
//

import SwiftUI

struct SettingsView: View {
    @Bindable var store: WorkstationStore
    @State private var selectedWorkstation: Workstation?
    @State private var isEditing = false

    var body: some View {
        HSplitView {
            // Sidebar - workstation list
            VStack(spacing: 0) {
                List(selection: $selectedWorkstation) {
                    ForEach(store.workstations) { workstation in
                        HStack {
                            Circle()
                                .fill(workstation.color)
                                .frame(width: 8, height: 8)
                            Text(workstation.name)
                        }
                        .tag(workstation)
                    }
                }
                .listStyle(.sidebar)

                Divider()

                HStack {
                    Button {
                        let newWorkstation = Workstation(
                            name: "New Workstation",
                            path: "~/Desktop",
                            colorHex: "#007AFF",
                            terminalTabs: [
                                TerminalTab(name: "Claude", command: "claude"),
                                TerminalTab(name: "Dev Server", command: nil),
                                TerminalTab(name: "Git", command: nil)
                            ],
                            cursorEnabled: true,
                            chromeURL: "http://localhost:3000",
                            simulatorEnabled: false,
                            simulatorDevice: "iPhone 16",
                            spaceNumber: nil
                        )
                        store.add(newWorkstation)
                        selectedWorkstation = newWorkstation
                        isEditing = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)

                    Button {
                        if let workstation = selectedWorkstation {
                            store.delete(workstation)
                            selectedWorkstation = store.workstations.first
                        }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedWorkstation == nil)

                    Spacer()
                }
                .padding(8)
            }
            .frame(minWidth: 200, maxWidth: 250)

            // Detail view
            if let workstation = selectedWorkstation,
               let index = store.workstations.firstIndex(where: { $0.id == workstation.id }) {
                WorkstationEditor(workstation: $store.workstations[index])
                    .frame(minWidth: 400)
            } else {
                ContentUnavailableView(
                    "No Workstation Selected",
                    systemImage: "square.stack.3d.up",
                    description: Text("Select a workstation or create a new one")
                )
                .frame(minWidth: 400)
            }
        }
        .frame(minWidth: 650, minHeight: 450)
    }
}

struct WorkstationEditor: View {
    @Binding var workstation: Workstation

    private let colorOptions: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Red", "#FF3B30"),
        ("Orange", "#FF9500"),
        ("Yellow", "#FFCC00"),
        ("Green", "#34C759"),
        ("Teal", "#5AC8FA")
    ]

    var body: some View {
        Form {
            Section("General") {
                LabeledContent("Name") {
                    TextField("Workstation name", text: $workstation.name)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledContent("Path") {
                    HStack {
                        Text(workstation.path)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK, let url = panel.url {
                                workstation.path = url.path
                            }
                        }
                    }
                }

                LabeledContent("Color") {
                    Picker("", selection: $workstation.colorHex) {
                        ForEach(colorOptions, id: \.hex) { option in
                            HStack {
                                Circle()
                                    .fill(Color(hex: option.hex) ?? .blue)
                                    .frame(width: 12, height: 12)
                                Text(option.name)
                            }
                            .tag(option.hex)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }

            Section("Terminal Tabs") {
                ForEach($workstation.terminalTabs) { $tab in
                    HStack(spacing: 12) {
                        TextField("Name", text: $tab.name)
                            .frame(width: 120)

                        Text("→")
                            .foregroundStyle(.secondary)

                        TextField("Command to run (optional)", text: Binding(
                            get: { tab.command ?? "" },
                            set: { tab.command = $0.isEmpty ? nil : $0 }
                        ))
                    }
                }

                HStack {
                    Button {
                        workstation.terminalTabs.append(
                            TerminalTab(name: "New Tab", command: nil)
                        )
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)

                    if workstation.terminalTabs.count > 1 {
                        Button {
                            workstation.terminalTabs.removeLast()
                        } label: {
                            Image(systemName: "minus")
                        }
                        .buttonStyle(.borderless)
                    }

                    Spacer()
                }
            }

            Section("Apps") {
                Toggle("Open in Cursor", isOn: $workstation.cursorEnabled)

                LabeledContent("Chrome URL") {
                    TextField("http://localhost:3000", text: Binding(
                        get: { workstation.chromeURL ?? "" },
                        set: { workstation.chromeURL = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }

                Toggle("Launch iOS Simulator", isOn: $workstation.simulatorEnabled)

                if workstation.simulatorEnabled {
                    LabeledContent("Device") {
                        TextField("iPhone 16", text: $workstation.simulatorDevice)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            Section("Desktop Space") {
                LabeledContent("Space") {
                    Picker("", selection: Binding(
                        get: { workstation.spaceNumber ?? 0 },
                        set: { workstation.spaceNumber = $0 == 0 ? nil : $0 }
                    )) {
                        Text("Current Space").tag(0)
                        ForEach(1...9, id: \.self) { num in
                            Text("Desktop \(num)").tag(num)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }

                Text("Tip: Create Spaces in Mission Control first (swipe up, click +)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    SettingsView(store: {
        let store = WorkstationStore()
        store.workstations = [Workstation.example]
        return store
    }())
}
