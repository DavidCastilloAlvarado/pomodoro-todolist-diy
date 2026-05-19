# Development History

## Phase 1 — Pomodoro Tab + Settings + Background + Sound

**Status: Completed**

**Changes:**
- **Removed** the unused "Search" tab from `AppShell`
- **Added** "Pomodoro" tab with full `PomodoroScreen` (idle/running/paused/completed states, duration picker, Start/Pause/Resume/Cancel)
- **Added** "Settings" tab to bottom nav (initially missed by builder, then corrected)
- **Implemented** `pomodoroTaskCallback` in `ForegroundTaskService` with real `Timer.periodic` countdown — the pomodoro now survives the app being killed/swiped away
- **Wired** `sendDataToMain` from foreground callback → `PomodoroViewModel` for sound/vibration on completion
- **Added** `FlutterForegroundTask.init()` in `main.dart` with `autoRunOnBoot: true`
- **Added** `audioplayers` package + `assets/sounds/complete.wav` fire sound
- **Added** `HapticFeedback.vibrate()` on completion
- **Extended** `StorageService` with pomodoro duration persistence
- **Added** `<service>` and `<receiver>` declarations to `AndroidManifest.xml`

**Files changed:**
- `lib/ui/screens/app_shell/app_shell.dart` — Search→Pomodoro tab, added Settings
- `lib/ui/screens/app_shell/pomodoro_screen.dart` (NEW) — Pomodoro UI
- `lib/ui/screens/app_shell/settings_view.dart` (NEW) — Settings UI
- `lib/data/services/foreground_task.dart` — Implemented callback
- `lib/data/services/storage_service.dart` — Pomodoro duration persistence
- `lib/ui/view_models/pomodoro_view_model.dart` — Foreground stream + sound + vibration
- `lib/main.dart` — `FlutterForegroundTask.init()`
- `pubspec.yaml` — `audioplayers` dependency
- `android/app/src/main/AndroidManifest.xml` — ForegroundService + receivers
- `assets/sounds/complete.wav` (NEW) — completion sound

**Review: Approved** (27/27 criteria met)

---

## Phase 2 — Fix Pomodoro Notification & Duration Bugs

**Status: Completed**

**Changes:**
- **`foreground_task.dart`** — Removed `_notificationService` field and import; removed `_updateNotification()` call from timer loop (was firing a new sound notification every second); removed completion notification block from timer; removed unused `_updateNotification()` method. The foreground service's own `FlutterForegroundTask.updateService()` handles silent countdown updates.
- **`pomodoro_screen.dart`** — Added `_durations` state field; updated `_loadDuration()` to read user's custom durations from `StorageService().getPomodoroDurations()` with fallback to `defaultPomodoroDurations`; updated chip generation to iterate over `_durations`; removed stale fallback chip.
- **`settings_view.dart`** — Added `TextEditingController` + `TextFormField` to `_DurationPickerDialog` for custom number input; added `_useCustom` flag to track selection mode; updated chip selection to clear text field and set `_useCustom = false`; updated "Add" button to check `_useCustom` and parse text field value.

**Review: Approved** (5/5 criteria met)

---

## Phase 3 — Fix Pomodoro Duration Refresh (Settings → Pomodoro)

**Status: Completed**

**Root cause:** `SettingsView` and `PomodoroScreen` both read/write `StorageService` directly with no bridge between them. When Settings saves, PomodoroScreen never knows to reload — it only loads in `initState`.

**Fix:** Created `PomodoroConfigViewModel` as a single shared `ChangeNotifier` registered in DI, following the same pattern already used by `PaletteViewModel` and `ListListViewModel`.

**Changes:**
- **`lib/ui/view_models/pomodoro_config_view_model.dart`** (NEW) — `ChangeNotifier` bridging `StorageService` and both screens. Holds `_durations`, provides `loadDurations()` and `saveDurations()` (persists to storage + calls `notifyListeners()`).
- **`lib/di/di_container.dart`** — Registered `PomodoroConfigViewModel` as `ChangeNotifierProvider` wired to `StorageService`.
- **`lib/ui/screens/app_shell/pomodoro_screen.dart`** — Replaced direct `StorageService` reads with `Consumer<PomodoroConfigViewModel>`. Removed `_durations` state field and `_loadDuration()` method. `initState` calls `context.read<PomodoroConfigViewModel>().loadDurations()`.
- **`lib/ui/screens/app_shell/settings_view.dart`** — Renamed `_customDurations` → `_workingDurations` (local mutable copy for add/remove workflow). Wrapped duration chips in `Consumer<PomodoroConfigViewModel>`. `_saveDurations()` calls `context.read<PomodoroConfigViewModel>().saveDurations(_workingDurations)`.
- **`lib/ui/screens/app_shell/app_shell.dart`** — Added `context.read<PomodoroConfigViewModel>().loadDurations()` in `addPostFrameCallback`.

**Review: Approved** (6/6 criteria met)
