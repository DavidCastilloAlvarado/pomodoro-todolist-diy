task: fix_pomodoro_config_refresh
reviewer: reviewer
date: 2026-05-18
status: approved
findings: []
completion_criteria_check:
  - [x] PomodoroConfigViewModel created as ChangeNotifier with durations getter and saveDurations() method — met: extends ChangeNotifier, has `List<int> get durations` (line 11) and `saveDurations(List<int>)` (line 25)
  - [x] PomodoroConfigViewModel registered in DI container (ChangeNotifierProvider) — met: import at line 12, provider at lines 78–82 in di_container.dart
  - [x] PomodoroScreen uses Consumer<PomodoroConfigViewModel> for durations (not direct StorageService reads) — met: Consumer at line 64; StorageService import removed
  - [x] SettingsView uses Consumer<PomodoroConfigViewModel> and calls saveDurations() on the ViewModel — met: Consumer at line 114; _saveDurations() calls context.read<PomodoroConfigViewModel>().saveDurations() at line 39
  - [x] Durations updated in Pomodoro tab immediately after saving in Settings (no restart needed) — met: saveDurations() calls notifyListeners() after persistence (line 28), Consumer in PomodoroScreen rebuilds on notification
  - [x] dart analyze passes with zero errors — met: "No issues found!"
summary: |
  All six completion criteria are met. The builder correctly:

  1. Created PomodoroConfigViewModel as a ChangeNotifier that bridges
     StorageService to both UI consumers, with durations getter and
     saveDurations() that persists + notifies listeners.

  2. Registered it in the DI container as a ChangeNotifierProvider,
     wired to StorageService via ctx.read<StorageService>().

  3. Replaced PomodoroScreen's direct StorageService reads with
     Consumer<PomodoroConfigViewModel> — the duration chips now rebuild
     automatically when the ViewModel fires notifyListeners().

  4. Updated SettingsView to use Consumer<PomodoroConfigViewModel> for
     the chip list and calls saveDurations() on the ViewModel instead of
     writing directly to StorageService.

  5. Added loadDurations() call in AppShell's addPostFrameCallback for
     initial load at app startup.

  The fix follows the same MVVM + Provider pattern already established by
  PaletteViewModel → PaletteViewModel.setPalette() → notifyListeners() →
  Consumer<PaletteViewModel>. `dart analyze` passes with zero issues.