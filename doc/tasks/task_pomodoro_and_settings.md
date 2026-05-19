name: pomodoro_and_settings
phase: 1
description: >
  Replace the unused "Search" tab in AppShell with a functional "Pomodoro" tab
  wired to the existing PomodoroViewModel, upgrade the Settings screen with
  useful app settings, fix the foreground service so the pomodoro timer
  survives app background/kill, and play a fire sound + vibrate on completion.
files:
  - lib/ui/screens/app_shell/app_shell.dart
  - lib/ui/screens/app_shell/pomodoro_screen.dart
  - lib/data/services/foreground_task.dart
  - lib/data/services/notification_service.dart
  - lib/data/services/storage_service.dart
  - lib/data/repositories/pomodoro_repository.dart
  - lib/ui/view_models/pomodoro_view_model.dart
  - android/app/src/main/AndroidManifest.xml
  - pubspec.yaml
completion_criteria:
  - [ ] The "Search" tab is removed from the BottomNavigationBar in app_shell.dart (no references to _SearchView, Icons.search, or "Search" remain)
  - [ ] The _SearchView class is removed from app_shell.dart
  - [ ] The IndexedStack children list has exactly two items: _ListsView and the new Pomodoro screen
  - [ ] The BottomNavigationBar has exactly two items: "Lists" (Icons.list) and "Pomodoro" (Icons.timer or Icons.access_time)
  - [ ] A new file lib/ui/screens/app_shell/pomodoro_screen.dart is created containing a PomodoroScreen widget
  - [ ] The PomodoroScreen reads PomodoroViewModel via context.read<PomodoroViewModel>()
  - [ ] When no session is active, the PomodoroScreen shows a duration picker (25, 50, 75 minutes as defaults) and a "Start" button
  - [ ] When a session is running, the PomodoroScreen shows a countdown timer (MM:SS), the associated item title, and a "Pause" button
  - [ ] When a session is paused, the PomodoroScreen shows the countdown timer, item title, and both "Resume" and "Cancel" buttons
  - [ ] Start/Pause/Resume/Cancel buttons call the corresponding PomodoroViewModel methods (startSession, pauseSession, resumeSession, cancelSession)
  - [ ] startSession uses the selected duration and defaults itemTitle to a placeholder (e.g., "Focus session") since no item picker exists yet
  - [ ] The Settings screen (_SettingsView) is upgraded to include: palette selection (existing swatches preserved), pomodoro duration configuration (editable default durations), and user name display
  - [ ] Pomodoro duration configuration is persisted via StorageService (e.g., save/load custom durations from shared_preferences)
  - [ ] pomodoroTaskCallback in foreground_task.dart is implemented with a Timer.periodic that decrements remaining time and calls showNotification when the timer reaches zero
  - [ ] The foreground task callback is annotated with @pragma('vm:entry-point') and uses the correct FlutterForegroundTask parameter type
  - [ ] android/app/src/main/AndroidManifest.xml has the required <service> declaration for FlutterForegroundTask (flutter_foreground_task plugin's ForegroundService)
  - [ ] android/app/src/main/AndroidManifest.xml has the required <receiver> declaration for FlutterForegroundTask's boot receiver (if applicable)
  - [ ] The foreground service is configured to survive the app being killed/swiped away (foregroundServiceType includes dataSync or mediaPlayback as appropriate)
  - [ ] PomodoroViewModel subscribes to ForegroundTaskService.remainingSecondsStream and updates _remainingSeconds when values arrive
  - [ ] audioplayers package is added to pubspec.yaml dependencies
  - [ ] A fire/explosion sound asset is added to assets/sounds/ (e.g., assets/sounds/complete.mp3)
  - [ ] The sound asset is registered in the flutter.assets section of pubspec.yaml
  - [ ] Sound plays on pomodoro completion via audioplayers (AudioPlayer.play() with AssetSource or UrlSource)
  - [ ] Sound plays on completion from both paths: foreground service (if app is backgrounded) and app itself (if app is foregrounded)
  - [ ] HapticFeedback.vibrate() is called on completion from the app path (PomodoroScreen or PomodoroViewModel)
  - [ ] The notification channel's enableVibration: true is respected on completion notifications
  - [ ] dart analyze passes with no errors
status: pending
