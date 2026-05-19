task: fix_item_alarm_cancellation
reviewer: reviewer
date: 2026-05-19
status: approved
findings:
  - severity: info
    file: lib/data/models/todo_item.dart
    line: 117
    description: copyWith with alarm: null silently keeps the old alarm (alarm ?? this.alarm). This is a latent bug — callers expecting to clear the alarm via copyWith(alarm: null) will not get the expected result. Currently, updateItemAlarm() in the ViewModel cancels the alarm via repository.cancelAlarm() *before* calling copyWith(alarm: null), so the overall alarm removal flow still works. However, any future caller using copyWith(alarm: null) to clear the alarm will be silently broken.
    fix_instruction: Change line 117 from `alarm: alarm ?? this.alarm,` to `alarm: alarm ??= this.alarm,` (or use a sentinel value like AlarmInfo.unset) so that explicitly passing null actually sets the alarm to null.
  - severity: info
    file: lib/data/repositories/item_repository.dart
    line: 54
    description: updateItem() in the repository correctly detects alarm removal via the wasAlarmSet flag (line 56) and cancels the alarm (line 73). The alarm persistence path (alarmDay/alarmHour/alarmMinute set to null via nullable cascade on lines 63-65) works correctly because the TodoItemsData object is built fresh from the passed TodoItem, which carries the correct null values.
    fix_instruction: No fix needed — this is an informational note confirming the alarm removal path is correct.

summary: |
  All six completion criteria are met:

  1. **Clear/remove action exposed in UI** — The AlarmPickerDialog shows a "Clear" button when initialAlarm is non-null (alarm_picker_dialog.dart:194-198). The ItemRow also supports long-press on the alarm icon to remove it (item_detail_page.dart:321-351). Using either path calls updateItemAlarm(itemId, null), which cancels the alarm and rebuilds the UI to show the item no longer has one.

  2. **Item update path supports null alarm** — The updateItemAlarm() ViewModel method (item_detail_view_model.dart:80-98) cancels the existing alarm via repository.cancelAlarm() before persisting the updated item with alarm: null. The repository's updateItem() correctly writes null alarm_day/alarm_hour/alarm_minute to the database via nullable cascade (item.alarm?.day.index etc.). The wasAlarmSet flag (line 56) ensures the old scheduled notification is cancelled.

  3. **Alarm cancellation before state sync** — Both the ViewModel (cancelAlarm before updateItem) and the repository (wasAlarmSet detection in updateItem) cancel the scheduled notification before the database update completes, keeping the final state in sync.

  4. **Completed items cancel alarm immediately** — toggleCompleted() in item_repository.dart (line 108-110) calls _alarm.cancelAlarm(itemId) when the item's previous completed state was false.

  5. **Completed items don't re-register alarms** — getPendingAlarms() in database.dart (line 317) filters with `completed = 0`. Both reRegisterAllAlarms() implementations (repository.dart:132 and alarm_service.dart:231) additionally skip items where completed == 1.

  6. **dart analyze passes** — Confirmed: "No issues found!"

  Two info-level findings are noted for future improvement (copyWith null-safety). No critical or warning findings.
completion_criteria_check:
  - [x] Criterion 1 — met: Clear button shown when alarm exists; UI updates after removal via notifyListeners()
  - [x] Criterion 2 — met: updateItemAlarm passes null to repository; database writes null alarm fields; wasAlarmSet flag triggers cancel
  - [x] Criterion 3 — met: cancelAlarm called before database update in both ViewModel and repository layers
  - [x] Criterion 4 — met: toggleCompleted cancels alarm when item transitions to completed
  - [x] Criterion 5 — met: getPendingAlarms filters completed = 0; reRegisterAllAlarms skips completed items in both layers
  - [x] Criterion 6 — met: dart analyze reports no issues
