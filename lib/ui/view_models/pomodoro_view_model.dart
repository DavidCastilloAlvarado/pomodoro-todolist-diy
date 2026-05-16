import 'dart:async';
import 'package:flutter/material.dart';
import 'package:birdle/data/models/pomodoro_session.dart';
import 'package:birdle/data/repositories/pomodoro_repository.dart';
import 'package:uuid/uuid.dart';

class PomodoroViewModel extends ChangeNotifier {
  PomodoroViewModel({required PomodoroRepository repository})
      : _repository = repository;

  final PomodoroRepository _repository;

  PomodoroSession? _session;
  PomodoroSession? get session => _session;

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  PomodoroStatus get status => _session?.status ?? PomodoroStatus.idle;

  bool get isRunning => status == PomodoroStatus.running;

  Timer? _timer;

  Future<void> loadActiveSession() async {
    _session = await _repository.getActiveSession();
    if (_session != null) {
      _remainingSeconds = _session!.remaining.inSeconds;
      notifyListeners();
    }
  }

  Future<void> startSession({
    required String itemTitle,
    required String listId,
    required int durationMinutes,
  }) async {
    final session = PomodoroSession(
      id: _uuid.v4(),
      itemTitle: itemTitle,
      listId: listId,
      durationMinutes: durationMinutes,
      status: PomodoroStatus.running,
      startedAt: DateTime.now(),
      remaining: Duration(minutes: durationMinutes),
    );
    _session = session;
    _remainingSeconds = durationMinutes * 60;
    await _repository.startSession(session);
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_session != null && _session!.status == PomodoroStatus.running) {
        final remaining = _session!.remaining - const Duration(seconds: 1);
        _session = _session!.copyWith(remaining: remaining);
        _remainingSeconds = remaining.inSeconds;
        notifyListeners();

        if (remaining.inSeconds <= 0) {
          _completeSession();
        }
      }
    });
  }

  Future<void> pauseSession() async {
    _timer?.cancel();
    await _repository.pauseSession();
    _session = _session?.copyWith(status: PomodoroStatus.paused);
    notifyListeners();
  }

  Future<void> resumeSession() async {
    await _repository.resumeSession();
    _session = _session?.copyWith(status: PomodoroStatus.running);
    _startTimer();
    notifyListeners();
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _timer = null;
    await _repository.completeSession();
    _session = _session?.copyWith(
      status: PomodoroStatus.completed,
      remaining: Duration.zero,
    );
    _remainingSeconds = 0;
    notifyListeners();
  }

  Future<void> cancelSession() async {
    _timer?.cancel();
    _timer = null;
    await _repository.pauseSession();
    _session = null;
    _remainingSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final _uuid = const Uuid();
