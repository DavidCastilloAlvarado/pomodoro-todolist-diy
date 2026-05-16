name: phase1_fix_errors
phase: 1
description: >
  Fix all dart analyze errors in Phase 1 foundation files to achieve a clean build.
files:
  - lib/data/services/database.dart
  - lib/di/di_container.dart
  - lib/core/themes/palettes.dart
  - lib/ui/view_models/palette_view_model.dart
  - lib/ui/view_models/list_list_view_model.dart
  - lib/ui/view_models/pomodoro_view_model.dart
  - lib/ui/screens/splash/splash_screen.dart
  - lib/app.dart
  - lib/data/services/alarm_service.dart
  - lib/data/services/foreground_task.dart
  - lib/data/repositories/user_repository.dart
  - lib/data/repositories/list_repository.dart
  - lib/data/repositories/item_repository.dart
  - lib/data/repositories/pomodoro_repository.dart
completion_criteria:
  - [x] dart analyze reports 0 errors
  - [x] database.dart uses correct Drift types (IntColumn for integer, TextColumn for text, DateTimeColumn for dateTime)
  - [x] database.dart table classes follow Drift conventions (auto-generated names like UsersTable, TodoListsTable)
  - [x] database.dart data classes properly defined (UsersData, TodoListsData, TodoItemsData, PomodoroSessionsData)
  - [x] di_container.dart imports SingleChildWidget from provider
  - [x] palettes.dart uses valid Color values (no Colors.emerald or Colors.violet)
  - [x] palette_view_model.dart has single constructor, references palettes correctly
  - [x] uuid import added to view models that use Uuid
  - [x] alarm_service.dart imports Color, TimeOfDay, AndroidAlarmOptions
  - [x] foreground_task.dart uses correct FlutterForegroundTask API
  - [x] splash_screen.dart imports OnboardingScreen and AppShell
  - [x] app.dart null safety resolved for colorScheme access
status: complete
