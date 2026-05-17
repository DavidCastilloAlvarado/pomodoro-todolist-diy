# Birdle — Phase Completion History

| Phase | Status | Date | Description |
|---|---|---|---|
| 1 — Foundation | complete | 2026-05-16 | Data layer: models, Drift DB, DAOs, services, repositories, palettes, DI |
| 2 — Splash & Onboarding | complete | 2026-05-16 | SplashScreen (2s branding), OnboardingScreen (polished UI), navigation wiring (App → SplashScreen → check → Onboarding/AppShell), removed duplicate user check from AppEntryPoint |
| 3 — Todo Core | complete | 2026-05-16 | ListListView (2-col grid with colored cards + FAB), ListItemDetailPage (checklist items, toggle complete, per-item color picker), AlarmPickerDialog (7 days + every-day + time picker), /item_detail route wired |


## Phase 3 — Todo Core (final gap fixed)

**Date:** 2026-05-16

**Task:** `task_phase3_itemcount.md` — Add item counts to list cards

**Changes:**
- `BirdleDatabase.countItemsByList()` — raw SQL `COUNT(*)` query
- `ListRepository.countItemsByList()` — delegates to database
- `ListListViewModel._itemCounts` Map + `Future.wait` parallel loading
- `_ListCard` subtitle: "No items" or "N items" in white text
- Counts refresh after list creation

**dart analyze:** 0 errors, 0 warnings
**Reviewer:** approved (all 8 criteria met)

---

## Phase 4: Alarm Notifications — Completed

**Date:** 2026-05-16

**Task:** `task_alarm_notifications.md` — Fix alarm notification system

**Findings:**
- `UILocalNotificationDateInterpretation.absolute` → `wallClockTime` (flutter_local_notifications v18 API)
- Added `timezone: ^0.10.0` as direct dependency
- `AlarmService.scheduleAlarm()` now calls `NotificationService.scheduleNotification()` (one-time) and `scheduleDailyNotification()` (every day)
- `AlarmService.cancelAlarm()` calls `NotificationService.cancelById()`
- `AlarmService.initAlarmManager()` calls `reRegisterAllAlarms()`
- `main.dart` initializes `NotificationService` and calls `alarmService.initAlarmManager()` on startup
- `dart analyze` — 0 errors
- Reviewer: **approved** (all 11 criteria met)

---

## Fix: List and Item Count Refresh Bugs

**Date:** 2026-05-16

**Task:** `task_fix_list_item_refresh.md` — Fix list not appearing + item counter stale

**Root causes:**
1. `_showAddListDialog` called `addList()` (in-memory append) then `loadLists()` (DB reload) — the redundant reload could overwrite the new list if timing was off
2. `ItemDetailViewModel` had no reference to `ListListViewModel`, so item count updates were never propagated back to the lists grid

**Changes:**
- `lib/ui/screens/app_shell/app_shell.dart` — Removed redundant `loadLists()` call; wrapped `GridView` in `RefreshIndicator`; changed `onTap` to async with `reloadListCounts()` on return from `/item_detail`
- `lib/ui/view_models/list_list_view_model.dart` — Added `reloadListCounts()` method that reloads only `_itemCounts` from DB

**dart analyze:** 0 errors, 0 new warnings (pre-existing lints unchanged)
**Reviewer:** approved (all 6 criteria met)

---

## Fix: List and Item Count Refresh Bugs (revised)

**Date:** 2026-05-16

**Task:** `task_fix_refresh_bugs.md` — Fix list not appearing + item counter stale

**Root causes:**
1. `ListListViewModel.addList()` appended new list to in-memory `_lists` after DB insert — if insert failed silently, phantom list persisted in memory but was gone after hard reload
2. `reloadListCounts()` iterated only over in-memory `_lists` — stale lists meant stale/missing counts
3. `deleteList()` also used in-memory filtering instead of DB reload

**Changes:**
- `lib/ui/view_models/list_list_view_model.dart` — `addList()`: replaced `_lists = [..._lists, list]` with `_lists = await _repository.getAllLists()` (DB reload after insert). `deleteList()`: same DB reload pattern. `reloadListCounts()`: added `_lists = await _repository.getAllLists()` at the start to ensure counts are computed against current DB state.

**dart analyze:** 0 errors, 0 warnings (2 pre-existing info messages unchanged)
**Reviewer:** approved (all 6 criteria met)

---

## Fix: ViewModels not notifying listeners (Provider → ChangeNotifierProvider)

**Date:** 2026-05-16

**Root cause:** All three view models (`PaletteViewModel`, `ListListViewModel`, `PomodoroViewModel`) extend `ChangeNotifier` but were registered with plain `Provider<>` in `di_container.dart`. Plain `Provider` does **not** subscribe to `notifyListeners()` — `Consumer<T>` widgets only rebuild via `ChangeNotifierProvider<T>`. Every `notifyListeners()` call was silently ignored, so UI never updated without a hot restart.

**Changes:**
- `lib/di/di_container.dart` — `Provider<PaletteViewModel>` → `ChangeNotifierProvider<PaletteViewModel>`
- `lib/di/di_container.dart` — `Provider<ListListViewModel>` → `ChangeNotifierProvider<ListListViewModel>`
- `lib/di/di_container.dart` — `Provider<PomodoroViewModel>` → `ChangeNotifierProvider<PomodoroViewModel>`

**dart analyze:** 0 errors, 0 warnings (2 pre-existing info messages unchanged)
