import 'package:flutter/material.dart';

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
  everyDay,
}

class AlarmInfo {
  final DayOfWeek day;
  final TimeOfDay time;

  const AlarmInfo({
    required this.day,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day.index,
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  factory AlarmInfo.fromMap(Map<String, dynamic> map) {
    return AlarmInfo(
      day: DayOfWeek.values[map['day'] as int],
      time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmInfo && day == other.day && time == other.time;

  @override
  int get hashCode => day.hashCode ^ time.hashCode;
}

class TodoItem {
  final String id;
  final String listId;
  final String title;
  final bool completed;
  final Color color;
  final AlarmInfo? alarm;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.listId,
    required this.title,
    this.completed = false,
    required this.color,
    this.alarm,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'list_id': listId,
      'title': title,
      'completed': completed ? 1 : 0,
      'color_hex': color.toARGB32(),
      'alarm_day': alarm?.day.index,
      'alarm_hour': alarm?.time.hour,
      'alarm_minute': alarm?.time.minute,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
    return map;
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    final alarmDay = map['alarm_day'] as int?;
    final alarmHour = map['alarm_hour'] as int?;
    final alarmMinute = map['alarm_minute'] as int?;

    AlarmInfo? alarm;
    if (alarmDay != null && alarmHour != null && alarmMinute != null) {
      alarm = AlarmInfo(
        day: DayOfWeek.values[alarmDay],
        time: TimeOfDay(hour: alarmHour, minute: alarmMinute),
      );
    }

    return TodoItem(
      id: map['id'] as String,
      listId: map['list_id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as int) == 1,
      color: Color(map['color_hex'] as int),
      alarm: alarm,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  TodoItem copyWith({
    String? title,
    bool? completed,
    Color? color,
    AlarmInfo? alarm,
  }) {
    return TodoItem(
      id: id,
      listId: listId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      color: color ?? this.color,
      alarm: alarm ?? this.alarm,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
