import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../providers/library_provider.dart';

/// Desktop layout with left-hand NavigationRail and animated content switcher.
class LibraryDesktopView extends ConsumerWidget {
  const LibraryDesktopView({
    super.key,
    required this.selectedTab,
    required this.searchQuery,
    required this.isSearchFocused,
    required this.searchFocusNode,
    required this.onTabChanged,
    required this.onSearchChanged,
    required this.onImportGame,
    required this.child,
  });

  final int selectedTab;
  final String searchQuery;
  final bool isSearchFocused;
  final FocusNode searchFocusNode;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onImportGame;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedTab <= 2 ? selectedTab : 0,
            onDestinationSelected: (value) async {
              if (value == 3) {
                onImportGame();
                return;
              }
              onTabChanged(value);
              if (value == 1) {
                final s = ref.read(libraryProvider);
                if (!s.hasLoadedRemote && !s.isLoadingRemote) {
                  ref.read(libraryProvider.notifier).refreshRemoteCatalog();
                }
              }
            },
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: colors.surface,
            indicatorColor: colors.secondaryContainer,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: Text(l10n.home),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront_rounded),
                label: Text(l10n.catalog),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(l10n.settings),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addGame),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                if (selectedTab != 2)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(
                          isSearchFocused ? 8 : 28,
                        ),
                      ),
                      child: SearchBar(
                        focusNode: searchFocusNode,
                        elevation: const WidgetStatePropertyAll(0),
                        backgroundColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isSearchFocused ? 8 : 28,
                            ),
                          ),
                        ),
                        hintText: selectedTab == 0
                            ? l10n.search
                            : 'Search online catalog...',
                        hintStyle: WidgetStatePropertyAll(
                          TextStyle(
                            color:
                                colors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        leading:
                            Icon(Icons.search_rounded, color: colors.primary),
                        trailing: [
                          if (searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => onSearchChanged(''),
                            ),
                        ],
                        onChanged: onSearchChanged,
                      ),
                    ),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (switcherChild, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: switcherChild,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(selectedTab),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
