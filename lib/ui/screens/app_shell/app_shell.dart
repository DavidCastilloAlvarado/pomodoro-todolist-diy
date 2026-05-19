import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:birdle/data/models/todo_list.dart';
import 'package:birdle/ui/screens/app_shell/pomodoro_screen.dart';
import 'package:birdle/ui/screens/settings/settings_page.dart';
import 'package:birdle/ui/view_models/list_list_view_model.dart';
import 'package:birdle/ui/view_models/pomodoro_view_model.dart';
import 'package:birdle/ui/widgets/color_picker_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListListViewModel>().loadLists();
      context.read<PomodoroViewModel>().loadActiveSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ListsView(),
          PomodoroScreen(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Pomodoro'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _ListsView extends StatefulWidget {
  const _ListsView();

  @override
  State<_ListsView> createState() => _ListsViewState();
}

class _ListsViewState extends State<_ListsView> {
  Future<void> _showAddListDialog(BuildContext context) async {
    final viewModel = context.read<ListListViewModel>();
    if (viewModel.isAdding) return;

    // Step 1: Pick a color
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => const ColorPickerDialog(),
    );
    if (pickedColor == null) return;
    if (!context.mounted) return;


    // Step 2: Get list name
    final TextEditingController nameController = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (nameContext) => AlertDialog(
        title: const Text('List name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Enter list name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.of(nameContext).pop(nameController.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(nameContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(nameContext).pop(nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    // Step 3: Create the list
    await viewModel.addList(name.trim(), pickedColor);
  }

  Future<void> _confirmDelete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete list'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      final viewModel = context.read<ListListViewModel>();
      await viewModel.deleteList(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ListListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
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
                  final list = viewModel.lists[index];
                  return _ListCard(
                    list: list,
                    itemCount: viewModel.itemCounts[list.id] ?? 0,
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
                    onDelete: () => _confirmDelete(list.id, list.name),
                  );
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddListDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _ListCard extends StatelessWidget {
  final TodoList list;
  final int itemCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ListCard({
    required this.list,
    required this.itemCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: list.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list,
                    size: 32,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      list.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemCount == 0 ? 'No items' : '$itemCount items',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
