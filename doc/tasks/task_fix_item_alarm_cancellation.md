name: fix_item_alarm_cancellation
phase: 4
description: Fix the item alarm lifecycle so users can remove an existing alarm from the item detail UI, alarm removals persist correctly, and marking an item as completed cancels any pending alarm without letting it re-register later.
files:
  - lib/ui/widgets/alarm_picker_dialog.dart
  - lib/ui/screens/item_detail_page.dart
  - lib/ui/view_models/item_detail_view_model.dart
  - lib/data/models/todo_item.dart
  - lib/data/repositories/item_repository.dart
  - lib/data/services/database.dart
completion_criteria:
  - [ ] The item alarm flow exposes a clear/remove action for items that already have an alarm, and using it updates the UI to show that the item no longer has an alarm.
  - [ ] The item update path supports explicitly setting an alarm to null so removing an alarm clears the persisted alarm fields instead of silently keeping the old alarm.
  - [ ] Removing or changing an item alarm cancels any previously scheduled notification for that item before leaving the final scheduled state in sync with the database.
  - [ ] When an item is marked completed, any scheduled alarm for that item is cancelled immediately.
  - [ ] Completed items do not get their cancelled alarms scheduled again during alarm re-registration on app startup.
  - [ ] `dart analyze` passes after the alarm cancellation fixes are implemented.
status: pending
