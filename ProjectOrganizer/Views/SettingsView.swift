//
//  SettingsView.swift
//  ProjectOrganizer
//

import SwiftUI
import AppKit

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
                .frame(maxHeight: .infinity)

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
                            spaceNumber: nil,
                            hotkey: nil
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
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
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

                // Hotkey feature disabled due to macOS compatibility issues
                // LabeledContent("Hotkey") {
                //     HotkeyRecorderView(hotkey: $workstation.hotkey, workstationId: workstation.id)
                // }

                Text("Tip: Use Ctrl+1, Ctrl+2, etc. to switch between desktop spaces")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var hotkey: KeyboardShortcut?
    var workstationId: UUID  // Track which workstation this is for

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.delegate = context.coordinator
        view.currentHotkey = hotkey
        context.coordinator.hotkeyBinding = $hotkey
        context.coordinator.currentWorkstationId = workstationId
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        // Stop any active recording if we switched to a different workstation
        if context.coordinator.currentWorkstationId != workstationId {
            nsView.stopRecordingIfNeeded()
            context.coordinator.currentWorkstationId = workstationId
        }

        // Update the binding to point to the current workstation's hotkey
        context.coordinator.hotkeyBinding = $hotkey
        nsView.currentHotkey = hotkey
        nsView.updateDisplay()
    }

    class Coordinator: HotkeyRecorderDelegate {
        var hotkeyBinding: Binding<KeyboardShortcut?>?
        var currentWorkstationId: UUID?

        func hotkeyRecorded(_ shortcut: KeyboardShortcut?) {
            hotkeyBinding?.wrappedValue = shortcut
        }
    }
}

protocol HotkeyRecorderDelegate: AnyObject {
    func hotkeyRecorded(_ shortcut: KeyboardShortcut?)
}

extension HotkeyRecorderNSView {
    func stopRecordingIfNeeded() {
        if isRecording {
            stopRecording()
        }
    }
}

class HotkeyRecorderNSView: NSView {
    weak var delegate: HotkeyRecorderDelegate?
    var currentHotkey: KeyboardShortcut?

    fileprivate var isRecording = false
    private let button = NSButton()
    private let clearButton = NSButton()
    private var eventMonitor: Any?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        button.bezelStyle = .roundRect
        button.target = self
        button.action = #selector(buttonClicked)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear")
        clearButton.bezelStyle = .inline
        clearButton.isBordered = false
        clearButton.target = self
        clearButton.action = #selector(clearClicked)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.isHidden = true
        addSubview(clearButton)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),

            clearButton.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 4),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            heightAnchor.constraint(equalToConstant: 24)
        ])

        updateDisplay()
    }

    func updateDisplay() {
        if isRecording {
            button.title = "Press keys..."
            button.contentTintColor = .controlAccentColor
        } else if let hotkey = currentHotkey {
            button.title = hotkey.displayString
            button.contentTintColor = nil
        } else {
            button.title = "Click to record"
            button.contentTintColor = .secondaryLabelColor
        }
        clearButton.isHidden = currentHotkey == nil || isRecording
    }

    @objc private func buttonClicked() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    @objc private func clearClicked() {
        currentHotkey = nil
        delegate?.hotkeyRecorded(nil)
        updateDisplay()
    }

    private func startRecording() {
        isRecording = true
        updateDisplay()
        window?.makeFirstResponder(self)

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isRecording else { return event }

            // Escape cancels
            if event.keyCode == 53 {
                self.stopRecording()
                return nil
            }

            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift]).rawValue
            let flags = NSEvent.ModifierFlags(rawValue: modifiers)
            let hasModifier = flags.contains(.command) || flags.contains(.option) ||
                              flags.contains(.control) || flags.contains(.shift)

            if hasModifier {
                let shortcut = KeyboardShortcut(keyCode: event.keyCode, modifiers: modifiers)
                self.currentHotkey = shortcut
                self.delegate?.hotkeyRecorded(shortcut)
                self.stopRecording()
                return nil
            }

            return nil
        }
    }

    fileprivate func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        updateDisplay()
    }

    override var acceptsFirstResponder: Bool { true }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}


#Preview {
    SettingsView(store: {
        let store = WorkstationStore()
        store.workstations = [Workstation.example]
        return store
    }())
}
