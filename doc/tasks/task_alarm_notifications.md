name: alarm_notifications
phase: 4
description: |
  Fix the alarm notification system. Currently AlarmService.scheduleAlarm() 
  computes the alarm time but never actually schedules a notification with 
  NotificationService. Also fix the compile error in notification_service.dart 
  (UILocalNotificationDateInterpretation.absolute doesn't exist in v18).

files:
  - lib/data/services/notification_service.dart
  - lib/data/services/alarm_service.dart
  - lib/main.dart
  - pubspec.yaml

completion_criteria:
  - [ ] UILocalNotificationDateInterpretation.absolute fixed to wallClockTime
  - [ ] timezone added as direct dependency in pubspec.yaml
  - [ ] flutter pub get succeeds
  - [ ] dart analyze shows 0 errors
  - [ ] AlarmService.scheduleAlarm() calls NotificationService.scheduleNotification() for one-time alarms
  - [ ] AlarmService.scheduleAlarm() calls NotificationService.scheduleDailyNotification() for every-day alarms
  - [ ] AlarmService.cancelAlarm() calls NotificationService.cancelById()
  - [ ] AlarmService.initAlarmManager() calls reRegisterAllAlarms()
  - [ ] main.dart initializes NotificationService and calls alarmService.initAlarmManager() on startup
  - [ ] App launches without red screen
  - [ ] Alarms trigger notifications at the scheduled time
