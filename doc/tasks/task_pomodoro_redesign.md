name: pomodoro_redesign
phase: 6
description: >
  Replace the current single-timer Pomodoro screen with the classic Pomodoro technique:
  three simultaneous timer displays (Work, Short Break, Long Break), a phase-based state
  machine with automatic transitions, a completed-sessions counter (0–4), and Start/Pause/
  Reset action buttons. The currently active timer is visually highlighted. Durations are
  configurable in a Settings page (three inputs for Work, Short Break, Long Break minutes)
  with defaults of 25/5/15. The Pomodoro screen listens to config changes and rebuilds
  with new durations — preserving remaining time if a timer is running. The foreground
  service is updated to track phase transitions so the countdown notification stays correct
  during background execution.

files:
  - lib/ui/view_models/pomodoro_view_model.dart
  - lib/ui/screens/app_shell/pomodoro_screen.dart
  - lib/ui/screens/settings/settings_page.dart
  - lib/data/models/pomodoro_session.dart
  - lib/data/services/database.dart
  - lib/data/repositories/pomodoro_repository.dart
  - lib/data/services/foreground_task.dart
  - lib/data/services/storage_service.dart
  - lib/ui/view_models/pomodoro_config_view_model.dart
  - lib/di/di_container.dart
  - lib/ui/screens/app_shell/app_shell.dart

completion_criteria:
  # --- ViewModel ---
  - [ ] `PomodoroViewModel` defines a `PomodoroPhase` enum with values `work`, `shortBreak`, `longBreak`
  - [ ] `PomodoroViewModel` reads configurable durations from `PomodoroConfigViewModel` (or a settings repository) to initialize its working durations
  - [ ] `PomodoroViewModel` exposes `currentPhase` (PomodoroPhase), `timeRemaining` (int seconds), `completedSessions` (int 0-4), `isTimerRunning` (bool)
  - [ ] `PomodoroViewModel` exposes `workDuration`, `breakDuration`, `longBreakDuration` as computed or accessible values (in seconds)
  - [ ] On initialization the ViewModel sets `currentPhase = work`, `timeRemaining = workDuration`, `completedSessions = 0`, `isTimerRunning = false`
  - [ ] `startTimer()` starts countdown; `pauseTimer()` stops countdown; `resetTimer()` stops countdown and restores `timeRemaining` to the default for `currentPhase` (using current config values)
  - [ ] When the Work timer expires: `completedSessions` increments; if `completedSessions < 4` → phase transitions to `shortBreak` (breakDuration); if `completedSessions == 4` → phase transitions to `longBreak` (longBreakDuration)
  - [ ] When the Short Break timer expires → phase transitions to `work` (workDuration)
  - [ ] When the Long Break timer expires: `completedSessions` resets to 0; phase transitions to `work` (workDuration)
  - [ ] Phase transitions emit `notifyListeners()` so the UI updates automatically
  - [ ] Completion sound + vibration fires on any timer completion (work, short break, long break)
  - [ ] ViewModel `dispose()` cancels the timer and the foreground stream subscription

  # --- PomodoroScreen UI ---
  - [ ] Screen displays three timer rows: Work, Short Break, Long Break — each showing its current time
  - [ ] The currently active timer row is visually highlighted (e.g., larger font, bold, colored underline or background)
  - [ ] Each timer row shows a circular progress indicator (or equivalent visual progress bar)
  - [ ] The active phase label (e.g., "Work", "Short Break", "Long Break") is displayed prominently
  - [ ] A completed-sessions counter (e.g., "Sessions: 2 / 4") with dot indicators is displayed
  - [ ] Three action buttons are shown: Start, Pause, Reset (visible when a timer exists)
  - [ ] Start button transitions to Pause when the timer is running; Pause button transitions to Resume when paused
  - [ ] Reset button stops the countdown and restores `timeRemaining` to the default for the current phase (using current config values)
  - [ ] Initial state shows the Work timer at 25:00 with a Start button (no Pause/Reset visible until started)
  - [ ] The duration picker (ChoiceChips) and "Ready to focus" idle state from the old implementation are removed
  - [ ] The screen uses `Consumer<PomodoroConfigViewModel>` or `Selector` to listen to config changes and rebuild when durations change

  # --- Configurable Durations ---
  - [ ] `PomodoroConfigViewModel` holds `workMinutes` (int), `breakMinutes` (int), `longBreakMinutes` (int) with defaults 25, 5, 15
  - [ ] `PomodoroConfigViewModel` loads these values from `StorageService` on construction
  - [ ] `PomodoroConfigViewModel.saveDurations(workMinutes, breakMinutes, longBreakMinutes)` persists to `StorageService` and **must call `notifyListeners()` after the values are updated**
  - [ ] `PomodoroConfigViewModel` is **not deleted** — it is refactored from a list-based model to a three-field model
  - [ ] `StorageService` methods are updated to store/read three individual duration values (not a comma-separated list)
  - [ ] `PomodoroViewModel` reads durations from `PomodoroConfigViewModel` on initialization
  - [ ] `PomodoroConfigViewModel` exposes the durations via a `ValueListenable` or `Stream` so the Pomodoro screen can listen for changes
  - [ ] When `PomodoroConfigViewModel` emits `notifyListeners()`, `PomodoroViewModel` updates its internal duration values and calls `notifyListeners()` so the screen rebuilds
  - [ ] **CRITICAL**: After any duration value is set/changed in Settings, `PomodoroConfigViewModel.notifyListeners()` must be called immediately — the Pomodoro tab must receive this event and refresh its displayed timer values. This is not optional.
  - [ ] If a timer is currently running/paused when config changes: remaining seconds are preserved but the progress indicator recalculates based on the new total
  - [ ] If no timer is running when config changes: the display immediately shows the new default durations
  - [ ] The `resetTimer()` method uses the current (configurable) duration for the active phase, not hardcoded values

  # --- Settings Page ---
  - [ ] A new `SettingsPage` is created at `lib/ui/screens/settings/settings_page.dart`
  - [ ] The Settings page contains three `TextFormField` inputs labeled "Work (min)", "Break (min)", "Long Break (min)"
  - [ ] The inputs are pre-populated with values from `PomodoroConfigViewModel`
  - [ ] A "Save" button persists the values via `PomodoroConfigViewModel.saveDurations()`
  - [ ] **CRITICAL**: On save, `PomodoroConfigViewModel.notifyListeners()` is called **immediately after** the new values are stored — the Pomodoro screen must refresh with the new durations. If this is missing, the Pomodoro tab will stay stuck on old values.
  - [ ] Input validation: only positive integers are accepted; invalid input is rejected or corrected
  - [ ] The Settings page is accessible from the app's navigation (e.g., bottom nav or a dedicated Settings tab)

  # --- PomodoroSession Model ---
  - [ ] `PomodoroSession` gains optional fields `currentPhase` (int, maps to `PomodoroPhase` values) and `completedSessions` (int)
  - [ ] `PomodoroSession` `toMap()` / `fromMap()` serialize the new fields
  - [ ] `PomodoroSession` `copyWith()` accepts `currentPhase?` and `completedSessions?`
  - [ ] Existing fields (`itemTitle`, `listId`, `durationMinutes`, `status`, `startedAt`, `endedAt`, `remaining`) are preserved unchanged

  # --- Database ---
  - [ ] `pomodoro_sessions` table gains columns `current_phase INTEGER DEFAULT 0` and `completed_sessions INTEGER DEFAULT 0`
  - [ ] `PomodoroSessionsData` data class includes `currentPhase` and `completedSessions` with defaults (0)
  - [ ] `BirdleDatabase` methods (`insertPomodoroSession`, `updatePomodoroSession`) write/read the new columns
  - [ ] `getActivePomodoro()` still works (unchanged query logic)

  # --- Repository ---
  - [ ] `PomodoroRepository` methods pass `currentPhase` and `completedSessions` through to the database layer
  - [ ] `getActiveSession()` maps the new columns into the `PomodoroSession` model
  - [ ] `completeSession()` persists the updated `completedSessions` count and phase

  # --- Foreground Task Service ---
  - [ ] `ForegroundTaskService` tracks `currentPhase` alongside `remainingSeconds`
  - [ ] The foreground timer callback handles phase transitions on timer expiration (same logic as ViewModel)
  - [ ] On phase transition, the notification title/text is updated to reflect the new phase
  - [ ] `sendDataToMain` fires with `type: 'pomodoro_complete'` on any timer completion (work or break)
  - [ ] The foreground service continues to count down correctly when the app is backgrounded

  # --- DI Container ---
  - [ ] `PomodoroViewModel` provider registration updated (no dependency changes needed)
  - [ ] `PomodoroConfigViewModel` provider **remains** in DI, wired to `StorageService`
  - [ ] `PomodoroConfigViewModel` is also available to the `SettingsPage` for reading/saving durations

  # --- AppShell ---
  - [ ] `app_shell.dart` no longer reads `PomodoroConfigViewModel` in `addPostFrameCallback` (or retains it if needed for other purposes)
  - [ ] All stale imports of `PomodoroConfigViewModel` are cleaned up from `app_shell.dart`
  - [ ] The Settings page is integrated into the bottom navigation (replaces or supplements the existing SettingsView)

  # --- Code Quality ---
  - [ ] `dart analyze` reports zero errors and zero warnings after changes
  - [ ] No unused imports remain in any modified file
  - [ ] The MVVM pattern is preserved: ViewModel owns all timer logic, screen is a lean view
  - [ ] Phase transition logic is centralized in the ViewModel (not duplicated in the foreground service)
  - [ ] The foreground service phase logic mirrors the ViewModel's state machine (same transition rules)
  - [ ] Duration values are never hardcoded in the PomodoroViewModel or PomodoroScreen — all durations come from `PomodoroConfigViewModel`
