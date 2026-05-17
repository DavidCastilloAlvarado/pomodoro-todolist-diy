name: fix_refresh_bugs
phase: 4
description: |
  Fix two data-sync bugs caused by stale in-memory state in `ListListViewModel`:

  **Bug 1 — New list not appearing after hard reload (app restart)**
  Root cause: `ListListViewModel.addList()` appends the new list to `_lists` after the
  repository insert. If the DB insert fails silently (e.g., constraint violation, connection
  issue), the in-memory `_lists` has the phantom list but the DB does not. On hard reload,
  `loadLists()` reads from DB and the phantom list is gone.

  **Bug 2 — Item counter on list cards not refreshing**
  Root cause: `reloadListCounts()` iterates only over the in-memory `_lists`. If `_lists`
  is out of sync with the DB (from Bug 1, or any stale state), the counts will miss lists
  or show incorrect values. Additionally, `ItemDetailPage` creates its own
  `ItemDetailViewModel` instance via inline `ChangeNotifierProvider`, completely disconnected
  from any shared state — mutations in the DB are correct, but there's no mechanism to
  invalidate the `ListListViewModel` cache.

files:
  - lib/ui/view_models/list_list_view_model.dart
  - lib/ui/screens/item_detail_page.dart
  - lib/di/di_container.dart
completion_criteria:
  - [ ] **Bug 1 fixed**: Creating a new list via FAB creates it in DB and the card appears immediately; after hard app restart (kill + relaunch), the list still appears in the grid
  - [ ] **Bug 2 fixed (add)**: Adding an item in ItemDetailPage and navigating back shows the updated item count on the list card without requiring a hard reload
  - [ ] **Bug 2 fixed (delete)**: Deleting an item in ItemDetailPage and navigating back shows the decremented item count on the list card
  - [ ] **Bug 2 fixed (toggle)**: Toggling item completion in ItemDetailPage and navigating back does not corrupt the item count
  - [ ] **Delete list works**: Deleting a list removes it from both DB and in-memory state correctly
  - [ ] **Static analysis passes**: `dart analyze` reports zero errors and zero warnings after changes
status: pending
