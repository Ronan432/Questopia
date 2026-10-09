import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';

/// Floating or standard mobile bottom bar with blur support for the library screen.
class LibraryMobileBottomBar extends ConsumerWidget {
  const LibraryMobileBottomBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final isBlur = settings.isNavBarBlur;
    final blurPercent = settings.navBarBlurPercent.clamp(10.0, 100.0);
    final sigma = (blurPercent / 100.0) * 24.0;

    final navBar = NavigationBar(
      backgroundColor:
          isBlur ? colors.surface.withValues(alpha: 0.70) : null,
      selectedIndex: selectedTab,
      onDestinationSelected: (index) {
        HapticFeedback.lightImpact();
        onTabSelected(index);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.library,
        ),
        NavigationDestination(
          icon: const Icon(Icons.storefront_outlined),
          selectedIcon: const Icon(Icons.storefront_rounded),
          label: l10n.catalog,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settings,
        ),
      ],
    );

    if (isBlur) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: navBar,
        ),
      );
    }

    return navBar;
  }
}
