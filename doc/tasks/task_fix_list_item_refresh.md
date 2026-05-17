# Task: Fix List and Item Count Refresh Bugs

## Overview

Fix two related bugs caused by stale state between `ItemDetailViewModel` and `ListListViewModel`:

1. **Bug 1 — New list not appearing after creation**: `_showAddListDialog` calls `addList()` then `loadLists()`, causing a redundant DB reload that may overwrite the in-memory append.
2. **Bug 2 — Item counter on list cards not refreshing**: When the user adds/deletes items in `ItemDetailPage` and navigates back, `ListListViewModel._itemCounts` is stale because `ItemDetailViewModel` has no way to notify `ListListViewModel`.

## Root Cause Analysis

- `ListListViewModel` is a singleton (Provider scope in `di_container.dart`)
- `ItemDetailViewModel` is created inline in `ItemDetailPage` via `ChangeNotifierProvider` — **not** registered in DI
- `ItemDetailViewModel` mutates items in the DB but never calls `ListListViewModel.loadLists()` to update `_itemCounts`
- `_ListsView` lives inside an `IndexedStack` in `AppShell`, so it stays alive and does **not** rebuild when navigating away from/to `/item_detail`
- `_showAddListDialog` calls `addList()` (which in-memory appends + notifies) **then** calls `loadLists()` (which reloads from DB, potentially losing the in-memory append if DB timing is off)

## Implementation Plan

### Step 1 — Remove redundant `loadLists()` call after `addList`

**File**: `lib/ui/screens/app_shell/app_shell.dart`

In `_showAddListDialog`, remove the `await viewModel.loadLists()` line after `await viewModel.addList(...)`.

**Reason**: `addList()` already appends to `_lists` in-memory and calls `notifyListeners()`. The `Consumer<ListListViewModel>` in `_ListsView` will rebuild automatically. The subsequent `loadLists()` call is redundant and can cause the new list to briefly appear then disappear if the DB reload hasn't fully committed.

**Change**:

```dart
// Before:
await viewModel.addList(name.trim(), pickedColor);
await viewModel.loadLists();

// After:
await viewModel.addList(name.trim(), pickedColor);
```

### Step 2 — Add `reloadListCounts()` method to `ListListViewModel`

**File**: `lib/ui/view_models/list_list_view_model.dart`

Add a lightweight method that reloads only the item counts (not the full list data). This avoids unnecessary network/DB work compared to `loadLists()` while keeping the API clean.

**Add**:

```dart
Future<void> reloadListCounts() async {
  final counts = <String, int>{};
  await Future.wait(
    _lists.map((list) async {
      counts[list.id] = await _repository.countItemsByList(list.id);
    }),
  );
  _itemCounts = counts;
  notifyListeners();
}
```

**Note**: If `_lists` is empty (unlikely but possible), this is a no-op. If the list data itself might have changed (e.g., another screen modifies lists), use `loadLists()` instead — but for this fix, `reloadListCounts` is sufficient since the only mutation path from ItemDetail is item CRUD.

### Step 3 — Add pull-to-refresh to the lists grid

**File**: `lib/ui/screens/app_shell/app_shell.dart`

Wrap the `GridView.builder` body inside a `RefreshIndicator` that calls `viewModel.loadLists()` on pull-down.

**Change** in `_ListsView.build`:

```dart
return Scaffold(
  body: RefreshIndicator(
    onRefresh: () async {
      await viewModel.loadLists();
    },
    child: GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: viewModel.lists.length,
      itemBuilder: (context, index) {
        // ... existing _ListCard code ...
      },
    ),
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: () => _showAddListDialog(context),
    child: const Icon(Icons.add),
  ),
);
```

**Key points**:
- `RefreshIndicator` is the standard Material pull-to-refresh widget
- Calls `loadLists()` (full reload) — this is correct because the user explicitly requested a refresh
- The `Consumer` will rebuild automatically when `notifyListeners()` fires from `loadLists()`

### Step 4 — Wire item count refresh when returning from `ItemDetailPage`

**File**: `lib/ui/screens/app_shell/app_shell.dart`

In `_ListsView`'s `itemBuilder`, change `onTap` from a simple callback to an `async` callback that awaits the navigation and then calls `reloadListCounts()`:

```dart
onTap: () async {
  await Navigator.of(context).pushNamed(
    '/item_detail',
    arguments: list.id,
  );
  if (context.mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<ListListViewModel>().reloadListCounts();
      }
    });
  }
},
```

**Key points**:
- `await` ensures we wait for the route to be popped
- `context.mounted` guards against stale context after async gap
- `addPostFrameCallback` ensures the reload happens after the current frame renders (avoids race with IndexedStack switching)

### Step 5 — Verify `ListListViewModel.loadLists()` is called on app startup

**File**: `lib/ui/screens/app_shell/app_shell.dart`

Already done in `_AppShellState.initState` via `addPostFrameCallback`. No change needed. Existing code at lines 22-25:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ListListViewModel>().loadLists();
    context.read<PomodoroViewModel>().loadActiveSession();
  });
}
```

**No change needed.**

## Files Modified

| File | Change |
|---|---|
| `lib/ui/screens/app_shell/app_shell.dart` | Remove redundant `loadLists()` call; wrap GridView in `RefreshIndicator`; add `reloadListCounts()` trigger on return from ItemDetailPage |
| `lib/ui/view_models/list_list_view_model.dart` | Add `reloadListCounts()` method |

## Completion Criteria

- [ ] **Bug 1 fixed**: Creating a new list from the FAB immediately shows the new card in the grid without requiring a hard reload or navigation away-and-back
- [ ] **Bug 2 fixed**: After adding an item to a list (via ItemDetailPage) and navigating back to the lists grid, the item count on the corresponding list card updates to reflect the new count
- [ ] **Bug 2 also fixed for deletions**: After deleting an item from a list and navigating back, the item count decrements correctly
- [ ] **Pull-to-refresh works**: Swiping down on the lists grid triggers a full reload of lists and item counts, showing any changes made remotely (e.g., from ItemDetailPage)
- [ ] **No regressions**: The app still loads lists correctly on startup (verified by `loadLists()` in `AppShell.initState`)
- [ ] **Static analysis passes**: `dart analyze` reports no errors or warnings related to the changes

## Notes

- The `IndexedStack` in `AppShell` keeps `_ListsView` alive, which is correct for performance but means the view does not rebuild on navigation. This is why explicit state refresh is needed.
- `ItemDetailViewModel` is intentionally not registered in DI (it's scoped to the route). Adding it to DI would be a larger refactor and is not necessary for this fix.
- The `reloadListCounts()` method is a compromise: it's lighter than `loadLists()` but still re-reads from the DB to ensure accuracy. If performance becomes an issue, a stream-based approach (e.g., `ItemRepository` emits item count changes) could be considered later.
