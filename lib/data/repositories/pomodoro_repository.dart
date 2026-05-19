import 'package:birdle/data/models/pomodoro_session.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/foreground_task.dart';

class PomodoroRepository {
  PomodoroRepository({
    required BirdleDatabase database,
    required ForegroundTaskService foregroundTask,
  }) : _db = database, _foregroundTask = foregroundTask;

  final BirdleDatabase _db;
  final ForegroundTaskService _foregroundTask;

  Future<PomodoroSession?> getActiveSession() async {
    final data = await _db.getActivePomodoro();
    if (data == null) return null;
    return PomodoroSession(
      id: data.id,
      itemTitle: data.itemTitle,
      listId: data.listId,
      durationMinutes: data.durationMinutes,
      status: PomodoroStatus.values[data.status],
      startedAt: DateTime.fromMillisecondsSinceEpoch(data.startedAt),
      endedAt: data.endedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(data.endedAt!)
          : null,
      remaining: Duration(seconds: data.remaining),
      currentPhase: data.currentPhase,
      completedSessions: data.completedSessions,
    );
  }

  Future<void> startSession(PomodoroSession session) async {
    await _db.insertPomodoroSession(PomodoroSessionsData(
      id: session.id,
      itemTitle: session.itemTitle,
      listId: session.listId,
      durationMinutes: session.durationMinutes,
      status: session.status.index,
      startedAt: session.startedAt.millisecondsSinceEpoch,
      endedAt: session.endedAt?.millisecondsSinceEpoch,
      remaining: session.remaining.inSeconds,
      currentPhase: session.currentPhase,
      completedSessions: session.completedSessions,
    ));
    await _foregroundTask.startPomodoroTask(session);
  }

  Future<void> pauseSession() async {
    await _foregroundTask.stopPomodoroTask();
    final session = await getActiveSession();
    if (session != null) {
      final updated = session.copyWith(status: PomodoroStatus.paused);
      await _db.updatePomodoroSession(PomodoroSessionsData(
        id: updated.id,
        itemTitle: updated.itemTitle,
        listId: updated.listId,
        durationMinutes: updated.durationMinutes,
        status: updated.status.index,
        startedAt: updated.startedAt.millisecondsSinceEpoch,
        endedAt: updated.endedAt?.millisecondsSinceEpoch,
        remaining: updated.remaining.inSeconds,
        currentPhase: updated.currentPhase,
        completedSessions: updated.completedSessions,
      ));
    }
  }

  Future<void> resumeSession() async {
    final session = await getActiveSession();
    if (session != null && session.status == PomodoroStatus.paused) {
      await _foregroundTask.startPomodoroTask(session);
      final updated = session.copyWith(status: PomodoroStatus.running);
      await _db.updatePomodoroSession(PomodoroSessionsData(
        id: updated.id,
        itemTitle: updated.itemTitle,
        listId: updated.listId,
        durationMinutes: updated.durationMinutes,
        status: updated.status.index,
        startedAt: updated.startedAt.millisecondsSinceEpoch,
        endedAt: updated.endedAt?.millisecondsSinceEpoch,
        remaining: updated.remaining.inSeconds,
        currentPhase: updated.currentPhase,
        completedSessions: updated.completedSessions,
      ));
    }
  }

  Future<void> completeSession() async {
    await _foregroundTask.stopPomodoroTask();
    final session = await getActiveSession();
    if (session != null) {
      final updated = session.copyWith(
        status: PomodoroStatus.completed,
        endedAt: DateTime.now(),
        remaining: Duration.zero,
      );
      await _db.updatePomodoroSession(PomodoroSessionsData(
        id: updated.id,
        itemTitle: updated.itemTitle,
        listId: updated.listId,
        durationMinutes: updated.durationMinutes,
        status: updated.status.index,
        startedAt: updated.startedAt.millisecondsSinceEpoch,
        endedAt: updated.endedAt?.millisecondsSinceEpoch,
        remaining: updated.remaining.inSeconds,
        currentPhase: updated.currentPhase,
        completedSessions: updated.completedSessions,
      ));
    }
  }

  Future<void> deleteActiveSession() async {
    await _foregroundTask.stopPomodoroTask();
    final session = await getActiveSession();
    if (session != null) {
      await _db.deletePomodoroSession(session.id);
    }
  }

  Future<List<PomodoroSession>> getHistory() async {
    final data = await _db.getPomodoroHistory();
    return data.map((d) => PomodoroSession(
      id: d.id,
      itemTitle: d.itemTitle,
      listId: d.listId,
      durationMinutes: d.durationMinutes,
      status: PomodoroStatus.values[d.status],
      startedAt: DateTime.fromMillisecondsSinceEpoch(d.startedAt),
      endedAt: d.endedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(d.endedAt!)
          : null,
      remaining: Duration(seconds: d.remaining),
      currentPhase: d.currentPhase,
      completedSessions: d.completedSessions,
    )).toList();
  }
}
