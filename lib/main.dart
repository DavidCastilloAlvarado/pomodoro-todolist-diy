import 'package:birdle/app.dart';
import 'package:birdle/data/services/alarm_service.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/notification_service.dart';
import 'package:birdle/data/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storage = StorageService();
  await storage.init();

  // Initialize notification service early so alarms can use it
  final notificationService = NotificationService();
  await notificationService.init();

  BirdleDatabase? database;
  String? dbError;
  try {
    database = BirdleDatabase();
    await database.open();

    // Initialize alarm service and re-register all alarms from DB
    final alarmService = AlarmService();
    alarmService.init(database: database);
    await alarmService.initAlarmManager();
  } catch (e, stack) {
    dbError = '$e\n$stack';
    debugPrint('Failed to initialize database: $dbError');
  }

  runApp(App(database: database, dbError: dbError));
}
