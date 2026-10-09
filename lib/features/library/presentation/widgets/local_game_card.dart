import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/helpers/sheet_helper.dart';
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

  Future<void> _showMenuSheet(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    await showQuestopiaSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: GamePoster(
                          localPath: game.posterPath,
                          isLocal: true,
                          height: 44,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            game.author.isNotEmpty
                                ? game.author
                                : 'QSP Interactive Fiction',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedListSection(
                children: [
                  SegmentedListTile(
                    leading: Icon(
                      Icons.play_arrow_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    title: Text(
                      l10n.play,
                      style: const TextStyle(fontSize: 16),
                    ),
                    minVerticalPadding: 16,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetCtx);
                      onPlay();
                    },
                  ),
                  SegmentedListTile(
                    leading: Icon(
                      game.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: game.isFavorite ? colors.error : null,
                      size: 24,
                    ),
                    title: Text(
                      game.isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: game.isFavorite
                        ? Icon(Icons.check_circle_rounded,
                            color: colors.primary)
                        : null,
                    minVerticalPadding: 16,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetCtx);
                      onToggleFavorite();
                    },
                  ),
                  SegmentedListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.error,
                      size: 24,
                    ),
                    title: Text(
                      'Remove from library',
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.error,
                      ),
                    ),
                    minVerticalPadding: 16,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetCtx);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => M3ETheme(
                          data: M3EThemeData(
                            colorScheme:
                                QuestopiaTheme.m3eColorSchemeFrom(colors),
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
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 16),
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
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GameCardFrame(
      contentPadding: isCompact
          ? const EdgeInsets.fromLTRB(8, 6, 8, 6)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: () => _showMenuSheet(context),
      onLongPress: () => _showMenuSheet(context),
      posterWidget: GamePoster(
        localPath: game.posterPath,
        isLocal: true,
        height: isCompact ? 86 : 116,
      ),
      titleWidget: Text(
        game.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isCompact ? 13 : 14.5,
          color: colors.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitleWidget: Text(
        game.author.isNotEmpty ? game.author : 'QSP Interactive Fiction',
        style: TextStyle(
          fontSize: isCompact ? 10.5 : 11.5,
          color: colors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actionsWidget: SizedBox(
        width: double.infinity,
        child: M3EButton.icon(
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
      ),
    );
  }
}
