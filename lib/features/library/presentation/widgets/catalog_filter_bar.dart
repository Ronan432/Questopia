import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/helpers/sheet_helper.dart';
import '../../providers/library_provider.dart';

/// Horizontal filter bar for remote catalog including sort, language, and featured chips.
class CatalogFilterBar extends ConsumerWidget {
  const CatalogFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showSortPickerSheet(context, ref, state),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            GestureDetector(
              onTap: () => notifier.setCatalogFilter(language: lang),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: state.catalogLanguage == lang
                      ? colors.secondaryContainer
                      : colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(
                    state.catalogLanguage == lang ? 24 : 8,
                  ),
                  border: Border.all(
                    color: state.catalogLanguage == lang
                        ? colors.primary.withValues(alpha: 0.2)
                        : colors.outlineVariant.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  lang.isEmpty ? 'All Languages' : lang.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: state.catalogLanguage == lang
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: state.catalogLanguage == lang
                        ? colors.onSecondaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () => notifier.setCatalogFilter(
              featuredOnly: !state.catalogFeaturedOnly,
            ),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: state.catalogFeaturedOnly
                    ? colors.secondaryContainer
                    : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(
                  state.catalogFeaturedOnly ? 24 : 8,
                ),
                border: Border.all(
                  color: state.catalogFeaturedOnly
                      ? colors.primary.withValues(alpha: 0.2)
                      : colors.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.catalogFeaturedOnly
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: state.catalogFeaturedOnly
                        ? Colors.amber
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Featured',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: state.catalogFeaturedOnly
                        ? FontWeight.w600
                        : FontWeight.w500,
                      color: state.catalogFeaturedOnly
                          ? colors.onSecondaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortPickerSheet(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
  ) {
    final notifier = ref.read(libraryProvider.notifier);
    showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'Sort Catalog',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
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
