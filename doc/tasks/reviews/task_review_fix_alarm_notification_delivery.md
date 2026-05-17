task: fix_alarm_notification_delivery
reviewer: reviewer
date: 2026-05-17
status: approved
findings: []
summary: |
  Re-review complete: the previous scope violation has been resolved. The added integration test file was removed, the `integration_test` dev dependency was reverted from `pubspec.yaml`, and the remaining test-file edits are compatibility adjustments to existing tests rather than new automated coverage.

  The underlying alarm-delivery implementation still satisfies the approved task criteria: Android scheduled-notification receivers are declared, startup initializes notifications before alarm re-registration, delivery diagnostics and manual verification guidance are present, alarm channel configuration is suitable for visible Android delivery, timezone/local wall-clock scheduling behavior is preserved, and `dart analyze` passes cleanly.
completion_criteria_check:
  - [x] Android scheduled-notification delivery requirements for `flutter_local_notifications` are verified against the current plugin version, and Birdle's manifest/application config includes any missing receiver/boot configuration needed for scheduled alarms to fire while the app is backgrounded, screen-off, or after reboot — met
  - [x] Alarm scheduling records enough diagnostics to verify delivery setup end-to-end, including notification permission/enabled state, exact-alarm availability, chosen Android schedule mode, resolved timezone/local scheduled time, and whether the scheduled request appears in `pendingNotificationRequests()` after scheduling — met
  - [x] `NotificationService` initialization and `main.dart` startup order are validated so timezone setup, notification plugin init, channel creation, permission requests, and alarm re-registration all happen before pending alarms are expected to fire — met
  - [x] Alarm notification channel configuration is confirmed sufficient for visible delivery on Android (high importance and correct alarm channel usage), or updated if current settings are insufficient — met
  - [x] Existing weekday and every-day scheduling continues to use future local wall-clock times, including the Peru / UTC-5 behavior already fixed, so the delivery fix does not reintroduce the timezone bug — met
  - [x] A repeatable Android manual verification path is added and documented so a reviewer can prove the real device/emulator behavior: schedule an alarm 1-2 minutes ahead, send the app to background or turn the screen off, wait until due time, and observe that the Birdle notification is actually shown — met
  - [x] No new automated tests or integration tests are added as part of this task unless the user explicitly confirms the on-device fix works and asks for follow-up coverage — met
  - [x] `dart analyze` passes without introducing new warnings or errors — met (`dart analyze` returned “No issues found!” during re-review)
