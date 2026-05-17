name: fix_timezone_initialize_alarm_crash
phase: 4
description: |
  Fix the `LateInitializationError` crash that occurs every time an alarm is set,
  and fix the subsequent `Isolate.resolvePackageUriSync` crash that prevents the app
  from starting.
  
  **Bug 1 — Root cause**: The `timezone` package's `tz.local` is accessed in
  `NotificationService.scheduleNotification()` (line 85) and `scheduleDailyNotification()`
  (line 154), but `initializeTimezone()` is **never called anywhere in the codebase**.
  
  **Bug 2 — Regression**: The previous fix added `import 'package:timezone/standalone.dart'`
  and `await initializeTimeZone()`. This import is **web-only** and crashes on mobile with
  `Unsupported operation: Isolate.resolvePackageUriSync`.
  
  **Correct fix**: 
  1. Remove the `standalone.dart` import (line 4)
  2. Use `await tz.initializeTimezone()` instead of `await initializeTimeZone()`
     — the `tz` import (`package:timezone/timezone.dart` as `tz`) is already present on line 5
  
  The call is idempotent and safe to invoke multiple times.

files:
  - lib/data/services/notification_service.dart

completion_criteria:
  - [ ] `import 'package:timezone/standalone.dart'` removed
  - [ ] `await tz.initializeTimezone()` used (not `initializeTimeZone()` from standalone)
  - [ ] App starts without `Isolate.resolvePackageUriSync` crash
  - [ ] `scheduleNotification()` no longer throws `LateInitializationError`
  - [ ] `scheduleDailyNotification()` no longer throws `LateInitializationError`
  - [ ] `dart analyze` passes cleanly (no new errors or warnings)

status: pending
