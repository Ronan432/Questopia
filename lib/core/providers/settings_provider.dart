import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { system, light, dark, amoled }

/// Accent color options matching the legacy Android/KMP theme palette.
const kThemeColorOptions = <String>[
  'dynamic',
  'blue',
  'green',
  'orange',
  'purple',
  'pink',
  'teal',
  'amber',
  'monochrome',
];

class SettingsState {
  final ThemeModeOption themeMode;
  final String themeColor;
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

  // Legacy parity settings (old Android/KMP client).
  final bool isImmersiveMode;
  final bool isImagesInDialogEnabled;
  final bool useGameTextColor;
  final int gameTextColor;
  final bool useGameBackgroundColor;
  final int gameBackColor;
  final bool useGameLinkColor;
  final int gameLinkColor;
  final bool isAutoWidth;
  final int customWidthImage;
  final bool isAutoHeight;
  final int customHeightImage;
  final bool isNavBarBlur;
  final double navBarBlurPercent;
  final bool isEdgeFeedback;
  final bool isExecStringEnabled;
  final int binaryPrefixes;

  const SettingsState({
    this.themeMode = ThemeModeOption.system,
    this.themeColor = 'dynamic',
    this.fontSize = 16.0,
    this.typefaceIndex = 0,
    this.isUseGameFont = false,
    this.isUseAutoscroll = true,
    this.isUseSeparator = false,
    this.isSquarePosters = false,
    this.isSoundEnabled = true,
    this.isVideoMute = true,
    this.isImageDisabled = false,
    this.isPinchZoomEnabled = true,
    this.isFullscreenImages = false,
    this.isAutosaveEnabled = false,
    this.autosaveInterval = 15,
    this.isCheatsEnabled = false,
    this.actionsHeightRatio = '1/3',
    this.language = 'system',
    this.gamesDirectory = '',
    this.isImmersiveMode = true,
    this.isImagesInDialogEnabled = false,
    this.useGameTextColor = true,
    this.gameTextColor = 0xFF000000,
    this.useGameBackgroundColor = true,
    this.gameBackColor = 0xFFE0E0E0,
    this.useGameLinkColor = true,
    this.gameLinkColor = 0xFF0000FF,
    this.isAutoWidth = true,
    this.customWidthImage = 400,
    this.isAutoHeight = true,
    this.customHeightImage = 400,
    this.isNavBarBlur = false,
    this.navBarBlurPercent = 70.0,
    this.isEdgeFeedback = true,
    this.isExecStringEnabled = false,
    this.binaryPrefixes = 1000,
  });

  SettingsState copyWith({
    ThemeModeOption? themeMode,
    String? themeColor,
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
    bool? isImmersiveMode,
    bool? isImagesInDialogEnabled,
    bool? useGameTextColor,
    int? gameTextColor,
    bool? useGameBackgroundColor,
    int? gameBackColor,
    bool? useGameLinkColor,
    int? gameLinkColor,
    bool? isAutoWidth,
    int? customWidthImage,
    bool? isAutoHeight,
    int? customHeightImage,
    bool? isNavBarBlur,
    double? navBarBlurPercent,
    bool? isEdgeFeedback,
    bool? isExecStringEnabled,
    int? binaryPrefixes,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
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
      isImmersiveMode: isImmersiveMode ?? this.isImmersiveMode,
      isImagesInDialogEnabled:
          isImagesInDialogEnabled ?? this.isImagesInDialogEnabled,
      useGameTextColor: useGameTextColor ?? this.useGameTextColor,
      gameTextColor: gameTextColor ?? this.gameTextColor,
      useGameBackgroundColor:
          useGameBackgroundColor ?? this.useGameBackgroundColor,
      gameBackColor: gameBackColor ?? this.gameBackColor,
      useGameLinkColor: useGameLinkColor ?? this.useGameLinkColor,
      gameLinkColor: gameLinkColor ?? this.gameLinkColor,
      isAutoWidth: isAutoWidth ?? this.isAutoWidth,
      customWidthImage: customWidthImage ?? this.customWidthImage,
      isAutoHeight: isAutoHeight ?? this.isAutoHeight,
      customHeightImage: customHeightImage ?? this.customHeightImage,
      isNavBarBlur: isNavBarBlur ?? this.isNavBarBlur,
      navBarBlurPercent: navBarBlurPercent ?? this.navBarBlurPercent,
      isEdgeFeedback: isEdgeFeedback ?? this.isEdgeFeedback,
      isExecStringEnabled: isExecStringEnabled ?? this.isExecStringEnabled,
      binaryPrefixes: binaryPrefixes ?? this.binaryPrefixes,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  static const _kThemeMode = 'pref_theme_mode';
  static const _kThemeColor = 'pref_theme_color';
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
  static const _kImmersive = 'pref_immersive_mode';
  static const _kImagesInDialog = 'pref_images_in_dialog';
  static const _kUseGameTextColor = 'pref_use_game_text_color';
  static const _kGameTextColor = 'pref_game_text_color';
  static const _kUseGameBackColor = 'pref_use_game_back_color';
  static const _kGameBackColor = 'pref_game_back_color';
  static const _kUseGameLinkColor = 'pref_use_game_link_color';
  static const _kGameLinkColor = 'pref_game_link_color';
  static const _kAutoWidth = 'pref_auto_width';
  static const _kCustomWidthImage = 'pref_custom_width_image';
  static const _kAutoHeight = 'pref_auto_height';
  static const _kCustomHeightImage = 'pref_custom_height_image';
  static const _kNavBarBlur = 'pref_nav_bar_blur';
  static const _kNavBarBlurPercent = 'pref_nav_bar_blur_percent';
  static const _kEdgeFeedback = 'pref_edge_feedback';
  static const _kExecString = 'pref_exec_string';
  static const _kBinaryPrefixes = 'pref_binary_prefixes';
  static const _kLegacyMigrated = 'pref_legacy_settings_migrated';

  static const _themeModes = [
    ThemeModeOption.system,
    ThemeModeOption.light,
    ThemeModeOption.dark,
    ThemeModeOption.amoled,
  ];

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_kLegacyMigrated) != true) {
      await _migrateLegacyPreferences(prefs);
    }

    if (!mounted) return;

    state = SettingsState(
      themeMode: _themeModes[
          (prefs.getInt(_kThemeMode) ?? 0).clamp(0, _themeModes.length - 1)],
      themeColor:
          prefs.getString(_kThemeColor) ?? _legacyString(prefs, 'themeColor') ?? 'dynamic',
      fontSize: prefs.getDouble(_kFontSize) ??
          double.tryParse(_legacyString(prefs, 'fontSize') ?? '') ??
          16.0,
      typefaceIndex: prefs.getInt(_kTypeface) ??
          int.tryParse(_legacyString(prefs, 'fontStyle') ??
              _legacyString(prefs, 'typeface') ??
              '') ??
          0,
      isUseGameFont: prefs.getBool(_kUseGameFont) ??
          _legacyBool(prefs, 'isUseGameFont') ??
          _legacyBool(prefs, 'useGameFont') ??
          false,
      isUseAutoscroll:
          prefs.getBool(_kAutoscroll) ?? _legacyBool(prefs, 'autoscroll') ?? true,
      isUseSeparator:
          prefs.getBool(_kSeparator) ?? _legacyBool(prefs, 'separator') ?? false,
      isSquarePosters: prefs.getBool(_kSquarePosters) ??
          _legacyBool(prefs, 'squarePosters') ??
          false,
      isSoundEnabled: prefs.getBool(_kSound) ??
          _legacyBool(prefs, 'pref_audio_play') ??
          _legacyBool(prefs, 'sound') ??
          true,
      isVideoMute: prefs.getBool(_kVideoMute) ??
          _legacyBool(prefs, 'pref_mute_video') ??
          _legacyBool(prefs, 'videoMute') ??
          true,
      isImageDisabled: prefs.getBool(_kImageDisabled) ??
          _legacyBool(prefs, 'pref_disable_image') ??
          false,
      isPinchZoomEnabled: prefs.getBool(_kPinchZoom) ??
          _legacyBool(prefs, 'pinchZoom') ??
          true,
      isFullscreenImages: prefs.getBool(_kFullscreenImages) ??
          _legacyBool(prefs, 'fullScreenImage') ??
          false,
      isAutosaveEnabled: prefs.getBool(_kAutosave) ??
          _legacyBool(prefs, 'autosave') ??
          false,
      autosaveInterval: prefs.getInt(_kAutosaveInterval) ??
          _legacyInt(prefs, 'autosaveInterval') ??
          15,
      isCheatsEnabled: prefs.getBool(_kCheats) ??
          _legacyBool(prefs, 'enableCheats') ??
          false,
      actionsHeightRatio: prefs.getString(_kActsHeight) ??
          _legacyString(prefs, 'actsHeight') ??
          '1/3',
      language: prefs.getString(_kLanguage) ?? _legacyString(prefs, 'lang') ?? 'system',
      gamesDirectory: prefs.getString(_kGamesDir) ?? '',
      isImmersiveMode: prefs.getBool(_kImmersive) ??
          _legacyBool(prefs, 'immersiveMode') ??
          true,
      isImagesInDialogEnabled: prefs.getBool(_kImagesInDialog) ??
          _legacyBool(prefs, 'permImgDialog') ??
          false,
      useGameTextColor: prefs.getBool(_kUseGameTextColor) ??
          _legacyBool(prefs, 'useGameTextColor') ??
          true,
      gameTextColor: prefs.getInt(_kGameTextColor) ??
          _legacyInt(prefs, 'textColor') ??
          0xFF000000,
      useGameBackgroundColor: prefs.getBool(_kUseGameBackColor) ??
          _legacyBool(prefs, 'useGameBackgroundColor') ??
          true,
      gameBackColor: prefs.getInt(_kGameBackColor) ??
          _legacyInt(prefs, 'backColor') ??
          0xFFE0E0E0,
      useGameLinkColor: prefs.getBool(_kUseGameLinkColor) ??
          _legacyBool(prefs, 'useGameLinkColor') ??
          true,
      gameLinkColor: prefs.getInt(_kGameLinkColor) ??
          _legacyInt(prefs, 'linkColor') ??
          0xFF0000FF,
      isAutoWidth: prefs.getBool(_kAutoWidth) ??
          _legacyBool(prefs, 'autoWidth') ??
          true,
      customWidthImage: prefs.getInt(_kCustomWidthImage) ??
          int.tryParse(_legacyString(prefs, 'customWidthImage') ?? '') ??
          400,
      isAutoHeight: prefs.getBool(_kAutoHeight) ??
          _legacyBool(prefs, 'autoHeight') ??
          true,
      customHeightImage: prefs.getInt(_kCustomHeightImage) ??
          int.tryParse(_legacyString(prefs, 'customHeightImage') ?? '') ??
          400,
      isNavBarBlur:
          prefs.getBool(_kNavBarBlur) ?? false,
      navBarBlurPercent:
          prefs.getDouble(_kNavBarBlurPercent) ?? 70.0,
      isEdgeFeedback:
          prefs.getBool(_kEdgeFeedback) ?? true,
      isExecStringEnabled: prefs.getBool(_kExecString) ??
          _legacyBool(prefs, 'execString') ??
          false,
      binaryPrefixes: prefs.getInt(_kBinaryPrefixes) ??
          int.tryParse(_legacyString(prefs, 'binPref') ?? '') ??
          1000,
    );
  }

  /// One-time migration from the legacy Android/KMP preference keys that
  /// lived in the same `com.questopia.re` SharedPreferences file.
  Future<void> _migrateLegacyPreferences(SharedPreferences prefs) async {
    final legacyThemeMode = _legacyString(prefs, 'themeMode');
    if (legacyThemeMode != null) {
      final index = _themeModes.indexWhere(
        (mode) => mode.name == legacyThemeMode,
      );
      if (index >= 0) await prefs.setInt(_kThemeMode, index);
    }
    await _migrateString(prefs, 'themeColor', _kThemeColor);
    await _migrateString(prefs, 'fontSize', _kFontSize);
    await _migrateString(prefs, 'fontStyle', _kTypeface);
    await _migrateBool(prefs, 'isUseGameFont', _kUseGameFont);
    await _migrateBool(prefs, 'autoscroll', _kAutoscroll);
    await _migrateBool(prefs, 'separator', _kSeparator);
    await _migrateBool(prefs, 'squarePosters', _kSquarePosters);
    await _migrateBool(prefs, 'pref_audio_play', _kSound);
    await _migrateBool(prefs, 'pref_mute_video', _kVideoMute);
    await _migrateBool(prefs, 'pref_disable_image', _kImageDisabled);
    await _migrateBool(prefs, 'pinchZoom', _kPinchZoom);
    await _migrateBool(prefs, 'fullScreenImage', _kFullscreenImages);
    await _migrateBool(prefs, 'autosave', _kAutosave);
    await _migrateInt(prefs, 'autosaveInterval', _kAutosaveInterval);
    await _migrateBool(prefs, 'enableCheats', _kCheats);
    await _migrateString(prefs, 'actsHeight', _kActsHeight);
    await _migrateString(prefs, 'lang', _kLanguage);
    await _migrateBool(prefs, 'immersiveMode', _kImmersive);
    await _migrateBool(prefs, 'permImgDialog', _kImagesInDialog);
    await _migrateBool(prefs, 'useGameTextColor', _kUseGameTextColor);
    await _migrateInt(prefs, 'textColor', _kGameTextColor);
    await _migrateBool(prefs, 'useGameBackgroundColor', _kUseGameBackColor);
    await _migrateInt(prefs, 'backColor', _kGameBackColor);
    await _migrateBool(prefs, 'useGameLinkColor', _kUseGameLinkColor);
    await _migrateInt(prefs, 'linkColor', _kGameLinkColor);
    await _migrateBool(prefs, 'autoWidth', _kAutoWidth);
    await _migrateString(prefs, 'customWidthImage', _kCustomWidthImage);
    await _migrateBool(prefs, 'autoHeight', _kAutoHeight);
    await _migrateString(prefs, 'customHeightImage', _kCustomHeightImage);
    await _migrateBool(prefs, 'execString', _kExecString);
    await _migrateString(prefs, 'binPref', _kBinaryPrefixes);
    await prefs.setBool(_kLegacyMigrated, true);
  }

  static String? _legacyString(SharedPreferences prefs, String key) =>
      prefs.getString(key);

  static bool? _legacyBool(SharedPreferences prefs, String key) =>
      prefs.getBool(key);

  static int? _legacyInt(SharedPreferences prefs, String key) =>
      prefs.getInt(key);

  Future<void> _migrateString(
    SharedPreferences prefs,
    String legacyKey,
    String newKey,
  ) async {
    if (prefs.get(newKey) != null) return;
    final value = prefs.getString(legacyKey);
    if (value == null) return;
    if (newKey == _kFontSize ||
        newKey == _kBinaryPrefixes ||
        newKey == _kTypeface ||
        newKey == _kCustomWidthImage ||
        newKey == _kCustomHeightImage) {
      final parsed = int.tryParse(value) ?? double.tryParse(value)?.round();
      if (parsed == null) return;
      if (newKey == _kFontSize) {
        await prefs.setDouble(newKey, double.parse(value));
      } else {
        await prefs.setInt(newKey, parsed);
      }
      return;
    }
    await prefs.setString(newKey, value);
  }

  Future<void> _migrateInt(
    SharedPreferences prefs,
    String legacyKey,
    String newKey,
  ) async {
    if (prefs.get(newKey) != null) return;
    final value = prefs.getInt(legacyKey);
    if (value == null) return;
    await prefs.setInt(newKey, value);
  }

  Future<void> _migrateBool(
    SharedPreferences prefs,
    String legacyKey,
    String newKey,
  ) async {
    if (prefs.get(newKey) != null) return;
    final value = prefs.getBool(legacyKey);
    if (value == null) return;
    await prefs.setBool(newKey, value);
  }

  Future<void> _set<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (value) {
      case final int v:
        await prefs.setInt(key, v);
      case final bool v:
        await prefs.setBool(key, v);
      case final double v:
        await prefs.setDouble(key, v);
      case final String v:
        await prefs.setString(key, v);
    }
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    state = state.copyWith(themeMode: mode);
    await _set(_kThemeMode, mode.index);
  }

  Future<void> setThemeColor(String color) async {
    if (!kThemeColorOptions.contains(color)) return;
    state = state.copyWith(themeColor: color);
    await _set(_kThemeColor, color);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _set(_kFontSize, size);
  }

  Future<void> setTypefaceIndex(int index) async {
    state = state.copyWith(typefaceIndex: index);
    await _set(_kTypeface, index);
  }

  Future<void> setUseGameFont(bool value) async {
    state = state.copyWith(isUseGameFont: value);
    await _set(_kUseGameFont, value);
  }

  Future<void> setAutoscroll(bool value) async {
    state = state.copyWith(isUseAutoscroll: value);
    await _set(_kAutoscroll, value);
  }

  Future<void> setSeparator(bool value) async {
    state = state.copyWith(isUseSeparator: value);
    await _set(_kSeparator, value);
  }

  Future<void> setSquarePosters(bool value) async {
    state = state.copyWith(isSquarePosters: value);
    await _set(_kSquarePosters, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(isSoundEnabled: value);
    await _set(_kSound, value);
  }

  Future<void> setVideoMute(bool value) async {
    state = state.copyWith(isVideoMute: value);
    await _set(_kVideoMute, value);
  }

  Future<void> setImageDisabled(bool value) async {
    state = state.copyWith(isImageDisabled: value);
    await _set(_kImageDisabled, value);
  }

  Future<void> setPinchZoom(bool value) async {
    state = state.copyWith(isPinchZoomEnabled: value);
    await _set(_kPinchZoom, value);
  }

  Future<void> setFullscreenImages(bool value) async {
    state = state.copyWith(isFullscreenImages: value);
    await _set(_kFullscreenImages, value);
  }

  Future<void> setAutosave(bool value) async {
    state = state.copyWith(isAutosaveEnabled: value);
    await _set(_kAutosave, value);
  }

  Future<void> setAutosaveInterval(int interval) async {
    state = state.copyWith(autosaveInterval: interval);
    await _set(_kAutosaveInterval, interval);
  }

  Future<void> setCheatsEnabled(bool value) async {
    state = state.copyWith(isCheatsEnabled: value);
    await _set(_kCheats, value);
  }

  Future<void> setActionsHeightRatio(String ratio) async {
    state = state.copyWith(actionsHeightRatio: ratio);
    await _set(_kActsHeight, ratio);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _set(_kLanguage, lang);
  }

  Future<void> setGamesDirectory(String path) async {
    state = state.copyWith(gamesDirectory: path);
    await _set(_kGamesDir, path);
  }

  Future<void> setImmersiveMode(bool value) async {
    state = state.copyWith(isImmersiveMode: value);
    await _set(_kImmersive, value);
  }

  Future<void> setImagesInDialog(bool value) async {
    state = state.copyWith(isImagesInDialogEnabled: value);
    await _set(_kImagesInDialog, value);
  }

  Future<void> setUseGameTextColor(bool value) async {
    state = state.copyWith(useGameTextColor: value);
    await _set(_kUseGameTextColor, value);
  }

  Future<void> setGameTextColor(int color) async {
    state = state.copyWith(gameTextColor: color);
    await _set(_kGameTextColor, color);
  }

  Future<void> setUseGameBackgroundColor(bool value) async {
    state = state.copyWith(useGameBackgroundColor: value);
    await _set(_kUseGameBackColor, value);
  }

  Future<void> setGameBackColor(int color) async {
    state = state.copyWith(gameBackColor: color);
    await _set(_kGameBackColor, color);
  }

  Future<void> setUseGameLinkColor(bool value) async {
    state = state.copyWith(useGameLinkColor: value);
    await _set(_kUseGameLinkColor, value);
  }

  Future<void> setGameLinkColor(int color) async {
    state = state.copyWith(gameLinkColor: color);
    await _set(_kGameLinkColor, color);
  }

  Future<void> setAutoWidth(bool value) async {
    state = state.copyWith(isAutoWidth: value);
    await _set(_kAutoWidth, value);
  }

  Future<void> setCustomWidthImage(int value) async {
    state = state.copyWith(customWidthImage: value.clamp(100, 2000));
    await _set(_kCustomWidthImage, value.clamp(100, 2000));
  }

  Future<void> setAutoHeight(bool value) async {
    state = state.copyWith(isAutoHeight: value);
    await _set(_kAutoHeight, value);
  }

  Future<void> setCustomHeightImage(int value) async {
    state = state.copyWith(customHeightImage: value.clamp(100, 2000));
    await _set(_kCustomHeightImage, value.clamp(100, 2000));
  }

  Future<void> setNavBarBlur(bool value) async {
    state = state.copyWith(isNavBarBlur: value);
    await _set(_kNavBarBlur, value);
  }

  Future<void> setNavBarBlurPercent(double percent) async {
    final clamped = percent.clamp(10.0, 100.0);
    state = state.copyWith(navBarBlurPercent: clamped);
    await _set(_kNavBarBlurPercent, clamped);
  }

  Future<void> setEdgeFeedback(bool value) async {
    state = state.copyWith(isEdgeFeedback: value);
    await _set(_kEdgeFeedback, value);
  }

  Future<void> setExecStringEnabled(bool value) async {
    state = state.copyWith(isExecStringEnabled: value);
    await _set(_kExecString, value);
  }

  Future<void> setBinaryPrefixes(int value) async {
    state = state.copyWith(binaryPrefixes: value);
    await _set(_kBinaryPrefixes, value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
