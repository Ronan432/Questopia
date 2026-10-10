import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Navigation destinations shown in the mobile bottom bar.
class LibraryMobileBottomBar extends ConsumerWidget {
  const LibraryMobileBottomBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.isInsideOverlay = false,
  });

  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final bool isInsideOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationBar(
      backgroundColor: isInsideOverlay ? Colors.transparent : null,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      selectedIndex: selectedTab,
      onDestinationSelected: (index) {
        HapticFeedback.lightImpact();
        onTabSelected(index);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.home,
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
  }
}