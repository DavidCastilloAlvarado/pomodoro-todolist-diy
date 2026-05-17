name: fix_alarm_notification_delivery
phase: 4
description: |
  Investigate and fix the Android alarm delivery regression where Birdle logs show
  successful scheduling through `flutter_local_notifications`, but no notification
  is shown when the scheduled time arrives.

  Most likely cause from the current repo state: Birdle schedules notifications via
  `zonedSchedule()`, but `android/app/src/main/AndroidManifest.xml` does not
  declare the `flutter_local_notifications` scheduled notification receivers that
  Android uses to actually deliver scheduled alarms while the app is backgrounded,
  screen-off, or after reboot. The fix should verify that Android delivery wiring
  is complete before changing scheduling logic that already appears to compute a
  valid future local wall-clock time.

  The implementation should also validate the remaining delivery prerequisites:
  notification permission/enabled state, exact-alarm capability and fallback mode,
  timezone/date conversion, alarm channel configuration, startup initialization,
  and a repeatable proof that a near-future alarm really fires on Android when due.

files:
  - android/app/src/main/AndroidManifest.xml
  - android/app/build.gradle.kts
  - lib/data/services/notification_service.dart
  - lib/data/services/alarm_service.dart
  - lib/main.dart
  - test/data/services/alarm_service_test.dart
  - test/main_test.dart
  - integration_test/alarm_delivery_test.dart
completion_criteria:
  - [ ] Android scheduled-notification delivery requirements for `flutter_local_notifications` are verified against the current plugin version, and Birdle's manifest/application config includes any missing receiver/boot configuration needed for scheduled alarms to fire while the app is backgrounded, screen-off, or after reboot.
  - [ ] Alarm scheduling records enough diagnostics to verify delivery setup end-to-end, including notification permission/enabled state, exact-alarm availability, chosen Android schedule mode, resolved timezone/local scheduled time, and whether the scheduled request appears in `pendingNotificationRequests()` after scheduling.
  - [ ] `NotificationService` initialization and `main.dart` startup order are validated so timezone setup, notification plugin init, channel creation, permission requests, and alarm re-registration all happen before pending alarms are expected to fire.
  - [ ] Alarm notification channel configuration is confirmed sufficient for visible delivery on Android (high importance and correct alarm channel usage), or updated if current settings are insufficient.
  - [ ] Existing weekday and every-day scheduling continues to use future local wall-clock times, with regression coverage for the Peru / UTC-5 scenario so the delivery fix does not reintroduce the prior timezone bug.
  - [ ] Automated verification is added for the scheduling side of delivery, covering at minimum that a near-future alarm produces a pending scheduled notification request with the expected ID, title/body, and local trigger time.
  - [ ] A repeatable Android verification path is added and documented in the task implementation notes or test flow so a reviewer can prove the real device/emulator behavior: schedule an alarm 1-2 minutes ahead, send the app to background or turn the screen off, wait until due time, and observe that the Birdle notification is actually shown.
  - [ ] `dart analyze` passes without introducing new warnings or errors.
status: pending
