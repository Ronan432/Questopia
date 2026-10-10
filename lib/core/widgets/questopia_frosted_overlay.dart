import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// Applies one single blur pass and one single tint behind a bottom overlay
/// stack so every child reads as one continuous frosted surface instead of
/// several differently tinted layers stacking on top of each other.
class QuestopiaFrostedOverlay extends ConsumerWidget {
  const QuestopiaFrostedOverlay({super.key, required this.child});

  final Widget child;

  /// Shared tint strength for every frosted surface in the app.
  static const double tintAlpha = 0.55;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colors = Theme.of(context).colorScheme;

    if (!settings.isNavBarBlur) return child;

    final percent = settings.navBarBlurPercent.clamp(10.0, 100.0);
    final sigma = (percent / 100.0) * 24.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ColoredBox(
          color: colors.surface.withValues(alpha: tintAlpha),
          child: child,
        ),
      ),
    );
  }
}