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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          ChoiceChip(
            showCheckmark: false,
            avatar: const Icon(Icons.sort_rounded, size: 18),
            label: Text(state.catalogSort.label),
            selected: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onSelected: (_) => _showSortPickerSheet(context, ref, state),
          ),
          const SizedBox(width: 8),
          for (final lang in const ['', 'ru', 'en']) ...[
            ChoiceChip(
              showCheckmark: false,
              label: Text(lang.isEmpty ? 'All Languages' : lang.toUpperCase()),
              selected: state.catalogLanguage == lang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) {
                notifier.setCatalogFilter(language: lang);
              },
            ),
            const SizedBox(width: 8),
          ],
          ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              state.catalogFeaturedOnly
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 18,
              color: state.catalogFeaturedOnly ? Colors.amber : null,
            ),
            label: const Text('Featured'),
            selected: state.catalogFeaturedOnly,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (selected) {
              notifier.setCatalogFilter(featuredOnly: selected);
            },
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
