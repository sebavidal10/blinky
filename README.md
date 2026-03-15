# FocusBuddy

A premium Pomodoro timer for macOS with a desktop companion. FocusBuddy lives in your menu bar and features a floating robot friend ("Blinky") that reacts to your focus sessions and provides smart reminders.

## Features

- **🤖 Interactive Robot Buddy**: Blinky has multiple mood states (Idle, Focusing, Relaxing, Celebrating) and natural blinking animations.
- **🌙 Automatic Focus Mode**: Seamlessly syncs macOS "Do Not Disturb" with your work sessions using AppleScript automation.
- **📈 Productivity Stats**: Track your daily progress, total sessions, and maintain focus streaks with an automated midnight reset.
- **🧠 Smart Reminders**: Context-aware productivity tips and postural reminders (e.g., "Take a deep breath", "Stay hydrated").
- **⚙️ Deeply Customizable**: Adjustable focus/break durations, long break cycles, and buddy appearance (opacity, lighting effects).
- **🚀 Native & Lightweight**: Built with SwiftUI and AppKit for maximum performance and a premium macOS feel.

## Requirements

- macOS 13 or later (Ventura, Sonoma, or Sequoia recommended)
- Xcode 15+ (for building from source)

## Technology Stack

- **Swift & SwiftUI**: Core app logic and modern user interface.
- **AppKit**: Status bar integration (`NSStatusItem`) and floating companion window.
- **Combine**: Reactive state management and optimized event observation.
- **AppleScript**: System automation for macOS Focus Mode synchronization.
- **ServiceManagement**: Modern login item management (`SMAppService`).

## Project Structure

```
FocusBuddy/
├── AppDelegate.swift        # App lifecycle and menu bar management
├── PomodoroTimer.swift      # Core timer engine, stats, and phase logic
├── BuddySettings.swift      # Global configuration and persistence logic
├── DNDManager.swift         # macOS Focus Mode automation bridge
├── BuddyView.swift          # Blinky's UI, animations, and smart reminders
├── MenuBarView.swift        # Main popover interface and session controls
├── SettingsView.swift       # Configuration and timer preferences
└── StatsView.swift         # Achievements and session history
```

## Status

Active development. Focused on premium UI/UX and system integration.

## License

All rights reserved.
