task: fix_alarm_now_provider_runtime_error
reviewer: reviewer
date: 2026-05-17
status: approved
findings: []
summary: |
  The implementation now satisfies the task criteria. `AlarmService` normalizes `_nowProvider` to a non-nullable `DateTime Function()` on every construction path, preserves the prior local wall-clock scheduling behavior for weekday and every-day alarms, and the regression coverage plus independent verification (`flutter test test/data/services/alarm_service_test.dart` and `dart analyze`) both pass.
completion_criteria_check:
  - "[x] `AlarmService.scheduleAlarm()` no longer throws the `_nowProvider` null/function mismatch when an item alarm is created or updated through the normal app flow."
  - "[x] `AlarmService` guarantees `_nowProvider` resolves to a valid `DateTime Function()` on every construction path, including the default singleton path used by the app."
  - "[x] Existing local wall-clock behavior is preserved: weekday alarms still schedule the next matching future local occurrence and `DayOfWeek.everyDay` alarms keep the same intended local hour/minute."
  - "[x] Regression coverage verifies the reported scheduling path no longer throws this exception and still computes the next local occurrence correctly."
  - "[x] `dart analyze` passes without introducing new warnings or errors."
