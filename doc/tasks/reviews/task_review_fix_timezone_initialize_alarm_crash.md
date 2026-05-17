task: fix_timezone_initialize_alarm_crash
reviewer: reviewer
date: 2026-05-17T00:00:00Z
status: approved
findings:
  - severity: info
    file: lib/data/services/notification_service.dart
    line: 4
    description: The `standalone.dart` import was successfully replaced with `timezone/data/latest_all.dart` as `tz_data`. This is the correct cross-platform approach — `latest_all.dart` works on both mobile and web without triggering `Isolate.resolvePackageUriSync`.
  - severity: info
    file: lib/data/services/notification_service.dart
    line: 19
    description: `tz_data.initializeTimeZones()` is called in `init()` before any `tz.local` access. This ensures timezone data is loaded before `scheduleNotification()` (line 87) or `scheduleDailyNotification()` (line 155) access `tz.local`, preventing `LateInitializationError`.
  - severity: info
    file: lib/data/services/notification_service.dart
    line: 47
    description: `AndroidNotificationDetails` in `showNotification()` retains all required properties: channelId, channelName, channelDescription, importance, priority, showWhen. No `sound` parameter means Android uses its system default notification sound — this is the correct fix for the `invalid_sound` error.
  - severity: info
    file: lib/data/services/notification_service.dart
    line: 97
    description: `AndroidNotificationDetails` in `scheduleNotification()` retains all required properties. Same reasoning as above — removing the invalid `RawResourceAndroidNotificationSound('default')` fixes the `invalid_sound` error while preserving notification functionality.
  - severity: info
    file: lib/data/services/notification_service.dart
    line: 165
    description: `AndroidNotificationDetails` in `scheduleDailyNotification()` retains all required properties. Same reasoning as above.
summary: |
  The fix correctly addresses both bugs:
  
  **Bug 1 (timezone crash):** The `standalone.dart` import was removed and replaced with `timezone/data/latest_all.dart` as `tz_data`. The `init()` method calls `tz_data.initializeTimeZones()` before any `tz.local` access, preventing `LateInitializationError` in both `scheduleNotification()` and `scheduleDailyNotification()`.
  
  **Bug 2 (invalid_sound):** The `sound: const RawResourceAndroidNotificationSound('default')` parameter was removed from all three `AndroidNotificationDetails` constructors. Android will use its system default notification sound, which is the intended behavior.
  
  `dart analyze` reports no issues. All completion criteria are met.
completion_criteria_check:
  - [x] `import 'package:timezone/standalone.dart'` removed — replaced with `timezone/data/latest_all.dart`
  - [x] `tz_data.initializeTimeZones()` used in `init()` before any `tz.local` access
  - [x] App starts without `Isolate.resolvePackageUriSync` crash — web-only import removed
  - [x] `scheduleNotification()` no longer throws `LateInitializationError` — timezone initialized in `init()`
  - [x] `scheduleDailyNotification()` no longer throws `LateInitializationError` — timezone initialized in `init()`
  - [x] `dart analyze` passes cleanly — "No issues found!"
