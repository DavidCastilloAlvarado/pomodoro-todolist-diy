
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
