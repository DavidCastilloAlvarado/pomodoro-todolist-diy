task: fix_alarm_not_firing_android12
reviewer: reviewer
date: 2026-05-16
status: needs_revision
findings:
  - severity: warning
    file: pubspec.yaml
    line: 26
    description: |
      Task spec criterion 1 requires `permission: ^10.0.0` to be added.
      The implementation uses `permission_handler: ^11.3.0` instead, which
      was already present in pubspec.yaml before this fix. While both packages
      provide `Permission.scheduleExactAlarm` and the functional outcome is
      equivalent, this deviates from the explicit criterion.
    fix_instruction: |
      Either (a) add `permission: ^10.0.0` as a dependency and update all
      imports / API calls to use the `permission` package (ryanheise's package),
      or (b) confirm with the task author that `permission_handler` is an
      acceptable substitute and update the criterion accordingly.
  - severity: info
    file: lib/data/services/notification_service.dart
    line: 197
    description: |
      Criterion 3 specifies `canScheduleExactAlarms()` should use
      `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()`.
      The implementation uses `Permission.scheduleExactAlarm.status` from
      `permission_handler` instead. Both approaches are valid; this is a
      deviation from the exact API specified.
    fix_instruction: |
      No action needed if `permission_handler` is accepted as the chosen
      permission package. If the spec's `resolvePlatformSpecificImplementation`
      approach is required, replace lines 197-199 with the platform-specific
      resolution call from `flutter_local_notifications`.
summary: |
  Both previously flagged warnings are now fixed:
  1. "Open Settings" button — present in the exact-alarms permission warning
     dialog (alarm_picker_dialog.dart line 61-69). ✅
  2. `use_build_context_synchronously` lint — all BuildContext usages after
     await calls are guarded with `mounted` checks (lines 45, 64, 75). ✅

  `dart analyze` passes cleanly for all reviewed files. The two remaining
  analyzer info-level issues are pre-existing in unrelated files.

  One deviation remains: pubspec.yaml uses `permission_handler: ^11.3.0`
  (already present) instead of the spec's `permission: ^10.0.0`. The
  functionality is equivalent — both packages provide
  `Permission.scheduleExactAlarm` — but the criterion is not literally met.
  This should be resolved by either adding the exact package specified or
  updating the criterion to accept `permission_handler` as an acceptable
  substitute.
completion_criteria_check:
  - [x] `permission: ^10.0.0` added to `pubspec.yaml` dependencies — NOT met (uses `permission_handler: ^11.3.0` instead)
  - [x] `flutter pub get` succeeds after adding the dependency — met
  - [ ] `canScheduleExactAlarms()` method added using `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()` — deviation (uses `Permission.scheduleExactAlarm.status` from `permission_handler`)
  - [x] `requestExactAlarmPermission()` method added using `Permission.scheduleExactAlarm` — met
  - [x] `scheduleNotification()` checks `canScheduleExactAlarms()` and uses `inexactAllowWhileIdle` as fallback — met
  - [x] `scheduleDailyNotification()` checks `canScheduleExactAlarms()` and uses `inexactAllowWhileIdle` as fallback — met
  - [x] `main.dart` calls `requestExactAlarmPermission()` after `requestNotificationPermission()` on startup — met
  - [x] UI warning shown in alarm picker dialog with "Open Settings" button — met
  - [x] Debug logging added to `scheduleNotification()` and `scheduleDailyNotification()` — met
  - [x] `dart analyze` passes cleanly (no new errors or warnings introduced) — met
