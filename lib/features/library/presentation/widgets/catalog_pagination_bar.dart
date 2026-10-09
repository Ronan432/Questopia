import 'dart:ui';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../providers/library_provider.dart';

/// Bottom pagination bar for browsing remote catalog pages with blur backdrop support.
class CatalogPaginationBar extends ConsumerWidget {
  const CatalogPaginationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(libraryProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isBlur = settings.isNavBarBlur;
    final blurPercent = settings.navBarBlurPercent.clamp(10.0, 100.0);
    final sigma = (blurPercent / 100.0) * 24.0;

    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    final bottomPadding = isDesktop
        ? 10.0
        : (isBlur ? (MediaQuery.paddingOf(context).bottom + 4.0) : 10.0);

    final content = Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
      decoration: BoxDecoration(
        color: isBlur ? colors.surface.withValues(alpha: 0.55) : colors.surface,
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
          FilledButton.tonalIcon(
            onPressed: state.currentPage > 1 && !state.isLoadingRemote
                ? () => notifier.setCatalogPage(state.currentPage - 1)
                : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
            label: const Text('Prev'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(40, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
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
          FilledButton.tonalIcon(
            onPressed:
                state.currentPage < state.totalPages && !state.isLoadingRemote
                    ? () => notifier.setCatalogPage(state.currentPage + 1)
                    : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            label: const Text('Next'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(40, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );

    if (isBlur) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: content,
        ),
      );
    }

    return content;
  }
}
