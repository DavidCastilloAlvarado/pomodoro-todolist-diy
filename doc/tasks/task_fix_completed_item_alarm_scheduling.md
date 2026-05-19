name: fix_completed_item_alarm_scheduling
phase: 4
description: |
  Fix the bug where modifying the alarm on a completed item causes a new alarm
  to be scheduled and fire, despite the item being marked as completed.

  Root cause: Two layers allow this:
  1. **UI layer** (`item_detail_page.dart`): The alarm picker is triggered for all
     items regardless of `completed` state — no guard on the alarm icon tap.
  2. **Repository layer** (`item_repository.dart`): `updateItem()` unconditionally
     calls `scheduleAlarm()` whenever `item.alarm != null`, without checking
     `item.completed`.

  Fix strategy:
  - **UI guard**: Disable the alarm picker (and alarm removal long-press) for
    completed items in `_ItemRow`. Show a subtle hint (e.g. dimmed icon or tooltip).
  - **Repository guard**: In `ItemRepository.updateItem()`, skip alarm scheduling
    when `item.completed == true`. This is the defense-in-depth layer that prevents
    the bug even if the UI is bypassed (e.g. via direct repository calls or future
    refactoring).

files:
  - lib/ui/screens/item_detail_page.dart
  - lib/data/repositories/item_repository.dart
completion_criteria:
  - [ ] Completed items' alarm icon in `_ItemRow` is visually dimmed and non-tappable
  - [ ] Tapping a completed item's alarm icon shows a brief SnackBar: "Alarms are disabled for completed items"
  - [ ] Long-press (alarm removal) on a completed item is disabled
  - [ ] `ItemRepository.updateItem()` skips `_alarm.scheduleAlarm()` when `item.completed == true`
  - [ ] Setting an alarm on a completed item via any code path does not schedule a notification
  - [ ] `dart analyze` passes with no errors or warnings
status: pending
