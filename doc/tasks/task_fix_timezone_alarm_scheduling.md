name: fix_timezone_alarm_scheduling
phase: 4
description: |
  Fix the timezone-related alarm scheduling bug where alarms set for times earlier than
  the current local time are rejected as "in the past".

  **Evidence from logs**:
  ```
  AlarmService: Scheduling alarm for "ghhjj" — day: DayOfWeek.sunday, time: 0:44
  NotificationService: Scheduling notification at 2026-05-17 00:44:00.000Z
  Failed: Must be a date in the future
  ```

  The alarm for 00:44 is rejected because the current time is already past 00:44.
  Alarms set 5+ hours ahead succeed because they're still in the future.

  **Root cause**:
  1. `alarm_service.dart` lacks a final validation guard after computing `alarmTime`.
     When the computed time is in the past, it should advance to the next occurrence.
  2. `scheduleDailyNotification()` uses `isAfter(now) || isAtSameMomentAs(now)` which
     fails at microsecond granularity. Replace with `!isBefore(now)`.

  **Fix**:
  1. In `alarm_service.dart` — add a final guard: after computing `alarmTime`, check
     `if (alarmTime.isBefore(now))` and advance by 7 days if needed.
  2. In `notification_service.dart` `scheduleDailyNotification()` — replace
     `isAfter(now) || isAtSameMomentAs(now)` with `!isBefore(now)` to fix microsecond
     comparison issues. Ensure when the time has passed, it schedules for tomorrow.

files:
  - lib/data/services/alarm_service.dart
  - lib/data/services/notification_service.dart

completion_criteria:
  - [ ] `alarm_service.dart` has a guard: if computed `alarmTime` is before `now`, advance to next week
  - [ ] `scheduleDailyNotification()` comparison uses `!isBefore(now)` and schedules for tomorrow when time has passed
  - [ ] Alarms set for near-future times (minutes/hours ahead) schedule successfully
  - [ ] Alarms set for far-future times still work
  - [ ] `dart analyze` passes cleanly (no new errors or warnings)

status: pending
