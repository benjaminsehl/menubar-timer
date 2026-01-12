import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var preferencesManager: PreferencesManager

    @State private var customMinutes: String = ""

    var body: some View {
        VStack(spacing: 0) {
            if let activeTimer = timerManager.activeTimer {
                ActiveTimerView(timer: activeTimer)
                    .environmentObject(timerManager)
                    .padding(.bottom, 12)

                Divider()
                    .padding(.bottom, 12)
            }

            QuickTimersSection(customMinutes: $customMinutes)
                .environmentObject(timerManager)
                .environmentObject(preferencesManager)

            Divider()
                .padding(.vertical, 12)

            SavedTimersSection()
                .environmentObject(timerManager)
                .environmentObject(preferencesManager)

            Divider()
                .padding(.vertical, 12)

            // Bottom actions
            HStack(spacing: 12) {
                Button("New Timer...") {
                    WindowManager.shared.openNewTimerWindow(preferencesManager: preferencesManager)
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)

                Spacer()

                SettingsLink {
                    Text("Preferences")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .font(.system(size: 11))
        }
        .padding(16)
        .frame(width: 280)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
        }
    }
}

// MARK: - Stage Dots View

struct StageDotsView: View {
    let totalStages: Int
    let currentStage: Int
    let currentRepetition: Int
    let totalRepetitions: Int?

    var body: some View {
        HStack(spacing: 6) {
            // Stage dots
            ForEach(0..<totalStages, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 6, height: 6)
            }

            // Repetition indicator
            if let total = totalRepetitions, total > 1 {
                Text("·")
                    .foregroundColor(.secondary)
                Text("\(currentRepetition)/\(total)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            } else if totalRepetitions == nil {
                Text("·")
                    .foregroundColor(.secondary)
                Image(systemName: "repeat")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index < currentStage {
            return Color.accentColor.opacity(0.4)
        } else if index == currentStage {
            return Color.accentColor
        } else {
            return Color.primary.opacity(0.15)
        }
    }
}

// MARK: - Active Timer View

struct ActiveTimerView: View {
    @ObservedObject var timer: ActiveTimer
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 12) {
            // Stage dots (only for multi-stage timers)
            if timer.stages.count > 1 || timer.isRepeating {
                StageDotsView(
                    totalStages: timer.stages.count,
                    currentStage: timer.currentStageIndex,
                    currentRepetition: timer.currentRepetition,
                    totalRepetitions: timer.repeatCount
                )
            }

            // Circular progress with time
            ZStack {
                CircularProgressView(progress: timer.progress)
                    .frame(width: 120, height: 120)

                VStack(spacing: 2) {
                    Text(timer.formattedTimeRemaining)
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .monospacedDigit()

                    if let label = timer.currentStage?.label {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Controls
            HStack(spacing: 24) {
                Button(action: { timerManager.stopCurrentTimer() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Stop")

                Button(action: {
                    if timer.isPaused {
                        timerManager.resumeTimer()
                    } else {
                        timerManager.pauseTimer()
                    }
                }) {
                    Image(systemName: timer.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(timer.isPaused ? "Resume" : "Pause")

                if timer.stages.count > 1 || timer.isRepeating {
                    Button(action: { timerManager.skipStage() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Skip")
                } else {
                    // Placeholder for alignment
                    Color.clear.frame(width: 32, height: 32)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Timers Section

struct QuickTimersSection: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var preferencesManager: PreferencesManager

    @Binding var customMinutes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK TIMER")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            // Preset buttons
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 52), spacing: 8)
            ], spacing: 8) {
                ForEach(preferencesManager.quickTimerMinutes, id: \.self) { minutes in
                    QuickTimerButton(minutes: minutes) {
                        timerManager.startOneOffTimer(
                            minutes: minutes,
                            alertSettings: preferencesManager.alertSettings
                        )
                    }
                }
            }

            // Custom input
            HStack(spacing: 8) {
                TextField("", text: $customMinutes, prompt: Text("Min"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .frame(width: 50)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(6)
                    .onSubmit { startCustomTimer() }

                Button(action: startCustomTimer) {
                    Text("Start")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(Int(customMinutes) == nil || (Int(customMinutes) ?? 0) <= 0)
            }
        }
    }

    private func startCustomTimer() {
        guard let minutes = Int(customMinutes), minutes > 0 else { return }
        timerManager.startOneOffTimer(
            minutes: minutes,
            alertSettings: preferencesManager.alertSettings
        )
        customMinutes = ""
    }
}

struct QuickTimerButton: View {
    let minutes: Int
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text("\(minutes)m")
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isHovering ? Color.primary.opacity(0.1) : Color.primary.opacity(0.06))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Saved Timers Section

struct SavedTimersSection: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var preferencesManager: PreferencesManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SAVED TIMERS")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            if preferencesManager.savedTimers.isEmpty {
                Text("No saved timers")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(preferencesManager.savedTimers) { timer in
                        SavedTimerRow(
                            timer: timer,
                            onStart: {
                                timerManager.startSavedTimer(
                                    timer,
                                    alertSettings: preferencesManager.alertSettings
                                )
                            },
                            onEdit: {
                                WindowManager.shared.openEditTimerWindow(
                                    timer: timer,
                                    preferencesManager: preferencesManager
                                )
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Saved Timer Row

struct SavedTimerRow: View {
    let timer: SavedTimer
    let onStart: () -> Void
    let onEdit: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Timer info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(timer.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    if timer.isRepeating {
                        Image(systemName: "repeat")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }

                Text(timerDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Actions
            HStack(spacing: 8) {
                if isHovering {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                Button(action: onStart) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(isHovering ? Color.primary.opacity(0.04) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private var timerDescription: String {
        if timer.stages.count == 1 {
            return timer.formattedTotalDuration
        } else {
            let stageDesc = timer.stages.map { stage in
                stage.label ?? stage.formattedDuration
            }.joined(separator: " → ")

            if timer.isRepeating, let count = timer.repeatCount {
                return "\(stageDesc) ×\(count)"
            }
            return stageDesc
        }
    }
}
