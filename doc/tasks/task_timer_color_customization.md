name: timer_color_customization
phase: 5
description: Add per-timer color customization for Work, Short Break, and Long Break timers. Persist colors in SharedPreferences, expose color pickers in SettingsPage, and apply custom colors to the PomodoroScreen timer rows (label text, circular progress icon, countdown time text). Also increase top padding in SettingsPage.
files:
  - lib/ui/view_models/pomodoro_config_view_model.dart
  - lib/data/services/storage_service.dart
  - lib/ui/screens/app_shell/pomodoro_screen.dart
  - lib/ui/screens/settings/settings_page.dart
completion_criteria:
  - [ ] `PomodoroDurations` has three new Color properties: `workColor`, `breakColor`, `longBreakColor` (defaulting to `null`)
  - [ ] `PomodoroDurations.notifyListeners()` is called when any color changes
  - [ ] `StorageService` has three new persistent keys: `birdle_pomodoro_work_color`, `birdle_pomodoro_break_color`, `birdle_pomodoro_long_break_color`
  - [ ] `StorageService.getPomodoroWorkColor()` returns `null` when key is absent (falls back to theme default)
  - [ ] `PomodoroConfigViewModel` loads colors from `StorageService` on construction and calls `notifyListeners()`
  - [ ] `PomodoroConfigViewModel.saveTimerColors()` persists all three colors and calls `notifyListeners()`
  - [ ] `PomodoroConfigViewModel` exposes getters: `workColor`, `breakColor`, `longBreakColor`
  - [ ] `PomodoroScreen._TimerRow` receives a `color` parameter and uses it for label text, CircularProgressIndicator, and time text
  - [ ] PomodoroScreen passes `config.workColor` / `config.breakColor` / `config.longBreakColor` to each `_TimerRow` (falls back to theme primary when color is null)
  - [ ] `SettingsPage` has a "Timer Colors" section with three color swatches, each tapping opens `ColorPickerDialog`
  - [ ] Selecting a color in SettingsPage calls `config.saveTimerColors()` and the PomodoroScreen updates in real-time
  - [ ] Top padding of `SettingsPage` is increased (padding changed from `EdgeInsets.all(16)` to `EdgeInsets.fromLTRB(16, 24, 16, 16)` or equivalent)
  - [ ] `dart analyze` passes with no errors
status: pending
