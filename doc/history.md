# Development History

## Phase 6 — Pomodoro Tab Redesign

### Task: `pomodoro_redesign`

**Status**: In progress

#### Implementation (completed)
- Replaced single-timer Pomodoro screen with classic Pomodoro technique (Work/Short Break/Long Break)
- Three simultaneous timer displays with circular progress indicators
- Phase-based state machine with automatic transitions
- Configurable durations via Settings page (workMinutes, breakMinutes, longBreakMinutes)
- `PomodoroConfigViewModel` refactored (not deleted) — exposes `ValueListenable` for config changes
- `PomodoroScreen` uses `Consumer<PomodoroConfigViewModel>` to listen to config changes
- `notifyListeners()` called immediately after any duration save — prevents stale values
- New `SettingsPage` with three duration inputs + validation
- `PomodoroSession` extended with `currentPhase` and `completedSessions`
- Database schema updated with `current_phase` and `completed_sessions` columns
- Foreground service updated to track phase transitions
- `dart analyze`: zero errors, zero warnings

#### Bug Fixes
1. **All timers showed the same value** — Fixed by replacing single `_timeRemaining` with per-phase fields (`_workRemaining`, `_breakRemaining`, `_longBreakRemaining`). Each timer row receives its own remaining value from the ViewModel.
2. **Start button did nothing** — Fixed by `_initDefaults()` in constructor setting all phases to full durations (was `int _timeRemaining = 0`). The countdown check `_phaseRemaining > 0` now passes.
3. **resetTimer() always reset to Work** — Fixed by switching to reset the CURRENT phase to its full duration.

#### Review Findings
- All critical criteria met
- `notifyListeners()` called immediately after config save (CRITICAL)
- All durations from `PomodoroConfigViewModel` — no hardcoded values
- `dart analyze`: zero errors, zero warnings

### Bug Fix Task: `pomodoro_bugfixes`

**Status**: Completed — all three critical bugs fixed

#### Bug 1: Database migration never runs (version 2, migration only for `oldVersion < 2`)
- **Root cause**: Database was at version 2. `_upgradeDb` only ran for `oldVersion < 2`, so the `current_phase` and `completed_sessions` columns were never added to existing databases. `startTimer()` crashed with `table pomodoro_sessions has no column named current_phase`.
- **Fix**: Bumped version to `3`, added `if (oldVersion < 3)` migration guard in `_upgradeDb`.

#### Bug 2: `_durations` is `late` + async-initialized → breaks show 00:00
- **Root cause**: `late PomodoroDurations _durations` had no sync initializer. `_loadDurations()` was fire-and-forget async. When `PomodoroViewModel._initDefaults()` ran in the constructor, it tried to read `_config.breakMinutes` which accessed the uninitialized `_durations`, throwing `LateInitializationError` silently.
- **Fix**: Changed to `final PomodoroDurations _durations = PomodoroDurations(workMinutes: 25, breakMinutes: 5, longBreakMinutes: 15)` — defaults available immediately.

#### Bug 3: `PomodoroDurations` fields are `final` → listener detachment on config save
- **Root cause**: `PomodoroDurations` had `final` fields. `saveDurations()` created a **new** instance, orphaning the listener `PomodoroViewModel` attached to the old instance.
- **Fix**: Made fields mutable, added `update()` method, `saveDurations()` now calls `_durations.update()` in place — listener stays attached.

- `dart analyze`: zero errors, zero warnings
