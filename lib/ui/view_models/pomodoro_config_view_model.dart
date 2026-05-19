import 'dart:async';
import 'package:birdle/data/services/storage_service.dart';
import 'package:flutter/foundation.dart';

/// Holds the three configurable Pomodoro durations.
/// Extends [ChangeNotifier] so the [PomodoroViewModel] can listen for
/// changes when the user updates durations in Settings.
class PomodoroDurations extends ChangeNotifier implements ValueListenable<PomodoroDurations> {
  PomodoroDurations({
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.longBreakMinutes = 15,
  });

  int workMinutes;
  int breakMinutes;
  int longBreakMinutes;

  void update({
    required int workMinutes,
    required int breakMinutes,
    required int longBreakMinutes,
  }) {
    this.workMinutes = workMinutes;
    this.breakMinutes = breakMinutes;
    this.longBreakMinutes = longBreakMinutes;
    notifyListeners();
  }

  @override
  PomodoroDurations get value => this;

  @override
  String toString() => 'PomodoroDurations(work: $workMinutes, break: $breakMinutes, longBreak: $longBreakMinutes)';
}

/// Manages the three configurable Pomodoro durations.
/// Loads from [StorageService] on construction and persists changes.
/// **CRITICAL:** `notifyListeners()` is called immediately after any
/// duration change so the Pomodoro screen refreshes.
class PomodoroConfigViewModel extends ChangeNotifier {
  PomodoroConfigViewModel({required StorageService storage}) : _storage = storage {
    _loadDurations();
  }

  final StorageService _storage;

  final PomodoroDurations _durations = PomodoroDurations(
    workMinutes: 25,
    breakMinutes: 5,
    longBreakMinutes: 15,
  );
  PomodoroDurations get durations => _durations;

  /// Exposes durations as a [ValueListenable] so the [PomodoroViewModel]
  /// can listen for changes via `valueListenable(durations)`.
  ValueListenable<PomodoroDurations> get durationsValue => _durations;

  int get workMinutes => _durations.workMinutes;
  int get breakMinutes => _durations.breakMinutes;
  int get longBreakMinutes => _durations.longBreakMinutes;

  Future<void> _loadDurations() async {
    _durations.update(
      workMinutes: _storage.getPomodoroWorkMinutes(),
      breakMinutes: _storage.getPomodoroBreakMinutes(),
      longBreakMinutes: _storage.getPomodoroLongBreakMinutes(),
    );
    notifyListeners();
  }

  /// Public method to reload durations from storage.
  Future<void> loadDurations() async {
    await _loadDurations();
  }

  /// Saves all three durations to storage and calls [notifyListeners]
  /// immediately so the Pomodoro screen refreshes.
  Future<void> saveDurations({
    required int workMinutes,
    required int breakMinutes,
    required int longBreakMinutes,
  }) async {
    await _storage.savePomodoroDurations(
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
      longBreakMinutes: longBreakMinutes,
    );
    _durations.update(
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
      longBreakMinutes: longBreakMinutes,
    );
    notifyListeners();
  }
}
