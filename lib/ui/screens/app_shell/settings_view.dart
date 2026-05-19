import 'package:birdle/data/services/storage_service.dart';
import 'package:birdle/ui/view_models/palette_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = StorageService();
    final name = storage.getName() ?? 'Not set';
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaletteViewModel>(
      builder: (context, paletteVm, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── User name ──────────────────────────────────────
            const Text(
              'User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _userName.isEmpty ? 'Not set' : _userName,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // ── Palette selection ──────────────────────────────
            const Text(
              'Color Palettes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: paletteVm.allPalettes.length,
                itemBuilder: (context, index) {
                  final palette = paletteVm.allPalettes[index];
                  final isSelected =
                      paletteVm.currentPalette == palette.name;
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
            const SizedBox(height: 8),
            Text(
              'Current: ${paletteVm.currentPalette}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }
}
