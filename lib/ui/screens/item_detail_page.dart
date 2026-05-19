import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/models/todo_list.dart';
import 'package:birdle/data/repositories/item_repository.dart';
import 'package:birdle/data/repositories/list_repository.dart';
import 'package:birdle/ui/widgets/alarm_picker_dialog.dart';

import 'package:birdle/ui/view_models/item_detail_view_model.dart';
import 'package:birdle/ui/widgets/color_picker_dialog.dart';

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (ctx) => ItemDetailViewModel(
        repository: ctx.read<ItemRepository>(),
        listId: listId,
      )..loadItems(),
      child: _ItemDetailBody(listId: listId),
    );
  }
}

class _ItemDetailBody extends StatelessWidget {
  final String listId;

  const _ItemDetailBody({required this.listId});

  Future<TodoList?> _fetchListName(BuildContext context) async {
    try {
      final listRepo = context.read<ListRepository>();
      return await listRepo.getListById(listId);
    } catch (_) {
      return null;
    }
  }

  void _showAddItemDialog(BuildContext context) async {
    final viewModel = context.read<ItemDetailViewModel>();
    if (viewModel.isAdding) return;

    final TextEditingController titleController = TextEditingController();

    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => const ColorPickerDialog(),
    );
    if (pickedColor == null || !context.mounted) return;

    final String? title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Item title'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Enter item title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              Navigator.of(dialogContext).pop(titleController.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(dialogContext).pop(text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (title == null || title.trim().isEmpty || !context.mounted) return;

    await viewModel.addItem(title.trim(), pickedColor);
  }

  Future<void> _showColorPickerForItem(
    BuildContext context,
    TodoItem item,
  ) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => const ColorPickerDialog(),
    );
    if (color == null || !context.mounted) return;

    final viewModel = context.read<ItemDetailViewModel>();
    await viewModel.updateItemColor(item.id, color);
  }

  Future<void> _confirmDelete(BuildContext context, TodoItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final viewModel = context.read<ItemDetailViewModel>();
      await viewModel.deleteItem(item.id);
    }
  }

  Future<void> _showAlarmPickerForItem(
    BuildContext context,
    TodoItem item,
  ) async {
    final result = await showDialog<AlarmPickerResult>(
      context: context,
      builder: (dialogContext) => AlarmPickerDialog(
        initialAlarm: item.alarm,
      ),
    );
    if (result == null || !context.mounted) return;

    final viewModel = context.read<ItemDetailViewModel>();
    switch (result) {
      case AlarmSet():
        await viewModel.updateItemAlarm(item.id, result.alarm);
      case AlarmRemoved():
        await viewModel.updateItemAlarm(item.id, null);
      case AlarmDismissed():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TodoList?>(
      future: _fetchListName(context),
      builder: (context, snapshot) {
        final listName = snapshot.data?.name ?? 'Items';

        return Scaffold(
          appBar: AppBar(
            title: Text(listName),
            centerTitle: true,
          ),
          body: Consumer<ItemDetailViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (viewModel.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checklist_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the FAB to add an item',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: viewModel.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = viewModel.items[index];
                  return _ItemRow(
                    item: item,
                    onTap: () => viewModel.toggleCompleted(item.id),
                    onColorTap: () => _showColorPickerForItem(context, item),
                    onAlarmTap: () => _showAlarmPickerForItem(context, item),
                    onDelete: () => _confirmDelete(context, item),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddItemDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onTap;
  final VoidCallback onColorTap;
  final VoidCallback onAlarmTap;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.item,
    required this.onTap,
    required this.onColorTap,
    required this.onAlarmTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: item.completed,
                onChanged: (_) => onTap(),
                side: BorderSide(
                  color: item.color,
                  width: 2,
                ),
              ),
              const SizedBox(width: 8),

              // Color indicator
              GestureDetector(
                onTap: onColorTap,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: item.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.completed
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Alarm indicator
              GestureDetector(
                onTap: item.completed
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alarms are disabled for completed items'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    : onAlarmTap,
                onLongPress: item.completed || item.alarm == null
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Remove alarm'),
                            content: Text(
                                'Remove the alarm for "${item.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          final viewModel =
                              context.read<ItemDetailViewModel>();
                          await viewModel.updateItemAlarm(item.id, null);
                        }
                      },
                child: Icon(
                  item.alarm != null
                      ? Icons.access_time
                      : Icons.access_time_outlined,
                  size: 20,
                  color: item.completed
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2)
                      : item.alarm != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35),
                ),
              ),

              const SizedBox(width: 8),

              // Delete button
              IconButton(
                onPressed: () => onDelete(),
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35),
                ),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
