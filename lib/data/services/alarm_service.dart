import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/notification_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  AlarmService._internal();

  factory AlarmService() => _instance;

  late BirdleDatabase _db;
  late NotificationService _notificationService;

  void init({required BirdleDatabase database}) {
    _db = database;
    _notificationService = NotificationService();
  }

  /// Schedule an alarm for the given item.
  /// - For "every day": schedules a daily recurring notification.
  /// - For specific day: schedules a one-time notification for the next occurrence.
  Future<void> scheduleAlarm(TodoItem item) async {
    final alarm = item.alarm;
    if (alarm == null) return;

    final now = DateTime.now();
    DateTime alarmTime;

    switch (alarm.day) {
      case DayOfWeek.everyDay:
        // Schedule daily recurring notification
        await _notificationService.scheduleDailyNotification(
          id: item.id.hashCode,
          title: item.title,
          body: 'Reminder: ${item.title}',
          time: alarm.time,
        );
        return;

      case DayOfWeek.monday:
      case DayOfWeek.tuesday:
      case DayOfWeek.wednesday:
      case DayOfWeek.thursday:
      case DayOfWeek.friday:
      case DayOfWeek.saturday:
      case DayOfWeek.sunday:
        // Calculate the next occurrence of the target day
        final currentDayOfWeek = now.weekday;
        final targetDay = alarm.day.index + 1;
        int daysUntil = targetDay - currentDayOfWeek;
        if (daysUntil <= 0) daysUntil += 7;

        alarmTime = DateTime(
          now.year,
          now.month,
          now.day + daysUntil,
          alarm.time.hour,
          alarm.time.minute,
        );

        // If the calculated time is in the past, add 7 days
        if (alarmTime.isBefore(now)) {
          alarmTime = alarmTime.add(const Duration(days: 7));
        }

        // Schedule a one-time notification for that specific day/time
        await _notificationService.scheduleNotification(
          id: item.id.hashCode,
          title: item.title,
          body: 'Reminder: ${item.title}',
          scheduledTime: alarmTime,
        );
        break;
    }
  }

  /// Cancel the alarm for the given item.
  Future<void> cancelAlarm(String itemId) async {
    await _notificationService.cancelById(itemId.hashCode);
  }

  /// Re-register all alarms from the database (called on app startup).
  Future<void> reRegisterAllAlarms() async {
    final pendingItems = await _db.getPendingAlarms();
    for (final itemData in pendingItems) {
      final alarmDay = itemData.alarmDay!;
      final alarmHour = itemData.alarmHour!;
      final alarmMinute = itemData.alarmMinute!;

      final item = TodoItem(
        id: itemData.id,
        listId: itemData.listId,
        title: itemData.title,
        completed: itemData.completed == 1,
        color: Color(itemData.colorHex),
        alarm: AlarmInfo(
          day: DayOfWeek.values[alarmDay],
          time: TimeOfDay(hour: alarmHour, minute: alarmMinute),
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(itemData.createdAt),
      );

      await scheduleAlarm(item);
    }
  }

  /// Get pending alarms from the database.
  List<TodoItem> getPendingAlarms() {
    return [];
  }

  /// Initialize the alarm manager (called on app startup).
  Future<void> initAlarmManager() async {
    await reRegisterAllAlarms();
  }
}
