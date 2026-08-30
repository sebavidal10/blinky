# Blinky ⚡️

A premium session tracker for macOS with a desktop companion. Blinky lives in your menu bar and features a floating robot friend that reacts to your work sessions and meetings, with smart calendar integration.

## 🚀 Key Features

- **🧩 Customizable Modules & Tabs**: Easily enable or disable individual modules (Timer, Calendar & Stats, Quick Notes, System Monitor) from Settings with a clean, clutter-free switch design.
- **🔒 Protected Quick Notes with Biometrics**: Safeguard sensitive notes and passwords with an elegant blur effect. Unlock individual notes or all at once using **Touch ID**, **Apple Watch**, or your macOS device password via `LocalAuthentication`, with persistent lock settings.
- **⏱️ Menu Bar Event Customization**: Choose how upcoming meetings appear in your menu bar: full display (*Time & Title*) or minimalist (*Time only / Countdown*).
- **🤖 Interactive Robot Buddy**: Blinky has multiple mood states (Idle, Focusing, Celebrating). **Imminent meetings** (selector for 5, 10, 15 mins) are displayed on his eyes with an orange countdown. **Contextual icons** (video, calendar, bolt) appear on his face to show the current activity type.
- **✨ Refined Header**: The robot buddy and session status are now integrated into the main header, providing a cleaner and more compact interface.
- **⏱️ Infinite Work Sessions**: Open-ended stopwatch sessions with no time limit.
- **📅 Smart Meeting Alerts**: Automatically detects upcoming meetings. **Auto-Start** logic activates the session and timer at the exact start time. The system menu bar dynamically shows the **Next Event** (within 12h) before the countdown begins, with a toggle in settings.
- **📁 Grouped Meetings**: Clear visual separation for Today/Tomorrow with **engaging empty states**.
- **📍 Activity Indicators**: Custom-built historical calendar with **dot indicators** for days with focus sessions or notes.
- **💎 Premium UI Consistency**: Normalized headers across all sections for a more professional and seamless experience.
- **⚙️ Segmented Settings**: Reimagined multi-card configuration with dedicated sections for General, Buddy Config, Modules, and Calendars. Browser and Calendar selection are integrated into the main **Settings** view.
- **📈 History Views**: Toggle between a daily calendar view and a **full list view** to track all your past sessions effortlessly, designed as a streamlined list for optimal space usage.
- **🗑️ Data Control**: Easily **Clear History** with a single click in settings to reset your progress and streaks.
- **📦 SwiftData Persistence**: High-performance session history using modern SwiftData architecture, with automatic migration from legacy `UserDefaults`.
- **✨ Visual Feedback**: Premium **Confetti celebration** effect when completing goals or achieving focus milestones.
- ** Context-Aware Reminders**: Blinky offers smart, real-time advice based on your focus time and meeting frequency (e.g., detecting back-to-back meetings).
- **🔄 Robust Sync Now**: The "Sync Now" button forces a re-read of all calendar sources (iCloud, Google Calendar, etc.) with a smooth **rotation animation** for visual feedback.
- **⭕️ Progress Ring**: Visual progress indicator around Blinky only appears during calendar meetings.
- **💬 Smart Reminders**: Blinky shows contextual motivational messages during active sessions.
- **⚡️ Integrated Insomnia Mode**: Prevents your Mac from sleeping with a single toggle. Now **enabled by default** on app launch.
- **📜 Detailed Session Cards**: Each session shows your goal, start time, and duration in a clean 2-line layout.
- **📝 Quick Notes**: Jot down thoughts instantly from the Buddy's floating UI or manage them in the dedicated **Notes** tab in the menu bar.
- **🗑 Secure Management**: All deletions for sessions and notes are guarded by a **Confirmation Dialog**, ensuring stability even during real-time timer updates.
- **🌐 Bilingual**: Full English and Spanish localization.
- **🔋 Native Performance & Efficiency**: Built with SwiftUI and AppKit for maximum performance. Incorporates deep optimizations like `DateFormatter` caching and `O(1)` calendar polling to ensure **zero battery drain** while running continuously in the background.

## 🛠 Technology Stack

- **Swift & SwiftUI**: Core app logic and modern user interface.
- **AppKit**: Status bar integration (`NSStatusItem`) and floating companion window.
- **LocalAuthentication**: Native biometric security (Touch ID / macOS password) for protected notes.
- **EventKit**: macOS Calendar integration for meeting-aware sessions with debounced fetching.
- **Combine**: Reactive state management and optimized event observation.
- **IOKit (pwr_mgt)**: Power management assertions for the Insomnia Mode.
- **ServiceManagement**: Modern login item management (`SMAppService`).

## 📂 Project Structure

```
Blinky/
├── BlinkyApp.swift            # App entry point
├── AppDelegate.swift          # App lifecycle, menu bar & popover management
├── BiometricAuthManager.swift # Touch ID / macOS password authentication
├── SessionManager.swift      # Core session engine, stats, timer logic & persistence
├── NotesManager.swift        # Quick notes engine and persistence
├── CalendarManager.swift     # macOS Calendar integration with debounced fetching
├── BuddySettings.swift        # Global configuration and persistence
├── InsomniaManager.swift      # Power management for sleep prevention
├── BuddyView.swift           # Blinky's UI, animations, smart reminders & moods
├── MenuBarView.swift         # Main popover interface and notes integration
├── SettingsView.swift        # Unified configuration (General, Browser, Modules, Calendars)
├── StatsView.swift           # Historial (session history and date navigation)
├── CalendarDotsView.swift    # Custom historical calendar with activity dots
├── NotesView.swift           # Quick notes list, biometric protection and management
├── Localization.swift        # Full English & Spanish support
├── SyncIcon.swift            # Reusable robust rotation animation component
└── UIComponents.swift        # Reusable UI components

BlinkyTests/
└── SessionManagerTests.swift  # Unit tests for session logic
```

## 💻 Local Development

Follow these steps to set up, build, and run Blinky on your local machine for development:

### 1. Prerequisites
- **macOS 13.0** (Ventura) or later.
- **Xcode 15.0** or later.

### 2. Setup & Run
1. **Clone the repository** (if you haven't already):
   ```bash
   git clone https://github.com/sebavidal10/blinky.git
   cd blinky
   ```

#### Option A: Using Xcode (GUI)
1. **Open the Project:**
   ```bash
   open Blinky.xcodeproj
   ```
2. **Select Scheme & Destination:**
   Set the active scheme to `Blinky` and select your Mac (`My Mac`) as the run destination.
3. **Build and Run:**
   Press `Cmd + R` (or select *Product > Run*) to build and launch the app.

#### Option B: Using Command Line (CLI)
You can compile and launch the app directly from your terminal using `xcodebuild`:
1. **Build the app:**
   ```bash
   xcodebuild -project Blinky.xcodeproj -scheme Blinky -configuration Debug -derivedDataPath build
   ```
2. **Launch the app:**
   ```bash
   open build/Build/Products/Debug/Blinky.app
   ```

> [!NOTE]
> Since Blinky is a menu bar application, look for the Blinky icon (⚡️) in your macOS menu bar once launched.

#### Permissions
Blinky integrates with macOS Calendars via `EventKit`. On the first launch, macOS will prompt you for Calendar access. Grant the permission to enable meeting-aware focus states.

### 3. Adding New Features
- **Localization:** Ensure any user-facing text is added to [Localization.swift](Blinky/Localization.swift) to support both English and Spanish.
- **SwiftData Persistence:** Persistent storage is handled via SwiftData. If you modify any schema, handle SwiftData models carefully to ensure clean migrations.

## 🧪 Testing

The app includes unit tests covering:
- Session state management (idle, working, meeting)
- Infinite vs time-limited sessions
- Timer controls (start, stop, pause, resume, reset)
- Session persistence and history
- Time formatting and progress calculations
- Day reset and streak logic

### How to Run Tests
- **In Xcode:** Press `Cmd + U`.
- **From Command Line:**
  ```bash
  xcodebuild test -project Blinky.xcodeproj -scheme Blinky -destination 'platform=macOS'
  ```

## 📋 Requirements

- macOS 13 or later (Ventura, Sonoma, or Sequoia)
- Xcode 15+ (for building from source)

## ⚖️ Status

Active development. Focused on premium UI/UX, system integration, and productivity excellence.

## 📄 License

All rights reserved.
