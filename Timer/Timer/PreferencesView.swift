import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        TabView {
            GeneralPreferencesTab()
                .environmentObject(preferencesManager)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AlertPreferencesTab()
                .environmentObject(preferencesManager)
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }

            SavedTimersPreferencesTab()
                .environmentObject(preferencesManager)
                .environmentObject(timerManager)
                .tabItem {
                    Label("Saved Timers", systemImage: "timer")
                }
        }
        .frame(width: 450, height: 350)
    }
}

// MARK: - General Preferences

struct GeneralPreferencesTab: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @State private var newMinutes: String = ""

    var body: some View {
        Form {
            Section("Quick Timer Presets") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configure the quick timer buttons shown in the menu")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Current presets
                    FlowLayout(spacing: 8) {
                        ForEach(preferencesManager.quickTimerMinutes, id: \.self) { minutes in
                            HStack(spacing: 4) {
                                Text("\(minutes)m")
                                Button(action: {
                                    preferencesManager.quickTimerMinutes.removeAll { $0 == minutes }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(6)
                        }
                    }

                    // Add new preset
                    HStack {
                        TextField("Minutes", text: $newMinutes)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit { addPreset() }

                        Button("Add") { addPreset() }
                            .disabled(Int(newMinutes) == nil)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func addPreset() {
        guard let minutes = Int(newMinutes), minutes > 0 else { return }
        if !preferencesManager.quickTimerMinutes.contains(minutes) {
            preferencesManager.quickTimerMinutes.append(minutes)
            preferencesManager.quickTimerMinutes.sort()
        }
        newMinutes = ""
    }
}

// MARK: - Alert Preferences

struct AlertPreferencesTab: View {
    @EnvironmentObject var preferencesManager: PreferencesManager

    var body: some View {
        Form {
            Section("Default Alert Settings") {
                Text("These settings are used unless a saved timer has custom settings")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Play Sound", isOn: $preferencesManager.alertSettings.playSound)

                if preferencesManager.alertSettings.playSound {
                    Picker("Sound", selection: $preferencesManager.alertSettings.soundName) {
                        ForEach(AlertSettings.availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }

                    Button("Preview Sound") {
                        NSSound(named: NSSound.Name(preferencesManager.alertSettings.soundName))?.play()
                    }
                }

                Toggle("Show Notification", isOn: $preferencesManager.alertSettings.showNotification)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Saved Timers Preferences

struct SavedTimersPreferencesTab: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @EnvironmentObject var timerManager: TimerManager

    @State private var selectedTimer: SavedTimer?

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedTimer) {
                ForEach(preferencesManager.savedTimers) { timer in
                    SavedTimerListRow(timer: timer)
                        .tag(timer)
                }
                .onDelete { offsets in
                    preferencesManager.deleteSavedTimer(at: offsets)
                }
            }
            .listStyle(.inset)

            Divider()

            HStack {
                Button(action: {
                    WindowManager.shared.openNewTimerWindow(preferencesManager: preferencesManager)
                }) {
                    Image(systemName: "plus")
                }

                Button(action: {
                    if let timer = selectedTimer {
                        WindowManager.shared.openEditTimerWindow(timer: timer, preferencesManager: preferencesManager)
                    }
                }) {
                    Image(systemName: "pencil")
                }
                .disabled(selectedTimer == nil)

                Button(action: {
                    if let timer = selectedTimer {
                        preferencesManager.deleteSavedTimer(timer)
                        selectedTimer = nil
                    }
                }) {
                    Image(systemName: "trash")
                }
                .disabled(selectedTimer == nil)

                Spacer()

                Button("Add Pomodoro") {
                    if !preferencesManager.savedTimers.contains(where: { $0.name == "Pomodoro" }) {
                        preferencesManager.addSavedTimer(.pomodoro)
                    }
                }
                .disabled(preferencesManager.savedTimers.contains(where: { $0.name == "Pomodoro" }))
            }
            .padding(8)
        }
    }
}

struct SavedTimerListRow: View {
    let timer: SavedTimer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(timer.name)
                    .fontWeight(.medium)

                if timer.isRepeating {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if timer.alertSettings != nil {
                    Image(systemName: "bell.badge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(stagesDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var stagesDescription: String {
        let stageDesc = timer.stages.map { stage in
            if let label = stage.label {
                return "\(label): \(stage.formattedDuration)"
            }
            return stage.formattedDuration
        }.joined(separator: " → ")

        if timer.isRepeating {
            if let count = timer.repeatCount {
                return "\(stageDesc) (×\(count))"
            }
            return "\(stageDesc) (∞)"
        }
        return stageDesc
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}
