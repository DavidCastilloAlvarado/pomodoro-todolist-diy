task: alarm_timezone_fix
reviewer: reviewer
date: 2026-05-17
status: approved
findings: []
summary: |
  Reviewed the builder changes against the approved task criteria. Notification scheduling now initializes `tz.local` from the device timezone before scheduling, alarm occurrence calculation stays in local wall-clock time for both weekday and daily alarms, past occurrences are rolled forward correctly, and regression coverage was added for the reported Peru UTC-5 case.

  Verification passed with `flutter test test/data/services/alarm_service_test.dart`. `dart analyze` reported only two unrelated pre-existing info-level issues outside the task files, so no new warnings or errors were introduced by this implementation.
completion_criteria_check:
  - [x] `NotificationService` initializes `tz.local` from the device's actual local timezone before scheduling notifications, so scheduled alarm logs no longer show UTC-only `Z` timestamps for local alarms on a non-UTC device.
  - [x] `AlarmService.scheduleAlarm()` treats `item.alarm.time` as a local wall-clock time when computing the next alarm occurrence for both weekday alarms and `DayOfWeek.everyDay` alarms.
  - [x] One-time weekday alarms that would otherwise fall in the past are rolled forward to the next valid future local occurrence instead of being passed to the notification plugin as an invalid past `TZDateTime`.
  - [x] Daily recurring alarms still schedule the next local occurrence correctly when today's selected time is already past, without shifting the intended wall-clock hour because of timezone conversion.
  - [x] Existing recurring behavior is preserved: specific weekdays still schedule the next matching weekday, and `DayOfWeek.everyDay` still schedules daily reminders at the same local clock time.
  - [x] Regression coverage or equivalent verification is added for the reported Peru UTC-5 scenario, demonstrating that scheduling a 01:56 local alarm at 00:54 local produces a future local schedule instead of a rejected past date.
  - [x] `dart analyze` passes without introducing new warnings or errors.
