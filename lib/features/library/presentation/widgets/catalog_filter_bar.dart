import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/helpers/sheet_helper.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../providers/library_provider.dart';

/// Horizontal filter bar for remote catalog including sort, language, and featured chips.
class CatalogFilterBar extends ConsumerStatefulWidget {
  const CatalogFilterBar({super.key});

  @override
  ConsumerState<CatalogFilterBar> createState() => _CatalogFilterBarState();
}

class _CatalogFilterBarState extends ConsumerState<CatalogFilterBar> {
  bool _isVisible = true;
  Timer? _reappearTimer;

  @override
  void dispose() {
    _reappearTimer?.cancel();
    super.dispose();
  }

  void _showBar() {
    _reappearTimer?.cancel();
    if (!_isVisible && mounted) setState(() => _isVisible = true);
  }

  void _hideBar() {
    if (_isVisible && mounted) setState(() => _isVisible = false);
  }

  bool _onScroll(ScrollNotification notification) {
    // Ignore the horizontal chip list so swiping categories sideways never
    // collapses the bar. Only vertical scrolling of the grid hides it.
    if (notification.metrics.axis == Axis.horizontal) return false;

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        _hideBar();
        _reappearTimer?.cancel();
        _reappearTimer = Timer(
          const Duration(milliseconds: 1200),
          _showBar,
        );
      } else if (notification.direction == ScrollDirection.forward) {
        _showBar();
        _reappearTimer?.cancel();
      }
    } else if (notification is ScrollEndNotification) {
      _reappearTimer?.cancel();
      _reappearTimer = Timer(const Duration(milliseconds: 400), _showBar);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _isVisible
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showSortPickerSheet(context, state),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort_rounded,
                              size: 18,
                              color: colors.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.catalogSort.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    for (final lang in const ['', 'ru', 'en']) ...[
                      _FilterChip(
                        label: lang.isEmpty
                            ? l10n.allLanguages
                            : lang.toUpperCase(),
                        isSelected: state.catalogLanguage == lang,
                        onTap: () =>
                            notifier.setCatalogFilter(language: lang),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _FilterChip(
                      label: l10n.featured,
                      isSelected: state.catalogFeaturedOnly,
                      leading: Icon(
                        state.catalogFeaturedOnly
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 18,
                        color: state.catalogFeaturedOnly
                            ? Colors.amber
                            : colors.onSurfaceVariant,
                      ),
                      onTap: () => notifier.setCatalogFilter(
                        featuredOnly: !state.catalogFeaturedOnly,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }

  void _showSortPickerSheet(BuildContext context, LibraryState state) {
    final notifier = ref.read(libraryProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuestopiaSheetHeaderPill(title: l10n.sortCatalog),
              SegmentedListSection(
                children: [
                  for (final opt in CatalogSortOption.values)
                    SegmentedListTile(
                      leading: Icon(
                        state.catalogSort == opt
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: state.catalogSort == opt
                            ? Theme.of(ctx).colorScheme.primary
                            : null,
                      ),
                      title: Text(opt.label),
                      trailing: state.catalogSort == opt
                          ? Icon(
                              Icons.check_rounded,
                              color: Theme.of(ctx).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        notifier.setCatalogFilter(sort: opt);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact rounded filter chip used across the catalog category bar.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Icon? leading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.secondaryContainer
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(isSelected ? 24 : 8),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.2)
                : colors.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colors.onSecondaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
