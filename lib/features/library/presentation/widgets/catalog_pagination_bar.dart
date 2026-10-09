import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../providers/library_provider.dart';

/// Bottom pagination bar for browsing remote catalog pages.
class CatalogPaginationBar extends ConsumerWidget {
  const CatalogPaginationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(libraryProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isBlur = settings.isNavBarBlur;
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    final bottomPadding = isDesktop
        ? 10.0
        : (isBlur ? (MediaQuery.paddingOf(context).bottom + 4.0) : 10.0);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
      decoration: BoxDecoration(
        color: isBlur ? colors.surface.withValues(alpha: 0.70) : colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: isBlur ? 0.2 : 0.35),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          M3EButton.icon(
            onPressed: state.currentPage > 1 && !state.isLoadingRemote
                ? () => notifier.setCatalogPage(state.currentPage - 1)
                : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
            label: const Text('Prev'),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
          ),
          AnimatedSwitcher(
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
                : Text(
                    'Page ${state.currentPage} of ${state.totalPages}',
                    key: ValueKey(
                      'catalog_page_${state.currentPage}_${state.totalPages}',
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.onSurface,
                    ),
                  ),
          ),
          M3EButton.icon(
            onPressed:
                state.currentPage < state.totalPages && !state.isLoadingRemote
                    ? () => notifier.setCatalogPage(state.currentPage + 1)
                    : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            label: const Text('Next'),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
          ),
        ],
      ),
    );
  }
}
