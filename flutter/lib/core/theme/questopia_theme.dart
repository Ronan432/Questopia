import 'package:flutter/material.dart';

abstract final class QuestopiaTheme {
  static ThemeData light() => _theme(Brightness.light, const Color(0xff4d5f9f));

  static ThemeData dark({required bool amoled}) => _theme(
    Brightness.dark,
    const Color(0xffbbc6ff),
    surface: amoled ? Colors.black : const Color(0xff11131a),
  );

  static ThemeData _theme(Brightness brightness, Color seed, {Color? surface}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
