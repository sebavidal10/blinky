# FocusBuddy

Pomodoro timer for macOS with a desktop companion. Lives in the menu bar and shows a floating buddy that reacts to your work sessions.

## Features

- **Floating Buddy**: Mood states (idle, focused, relaxing, celebrating) and animations.
- **Automated Focus Mode (DND)**: Syncs macOS "Do Not Disturb" with your focus sessions.
- **Launch at Login**: Option to start FocusBuddy automatically with your Mac.
- **Session Control**: Pause, Skip, or Finish Full Cycle with safety confirmations.
- **Smart Reminders**: Productivity tips and postural reminders during session phases.
- **Daily Stats**: Track total sessions and daily streaks with automated midnight reset.
- **Draggable Window**: Adjustable buddy opacity and visibility.

## Requirements

- macOS 13 or later (Sonoma/Sequoia recommended for Focus Mode sync)
- Xcode 15+

## Stack

- **Swift & SwiftUI**: Modern macOS development.
- **AppKit**: Status bar integration (NSStatusItem) and floating windows.
- **AppleScript**: System automation for macOS Focus Modes.
- **ServiceManagement**: Modern login item management (SMAppService).
- **Combine**: Reactive state management and event observation.
- **UserDefaults**: Lightweight local persistence with background saving.

## Project Structure

```
FocusBuddy/
├── AppDelegate.swift        # Lifecycle and system integration
├── PomodoroTimer.swift      # Core timer logic and stats management
├── BuddySettings.swift      # Global settings and persistence
├── DNDManager.swift         # macOS Focus Mode (DND) automation
├── BuddyView.swift          # Floating buddy UI and animations
├── MenuBarView.swift        # Menu bar interface and session controls
└── SettingsView.swift       # Configuration UI
```

## Status

Ready for personal testing and refinement.

## License

All rights reserved.
