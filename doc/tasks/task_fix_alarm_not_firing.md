name: fix_alarm_not_firing_android12
phase: 5
description: |
  Fix the critical bug where alarms set in the Birdle Flutter app NEVER fire on
  Android 12+ devices.

  **Root cause:** The app uses `flutter_local_notifications` with
  `AndroidScheduleMode.exactAllowWhileIdle` unconditionally in both
  `scheduleNotification()` and `scheduleDailyNotification()`. On Android 12+
  (API 31+), `SCHEDULE_EXACT_ALARM` is a special runtime permission that is
  declared in the manifest but is **never requested or checked** at runtime.

  Android 12+ behavior for `SCHEDULE_EXACT_ALARM`:
  1. Permission is declared in the manifest (already done — both
     `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`).
  2. **MUST be granted by the user** at runtime via Settings → Apps → Birdle →
     Special app access → Exact alarms → Allow.
  3. Is **NOT automatically granted** even though it's declared in the manifest.
  4. When not granted, `flutter_local_notifications` silently falls back to
     inexact scheduling or fails entirely — the alarm never fires at the
     scheduled time.

  The app uses `android_alarm_manager_plus` and `flutter_local_notifications`
  but never calls `Permission.request(Permission.scheduleExactAlarm)` or checks
  `canScheduleExactAlarms()`.

  **Fix:** Add the `permission` package, check exact alarm support at schedule
  time, fall back to `inexactAllowWhileIdle` when unavailable, request the
  permission on startup, and show a UI warning to the user when the permission
  is not granted.

files:
  - pubspec.yaml
  - lib/data/services/notification_service.dart
  - lib/main.dart
  - lib/ui/widgets/alarm_picker_dialog.dart

completion_criteria:
  - [ ] `permission: ^10.0.0` added to `pubspec.yaml` dependencies
  - [ ] `flutter pub get` succeeds after adding the dependency
  - [ ] `canScheduleExactAlarms()` method added to `NotificationService` using
        `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()`
  - [ ] `requestExactAlarmPermission()` method added to `NotificationService`
        using `Permission.scheduleExactAlarm`
  - [ ] `scheduleNotification()` checks `canScheduleExactAlarms()` and uses
        `inexactAllowWhileIdle` as fallback when exact alarms are unavailable
  - [ ] `scheduleDailyNotification()` checks `canScheduleExactAlarms()` and uses
        `inexactAllowWhileIdle` as fallback when exact alarms are unavailable
  - [ ] `main.dart` calls `requestExactAlarmPermission()` after
        `requestNotificationPermission()` on startup
  - [ ] UI warning shown in alarm picker dialog when exact alarm permission is
        not granted, with a button to open the exact alarms settings page
  - [ ] Debug logging added to `scheduleNotification()` and
        `scheduleDailyNotification()` — logs whether exact alarms are supported,
        which schedule mode is used, the scheduled time, and the result of
        `zonedSchedule`
  - [ ] `dart analyze` passes cleanly (no new errors or warnings introduced)

status: pending
