import 'dart:io';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../game/presentation/game_screen.dart';
import '../../../game/providers/game_engine_provider.dart';
import '../../data/local_game.dart';
import '../../data/remote_game.dart';
import '../../providers/library_provider.dart';
import '../widgets/catalog_filter_bar.dart';
import '../widgets/catalog_pagination_bar.dart';
import '../widgets/remote_game_card.dart';

/// Remote catalog games view with filter bar, grid, and pagination.
class CatalogGamesView extends ConsumerWidget {
  const CatalogGamesView({super.key, required this.games});

  final List<RemoteGame> games;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);

    return Column(
      children: [
        const CatalogFilterBar(),
        Expanded(
          child: _buildRemoteGrid(context, ref, games, state),
        ),
        if (state.totalPages > 1) const CatalogPaginationBar(),
      ],
    );
  }

  Widget _buildRemoteGrid(
    BuildContext context,
    WidgetRef ref,
    List<RemoteGame> games,
    LibraryState state,
  ) {
    if (state.isLoadingRemote && games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (state.remoteError != null && games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.remoteError!,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => ref
                  .read(libraryProvider.notifier)
                  .refreshRemoteCatalog(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No catalog items available.')),
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
    final hasPagination = state.totalPages > 1;
    final bottomGridPadding = hasPagination
        ? 8.0
        : (isNavBarBlur ? 90.0 : (isCompact ? 20.0 : 24.0));

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        4,
        isCompact ? 12 : 20,
        bottomGridPadding,
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isCompact ? 200 : 320,
        mainAxisExtent: isCompact ? 208 : 245,
        crossAxisSpacing: isCompact ? 10 : 14,
        mainAxisSpacing: isCompact ? 10 : 14,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final remoteGame = games[index];
        final isDownloading = state.downloadingGameId == remoteGame.id;
        final progress = isDownloading ? state.downloadProgress : null;

        LocalGame? matchingLocal;
        try {
          matchingLocal = state.localGames.firstWhere(
            (g) => g.id == remoteGame.id || g.title == remoteGame.displayName,
          );
        } catch (_) {}

        return RemoteGameCard(
          game: remoteGame,
          isCompact: isCompact,
          isDownloading: isDownloading,
          progress: progress,
          isInstalled: matchingLocal != null,
          onPlay: matchingLocal != null
              ? () async {
                  final f = File(matchingLocal!.gameFilePath);
                  if (!await f.exists()) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Game file not found at ${matchingLocal!.gameFilePath}. Folder may have been moved or storage permission revoked.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  ref.read(gameEngineProvider.notifier).loadGame(matchingLocal!);
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GameScreen(title: matchingLocal!.title),
                      ),
                    );
                  }
                }
              : null,
          onDownload: () => _download(context, ref, remoteGame),
        );
      },
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    RemoteGame remoteGame,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final downloaded =
          await ref.read(libraryProvider.notifier).downloadGame(remoteGame);
      if (downloaded != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Downloaded ${remoteGame.displayName}')),
        );
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
