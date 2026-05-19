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

## Phase 4 — Pomodoro Break Timer Fix

### Task: `pomodoro_break_timer_fix`

**Status**: Completed — reviewer approved all 7 criteria

#### Bug: Short Break timer showed 00:00 and stopped after Work phase completed

**Root cause**: Three issues in the phase transition flow:
1. `_onPhaseComplete()` canceled `_timer` but never called `_startTimer()` to restart countdown for the new phase
2. Foreground stream listener overwrote `_breakRemaining` with stale `0` after Work phase finished
3. Foreground callback's `remaining` stayed `<= 0`, causing repeated `pomodoro_complete` events

**Fixes applied**:
1. Added `_startTimer()` call in `_onPhaseComplete()` after phase transition (`pomodoro_view_model.dart:283`)
2. Added `if (seconds <= 0) return;` guard in foreground stream listener (`pomodoro_view_model.dart:94`)
3. Reset `remaining = newPhaseDuration` in foreground callback after phase transition (`foreground_task.dart:138-152`)
4. Removed DI dependency — replaced `PomodoroConfigViewModel()` with default values in foreground task (`foreground_task.dart:38`)

**Verification**: `dart analyze` — zero errors, zero warnings. Reviewer approved all 7 completion criteria.

## Phase 5 — Per-Timer Color Customization

### Task: `timer_color_customization`

**Status**: Completed — reviewer approved all 13 criteria

#### Feature: Per-timer color customization for Work, Short Break, Long Break timers

**Changes (4 files, no new files):**

| File | Change |
|------|--------|
| `lib/ui/view_models/pomodoro_config_view_model.dart` | Added `workColor`, `breakColor`, `longBreakColor` to `PomodoroDurations` (default `null`); added `setColors()` method that calls `notifyListeners()`; added `saveTimerColors()`, color getters, load in constructor |
| `lib/data/services/storage_service.dart` | Added 3 color keys (`birdle_pomodoro_work_color`, `birdle_pomodoro_break_color`, `birdle_pomodoro_long_break_color`); added getter/setter methods; colors stored as hex strings |
| `lib/ui/screens/app_shell/pomodoro_screen.dart` | Added `color` parameter to `_TimerRow`; uses custom color for label text, CircularProgressIndicator, and time text; falls back to theme primary when `null` |
| `lib/ui/screens/settings/settings_page.dart` | Added "Timer Colors" section with 3 swatches + `ColorPickerDialog`; increased top padding from `EdgeInsets.all(16)` to `EdgeInsets.fromLTRB(16, 24, 16, 16)` |

**Color propagation:** `PomodoroDurations.setColors()` → `notifyListeners()` → `PomodoroConfigViewModel` → `PomodoroScreen` via existing `Consumer` pattern.

**Verification:** `dart analyze` — zero errors, zero warnings. Reviewer approved all 13 completion criteria after 1 revision (added `setColors()` to `PomodoroDurations` to properly notify listeners on color change).

## Phase 6 — Pomodoro Reset Bug Fix

### Task: `pomodoro_full_reset`

**Status**: Completed — reviewer approved all 8 criteria

#### Bug: Reset button only reset the current phase, not the entire pomodoro cycle

**Root cause:** `resetTimer()` in `PomodoroViewModel` was designed as a "reset current phase only" button. It never changed `_currentPhase` or `_completedSessions`, leaving the pomodoro stuck on whatever phase it was in (Short Break, Long Break) with the dot counter intact. The Settings → Save workaround worked because `_onConfigChanged()` accidentally triggered a full reset in the idle branch.

**Fix (2 files):**

| File | Change |
|------|--------|
| `lib/ui/view_models/pomodoro_view_model.dart` | Rewrote `resetTimer()`: unconditionally sets `_currentPhase = PomodoroPhase.work`, resets all remaining times to full duration, resets `_completedSessions = 0`, deletes active DB session |
| `lib/data/repositories/pomodoro_repository.dart` | Added `deleteActiveSession()` method: stops foreground task, fetches active session, calls `_db.deletePomodoroSession()` |

**What is NOT reset (intentionally):** Timer color customizations and config durations — these are user preferences, not session state.

**Verification:** `dart analyze` — zero errors, zero warnings. Reviewer approved all 8 completion criteria.

## Phase 4 — Item Alarm Cancellation

### Task: `fix_item_alarm_cancellation`

**Status**: Completed — reviewer approved all 6 criteria

#### Feature: Remove item alarms + cancel on completion

**Changes (6 files):**

| File | Change |
|------|--------|
| `lib/ui/widgets/alarm_picker_dialog.dart` | Added sealed `AlarmPickerResult` type (`AlarmSet`/`AlarmRemoved`/`AlarmDismissed`); added "Clear" button visible only when `initialAlarm != null` |
| `lib/ui/screens/item_detail_page.dart` | Updated alarm picker handler for all 3 result variants; added long-press gesture on alarm icon with confirmation dialog to quickly remove an alarm |
| `lib/ui/view_models/item_detail_view_model.dart` | `updateItemAlarm()` now cancels the old alarm before setting a new one, and schedules the new alarm after DB update |
| `lib/data/repositories/item_repository.dart` | `updateItem()` detects alarm removal (`wasAlarmSet`) and cancels scheduled notification; added public `cancelAlarm`/`scheduleAlarm` wrappers; `reRegisterAllAlarms` skips completed items |
| `lib/data/services/database.dart` | `getPendingAlarms` query now filters `completed = 0` |
| `lib/data/services/alarm_service.dart` | Added defense-in-depth `completed == 1` guard in `reRegisterAllAlarms` |

**Completion criteria:** All 6 met — clear/remove action, null alarm persistence, cancel-before-sync, cancel on completion, no re-registration, `dart analyze` passes.
