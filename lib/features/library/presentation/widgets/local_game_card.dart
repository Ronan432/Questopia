import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/questopia_theme.dart';
import '../../data/local_game.dart';
import 'game_card_frame.dart';
import 'game_poster.dart';

class LocalGameCard extends StatelessWidget {
  const LocalGameCard({
    super.key,
    required this.game,
    required this.onPlay,
    required this.onRemove,
    required this.onToggleFavorite,
    this.isCompact = false,
  });

  final LocalGame game;
  final VoidCallback onPlay;
  final VoidCallback onRemove;
  final VoidCallback onToggleFavorite;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GameCardFrame(
      contentPadding: isCompact
          ? const EdgeInsets.fromLTRB(8, 6, 8, 6)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: onPlay,
      onLongPress: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => M3ETheme(
            data: M3EThemeData(
              colorScheme: QuestopiaTheme.m3eColorSchemeFrom(colors),
            ),
            child: AlertDialog(
              title: const Text('Remove from library'),
              content: Text(
                'Remove "${game.title}" from your library?\n\nNote: Game files on your device will NOT be deleted.',
              ),
              actions: [
                M3EButton.icon(
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancel'),
                  style: M3EButtonStyle.outlined,
                  size: M3EButtonSize.sm,
                  shape: M3EButtonShape.round,
                ),
                const SizedBox(width: 8),
                M3EButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Remove'),
                  style: M3EButtonStyle.filled,
                  size: M3EButtonSize.sm,
                  shape: M3EButtonShape.round,
                ),
              ],
            ),
          ),
        );
        if (confirmed == true) {
          onRemove();
        }
      },
      posterWidget: GamePoster(
        localPath: game.posterPath,
        isLocal: true,
        height: isCompact ? 90 : 120,
      ),
      titleWidget: Text(
        game.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isCompact ? 13 : 15,
          color: colors.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitleWidget: Text(
        game.author.isNotEmpty ? game.author : 'QSP Interactive Fiction',
        style: TextStyle(
          fontSize: isCompact ? 10.5 : 12,
          color: colors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actionsWidget: Row(
        children: [
          M3EButton.icon(
            onPressed: onPlay,
            icon: Icon(Icons.play_arrow_rounded, size: isCompact ? 16 : 18),
            label: Text(
              l10n.play,
              style: TextStyle(fontSize: isCompact ? 11.5 : 13),
            ),
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: isCompact ? 18 : 22,
            tooltip: game.isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            icon: Icon(
              game.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: game.isFavorite ? colors.error : colors.onSurfaceVariant,
            ),
            onPressed: onToggleFavorite,
          ),
        ],
      ),
    );
  }
}
