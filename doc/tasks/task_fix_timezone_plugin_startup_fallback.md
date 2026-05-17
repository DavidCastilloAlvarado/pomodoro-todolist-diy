name: fix_timezone_plugin_startup_fallback
phase: 6
description: |
  Fix the startup crash introduced by the local-time alarm scheduling change.

  **Likely root cause:** `NotificationService.init()` now eagerly calls
  `initializeLocalTimezone()`, which unconditionally awaits
  `FlutterTimezone.getLocalTimezone()`. That platform channel is invoked from
  `main()` before `runApp()`, so when the `flutter_timezone` plugin is not
  available on a hot reload / hot restart / plugin-registration edge path, the
  `MissingPluginException` escapes and aborts app startup.

  **Safest fix direction:** keep the timezone-aware scheduling behavior from the
  previous fix when the plugin resolves normally, but make timezone resolution a
  best-effort step instead of a startup-critical failure. Handle
  `MissingPluginException` and related platform resolution failures inside the
  notification timezone initialization path, log the fallback path, and choose a
  deterministic non-crashing fallback timezone strategy when the device IANA
  timezone cannot be resolved. The fallback must still allow alarm scheduling to
  proceed and should preserve local wall-clock behavior as closely as possible,
  while using UTC only as a last resort.

files:
  - lib/data/services/notification_service.dart
  - lib/main.dart
  - test/data/services/alarm_service_test.dart

completion_criteria:
  - [ ] `NotificationService` no longer lets `FlutterTimezone.getLocalTimezone()` crash startup; `MissingPluginException` and equivalent timezone-resolution failures are caught on the initialization path used by `main()`.
  - [ ] When the timezone plugin resolves normally, `NotificationService` still initializes `tz.local` from the device timezone so the prior local-time alarm scheduling behavior is preserved for non-UTC devices.
  - [ ] When the timezone plugin cannot resolve, the service uses a documented fallback timezone strategy that keeps startup alive, allows alarm scheduling to continue, and avoids silently rethrowing the plugin error.
  - [ ] Regression coverage is added for both paths: a normal device-timezone path (for example `America/Lima`) and a failing timezone-provider path that simulates `MissingPluginException` during initialization.
  - [ ] Verification demonstrates that app startup no longer crashes on hot reload / restart paths and that alarms still schedule against local wall-clock time after the fallback hardening.
  - [ ] `dart analyze` passes without introducing new warnings or errors.

status: pending
