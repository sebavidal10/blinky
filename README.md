# FocusBuddy

A premium Pomodoro timer for macOS with a desktop companion. FocusBuddy lives in your menu bar and features a floating robot friend ("Blinky") that reacts to your focus sessions and provides smart reminders.

## 🚀 Key Features

- **🤖 Interactive Robot Buddy**: Blinky has multiple mood states (Idle, Focusing, Relaxing, Celebrating) and natural blinking animations.
- **⚡️ Integrated Insomnia Mode**: Prevents your Mac from sleeping with a single toggle. Perfect for long downloads, presentations, or deep focus sessions without system interruptions.
- **☕️ Caffeine Visual State**: When Insomnia Mode is active, Blinky enters a "Caffeine Mode" with distinct amber eyes, providing a subtle and integrated status indicator.
- **🌙 Automatic Focus Mode**: Seamlessly syncs macOS "Do Not Disturb" with your work sessions using AppleScript automation.
- **📈 Productivity Stats**: Track your daily progress, total sessions, and maintain focus streaks with an automated midnight reset.
- **🧠 Smart Reminders**: Context-aware productivity tips and postural reminders (e.g., "Take a deep breath", "Stay hydrated").
- **⚙️ Premium Customization**: Adjustable focus/break durations, long break cycles, and buddy appearance (opacity, lighting effects).
- **🔋 Native Performance**: Built with SwiftUI and AppKit for maximum performance, minimal resource usage, and a premium macOS feel.

## 🛠 Technology Stack

- **Swift & SwiftUI**: Core app logic and modern user interface.
- **AppKit**: Status bar integration (`NSStatusItem`) and floating companion window.
- **Combine**: Reactive state management and optimized event observation.
- **IOKit (pwr_mgt)**: Power management assertions for the Insomnia Mode.
- **AppleScript**: System automation for macOS Focus Mode synchronization.
- **ServiceManagement**: Modern login item management (`SMAppService`).

## 📂 Project Structure

```
FocusBuddy/
├── AppDelegate.swift        # App lifecycle, menu bar & popover management
├── PomodoroTimer.swift      # Core timer engine, stats, and phase logic
├── BuddySettings.swift      # Global configuration and persistence
├── InsomniaManager.swift    # Power management for sleep prevention
├── DNDManager.swift         # macOS Focus Mode automation bridge
├── BuddyView.swift          # Blinky's UI, animations, and "Caffeine Mode"
├── MenuBarView.swift        # Main popover interface and session controls
├── SettingsView.swift       # Detailed configuration preferences
├── Localization.swift       # Full English & Spanish support
└── StatsView.swift         # Achievements and session history
```

## 📋 Requirements

- macOS 13 or later (Ventura, Sonoma, or Sequoia)
- Xcode 15+ (for building from source)

## ⚖️ Status

Active development. Focused on premium UI/UX, system integration, and productivity excellence.

## 📄 License

All rights reserved.
