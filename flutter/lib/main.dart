import 'package:flutter/material.dart';

import 'core/theme/questopia_theme.dart';
import 'features/library/presentation/library_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuestopiaApp());
}

class QuestopiaApp extends StatefulWidget {
  const QuestopiaApp({super.key});

  @override
  State<QuestopiaApp> createState() => _QuestopiaAppState();
}

class _QuestopiaAppState extends State<QuestopiaApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _amoled = false;

  void _setTheme(ThemeMode mode, bool amoled) {
    setState(() {
      _themeMode = mode;
      _amoled = amoled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questopia',
      debugShowCheckedModeBanner: false,
      theme: QuestopiaTheme.light(),
      darkTheme: QuestopiaTheme.dark(amoled: _amoled),
      themeMode: _themeMode,
      home: LibraryScreen(onThemeChanged: _setTheme),
    );
  }
}
