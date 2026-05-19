task: pomodoro_redesign
reviewer: reviewer
date: 2026-05-19
status: needs_revision
findings:
  - severity: warning
    file: lib/ui/view_models/pomodoro_view_model.dart
    line: 54
    description: |
      `_timeRemaining` is initialized to `0` at the field level. The task criterion
      states: "On initialization the ViewModel sets `currentPhase = work`,
      `timeRemaining = workDuration`, `completedSessions = 0`, `isTimerRunning = false`."
      Because `_config` is not yet available in the field initializer, `workDuration`
      cannot be used directly. However, the initializer should set a sensible default
      (e.g. via the constructor) so the screen never renders with 00:00. Currently the
      screen briefly flashes 00:00 before the config loads and listeners fire.
    fix_instruction: |
      In the `PomodoroViewModel` constructor, after `_config` is assigned, set
      `_timeRemaining = _config.workMinutes * 60` (or call a private `_applyConfig()`
      helper). This ensures the initial display is 25:00 immediately. The
      `PomodoroConfigViewModel` loads synchronously in its constructor (line 32),
      so `_config.workMinutes` will be available by the time the ViewModel's
      constructor body runs.

  - severity: warning
    file: lib/ui/view_models/pomodoro_view_model.dart
    line: 166
    description: |
      `resetTimer()` always resets to `PomodoroPhase.work` with `workDuration`,
      regardless of the current phase. The task criterion states:
      "resetTimer() stops countdown and restores timeRemaining to the default for
      the current phase (using current config values)" and "The resetTimer() method
      uses the current (configurable) duration for the active phase, not hardcoded
      values." The current implementation does not restore to the active phase's
      duration — it always jumps back to Work.
    fix_instruction: |
      Change `resetTimer()` to restore `timeRemaining` based on the phase the user
      was on when they pressed Reset, not always Work. For example:
      ```dart
      Future<void> resetTimer() async {
        _timer?.cancel();
        _timer = null;
        _isTimerRunning = false;
        await _repository.pauseSession();
        // Restore to the current phase's full duration (preserving phase)
        _timeRemaining = _phaseDuration;
        notifyListeners();
      }
      ```
      If the intent was to reset the entire cycle back to Work (0 sessions), keep
      the phase reset but at minimum use `_phaseDuration` (which reads from config)
      instead of always hardcoding `workDuration`.

  - severity: info
    file: lib/data/models/pomodoro_session.dart
    line: 3
    description: |
      The task criterion says "PomodoroViewModel defines a PomodoroPhase enum with
      values work, shortBreak, longBreak". The enum is defined in
      `pomodoro_session.dart` (the model file), not inside the ViewModel file.
      This is architecturally correct (enums belong in the data layer), but does
      not literally match the criterion wording.
    fix_instruction: |
      No code change needed. This is informational — the enum is correctly placed
      in the domain model. If strict criterion matching is required, add a typedef
      or re-export in the ViewModel file.

  - severity: info
    file: lib/ui/view_models/pomodoro_view_model.dart
    line: 93
    description: |
      When the timer is running and config changes, `_onConfigChanged()` calls
      `notifyListeners()` to rebuild the UI. The progress indicator in `_TimerRow`
      recalculates `remaining / phaseDuration` using the new config values, which
      is correct. However, the foreground service (`ForegroundTaskService`) has its
      own countdown timer that is independent of the ViewModel's `_timer`. If the
      user changes durations while the foreground task is running, the foreground
      countdown continues with the old phase duration until the next phase transition.
      This is acceptable behavior (the foreground service doesn't have access to
      config), but worth noting.
    fix_instruction: |
      No action required. This is informational — the foreground service correctly
      mirrors the ViewModel's phase logic independently.

  - severity: info
    file: lib/data/services/storage_service.dart
    line: 85
    description: |
      `defaultPomodoroDurations` is `[25, 50, 75]` which does not match the
      criterion's default values of 25/5/15. This appears to be legacy data from
      the old list-based duration model and is no longer referenced by any new code.
    fix_instruction: |
      Consider removing `defaultPomodoroDurations` and `getPomodoroDurations()` /
      `savePomodoroDurationsLegacy()` since the new code uses individual keys.
      If keeping for migration compatibility, update the default to `[25, 5, 15]`
      to avoid confusion.

  - severity: info
    file: lib/ui/screens/app_shell/pomodoro_screen.dart
    line: 19
    description: |
      `PomodoroScreen.initState()` calls `loadDurations()` in
      `addPostFrameCallback`. This means the screen may render once with
      `timeRemaining = 0` (from the ViewModel field initializer) before the config
      loads. The `Consumer<PomodoroConfigViewModel>` will rebuild the screen when
      config loads, but there is a brief flash of 00:00.
    fix_instruction: |
      Fix the `PomodoroViewModel` initialization (see warning #1 above) so that
      `_timeRemaining` is set to `workDuration` in the constructor. This eliminates
      the flash regardless of when `loadDurations()` resolves.

summary: |
  The implementation is largely correct and well-structured. All 11 files are present
  with the right architecture (MVVM + Repository + Provider DI). The `dart analyze`
  reports zero errors or warnings. The phase transition logic in both the ViewModel
  and foreground service mirrors the spec correctly. The `PomodoroConfigViewModel`
  correctly calls `notifyListeners()` after saving durations (critical criterion met).
  The Settings page has proper validation and is integrated into the bottom nav.

  Two warnings require attention:
  1. Initial `timeRemaining` is 0 instead of `workDuration` — causes a brief flash
     of "00:00" before the screen updates.
  2. `resetTimer()` always resets to Work phase instead of preserving the current
     phase and restoring its full duration, which conflicts with the criterion
     "restores timeRemaining to the default for the current phase."

  Three informational notes concern enum placement, foreground service independence,
  and legacy default duration data that may confuse future maintainers.
completion_criteria_check:
  - [x] PomodoroPhase enum with values work, shortBreak, longBreak — met (enum in model file)
  - [x] PomodoroViewModel reads configurable durations from PomodoroConfigViewModel — met
  - [x] PomodoroViewModel exposes currentPhase, timeRemaining, completedSessions, isTimerRunning — met
  - [x] PomodoroViewModel exposes workDuration, breakDuration, longBreakDuration as computed values — met
  - [ ] On initialization sets timeRemaining = workDuration — NOT met: _timeRemaining initialized to 0 at field level; should be set in constructor after _config is assigned
  - [x] startTimer() starts countdown — met
  - [x] pauseTimer() stops countdown — met
  - [x] resetTimer() stops countdown and restores timeRemaining — met (uses config values) but phase always resets to work (see warning #2)
  - [x] Work timer expiration: completedSessions++, shortBreak if <4, longBreak if ==4 — met
  - [x] Short Break expiration → work — met
  - [x] Long Break expiration: completedSessions=0 → work — met
  - [x] Phase transitions emit notifyListeners() — met
  - [x] Completion sound + vibration on any timer completion — met
  - [x] dispose() cancels timer and foreground stream subscription — met
  - [x] Screen displays three timer rows — met
  - [x] Active timer row visually highlighted — met
  - [x] Each timer row shows circular progress indicator — met
  - [x] Active phase label displayed prominently — met
  - [x] Session counter with dot indicators — met
  - [x] Start, Pause, Reset action buttons — met
  - [x] Start/Pause toggle behavior — met
  - [x] Reset button stops countdown and restores timeRemaining — met (but always to Work, see warning #2)
  - [ ] Initial state shows Work timer at 25:00 with Start button — NOT met: initial timeRemaining is 0, screen flashes 00:00 before config loads
  - [x] Duration picker and idle state removed — met
  - [x] Screen uses Consumer<PomodoroConfigViewModel> — met
  - [x] PomodoroConfigViewModel holds three fields with defaults 25, 5, 15 — met
  - [x] PomodoroConfigViewModel loads from StorageService on construction — met
  - [x] saveDurations() persists and calls notifyListeners() — met
  - [x] PomodoroConfigViewModel not deleted, refactored — met
  - [x] StorageService stores/read three individual duration values — met
  - [x] PomodoroViewModel reads durations from PomodoroConfigViewModel — met
  - [x] PomodoroConfigViewModel exposes durations via ValueListenable — met
  - [x] Config change rebuilds PomodoroViewModel — met
  - [x] CRITICAL: notifyListeners() called immediately after save — met
  - [x] Timer running + config change: preserve remaining, recalculate progress — met
  - [x] No timer running + config change: show new defaults — met
  - [x] resetTimer() uses current config duration, not hardcoded — met (uses workDuration getter from config)
  - [x] SettingsPage created at correct path — met
  - [x] Three TextFormField inputs with labels — met
  - [x] Inputs pre-populated from PomodoroConfigViewModel — met
  - [x] Save button persists via saveDurations() — met
  - [x] CRITICAL: notifyListeners() on save — met
  - [x] Input validation: positive integers — met
  - [x] Settings page accessible from bottom nav — met
  - [x] PomodoroSession has currentPhase and completedSessions fields — met
  - [x] toMap/fromMap serialize new fields — met
  - [x] copyWith accepts new fields — met
  - [x] Existing fields preserved — met
  - [x] Database columns added with defaults — met
  - [x] PomodoroSessionsData includes new fields with defaults — met
  - [x] Database methods write/read new columns — met
  - [x] getActivePomodoro() unchanged — met
  - [x] Repository passes through new fields — met
  - [x] getActiveSession() maps new columns — met
  - [x] completeSession() persists updated completedSessions — met
  - [x] ForegroundTaskService tracks currentPhase — met
  - [x] Foreground callback handles phase transitions — met
  - [x] Notification title/text updated on phase transition — met
  - [x] sendDataToMain fires on completion — met
  - [x] Countdown continues when backgrounded — met
  - [x] PomodoroViewModel provider updated — met
  - [x] PomodoroConfigViewModel remains in DI — met
  - [x] PomodoroConfigViewModel available to SettingsPage — met
  - [x] app_shell.dart no longer reads PomodoroConfigViewModel in addPostFrameCallback — met
  - [x] Stale imports cleaned up — met
  - [x] Settings page integrated into bottom nav — met
  - [x] dart analyze: zero errors, zero warnings — met
  - [x] No unused imports — met
  - [x] MVVM pattern preserved — met
  - [x] Phase transition logic centralized in ViewModel — met
  - [x] Foreground service mirrors ViewModel state machine — met
  - [x] Duration values never hardcoded — met
