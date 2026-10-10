import 'dart:io';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/widgets/questopia_morph_button.dart';
import '../../../game/presentation/game_screen.dart';
import '../../../game/providers/game_engine_provider.dart';
import '../../data/local_game.dart';
import '../../providers/library_provider.dart';
import '../widgets/local_game_card.dart';

/// Local installed games view with empty placeholder and adaptive grid layout.
class LocalGamesView extends ConsumerWidget {
  const LocalGamesView({
    super.key,
    required this.games,
    required this.onImportFolder,
  });

  final List<LocalGame> games;
  final VoidCallback onImportFolder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.sports_esports_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l10n.emptyLibraryHint,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: QuestopiaMorphButton.filled(
              onPressed: onImportFolder,
              icon: const Icon(Icons.add_rounded, size: 20),
              child: Text(l10n.addGame),
            ),
          ),
        ],
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);
    final isNavBarBlur = !isDesktop && ref.watch(settingsProvider).isNavBarBlur;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        4,
        isCompact ? 12 : 20,
        isNavBarBlur ? 90 : (isCompact ? 20 : 24),
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isCompact ? 200 : 320,
        mainAxisExtent: isCompact ? 208 : 245,
        crossAxisSpacing: isCompact ? 10 : 14,
        mainAxisSpacing: isCompact ? 10 : 14,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return LocalGameCard(
          game: game,
          isCompact: isCompact,
          onPlay: () async {
            final f = File(game.gameFilePath);
            if (!await f.exists()) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.gameFileNotFound(game.gameFilePath),
                    ),
                  ),
                );
              }
              return;
            }
            ref.read(gameEngineProvider.notifier).loadGame(game);
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => GameScreen(title: game.title),
                ),
              );
            }
          },
          onRemove: () {
            ref.read(libraryProvider.notifier).removeGameFromLibrary(game);
          },
          onToggleFavorite: () {
            ref.read(libraryProvider.notifier).toggleFavorite(game);
          },
        );
      },
    );
  }
}
