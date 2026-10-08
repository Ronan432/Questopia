import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/media/poster_menu_sheet.dart';
import '../../data/remote_game.dart';
import 'game_card_frame.dart';
import 'game_poster.dart';

class RemoteGameCard extends StatelessWidget {
  const RemoteGameCard({
    super.key,
    required this.game,
    required this.isDownloading,
    required this.progress,
    required this.onDownload,
    this.isCompact = false,
  });

  final RemoteGame game;
  final bool isDownloading;
  final double? progress;
  final VoidCallback onDownload;
  final bool isCompact;

  String get _sizeLabel {
    if (game.fileSize <= 0) return '';
    if (game.fileSize >= 1024 * 1024) {
      return '${(game.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (game.fileSize >= 1024) {
      return '${(game.fileSize / 1024).toStringAsFixed(0)} KB';
    }
    return '${game.fileSize} B';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GameCardFrame(
      contentPadding: isCompact
          ? const EdgeInsets.fromLTRB(8, 6, 8, 6)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onLongPress: game.posterUrl.isNotEmpty
          ? () => showPosterMenuSheet(
                context: context,
                imageUri: game.posterUrl,
              )
          : null,
      posterWidget: GamePoster(
        remoteUrl: game.posterUrl,
        isLocal: false,
        height: isCompact ? 90 : 120,
      ),
      titleWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              game.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 13 : 15,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (game.lang.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                game.lang.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (game.author.isNotEmpty)
                Expanded(
                  child: Text(
                    'Author: ${game.author}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (game.version.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  'v${game.version}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.outline,
                      ),
                ),
              ],
            ],
          ),
          if (_sizeLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Size: $_sizeLabel',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.outline,
                  ),
            ),
          ],
        ],
      ),
      actionsWidget: isDownloading
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 4),
                Text(
                  progress == null
                      ? l10n.downloading
                      : '${(progress! * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            )
          : Row(
              children: [
                const Spacer(),
                M3EButton.icon(
                  onPressed: onDownload,
                  icon: Icon(Icons.download_rounded,
                      size: isCompact ? 16 : 18),
                  label: Text(
                    l10n.download,
                    style: TextStyle(fontSize: isCompact ? 11.5 : 13),
                  ),
                  style: M3EButtonStyle.filled,
                  size: M3EButtonSize.sm,
                  shape: M3EButtonShape.round,
                ),
              ],
            ),
    );
  }
}
