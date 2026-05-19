import 'package:birdle/data/services/storage_service.dart';
import 'package:flutter/material.dart';

class PomodoroConfigViewModel extends ChangeNotifier {
  PomodoroConfigViewModel({required StorageService storage}) : _storage = storage {
    _loadDurations();
  }

  final StorageService _storage;
  List<int> _durations = [];
  List<int> get durations => List.unmodifiable(_durations);

  Future<void> _loadDurations() async {
    final stored = _storage.getPomodoroDurations();
    _durations = stored.isNotEmpty
        ? stored
        : List.from(StorageService.defaultPomodoroDurations);
    notifyListeners();
  }

  Future<void> loadDurations() async {
    await _loadDurations();
  }

  Future<void> saveDurations(List<int> durations) async {
    await _storage.savePomodoroDurations(durations);
    _durations = List.from(durations);
    notifyListeners();
  }
}
