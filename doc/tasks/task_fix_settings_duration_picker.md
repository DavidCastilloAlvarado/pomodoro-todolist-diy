name: fix_settings_duration_picker
phase: 4
description: >
  Fix Settings pomodoro duration picker: remove unnecessary "Save Durations"
  button, fix the dialog to prioritize custom text input over chip selection,
  ensure new durations appear immediately in both Settings and Pomodoro tabs.
files:
  - lib/ui/screens/app_shell/settings_view.dart
completion_criteria:
  - [ ] "Save Durations" button removed from SettingsView
  - [ ] _saveDurations() method removed from _SettingsViewState
  - [ ] Dialog always prioritizes text field input over chip selection
  - [ ] If text field has a valid positive integer, that value is used (even if a chip is also selected)
  - [ ] If text field is empty or invalid, fall back to chip selection
  - [ ] New durations appear immediately in Settings chips (auto-rebuild via Consumer)
  - [ ] New durations appear immediately in Pomodoro tab (auto-rebuild via Consumer)
  - [ ] dart analyze passes with zero errors

---

## Action Plan

### File 1: `lib/ui/screens/app_shell/settings_view.dart`

Three changes in this single file.

---

#### Change 1: Remove `_saveDurations()` method (lines 38–46)

Remove the entire method:

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

It is no longer needed because:
- `PomodoroConfigViewModel.saveDurations()` already calls `notifyListeners()` after persisting
- Both Settings chips and PomodoroScreen chips are wrapped in `Consumer<PomodoroConfigViewModel>` which auto-rebuilds
- The snackbar is unnecessary noise

---

#### Change 2: Remove "Save Durations" button (lines 152–155)

Replace:

```dart
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saveDurations,
              child: const Text('Save Durations'),
            ),
          ],
        );
      },
    );
```

With:

```dart
          ],
        );
      },
    );
```

The `SizedBox(height: 16)` padding before the button is also removed since the button is gone — the ListView ends cleanly after the duration chips section.

---

#### Change 3: Fix `_DurationPickerDialog` "Add" button to prioritize text input

Replace the existing "Add" button (lines 238–250):

```dart
        TextButton(
          onPressed: () {
            if (_useCustom) {
              final parsed = int.tryParse(_customController.text);
              if (parsed != null && parsed > 0) {
                Navigator.of(context).pop(parsed);
              }
            } else {
              Navigator.of(context).pop(_selected);
            }
          },
          child: const Text('Add'),
        ),
```

With:

```dart
        TextButton(
          onPressed: () {
            // Always try text field first — it takes priority over chip selection.
            final parsed = int.tryParse(_customController.text);
            if (parsed != null && parsed > 0) {
              Navigator.of(context).pop(parsed);
            } else {
              // Text field is empty or invalid — fall back to chip selection.
              Navigator.of(context).pop(_selected);
            }
          },
          child: const Text('Add'),
        ),
```

**Why this fixes the bug:** The old logic used `_useCustom` as a gate — it only became `true` when the user pressed Enter in the text field (`onFieldSubmitted`). If the user typed a value and clicked "Add" without pressing Enter, `_useCustom` stayed `false` and the dialog returned `_selected` (the chip value), completely ignoring the typed text. The new logic always tries the text field first and only falls back to the chip if the text is empty or invalid.

**Also remove `_useCustom` state field** (line 176) since it is no longer needed:

Remove:
```dart
  bool _useCustom = false;
```

And remove the `_useCustom` logic from the chip selection handler (line 198) — chips should always be selectable now since the text field takes priority in the "Add" button:

Replace:
```dart
              final isSelected = d == _selected && !_useCustom;
              return ChoiceChip(
                label: Text('$d'),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selected = d;
                  _useCustom = false;
                  _customController.clear();
                }),
              );
```

With:
```dart
              final isSelected = d == _selected;
              return ChoiceChip(
                label: Text('$d'),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selected = d;
                  _customController.clear();
                }),
              );
```

---

## Summary of Bug Fixes

| Bug | Before | After |
|---|---|---|
| Unnecessary "Save Durations" button | Button + snackbar required manual save | Removed — auto-save on add/delete via ViewModel |
| Custom text ignored when clicking "Add" | `_useCustom` only set by Enter key; clicking "Add" without Enter returned chip value | Text field always tried first; chip selection is fallback |
| Durations not visible immediately | N/A (fixed in phase 3 by Consumer wiring) | Consumer<PomodoroConfigViewModel> rebuilds both tabs automatically |
