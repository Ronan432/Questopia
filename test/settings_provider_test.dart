import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/core/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  SettingsNotifier readNotifier(ProviderContainer container) {
    container.read(settingsProvider);
    return container.read(settingsProvider.notifier);
  }

  test('fresh install uses KMP-parity defaults', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = readNotifier(container);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final settings = container.read(settingsProvider);
    expect(settings.isAutosaveEnabled, isFalse);
    expect(settings.isCheatsEnabled, isFalse);
    expect(settings.isVideoMute, isTrue);
    expect(settings.useGameBackgroundColor, isTrue);
    expect(settings.gameBackColor, 0xFFE0E0E0);
    expect(settings.useGameLinkColor, isTrue);
    expect(settings.gameLinkColor, 0xFF0000FF);
    expect(settings.isAutoWidth, isTrue);
    expect(settings.customWidthImage, 400);
    expect(settings.isAutoHeight, isTrue);
    expect(settings.customHeightImage, 400);
    expect(settings.isNavBarBlur, isFalse);
    expect(notifier, isNotNull);
  });

  test('new settings round-trip through storage', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = readNotifier(container);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.setUseGameBackgroundColor(false);
    await notifier.setGameBackColor(0xFF112233);
    await notifier.setUseGameLinkColor(false);
    await notifier.setGameLinkColor(0xFF445566);
    await notifier.setAutoWidth(false);
    await notifier.setCustomWidthImage(800);
    await notifier.setAutoHeight(false);
    await notifier.setCustomHeightImage(600);
    await notifier.setNavBarBlur(true);

    final settings = container.read(settingsProvider);
    expect(settings.useGameBackgroundColor, isFalse);
    expect(settings.gameBackColor, 0xFF112233);
    expect(settings.useGameLinkColor, isFalse);
    expect(settings.gameLinkColor, 0xFF445566);
    expect(settings.isAutoWidth, isFalse);
    expect(settings.customWidthImage, 800);
    expect(settings.isAutoHeight, isFalse);
    expect(settings.customHeightImage, 600);
    expect(settings.isNavBarBlur, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('pref_use_game_back_color'), isFalse);
    expect(prefs.getInt('pref_game_back_color'), 0xFF112233);
    expect(prefs.getInt('pref_custom_width_image'), 800);
    expect(prefs.getBool('pref_nav_bar_blur'), isTrue);
  });

  test('legacy KMP keys migrate to new settings', () async {
    SharedPreferences.setMockInitialValues({
      'useGameBackgroundColor': false,
      'backColor': 0xFF111111,
      'useGameLinkColor': false,
      'linkColor': 0xFF222222,
      'autoWidth': false,
      'customWidthImage': '500',
      'autoHeight': false,
      'customHeightImage': '700',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    readNotifier(container);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final settings = container.read(settingsProvider);
    expect(settings.useGameBackgroundColor, isFalse);
    expect(settings.gameBackColor, 0xFF111111);
    expect(settings.useGameLinkColor, isFalse);
    expect(settings.gameLinkColor, 0xFF222222);
    expect(settings.isAutoWidth, isFalse);
    expect(settings.customWidthImage, 500);
    expect(settings.isAutoHeight, isFalse);
    expect(settings.customHeightImage, 700);
  });
}
