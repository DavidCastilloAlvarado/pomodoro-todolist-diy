name: fix_android_notification_icon_regression
phase: 4
description: |
  Fix the Android alarm scheduling regression where `flutter_local_notifications`
  now fails with `PlatformException(invalid_icon, The resource ic_stat_birdle
  could not be found...)` before the notification request is accepted.

  **Likely root cause:** `NotificationService` hardcodes `ic_stat_birdle`, and
  the app currently provides only `android/app/src/main/res/drawable/ic_stat_birdle.xml`.
  The new failure indicates the active Android head project / build variant is not
  resolving that resource at runtime for scheduled notifications. The safest fix
  direction is to preserve the current local-time scheduling behavior and recent
  delivery changes, and repair only the Android small-icon resource
  path/format/configuration so Birdle references a guaranteed packaged
  notification icon.

  **Scope guardrails:**
  - Do not rework the local-time scheduling logic unless the icon fix requires a
    minimal related adjustment.
  - Keep the existing scheduled-notification delivery wiring intact unless a
    minimal manifest/resource correction is required for the icon to resolve.
  - Verify the fix manually on Android first by scheduling a near-future alarm,
    backgrounding/locking the device, and confirming both successful scheduling
    and visible delivery at the expected local time.
  - Do not add new automated or integration tests until the user confirms the
    manual fix works.

files:
  - lib/data/services/notification_service.dart
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/res/drawable/ic_stat_birdle.xml
completion_criteria:
  - [ ] The Android notification icon reference used during initialization and scheduling resolves in the active app module/build variant, so scheduling no longer fails with `PlatformException(invalid_icon, ... ic_stat_birdle ...)`.
  - [ ] The fix uses a guaranteed packaged Android notification small-icon resource, with only the minimal manifest/resource/configuration changes needed to make that lookup reliable.
  - [ ] The current local-time alarm scheduling behavior and recent notification delivery changes are preserved; fixing the icon lookup does not regress timezone handling, resolved trigger times, or background delivery behavior.
  - [ ] Manual Android verification is completed before any follow-up test work: schedule an alarm 1-2 minutes ahead, confirm scheduling succeeds without the invalid-icon error, background or lock the device, and observe the notification at the expected local time.
  - [ ] No new automated tests or integration tests are added in this task unless the user later confirms the manual fix works and explicitly asks for follow-up coverage.
  - [ ] `dart analyze` passes without introducing new warnings or errors.
status: pending
