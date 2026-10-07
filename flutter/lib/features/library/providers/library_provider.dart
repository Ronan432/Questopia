import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../data/game_repository.dart';
import '../data/local_game.dart';
import '../data/remote_game.dart';

class LibraryState {
  final List<LocalGame> localGames;
  final List<RemoteGame> remoteGames;
  final bool isLoadingLocal;
  final bool isLoadingRemote;
  final String? downloadingGameId;

  const LibraryState({
    this.localGames = const [],
    this.remoteGames = const [],
    this.isLoadingLocal = false,
    this.isLoadingRemote = false,
    this.downloadingGameId,
  });

  LibraryState copyWith({
    List<LocalGame>? localGames,
    List<RemoteGame>? remoteGames,
    bool? isLoadingLocal,
    bool? isLoadingRemote,
    String? downloadingGameId,
  }) {
    return LibraryState(
      localGames: localGames ?? this.localGames,
      remoteGames: remoteGames ?? this.remoteGames,
      isLoadingLocal: isLoadingLocal ?? this.isLoadingLocal,
      isLoadingRemote: isLoadingRemote ?? this.isLoadingRemote,
      downloadingGameId: downloadingGameId,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._repository, this._customDir) : super(const LibraryState()) {
    refreshLocalGames();
    refreshRemoteCatalog();
  }

  final GameRepository _repository;
  final String _customDir;

  Future<void> refreshLocalGames() async {
    state = state.copyWith(isLoadingLocal: true);
    final games = await _repository.scanLocalGames(_customDir);
    state = state.copyWith(localGames: games, isLoadingLocal: false);
  }

  Future<void> refreshRemoteCatalog() async {
    state = state.copyWith(isLoadingRemote: true);
    final games = await _repository.fetchRemoteCatalog();
    state = state.copyWith(remoteGames: games, isLoadingRemote: false);
  }

  Future<LocalGame?> downloadGame(RemoteGame remoteGame) async {
    state = state.copyWith(downloadingGameId: remoteGame.id);
    final game = await _repository.downloadAndExtractGame(remoteGame, _customDir);
    await refreshLocalGames();
    state = state.copyWith(downloadingGameId: null);
    return game;
  }
}

final gameRepositoryProvider = Provider((ref) => GameRepository());

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  final settings = ref.watch(settingsProvider);
  return LibraryNotifier(repo, settings.gamesDirectory);
});
