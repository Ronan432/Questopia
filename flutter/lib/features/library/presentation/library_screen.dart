import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/presentation/game_screen.dart';
import '../../game/providers/game_engine_provider.dart';
import '../../settings/presentation/settings_sheet.dart';
import '../data/local_game.dart';
import '../data/remote_game.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final libraryNotifier = ref.read(libraryProvider.notifier);

    final filteredLocal = libraryState.localGames.where((game) {
      return game.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredRemote = libraryState.remoteGames.where((game) {
      return game.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Questopia'),
        actions: [
          IconButton(
            tooltip: 'Import Game',
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['qsp', 'gam', 'zip'],
              );
              if (result != null && result.files.isNotEmpty) {
                await libraryNotifier.refreshLocalGames();
              }
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => const SettingsSheet(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SearchBar(
                hintText: _selectedTab == 0 ? 'Search local games' : 'Search catalog',
                leading: const Icon(Icons.search_rounded),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? _buildLocalGrid(filteredLocal, libraryState.isLoadingLocal)
                  : _buildRemoteGrid(filteredRemote, libraryState),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (value) => setState(() => _selectedTab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Catalog',
          ),
        ],
      ),
    );
  }

  Widget _buildLocalGrid(List<LocalGame> games, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (games.isEmpty) {
      return const Center(
        child: Text('No games found in local library.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 460
                ? 2
                : 1;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 1 ? 2.6 : .92,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _LocalGameCard(
              game: game,
              onPlay: () {
                ref.read(gameEngineProvider.notifier).loadGame(game);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(title: game.title),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRemoteGrid(List<RemoteGame> games, LibraryState state) {
    if (state.isLoadingRemote) {
      return const Center(child: CircularProgressIndicator());
    }

    if (games.isEmpty) {
      return const Center(
        child: Text('No catalog items available.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 460
                ? 2
                : 1;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 1 ? 2.6 : .92,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final remoteGame = games[index];
            final isDownloading = state.downloadingGameId == remoteGame.id;

            return _RemoteGameCard(
              game: remoteGame,
              isDownloading: isDownloading,
              onDownload: () async {
                final messenger = ScaffoldMessenger.of(context);
                final downloaded = await ref
                    .read(libraryProvider.notifier)
                    .downloadGame(remoteGame);
                if (downloaded != null && mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Downloaded ${remoteGame.title}')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _LocalGameCard extends StatelessWidget {
  const _LocalGameCard({required this.game, required this.onPlay});

  final LocalGame game;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: colors.onSecondaryContainer,
                ),
              ),
              const Spacer(),
              Text(
                game.title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                game.author.isNotEmpty ? game.author : 'QSP Interactive Fiction',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteGameCard extends StatelessWidget {
  const _RemoteGameCard({
    required this.game,
    required this.isDownloading,
    required this.onDownload,
  });

  final RemoteGame game;
  final bool isDownloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: colors.tertiaryContainer,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                Icons.cloud_download_rounded,
                color: colors.onTertiaryContainer,
              ),
            ),
            const Spacer(),
            Text(
              game.title,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              game.author.isNotEmpty ? game.author : 'Online Repository',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            isDownloading
                ? const CircularProgressIndicator()
                : OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download'),
                  ),
          ],
        ),
      ),
    );
  }
}
