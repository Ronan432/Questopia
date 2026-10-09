import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../data/game_repository.dart';
import '../data/local_game.dart';
import '../data/remote_game.dart';

enum CatalogSortOption {
  comments('comments', 'Comments'),
  name('name', 'Name'),
  updated('updated', 'Updated'),
  created('created', 'Added'),
  likes('likes', 'Likes'),
  downloads('downloads', 'Downloads'),
  plays('plays', 'Plays');

  final String value;
  final String label;
  const CatalogSortOption(this.value, this.label);
}

class LibraryState {
  final List<LocalGame> localGames;
  final List<RemoteGame> remoteGames;
  final bool isLoadingLocal;
  final bool isLoadingRemote;
  final String? downloadingGameId;
  final double? downloadProgress;
  final String? remoteError;
  final bool hasLoadedRemote;
  final CatalogSortOption catalogSort;
  final String catalogLanguage;
  final bool catalogFeaturedOnly;
  final int currentPage;
  final int totalPages;

  const LibraryState({
    this.localGames = const [],
    this.remoteGames = const [],
    this.isLoadingLocal = false,
    this.isLoadingRemote = false,
    this.downloadingGameId,
    this.downloadProgress,
    this.remoteError,
    this.hasLoadedRemote = false,
    this.catalogSort = CatalogSortOption.comments,
    this.catalogLanguage = '',
    this.catalogFeaturedOnly = false,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  LibraryState copyWith({
    List<LocalGame>? localGames,
    List<RemoteGame>? remoteGames,
    bool? isLoadingLocal,
    bool? isLoadingRemote,
    String? downloadingGameId,
    double? downloadProgress,
    String? remoteError,
    bool? hasLoadedRemote,
    CatalogSortOption? catalogSort,
    String? catalogLanguage,
    bool? catalogFeaturedOnly,
    int? currentPage,
    int? totalPages,
    bool clearDownloading = false,
    bool clearProgress = false,
    bool clearError = false,
  }) {
    return LibraryState(
      localGames: localGames ?? this.localGames,
      remoteGames: remoteGames ?? this.remoteGames,
      isLoadingLocal: isLoadingLocal ?? this.isLoadingLocal,
      isLoadingRemote: isLoadingRemote ?? this.isLoadingRemote,
      downloadingGameId: clearDownloading
          ? null
          : (downloadingGameId ?? this.downloadingGameId),
      downloadProgress:
          clearProgress ? null : (downloadProgress ?? this.downloadProgress),
      remoteError: clearError ? null : (remoteError ?? this.remoteError),
      hasLoadedRemote: hasLoadedRemote ?? this.hasLoadedRemote,
      catalogSort: catalogSort ?? this.catalogSort,
      catalogLanguage: catalogLanguage ?? this.catalogLanguage,
      catalogFeaturedOnly: catalogFeaturedOnly ?? this.catalogFeaturedOnly,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._repository, this._customDir)
      : super(const LibraryState()) {
    debugPrint(
        '[QUESTOPIA_REFRESH] >>> LibraryNotifier INSTANTIATED ONCE (customDir: "$_customDir") <<<');
  }

  final GameRepository _repository;
  final String _customDir;
  int _generation = 0;

  Future<void> refreshLocalGames({bool force = false}) async {
    final currentGen = ++_generation;
    debugPrint(
        '[QUESTOPIA_REFRESH] [LOCAL] refreshLocalGames START (gen: $currentGen, force: $force, currentCount: ${state.localGames.length})');
    if (!mounted) {
      debugPrint('[QUESTOPIA_REFRESH] [LOCAL] aborted: notifier not mounted');
      return;
    }
    if (!force && state.localGames.isNotEmpty) {
      debugPrint(
          '[QUESTOPIA_REFRESH] [LOCAL] skipped: already has ${state.localGames.length} games and force=false');
      return;
    }
    if (state.localGames.isEmpty) {
      state = state.copyWith(isLoadingLocal: true);
    }
    try {
      final games = await _repository.scanLocalGames(_customDir);
      if (!mounted || currentGen != _generation) {
        debugPrint(
            '[QUESTOPIA_REFRESH] [LOCAL] Ignored stale scan result (gen $currentGen != $_generation)');
        return;
      }
      state = state.copyWith(localGames: games, isLoadingLocal: false);
      debugPrint(
          '[QUESTOPIA_REFRESH] [LOCAL] scanLocalGames SUCCESS: found ${games.length} games');
    } catch (e, st) {
      debugPrint('[QUESTOPIA_REFRESH] [LOCAL] scanLocalGames ERROR: $e\n$st');
      if (!mounted || currentGen != _generation) return;
      state =
          state.copyWith(localGames: state.localGames, isLoadingLocal: false);
    }
  }

  Future<void> refreshRemoteCatalog({bool force = false}) async {
    debugPrint(
        '[QUESTOPIA_REFRESH] [REMOTE] refreshRemoteCatalog START (force: $force, hasLoaded: ${state.hasLoadedRemote}, isLoading: ${state.isLoadingRemote}, page: ${state.currentPage})');
    if (!mounted) {
      debugPrint('[QUESTOPIA_REFRESH] [REMOTE] aborted: notifier not mounted');
      return;
    }
    if (state.isLoadingRemote) {
      debugPrint('[QUESTOPIA_REFRESH] [REMOTE] skipped: already in flight');
      return;
    }
    if (!force && state.hasLoadedRemote && state.remoteGames.isNotEmpty) {
      debugPrint(
          '[QUESTOPIA_REFRESH] [REMOTE] skipped: already loaded ${state.remoteGames.length} games and force=false');
      return;
    }
    state = state.copyWith(isLoadingRemote: true, clearError: true);
    try {
      final result = await _repository.fetchRemoteCatalog(
        sort: state.catalogSort.value,
        language: state.catalogLanguage,
        featured: state.catalogFeaturedOnly,
        page: state.currentPage,
      );
      if (!mounted) return;
      state = state.copyWith(
        remoteGames: result.games,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        isLoadingRemote: false,
        hasLoadedRemote: true,
        clearError: true,
      );
      debugPrint(
          '[QUESTOPIA_REFRESH] [REMOTE] fetchRemoteCatalog SUCCESS: ${result.games.length} games (page ${result.currentPage}/${result.totalPages})');
    } on RepositoryException catch (error) {
      debugPrint(
          '[QUESTOPIA_REFRESH] [REMOTE] RepositoryException: ${error.message}');
      if (!mounted) return;
      state = state.copyWith(
        isLoadingRemote: false,
        remoteError: error.message,
        hasLoadedRemote: true,
      );
    } catch (e, st) {
      debugPrint('[QUESTOPIA_REFRESH] [REMOTE] UNEXPECTED ERROR: $e\n$st');
      if (!mounted) return;
      state = state.copyWith(
        isLoadingRemote: false,
        remoteError: 'Could not reach the repository.',
        hasLoadedRemote: true,
      );
    }
  }

  Future<void> setCatalogPage(int page) async {
    if (!mounted) return;
    if (page < 1 || page > state.totalPages) return;
    state = state.copyWith(currentPage: page, hasLoadedRemote: false);
    await refreshRemoteCatalog(force: true);
  }

  Future<void> setCatalogFilter({
    CatalogSortOption? sort,
    String? language,
    bool? featuredOnly,
  }) async {
    if (!mounted) return;
    state = state.copyWith(
      catalogSort: sort,
      catalogLanguage: language,
      catalogFeaturedOnly: featuredOnly,
      currentPage: 1,
      hasLoadedRemote: false,
    );
    await refreshRemoteCatalog(force: true);
  }

  Future<LocalGame?> downloadGame(RemoteGame remoteGame) async {
    if (!mounted) return null;
    state = state.copyWith(
      downloadingGameId: remoteGame.id,
      downloadProgress: 0,
    );
    try {
      final game = await _repository.downloadAndExtractGame(
        remoteGame,
        customDir: _customDir,
        onProgress: (value) {
          if (mounted) state = state.copyWith(downloadProgress: value);
        },
      );
      if (game != null && mounted) {
        _generation++;
        final existing = state.localGames
            .where((g) => g.id != game.id && g.folderPath != game.folderPath)
            .toList();
        state = state.copyWith(
          localGames: [game, ...existing],
          clearDownloading: true,
          clearProgress: true,
        );
      } else if (mounted) {
        state = state.copyWith(clearDownloading: true, clearProgress: true);
      }
      return game;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(clearDownloading: true, clearProgress: true);
      }
      rethrow;
    }
  }

  /// Imports a game folder picked by the user into the local library.
  Future<LocalGame?> importGameFolder(String sourcePath) async {
    debugPrint(
        '[QUESTOPIA_IMPORT] [NOTIFIER] importGameFolder called with sourcePath: "$sourcePath"');
    if (!mounted) {
      debugPrint(
          '[QUESTOPIA_IMPORT] [NOTIFIER] Notifier is unmounted, aborting');
      return null;
    }
    try {
      final game = await _repository.importGameFolder(
        sourcePath,
        customDir: _customDir,
        onProgress: (value) {
          if (mounted) state = state.copyWith(downloadProgress: value);
        },
      );
      if (game != null && mounted) {
        _generation++;
        final existing = state.localGames
            .where((g) => g.id != game.id && g.folderPath != game.folderPath)
            .toList();
        state = state.copyWith(localGames: [game, ...existing]);
        debugPrint(
            '[QUESTOPIA_IMPORT] [NOTIFIER] Injected imported game into state: "${game.title}" (total games in state: ${state.localGames.length})');
      } else {
        debugPrint(
            '[QUESTOPIA_IMPORT] [NOTIFIER] Repository returned null game');
      }
      return game;
    } catch (e, st) {
      debugPrint('[QUESTOPIA_IMPORT] [NOTIFIER] ERROR during import: $e\n$st');
      rethrow;
    } finally {
      if (mounted) {
        state = state.copyWith(clearProgress: true);
      }
    }
  }

  Future<void> toggleFavorite(LocalGame game) async {
    if (!mounted) return;
    final updated = await _repository.toggleFavorite(game);
    if (!mounted) return;
    state = state.copyWith(
      localGames: [
        for (final entry in state.localGames)
          if (entry.id == updated.id && entry.folderPath == updated.folderPath)
            updated
          else
            entry,
      ],
    );
  }

  Future<void> removeGameFromLibrary(LocalGame game) async {
    if (!mounted) return;
    await _repository.hideGame(game);
    state = state.copyWith(
      localGames: state.localGames
          .where((entry) => entry.folderPath != game.folderPath)
          .toList(),
    );
  }
}

final gameRepositoryProvider = Provider((ref) => GameRepository());

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final repo = ref.read(gameRepositoryProvider);
  final gamesDir = ref.read(settingsProvider).gamesDirectory;
  return LibraryNotifier(repo, gamesDir);
});
