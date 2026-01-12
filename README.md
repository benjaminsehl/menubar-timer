# Timer

A native macOS menubar app for managing timers. Supports one-off timers, multi-stage sequences, and repeating timers like Pomodoro.

## Features

- **Quick Timers** - Preset buttons for common durations (5m, 10m, 15m, etc.) or enter a custom duration
- **Saved Timers** - Create named timers that persist across app launches
- **Multi-Stage Sequences** - Chain multiple intervals together (e.g., 10m → 15m → 10m) for meeting cues or structured workflows
- **Repeating Timers** - Set timers to repeat a fixed number of times or indefinitely (Pomodoro-style)
- **Stage Labels** - Name each stage (e.g., "Work", "Break") for clear notifications
- **Menubar Display** - Shows current stage and time remaining (e.g., `Work · 24:21`)
- **Customizable Alerts** - Configure sound and/or notification per timer or globally
- **Time Sensitive Notifications** - Can break through Focus/Do Not Disturb when allowed

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later

## Building

1. Open `Timer.xcodeproj` in Xcode
2. Build and run (⌘R)

The app will appear as a timer icon in your menubar.

## Usage

### Quick Timer
Click the menubar icon and select a preset duration, or enter a custom number of minutes.

### Creating a Saved Timer
1. Click "New Timer..." in the popover
2. Enter a name for your timer
3. Add stages with optional labels and durations
4. Enable "Repeat Timer" for Pomodoro-style cycling
5. Optionally configure custom alert settings
6. Click "Save"

### Example: Pomodoro Timer
A default Pomodoro timer is included:
- Work: 25 minutes
- Break: 5 minutes
- Repeats 4 times

### Controls
- **Play/Pause** - Start, pause, or resume the timer
- **Stop** - Cancel the current timer
- **Skip** - Jump to the next stage (for multi-stage timers)

## Preferences

Access via the popover or `⌘,`:

- **General** - Configure quick timer presets
- **Alerts** - Set default sound and notification preferences
- **Saved Timers** - Manage your saved timer library

## License

MIT
