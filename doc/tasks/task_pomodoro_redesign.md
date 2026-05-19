name: pomodoro_redesign
phase: 6
description: >
  Replace the current single-timer Pomodoro screen with the classic Pomodoro technique:
  three simultaneous timer displays (Work 25 min, Short Break 5 min, Long Break 15 min),
  a phase-based state machine with automatic transitions, a completed-sessions counter
  (0–4), and Start/Pause/Reset action buttons. The currently active timer is visually
  highlighted. The foreground service is updated to track phase transitions so the
  countdown notification stays correct during background execution.

files:
  - lib/ui/view_models/pomodoro_view_model.dart
  - lib/ui/screens/app_shell/pomodoro_screen.dart
  - lib/data/models/pomodoro_session.dart
  - lib/data/services/database.dart
  - lib/data/repositories/pomodoro_repository.dart
  - lib/data/services/foreground_task.dart
  - lib/di/di_container.dart
  - lib/ui/view_models/pomodoro_config_view_model.dart
  - lib/ui/screens/app_shell/app_shell.dart

completion_criteria:
  # --- ViewModel ---
  - [ ] `PomodoroViewModel` defines a `PomodoroPhase` enum with values `work`, `shortBreak`, `longBreak`
  - [ ] `PomodoroViewModel` defines constants `workDuration = 25 * 60`, `shortBreakDuration = 5 * 60`, `longBreakDuration = 15 * 60`
  - [ ] `PomodoroViewModel` exposes `currentPhase` (PomodoroPhase), `timeRemaining` (int seconds), `completedSessions` (int 0-4), `isTimerRunning` (bool)
  - [ ] On initialization the ViewModel sets `currentPhase = work`, `timeRemaining = workDuration`, `completedSessions = 0`, `isTimerRunning = false`
  - [ ] `startTimer()` starts countdown; `pauseTimer()` stops countdown; `resetTimer()` stops countdown and restores `timeRemaining` to the default for `currentPhase`
  - [ ] When the Work timer expires: `completedSessions` increments; if `completedSessions < 4` → phase transitions to `shortBreak` (5 min); if `completedSessions == 4` → phase transitions to `longBreak` (15 min)
  - [ ] When the Short Break timer expires → phase transitions to `work` (25 min)
  - [ ] When the Long Break timer expires: `completedSessions` resets to 0; phase transitions to `work` (25 min)
  - [ ] Phase transitions emit `notifyListeners()` so the UI updates automatically
  - [ ] Completion sound + vibration fires on any timer completion (work, short break, long break)
  - [ ] ViewModel `dispose()` cancels the timer and the foreground stream subscription

  # --- PomodoroScreen UI ---
  - [ ] Screen displays three timer rows: Work (25:00), Short Break (05:00), Long Break (15:00)
  - [ ] The currently active timer row is visually highlighted (e.g., larger font, bold, colored underline or background)
  - [ ] Each timer row shows a circular progress indicator (or equivalent visual progress bar)
  - [ ] The active phase label (e.g., "Work", "Short Break", "Long Break") is displayed prominently above or below the active timer
  - [ ] A completed-sessions counter (e.g., "Sessions: 2 / 4") with dot indicators is displayed
  - [ ] Three action buttons are shown: Start, Pause, Reset (visible when a timer exists)
  - [ ] Start button transitions to Pause when the timer is running; Pause button transitions to Resume when paused
  - [ ] Reset button stops the countdown and restores `timeRemaining` to the default for the current phase
  - [ ] Initial state shows the Work timer at 25:00 with a Start button (no Pause/Reset visible until started)
  - [ ] The duration picker (ChoiceChips) and "Ready to focus" idle state from the old implementation are removed

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
  - [ ] `PomodoroConfigViewModel` provider is **removed** from DI (no longer needed)

  # --- PomodoroConfigViewModel ---
  - [ ] `PomodoroConfigViewModel` is **deleted** (file removed) because durations are now fixed at 25/5/15

  # --- AppShell ---
  - [ ] `app_shell.dart` no longer reads `PomodoroConfigViewModel` in `addPostFrameCallback`
  - [ ] All imports of `PomodoroConfigViewModel` are removed from `app_shell.dart`

  # --- Code Quality ---
  - [ ] `dart analyze` reports zero errors and zero warnings after changes
  - [ ] No unused imports remain in any modified file
  - [ ] The MVVM pattern is preserved: ViewModel owns all timer logic, screen is a lean view
  - [ ] Phase transition logic is centralized in the ViewModel (not duplicated in the foreground service)
  - [ ] The foreground service phase logic mirrors the ViewModel's state machine (same transition rules)
