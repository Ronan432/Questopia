import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/settings_provider.dart';
import 'core/theme/questopia_theme.dart';
import 'features/library/presentation/library_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: QuestopiaApp(),
    ),
  );
}

class QuestopiaApp extends ConsumerWidget {
  const QuestopiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    ThemeMode mode;
    bool isAmoled = false;

    switch (settings.themeMode) {
      case ThemeModeOption.light:
        mode = ThemeMode.light;
        break;
      case ThemeModeOption.dark:
        mode = ThemeMode.dark;
        break;
      case ThemeModeOption.amoled:
        mode = ThemeMode.dark;
        isAmoled = true;
        break;
      case ThemeModeOption.system:
        mode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      title: 'Questopia',
      debugShowCheckedModeBanner: false,
      theme: QuestopiaTheme.light(),
      darkTheme: QuestopiaTheme.dark(amoled: isAmoled),
      themeMode: mode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ru', ''),
        Locale('tr', ''),
      ],
      home: const LibraryScreen(),
    );
  }
}
