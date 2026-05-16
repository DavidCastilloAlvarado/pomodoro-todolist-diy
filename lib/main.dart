import 'package:birdle/app.dart';
import 'package:birdle/data/services/database.dart';
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

  BirdleDatabase? database;
  String? dbError;
  try {
    database = BirdleDatabase();
    await database.open();
  } catch (e, stack) {
    dbError = '$e\n$stack';
    debugPrint('Failed to initialize database: $dbError');
  }

  runApp(App(database: database, dbError: dbError));
}
