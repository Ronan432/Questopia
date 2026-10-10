import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/widgets/questopia_morph_button.dart';
import '../../providers/library_provider.dart';

/// Bottom pagination bar for browsing remote catalog pages.
///
/// When placed inside [QuestopiaFrostedOverlay] the parent supplies the shared
/// blur and tint, so this bar paints nothing of its own and the frozen surface
/// stays continuous with the navigation bar below it.
class CatalogPaginationBar extends ConsumerWidget {
  const CatalogPaginationBar({super.key, this.isInsideOverlay = false});

  final bool isInsideOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(libraryProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final isBlur = settings.isNavBarBlur;

    final bottomPadding = MediaQuery.paddingOf(context).bottom > 0 ? 6.0 : 10.0;

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuestopiaMorphButton.tonal(
          onPressed: state.currentPage > 1 && !state.isLoadingRemote
              ? () => notifier.setCatalogPage(state.currentPage - 1)
              : null,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          child: Text(l10n.prev),
        ),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state.isLoadingRemote
                  ? SizedBox(
                      key: const ValueKey('catalog_page_loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colors.primary,
                      ),
                    )
                  : _PageIndicatorPill(
                      key: ValueKey(
                        'catalog_page_${state.currentPage}_${state.totalPages}',
                      ),
                      label: l10n.pageOf(
                        state.currentPage,
                        state.totalPages,
                      ),
                    ),
            ),
          ),
        ),
        QuestopiaMorphButton.tonal(
          onPressed:
              state.currentPage < state.totalPages && !state.isLoadingRemote
                  ? () => notifier.setCatalogPage(state.currentPage + 1)
                  : null,
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          child: Text(l10n.next),
        ),
      ],
    );

    if (isInsideOverlay) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
        child: row,
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
      color: isBlur
          ? colors.surface.withValues(alpha: 0.55)
          : colors.surface,
      child: row,
    );
  }
}

/// Frosted pill that shows the current catalog page position.
class _PageIndicatorPill extends StatelessWidget {
  const _PageIndicatorPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colors.onSecondaryContainer,
        ),
      ),
    );
  }
}