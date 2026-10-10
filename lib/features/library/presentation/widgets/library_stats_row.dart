import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/helpers/dialog_helper.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/local_game.dart';
import '../../providers/library_provider.dart';

/// A pair of summary tiles shown above the library grid, with inline accordion expansion.
class LibraryStatsRow extends ConsumerStatefulWidget {
  const LibraryStatsRow({
    super.key,
    required this.games,
    required this.showFavoritesOnly,
    required this.onToggleFavoritesOnly,
  });

  final List<LocalGame> games;
  final bool showFavoritesOnly;
  final VoidCallback onToggleFavoritesOnly;

  @override
  ConsumerState<LibraryStatsRow> createState() => _LibraryStatsRowState();
}

class _LibraryStatsRowState extends ConsumerState<LibraryStatsRow> {
  bool _isExpanded = false;

  int get _favoriteCount => widget.games.where((game) => game.isFavorite).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.library_books_outlined,
                label: l10n.installedGames,
                value: widget.games.length,
                highlighted: _isExpanded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isExpanded = !_isExpanded);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.favorite_rounded,
                label: l10n.favoriteGames,
                value: _favoriteCount,
                highlighted: widget.showFavoritesOnly,
                onTap: widget.onToggleFavoritesOnly,
              ),
            ),
          ],
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Material(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_open_rounded, color: colors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.games.length} installed games in library',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.games.isNotEmpty)
                      QuestopiaMorphButton.filled(
                        isDestructive: true,
                        onPressed: () async {
                          final confirmed = await showQuestopiaDialog<bool>(
                            context: context,
                            builder: (ctx) => QuestopiaConfirmationDialog(
                              title: l10n.deleteAllGamesTitle,
                              message: l10n.deleteAllGamesMessage,
                              confirmLabel: l10n.delete,
                              cancelLabel: l10n.cancel,
                              isDestructive: true,
                              icon: Icons.delete_sweep_rounded,
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await ref.read(libraryProvider.notifier).removeAllGames();
                            if (mounted) {
                              setState(() => _isExpanded = false);
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        child: Text(l10n.deleteAll),
                      ),
                  ],
                ),
              ),
            ),
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
