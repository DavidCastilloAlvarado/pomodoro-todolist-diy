task: fix_pomodoro_bugs
reviewer: reviewer
date: 2026-05-18
status: approved
findings:
  - severity: info
    file: lib/data/services/foreground_task.dart
    line: 13
    description: >
      _currentSession field is retained but only used by the timer loop in
      startPomodoroTask(). This is fine since the timer still needs it to
      track the active session state. No issue.
  - severity: info
    file: lib/ui/screens/app_shell/settings_view.dart
    line: 170
    description: >
      _customController is a final field initialized inline. This is correct
      — it avoids the "non-const field initializer" issue that would arise
      with 'final TextEditingController = TextEditingController()' at class
      scope in a State class. No issue.
completion_criteria_check:
  - [x] No notification rings/fires when starting a pomodoro — met: _notificationService field and import removed from foreground_task.dart; timer loop no longer calls _updateNotification() or _notificationService.showNotification()
  - [x] Notifications continue to update normally after pause and resume — met: only FlutterForegroundTask.updateService() updates the notification text; no duplicate sound notifications remain
  - [x] Pomodoro screen shows user's custom durations from Settings (falls back to defaults if none set) — met: _durations loaded from StorageService().getPomodoroDurations() with fallback to defaultPomodoroDurations; chips rendered from _durations
  - [x] Settings duration picker supports custom number input (e.g., 1, 2, 3 minutes) alongside preset chips — met: TextFormField with keyboardType TextInputType.number added; _useCustom flag tracks selection mode; Add button checks _useCustom and parses text field value
  - [x] dart analyze passes with zero errors — met: "No issues found!"
summary: |
  All five completion criteria are met. The builder correctly:

  1. Removed the duplicate `_notificationService.showNotification()` calls
     from the main-isolate timer in `foreground_task.dart`, eliminating the
     "rings as crazy" bug. The foreground service's own
     `FlutterForegroundTask.updateService()` handles silent countdown
     updates.

  2. Fixed pause/resume notification continuity by removing the timer-based
     notification source entirely — pause/resume no longer affect notification
     delivery since only the foreground service manages it.

  3. Wired `pomodoro_screen.dart` to read custom durations from
     `StorageService().getPomodoroDurations()` with a fallback to
     `defaultPomodoroDurations`, and renders chips from that list.

  4. Added a `TextFormField` to `_DurationPickerDialog` in
     `settings_view.dart` alongside the preset chips, with `_useCustom`
     tracking mode and proper `dispose()` cleanup.

  `dart analyze` passes with zero errors. No issues found.