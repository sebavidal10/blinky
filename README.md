# Blinky ⚡️

A premium session tracker for macOS with a desktop companion. Blinky lives in your menu bar and features a floating robot friend that reacts to your work sessions and meetings, with smart calendar integration.

## 🚀 Key Features

- **🤖 Interactive Robot Buddy**: Blinky has multiple mood states (Idle, Focusing, Celebrating) and natural blinking animations.
- **⏱️ Infinite Work Sessions**: Open-ended stopwatch sessions with no time limit - you decide when to finish.
- **📅 Calendar Integration**: Sync with macOS Calendar to automatically detect meetings for Today and Tomorrow.
- **📁 Grouped Meetings**: Clear visual separation between Today's and Tomorrow's events with smart iconography (video for meetings, calendar for events).
- **⚙️ Reorganized Settings**: Intuitive layout with General, Appearance, and Calendars sections for better navigation.
- **⭕️ Progress Ring**: Visual progress indicator around Blinky only appears during calendar meetings.
- **💬 Smart Reminders**: Blinky shows contextual motivational messages during active sessions.
- **⚡️ Integrated Insomnia Mode**: Prevents your Mac from sleeping with a single toggle.
- **📈 Historial (History)**: Track your daily progress with a filtered session list. Navigate by date using arrows or a calendar picker, and quickly return to today with the "Hoy" shortcut.
- **📜 Detailed Session Cards**: Each session shows your goal, start time, and duration in a clean 2-line layout.
- **🗑 Session Management**: Delete individual sessions directly from the history list.
- **🌐 Bilingual**: Full English and Spanish localization.
- **🔋 Native Performance**: Built with SwiftUI and AppKit for maximum performance and minimal resource usage.

## 🛠 Technology Stack

- **Swift & SwiftUI**: Core app logic and modern user interface.
- **AppKit**: Status bar integration (`NSStatusItem`) and floating companion window.
- **EventKit**: macOS Calendar integration for meeting-aware sessions with debounced fetching.
- **Combine**: Reactive state management and optimized event observation.
- **IOKit (pwr_mgt)**: Power management assertions for the Insomnia Mode.
- **ServiceManagement**: Modern login item management (`SMAppService`).

## 📂 Project Structure

```
Blinky/
├── BlinkyApp.swift            # App entry point
├── AppDelegate.swift          # App lifecycle, menu bar & popover management
├── SessionManager.swift      # Core session engine, stats, timer logic & persistence
├── CalendarManager.swift     # macOS Calendar integration with debounced fetching
├── BuddySettings.swift        # Global configuration and persistence
├── InsomniaManager.swift      # Power management for sleep prevention
├── BuddyView.swift           # Blinky's UI, animations, smart reminders & moods
├── MenuBarView.swift         # Main popover interface and session controls
├── SettingsView.swift        # Detailed configuration preferences
├── StatsView.swift           # Historial (session history and date navigation)
├── Localization.swift        # Full English & Spanish support
└── UIComponents.swift        # Reusable UI components

BlinkyTests/
└── SessionManagerTests.swift  # Unit tests for session logic
```

## 🧪 Testing

The app includes unit tests covering:
- Session state management (idle, working, meeting)
- Infinite vs time-limited sessions
- Timer controls (start, stop, pause, resume, reset)
- Session persistence and history
- Time formatting and progress calculations
- Day reset and streak logic

Run tests with `Cmd+U` in Xcode.

## 📋 Requirements

- macOS 13 or later (Ventura, Sonoma, or Sequoia)
- Xcode 15+ (for building from source)

## ⚖️ Status

Active development. Focused on premium UI/UX, system integration, and productivity excellence.

## 📄 License

All rights reserved.
