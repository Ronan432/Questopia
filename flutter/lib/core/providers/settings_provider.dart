import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { system, light, dark, amoled }

class SettingsState {
  final ThemeModeOption themeMode;
  final double fontSize;
  final int typefaceIndex;
  final bool isUseGameFont;
  final bool isUseAutoscroll;
  final bool isUseSeparator;
  final bool isSquarePosters;
  final bool isSoundEnabled;
  final bool isVideoMute;
  final bool isImageDisabled;
  final bool isPinchZoomEnabled;
  final bool isFullscreenImages;
  final bool isAutosaveEnabled;
  final int autosaveInterval;
  final bool isCheatsEnabled;
  final String actionsHeightRatio;
  final String language;
  final String gamesDirectory;

  const SettingsState({
    this.themeMode = ThemeModeOption.system,
    this.fontSize = 16.0,
    this.typefaceIndex = 0,
    this.isUseGameFont = false,
    this.isUseAutoscroll = true,
    this.isUseSeparator = false,
    this.isSquarePosters = false,
    this.isSoundEnabled = true,
    this.isVideoMute = false,
    this.isImageDisabled = false,
    this.isPinchZoomEnabled = true,
    this.isFullscreenImages = false,
    this.isAutosaveEnabled = true,
    this.autosaveInterval = 15,
    this.isCheatsEnabled = true,
    this.actionsHeightRatio = '1/3',
    this.language = 'system',
    this.gamesDirectory = '',
  });

  SettingsState copyWith({
    ThemeModeOption? themeMode,
    double? fontSize,
    int? typefaceIndex,
    bool? isUseGameFont,
    bool? isUseAutoscroll,
    bool? isUseSeparator,
    bool? isSquarePosters,
    bool? isSoundEnabled,
    bool? isVideoMute,
    bool? isImageDisabled,
    bool? isPinchZoomEnabled,
    bool? isFullscreenImages,
    bool? isAutosaveEnabled,
    int? autosaveInterval,
    bool? isCheatsEnabled,
    String? actionsHeightRatio,
    String? language,
    String? gamesDirectory,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      typefaceIndex: typefaceIndex ?? this.typefaceIndex,
      isUseGameFont: isUseGameFont ?? this.isUseGameFont,
      isUseAutoscroll: isUseAutoscroll ?? this.isUseAutoscroll,
      isUseSeparator: isUseSeparator ?? this.isUseSeparator,
      isSquarePosters: isSquarePosters ?? this.isSquarePosters,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isVideoMute: isVideoMute ?? this.isVideoMute,
      isImageDisabled: isImageDisabled ?? this.isImageDisabled,
      isPinchZoomEnabled: isPinchZoomEnabled ?? this.isPinchZoomEnabled,
      isFullscreenImages: isFullscreenImages ?? this.isFullscreenImages,
      isAutosaveEnabled: isAutosaveEnabled ?? this.isAutosaveEnabled,
      autosaveInterval: autosaveInterval ?? this.autosaveInterval,
      isCheatsEnabled: isCheatsEnabled ?? this.isCheatsEnabled,
      actionsHeightRatio: actionsHeightRatio ?? this.actionsHeightRatio,
      language: language ?? this.language,
      gamesDirectory: gamesDirectory ?? this.gamesDirectory,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  static const _kThemeMode = 'pref_theme_mode';
  static const _kFontSize = 'pref_font_size';
  static const _kTypeface = 'pref_typeface';
  static const _kUseGameFont = 'pref_use_game_font';
  static const _kAutoscroll = 'pref_autoscroll';
  static const _kSeparator = 'pref_separator';
  static const _kSquarePosters = 'pref_square_posters';
  static const _kSound = 'pref_sound';
  static const _kVideoMute = 'pref_video_mute';
  static const _kImageDisabled = 'pref_image_disabled';
  static const _kPinchZoom = 'pref_pinch_zoom';
  static const _kFullscreenImages = 'pref_fullscreen_images';
  static const _kAutosave = 'pref_autosave';
  static const _kAutosaveInterval = 'pref_autosave_interval';
  static const _kCheats = 'pref_cheats';
  static const _kActsHeight = 'pref_acts_height';
  static const _kLanguage = 'pref_language';
  static const _kGamesDir = 'pref_games_dir';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      themeMode: ThemeModeOption.values[(prefs.getInt(_kThemeMode) ?? 0).clamp(0, 3)],
      fontSize: prefs.getDouble(_kFontSize) ?? 16.0,
      typefaceIndex: prefs.getInt(_kTypeface) ?? 0,
      isUseGameFont: prefs.getBool(_kUseGameFont) ?? false,
      isUseAutoscroll: prefs.getBool(_kAutoscroll) ?? true,
      isUseSeparator: prefs.getBool(_kSeparator) ?? false,
      isSquarePosters: prefs.getBool(_kSquarePosters) ?? false,
      isSoundEnabled: prefs.getBool(_kSound) ?? true,
      isVideoMute: prefs.getBool(_kVideoMute) ?? false,
      isImageDisabled: prefs.getBool(_kImageDisabled) ?? false,
      isPinchZoomEnabled: prefs.getBool(_kPinchZoom) ?? true,
      isFullscreenImages: prefs.getBool(_kFullscreenImages) ?? false,
      isAutosaveEnabled: prefs.getBool(_kAutosave) ?? true,
      autosaveInterval: prefs.getInt(_kAutosaveInterval) ?? 15,
      isCheatsEnabled: prefs.getBool(_kCheats) ?? true,
      actionsHeightRatio: prefs.getString(_kActsHeight) ?? '1/3',
      language: prefs.getString(_kLanguage) ?? 'system',
      gamesDirectory: prefs.getString(_kGamesDir) ?? '',
    );
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSize, size);
  }

  Future<void> setTypefaceIndex(int index) async {
    state = state.copyWith(typefaceIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTypeface, index);
  }

  Future<void> setUseGameFont(bool value) async {
    state = state.copyWith(isUseGameFont: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseGameFont, value);
  }

  Future<void> setAutoscroll(bool value) async {
    state = state.copyWith(isUseAutoscroll: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoscroll, value);
  }

  Future<void> setSeparator(bool value) async {
    state = state.copyWith(isUseSeparator: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeparator, value);
  }

  Future<void> setSquarePosters(bool value) async {
    state = state.copyWith(isSquarePosters: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSquarePosters, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(isSoundEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSound, value);
  }

  Future<void> setVideoMute(bool value) async {
    state = state.copyWith(isVideoMute: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kVideoMute, value);
  }

  Future<void> setImageDisabled(bool value) async {
    state = state.copyWith(isImageDisabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kImageDisabled, value);
  }

  Future<void> setPinchZoom(bool value) async {
    state = state.copyWith(isPinchZoomEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPinchZoom, value);
  }

  Future<void> setFullscreenImages(bool value) async {
    state = state.copyWith(isFullscreenImages: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFullscreenImages, value);
  }

  Future<void> setAutosave(bool value) async {
    state = state.copyWith(isAutosaveEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutosave, value);
  }

  Future<void> setAutosaveInterval(int interval) async {
    state = state.copyWith(autosaveInterval: interval);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAutosaveInterval, interval);
  }

  Future<void> setCheatsEnabled(bool value) async {
    state = state.copyWith(isCheatsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCheats, value);
  }

  Future<void> setActionsHeightRatio(String ratio) async {
    state = state.copyWith(actionsHeightRatio: ratio);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActsHeight, ratio);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, lang);
  }

  Future<void> setGamesDirectory(String path) async {
    state = state.copyWith(gamesDirectory: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGamesDir, path);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
