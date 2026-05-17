name: fix_list_reload
phase: 4
description: |
  Fix two data-sync bugs in the Birdle Flutter app:

  **Bug 1 — New lists don't appear after a hard reload (app restart)**
  Root cause: `ListListViewModel` has no constructor-initiated `loadLists()` call.
  It relies entirely on `AppShell.initState()` to trigger the load. The ViewModel
  is a lazy-singleton Provider — only instantiated when first read. If the Provider
  is ready before `AppShell` builds, the lists remain empty.

  **Bug 2 — Item counter doesn't refresh when adding items to a list**
  Root cause: `ItemDetailPage` and `ListListViewModel` are completely decoupled.
  When an item is added in `ItemDetailPage`, the `ListListViewModel._itemCounts`
  map is never updated — it holds a stale cached value. On navigating back to
  `_ListsView`, the `_ListCard` displays the outdated count.

files:
  - lib/ui/view_models/list_list_view_model.dart
  - lib/ui/screens/item_detail_page.dart
  - lib/ui/view_models/item_detail_view_model.dart
completion_criteria:
  - [ ] `ListListViewModel` constructor calls `loadLists()` in its body (after the initializer list), so data loads immediately upon instantiation
  - [ ] `ListListViewModel.loadLists()` is guarded against double-load during construction (no-op if `_lists` is still empty and `_initialLoad` flag is false)
  - [ ] `ItemDetailPage` is converted from `StatelessWidget` to `StatefulWidget` with a `WidgetsBindingObserver`
  - [ ] `WidgetsBindingObserver.didChangeAppLifecycleState()` calls `loadLists()` on `ListListViewModel` when state transitions to `AppLifecycleState.resumed`
  - [ ] `ItemDetailPage` registers the observer in `initState()` and unregisters in `dispose()`
  - [ ] `dart analyze` passes with zero errors and zero warnings after changes
status: pending
