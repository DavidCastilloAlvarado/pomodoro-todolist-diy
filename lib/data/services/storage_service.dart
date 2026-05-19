import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _kNameKey = 'birdle_user_name';
  static const _kPaletteKey = 'birdle_palette';
  static const _kOnboardingKey = 'birdle_onboarding_complete';

  static final StorageService _instance = StorageService._internal();
  StorageService._internal();

  factory StorageService() => _instance;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String? getName() {
    return _prefs?.getString(_kNameKey);
  }

  Future<void> saveName(String name) async {
    await _prefs?.setString(_kNameKey, name);
  }

  String getPalette() {
    return _prefs?.getString(_kPaletteKey) ?? 'default';
  }

  Future<void> savePalette(String palette) async {
    await _prefs?.setString(_kPaletteKey, palette);
  }

  bool isFirstLaunch() {
    return _prefs?.getBool(_kOnboardingKey) != true;
  }

  Future<void> completeOnboarding() async {
    await _prefs?.setBool(_kOnboardingKey, true);
  }

  // ── Pomodoro duration config ──────────────────────────────────────

  static const _kPomoDurationsKey = 'birdle_pomodoro_durations';

  List<int> getPomodoroDurations() {
    final raw = _prefs?.getString(_kPomoDurationsKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').map(int.parse).toList();
  }

  Future<void> savePomodoroDurations(List<int> durations) async {
    await _prefs?.setString(_kPomoDurationsKey, durations.join(','));
  }

  // Default durations available to the user
  static const List<int> defaultPomodoroDurations = [25, 50, 75];
}
