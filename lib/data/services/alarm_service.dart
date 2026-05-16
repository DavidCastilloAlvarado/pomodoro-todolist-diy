import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/services/database.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  AlarmService._internal();

  factory AlarmService() => _instance;

  late BirdleDatabase _db;

  void init({required BirdleDatabase database}) {
    _db = database;
  }

  Future<void> scheduleAlarm(TodoItem item) async {
    final alarm = item.alarm;
    if (alarm == null) return;

    final now = DateTime.now();
    var alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    switch (alarm.day) {
      case DayOfWeek.everyDay:
        break;
      case DayOfWeek.monday:
      case DayOfWeek.tuesday:
      case DayOfWeek.wednesday:
      case DayOfWeek.thursday:
      case DayOfWeek.friday:
      case DayOfWeek.saturday:
      case DayOfWeek.sunday:
        final currentDayOfWeek = now.weekday;
        final targetDay = alarm.day.index + 1;
        int daysUntil = targetDay - currentDayOfWeek;
        if (daysUntil <= 0) daysUntil += 7;
        alarmTime = DateTime(now.year, now.month, now.day + daysUntil, alarm.time.hour, alarm.time.minute);
        if (alarmTime.isBefore(now)) {
          alarmTime = alarmTime.add(const Duration(days: 7));
        }
        break;
    }
  }

  Future<void> cancelAlarm(String itemId) async {
    // Alarm cancelled
  }

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

  List<TodoItem> getPendingAlarms() {
    return [];
  }

  Future<void> initAlarmManager() async {}
}
