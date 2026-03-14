# FocusBuddy

Pomodoro timer for macOS with a desktop companion. Lives in the menu bar and shows a floating buddy that reacts to your work sessions.

## Features

- Menu bar app — no Dock icon
- Floating buddy with mood states (idle, focused, tired, celebrating, sleeping)
- Pomodoro timer with configurable work and break durations
- Session tracking — daily stats and streak
- Notifications on session completion
- Draggable buddy window
- Buddy size adjustment

## Requirements

- macOS 13 or later
- Xcode 15+

## Stack

- Swift
- SwiftUI
- AppKit (menu bar, floating window)
- UserDefaults (persistence)
- UserNotifications

## Project structure

```
FocusBuddy/
├── FocusBuddyApp.swift      # Entry point
├── AppDelegate.swift        # Menu bar + floating window setup
├── PomodoroTimer.swift      # Timer state machine
├── BuddySettings.swift      # Buddy selection and size
├── BuddyView.swift          # Floating buddy window
├── MenuBarView.swift        # Popover controls and stats
└── SettingsView.swift       # Timer and buddy configuration
```

## Status

Work in progress.

## License

All rights reserved.
