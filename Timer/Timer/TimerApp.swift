import SwiftUI

@main
struct TimerApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var preferencesManager = PreferencesManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(timerManager)
                .environmentObject(preferencesManager)
        } label: {
            MenuBarLabel()
                .environmentObject(timerManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            PreferencesView()
                .environmentObject(preferencesManager)
                .environmentObject(timerManager)
        }
    }
}

struct MenuBarLabel: View {
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        if let active = timerManager.activeTimer {
            let timeText = active.formattedTimeRemaining
            if let label = active.currentStage?.label {
                Text("\(label) · \(timeText)")
                    .monospacedDigit()
            } else {
                Text(timeText)
                    .monospacedDigit()
            }
        } else {
            Image(systemName: "timer")
        }
    }
}
