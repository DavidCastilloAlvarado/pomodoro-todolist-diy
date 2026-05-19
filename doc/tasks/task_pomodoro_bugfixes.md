name: pomodoro_bugfixes
phase: 6
description: >
  Fix three critical bugs in the Pomodoro implementation:
  1. Database migration not applied (current_phase column missing) — causes crash on startTimer
  2. _durations is late and async-initialized — causes 00:00 for break timers
  3. PomodoroDurations fields are final — listener detachment on config save
files:
  - lib/data/services/database.dart
  - lib/ui/view_models/pomodoro_config_view_model.dart
  - lib/data/models/pomodoro_session.dart
completion_criteria:
  # Database fix
  - [ ] Database version bumped from 2 to 3 in BirdleDatabase.open()
  - [ ] _upgradeDb handles oldVersion < 3 to add current_phase and completed_sessions columns
  - [ ] Existing databases can now successfully INSERT into pomodoro_sessions with new columns
  - [ ] Fresh installs still create the table with all columns correctly
  
  # Config initialization fix
  - [ ] PomodoroConfigViewModel._durations is initialized with default values synchronously (not late)
  - [ ] Default values are workMinutes: 25, breakMinutes: 5, longBreakMinutes: 15
  - [ ] PomodoroViewModel._initDefaults() works even before _loadDurations() completes
  - [ ] Short Break and Long Break show correct durations from the start (not 00:00)
  
  # PomodoroDurations mutability fix
  - [ ] PomodoroDurations fields (workMinutes, breakMinutes, longBreakMinutes) are mutable (no final)
  - [ ] PomodoroDurations has an update() method that changes values and calls notifyListeners()
  - [ ] PomodoroConfigViewModel.saveDurations() calls _durations.update() instead of creating new instance
  - [ ] The listener attached by PomodoroViewModel continues to work after config save
  
  # Verification
  - [ ] Pressing Start no longer crashes with database error
  - [ ] Pressing Start begins countdown on the Work timer
  - [ ] Short Break shows correct duration (from settings or default 5 min)
  - [ ] Long Break shows correct duration (from settings or default 15 min)
  - [ ] Changing durations in Settings and saving causes Pomodoro screen to refresh
  - [ ] dart analyze reports zero errors and zero warnings
status: pending
