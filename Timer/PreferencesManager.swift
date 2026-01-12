import Foundation
import Combine

class PreferencesManager: ObservableObject {
    @Published var alertSettings: AlertSettings {
        didSet { saveAlertSettings() }
    }

    @Published var savedTimers: [SavedTimer] {
        didSet { saveSavedTimers() }
    }

    @Published var quickTimerMinutes: [Int] {
        didSet { saveQuickTimerMinutes() }
    }

    private let alertSettingsKey = "alertSettings"
    private let savedTimersKey = "savedTimers"
    private let quickTimerMinutesKey = "quickTimerMinutes"

    init() {
        // Load alert settings
        if let data = UserDefaults.standard.data(forKey: alertSettingsKey),
           let settings = try? JSONDecoder().decode(AlertSettings.self, from: data) {
            self.alertSettings = settings
        } else {
            self.alertSettings = .default
        }

        // Load saved timers
        if let data = UserDefaults.standard.data(forKey: savedTimersKey),
           let timers = try? JSONDecoder().decode([SavedTimer].self, from: data) {
            self.savedTimers = timers
        } else {
            // Default with Pomodoro
            self.savedTimers = [SavedTimer.pomodoro]
        }

        // Load quick timer presets
        if let minutes = UserDefaults.standard.array(forKey: quickTimerMinutesKey) as? [Int] {
            self.quickTimerMinutes = minutes
        } else {
            self.quickTimerMinutes = [5, 10, 15, 25, 30, 45, 60]
        }
    }

    private func saveAlertSettings() {
        if let data = try? JSONEncoder().encode(alertSettings) {
            UserDefaults.standard.set(data, forKey: alertSettingsKey)
        }
    }

    private func saveSavedTimers() {
        if let data = try? JSONEncoder().encode(savedTimers) {
            UserDefaults.standard.set(data, forKey: savedTimersKey)
        }
    }

    private func saveQuickTimerMinutes() {
        UserDefaults.standard.set(quickTimerMinutes, forKey: quickTimerMinutesKey)
    }

    func addSavedTimer(_ timer: SavedTimer) {
        savedTimers.append(timer)
    }

    func updateSavedTimer(_ timer: SavedTimer) {
        if let index = savedTimers.firstIndex(where: { $0.id == timer.id }) {
            savedTimers[index] = timer
        }
    }

    func deleteSavedTimer(_ timer: SavedTimer) {
        savedTimers.removeAll { $0.id == timer.id }
    }

    func deleteSavedTimer(at offsets: IndexSet) {
        savedTimers.remove(atOffsets: offsets)
    }
}
