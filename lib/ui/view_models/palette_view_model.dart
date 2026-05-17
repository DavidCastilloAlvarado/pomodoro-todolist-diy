import 'package:flutter/material.dart';
import 'package:birdle/core/themes/palettes.dart';
import 'package:birdle/data/services/storage_service.dart';

class PaletteViewModel extends ChangeNotifier {
  PaletteViewModel({required StorageService storage}) : _storage = storage {
    _currentPalette = StorageService().getPalette();
  }

  final StorageService _storage;

  String _currentPalette = 'default';
  String get currentPalette => _currentPalette;

  ColorScheme get colorScheme {
    final palette = palettes[_currentPalette];
    return palette?.light ?? palettes.values.first.light;
  }
  ColorScheme? get darkColorScheme => palettes[_currentPalette]?.dark;

  List<Palette> get allPalettes => palettes.values.toList();

  Future<void> setPalette(String name) async {
    _currentPalette = name;
    await _storage.savePalette(name);
    notifyListeners();
  }
}
