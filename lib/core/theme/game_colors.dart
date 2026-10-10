import 'package:flutter/material.dart';

/// Fixed reading surface colors for the game screen.
///
/// The story and status panes intentionally ignore the Material color scheme.
/// Dynamic Material You tints bleed into the rendered QSP HTML and shift with
/// the system wallpaper, which makes the reading surface unstable. The game
/// text keeps a neutral, high contrast surface instead: pure black with white
/// text in dark mode, pure white with black text in light mode.
class GameColors {
  const GameColors._();

  static const Color _darkBackground = Color(0xFF000000);
  static const Color _darkForeground = Color(0xFFFFFFFF);
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightForeground = Color(0xFF000000);

  /// Reading surface behind the game text.
  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? _darkBackground : _lightBackground;

  /// Text color paired with [background].
  static Color foreground(Brightness brightness) =>
      brightness == Brightness.dark ? _darkForeground : _lightForeground;
}