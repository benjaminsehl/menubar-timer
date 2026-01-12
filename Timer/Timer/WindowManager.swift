import SwiftUI
import AppKit

class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var editTimerWindow: NSWindow?

    func openNewTimerWindow(preferencesManager: PreferencesManager) {
        openEditTimerWindow(mode: .create, preferencesManager: preferencesManager)
    }

    func openEditTimerWindow(timer: SavedTimer, preferencesManager: PreferencesManager) {
        openEditTimerWindow(mode: .edit(timer), preferencesManager: preferencesManager)
    }

    private func openEditTimerWindow(mode: EditTimerMode, preferencesManager: PreferencesManager) {
        // Close existing window if any
        editTimerWindow?.close()

        let contentView = EditTimerView(mode: mode, onDismiss: { [weak self] in
            self?.editTimerWindow?.close()
            self?.editTimerWindow = nil
        })
        .environmentObject(preferencesManager)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = mode.title
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        editTimerWindow = window
    }

    func closeEditTimerWindow() {
        editTimerWindow?.close()
        editTimerWindow = nil
    }
}
