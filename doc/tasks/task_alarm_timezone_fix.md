name: alarm_timezone_fix
phase: 4
description: |
  Fix the alarm scheduling bug where a user-selected alarm time is treated with the
  wrong timezone basis before it reaches `flutter_local_notifications`, causing
  valid future alarms to be rejected as past dates.

  Bug summary:
  - User-selected `item.alarm.time` is intended to represent local wall-clock time.
  - Current logs show notifications being scheduled as `...Z`, which indicates the
    timezone package is still using UTC instead of the device timezone.
  - On a UTC-5 device (Peru), scheduling an alarm for 01:56 while the local time is
    00:54 can become 01:56Z, which is 20:56 local on the previous day and therefore
    fails the plugin's future-date validation.

  Proposed fix scope:
  - Normalize alarm occurrence calculations in `AlarmService.scheduleAlarm()` around
    local wall-clock time only.
  - Initialize the timezone layer with the device's actual local timezone before
    creating any `TZDateTime` values for notifications.
  - Ensure both one-time weekday alarms and daily recurring alarms continue to roll
    forward to the next valid local occurrence when the selected time for today has
    already passed.

files:
  - pubspec.yaml
  - lib/data/services/alarm_service.dart
  - lib/data/services/notification_service.dart
  - test/data/services/alarm_service_test.dart

completion_criteria:
  - [ ] `NotificationService` initializes `tz.local` from the device's actual local timezone before scheduling notifications, so scheduled alarm logs no longer show UTC-only `Z` timestamps for local alarms on a non-UTC device.
  - [ ] `AlarmService.scheduleAlarm()` treats `item.alarm.time` as a local wall-clock time when computing the next alarm occurrence for both weekday alarms and `DayOfWeek.everyDay` alarms.
  - [ ] One-time weekday alarms that would otherwise fall in the past are rolled forward to the next valid future local occurrence instead of being passed to the notification plugin as an invalid past `TZDateTime`.
  - [ ] Daily recurring alarms still schedule the next local occurrence correctly when today's selected time is already past, without shifting the intended wall-clock hour because of timezone conversion.
  - [ ] Existing recurring behavior is preserved: specific weekdays still schedule the next matching weekday, and `DayOfWeek.everyDay` still schedules daily reminders at the same local clock time.
  - [ ] Regression coverage or equivalent verification is added for the reported Peru UTC-5 scenario, demonstrating that scheduling a 01:56 local alarm at 00:54 local produces a future local schedule instead of a rejected past date.
  - [ ] `dart analyze` passes without introducing new warnings or errors.

status: pending
