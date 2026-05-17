name: fix_alarms
phase: 1
description: Fix todo item alarms so they fire and produce sound reliably. Addresses 6 root causes: hardcoded timezone, missing alarm sound, missing runtime notification permission (Android 13+), notification ID collision, overly restrictive alarm schedule mode, and no error handling in AlarmService.
files:
  - lib/data/services/notification_service.dart
  - lib/data/services/alarm_service.dart
  - lib/main.dart
completion_criteria:
  - [ ] Timezone in notification_service.dart uses device local timezone (tz.TZDateTime.now(tz.local)) instead of hardcoded 'Asia/Manila'
  - [ ] Notifications include an alarm sound (AndroidNotificationDetails uses defaultAlertSound or a custom alarm sound)
  - [ ] Notification IDs are unique and positive (use .abs() on hash codes to avoid negative IDs)
  - [ ] Runtime notification permission is requested on Android 13+ (use flutter_local_notifications AndroidPlugin.requestNotificationsPermission())
  - [ ] Alarm scheduling uses a reliable AndroidScheduleMode (powerAlarm or inexactAllowWhileIdle instead of alarmClock)
  - [ ] AlarmService has try/catch logging around scheduleAlarm() to catch and report failures
  - [ ] App compiles without errors (dart analyze passes cleanly)
  - [ ] Alarms fire when app is open AND when app is closed (notification-based)
  - [ ] Daily recurring alarms work correctly (everyDay mode)
  - [ ] One-time alarms on specific days work correctly (monday-sunday mode)
status: pending
