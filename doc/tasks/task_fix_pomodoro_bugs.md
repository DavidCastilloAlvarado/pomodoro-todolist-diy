name: fix_pomodoro_bugs
phase: 2
description: >
  Fix three pomodoro bugs: (1) notification rings "as crazy" on Start because
  the main-isolate timer fires a new sound notification every second, (2)
  pause/resume breaks notifications due to the same root cause, and
  (3) custom durations set in Settings don't appear on the Pomodoro screen
  and the Settings duration picker lacks custom number input.
files:
  - lib/data/services/foreground_task.dart
  - lib/ui/screens/app_shell/pomodoro_screen.dart
  - lib/ui/screens/app_shell/settings_view.dart
completion_criteria:
  - [ ] No notification rings/fires when starting a pomodoro (notification is silent, only shows countdown)
  - [ ] Notifications continue to update normally after pause and resume
  - [ ] Pomodoro screen shows user's custom durations from Settings (falls back to defaults if none set)
  - [ ] Settings duration picker supports custom number input (e.g., 1, 2, 3 minutes) alongside preset chips
  - [ ] dart analyze passes with zero errors

---

## Action Plan

### File 1: `lib/data/services/foreground_task.dart`

**Bug 1 & 2 fix — remove duplicate sound notifications from the main-isolate timer.**

The main-isolate timer (line 41–56) calls `_updateNotification()` every second,
which in turn calls `_notificationService.showNotification()` — creating a NEW
notification with `playSound: true` every second. This is the root cause of
"rings as crazy" on Start and broken notifications on pause/resume.

**Changes:**

1. **Remove the `_updateNotification()` call from the timer loop** (line 46).
   Delete this line:
   ```dart
   _updateNotification(_currentSession!.itemTitle, remaining.inSeconds);
   ```
   The foreground service's own notification (updated via
   `FlutterForegroundTask.updateService()` in `pomodoroTaskCallback`) is
   sufficient for showing the countdown.

2. **Remove the completion notification from the timer** (lines 49–53).
   Delete this block:
   ```dart
   if (remaining.inSeconds <= 0) {
     stopPomodoroTask();
     _notificationService.showNotification(
       'Pomodoro Complete!',
       'Session for ${_currentSession!.itemTitle} is done.',
     );
   }
   ```
   The foreground service already sends `{'type': 'pomodoro_complete'}` via
   `FlutterForegroundTask.sendDataToMain()` and the `PomodoroViewModel` in the
   main isolate handles sound + vibration from that signal.

3. **Remove the unused `_updateNotification` method** (lines 65–70) since it
   is no longer called from anywhere.

4. **Remove the unused `_notificationService` field** (line 12) and its import
   of `notification_service.dart` (line 3) if it is no longer referenced
   elsewhere in this file after the above deletions.

5. **Remove the unused `_currentSession` field** (line 15) if it is no longer
   referenced after removing the timer logic above. If it is still needed for
   other methods, leave it.

### File 2: `lib/ui/screens/app_shell/pomodoro_screen.dart`

**Bug 3a fix — read user's custom durations instead of hardcoded defaults.**

Currently line 73 reads from `StorageService.defaultPomodoroDurations` (the
static `[25, 50, 75]` list) instead of the user's saved custom durations.

**Changes:**

1. **Add a helper to load durations on idle.** Replace the existing `_loadDuration`
   method (lines 23–29) to also load the duration list:
   ```dart
   List<int> _durations = [];

   Future<void> _loadDuration() async {
     final storage = StorageService();
     final storedDurations = storage.getPomodoroDurations();
     setState(() {
       _durations = storedDurations.isNotEmpty
           ? storedDurations
           : List.from(StorageService.defaultPomodoroDurations);
       if (_durations.isNotEmpty) {
         _selectedDuration = _durations.first;
       }
     });
   }
   ```

2. **Update the duration chip generation** (lines 72–87) to use `_durations`
   instead of `StorageService.defaultPomodoroDurations`:
   ```dart
   Wrap(
     spacing: 8,
     runSpacing: 8,
     children: _durations.map((d) {
       final isSelected = d == _selectedDuration;
       return ChoiceChip(
         label: Text('$d'),
         selected: isSelected,
         onSelected: (_) => setState(() => _selectedDuration = d),
       );
     }).toList(),
   ),
   ```

3. **Remove the stale chip fallback** (lines 81–86) that shows the currently
   selected duration when it's not in the default list. Since `_durations`
   now contains the user's actual list, this is no longer needed.

### File 3: `lib/ui/screens/app_shell/settings_view.dart`

**Bug 3b fix — add custom number input to the duration picker dialog.**

The `_DurationPickerDialog` (lines 159–206) only offers preset chips
`[25, 50, 75, 10, 15, 30, 45, 60]` with no way to enter a custom value like
1, 2, or 3 minutes.

**Changes:**

1. **Add a `TextEditingController` and `TextFormField`** to the dialog for
   custom input. Update `_DurationPickerDialogState`:
   ```dart
   class _DurationPickerDialogState extends State<_DurationPickerDialog> {
     int _selected = 25;
     final TextEditingController _customController = TextEditingController();
     bool _useCustom = false;

     @override
     void dispose() {
       _customController.dispose();
       super.dispose();
     }

     @override
     Widget build(BuildContext context) {
       return AlertDialog(
         title: const Text('Add Duration'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text('Choose a duration in minutes:'),
             const SizedBox(height: 12),
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: [25, 50, 75, 10, 15, 30, 45, 60].map((d) {
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
               }).toList(),
             ),
             const SizedBox(height: 12),
             const Text('Or enter a custom value:'),
             const SizedBox(height: 4),
             TextFormField(
               controller: _customController,
               keyboardType: TextInputType.number,
               decoration: const InputDecoration(
                 hintText: 'e.g. 1, 2, 3',
                 border: OutlineInputBorder(),
                 prefixText: '',
               ),
               onSubmitted: (val) {
                 final parsed = int.tryParse(val);
                 if (parsed != null && parsed > 0) {
                   setState(() {
                     _selected = parsed;
                     _useCustom = true;
                   });
                 }
               },
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: const Text('Cancel'),
           ),
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
         ],
       );
     }
   }
   ```

---

## Summary of Bug Fixes

| Bug | Root Cause | Fix |
|---|---|---|
| 1. Rings "as crazy" on Start | Main-isolate timer calls `_notificationService.showNotification()` every second → new sound notification each time | Remove `_updateNotification()` call from timer; rely on foreground service's `updateService()` for silent countdown updates |
| 2. Pause breaks notifications | Pausing cancels the timer → `_updateNotification()` stops firing; resume restarts it but foreground service notification already has `playSound: true` only on creation | Same fix as Bug 1 — eliminates the duplicate notification source entirely |
| 3a. Custom durations not shown | Pomodoro screen reads `StorageService.defaultPomodoroDurations` (hardcoded) instead of user's saved durations | Read from `StorageService().getPomodoroDurations()`, fall back to defaults if empty |
| 3b. No custom number input | Settings dialog only offers preset chips `[25, 50, 75, 10, 15, 30, 45, 60]` | Add `TextFormField` alongside preset chips; user can type any positive integer |
