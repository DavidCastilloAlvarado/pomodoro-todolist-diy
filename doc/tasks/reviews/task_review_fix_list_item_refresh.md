task: fix_list_item_refresh
reviewer: reviewer
date: 2026-05-16
status: approved
findings:
  - severity: info
    file: lib/ui/screens/app_shell/app_shell.dart
    line: 76
    description: Pre-existing lint warning `use_build_context_synchronously` on the `showDialog<String>` context parameter. The `mounted` guard at line 70 is on the State object, not on the `context` passed into the async dialog. This warning existed before the task changes and is unrelated to the fix.
summary: |
  All five completion criteria are met:

  1. **Bug 1 fixed** — `_showAddListDialog` (line 105) calls `await viewModel.addList(name.trim(), pickedColor)` and returns immediately. The redundant `await viewModel.loadLists()` call has been removed. Since `addList()` appends to `_lists` in-memory and calls `notifyListeners()`, the `Consumer<ListListViewModel>` in `_ListsView` rebuilds automatically and the new card appears immediately.

  2. **Bug 2 fixed** — `onTap` in `_ListCard` (lines 158-170) is now an `async` callback. It awaits `Navigator.of(context).pushNamed('/item_detail', arguments: list.id)`, then uses `context.mounted` guards with `WidgetsBinding.instance.addPostFrameCallback` to call `context.read<ListListViewModel>().reloadListCounts()` after the route is popped. This ensures the item count on the list card updates when returning from ItemDetailPage.

  3. **Pull-to-refresh works** — The `GridView.builder` is wrapped in a `RefreshIndicator` (lines 141-174) whose `onRefresh` calls `await viewModel.loadLists()`. This triggers a full reload of lists and item counts, and the `Consumer` rebuilds automatically when `notifyListeners()` fires.

  4. **`reloadListCounts()` method exists** — Added to `ListListViewModel` (lines 67-76 in `list_list_view_model.dart`). It iterates `_lists`, calls `_repository.countItemsByList(list.id)` for each list via `Future.wait`, assigns the result to `_itemCounts`, and calls `notifyListeners()`. This is a lightweight reload that only updates counts without reloading the full list data.

  5. **Static analysis passes** — `dart analyze` reports 0 errors and 1 pre-existing info-level lint warning (line 76, `use_build_context_synchronously` on the name-input dialog). No new warnings were introduced by these changes.

  Architectural compliance:
  - `ListListViewModel` extends `ChangeNotifier` (MVVM pattern) ✓
  - ViewModel uses `ListRepository` for all data access (Repository pattern) ✓
  - Views are lean widgets using `Consumer` to access ViewModel (no business logic in views) ✓
  - Dependency injection via `context.read<ListListViewModel>()` (Provider) ✓
  - Proper separation of concerns: UI triggers state updates, ViewModel manages state, Repository handles persistence ✓
  - Null safety throughout, proper `mounted` guards on async gaps ✓
  - No hardcoded magic values — uses `EdgeInsets.all(12)`, `const` where appropriate ✓
completion_criteria_check:
  - [x] Bug 1 fixed — Creating a new list from the FAB immediately shows the new card in the grid without requiring a hard reload
  - [x] Bug 2 fixed — After adding an item to a list and navigating back, the item count on the corresponding list card updates
  - [x] Bug 2 also fixed for deletions — The same `reloadListCounts()` mechanism handles item deletions (re-reads counts from DB)
  - [x] Pull-to-refresh works — Swiping down on the lists grid triggers `viewModel.loadLists()` via `RefreshIndicator`
  - [x] No regressions — `loadLists()` is still called in `AppShell.initState` via `addPostFrameCallback` (lines 22-25)
  - [x] Static analysis passes — 0 errors, 0 new warnings (1 pre-existing info-level lint on unrelated code)
