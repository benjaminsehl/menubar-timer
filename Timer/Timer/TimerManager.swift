import Foundation
import UserNotifications
import AppKit
import Combine

class TimerManager: ObservableObject {
    @Published var activeTimer: ActiveTimer?
    @Published var recentTimers: [SavedTimer] = []

    private var cancellables = Set<AnyCancellable>()
    private let maxRecentTimers = 5

    init() {
        requestNotificationPermission()
    }

    // MARK: - Timer Control

    func startOneOffTimer(minutes: Int, alertSettings: AlertSettings) {
        stopCurrentTimer()

        let timer = ActiveTimer(duration: TimeInterval(minutes * 60), alertSettings: alertSettings)
        setupTimerCallbacks(timer)
        timer.start()
        activeTimer = timer
    }

    func startOneOffTimer(duration: TimeInterval, alertSettings: AlertSettings) {
        stopCurrentTimer()

        let timer = ActiveTimer(duration: duration, alertSettings: alertSettings)
        setupTimerCallbacks(timer)
        timer.start()
        activeTimer = timer
    }

    func startSavedTimer(_ savedTimer: SavedTimer, alertSettings: AlertSettings) {
        stopCurrentTimer()

        let effectiveSettings = savedTimer.effectiveAlertSettings(defaultSettings: alertSettings)
        let timer = ActiveTimer(savedTimer: savedTimer, alertSettings: effectiveSettings)
        setupTimerCallbacks(timer)
        timer.start()
        activeTimer = timer

        addToRecentTimers(savedTimer)
    }

    func pauseTimer() {
        activeTimer?.pause()
    }

    func resumeTimer() {
        activeTimer?.resume()
    }

    func stopCurrentTimer() {
        activeTimer?.stop()
        activeTimer = nil
    }

    func skipStage() {
        activeTimer?.skipStage()
    }

    // MARK: - Timer Callbacks

    private func setupTimerCallbacks(_ timer: ActiveTimer) {
        timer.onStageComplete = { [weak self] completedStage, nextStage, isLastStage in
            self?.handleStageComplete(
                timer: timer,
                completedStage: completedStage,
                nextStage: nextStage,
                isLastStage: isLastStage
            )
        }

        timer.onTimerComplete = { [weak self] in
            self?.handleTimerComplete(timer: timer)
        }

        // Observe timer for UI updates
        timer.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func handleStageComplete(
        timer: ActiveTimer,
        completedStage: TimerStage,
        nextStage: TimerStage?,
        isLastStage: Bool
    ) {
        let timerName = timer.savedTimer?.name ?? "Timer"
        let completedLabel = completedStage.label ?? "Stage"

        var title = "\(completedLabel) Complete"
        var body: String

        if let next = nextStage {
            let nextLabel = next.label ?? "Next stage"
            let nextDuration = next.formattedDuration
            body = "Up next: \(nextLabel) (\(nextDuration))"
        } else if isLastStage && timer.isRepeating {
            body = "Starting next cycle..."
        } else {
            body = "\(timerName) finished"
        }

        // For multi-stage timers, include timer name in title
        if timer.stages.count > 1 {
            title = "\(timerName): \(completedLabel) Complete"
        }

        sendAlert(title: title, body: body, alertSettings: timer.alertSettings)
    }

    private func handleTimerComplete(timer: ActiveTimer) {
        let timerName = timer.savedTimer?.name ?? "Timer"

        sendAlert(
            title: "\(timerName) Complete",
            body: "All stages finished",
            alertSettings: timer.alertSettings
        )

        DispatchQueue.main.async { [weak self] in
            self?.activeTimer = nil
        }
    }

    // MARK: - Alerts

    private func sendAlert(title: String, body: String, alertSettings: AlertSettings) {
        if alertSettings.playSound {
            playSound(named: alertSettings.soundName)
        }

        if alertSettings.showNotification {
            sendNotification(title: title, body: body)
        }
    }

    private func playSound(named soundName: String) {
        NSSound(named: NSSound.Name(soundName))?.play()
    }

    private func requestNotificationPermission() {
        // Request standard permissions - time sensitive doesn't need special authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.interruptionLevel = .timeSensitive  // Can break through Focus/DND

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Recent Timers

    private func addToRecentTimers(_ timer: SavedTimer) {
        recentTimers.removeAll { $0.id == timer.id }
        recentTimers.insert(timer, at: 0)
        if recentTimers.count > maxRecentTimers {
            recentTimers.removeLast()
        }
    }
}
