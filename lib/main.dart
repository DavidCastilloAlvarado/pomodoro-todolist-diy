import 'package:birdle/app.dart';
import 'package:birdle/data/services/alarm_service.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/notification_service.dart';
import 'package:birdle/data/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef StorageInitializer = Future<void> Function();
typedef PreferredOrientationsSetter =
    Future<void> Function(List<DeviceOrientation> orientations);
typedef AppRunner = void Function(Widget app);

Future<Widget> bootstrapBirdleApp({
  StorageInitializer? storageInitializer,
  PreferredOrientationsSetter? preferredOrientationsSetter,
  NotificationService? notificationService,
  BirdleDatabase Function()? databaseFactory,
  AlarmService? alarmService,
  AppRunner? appRunner,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await (preferredOrientationsSetter ?? SystemChrome.setPreferredOrientations)([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await (storageInitializer ??
      () async {
        final storage = StorageService();
        await storage.init();
      })();

  // Initialize notification service early so alarms can use it
  final resolvedNotificationService =
      notificationService ?? NotificationService();
  try {
    await resolvedNotificationService.init();

    // Request notification permission on Android 13+
    await resolvedNotificationService.requestNotificationPermission();

    // Request exact alarm permission on Android 12+
    final exactAlarmOk = await resolvedNotificationService
        .requestExactAlarmPermission();
    if (!exactAlarmOk) {
      debugPrint(
        'NotificationService: Could not grant exact alarm permission — alarms may not fire reliably',
      );
    }
  } catch (error, stackTrace) {
    debugPrint(
      'NotificationService: Startup initialization failed, continuing app startup: $error',
    );
    debugPrintStack(
      label: 'NotificationService startup failure',
      stackTrace: stackTrace,
    );
  }

  BirdleDatabase? database;
  String? dbError;
  try {
    database = (databaseFactory ?? BirdleDatabase.new)();
    await database.open();

    // Initialize alarm service and re-register all alarms from DB
    final resolvedAlarmService = alarmService ?? AlarmService();
    resolvedAlarmService.init(database: database);
    await resolvedAlarmService.initAlarmManager();
  } catch (e, stack) {
    dbError = '$e\n$stack';
    debugPrint('Failed to initialize database: $dbError');
  }

  final app = App(database: database, dbError: dbError);
  if (appRunner != null) {
    appRunner(app);
  } else {
    runApp(app);
  }

  return app;
}

Future<void> main() async {
  await bootstrapBirdleApp();
}
