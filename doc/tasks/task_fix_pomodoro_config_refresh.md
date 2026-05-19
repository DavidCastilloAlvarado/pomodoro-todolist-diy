name: fix_pomodoro_config_refresh
phase: 3
description: >
  Fix pomodoro duration persistence refresh — durations set in Settings
  must appear in the Pomodoro tab immediately without restarting the app.
  Root cause: SettingsView and PomodoroScreen both read/write StorageService
  directly with no bridge between them. Fix: create PomodoroConfigViewModel
  as a ChangeNotifier that bridges StorageService and both screens, wired
  through Provider so consumers rebuild automatically when durations change.
files:
  - lib/ui/view_models/pomodoro_config_view_model.dart (NEW)
  - lib/di/di_container.dart
  - lib/ui/screens/app_shell/pomodoro_screen.dart
  - lib/ui/screens/app_shell/settings_view.dart
  - lib/ui/screens/app_shell/app_shell.dart
completion_criteria:
  - [ ] PomodoroConfigViewModel created as ChangeNotifier with durations getter and saveDurations() method
  - [ ] PomodoroConfigViewModel registered in DI container (ChangeNotifierProvider)
  - [ ] PomodoroScreen uses Consumer<PomodoroConfigViewModel> for durations (not direct StorageService reads)
  - [ ] SettingsView uses Consumer<PomodoroConfigViewModel> and calls saveDurations() on the ViewModel
  - [ ] Durations updated in Pomodoro tab immediately after saving in Settings (no restart needed)
  - [ ] dart analyze passes with zero errors

---

## Action Plan

### File 1: `lib/ui/view_models/pomodoro_config_view_model.dart` (NEW)

Create this new file. It bridges `StorageService` and both UI consumers:

```dart
import 'package:birdle/data/services/storage_service.dart';
import 'package:flutter/material.dart';

class PomodoroConfigViewModel extends ChangeNotifier {
  PomodoroConfigViewModel({required StorageService storage}) : _storage = storage {
    _loadDurations();
  }

  final StorageService _storage;
  List<int> _durations = [];
  List<int> get durations => List.unmodifiable(_durations);

  Future<void> _loadDurations() async {
    final stored = _storage.getPomodoroDurations();
    _durations = stored.isNotEmpty
        ? stored
        : List.from(StorageService.defaultPomodoroDurations);
    notifyListeners();
  }

  Future<void> loadDurations() async {
    await _loadDurations();
  }

  Future<void> saveDurations(List<int> durations) async {
    await _storage.savePomodoroDurations(durations);
    _durations = List.from(durations);
    notifyListeners();
  }
}
```

Key points:
- Extends `ChangeNotifier` (required for `ChangeNotifierProvider`).
- `_durations` is initialized to `[]` and populated asynchronously in the constructor.
- `durations` getter returns `List.unmodifiable(_durations)` for safety.
- `loadDurations()` is a public method so `AppShell` can trigger a refresh.
- `saveDurations()` persists to storage **and** calls `notifyListeners()` so all consumers rebuild.

---

### File 2: `lib/di/di_container.dart`

Add `PomodoroConfigViewModel` to the `viewModels` list.

**Add import** (after line 12):
```dart
import 'package:birdle/ui/view_models/pomodoro_config_view_model.dart';
```

**Add provider** (after the existing `PomodoroViewModel` entry, before the closing `]` on line 77):
```dart
    ChangeNotifierProvider<PomodoroConfigViewModel>(
      create: (ctx) => PomodoroConfigViewModel(
        storage: ctx.read<StorageService>(),
      ),
    ),
```

The `viewModels` list should now have 4 providers in order: PaletteViewModel, ListListViewModel, PomodoroViewModel, PomodoroConfigViewModel.

---

### File 3: `lib/ui/screens/app_shell/pomodoro_screen.dart`

Replace direct `StorageService` reads with `Consumer<PomodoroConfigViewModel>`.

**Step 3.1 — Remove `_durations` state field and `_loadDuration()` method.**

Remove from `_PomodoroScreenState`:
- Line 16: `List<int> _durations = [];`
- Lines 24–35: the entire `_loadDuration()` method

**Step 3.2 — Remove `StorageService` import.**

Remove line 2: `import 'package:birdle/data/services/storage_service.dart';`

**Step 3.3 — Replace the duration chip generation with `Consumer<PomodoroConfigViewModel>`.**

Replace the `Wrap` (lines 75–86) with:
```dart
                    Consumer<PomodoroConfigViewModel>(
                      builder: (context, config, _) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: config.durations.map((d) {
                            final isSelected = d == _selectedDuration;
                            return ChoiceChip(
                              label: Text('$d'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedDuration = d),
                            );
                          }).toList(),
                        );
                      },
                    ),
```

**Step 3.4 — Initialize `_selectedDuration` from ViewModel durations in `initState`.**

Update `initState` to also trigger a config load:
```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = context.read<PomodoroConfigViewModel>();
      config.loadDurations();
    });
  }
```

---

### File 4: `lib/ui/screens/app_shell/settings_view.dart`

Replace `_customDurations` state with `Consumer<PomodoroConfigViewModel>`.

**Step 4.1 — Remove `_customDurations` state field.**

Remove line 15: `List<int> _customDurations = [25, 50, 75];`

**Step 4.2 — Remove duration loading from `_loadData()`.**

Update `_loadData()` to only load the user name:
```dart
  Future<void> _loadData() async {
    final storage = StorageService();
    final name = storage.getName() ?? 'Not set';
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }
```

**Step 4.3 — Update `_saveDurations()` to use the ViewModel.**

Replace `_saveDurations()`:
```dart
  Future<void> _saveDurations() async {
    final config = context.read<PomodoroConfigViewModel>();
    await config.saveDurations(_customDurations);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pomodoro durations saved')),
      );
    }
  }
```

**Step 4.4 — Add a local `_customDurations` state field for the "add" workflow.**

Since the ViewModel's `durations` getter is unmodifiable, we need a local mutable copy for the "add duration" flow. Add to `_SettingsViewState`:
```dart
  String _userName = '';
  List<int> _workingDurations = [25, 50, 75];
```

Update `_loadData()` to also load durations locally for the working copy:
```dart
  Future<void> _loadData() async {
    final storage = StorageService();
    final name = storage.getName() ?? 'Not set';
    final storedDurations = storage.getPomodoroDurations();
    if (mounted) {
      setState(() {
        _userName = name;
        _workingDurations = storedDurations.isEmpty
            ? List.from(StorageService.defaultPomodoroDurations)
            : storedDurations;
      });
    }
  }
```

Update `_saveDurations()`:
```dart
  Future<void> _saveDurations() async {
    final config = context.read<PomodoroConfigViewModel>();
    await config.saveDurations(_workingDurations);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pomodoro durations saved')),
      );
    }
  }
```

**Step 4.5 — Replace the duration chip section with `Consumer<PomodoroConfigViewModel>`.**

Replace the entire "Pomodoro Durations" section (lines 107–145) with:
```dart
            // ── Pomodoro durations ─────────────────────────────
            const Text(
              'Pomodoro Durations (minutes)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<PomodoroConfigViewModel>(
              builder: (context, config, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...config.durations.map(
                      (d) => Chip(
                        label: Text('$d min'),
                        onDeleted: () {
                          setState(() {
                            _workingDurations.remove(d);
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        showDialog<int>(
                          context: context,
                          builder: (ctx) => _DurationPickerDialog(
                            currentDurations: _workingDurations,
                          ),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              _workingDurations.add(value);
                            });
                          }
                        });
                      },
                    ),
                  ],
                );
              },
            ),
```

**Step 4.6 — Update `_DurationPickerDialog` to accept `_workingDurations`.**

The dialog already receives `currentDurations` as a parameter — no changes needed to the dialog itself. Just ensure the `currentDurations` prop is passed as `_workingDurations` (already done in Step 4.5).

---

### File 5: `lib/ui/screens/app_shell/app_shell.dart`

Trigger a config load when the app starts.

**Step 5.1 — Add import.**

Add after line 7:
```dart
import 'package:birdle/ui/view_models/pomodoro_config_view_model.dart';
```

**Step 5.2 — Add `loadDurations()` call in `initState`.**

Update the `addPostFrameCallback` block (lines 23–26):
```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListListViewModel>().loadLists();
      context.read<PomodoroViewModel>().loadActiveSession();
      context.read<PomodoroConfigViewModel>().loadDurations();
    });
```

---

## Summary of Bug Fix

| Screen | Before (broken) | After (fixed) |
|---|---|---|
| PomodoroScreen | Reads `StorageService().getPomodoroDurations()` in `initState` only | Reads from `Consumer<PomodoroConfigViewModel>` — rebuilds when `notifyListeners()` fires |
| SettingsView | Writes to `StorageService().savePomodoroDurations()` with no broadcast | Calls `config.saveDurations()` which persists **and** calls `notifyListeners()` |
| Bridge | None — two independent `StorageService` instances | `PomodoroConfigViewModel` — single `ChangeNotifier` shared via DI |
