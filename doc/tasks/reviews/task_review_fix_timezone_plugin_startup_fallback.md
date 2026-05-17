task: fix_timezone_plugin_startup_fallback
reviewer: reviewer
date: 2026-05-17
status: approved
findings: []
summary: |
  The implementation now satisfies the task criteria. NotificationService preserves device timezone behavior when the plugin resolves, falls back safely to a deterministic fixed-offset local timezone when timezone lookup fails, and the new bootstrapBirdleApp startup test demonstrates that MissingPluginException on startup no longer blocks app rendering while follow-up alarm scheduling still preserves local wall-clock behavior.
completion_criteria_check:
  - [x] NotificationService no longer lets FlutterTimezone.getLocalTimezone() crash startup; MissingPluginException and equivalent initialization failures are caught on the initialization path used by main().
  - [x] When the timezone plugin resolves normally, NotificationService still initializes tz.local from the device timezone so the prior local-time alarm scheduling behavior is preserved for non-UTC devices.
  - [x] When the timezone plugin cannot resolve, the service uses a documented fallback timezone strategy that keeps startup alive, allows alarm scheduling to continue, and avoids silently rethrowing the plugin error.
  - [x] Regression coverage is added for both paths: a normal device-timezone path and a failing timezone-provider path that simulates MissingPluginException during initialization.
  - [x] Verification demonstrates that app startup no longer crashes on hot reload / restart paths and that alarms still schedule against local wall-clock time after the fallback hardening.
  - [x] Builder reported dart analyze passed without introducing new warnings or errors.
