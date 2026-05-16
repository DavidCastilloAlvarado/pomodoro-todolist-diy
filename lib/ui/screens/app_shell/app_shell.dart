import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:birdle/ui/view_models/list_list_view_model.dart';
import 'package:birdle/ui/view_models/palette_view_model.dart';
import 'package:birdle/ui/view_models/pomodoro_view_model.dart';

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
          _SearchView(),
          _SettingsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _ListsView extends StatelessWidget {
  const _ListsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<ListListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: viewModel.lists.map((list) {
            return ListTile(
              title: Text(list.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => viewModel.deleteList(list.id),
              ),
              onTap: () => Navigator.of(context).pushNamed(
                '/item_detail',
                arguments: list.id,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Search'));
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<PaletteViewModel>(
      builder: (context, paletteVm, child) {
        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Color Palettes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: paletteVm.allPalettes.length,
                itemBuilder: (context, index) {
                  final palette = paletteVm.allPalettes[index];
                  final isSelected = paletteVm.currentPalette == palette.name;
                  return GestureDetector(
                    onTap: () => paletteVm.setPalette(palette.name),
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: palette.accentColors.first,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
