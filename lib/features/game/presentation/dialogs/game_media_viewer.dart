import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/qsp_media.dart';
import '../../../../core/media/qsp_path_resolver.dart';
import '../../providers/game_engine_provider.dart';

/// Embedded media viewer for game dialogs supporting images and media_kit videos.
class GameMediaViewer extends ConsumerWidget {
  const GameMediaViewer({
    super.key,
    required this.mediaPath,
    this.gameFolderPath,
    this.maxHeight = 260,
  });

  final String mediaPath;
  final String? gameFolderPath;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final folder = gameFolderPath ??
        ref.watch(gameEngineProvider).activeGame?.folderPath;
    final resolver = folder != null && folder.isNotEmpty
        ? QspPathResolver([folder])
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: QspMedia(
            src: mediaPath,
            resolver: resolver,
            fit: BoxFit.contain,
            autoplay: true,
            loop: true,
          ),
        ),
      ),
    );
  }
}
