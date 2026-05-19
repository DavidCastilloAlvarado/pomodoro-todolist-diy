task: fix_completed_item_alarm_scheduling
reviewer: reviewer
date: 2026-05-19
status: approved
findings:
  - severity: info
    file: lib/ui/screens/item_detail_page.dart
    line: 362-378
    description: Alarm icon in _ItemRow uses `.withValues(alpha: 0.2)` for completed items, providing a clear visual dimming cue that the alarm is disabled. This is a good UX choice.
  - severity: info
    file: lib/ui/screens/item_detail_page.dart
    line: 320-329
    description: The SnackBar message "Alarms are disabled for completed items" exactly matches the criterion text. Duration of 2 seconds is reasonable. The `onTap` callback is replaced with the SnackBar handler when `item.completed` is true, making the icon non-tappable for alarm scheduling.
  - severity: info
    file: lib/ui/screens/item_detail_page.dart
    line: 330-331
    description: `onLongPress` is set to `null` when `item.completed` is true, correctly disabling alarm removal via long-press.
  - severity: info
    file: lib/data/repositories/item_repository.dart
    line: 69
    description: The guard `if (item.alarm != null && !item.completed)` on line 69 correctly prevents `_alarm.scheduleAlarm()` from being called when the item is completed. This is the defense-in-depth layer specified in the task.
  - severity: info
    file: lib/data/repositories/item_repository.dart
    line: 133
    description: `reRegisterAllAlarms()` also skips completed items (line 133: `if (itemData.completed == 1) continue;`), providing an additional safety net during reboot recovery.
  - severity: info
    file: lib/data/services/alarm_service.dart
    line: 231
    description: `AlarmService.reRegisterAllAlarms()` also skips completed items (line 231), providing a third layer of defense against scheduling alarms for completed items on app startup.

summary: |
  All six completion criteria are met:

  1. **UI dimming + non-tappable**: The alarm icon in `_ItemRow` is visually dimmed (alpha 0.2) for completed items, and the `GestureDetector.onTap` is replaced with a no-op SnackBar handler, making it effectively non-tappable for alarm scheduling.
  2. **SnackBar message**: Tapping the completed item's alarm icon shows the exact SnackBar text "Alarms are disabled for completed items" for 2 seconds.
  3. **Long-press disabled**: `onLongPress` is set to `null` when `item.completed` is true, disabling alarm removal via long-press.
  4. **Repository guard**: `ItemRepository.updateItem()` line 69 checks `!item.completed` before calling `_alarm.scheduleAlarm()`, skipping alarm scheduling for completed items.
  5. **No notification scheduled**: Through all code paths — UI guard in `_ItemRow`, repository guard in `updateItem()`, and reboot recovery in both `ItemRepository.reRegisterAllAlarms()` and `AlarmService.reRegisterAllAlarms()` — completed items are skipped and no notification is scheduled.
  6. **dart analyze**: Passes with zero errors and zero warnings.

  Defense-in-depth is well-implemented: three independent layers (UI, repository, alarm service) all guard against scheduling alarms for completed items.
completion_criteria_check:
  - [x] Completed items' alarm icon in `_ItemRow` is visually dimmed and non-tappable — met
  - [x] Tapping a completed item's alarm icon shows a brief SnackBar: "Alarms are disabled for completed items" — met
  - [x] Long-press (alarm removal) on a completed item is disabled — met
  - [x] `ItemRepository.updateItem()` skips `_alarm.scheduleAlarm()` when `item.completed == true` — met
  - [x] Setting an alarm on a completed item via any code path does not schedule a notification — met
  - [x] `dart analyze` passes with no errors or warnings — met
