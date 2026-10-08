import 'dart:io';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/error/crash_reporter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/media/poster_menu_sheet.dart';
import '../../../core/theme/questopia_theme.dart';
import '../../../core/utils/path_picker_helper.dart';
import '../../../core/widgets/questopia_scaffold.dart';
import '../../game/presentation/game_screen.dart';
import '../../game/providers/game_engine_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/local_game.dart';
import '../data/remote_game.dart';
import '../providers/library_provider.dart';
import 'widgets/game_card_frame.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerCrashReport());
  }

  Future<void> _offerCrashReport() async {
    final report = await CrashReporter.takePendingReport();
    if (!mounted || report == null) return;
    final preview =
        report.length > 800 ? '${report.substring(0, 800)}...' : report;
    await showDialog<void>(
      context: context,
      builder: (ctx) => M3ETheme(
        data: M3EThemeData(
          colorScheme: QuestopiaTheme.m3eColorSchemeFrom(Theme.of(context).colorScheme),
        ),
        child: AlertDialog(
          title: const Text('Crash report'),
          content: SingleChildScrollView(child: Text(preview)),
          actions: [
            M3EButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Close'),
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.sm,
              shape: M3EButtonShape.round,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importGameFolder() async {
    final messenger = ScaffoldMessenger.of(context);
    final libraryNotifier = ref.read(libraryProvider.notifier);

    final selected = await PathPickerHelper.pickDirectory(
      context,
      title: 'Select game folder',
    );
    if (selected == null || selected.isEmpty) return;

    try {
      final game = await libraryNotifier.importGameFolder(selected);
      if (game != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Imported ${game.title}')),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final filteredLocal = libraryState.localGames.where((game) {
      return game.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredRemote = libraryState.remoteGames.where((game) {
      return game.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    final mainContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SearchBar(
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              colors.surfaceContainerHigh,
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            hintText: _selectedTab == 0
                ? l10n.search
                : 'Search online catalog...',
            hintStyle: WidgetStateProperty.all(
              TextStyle(
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            leading: Icon(Icons.search_rounded, color: colors.primary),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: _selectedTab == 0
              ? _buildLocalTab(filteredLocal, libraryState)
              : _buildRemoteTab(filteredRemote, libraryState),
        ),
      ],
    );

    return M3ETheme(
      data: M3EThemeData(
        colorScheme: QuestopiaTheme.m3eColorSchemeFrom(colors),
      ),
      child: QuestopiaScaffold(
        title: isDesktop ? '' : 'Questopia',
        actions: isDesktop
            ? null
            : [
                M3EIconButton(
                  tooltip: 'Import game folder',
                  icon: const Icon(Icons.folder_open_rounded),
                  variant: M3EIconButtonVariant.standard,
                  size: M3EIconButtonSize.sm,
                  onPressed: _importGameFolder,
                ),
                const SizedBox(width: 4),
                M3EIconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  variant: M3EIconButtonVariant.tonal,
                  size: M3EIconButtonSize.sm,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
        body: SafeArea(
          child: isDesktop
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedTab <= 2 ? _selectedTab : 0,
                      onDestinationSelected: (value) async {
                        if (value == 3) {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => M3ETheme(
                              data: M3EThemeData(
                                colorScheme: QuestopiaTheme.m3eColorSchemeFrom(colors),
                              ),
                              child: AlertDialog(
                                title: const Text('Add Game'),
                                content: const Text(
                                    'Would you like to select and import a game folder from your device?'),
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
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Import'),
                                    style: M3EButtonStyle.filled,
                                    size: M3EButtonSize.sm,
                                    shape: M3EButtonShape.round,
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (confirmed == true) {
                            await _importGameFolder();
                          }
                          return;
                        }
                        setState(() => _selectedTab = value);
                      },
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: colors.surfaceContainerLow,
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.library_books_outlined),
                          selectedIcon: const Icon(Icons.library_books),
                          label: Text(l10n.library),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.explore_outlined),
                          selectedIcon: const Icon(Icons.explore),
                          label: Text(l10n.catalog),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(l10n.settings),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Add Game'),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: _selectedTab == 2
                          ? const SettingsScreen(isInline: true)
                          : mainContent,
                    ),
                  ],
                )
              : mainContent,
        ),
        bottomNavigationBar: isDesktop
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: NavigationBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      selectedIndex: _selectedTab,
                      onDestinationSelected: (value) =>
                          setState(() => _selectedTab = value),
                      destinations: [
                        NavigationDestination(
                          icon: const Icon(Icons.library_books_outlined),
                          selectedIcon: const Icon(Icons.library_books),
                          label: l10n.library,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.explore_outlined),
                          selectedIcon: const Icon(Icons.explore),
                          label: l10n.catalog,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLocalTab(List<LocalGame> games, LibraryState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(libraryProvider.notifier).refreshLocalGames(force: true),
      child: _buildLocalGrid(games, state.isLoadingLocal),
    );
  }

  Widget _buildRemoteTab(List<RemoteGame> games, LibraryState state) {
    return Column(
      children: [
        _buildCatalogFilterBar(state),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(libraryProvider.notifier)
                .refreshRemoteCatalog(force: true),
            child: _buildRemoteGrid(games, state),
          ),
        ),
        if (state.totalPages > 1) _buildPaginationBar(state),
      ],
    );
  }

  Widget _buildPaginationBar(LibraryState state) {
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(libraryProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          M3EButton.icon(
            onPressed: state.currentPage > 1
                ? () => notifier.setCatalogPage(state.currentPage - 1)
                : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Prev'),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colors.onSurface,
            ),
          ),
          M3EButton.icon(
            onPressed: state.currentPage < state.totalPages
                ? () => notifier.setCatalogPage(state.currentPage + 1)
                : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Next'),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogFilterBar(LibraryState state) {
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(libraryProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<CatalogSortOption>(
                    value: state.catalogSort,
                    isDense: true,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    items: CatalogSortOption.values.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text(opt.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        notifier.setCatalogFilter(sort: val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          for (final lang in const ['', 'ru', 'en']) ...[
            FilterChip(
              selected: state.catalogLanguage == lang,
              label: Text(
                lang.isEmpty ? 'All Languages' : lang.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
              onSelected: (selected) {
                notifier.setCatalogFilter(language: lang);
              },
            ),
            const SizedBox(width: 6),
          ],
          FilterChip(
            selected: state.catalogFeaturedOnly,
            avatar: const Text('⭐', style: TextStyle(fontSize: 12)),
            label: const Text('Featured', style: TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            onSelected: (selected) {
              notifier.setCatalogFilter(featuredOnly: selected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocalGrid(List<LocalGame> games, bool isLoading) {
    if (isLoading && games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (games.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text('No games found in local library.'),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 245,
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
          onToggleFavorite: () {
            ref.read(libraryProvider.notifier).toggleFavorite(game);
          },
          onRemove: () {
            ref.read(libraryProvider.notifier).removeGameFromLibrary(game);
          },
        );
      },
    );
  }

  Widget _buildRemoteGrid(List<RemoteGame> games, LibraryState state) {
    if (state.isLoadingRemote && games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
              onPressed: () =>
                  ref.read(libraryProvider.notifier).refreshRemoteCatalog(force: true),
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

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 245,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final remoteGame = games[index];
        final isDownloading = state.downloadingGameId == remoteGame.id;
        final progress = isDownloading ? state.downloadProgress : null;

        return _RemoteGameCard(
          game: remoteGame,
          isDownloading: isDownloading,
          progress: progress,
          onDownload: () => _download(remoteGame),
        );
      },
    );
  }

  Future<void> _download(RemoteGame remoteGame) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final downloaded = await ref
          .read(libraryProvider.notifier)
          .downloadGame(remoteGame);
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

class _LocalGameCard extends StatelessWidget {
  const _LocalGameCard({
    required this.game,
    required this.onPlay,
    required this.onToggleFavorite,
    required this.onRemove,
  });

  final LocalGame game;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final hasPoster =
        game.posterPath.isNotEmpty && File(game.posterPath).existsSync();

    return GameCardFrame(
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
              content: Text('Remove "${game.title}" from your library?\n\nNote: Game files on your device will NOT be deleted.'),
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
      posterWidget: SizedBox(
        height: 120,
        width: double.infinity,
        child: hasPoster
            ? Image.file(
                File(game.posterPath),
                fit: BoxFit.cover,
              )
            : Container(
                color: colors.secondaryContainer,
                child: Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 40,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
      ),
      titleWidget: Text(
        game.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitleWidget: Text(
        game.author.isNotEmpty
            ? game.author
            : 'QSP Interactive Fiction',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actionsWidget: Row(
        children: [
          M3EButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(l10n.play),
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
          ),
          const Spacer(),
          IconButton(
            tooltip: game.isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            icon: Icon(
              game.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: game.isFavorite ? colors.primary : null,
            ),
            onPressed: onToggleFavorite,
          ),
        ],
      ),
    );
  }
}

class _RemoteGameCard extends StatelessWidget {
  const _RemoteGameCard({
    required this.game,
    required this.isDownloading,
    required this.progress,
    required this.onDownload,
  });

  final RemoteGame game;
  final bool isDownloading;
  final double? progress;
  final VoidCallback onDownload;

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

  Widget _buildPoster(ColorScheme colors) {
    final poster = game.posterUrl;
    if (poster.isNotEmpty) {
      debugPrint('[Poster] Primary image attempt for #${game.id} (${game.displayName}): $poster');
      return Image.network(
        poster,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) {
          debugPrint('[Poster] Primary image failed for #${game.id}: $err ($poster)');
          if (game.id.isNotEmpty && !poster.contains('cover-titled-v2.jpg')) {
            final fallbackUrl1 =
                'https://qsp.org/storage/games/${game.id}/cover-titled-v2.jpg';
            debugPrint('[Poster] Fallback 1 attempt for #${game.id}: $fallbackUrl1');
            return Image.network(
              fallbackUrl1,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx2, err2, stack2) {
                debugPrint('[Poster] Fallback 1 failed for #${game.id}: $err2 ($fallbackUrl1)');
                final fallbackUrl2 =
                    'https://qsp.org/storage/games/${game.id}/cover.jpg';
                debugPrint('[Poster] Fallback 2 attempt for #${game.id}: $fallbackUrl2');
                return Image.network(
                  fallbackUrl2,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx3, err3, stack3) {
                    debugPrint('[Poster] Fallback 2 failed for #${game.id}: $err3 ($fallbackUrl2)');
                    return _buildPlaceholder(colors);
                  },
                );
              },
            );
          }
          return _buildPlaceholder(colors);
        },
        loadingBuilder: (ctx, child, loading) {
          if (loading == null) {
            debugPrint('[Poster] Successfully rendered poster for #${game.id}');
            return child;
          }
          return Container(
            height: 120,
            width: double.infinity,
            color: colors.surfaceContainerHigh,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    debugPrint('[Poster] No primary poster URL for #${game.id} (${game.displayName})');
    return _buildPlaceholder(colors);
  }

  Widget _buildPlaceholder(ColorScheme colors) {
    return Container(
      height: 120,
      width: double.infinity,
      color: colors.tertiaryContainer,
      child: Center(
        child: Icon(
          Icons.cloud_download_rounded,
          size: 40,
          color: colors.onTertiaryContainer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: game.posterUrl.isNotEmpty
                ? () => showPosterMenuSheet(
                      context: context,
                      imageUri: game.posterUrl,
                    )
                : null,
            child: _buildPoster(colors),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          game.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (game.lang.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
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
                  const SizedBox(height: 2),
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
                  const SizedBox(height: 6),
                  if (isDownloading)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  else
                    SizedBox(
                      width: double.infinity,
                      child: M3EButton.icon(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(l10n.download),
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        shape: M3EButtonShape.round,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
