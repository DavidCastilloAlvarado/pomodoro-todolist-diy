task: pomodoro_full_reset
reviewer: reviewer
date: 2026-05-19
status: approved
findings: []
summary: |
  The `resetTimer()` method in `PomodoroViewModel` and `deleteActiveSession()` in `PomodoroRepository`
  correctly implement a full Pomodoro cycle reset. Every completion criterion is met:

  1. **Work phase reset** — Timer is cancelled, phase set to Work, workRemaining set to full duration, completedSessions set to 0.
  2. **Short Break reset** — Phase unconditionally set to Work (not stuck on Short Break anymore).
  3. **Long Break reset** — Phase unconditionally set to Work (not stuck on Long Break anymore).
  4. **Dot indicators** — Since `completedSessions` is set to 0, the expression `index < vm.completedSessions` in `pomodoro_screen.dart` evaluates to `0 < 0` for all 4 dots, rendering them all in the empty `primaryContainer` color.
  5. **Database cleanup** — `deleteActiveSession()` retrieves and deletes the active session from the database via `_db.deletePomodoroSession(session.id)`.
  6. **Foreground task** — `deleteActiveSession()` calls `_foregroundTask.stopPomodoroTask()` before database deletion, ensuring no orphaned background timer.
  7. **Restart capability** — After reset, `_isTimerRunning` is false, so `startTimer()` proceeds normally: creates a new `PomodoroSession`, saves it, and starts the countdown from the Work phase.
  8. **Color preservation** — `resetTimer()` only touches session state fields (`_currentPhase`, `_workRemaining`, `_completedSessions`, etc.). It does NOT touch `PomodoroConfigViewModel` or `PomodoroDurations` where `workColor`, `breakColor`, `longBreakColor` live. User customizations are preserved.

  Architecture compliance: The ViewModel extends `ChangeNotifier` and calls `notifyListeners()` after reset. The Repository delegates to the Service layer (database + foreground task) per the MVVM+Repository pattern. All code is null-safe and follows the project's style conventions.
completion_criteria_check:
  - [x] Criterion 1 — Pressing Reset while in Work phase: timer stops, phase stays Work, workRemaining resets to full duration, completedSessions becomes 0
  - [x] Criterion 2 — Pressing Reset while in Short Break phase: phase transitions to Work, workRemaining resets to full work duration, completedSessions becomes 0
  - [x] Criterion 3 — Pressing Reset while in Long Break phase: phase transitions to Work, workRemaining resets to full work duration, completedSessions becomes 0
  - [x] Criterion 4 — All dot indicators (4 circles) are empty after reset
  - [x] Criterion 5 — Active session is deleted from the database
  - [x] Criterion 6 — Foreground task is stopped
  - [x] Criterion 7 — Timer can be restarted after reset
  - [x] Criterion 8 — User's timer color customizations are NOT reset
