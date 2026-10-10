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
import '../widgets/library_stats_row.dart';
import '../widgets/local_game_card.dart';

/// Local installed games view with empty placeholder and adaptive grid layout.
class LocalGamesView extends ConsumerWidget {
  const LocalGamesView({
    super.key,
    required this.games,
    required this.onImportFolder,
    required this.allGames,
    required this.showFavoritesOnly,
    required this.onToggleFavoritesOnly,
  });

  final List<LocalGame> games;
  final VoidCallback onImportFolder;

  /// Unfiltered library, used for the summary counters.
  final List<LocalGame> allGames;
  final bool showFavoritesOnly;
  final VoidCallback onToggleFavoritesOnly;

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

    final horizontalPadding = isCompact ? 12.0 : 20.0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            12,
          ),
          sliver: SliverToBoxAdapter(
            child: LibraryStatsRow(
              games: allGames,
              showFavoritesOnly: showFavoritesOnly,
              onToggleFavoritesOnly: onToggleFavoritesOnly,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            isNavBarBlur ? 90 : (isCompact ? 20 : 24),
          ),
          sliver: SliverGrid.builder(
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
          ),
        ),
      ],
    );
  }
}
