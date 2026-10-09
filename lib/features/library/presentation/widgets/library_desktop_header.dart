import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Desktop top header containing category chips, expandable search bar, and add game action.
class LibraryDesktopHeader extends StatelessWidget {
  const LibraryDesktopHeader({
    super.key,
    required this.selectedTab,
    required this.searchQuery,
    required this.isSearchFocused,
    required this.searchFocusNode,
    required this.onTabChanged,
    required this.onSearchChanged,
    required this.onImportGame,
  });

  final int selectedTab;
  final String searchQuery;
  final bool isSearchFocused;
  final FocusNode searchFocusNode;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onImportGame;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildDesktopTabButton(0, l10n.library, Icons.sports_esports_outlined),
          const SizedBox(width: 8),
          _buildDesktopTabButton(1, l10n.catalog, Icons.storefront_outlined),
          const SizedBox(width: 8),
          _buildDesktopTabButton(2, l10n.settings, Icons.settings_outlined),
          const Spacer(),
          if (selectedTab == 0 || selectedTab == 1) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSearchFocused || searchQuery.isNotEmpty ? 280 : 180,
              height: 40,
              child: TextField(
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: selectedTab == 0 ? l10n.search : 'Search...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: colors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (selectedTab == 0)
            FilledButton.tonalIcon(
              onPressed: onImportGame,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Game'),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopTabButton(int index, String label, IconData icon) {
    final isSelected = selectedTab == index;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => onTabChanged(index),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
