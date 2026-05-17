task: fix_refresh_bugs
reviewer: reviewer
date: 2026-05-16
status: approved
findings:
  - severity: info
    file: lib/ui/screens/app_shell/app_shell.dart
    line: 165
    description: The `context.mounted` check inside `addPostFrameCallback` (line 165) is redundant — the callback is always scheduled in the current frame, so the widget is guaranteed to be mounted when it fires. However, this is harmless defensive coding and does not impact correctness.
  - severity: info
    file: lib/ui/view_models/list_list_view_model.dart
    line: 71
    description: `reloadListCounts()` reloads the full `_lists` from DB (line 71) even though it only needs the counts. This is slightly redundant but harmless and actually beneficial — it keeps `_lists` in sync with DB as a side effect.
summary: |
  The builder's fix correctly addresses both data-sync bugs by replacing in-memory state manipulation with database-reloaded state in all three critical methods (`addList`, `deleteList`, `reloadListCounts`). This approach is sound:

  - **Bug 1 (new list not persisting)**: `addList()` now reloads `_lists` from DB after insert, ensuring the in-memory state matches the database. On hard restart, `loadLists()` in `AppShell.initState()` reads from DB, so the list appears correctly.
  - **Bug 2 (item count stale after navigation)**: `reloadListCounts()` is called via `addPostFrameCallback` after navigating back from `/item_detail`. It first refreshes `_lists` from DB, then recomputes all counts via `countItemsByList()`. This guarantees the counts are always computed against the current DB state, regardless of what modifications occurred in `ItemDetailPage` (which uses its own disconnected `ItemDetailViewModel` instance).
  - **Delete list**: `deleteList()` deletes from DB then reloads `_lists` from DB, correctly removing the list from both layers.

  No changes to `di_container.dart` were needed — the existing Provider setup is sufficient because `reloadListCounts()` acts as an explicit cache invalidation mechanism rather than requiring shared ViewModel instances.

  The `ItemDetailPage` creates its own `ItemDetailViewModel` via inline `ChangeNotifierProvider` (line 20-26), completely disconnected from the shared `ListListViewModel`. This is the root cause of Bug 2. The fix handles this correctly by reloading from DB on navigation back rather than trying to wire up cross-ViewModel event buses or shared state.

  Static analysis: 0 errors, 0 warnings (2 pre-existing info messages).
completion_criteria_check:
  - [x] Bug 1 fixed — Creating a new list via FAB creates it in DB and the card appears immediately; after hard app restart (kill + relaunch), the list still appears in the grid — met
  - [x] Bug 2 fixed (add) — Adding an item in ItemDetailPage and navigating back shows the updated item count on the list card without requiring a hard reload — met
  - [x] Bug 2 fixed (delete) — Deleting an item in ItemDetailPage and navigating back shows the decremented item count on the list card — met
  - [x] Bug 2 fixed (toggle) — Toggling item completion in ItemDetailPage and navigating back does not corrupt the item count — met
  - [x] Delete list works — Deleting a list removes it from both DB and in-memory state correctly — met
  - [x] Static analysis passes — `dart analyze` reports zero errors and zero warnings after changes — met
