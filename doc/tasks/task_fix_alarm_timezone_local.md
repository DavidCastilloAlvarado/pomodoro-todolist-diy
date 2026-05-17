name: fix_alarm_timezone_local
phase: 4
description: |
  Fix the alarm scheduling timezone bug where alarms always fail with
  `Invalid argument (scheduledDate): Must be a date in the future`.
  
  **Root cause**: `DateTime.now()` on Android returns **UTC** time, not local time.
  The alarm service uses `now` (UTC) to compute the alarm date, mixing UTC date
  components with local alarm time. This produces a time offset by the device's
  timezone offset (e.g., UTC-5 for Peru).
  
  **Evidence**: User's local time is 00:54 (Peru). Alarm for 01:56 is rejected as
  "in the past" because the computed time is in UTC, not local.
  
  **Fix**: In `alarm_service.dart` `scheduleAlarm()`, change:
    `final now = DateTime.now();`
  to:
    `final now = DateTime.now().toLocal();`
  
  This is a **one-line fix** that makes all date/time comparisons work in local time.

files:
  - lib/data/services/alarm_service.dart

completion_criteria:
  - [ ] `DateTime.now()` changed to `DateTime.now().toLocal()` in `scheduleAlarm()`
  - [ ] Alarms set for near-future times (minutes/hours ahead) schedule successfully
  - [ ] Alarms set for far-future times still work
  - [ ] `dart analyze` passes cleanly (no new errors or warnings)

status: pending
