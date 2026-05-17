import 'package:birdle/data/repositories/item_repository.dart';
import 'package:birdle/data/repositories/list_repository.dart';
import 'package:birdle/data/repositories/pomodoro_repository.dart';
import 'package:birdle/data/repositories/user_repository.dart';
import 'package:birdle/data/services/alarm_service.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/foreground_task.dart';
import 'package:birdle/data/services/notification_service.dart';
import 'package:birdle/data/services/storage_service.dart';
import 'package:birdle/ui/view_models/list_list_view_model.dart';
import 'package:birdle/ui/view_models/palette_view_model.dart';
import 'package:birdle/ui/view_models/pomodoro_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> buildProviders({BirdleDatabase? database}) {
  final db = database ?? BirdleDatabase();

  final services = <SingleChildWidget>[
    Provider<StorageService>(
      create: (_) => StorageService(),
    ),
    Provider<BirdleDatabase>(
      create: (_) => db,
    ),
    Provider<AlarmService>(
      create: (_) => AlarmService(),
    ),
    Provider<NotificationService>(
      create: (_) => NotificationService(),
    ),
    Provider<ForegroundTaskService>(
      create: (_) => ForegroundTaskService(),
    ),
  ];

  final repositories = <SingleChildWidget>[
    Provider<UserRepository>(
      create: (ctx) => UserRepository(
        database: ctx.read<BirdleDatabase>(),
        storage: ctx.read<StorageService>(),
      ),
    ),
    Provider<ListRepository>(
      create: (ctx) => ListRepository(database: ctx.read<BirdleDatabase>()),
    ),
    Provider<ItemRepository>(
      create: (ctx) => ItemRepository(
        database: ctx.read<BirdleDatabase>(),
        alarm: ctx.read<AlarmService>(),
      ),
    ),
    Provider<PomodoroRepository>(
      create: (ctx) => PomodoroRepository(
        database: ctx.read<BirdleDatabase>(),
        foregroundTask: ctx.read<ForegroundTaskService>(),
      ),
    ),
  ];

  final viewModels = <SingleChildWidget>[
    ChangeNotifierProvider<PaletteViewModel>(
      create: (ctx) => PaletteViewModel(
        storage: ctx.read<StorageService>(),
      ),
    ),
    ChangeNotifierProvider<ListListViewModel>(
      create: (ctx) => ListListViewModel(
        repository: ctx.read<ListRepository>(),
      ),
    ),
    ChangeNotifierProvider<PomodoroViewModel>(
      create: (ctx) => PomodoroViewModel(
        repository: ctx.read<PomodoroRepository>(),
      ),
    ),
  ];

  return [...services, ...repositories, ...viewModels];
}
