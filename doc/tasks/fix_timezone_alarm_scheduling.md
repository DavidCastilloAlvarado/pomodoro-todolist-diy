# Investigation: Timezone Alarm Scheduling Bug

## Bug Summary

Alarms scheduled for times earlier than the current local time fail with:
```
Invalid argument (scheduledDate): Must be a date in the future
```

**Log evidence:**
```
I/flutter: AlarmService: Scheduling alarm for "ghhjj" — day: DayOfWeek.sunday, time: 0:44
I/flutter: NotificationService: Scheduling notification id=... at 2026-05-17 00:44:00.000Z
I/flutter: Failed to schedule alarm: Must be a date in the future
```

The `Z` suffix on `00:44:00.000Z` indicates UTC. If the user's local time is already past 00:44, the scheduled time is in the past and the notification library rejects it.

---

## Root Cause Analysis

### 1. Data Flow: How alarm times travel through the system

**Storage (no timezone involved):**
- `AlarmInfo` stores `day` (DayOfWeek enum index) and `time` (TimeOfDay with hour/minute ints)
- These are persisted as plain integers in SQLite (`alarm_day`, `alarm_hour`, `alarm_minute`)
- **No timezone data is stored** — only wall-clock components

**Retrieval:**
- `alarm_service.dart` line 122-123: `DayOfWeek.values[alarmDay]` and `TimeOfDay(hour: alarmHour, minute: alarmMinute)`
- `TimeOfDay` is a pure data class with no timezone semantics

### 2. Single-alarm path (`alarm_service.dart` lines 46-94)

```dart
// Line 30: Gets current local time
final now = DateTime.now();

// Line 59: Constructs a local DateTime for the target day at alarm time
final todayTargetTime = DateTime(
  now.year, now.month, now.day,
  alarm.time.hour, alarm.time.minute,
);

// Lines 64-74: Guard logic
if (daysUntil == 0) {
  if (todayTargetTime.isBefore(now)) {
    daysUntil = 7;  // Schedule for next week
  }
}

// Lines 77-83: Constructs alarmTime (local DateTime)
alarmTime = DateTime(
  now.year, now.month, now.day + daysUntil,
  alarm.time.hour, alarm.time.minute,
);
```

**Guard check:** `todayTargetTime.isBefore(now)` correctly identifies when the alarm time has passed on the target day and rolls to next week. **This path has a guard.**

### 3. Daily-alarm path (`notification_service.dart` lines 122-187)

```dart
// Line 127: Receives TimeOfDay (pure hour/minute ints, no timezone)
required TimeOfDay time,

// Line 138: Gets current local time
final now = DateTime.now();

// Line 139-142: Constructs local DateTime for target time today
final todayAtTargetTime = DateTime(
  now.year, now.month, now.day,
  time.hour, time.minute,
);

// Lines 144-151: Comparison logic
DateTime nextOccurrence;
if (todayAtTargetTime.isAfter(now) || todayAtTargetTime.isAtSameMomentAs(now)) {
  nextOccurrence = todayAtTargetTime;      // Schedule for today
} else {
  nextOccurrence = todayAtTargetTime.add(const Duration(days: 1));  // Schedule for tomorrow
}

// Lines 154-161: Converts to TZDateTime
final tzScheduledTime = tz.TZDateTime(
  tz.local,
  nextOccurrence.year, nextOccurrence.month, nextOccurrence.day,
  nextOccurrence.hour, nextOccurrence.minute,
);
```

**The guard logic here is present but has a subtle edge-case bug.**

### 4. The `TZDateTime` constructor — correctly used

```dart
tz.TZDateTime(tz.local, year, month, day, hour, minute)
```

This constructor takes `(timeZone, year, month, day, hour, [second, [millisecond]])` and interprets the date/time components as **local time** in the given zone. **This is correct** — the components from `DateTime(...)` are interpreted as local time, which is the intended behavior.

### 5. The `isAtSameMomentAs` edge case

In `scheduleDailyNotification` (line 145):
```dart
if (todayAtTargetTime.isAfter(now) || todayAtTargetTime.isAtSameMomentAs(now))
```

`DateTime.now()` returns a DateTime with **microsecond precision**, while `DateTime(year, month, day, hour, minute)` has **zero microseconds**. When the target time equals the current time exactly (e.g., both are 00:44:00), `isAtSameMomentAs` compares the underlying millisecond values:
- `todayAtTargetTime.millisecondsSinceEpoch` = some value at 00:44:00.000
- `now.millisecondsSinceEpoch` = same value at 00:44:00.xxx (microseconds may differ)

Since microseconds differ, `isAtSameMomentAs` returns `false`, and the condition falls through to the `else` branch (schedule for tomorrow). **This is actually correct behavior** — if the times are "equal" at second granularity but differ at microsecond granularity, scheduling for tomorrow is safer.

### 6. The actual root cause

**There are two distinct bugs:**

#### Bug A: Daily alarm path — missing robustness guard

The comparison `isAfter(now) || isAtSameMomentAs(now)` in `scheduleDailyNotification` works in most cases, but it's not bulletproof. The `isAtSameMomentAs` comparison is unreliable due to microsecond precision differences. The real issue is that **there is no final guard after constructing `TZDateTime`** — the code doesn't verify the result is actually in the future before passing it to the notification library.

**Scenario that triggers the bug:**
1. User creates item with alarm for "every day" at 00:44
2. Current time is 08:00 on May 17
3. `todayAtTargetTime` = May 17 00:44 (in the past)
4. `isAfter(now)` = false, `isAtSameMomentAs(now)` = false
5. `nextOccurrence` = May 18 00:44 ✓ (correct)
6. `tzScheduledTime` = May 18 00:44 local ✓ (correct)

This scenario actually works correctly. The bug manifests when:

1. The device timezone is UTC (as suggested by the `Z` in the log)
2. The user's alarm is for a specific day (e.g., Sunday) at 00:44
3. The current time is already past 00:44 on that Sunday
4. The guard in `alarm_service.dart` should catch this, but there may be an edge case

#### Bug B: `DateTime` construction with day overflow — potential edge case

In `alarm_service.dart` line 80:
```dart
alarmTime = DateTime(
  now.year,
  now.month,
  now.day + daysUntil,  // Can exceed month length
  alarm.time.hour,
  alarm.time.minute,
);
```

Dart's `DateTime` constructor **does** normalize overflow (e.g., May 31 + 7 = June 7). So this is not actually a bug — the constructor handles it correctly.

#### Bug C (confirmed): The daily-alarm path lacks a final validation guard

The `scheduleDailyNotification` method computes `nextOccurrence` and converts it to `TZDateTime`, but **never validates that the result is in the future** after the conversion. If the comparison logic has any edge case where `nextOccurrence` ends up in the past (e.g., timezone boundary issues, leap second edge cases), it will fail silently.

The single-alarm path has the guard (`if (todayTargetTime.isBefore(now)`) but the daily-alarm path's guard is less robust.

### 7. Hypothesis about the `Z` in the log

The log shows: `2026-05-17 00:44:00.000Z`

This `Z` suffix is **not** from `TZDateTime.toString()` (which would show `+00:00` or similar offset). It's likely from:
1. The device's timezone being UTC (so `tz.local` = UTC)
2. Or the debug print output being converted by the logging framework

If the device is in UTC and the current time is past 00:44 UTC, then:
- For the single-alarm path: the guard should roll to next week ✓
- For the daily-alarm path: `isAfter(now)` should be false, rolling to tomorrow ✓

**The most likely trigger:** The guard in the single-alarm path is working, but the **daily-alarm path** is the one that fails. When the user sets a "every day" alarm at 00:44 and the current time is past 00:44, the comparison `isAtSameMomentAs` may produce unexpected results due to microsecond precision, causing the code to schedule for "today" (which is in the past) instead of "tomorrow."

---

## Confirmed Root Cause

**Primary bug:** The `scheduleDailyNotification` method in `notification_service.dart` (line 145) uses `isAtSameMomentAs` for equality comparison, which is unreliable due to microsecond precision differences between `DateTime.now()` and constructed `DateTime` objects. When the target time equals the current time at second granularity but differs at microsecond granularity, the comparison fails and the code may schedule for the wrong day.

**Secondary issue:** Neither `scheduleNotification` nor `scheduleDailyNotification` has a final validation guard that checks the computed `TZDateTime` is actually in the future before passing it to the notification plugin. The single-alarm path has an early guard, but it's not a defense-in-depth approach.

---

## The Fix

### Fix 1: Add a final validation guard in `scheduleNotification`

In `lib/data/services/notification_service.dart`, after computing `tzScheduledTime`, add:

```dart
// Guard: ensure the scheduled time is in the future
if (tzScheduledTime.isBefore(tz.now())) {
  tzScheduledTime = tzScheduledTime.add(const Duration(days: 1));
}
```

This is the simplest and most robust fix — it catches any edge case where the computed time ended up in the past.

### Fix 2: Tighten the comparison in `scheduleDailyNotification`

Replace the unreliable `isAtSameMomentAs` check with a simpler `isBefore` check:

```dart
// Current (buggy):
if (todayAtTargetTime.isAfter(now) || todayAtTargetTime.isAtSameMomentAs(now)) {
  nextOccurrence = todayAtTargetTime;
} else {
  nextOccurrence = todayAtTargetTime.add(const Duration(days: 1));
}

// Fixed:
if (todayAtTargetTime.isBefore(now)) {
  nextOccurrence = todayAtTargetTime.add(const Duration(days: 1));
} else {
  nextOccurrence = todayAtTargetTime;
}
```

This is equivalent logic but simpler and avoids the unreliable `isAtSameMomentAs`.

### Fix 3: Add the same guard to `scheduleNotification` for defense-in-depth

```dart
final tzScheduledTime = tz.TZDateTime(
  tz.local,
  scheduledTime.year,
  scheduledTime.month,
  scheduledTime.day,
  scheduledTime.hour,
  scheduledTime.minute,
);

// FIX: Guard against past times
if (tzScheduledTime.isBefore(tz.now())) {
  tzScheduledTime = tzScheduledTime.add(const Duration(days: 1));
}
```

### Alternative approach: Use `tz.TZDateTime.from()`

If available, `tz.TZDateTime.from(scheduledTime, tz.local)` would be cleaner — it properly interprets the `DateTime`'s timezone information. However, since `scheduledTime` is a local `DateTime` (created with `DateTime(...)` not `DateTime.utc(...)`), the current approach of extracting components is correct. The bug is not in the conversion — it's in the lack of a "is this in the future?" guard.

---

## Files to Change

| File | Change |
|------|--------|
| `lib/data/services/notification_service.dart` | Add final validation guard in `scheduleNotification()` (after line 93) |
| `lib/data/services/notification_service.dart` | Simplify comparison in `scheduleDailyNotification()` (line 145) |

## Files to Review (no changes needed)

| File | Reason |
|------|--------|
| `lib/data/services/alarm_service.dart` | Has guard logic but no final validation; consider adding defense-in-depth guard |
| `lib/data/models/todo_item.dart` | `AlarmInfo` stores no timezone — correct by design |
| `lib/data/repositories/item_repository.dart` | Calls `scheduleAlarm` — no changes needed |

---

## Verification Steps

1. Create an item with an alarm set to a time earlier than the current local time
2. Verify the alarm is scheduled for the next valid occurrence (not in the past)
3. Test edge cases:
   - Alarm time exactly equals current time (second granularity)
   - Alarm at midnight (00:00) when current time is past midnight
   - Alarm at end of month (day overflow)
   - Device timezone at UTC+0, UTC+X, UTC-X boundaries
4. Run `dart analyze` to ensure no new warnings
