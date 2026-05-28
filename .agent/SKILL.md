---
name: Code Precision and Syntax Guard
description: Guidelines to prevent syntax errors like extraneous braces or missing imports during code modifications.
---

# Code Precision and Syntax Guard

This skill ensures that every code modification maintains the structural integrity of the file and avoids common syntax errors, particularly when using `multi_replace_file_content` or `replace_file_content`.

## Precision Rules

1. **Brace Integrity**: 
   - Before applying an edit, always count opening and closing braces in the `TargetContent` and ensure the `ReplacementContent` maintains a valid balance.
   - Avoid including the final brace of a method if you are only adding lines *inside* the method, unless you are absolutely sure of the context.
   - **Check for "Double Closure"**: Ensure your edit doesn't accidentally include a closing brace that is already present in the lines immediately following the `TargetContent`.

2. **Context Awareness**:
   - Always view at least 5-10 lines *before* and *after* the section you intend to edit to understand the nesting level.
   - If the file has a lot of similar-looking closures, include more surrounding context in `TargetContent` to make it unique and identifiable.

3. **Strict Import Preservation**:
   - **NEVER** remove top-level imports unless you are explicitly refactoring away from that framework.
   - Even if you add new frameworks (like `SwiftData`), keep the existing ones (`Foundation`, `Combine`, `SwiftUI`, `AppKit`) as they are often required by secondary protocols like `ObservableObject` or `Identifiable`.
   - Before applying a replacement chunk at the top of a file, verify that you are not overwriting or deleting essential imports.

4. **Incremental Verification**:
   - After a significant edit, use `view_file` to inspect the modified area and confirm that there are no "dangling" braces or syntax errors.
   - If a file fails to compile (or shows syntax errors), immediately inspect the lines reported in the error message and the surrounding scope.

4. **Mandatory Import Verification**:
   - Before completing any edit, verify that all types and protocols used (e.g., `ObservableObject`, `AnyCancellable`, `@Published`) have their corresponding frameworks imported (e.g., `Combine`, `SwiftUI`, `EventKit`).
   - If you add or modify code that relies on a specific framework, check the top of the file to ensure the `import` statement exists.

5. **Swift Specifics**:
   - Be wary of trailing closures and their braces.
   - Ensure `@objc` methods and protocols are correctly closed.

6. **Mandatory Syntax Verification**:
   - After *every* edit to a `.swift` file, you MUST perform a visual check of the surrounding scope to ensure all braces are balanced.
   - If in doubt, use `run_command` with `swiftc -parse <file_path>` to catch structural errors, even if it reports missing module errors (it will still report extraneous braces first).

7. **Performance & Memory (DateFormatter)**:
   - `DateFormatter` instantiations are notoriously expensive in Swift. **NEVER** instantiate them inside computed properties like `body` or properties that re-evaluate frequently.
   - Always declare them as `static let` or `fileprivate static let` within the struct or class.
   - For locale changes, simply set `FormatterName.locale = Locale(...)` before calling `.string(from:)`.

## Error Prevention Workflow

1. **Plan**: Identify the exact lines.
2. **Double-Check**: Compare the last line of your `ReplacementContent` with what will follow in the file.
3. **Apply**: Execute the tool call.
4. **Verify**: View the file to ensure the closing braces match the indentation and scope.

## Data Governance & Safety

1. **Delete Confirmation**: Every deletion of persisted data (Notes, Sessions, etc.) MUST be guarded by a `.confirmationDialog`. User safety against accidental data loss is a top priority for this premium app.
2. **Dialog Stability**: For list/row items, the `confirmationDialog` and its trigger state MUST reside at the **Parent View** level (e.g., in `StatsView` or `NotesView`), not within individual rows. This prevents the dialog from vanishing if the row is refreshed or recreated by an `ObservableObject` tick (like `SessionManager's` second tick).
3. **SwiftData Persistence**: Use SwiftData for high-volume historical data (sessions). Maintain a migration layer from `UserDefaults` for legacy support. Ensure `modelContext.save()` is called after meaningful changes.
4. **Contextual Intelligence**: Smart reminders should be calculated in `SessionManager` using real-time metrics (`focusTimeToday`, `consecutiveMeetings`) and visualized in `BuddyView` via `ConfettiView` or `MessageBubble`.
## Branding and Tone

1. **Blinky Entity**: Always refer to the application and the character as **Blinky**. The previous name "FocusBuddy" is deprecated and must not be used in any user-facing strings, comments, or documentation.
2. **Session Tracker Focus**: The project has pivoted from a Pomodoro timer to a **Session Tracker**. Avoid "Pomodoro" terminology in UI and logic (use "Sessions", "Work", "Meetings" instead).

## Key Implementation Details

- **UI Architecture**: Maintain a segmented layout in Settings using independent `.ultraThinMaterial` cards for different logic groups (General, Buddy, etc.). Ensure vertical alignment for all controls, avoiding ad-hoc padding that breaks the grid. In the achievements/history views (`StatsView`), keep the interface compact and clean by displaying lists/calendars directly and avoiding large/redundant summary cards (like 'Sessions' and 'Focus' cards).
- **Contextual Icons**: Dynamic SFSymbols appear as circular overlays in the **bottom-left** of Blinky's outer shell, mirroring the pencil button on the right.
- **Meeting Automation**: `SessionManager` includes **Auto-Start** logic. If a meeting on the user's calendar begins, it automatically transitions to `.meeting` mode and starts the timer. Ensure the `Aura` in `BuddyView` is teal during meetings.
- **Meeting Countdown**: Discrete threshold (5, 10, 15 min picker) displayed on eyes.
- **Insomnia Mode**: Power management assertions to prevent sleep. **Forced to enabled by default** on every app launch.
- **Automated Build Versioning**: Whenever finishing a task that requires compiling a new release or submitting to the App Store, you MUST remember to automatically increment the `CURRENT_PROJECT_VERSION` (build number) in `project.pbxproj`. **CRITICAL: Always update the version before finalizing a session.**
