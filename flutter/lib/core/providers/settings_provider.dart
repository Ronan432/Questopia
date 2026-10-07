import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { system, light, dark, amoled }

class SettingsState {
  final ThemeModeOption themeMode;
  final double fontSize;
  final String gamesDirectory;

  const SettingsState({
    this.themeMode = ThemeModeOption.system,
    this.fontSize = 16.0,
    this.gamesDirectory = '',
  });

  SettingsState copyWith({
    ThemeModeOption? themeMode,
    double? fontSize,
    String? gamesDirectory,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      gamesDirectory: gamesDirectory ?? this.gamesDirectory,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyFontSize = 'settings_font_size';
  static const _keyGamesDirectory = 'settings_games_dir';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode) ?? 0;
    final fontSz = prefs.getDouble(_keyFontSize) ?? 16.0;
    final dir = prefs.getString(_keyGamesDirectory) ?? '';

    state = SettingsState(
      themeMode: ThemeModeOption.values[themeIndex.clamp(0, 3)],
      fontSize: fontSz,
      gamesDirectory: dir,
    );
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  Future<void> setGamesDirectory(String path) async {
    state = state.copyWith(gamesDirectory: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGamesDirectory, path);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
