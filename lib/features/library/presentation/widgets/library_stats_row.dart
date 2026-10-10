import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../data/local_game.dart';

/// A pair of summary tiles shown above the library grid.
///
/// The counts give the library a header instead of starting straight into the
/// poster grid, and the favorite tile doubles as a shortcut into the filtered
/// view.
class LibraryStatsRow extends StatelessWidget {
  const LibraryStatsRow({
    super.key,
    required this.games,
    required this.showFavoritesOnly,
    required this.onToggleFavoritesOnly,
  });

  final List<LocalGame> games;
  final bool showFavoritesOnly;
  final VoidCallback onToggleFavoritesOnly;

  int get _favoriteCount => games.where((game) => game.isFavorite).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.library_books_outlined,
            label: l10n.installedGames,
            value: games.length,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.favorite_rounded,
            label: l10n.favoriteGames,
            value: _favoriteCount,
            highlighted: showFavoritesOnly,
            onTap: onToggleFavoritesOnly,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: highlighted
          ? colors.secondaryContainer
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: highlighted ? colors.onSecondaryContainer : colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: highlighted
                            ? colors.onSecondaryContainer
                            : colors.onSurface,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: highlighted
                            ? colors.onSecondaryContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}