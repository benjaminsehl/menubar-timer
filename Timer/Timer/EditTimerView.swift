import SwiftUI
import AppKit

enum EditTimerMode: Equatable {
    case create
    case edit(SavedTimer)

    var title: String {
        switch self {
        case .create: return "New Timer"
        case .edit: return "Edit Timer"
        }
    }
}

struct EditTimerView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager

    let mode: EditTimerMode
    let onDismiss: () -> Void

    @State private var name: String = ""
    @State private var stages: [TimerStage] = [TimerStage(duration: 300)]
    @State private var isRepeating: Bool = false
    @State private var repeatCount: Int = 4
    @State private var repeatForever: Bool = false
    @State private var useCustomAlerts: Bool = false
    @State private var alertSettings: AlertSettings = .default

    init(mode: EditTimerMode, onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.onDismiss = onDismiss

        if case .edit(let timer) = mode {
            _name = State(initialValue: timer.name)
            _stages = State(initialValue: timer.stages)
            _isRepeating = State(initialValue: timer.isRepeating)
            _repeatCount = State(initialValue: timer.repeatCount ?? 4)
            _repeatForever = State(initialValue: timer.repeatCount == nil && timer.isRepeating)
            _useCustomAlerts = State(initialValue: timer.alertSettings != nil)
            _alertSettings = State(initialValue: timer.alertSettings ?? .default)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content
            Form {
                Section {
                    TextField("Timer Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Stages") {
                    ForEach($stages) { $stage in
                        StageEditor(stage: $stage, onDelete: stages.count > 1 ? {
                            stages.removeAll { $0.id == stage.id }
                        } : nil)
                    }

                    Button(action: addStage) {
                        Label("Add Stage", systemImage: "plus")
                    }
                }

                Section("Repeat") {
                    Toggle("Repeat Timer", isOn: $isRepeating)

                    if isRepeating {
                        Toggle("Repeat Forever", isOn: $repeatForever)

                        if !repeatForever {
                            Stepper("Repeat \(repeatCount) times", value: $repeatCount, in: 1...100)
                        }
                    }
                }

                Section("Alerts") {
                    Toggle("Use Custom Alert Settings", isOn: $useCustomAlerts)

                    if useCustomAlerts {
                        AlertSettingsEditor(settings: $alertSettings)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer
            HStack {
                if case .edit(let timer) = mode {
                    Button("Delete") {
                        preferencesManager.deleteSavedTimer(timer)
                        onDismiss()
                    }
                    .foregroundColor(.red)
                }

                Spacer()

                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    saveTimer()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || stages.isEmpty || stages.allSatisfy { $0.duration == 0 })
            }
            .padding()
        }
        .frame(width: 420, height: 480)
    }

    private func addStage() {
        stages.append(TimerStage(duration: 300))
    }

    private func saveTimer() {
        let timer = SavedTimer(
            id: {
                if case .edit(let existing) = mode {
                    return existing.id
                }
                return UUID()
            }(),
            name: name,
            stages: stages,
            isRepeating: isRepeating,
            repeatCount: isRepeating && !repeatForever ? repeatCount : nil,
            alertSettings: useCustomAlerts ? alertSettings : nil
        )

        switch mode {
        case .create:
            preferencesManager.addSavedTimer(timer)
        case .edit:
            preferencesManager.updateSavedTimer(timer)
        }

        onDismiss()
    }
}

// MARK: - Stage Editor

struct StageEditor: View {
    @Binding var stage: TimerStage
    let onDelete: (() -> Void)?

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    init(stage: Binding<TimerStage>, onDelete: (() -> Void)?) {
        self._stage = stage
        self.onDelete = onDelete
        let total = Int(stage.wrappedValue.duration)
        self._minutes = State(initialValue: total / 60)
        self._seconds = State(initialValue: total % 60)
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("Label (optional)", text: Binding(
                get: { stage.label ?? "" },
                set: { stage.label = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 100, maxWidth: 140)

            Spacer()

            HStack(spacing: 4) {
                Text("\(minutes)")
                    .frame(width: 30, alignment: .trailing)
                    .monospacedDigit()
                Text("m")
                    .foregroundColor(.secondary)
                Stepper("", value: $minutes, in: 0...999)
                    .labelsHidden()
                    .onChange(of: minutes) { _, _ in updateDuration() }
            }

            HStack(spacing: 4) {
                Text("\(seconds)")
                    .frame(width: 20, alignment: .trailing)
                    .monospacedDigit()
                Text("s")
                    .foregroundColor(.secondary)
                Stepper("", value: $seconds, in: 0...59)
                    .labelsHidden()
                    .onChange(of: seconds) { _, _ in updateDuration() }
            }

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            } else {
                // Placeholder for alignment
                Color.clear.frame(width: 20)
            }
        }
    }

    private func updateDuration() {
        stage.duration = TimeInterval(minutes * 60 + seconds)
    }
}

// MARK: - Alert Settings Editor

struct AlertSettingsEditor: View {
    @Binding var settings: AlertSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Play Sound", isOn: $settings.playSound)

            if settings.playSound {
                HStack {
                    Picker("Sound", selection: $settings.soundName) {
                        ForEach(AlertSettings.availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)

                    Button("Preview") {
                        NSSound(named: NSSound.Name(settings.soundName))?.play()
                    }
                }
            }

            Toggle("Show Notification", isOn: $settings.showNotification)
        }
    }
}
