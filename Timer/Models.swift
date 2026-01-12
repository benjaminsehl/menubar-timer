import Foundation

// MARK: - Alert Settings

struct AlertSettings: Codable, Equatable, Hashable {
    var playSound: Bool = true
    var showNotification: Bool = true
    var soundName: String = "Glass"

    static let `default` = AlertSettings()

    static let availableSounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
    ]
}

// MARK: - Timer Stage

struct TimerStage: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var duration: TimeInterval // in seconds
    var label: String?

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if seconds == 0 {
            return "\(minutes)m"
        }
        return "\(minutes)m \(seconds)s"
    }
}

// MARK: - Saved Timer

struct SavedTimer: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var stages: [TimerStage]
    var isRepeating: Bool = false
    var repeatCount: Int? = nil // nil means infinite
    var alertSettings: AlertSettings?

    func effectiveAlertSettings(defaultSettings: AlertSettings) -> AlertSettings {
        alertSettings ?? defaultSettings
    }

    var totalDuration: TimeInterval {
        stages.reduce(0) { $0 + $1.duration }
    }

    var formattedTotalDuration: String {
        let total = Int(totalDuration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    static var pomodoro: SavedTimer {
        SavedTimer(
            name: "Pomodoro",
            stages: [
                TimerStage(duration: 25 * 60, label: "Work"),
                TimerStage(duration: 5 * 60, label: "Break")
            ],
            isRepeating: true,
            repeatCount: 4
        )
    }
}

// MARK: - Active Timer

class ActiveTimer: ObservableObject, Identifiable {
    let id = UUID()
    @Published var timeRemaining: TimeInterval
    @Published var isPaused: Bool = false
    @Published var currentStageIndex: Int = 0
    @Published var currentRepetition: Int = 1

    let savedTimer: SavedTimer?
    let stages: [TimerStage]
    let isRepeating: Bool
    let repeatCount: Int?
    let alertSettings: AlertSettings

    private var timer: Timer?
    // Parameters: completedStage, nextStage (nil if none), isLastStageInCycle
    var onStageComplete: ((TimerStage, TimerStage?, Bool) -> Void)?
    var onTimerComplete: (() -> Void)?

    init(duration: TimeInterval, alertSettings: AlertSettings) {
        self.timeRemaining = duration
        self.savedTimer = nil
        self.stages = [TimerStage(duration: duration)]
        self.isRepeating = false
        self.repeatCount = nil
        self.alertSettings = alertSettings
    }

    init(savedTimer: SavedTimer, alertSettings: AlertSettings) {
        self.savedTimer = savedTimer
        self.stages = savedTimer.stages
        self.isRepeating = savedTimer.isRepeating
        self.repeatCount = savedTimer.repeatCount
        self.timeRemaining = savedTimer.stages.first?.duration ?? 0
        self.alertSettings = alertSettings
    }

    var currentStage: TimerStage? {
        guard currentStageIndex < stages.count else { return nil }
        return stages[currentStageIndex]
    }

    var formattedTimeRemaining: String {
        let total = Int(timeRemaining)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard let stage = currentStage else { return 0 }
        return 1 - (timeRemaining / stage.duration)
    }

    var statusText: String {
        var parts: [String] = []

        if let name = savedTimer?.name {
            parts.append(name)
        }

        if let label = currentStage?.label {
            parts.append(label)
        }

        if stages.count > 1 {
            parts.append("Stage \(currentStageIndex + 1)/\(stages.count)")
        }

        if isRepeating {
            if let count = repeatCount {
                parts.append("Rep \(currentRepetition)/\(count)")
            } else {
                parts.append("Rep \(currentRepetition)")
            }
        }

        return parts.joined(separator: " • ")
    }

    func start() {
        isPaused = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        start()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func skipStage() {
        advanceToNextStage()
    }

    private func tick() {
        guard !isPaused else { return }

        timeRemaining -= 0.1

        if timeRemaining <= 0 {
            advanceToNextStage()
        }
    }

    private func advanceToNextStage() {
        let completedStage = currentStage

        if currentStageIndex < stages.count - 1 {
            // Move to next stage
            currentStageIndex += 1
            timeRemaining = stages[currentStageIndex].duration
            let nextStage = stages[currentStageIndex]
            if let stage = completedStage {
                onStageComplete?(stage, nextStage, false)
            }
        } else if isRepeating {
            // Check if we should repeat
            let shouldRepeat: Bool
            if let count = repeatCount {
                shouldRepeat = currentRepetition < count
            } else {
                shouldRepeat = true
            }

            if shouldRepeat {
                currentRepetition += 1
                currentStageIndex = 0
                timeRemaining = stages[0].duration
                let nextStage = stages[0]
                if let stage = completedStage {
                    onStageComplete?(stage, nextStage, true)
                }
            } else {
                // All repetitions complete - only call onTimerComplete (not stage complete)
                stop()
                onTimerComplete?()
            }
        } else {
            // Timer complete (single run, no repeat) - only call onTimerComplete
            stop()
            onTimerComplete?()
        }
    }
}
