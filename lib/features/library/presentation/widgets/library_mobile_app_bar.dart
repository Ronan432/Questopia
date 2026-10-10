import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../providers/library_provider.dart';

/// Mobile app bar for library screen with dynamic title, animated transitions, search bar, and actions.
class LibraryMobileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const LibraryMobileAppBar({
    super.key,
    required this.selectedTab,
    required this.isSearchOpen,
    required this.showFavoritesOnly,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onToggleFavorites,
    required this.onImportGame,
  });

  final int selectedTab;
  final bool isSearchOpen;
  final bool showFavoritesOnly;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final VoidCallback onToggleFavorites;
  final VoidCallback onImportGame;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: colors.surface,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: isSearchOpen
              ? SizedBox(
                  key: const ValueKey('search_bar_active'),
                  height: 46,
                  child: SearchBar(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    hintText: selectedTab == 0
                        ? l10n.search
                        : 'Search games...',
                    leading: Icon(
                      Icons.search_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    trailing: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Close search',
                        onPressed: onCloseSearch,
                      ),
                    ],
                    elevation: const WidgetStatePropertyAll(0),
                    backgroundColor:
                        WidgetStatePropertyAll(colors.surfaceContainerHigh),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 14),
                    ),
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    hintStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                )
              : Row(
                  key: const ValueKey('normal_title_row'),
                  children: [
                    Text(
                      selectedTab == 0
                          ? 'Questopia'
                          : (selectedTab == 1
                              ? l10n.catalog
                              : l10n.settings),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (selectedTab == 0) ...[
                      IconButton(
                        tooltip: l10n.importGameTooltip,
                        icon: const Icon(Icons.add_rounded),
                        onPressed: onImportGame,
                      ),
                      IconButton(
                        tooltip: showFavoritesOnly
                            ? 'Show all games'
                            : 'Show favorites only',
                        icon: Icon(
                          showFavoritesOnly
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: showFavoritesOnly ? colors.error : null,
                        ),
                        onPressed: onToggleFavorites,
                      ),
                      IconButton(
                        tooltip: l10n.search,
                        icon: const Icon(Icons.search_rounded),
                        onPressed: onOpenSearch,
                      ),
                    ] else if (selectedTab == 1) ...[
                      IconButton(
                        tooltip: 'Refresh catalog',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => ref
                            .read(libraryProvider.notifier)
                            .refreshRemoteCatalog(force: true),
                      ),
                      IconButton(
                        tooltip: l10n.search,
                        icon: const Icon(Icons.search_rounded),
                        onPressed: onOpenSearch,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
