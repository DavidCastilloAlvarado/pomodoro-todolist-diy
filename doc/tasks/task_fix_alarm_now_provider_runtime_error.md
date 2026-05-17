name: fix_alarm_now_provider_runtime_error
phase: 4
description: |
  Fix the alarm scheduling regression where `AlarmService.scheduleAlarm()` throws
  `type 'Null' is not a subtype of type '() => DateTime' of 'function result'`
  when it calls `_nowProvider()` during alarm scheduling.

  Likely root cause:
  - The `nowProvider` seam introduced for the prior timezone/local-time fix is
    not being normalized safely on every construction path, so a null-valued
    callback can still reach `_nowProvider` and fail at invocation time.
  - The fix must harden `_nowProvider` initialization/invocation without
    regressing the previously approved local wall-clock scheduling behavior for
    weekday and every-day alarms.

  Scope:
  - Ensure `AlarmService` always resolves a non-null current-time provider before
    computing the next alarm occurrence.
  - Preserve the intended local-time occurrence calculation and timezone-aware
    notification scheduling behavior from the previous alarm timezone fix.
  - Add or update regression coverage for the reported runtime exception so the
    scheduling path can be verified without throwing.

files:
  - lib/data/services/alarm_service.dart
  - lib/data/services/notification_service.dart
  - test/data/services/alarm_service_test.dart

completion_criteria:
  - [ ] `AlarmService.scheduleAlarm()` no longer throws the `_nowProvider` null/function mismatch when an item alarm is created or updated through the normal app flow.
  - [ ] `AlarmService` guarantees `_nowProvider` resolves to a valid `DateTime Function()` on every construction path, including the default singleton path used by the app.
  - [ ] Existing local wall-clock behavior is preserved: weekday alarms still schedule the next matching future local occurrence and `DayOfWeek.everyDay` alarms keep the same intended local hour/minute.
  - [ ] Regression coverage verifies the reported scheduling path no longer throws this exception and still computes the next local occurrence correctly.
  - [ ] `dart analyze` passes without introducing new warnings or errors.

status: pending
