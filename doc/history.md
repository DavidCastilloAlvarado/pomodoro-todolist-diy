
## Phase 6 — Fix timezone initialization crash (LateInitializationError)

**Status:** Completed

**Root cause:** The `timezone` package requires calling `initializeTimeZone()` to load the timezone database before `tz.local` can be accessed. The app never called this, so every alarm schedule call crashed with `LateInitializationError: Field '_local' has not been initialized` **before it even reached the scheduling code**.

**Fix applied:**

| File | Change |
|---|---|
| `lib/data/services/notification_service.dart` | Added `import 'package:timezone/standalone.dart';` and `await initializeTimeZone();` in `init()` |

This is the **actual** bug that prevented alarms from firing. Without `initializeTimeZone()`, the app crashes on every alarm schedule attempt. The `timezone` package is a standard dependency (`timezone: ^0.10.0`) and `initializeTimeZone()` is the documented initialization step that `flutter_local_notifications` does NOT perform automatically.

**Reviewer findings:** All 4 completion criteria met. `dart analyze` passes cleanly.

## Phase 6 — Fix timezone initialization crash (correction)

**Status:** Completed

**Regression:** The initial fix used `package:timezone/standalone.dart` which is web-only and crashed on mobile with `Unsupported operation: Isolate.resolvePackageUriSync`, preventing the app from starting.

**Corrected fix:**

| File | Change |
|---|---|
| `lib/data/services/notification_service.dart` | Removed `standalone.dart` import; replaced `initializeTimeZone()` with `tz_data.initializeTimeZones()` from `package:timezone/data/latest_all.dart` |

The `timezone` 0.10.x package requires two steps on mobile:
1. Import `package:timezone/data/latest_all.dart` and call `initializeTimeZones()` to load timezone data
2. Use `package:timezone/timezone.dart` as `tz` for `tz.local` and `tz.TZDateTime`

Both imports are now correctly in place. `dart analyze` passes cleanly.

## Phase 6 — Fix invalid_sound alarm crash

**Status:** Completed

**Bug:** `PlatformException(invalid_sound, The resource default could not be found)` — `RawResourceAndroidNotificationSound('default')` referenced a non-existent `res/raw/default` file in the Android project.

**Fix:**

| File | Change |
|---|---|
| `lib/data/services/notification_service.dart` | Removed `sound: const RawResourceAndroidNotificationSound('default')` from all 3 `AndroidNotificationDetails` constructors (`showNotification`, `scheduleNotification`, `scheduleDailyNotification`) |

Without a custom `sound` property, Android uses its **system default notification sound** automatically (since `playSound: true` is the channel default). No new resource files needed.

**Note for testing:** Android notification channels are immutable after first creation. If the app was already installed with the broken channel, you may need to **uninstall and reinstall** (or clear app data) for the fix to take effect on your device.

## Phase 6 — Fix alarms rejected as "in the past"

**Status:** Completed

**Bug:** Alarms set for times earlier than the current local time were rejected with:
```
Invalid argument (scheduledDate): Must be a date in the future
```
Alarms set 5+ hours ahead worked because they were still in the future.

**Fix:**

| File | Change |
|---|---|
| `lib/data/services/alarm_service.dart` | Added final guard: if computed `alarmTime.isBefore(now)`, advance `daysUntil` by 7 and recompute |
| `lib/data/services/notification_service.dart` | Replaced `isAfter(now) \|\| isAtSameMomentAs(now)` with `!isBefore(now)` to fix microsecond precision comparison |

The guard in `alarm_service.dart` catches any edge case where the computed alarm time ends up in the past. The `!isBefore(now)` fix in `notification_service.dart` eliminates the microsecond-precision bug that could cause the daily alarm to schedule for the wrong day.

**Reviewer findings:** All 5 completion criteria met. `dart analyze` clean. Logic verified for all edge cases (same day, past time, next week, future day).

## Phase 6 — Fix local timezone alarm scheduling

**Status:** Completed

**Bug:** User-selected alarm times were being interpreted with UTC semantics in the notification scheduling layer instead of the device's local timezone. On non-UTC devices such as Peru (UTC-5), a future local alarm like 01:56 at local time 00:54 could be converted into a past `TZDateTime`, causing:
```
Invalid argument (scheduledDate): Must be a date in the future
```

**Fix:**

| File | Change |
|---|---|
| `pubspec.yaml` | Added `flutter_timezone` dependency so the app can resolve the device's actual timezone |
| `lib/data/services/notification_service.dart` | Initialized `tz.local` from the device timezone before creating scheduled `TZDateTime` values |
| `lib/data/services/alarm_service.dart` | Normalized next-occurrence calculations around local wall-clock time for daily and weekday alarms, including rollover to the next valid future occurrence |
| `test/data/services/alarm_service_test.dart` | Added regression coverage for the Peru UTC-5 scenario and recurring scheduling behavior |

The scheduling flow now preserves the user's intended local clock time instead of treating it like UTC. Daily alarms and weekday alarms continue to recur correctly, and past same-day occurrences are rolled forward to the next valid future local time.

**Reviewer findings:** Approved. Task criteria satisfied. Targeted tests passed; `dart analyze` reported only two unrelated pre-existing info-level issues outside the task files.

## Phase 6 — Fix alarm nowProvider runtime regression

**Status:** Completed

**Bug:** Alarm scheduling regressed with:
```
type 'Null' is not a subtype of type '() => DateTime' of 'function result'
```
The failure occurred in `AlarmService._nowProvider` during `scheduleAlarm()`, which meant alarm creation or update could crash before scheduling completed.

**Fix:**

| File | Change |
|---|---|
| `lib/data/services/alarm_service.dart` | Normalized `_nowProvider` to a guaranteed `DateTime Function()` on every construction path and wrapped injected providers so null results fall back to system time |
| `lib/data/services/notification_service.dart` | Kept timezone-aware scheduling behavior aligned with the prior local-time fix |
| `test/data/services/alarm_service_test.dart` | Added regression coverage for default construction, null-provider fallback, and preserved local scheduling behavior |

The app's normal alarm update flow no longer crashes because the service always resolves a valid current-time callback before computing the next occurrence.

**Reviewer findings:** Approved. Targeted alarm tests and `dart analyze` passed cleanly.

## Phase 6 — Fix timezone plugin startup fallback

**Status:** Completed

**Bug:** App startup could fail after hot restart / plugin-registration edge cases with:
```
MissingPluginException(No implementation found for method getLocalTimezone on channel flutter_timezone)
```
The crash happened because `NotificationService.init()` eagerly awaited `FlutterTimezone.getLocalTimezone()` during startup, and the exception was allowed to abort initialization.

**Fix:**

| File | Change |
|---|---|
| `lib/data/services/notification_service.dart` | Hardened local timezone initialization to catch `MissingPluginException`, `PlatformException`, and related failures; preserved the normal device-timezone path; added fallback timezone resolution using a fixed-offset local location and UTC as final fallback |
| `lib/main.dart` | Guarded startup/bootstrap so notification initialization failures are logged instead of crashing app launch; extracted a testable bootstrap path |
| `test/data/services/alarm_service_test.dart` | Added regression coverage for successful device timezone initialization and failing timezone-provider fallback behavior |
| `test/main_test.dart` | Added startup-path verification proving app bootstrap survives timezone plugin failure and still reaches rendering/alarm scheduling flow |

The app now keeps startup alive even when the timezone plugin is temporarily unavailable, while still using the real device timezone whenever plugin resolution succeeds. Local wall-clock alarm scheduling behavior remains preserved as closely as possible through the fallback path.

**Reviewer findings:** Approved. Startup-path verification added; targeted tests and `dart analyze` passed cleanly.

## Phase 4 — Fix alarm notification delivery

**Status:** Completed

**Bug:** Alarm scheduling completed successfully and logged a valid future local trigger time, but no notification appeared when the alarm became due.

**Fix:**

| File | Change |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Verified and enabled Android scheduled-notification delivery wiring for `flutter_local_notifications` receivers |
| `android/app/build.gradle.kts` | Ensured Android build config remains compatible with scheduled delivery requirements |
| `android/app/src/main/res/drawable/ic_stat_birdle.xml` | Added a dedicated notification small icon for reliable background/scheduled delivery |
| `lib/data/services/notification_service.dart` | Added delivery diagnostics for permission state, exact alarms, channel details, timezone, schedule mode, and pending notification requests |
| `lib/data/services/alarm_service.dart` | Preserved local wall-clock scheduling behavior while improving end-to-end scheduling diagnostics |
| `lib/main.dart` | Kept startup ordering aligned with notification initialization and alarm re-registration requirements |

The delivery path now uses Android-compatible notification resources and explicit diagnostics so scheduled alarms can be verified end-to-end on device without changing the previously fixed local-time calculation logic.

**Reviewer findings:** Approved. No new automated/integration tests remain in this task. `dart analyze` passed cleanly.

## Phase 6 — Fix Lists tab top padding

**Status:** Completed

**Issue:** The Lists tab grid started flush against the top of the screen, causing the first row of list cards to sit too close to the status bar/top edge.

**Fix:**

| File | Change |
|---|---|
| `lib/ui/screens/app_shell/app_shell.dart` | Wrapped the Lists tab scrollable content in `SafeArea(bottom: false)` so the grid respects the top inset while preserving the existing `RefreshIndicator`, two-column grid layout, card interactions, and floating add-list button behavior |

The change is intentionally minimal and localized to the Lists tab layout so only the missing top inset is corrected.

**Reviewer findings:** Approved. All completion criteria satisfied and `dart analyze` passed cleanly.

## Phase 4 — Fix Android manifest keep instruction build failure

**Status:** Completed

**Bug:** `flutter run` failed during `:app:processDebugMainManifest` with:
```
Error: Invalid instruction 'keep', valid instructions are : REMOVE,REPLACE,STRICT,IGNORE_WARNING
```
The app manifest declared `tools:keep` on `<application>`, but `keep` is not a valid Android manifest-merger instruction.

**Fix:**

| File | Change |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Removed the unsupported `tools:keep` attribute and the now-unused `tools` XML namespace |
| `android/app/src/main/res/drawable/ic_stat_birdle.xml` | Updated the inline comment so it no longer claims the icon is retained via the manifest |
| `lib/data/services/notification_service.dart` | Corrected the stale comment describing how `ic_stat_birdle` is packaged/used as the Android notification small icon |

The Android notification icon resource `ic_stat_birdle` remains available to the existing notification setup, but the unsupported manifest syntax is gone, allowing Android manifest processing to complete normally again.

**Reviewer findings:** Approved. `flutter build apk --debug` succeeded and all completion criteria were satisfied.
