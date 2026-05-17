import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:birdle/data/models/pomodoro_session.dart';

// Data classes
class UsersData {
  final String id;
  final String name;
  final int createdAt;
  const UsersData({required this.id, required this.name, required this.createdAt});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
  };

  factory UsersData.fromMap(Map<String, dynamic> map) => UsersData(
    id: map['id'] as String,
    name: map['name'] as String,
    createdAt: map['created_at'] as int,
  );
}

class TodoListsData {
  final String id;
  final String name;
  final int colorHex;
  final int createdAt;
  final int updatedAt;
  const TodoListsData({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color_hex': colorHex,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory TodoListsData.fromMap(Map<String, dynamic> map) => TodoListsData(
    id: map['id'] as String,
    name: map['name'] as String,
    colorHex: map['color_hex'] as int,
    createdAt: map['created_at'] as int,
    updatedAt: map['updated_at'] as int,
  );
}

class TodoItemsData {
  final String id;
  final String listId;
  final String title;
  final int completed;
  final int colorHex;
  final int? alarmDay;
  final int? alarmHour;
  final int? alarmMinute;
  final int createdAt;
  const TodoItemsData({
    required this.id,
    required this.listId,
    required this.title,
    required this.completed,
    required this.colorHex,
    required this.createdAt,
    this.alarmDay,
    this.alarmHour,
    this.alarmMinute,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'list_id': listId,
    'title': title,
    'completed': completed,
    'color_hex': colorHex,
    'alarm_day': alarmDay,
    'alarm_hour': alarmHour,
    'alarm_minute': alarmMinute,
    'created_at': createdAt,
  };

  factory TodoItemsData.fromMap(Map<String, dynamic> map) => TodoItemsData(
    id: map['id'] as String,
    listId: map['list_id'] as String,
    title: map['title'] as String,
    completed: map['completed'] as int,
    colorHex: map['color_hex'] as int,
    alarmDay: map['alarm_day'] as int?,
    alarmHour: map['alarm_hour'] as int?,
    alarmMinute: map['alarm_minute'] as int?,
    createdAt: map['created_at'] as int,
  );
}

class PomodoroSessionsData {
  final String id;
  final String itemTitle;
  final String listId;
  final int durationMinutes;
  final int status;
  final int startedAt;
  final int? endedAt;
  final int remaining;
  const PomodoroSessionsData({
    required this.id,
    required this.itemTitle,
    required this.listId,
    required this.durationMinutes,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.remaining,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'item_title': itemTitle,
    'list_id': listId,
    'duration_minutes': durationMinutes,
    'status': status,
    'started_at': startedAt,
    'ended_at': endedAt,
    'remaining': remaining,
  };

  factory PomodoroSessionsData.fromMap(Map<String, dynamic> map) => PomodoroSessionsData(
    id: map['id'] as String,
    itemTitle: map['item_title'] as String,
    listId: map['list_id'] as String,
    durationMinutes: map['duration_minutes'] as int,
    status: map['status'] as int,
    startedAt: map['started_at'] as int,
    endedAt: map['ended_at'] as int?,
    remaining: map['remaining'] as int,
  );
}

// Tables (for Drift reference)
class Users {}

class TodoLists {}

class TodoItems {}

class PomodoroSessions {}

  // Database
class BirdleDatabase {
  Database? _db;

  Database get _dbOrThrow {
    if (_db == null) {
      throw StateError('Database not initialized. Call open() first.');
    }
    return _db!;
  }

  Future<void> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'birdle.db');
    _db = await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE todo_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE todo_items (
        id TEXT PRIMARY KEY,
        list_id TEXT NOT NULL,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL,
        color_hex INTEGER NOT NULL,
        alarm_day INTEGER,
        alarm_hour INTEGER,
        alarm_minute INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id TEXT PRIMARY KEY,
        item_title TEXT NOT NULL,
        list_id TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        status INTEGER NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        remaining INTEGER NOT NULL
      )
    ''');
  }

  // UserDao
  Future<void> insertUser(UsersData user) async {
    await _dbOrThrow.insert('users', user.toMap());
  }

  Future<UsersData?> getFirstUser() async {
    final result = await _dbOrThrow.query('users', limit: 1);
    if (result.isEmpty) return null;
    return UsersData.fromMap(result.first);
  }

  Future<void> updateUsers(UsersData user) async {
    await _dbOrThrow.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // ListDao
  Future<void> insertTodoList(TodoListsData list) async {
    await _dbOrThrow.insert('todo_lists', list.toMap());
  }

  Future<List<TodoListsData>> getAllTodoLists() async {
    final result = await _dbOrThrow.query('todo_lists');
    return result.map(TodoListsData.fromMap).toList();
  }

  Future<TodoListsData?> getTodoListById(String id) async {
    final result = await _dbOrThrow.query('todo_lists', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return TodoListsData.fromMap(result.first);
  }

  Future<void> updateTodoList(TodoListsData list) async {
    await _dbOrThrow.update('todo_lists', list.toMap(), where: 'id = ?', whereArgs: [list.id]);
  }

  Future<void> deleteTodoList(String id) async {
    await _dbOrThrow.delete('todo_lists', where: 'id = ?', whereArgs: [id]);
  }

  // ItemDao
  Future<void> insertTodoItem(TodoItemsData item) async {
    await _dbOrThrow.insert('todo_items', item.toMap());
  }

  Future<List<TodoItemsData>> getItemsByList(String listId) async {
    final result = await _dbOrThrow.query('todo_items', where: 'list_id = ?', whereArgs: [listId]);
    return result.map(TodoItemsData.fromMap).toList();
  }

  Future<int> countItemsByList(String listId) async {
    final result = await _dbOrThrow.rawQuery('SELECT COUNT(*) FROM todo_items WHERE list_id = ?', [listId]);
    return result.first.values.first as int;
  }

  Future<TodoItemsData?> getTodoItemById(String id) async {
    final result = await _dbOrThrow.query('todo_items', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return TodoItemsData.fromMap(result.first);
  }

  Future<void> updateTodoItem(TodoItemsData item) async {
    await _dbOrThrow.update('todo_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteTodoItem(String id) async {
    await _dbOrThrow.delete('todo_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TodoItemsData>> getPendingAlarms() async {
    final result = await _dbOrThrow.query('todo_items', where: 'alarm_day IS NOT NULL');
    return result.map(TodoItemsData.fromMap).toList();
  }

  // PomodoroDao
  Future<void> insertPomodoroSession(PomodoroSessionsData session) async {
    await _dbOrThrow.insert('pomodoro_sessions', session.toMap());
  }

  Future<PomodoroSessionsData?> getActivePomodoro() async {
    final result = await _dbOrThrow.query(
      'pomodoro_sessions',
      where: 'status = ?',
      whereArgs: [PomodoroStatus.running.index],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return PomodoroSessionsData.fromMap(result.first);
  }

  Future<void> updatePomodoroSession(PomodoroSessionsData session) async {
    await _dbOrThrow.update(
      'pomodoro_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deletePomodoroSession(String id) async {
    await _dbOrThrow.delete('pomodoro_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PomodoroSessionsData>> getPomodoroHistory() async {
    final result = await _dbOrThrow.query(
      'pomodoro_sessions',
      orderBy: 'started_at DESC',
    );
    return result.map(PomodoroSessionsData.fromMap).toList();
  }
}
