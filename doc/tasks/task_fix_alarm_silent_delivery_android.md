name: fix_alarm_silent_delivery_android
phase: 4
description: |
  Investigate and fix the remaining Android alarm-delivery bug where Birdle now
  logs successful end-to-end scheduling, the request appears in
  `pendingNotificationRequests()`, and exact-alarm / notification diagnostics are
  green, but nothing visible or audible happens when the due time arrives.

  **Most likely remaining cause from the current repo state:** Birdle's current
  code requests an alarm-oriented channel (`Importance.max`,
  `AudioAttributesUsage.alarm`, sound/vibration enabled), but the reported device
  diagnostics still show the actual persisted alarm channel as
  `importance=high` and `audioUsage=notification`. For Android 8+, notification
  channel sound/importance behavior is effectively immutable after the channel is
  first created, so an older app install may still be using a legacy/silent or
  non-alarm channel even though current code asks for stronger alarm semantics.

  **Secondary check still required:** Birdle uses
  `flutter_local_notifications: ^18.0.1`, whose README/example require Android
  scheduled-delivery receivers in the app manifest. Birdle's manifest appears to
  include the main scheduled receivers already, so the safest direction is to
  re-verify that wiring against the exact plugin version in use and make only any
  minimal missing manifest changes that are still actually required.

  **Safest fix direction:** Preserve the current local-time scheduling logic,
  startup ordering, and delivery diagnostics. Focus the implementation on
  confirming manifest delivery wiring for plugin v18.0.1 and on ensuring alarms
  use a freshly applied Android channel configuration with alarm semantics on
  upgraded installs, rather than reworking the scheduling calculations that now
  appear correct.

  **Validation order:** Manual on-device verification comes first. Do not add new
  automated or integration tests in this task unless the user later confirms the
  manual fix works and explicitly asks for follow-up coverage.

files:
  - android/app/src/main/AndroidManifest.xml
  - lib/data/services/notification_service.dart
completion_criteria:
  - [ ] `flutter_local_notifications` scheduled-notification delivery requirements are re-verified specifically against Birdle's installed plugin version (`^18.0.1`), and `android/app/src/main/AndroidManifest.xml` is confirmed complete for scheduled delivery or updated with only the minimal missing receiver/service wiring required by that version.
  - [ ] The alarm-notification channel initialization path explicitly handles upgraded installs where the existing `birdle_alarms` channel is immutable and its persisted settings do not match the current expected alarm behavior; Birdle recreates or migrates to a fresh channel configuration so sound/alarm settings actually take effect on device.
  - [ ] The channel used for alarms is validated to use alarm-oriented semantics rather than generic notification semantics, including alarm-appropriate importance/category/audio usage plus sound and vibration enabled, and diagnostics report the actual channel state after initialization.
  - [ ] The current local-time scheduling behavior and recent diagnostics are preserved, including timezone-aware wall-clock scheduling, exact-alarm capability logging, and verification that scheduled requests still appear in `pendingNotificationRequests()`.
  - [ ] Manual Android verification is completed before any follow-up test work: verify the fix on device with a near-future alarm while the app is backgrounded or the screen is off, confirm visible and audible delivery at the expected local time, and specifically confirm the behavior on an upgraded install path where a legacy channel may already exist.
  - [ ] No new automated tests or integration tests are added in this task; test creation remains explicitly deferred until the user confirms the manual on-device fix works.
  - [ ] `dart analyze` passes without introducing new warnings or errors.
status: pending
