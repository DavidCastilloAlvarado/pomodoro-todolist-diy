name: phase1_foundation
phase: 1
description: >
  Build the foundation layer: add dependencies, create data models, Drift database
  schema with DAOs, service layer wrappers, repositories, palette definitions, and
  DI container setup.
files:
  - pubspec.yaml (add dependencies)
  - lib/data/models/user.dart
  - lib/data/models/todo_list.dart
  - lib/data/models/todo_item.dart
  - lib/data/models/pomodoro_session.dart
  - lib/data/services/database.dart (Drift database + all DAOs)
  - lib/data/services/storage_service.dart
  - lib/data/services/alarm_service.dart
  - lib/data/services/notification_service.dart
  - lib/data/services/foreground_task.dart
  - lib/data/repositories/user_repository.dart
  - lib/data/repositories/list_repository.dart
  - lib/data/repositories/item_repository.dart
  - lib/data/repositories/pomodoro_repository.dart
  - lib/core/themes/palettes.dart
  - lib/di/di_container.dart
  - lib/main.dart (update)
  - lib/app.dart
completion_criteria:
  - [x] All Phase 1 dependencies added to pubspec.yaml (sqflite, drift, flutter_local_notifications, android_alarm_manager_plus, workmanager, flutter_foreground_task, shared_preferences, uuid, intl, provider)
  - [x] 4 data models created: User, TodoList, TodoItem, PomodoroSession with all fields from architecture.md
  - [x] Drift database defined with 4 tables (UserDao, TodoListDao, TodoItemDao, PomodoroDao) matching architecture.md schema
  - [x] DAO interfaces implemented with all CRUD methods from architecture.md
  - [x] StorageService created with name/palette/firstLaunch methods
  - [x] AlarmService created with schedule/cancel/reRegister methods
  - [x] NotificationService created with show/cancel/init methods
  - [x] ForegroundTaskService created with start/stop/updateNotification methods
  - [x] 4 repositories created (User, List, Item, Pomodoro) following architecture.md patterns
  - [x] 7 color palettes defined in palettes.dart (default, dark, ocean, sunset, forest, lavender, high_contrast)
  - [x] DI container set up with all services, repositories, and ViewModels via Provider
  - [x] dart analyze passes with no errors
status: complete
