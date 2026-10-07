import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/native/qsp_ffi.dart';
import '../../../core/native/qsp_models.dart';
import '../../library/data/local_game.dart';

enum GameDialogType {
  none,
  message,
  input,
  menu,
  error,
  imagePreview,
  restartConfirmation,
}

class GameEngineState {
  final LocalGame? activeGame;
  final QspGameState gameState;
  final GameDialogType activeDialog;
  final String messageText;
  final String inputPrompt;
  final List<QspMenuItem> menuItems;
  final QspErrorInfo? errorInfo;
  final String previewImageUrl;
  final Map<int, Uint8List> saveSlots;
  final Uint8List? autoSaveData;
  final bool isLoading;

  const GameEngineState({
    this.activeGame,
    this.gameState = const QspGameState(),
    this.activeDialog = GameDialogType.none,
    this.messageText = '',
    this.inputPrompt = '',
    this.menuItems = const [],
    this.errorInfo,
    this.previewImageUrl = '',
    this.saveSlots = const {},
    this.autoSaveData,
    this.isLoading = false,
  });

  GameEngineState copyWith({
    LocalGame? activeGame,
    QspGameState? gameState,
    GameDialogType? activeDialog,
    String? messageText,
    String? inputPrompt,
    List<QspMenuItem>? menuItems,
    QspErrorInfo? errorInfo,
    String? previewImageUrl,
    Map<int, Uint8List>? saveSlots,
    Uint8List? autoSaveData,
    bool? isLoading,
  }) {
    return GameEngineState(
      activeGame: activeGame ?? this.activeGame,
      gameState: gameState ?? this.gameState,
      activeDialog: activeDialog ?? this.activeDialog,
      messageText: messageText ?? this.messageText,
      inputPrompt: inputPrompt ?? this.inputPrompt,
      menuItems: menuItems ?? this.menuItems,
      errorInfo: errorInfo ?? this.errorInfo,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      saveSlots: saveSlots ?? this.saveSlots,
      autoSaveData: autoSaveData ?? this.autoSaveData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GameEngineNotifier extends StateNotifier<GameEngineState> {
  GameEngineNotifier() : super(const GameEngineState());

  QspFfi? get _ffi => QspFfi.tryLoad();

  Future<bool> loadGame(LocalGame game) async {
    state = state.copyWith(isLoading: true, activeGame: game);

    final ffi = _ffi;
    if (ffi == null) {
      // Mock / fallback if native library is missing during UI test
      state = state.copyWith(
        isLoading: false,
        gameState: QspGameState(
          mainDesc: '<p>Loaded ${game.title}</p>',
          varsDesc: '',
          actions: [
            const QspAction(index: 0, name: 'Examine room', image: ''),
            const QspAction(index: 1, name: 'Open inventory', image: ''),
          ],
          objects: [
            const QspObject(index: 0, name: 'Key', image: ''),
          ],
        ),
      );
      return true;
    }

    final file = File(game.gameFilePath);
    if (!await file.exists()) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    final bytes = await file.readAsBytes();
    ffi.init();
    final loaded = ffi.loadGameData(bytes, isNew: true);
    if (!loaded) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    _refreshState();
    state = state.copyWith(isLoading: false);
    return true;
  }

  void _refreshState() {
    final ffi = _ffi;
    if (ffi == null) return;

    final mainDesc = ffi.getMainDesc();
    final varsDesc = ffi.getVarsDesc();
    final actions = ffi.getActions();
    final objects = ffi.getObjects();

    state = state.copyWith(
      gameState: QspGameState(
        mainDesc: mainDesc,
        varsDesc: varsDesc,
        actions: actions,
        objects: objects,
      ),
    );
  }

  void execAction(int index) {
    final ffi = _ffi;
    if (ffi != null) {
      ffi.executeAction(index);
      _refreshState();
    }
  }

  void selectObject(int index) {
    final ffi = _ffi;
    if (ffi != null) {
      ffi.selectObject(index);
      _refreshState();
    }
  }

  void execCode(String code) {
    final ffi = _ffi;
    if (ffi != null) {
      ffi.execString(code);
      _refreshState();
    }
  }

  void closeDialog() {
    state = state.copyWith(activeDialog: GameDialogType.none);
  }

  void saveToSlot(int slotIndex) {
    final ffi = _ffi;
    if (ffi != null) {
      final data = ffi.saveGameData();
      if (data != null) {
        final newSlots = Map<int, Uint8List>.from(state.saveSlots);
        newSlots[slotIndex] = data;
        state = state.copyWith(saveSlots: newSlots);
      }
    }
  }

  void loadFromSlot(int slotIndex) {
    final data = state.saveSlots[slotIndex];
    if (data != null) {
      final ffi = _ffi;
      if (ffi != null) {
        ffi.openSaveData(data);
        _refreshState();
      }
    }
  }

  void restartGame() {
    final ffi = _ffi;
    if (ffi != null) {
      ffi.restartGame();
      _refreshState();
    }
  }

  void overrideVariable(String varName, String value) {
    final ffi = _ffi;
    if (ffi != null) {
      ffi.execString('$varName = $value');
      _refreshState();
    }
  }
}

final gameEngineProvider =
    StateNotifierProvider<GameEngineNotifier, GameEngineState>((ref) {
  return GameEngineNotifier();
});
