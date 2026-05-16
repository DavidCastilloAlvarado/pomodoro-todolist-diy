# Birdle Todo App — Architecture Design

> Follows the **MVVM + Repository** pattern from Flutter architecture best practices.
> Strict separation of concerns across UI, Logic (ViewModel), and Data layers.

---

## Architectural Layers

```
┌─────────────────────────────────────────────────────┐
│                   UI Layer (MVVM)                    │
│  ┌──────────┐    ┌──────────┐    ┌──────────────┐  │
│  │  Views    │    │ViewModels│    │  PaletteBar  │  │
│  │ (Widgets) │◄── │(Notifier)│◄── │  (Widget)    │  │
│  └──────────┘    └──────────┘    └──────────────┘  │
├─────────────────────────────────────────────────────┤
│                 Logic Layer (ViewModel)              │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐  │
│  │UserVM      │  │ListVM      │  │ItemVM        │  │
│  │PomodoroVM  │  │PaletteVM   │  │AlarmVM       │  │
│  └────────────┘  └────────────┘  └──────────────┘  │
├─────────────────────────────────────────────────────┤
│                 Data Layer (Repository)              │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │Services  │  │Repos     │  │  AlarmManager    │  │
│  │(Stateless)│ │(CRUD)    │  │  (Native bridge) │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
├─────────────────────────────────────────────────────┤
│              Persistence & Platform                    │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Drift   │  │SharedPreferences│ │  Android     │  │
│  │ (SQLite) │  │              │  │  Services     │  │
│  └──────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## Project Structure

```
lib/
├── main.dart                          # Entry point, runApp
├── app.dart                          # MaterialApp, routes, theme provider scope
│
├── core/                             # Shared infrastructure
│   ├── themes/
│   │   ├── palettes.dart             # 7 color palette definitions
│   │   └── theme_extensions.dart     # Palette-aware color extensions
│   ├── widgets/
│   │   ├── palette_bar.dart          # Top bar: 7 palette swatches
│   │   ├── color_picker_dialog.dart  # Reusable color picker
│   │   └── alarm_picker_dialog.dart  # Day + time picker
│   └── constants.dart               # App-wide constants
│
├── data/
│   ├── models/
│   │   ├── user.dart                 # Domain model: User
│   │   ├── todo_list.dart            # Domain model: TodoList
│   │   ├── todo_item.dart            # Domain model: TodoItem
│   │   └── pomodoro_session.dart     # Domain model: PomodoroSession
│   ├── repositories/
│   │   ├── user_repository.dart      # User CRUD
│   │   ├── list_repository.dart      # TodoList CRUD
│   │   ├── item_repository.dart      # TodoItem CRUD + completion
│   │   └── pomodoro_repository.dart  # PomodoroSession CRUD
│   └── services/
│       ├── database.dart             # Drift database definition + DAOs
│       ├── storage_service.dart      # SharedPreferences wrapper
│       ├── alarm_service.dart        # android_alarm_manager_plus wrapper
│       ├── notification_service.dart # flutter_local_notifications wrapper
│       └── foreground_task.dart      # flutter_foreground_task wrapper
│
├── ui/
│   ├── screens/
│   │   ├── splash/
│   │   │   ├── splash_screen.dart    # View: image, 2s delay
│   │   │   └── splash_view_model.dart
│   │   ├── onboarding/
│   │   │   ├── onboarding_screen.dart   # View: name input
│   │   │   └── onboarding_view_model.dart
│   │   ├── app_shell/
│   │   │   ├── app_shell.dart           # Scaffold with palette bar + page view
│   │   │   └── app_shell_view_model.dart
│   │   ├── list_list/
│   │   │   ├── list_list_view.dart      # Grid of list cards
│   │   │   └── list_list_view_model.dart
│   │   └── item_detail/
│   │       ├── item_detail_page.dart    # List of items with colors
│   │       └── item_detail_view_model.dart
│   │
│   └── widgets/
│       ├── pomodoro/
│       │   ├── pomodoro_widget.dart     # Bottom-left floating timer
│       │   └── pomodoro_view_model.dart
│       ├── list_card.dart               # Reusable list card widget
│       └── item_tile.dart               # Reusable item tile widget
│
└── di/
    └── di_container.dart                # Provider scopes + dependency registration
```

---

## Data Models (Domain Layer)

### User

```dart
class User {
  final String id;
  final String name;
  final DateTime createdAt;

  User({required this.id, required this.name, required this.createdAt});
}
```

**Responsibilities:**
- Stores the user's display name
- Created once during onboarding
- Used for future multi-user support

### TodoList

```dart
class TodoList {
  final String id;
  final String name;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoList({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  TodoList copyWith({String? name, Color? color}) {
    return TodoList(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
```

**Responsibilities:**
- Container for TodoItem objects
- Has its own color for visual distinction
- Tracks creation/update timestamps

### TodoItem

```dart
class TodoItem {
  final String id;
  final String listId;
  final String title;
  final bool completed;
  final Color color;
  final AlarmInfo? alarm;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.listId,
    required this.title,
    this.completed = false,
    required this.color,
    this.alarm,
    required this.createdAt,
  });

  TodoItem copyWith({
    String? title,
    bool? completed,
    Color? color,
    AlarmInfo? alarm,
  }) {
    return TodoItem(
      id: id,
      listId: listId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      color: color ?? this.color,
      alarm: alarm ?? this.alarm,
      createdAt: createdAt,
    );
  }
}

class AlarmInfo {
  final DayOfWeek day;
  final TimeOfDay time;

  AlarmInfo({required this.day, required this.time});
}

enum DayOfWeek {
  monday, tuesday, wednesday, thursday, friday, saturday, sunday, everyDay;
}
```

**Responsibilities:**
- Represents a single todo item
- Has its own color for visual distinction
- Optional alarm with day and time
- Tracks completion state

### PomodoroSession

```dart
class PomodoroSession {
  final String id;
  final String itemTitle;
  final String listId;
  final int durationMinutes;
  final PomodoroStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration remaining;

  PomodoroSession({
    required this.id,
    required this.itemTitle,
    required this.listId,
    required this.durationMinutes,
    this.status = PomodoroStatus.idle,
    required this.startedAt,
    this.endedAt,
    required this.remaining,
  });

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
}

enum PomodoroStatus { idle, running, paused, completed }
```

**Responsibilities:**
- Tracks a single pomodoro session
- Stores the associated todo item title
- Tracks elapsed/remaining time
- Supports start/pause/resume/complete lifecycle

---

## Data Layer — Services (Stateless Wrappers)

Each service wraps a third-party plugin or system API. All services are stateless singletons.

### Database Service (Drift)

```
data/services/database.dart
├── BirdleDatabase (DriftDatabase)
│   ├── UserDao
│   ├── ListDao
│   ├── ItemDao
│   └── PomodoroDao
```

**Responsibilities:**
- Manages SQLite database connection
- Defines table schemas (UserDao, ListDao, ItemDao, PomodoroDao)
- Exposes CRUD operations per table
- Handles migrations

**DAO Interfaces:**

```dart
// UserDao
abstract class UserDao {
  Future<void> insert(User user);
  Future<User?> getFirst();
  Future<void> update(User user);
}

// ListDao
abstract class ListDao {
  Future<void> insert(TodoList list);
  Future<List<TodoList>> getAll();
  Future<TodoList?> getById(String id);
  Future<void> update(TodoList list);
  Future<void> delete(String id);
}

// ItemDao
abstract class ItemDao {
  Future<void> insert(TodoItem item);
  Future<List<TodoItem>> getByList(String listId);
  Future<TodoItem?> getById(String id);
  Future<void> update(TodoItem item);
  Future<void> delete(String id);
  Future<List<TodoItem>> getPendingAlarms();
}

// PomodoroDao
abstract class PomodoroDao {
  Future<void> insert(PomodoroSession session);
  Future<PomodoroSession?> getActive();
  Future<void> update(PomodoroSession session);
  Future<void> delete(String id);
  Future<List<PomodoroSession>> getHistory();
}
```

### Storage Service

```
data/services/storage_service.dart
├── String? getName()
├── Future<void> saveName(String)
├── String getPalette()
├── Future<void> savePalette(String)
├── bool isFirstLaunch()
└── Future<void> completeOnboarding()
```

**Responsibilities:**
- Wraps `shared_preferences`
- Stores user name (persisted across launches)
- Stores current palette selection
- Tracks first-launch state for onboarding flow

### Alarm Service

```
data/services/alarm_service.dart
├── Future<void> scheduleAlarm(TodoItem)
├── Future<void> cancelAlarm(String itemId)
├── Future<void> reRegisterAllAlarms()   // called by BootReceiver
├── List<AlarmInfo> getPendingAlarms()
└── Future<void> init()
```

**Responsibilities:**
- Wraps `android_alarm_manager_plus`
- Schedules inexact alarms (battery-friendly)
- Re-registers alarms after device reboot (called by BootReceiver)
- Queries pending alarms from database

**Implementation notes:**
- Uses `alarmManager.setInexactAlarm()` for battery efficiency
- Alarm day is stored as integer (0-6) + flag for recurring
- On each scheduled trigger, checks if the alarm should fire (day match, time window)
- If alarm should fire, delegates to NotificationService

### Notification Service

```
data/services/notification_service.dart
├── Future<void> showNotification(String title, String body, {int id})
├── Future<void> cancelNotification(String id)
├── Future<void> cancelAll()
└── Future<void> init()
```

**Responsibilities:**
- Wraps `flutter_local_notifications`
- Shows notification when item alarm triggers
- Shows countdown notification during pomodoro
- Works with screen off (Android notification channel)

**Android setup:**
- Creates notification channel on init
- Uses `NotificationDetails` with priority/maxPriority for heads-up notifications
- Handles permission request for `POST_NOTIFICATIONS` (Android 13+)

### Foreground Task Service

```
data/services/foreground_task.dart
├── Future<void> startPomodoroTask(PomodoroSession)
├── Future<void> stopPomodoroTask()
├── Stream<int> getRemainingSecondsStream()
└── Future<void> updateNotification(String title, int remaining)
```

**Responsibilities:**
- Wraps `flutter_foreground_task`
- Runs pomodoro countdown in foreground service
- Updates notification with remaining time
- Keeps timer alive when screen is off

**Implementation notes:**
- Uses `FlutterForegroundTask.startService()` with notification
- Timer ticks every second in the background
- On completion, calls `stopService()` and notifies user
- Handles lifecycle: app backgrounded → service continues → app foregrounded → syncs state

---

## Data Layer — Repositories

Each repository consumes one or more services and returns domain models. Repositories are the single source of truth.

```
data/repositories/
├── user_repository.dart          → consumes DatabaseService + StorageService
├── list_repository.dart          → consumes DatabaseService
├── item_repository.dart          → consumes DatabaseService + AlarmService
└── pomodoro_repository.dart      → consumes DatabaseService + ForegroundTaskService
```

### UserRepository

```dart
class UserRepository {
  UserRepository({
    required DatabaseService database,
    required StorageService storage,
  }) : _db = database, _storage = storage;

  final DatabaseService _db;
  final StorageService _storage;

  Future<void> saveUser(String name) async {
    final user = User(
      id: uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _db.userDao.insert(user);
    await _storage.saveName(name);
  }

  Future<User?> getUser() async {
    return await _db.userDao.getFirst();
  }

  Future<bool> isFirstLaunch() async {
    return _storage.isFirstLaunch();
  }

  Future<void> completeOnboarding() async {
    await _storage.completeOnboarding();
  }
}
```

### ListRepository

```dart
class ListRepository {
  ListRepository({required DatabaseService database}) : _db = database;

  final DatabaseService _db;

  Future<List<TodoList>> getAllLists() async {
    return await _db.listDao.getAll();
  }

  Future<void> addList(TodoList list) async {
    await _db.listDao.insert(list);
  }

  Future<void> updateList(TodoList list) async {
    await _db.listDao.update(list);
  }

  Future<void> deleteList(String id) async {
    await _db.listDao.delete(id);
  }

  Future<TodoList?> getListById(String id) async {
    return await _db.listDao.getById(id);
  }
}
```

### ItemRepository

```dart
class ItemRepository {
  ItemRepository({
    required DatabaseService database,
    required AlarmService alarm,
  }) : _db = database, _alarm = alarm;

  final DatabaseService _db;
  final AlarmService _alarm;

  Future<List<TodoItem>> getItems(String listId) async {
    return await _db.itemDao.getByList(listId);
  }

  Future<void> addItem(TodoItem item) async {
    await _db.itemDao.insert(item);
    if (item.alarm != null) {
      await _alarm.scheduleAlarm(item);
    }
  }

  Future<void> updateItem(TodoItem item) async {
    await _db.itemDao.update(item);
    // Handle alarm changes
    if (item.alarm != null) {
      await _alarm.scheduleAlarm(item);
    }
  }

  Future<void> toggleCompleted(String itemId) async {
    final item = await _db.itemDao.getById(itemId);
    if (item != null) {
      final updated = item.copyWith(completed: !item.completed);
      await _db.itemDao.update(updated);
      if (item.completed) {
        // Alarm was set, now cancelled
        await _alarm.cancelAlarm(itemId);
      }
    }
  }

  Future<void> deleteItem(String itemId) async {
    await _alarm.cancelAlarm(itemId);
    await _db.itemDao.delete(itemId);
  }

  Future<void> reRegisterAllAlarms() async {
    final pending = await _db.itemDao.getPendingAlarms();
    for (final item in pending) {
      await _alarm.scheduleAlarm(item);
    }
  }
}
```

### PomodoroRepository

```dart
class PomodoroRepository {
  PomodoroRepository({
    required DatabaseService database,
    required ForegroundTaskService foregroundTask,
  }) : _db = database, _foregroundTask = foregroundTask;

  final DatabaseService _db;
  final ForegroundTaskService _foregroundTask;

  Future<PomodoroSession?> getActiveSession() async {
    return await _db.pomodoroDao.getActive();
  }

  Future<void> startSession(PomodoroSession session) async {
    await _db.pomodoroDao.insert(session);
    await _foregroundTask.startPomodoroTask(session);
  }

  Future<void> pauseSession() async {
    await _foregroundTask.stopPomodoroTask();
    final session = await _db.pomodoroDao.getActive();
    if (session != null) {
      await _db.pomodoroDao.update(session.copyWith(status: PomodoroStatus.paused));
    }
  }

  Future<void> resumeSession() async {
    final session = await _db.pomodoroDao.getActive();
    if (session != null && session.status == PomodoroStatus.paused) {
      await _foregroundTask.startPomodoroTask(session);
      await _db.pomodoroDao.update(session.copyWith(status: PomodoroStatus.running));
    }
  }

  Future<void> completeSession() async {
    await _foregroundTask.stopPomodoroTask();
    final session = await _db.pomodoroDao.getActive();
    if (session != null) {
      await _db.pomodoroDao.update(session.copyWith(
        status: PomodoroStatus.completed,
        endedAt: DateTime.now(),
        remaining: Duration.zero,
      ));
    }
  }

  Future<List<PomodoroSession>> getHistory() async {
    return await _db.pomodoroDao.getHistory();
  }
}
```

---

## Logic Layer — ViewModels

All ViewModels extend `ChangeNotifier`. Injected via constructor (injected by Provider).

```
ui/
├── screens/
│   ├── splash/
│   │   └── splash_view_model.dart     // navigate after delay
│   ├── onboarding/
│   │   └── onboarding_view_model.dart // save name
│   ├── app_shell/
│   │   └── app_shell_view_model.dart  // manage page index
│   ├── list_list/
│   │   └── list_list_view_model.dart  // lists CRUD
│   └── item_detail/
│       └── item_detail_view_model.dart // items CRUD + alarm
│
└── widgets/
    └── pomodoro/
        └── pomodoro_view_model.dart    // timer control + foreground task
```

### SplashViewModel

```dart
class SplashViewModel extends ChangeNotifier {
  SplashViewModel({required UserRepository userRepo}) : _userRepo = userRepo;

  final UserRepository _userRepo;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _hasUser = false;
  bool get hasUser => _hasUser;

  Future<void> initialize() async {
    // Simulate splash delay
    await Future.delayed(const Duration(seconds: 2));
    _hasUser = !await _userRepo.isFirstLaunch();
    _isLoading = false;
    notifyListeners();
  }
}
```

### OnboardingViewModel

```dart
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({required UserRepository userRepo}) : _userRepo = userRepo;

  final UserRepository _userRepo;

  String _name = '';
  String get name => _name;

  bool _isValid => _name.trim().isNotEmpty;

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (!_isValid) return false;
    await _userRepo.saveUser(_name.trim());
    await _userRepo.completeOnboarding();
    return true;
  }
}
```

### PaletteViewModel

```dart
class PaletteViewModel extends ChangeNotifier {
  PaletteViewModel({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  String _currentPalette = 'default';
  String get currentPalette => _currentPalette;

  ColorScheme get colorScheme => palettes[_currentPalette]!.light;
  ColorScheme get darkColorScheme => palettes[_currentPalette]!.dark;

  List<Palette> get allPalettes => palettes.values.toList();

  Future<void> setPalette(String name) async {
    _currentPalette = name;
    await _storage.savePalette(name);
    notifyListeners();
  }
}
```

### ListListViewModel

```dart
class ListListViewModel extends ChangeNotifier {
  ListListViewModel({required ListRepository repository})
      : _repository = repository;

  final ListRepository _repository;

  List<TodoList> _lists = [];
  List<TodoList> get lists => List.unmodifiable(_lists);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadLists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _lists = await _repository.getAllLists();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addList(String name, Color color) async {
    final list = TodoList(
      id: uuid.v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.addList(list);
    _lists = [..._lists, list];
    notifyListeners();
  }

  Future<void> deleteList(String id) async {
    await _repository.deleteList(id);
    _lists = _lists.where((l) => l.id != id).toList();
    notifyListeners();
  }
}
```

### ItemDetailViewModel

```dart
class ItemDetailViewModel extends ChangeNotifier {
  ItemDetailViewModel({
    required ItemRepository repository,
    required String listId,
  }) : _repository = repository, _listId = listId;

  final ItemRepository _repository;
  final String _listId;

  List<TodoItem> _items = [];
  List<TodoItem> get items => List.unmodifiable(_items);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repository.getItems(_listId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(String title, Color color) async {
    final item = TodoItem(
      id: uuid.v4(),
      listId: _listId,
      title: title,
      color: color,
      createdAt: DateTime.now(),
    );
    await _repository.addItem(item);
    _items = [..._items, item];
    notifyListeners();
  }

  Future<void> toggleItem(String itemId) async {
    await _repository.toggleCompleted(itemId);
    _items = _items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(completed: !item.completed);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  Future<void> setItemColor(String itemId, Color color) async {
    final item = _items.firstWhere((i) => i.id == itemId);
    final updated = item.copyWith(color: color);
    await _repository.updateItem(updated);
    _items = _items.map((i) => i.id == itemId ? updated : i).toList();
    notifyListeners();
  }

  Future<void> setItemAlarm(String itemId, AlarmInfo? alarm) async {
    final item = _items.firstWhere((i) => i.id == itemId);
    final updated = item.copyWith(alarm: alarm);
    await _repository.updateItem(updated);
    _items = _items.map((i) => i.id == itemId ? updated : i).toList();
    notifyListeners();
  }
}
```

### PomodoroViewModel

```dart
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
      id: uuid.v4(),
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
```

---

## UI Layer — Views

All Views are lean widgets. No business logic. Use `ListenableBuilder` to react to ViewModel changes.

### Screen Views

| Screen | ViewModel | Responsibility |
|---|---|---|
| `splash_screen.dart` | `SplashViewModel` | Show image → navigate after 2s |
| `onboarding_screen.dart` | `OnboardingViewModel` | Name input → save → navigate |
| `app_shell.dart` | `AppShellViewModel` | Scaffold shell, palette bar, page routing |
| `list_list_view.dart` | `ListListViewModel` | Grid of colored list cards + FAB |
| `item_detail_page.dart` | `ItemDetailViewModel` | Item list, color picker, alarm picker |

### Widget Views

| Widget | Responsibility |
|---|---|
| `palette_bar.dart` | Top bar with 7 palette swatches |
| `color_picker_dialog.dart` | Reusable color picker dialog |
| `alarm_picker_dialog.dart` | Day + time picker dialog |
| `list_card.dart` | Colored card showing list name + item count |
| `item_tile.dart` | Item row with color, checkbox, alarm icon |
| `pomodoro_widget.dart` | Bottom-left floating timer with item title |

### View Pattern Example — ListListView

```dart
class ListListView extends StatelessWidget {
  const ListListView({super.key, required this.viewModel});

  final ListListViewModel viewModel;

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ColorPickerDialog(
        onColorSelected: (color) {
          // Trigger ViewModel via context.read
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: viewModel.lists.length + 1,
          itemBuilder: (context, index) {
            if (index == viewModel.lists.length) {
              return GestureDetector(
                onTap: () => _showColorPicker(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add, size: 48),
                ),
              );
            }
            return ListCard(list: viewModel.lists[index]);
          },
        );
      },
    );
  }
}
```

### View Pattern Example — PomodoroWidget

```dart
class PomodoroWidget extends StatelessWidget {
  const PomodoroWidget({super.key, required this.viewModel});

  final PomodoroViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 16,
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.status == PomodoroStatus.idle) {
            return _IdleState(viewModel: viewModel);
          }
          return _RunningState(
            viewModel: viewModel,
            remaining: viewModel.remainingSeconds,
          );
        },
      ),
    );
  }
}

class _IdleState extends StatelessWidget {
  final PomodoroViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showPomodoroPicker(context),
      child: const Text('Pomodoro'),
    );
  }
}

class _RunningState extends StatelessWidget {
  final PomodoroViewModel viewModel;
  final int remaining;

  String get _formatted {
    final mins = remaining ~/ 60;
    final secs = remaining % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          viewModel.session?.itemTitle ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          _formatted,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: viewModel.isRunning
                  ? viewModel.pauseSession
                  : viewModel.resumeSession,
              child: Text(viewModel.isRunning ? 'Pause' : 'Resume'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: viewModel.cancelSession,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Theme / Palette System

### Palette Definitions

```dart
// core/themes/palettes.dart

class Palette {
  final String name;
  final ColorScheme light;
  final ColorScheme dark;
  final List<Color> accentColors;
  final String description;

  const Palette({
    required this.name,
    required this.light,
    required this.dark,
    required this.accentColors,
    required this.description,
  });
}

final palettes = {
  'default': Palette(
    name: 'Default',
    light: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.teal,
      surface: Colors.white,
      onSurface: Colors.black,
      // ...
    ),
    dark: ColorScheme.dark(
      primary: Colors.blueAccent,
      secondary: Colors.tealAccent,
      surface: Colors.grey[900]!,
      onSurface: Colors.white,
      // ...
    ),
    accentColors: [
      Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.red, Colors.teal,
    ],
    description: 'Light and neutral tones',
  ),
  'dark': Palette(
    name: 'Dark',
    light: /* ... */,
    dark: /* ... */,
    accentColors: [
      Colors.greenAccent, Colors.pinkAccent,
      Colors.amberAccent, Colors.cyanAccent,
    ],
    description: 'Dark mode optimized',
  ),
  'ocean': Palette(
    name: 'Ocean',
    accentColors: [
      Colors.cyan, Colors.teal, Colors.lightBlue,
      Colors.blueAccent, Colors.indigoAccent,
    ],
    description: 'Blue and teal tones',
  ),
  'sunset': Palette(
    name: 'Sunset',
    accentColors: [
      Colors.orange, Colors.deepOrange, Colors.amber,
      Colors.pink, Colors.redAccent,
    ],
    description: 'Orange and pink tones',
  ),
  'forest': Palette(
    name: 'Forest',
    accentColors: [
      Colors.green, Colors.lightGreen, Colors.lime,
      Colors.teal, Colors.emerald,
    ],
    description: 'Green tones',
  ),
  'lavender': Palette(
    name: 'Lavender',
    accentColors: [
      Colors.purple, Colors.purpleAccent, Colors.deepPurple,
      Colors.indigo, Colors.violet,
    ],
    description: 'Purple tones',
  ),
  'high_contrast': Palette(
    name: 'High Contrast',
    accentColors: [
      Colors.yellow, Colors.white, Colors.black,
      Colors.orange, Colors.red,
    ],
    description: 'Black, white, and yellow',
  ),
};
```

### PaletteViewModel

```dart
class PaletteViewModel extends ChangeNotifier {
  PaletteViewModel({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  String _currentPalette = 'default';
  String get currentPalette => _currentPalette;

  ColorScheme get colorScheme => palettes[_currentPalette]!.light;
  ColorScheme get darkColorScheme => palettes[_currentPalette]!.dark;

  List<Palette> get allPalettes => palettes.values.toList();

  Future<void> setPalette(String name) async {
    _currentPalette = name;
    await _storage.savePalette(name);
    notifyListeners();
  }
}
```

### PaletteBar Widget

```dart
class PaletteBar extends StatelessWidget {
  const PaletteBar({super.key, required this.viewModel});

  final PaletteViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.allPalettes.length,
        itemBuilder: (context, index) {
          final palette = viewModel.allPalettes[index];
          final isSelected = viewModel.currentPalette == palette.name;
          return GestureDetector(
            onTap: () => viewModel.setPalette(palette.name),
            child: Container(
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: palette.accentColors.first,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## Dependency Injection

### di_container.dart

```
Provider scope hierarchy:

MultiProvider
├── Provider<StorageService>         // singleton
├── Provider<DatabaseService>        // singleton
├── Provider<AlarmService>           // singleton
├── Provider<NotificationService>    // singleton
├── Provider<ForegroundTaskService>  // singleton
├── Provider<UserRepository>         // depends on StorageService + DatabaseService
├── Provider<ListRepository>         // depends on DatabaseService
├── Provider<ItemRepository>         // depends on DatabaseService + AlarmService
├── Provider<PomodoroRepository>     // depends on DatabaseService + ForegroundTaskService
├── Provider<PaletteViewModel>       // depends on StorageService
├── Provider<ListListViewModel>      // depends on ListRepository
├── Provider<ItemDetailViewModel>    // depends on ItemRepository
├── Provider<PomodoroViewModel>      // depends on PomodoroRepository
└── Provider<SplashViewModel>        // none
```

### app.dart

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildProviders(),  // from di_container.dart
      child: MaterialApp(
        home: const AppEntryPoint(),  // decides splash vs onboarding vs shell
      ),
    );
  }
}

List<SingleChildWidget> buildProviders() {
  // Services (singleton)
  final services = [
    Provider<StorageService>(create: (_) => StorageService()),
    Provider<DatabaseService>(create: (_) => DatabaseService()),
    Provider<AlarmService>(create: (_) => AlarmService()),
    Provider<NotificationService>(create: (_) => NotificationService()),
    Provider<ForegroundTaskService>(create: (_) => ForegroundTaskService()),
  ];

  // Repositories
  final repositories = [
    Provider<UserRepository>(
      create: (ctx) => UserRepository(
        database: ctx.read<DatabaseService>(),
        storage: ctx.read<StorageService>(),
      ),
    ),
    Provider<ListRepository>(
      create: (ctx) => ListRepository(database: ctx.read<DatabaseService>()),
    ),
    Provider<ItemRepository>(
      create: (ctx) => ItemRepository(
        database: ctx.read<DatabaseService>(),
        alarm: ctx.read<AlarmService>(),
      ),
    ),
    Provider<PomodoroRepository>(
      create: (ctx) => PomodoroRepository(
        database: ctx.read<DatabaseService>(),
        foregroundTask: ctx.read<ForegroundTaskService>(),
      ),
    ),
  ];

  // ViewModels
  final viewModels = [
    Provider<PaletteViewModel>(
      create: (ctx) => PaletteViewModel(storage: ctx.read<StorageService>()),
    ),
    Provider<ListListViewModel>(
      create: (ctx) => ListListViewModel(repository: ctx.read<ListRepository>()),
    ),
    Provider<PomodoroViewModel>(
      create: (ctx) => PomodoroViewModel(repository: ctx.read<PomodoroRepository>()),
    ),
  ];

  return [...services, ...repositories, ...viewModels];
}
```

### app.dart — Entry Point Logic

```dart
class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.read<SplashViewModel>(),
      builder: (context, _) {
        final vm = context.read<SplashViewModel>();
        if (vm.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!vm.hasUser) {
          return const OnboardingScreen();
        }
        return const AppShell();
      },
    );
  }
}
```

---

## Theme / Palette System

### Palette Definitions

```dart
// core/themes/palettes.dart

class Palette {
  final String name;
  final ColorScheme light;
  final ColorScheme dark;
  final List<Color> accentColors;
  final String description;

  const Palette({
    required this.name,
    required this.light,
    required this.dark,
    required this.accentColors,
    required this.description,
  });
}

final palettes = {
  'default': Palette(
    name: 'Default',
    light: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.teal,
      surface: Colors.white,
      onSurface: Colors.black,
      // ...
    ),
    dark: ColorScheme.dark(
      primary: Colors.blueAccent,
      secondary: Colors.tealAccent,
      surface: Colors.grey[900]!,
      onSurface: Colors.white,
      // ...
    ),
    accentColors: [
      Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.red, Colors.teal,
    ],
    description: 'Light and neutral tones',
  ),
  'dark': Palette(
    name: 'Dark',
    light: /* ... */,
    dark: /* ... */,
    accentColors: [
      Colors.greenAccent, Colors.pinkAccent,
      Colors.amberAccent, Colors.cyanAccent,
    ],
    description: 'Dark mode optimized',
  ),
  'ocean': Palette(
    name: 'Ocean',
    accentColors: [
      Colors.cyan, Colors.teal, Colors.lightBlue,
      Colors.blueAccent, Colors.indigoAccent,
    ],
    description: 'Blue and teal tones',
  ),
  'sunset': Palette(
    name: 'Sunset',
    accentColors: [
      Colors.orange, Colors.deepOrange, Colors.amber,
      Colors.pink, Colors.redAccent,
    ],
    description: 'Orange and pink tones',
  ),
  'forest': Palette(
    name: 'Forest',
    accentColors: [
      Colors.green, Colors.lightGreen, Colors.lime,
      Colors.teal, Colors.emerald,
    ],
    description: 'Green tones',
  ),
  'lavender': Palette(
    name: 'Lavender',
    accentColors: [
      Colors.purple, Colors.purpleAccent, Colors.deepPurple,
      Colors.indigo, Colors.violet,
    ],
    description: 'Purple tones',
  ),
  'high_contrast': Palette(
    name: 'High Contrast',
    accentColors: [
      Colors.yellow, Colors.white, Colors.black,
      Colors.orange, Colors.red,
    ],
    description: 'Black, white, and yellow',
  ),
};
```

### PaletteViewModel

```dart
class PaletteViewModel extends ChangeNotifier {
  PaletteViewModel({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  String _currentPalette = 'default';
  String get currentPalette => _currentPalette;

  ColorScheme get colorScheme => palettes[_currentPalette]!.light;
  ColorScheme get darkColorScheme => palettes[_currentPalette]!.dark;

  List<Palette> get allPalettes => palettes.values.toList();

  Future<void> setPalette(String name) async {
    _currentPalette = name;
    await _storage.savePalette(name);
    notifyListeners();
  }
}
```

### PaletteBar Widget

```dart
class PaletteBar extends StatelessWidget {
  const PaletteBar({super.key, required this.viewModel});

  final PaletteViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.allPalettes.length,
        itemBuilder: (context, index) {
          final palette = viewModel.allPalettes[index];
          final isSelected = viewModel.currentPalette == palette.name;
          return GestureDetector(
            onTap: () => viewModel.setPalette(palette.name),
            child: Container(
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: palette.accentColors.first,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## Background & Persistence Strategy

### Alarms (battery-friendly + reboot)

```
User sets alarm on item
  → ItemDetailPage (UI)
    → ItemDetailViewModel.setAlarm(itemId, day, time)  (Logic)
      → ItemRepository.updateAlarm(itemId, alarm)       (Data)
        → DatabaseService.itemDao.updateAlarm()         (Service)
        → AlarmService.scheduleAlarm(item)              (Service)
          → android_alarm_manager_plus                  (Native)

Device reboots
  → BootReceiver.kt (receives BOOT_COMPLETED)
    → AlarmService.reRegisterAllAlarms()
      → Query pending alarms from DB
      → Re-schedule each via android_alarm_manager_plus
```

### Pomodoro (background execution)

```
User starts pomodoro
  → PomodoroViewModel.start()
    → PomodoroRepository.startSession()
      → ForegroundTaskService.startPomodoroTask(session)
        → flutter_foreground_task (foreground service with notification)
        → Timer ticks even with screen off
        → Notification shows remaining time

Pomodoro completes
  → ForegroundTaskService.stopPomodoroTask()
  → PomodoroRepository.completeSession()
  → Notification: "Pomodoro complete!"
```

---

## Data Flow Diagram

```
User taps "Add List"
  → ListListView (UI)
    → ListListViewModel.addList(name, color)  (Logic)
      → ListRepository.addList(list)            (Data)
        → DatabaseService.listDao.insert()      (Service)
        → notifyListeners()
  → ListListView rebuilds with new card          (UI)

User sets alarm on item
  → ItemDetailPage (UI)
    → ItemDetailViewModel.setAlarm(itemId, day, time)  (Logic)
      → ItemRepository.updateAlarm(itemId, alarm)       (Data)
        → DatabaseService.itemDao.updateAlarm()         (Service)
        → AlarmService.scheduleAlarm(item)              (Service)
          → android_alarm_manager_plus                  (Native)

Device reboots
  → BootReceiver.kt (Native)
    → AlarmService.reRegisterAllAlarms()                (Service)
      → DatabaseService.itemDao.getPendingAlarms()      (Service)
        → android_alarm_manager_plus.schedule()         (Native)

Pomodoro starts
  → PomodoroWidget (UI)
    → PomodoroViewModel.start(session)  (Logic)
      → PomodoroRepository.startSession()         (Data)
        → ForegroundTaskService.start()           (Service)
          → flutter_foreground_task               (Native)
          → Timer ticks → update notification     (Background)
```

---

## Android Native Components

### BootReceiver.kt

```kotlin
package com.example.birdle

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action == "android.intent.action.BOOT_COMPLETED") {
      Log.d("BootReceiver", "Device rebooted - re-registering alarms")
      // Trigger Flutter side to re-register alarms
      // Use workmanager or direct method channel
      val flutterEngine = FlutterEngine(context)
      flutterEngine.dartExecutor.executeScript(
        "AlarmService.reRegisterAllAlarms()"
      )
      // Or use workmanager to schedule a task
    }
  }
}
```

### Required Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- BootReceiver registration -->
<receiver
    android:name="com.example.birdle.BootReceiver"
    android:enabled="true"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

---

## Implementation Phases (Mapped to Architecture)

### Phase 1 — Foundation (Data Layer)

1. Add dependencies to `pubspec.yaml`
2. Create `data/models/` — User, TodoList, TodoItem, PomodoroSession
3. Create `data/services/database.dart` — Drift database + DAOs
4. Create `data/services/storage_service.dart` — SharedPreferences wrapper
5. Create `data/services/alarm_service.dart` — Alarm manager wrapper
6. Create `data/services/notification_service.dart` — Notifications wrapper
7. Create `data/services/foreground_task.dart` — Foreground service wrapper
8. Create `data/repositories/` — User, List, Item, Pomodoro repositories
9. Create `core/themes/palettes.dart` — 7 palette definitions
10. Create `di/di_container.dart` — Provider dependency registration

### Phase 2 — Splash & Onboarding (UI + ViewModel)

11. Create `ui/screens/splash/` — Splash screen + ViewModel
12. Create `ui/screens/onboarding/` — Onboarding screen + ViewModel
13. Wire `app.dart` — entry point logic (splash → onboarding → shell)

### Phase 3 — Todo Core (UI + ViewModel)

14. Create `ui/widgets/palette_bar.dart` — Top palette selector bar
15. Create `ui/widgets/color_picker_dialog.dart` — Reusable color picker
16. Create `ui/screens/list_list/` — List grid view + ViewModel
17. Create `ui/screens/item_detail/` — Item detail page + ViewModel
18. Create `ui/widgets/list_card.dart` — List card widget
19. Create `ui/widgets/item_tile.dart` — Item tile widget
20. Create `ui/widgets/alarm_picker_dialog.dart` — Alarm day/time picker

### Phase 4 — Alarms (Data + Android)

21. Wire `alarm_service.dart` — Schedule/cancel alarms via android_alarm_manager_plus
22. Create `android/.../BootReceiver.kt` — Handle BOOT_COMPLETED
23. Update `AndroidManifest.xml` — All permissions + BootReceiver registration
24. Test alarm persistence across reboots

### Phase 5 — Pomodoro (UI + Data + Android)

25. Create `ui/widgets/pomodoro/pomodoro_widget.dart` — Floating timer
26. Create `ui/widgets/pomodoro/pomodoro_view_model.dart` — Timer logic
27. Wire `foreground_task.dart` — Foreground service for timer
28. Update `AndroidManifest.xml` — Foreground service declaration
29. Test background execution with screen off

### Phase 6 — Polish

30. Wire `PaletteViewModel` — Connect palette bar to theme switching
31. End-to-end testing: alarms, pomodoro, reboot
32. UI polish across all screens

---

## Data Flow Diagram

```
User taps "Add List"
  → ListListView (UI)
    → ListListViewModel.addList(name, color)  (Logic)
      → ListRepository.addList(list)            (Data)
        → DatabaseService.listDao.insert()      (Service)
        → notifyListeners()
  → ListListView rebuilds with new card          (UI)

User sets alarm on item
  → ItemDetailPage (UI)
    → ItemDetailViewModel.setAlarm(itemId, day, time)  (Logic)
      → ItemRepository.updateAlarm(itemId, alarm)       (Data)
        → DatabaseService.itemDao.updateAlarm()         (Service)
        → AlarmService.scheduleAlarm(item)              (Service)
          → android_alarm_manager_plus                  (Native)

Device reboots
  → BootReceiver.kt (Native)
    → AlarmService.reRegisterAllAlarms()                (Service)
      → DatabaseService.itemDao.getPendingAlarms()      (Service)
        → android_alarm_manager_plus.schedule()         (Native)

Pomodoro starts
  → PomodoroWidget (UI)
    → PomodoroViewModel.start(session)  (Logic)
      → PomodoroRepository.startSession()         (Data)
        → ForegroundTaskService.start()           (Service)
          → flutter_foreground_task               (Native)
          → Timer ticks → update notification     (Background)
```
