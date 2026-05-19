import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:birdle/data/models/pomodoro_session.dart';
import 'package:birdle/data/repositories/pomodoro_repository.dart';
import 'package:birdle/data/services/foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:uuid/uuid.dart';

class PomodoroViewModel extends ChangeNotifier {
  PomodoroViewModel({required PomodoroRepository repository})
      : _repository = repository {
    _initForegroundStream();
    _initForegroundTaskCallback();
  }

  final PomodoroRepository _repository;
  Timer? _timer;
  StreamSubscription<int>? _foregroundSubscription;

  PomodoroSession? _session;
  PomodoroSession? get session => _session;

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  PomodoroStatus get status => _session?.status ?? PomodoroStatus.idle;

  bool get isRunning => status == PomodoroStatus.running;

  void _initForegroundStream() {
    _foregroundSubscription =
        ForegroundTaskService().remainingSecondsStream.listen((seconds) {
      _remainingSeconds = seconds;
      notifyListeners();
    });
  }

  void _initForegroundTaskCallback() {
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  }

  void _onForegroundTaskData(Object data) {
    if (data is Map && data['type'] == 'pomodoro_complete') {
      // Only play sound + vibrate if the app is in the foreground
      // and a session is still active.
      if (status == PomodoroStatus.running ||
          status == PomodoroStatus.paused) {
        _playCompletionSound();
        HapticFeedback.vibrate();
      }
    }
  }

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

    // Sound + vibration on completion (app is in foreground)
    _playCompletionSound();
    HapticFeedback.vibrate();

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
    _foregroundSubscription?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Sound ────────────────────────────────────────────────────────

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/complete.mp3'));
    } catch (_) {
      // Sound playback failed silently
    }
  }
}

final _uuid = const Uuid();
