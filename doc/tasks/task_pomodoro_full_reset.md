name: pomodoro_full_reset
phase: 6
description: Fix the Pomodoro Reset button to perform a full cycle reset — returning to Work phase with session count cleared — instead of only resetting the current phase's remaining time.
files:
  - lib/ui/view_models/pomodoro_view_model.dart
  - lib/data/repositories/pomodoro_repository.dart
completion_criteria:
  - [ ] Pressing Reset while in Work phase: timer stops, phase stays Work, workRemaining resets to full duration, completedSessions becomes 0
  - [ ] Pressing Reset while in Short Break phase: phase transitions to Work, workRemaining resets to full work duration, completedSessions becomes 0 (was stuck on Short Break before)
  - [ ] Pressing Reset while in Long Break phase: phase transitions to Work, workRemaining resets to full work duration, completedSessions becomes 0 (was stuck on Long Break before)
  - [ ] All dot indicators (4 circles) are empty after reset regardless of how many were filled before
  - [ ] Active session is deleted from the database (no stale paused session lingering)
  - [ ] Foreground task is stopped (no orphaned background timer continues)
  - [ ] Timer can be restarted after reset (Start button works, countdown begins from Work phase)
  - [ ] User's timer color customizations (workColor, breakColor, longBreakColor) are NOT reset — they are user preferences, not session state
status: pending
