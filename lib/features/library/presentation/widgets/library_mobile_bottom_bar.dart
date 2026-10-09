import 'dart:ui';

import 'package:flutter/material.dart';
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

    final items = [
      (
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.library,
      ),
      (
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront_rounded,
        label: l10n.catalog,
      ),
      (
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
      ),
    ];

    Widget barContent = Container(
      decoration: BoxDecoration(
        color: isBlur ? colors.surface.withValues(alpha: 0.55) : colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: isBlur ? 0.2 : 0.35),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: MediaQuery.paddingOf(context).bottom + 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            _buildNavItem(
              context,
              index: i,
              icon: items[i].icon,
              selectedIcon: items[i].selectedIcon,
              label: items[i].label,
              isSelected: selectedTab == i,
              colors: colors,
            ),
        ],
      ),
    );

    if (isBlur) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: barContent,
        ),
      );
    }

    return barContent;
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required ColorScheme colors,
  }) {
    final activeColor = colors.primary;
    final inactiveColor = colors.onSurfaceVariant;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 24,
                color: isSelected ? colors.onSecondaryContainer : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
