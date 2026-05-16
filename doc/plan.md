# Birdle Todo App — Development Plan

## Overview

A Flutter todo app with SQL persistence, color palettes, item alarms, and a pomodoro timer that works in the background and survives device reboots.

---

## Dependencies

| Package | Purpose |
|---|---|
| `sqflite` | Local SQLite persistence |
| `drift` | Type-safe DB ORM |
| `flutter_local_notifications` | Background notifications |
| `android_alarm_manager_plus` | Schedule alarms that survive reboot |
| `workmanager` | Background task scheduling, boot receiver |
| `flutter_foreground_task` | Foreground service for pomodoro |
| `shared_preferences` | Persist name + palette choice |
| `provider` | State management |
| `uuid` | Unique IDs |
| `intl` | Date/time formatting |

---

## Color Palettes (7)

| Palette | Description |
|---|---|
| `default` | Light/neutral tones |
| `dark` | Dark mode |
| `ocean` | Blue/teal tones |
| `sunset` | Orange/pink tones |
| `forest` | Green tones |
| `lavender` | Purple tones |
| `high_contrast` | Black/white/yellow |

---

## Data Layer (Drift)

### Tables

- **User** — `id`, `name`, `created_at`
- **TodoList** — `id`, `name`, `color_hex`, `created_at`
- **TodoItem** — `id`, `list_id`, `title`, `completed`, `color_hex`, `alarm_day?`, `alarm_time?`
- **PomodoroSession** — `id`, `item_title`, `duration`, `status`, `started_at`

---

## Screen Flow

```
SplashScreen (image, 2s)
  → OnboardingPage (ask name)
    → AppShell
        ├── PaletteBar (top, 7 palette swatches)
        ├── ListListView (all lists, add with color picker)
        ├── ListItemDetailPage (items, per-item color picker, alarm picker)
        └── PomodoroWidget (bottom-left floating timer)
```

---

## Implementation Steps

### Phase 1 — Foundation

1. Add all dependencies to `pubspec.yaml`
2. Create Drift database schema (User, TodoList, TodoItem, PomodoroSession)
3. Create DAO classes for each table
4. Create service layer: UserService, ListService, ItemService, PomodoroService
5. Set up Provider AppState (user, currentPalette, lists, items)
6. Define 7 color palette theme data objects

### Phase 2 — Splash & Onboarding

7. Create SplashScreen — shows image, navigates after 2-second delay
8. Create OnboardingPage — asks for user name, saves to shared_preferences + DB
9. Wire navigation: splash → check name exists → AppShell or OnboardingPage

### Phase 3 — Todo Core

10. Create ListListView — grid of colored list cards, FAB to add new list with color picker
11. Create ListItemDetailPage — list of items, tap to complete, per-item color picker
12. Add alarm picker for items — day + time selector, saves to DB

### Phase 4 — Alarms (battery-friendly + reboot)

13. Configure `android_alarm_manager_plus` for inexact alarms (battery-friendly)
14. Create BootReceiver that re-registers all pending alarms after device restart
15. Set up `flutter_local_notifications` for notification display (works with screen off)
16. Android manifest permissions: `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE`, `WAKE_LOCK`, `SCHEDULE_EXACT_ALARM`

### Phase 5 — Pomodoro

17. Create PomodoroWidget — bottom-left floating timer overlay
18. Picker to select a todo item (shows item title during countdown)
19. Default durations: 25, 50, 75 min — user can customize
20. Foreground service keeps timer alive when screen is off
21. Notification shows countdown during pomodoro

### Phase 6 — Polish

22. Palette bar at top of app, tap to switch — applies to all screens
23. Test reboot alarm persistence
24. Test pomodoro background execution
25. UI polish, edge case handling

---

## Android Manifest Changes

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- BootReceiver -->
<receiver android:name="com.alarm_manager.BootReceiver"
    android:enabled="true"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

---

## File Structure

```
lib/
  main.dart
  app.dart                    # MaterialApp + route config
  database/
    database.dart             # Drift database definition
    dao/
      user_dao.dart
      list_dao.dart
      item_dao.dart
      pomodoro_dao.dart
  models/
    user.dart
    todo_list.dart
    todo_item.dart
    pomodoro_session.dart
  providers/
    app_provider.dart
    palette_provider.dart
    pomodoro_provider.dart
  services/
    alarm_service.dart
    pomodoro_service.dart
  screens/
    splash_screen.dart
    onboarding_screen.dart
    app_shell.dart
    list_list_view.dart
    item_detail_page.dart
  widgets/
    palette_bar.dart
    pomodoro_widget.dart
    color_picker_dialog.dart
    alarm_picker_dialog.dart
  utils/
    palettes.dart
    constants.dart
android/
  app/src/main/AndroidManifest.xml   # permissions + receivers
  .../java/com/example/birdle/
    BootReceiver.kt
assets/
  images/
    splash_image.png
```
