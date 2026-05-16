enum PomodoroStatus { idle, running, paused, completed }

class PomodoroSession {
  final String id;
  final String itemTitle;
  final String listId;
  final int durationMinutes;
  final PomodoroStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration remaining;

  const PomodoroSession({
    required this.id,
    required this.itemTitle,
    required this.listId,
    required this.durationMinutes,
    this.status = PomodoroStatus.idle,
    required this.startedAt,
    this.endedAt,
    required this.remaining,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_title': itemTitle,
      'list_id': listId,
      'duration_minutes': durationMinutes,
      'status': status.index,
      'started_at': startedAt.millisecondsSinceEpoch,
      'ended_at': endedAt?.millisecondsSinceEpoch,
      'remaining': remaining.inSeconds,
    };
  }

  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id'] as String,
      itemTitle: map['item_title'] as String,
      listId: map['list_id'] as String,
      durationMinutes: map['duration_minutes'] as int,
      status: PomodoroStatus.values[map['status'] as int],
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      endedAt: map['ended_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int)
          : null,
      remaining: Duration(seconds: map['remaining'] as int),
    );
  }

  PomodoroSession copyWith({
    PomodoroStatus? status,
    DateTime? endedAt,
    Duration? remaining,
  }) {
    return PomodoroSession(
      id: id,
      itemTitle: itemTitle,
      listId: listId,
      durationMinutes: durationMinutes,
      status: status ?? this.status,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      remaining: remaining ?? this.remaining,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSession && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
