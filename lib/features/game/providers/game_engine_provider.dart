import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/audio/game_audio.dart';
import '../../../core/native/qsp_callbacks.dart';
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
  executor,
  fileLoad,
}

class GameEngineState {
  final LocalGame? activeGame;
  final QspGameState gameState;
  final GameDialogType activeDialog;
  final String messageText;
  final String inputPrompt;
  final String inputPrefill;
  final List<QspMenuItem> menuItems;
  final QspErrorInfo? errorInfo;
  final String previewImageUrl;
  final Map<int, Uint8List> saveSlots;
  final Uint8List? autoSaveData;
  final bool isLoading;
  final int timerIntervalMs;
  final String consoleOutput;

  const GameEngineState({
    this.activeGame,
    this.gameState = const QspGameState(),
    this.activeDialog = GameDialogType.none,
    this.messageText = '',
    this.inputPrompt = '',
    this.inputPrefill = '',
    this.menuItems = const [],
    this.errorInfo,
    this.previewImageUrl = '',
    this.saveSlots = const {},
    this.autoSaveData,
    this.isLoading = false,
    this.timerIntervalMs = 0,
    this.consoleOutput = '',
  });

  GameEngineState copyWith({
    LocalGame? activeGame,
    QspGameState? gameState,
    GameDialogType? activeDialog,
    String? messageText,
    String? inputPrompt,
    String? inputPrefill,
    List<QspMenuItem>? menuItems,
    QspErrorInfo? errorInfo,
    String? previewImageUrl,
    Map<int, Uint8List>? saveSlots,
    Uint8List? autoSaveData,
    bool? isLoading,
    int? timerIntervalMs,
    String? consoleOutput,
  }) {
    return GameEngineState(
      activeGame: activeGame ?? this.activeGame,
      gameState: gameState ?? this.gameState,
      activeDialog: activeDialog ?? this.activeDialog,
      messageText: messageText ?? this.messageText,
      inputPrompt: inputPrompt ?? this.inputPrompt,
      inputPrefill: inputPrefill ?? this.inputPrefill,
      menuItems: menuItems ?? this.menuItems,
      errorInfo: errorInfo ?? this.errorInfo,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      saveSlots: saveSlots ?? this.saveSlots,
      autoSaveData: autoSaveData ?? this.autoSaveData,
      isLoading: isLoading ?? this.isLoading,
      timerIntervalMs: timerIntervalMs ?? this.timerIntervalMs,
      consoleOutput: consoleOutput ?? this.consoleOutput,
    );
  }
}

class GameEngineNotifier extends StateNotifier<GameEngineState> {
  GameEngineNotifier({GameAudio? audio})
      : _audio = audio ?? GameAudio(),
        super(const GameEngineState());

  QspFfi? get _ffi => QspFfi.tryLoad();
  final GameAudio _audio;

  GameAudio get audio => _audio;

  QspCallbackBridge? _bridge;
  Timer? _timer;

  @override
  void dispose() {
    debugPrint('[GameEngineNotifier] Disposing engine notifier...');
    _timer?.cancel();
    _bridge?.dispose();
    super.dispose();
  }

  void _installCallbacks(QspFfi ffi) {
    if (!ffi.supportsCallbacks) {
      debugPrint(
          '[GameEngineNotifier] Native library does not support callbacks.');
      return;
    }
    _bridge?.dispose();
    debugPrint('[GameEngineNotifier] Installing callback bridge...');
    final bridge = QspCallbackBridge(
      library: ffi.nativeLibrary,
      onEvent: handleEngineEvent,
    );
    bridge.installOneWayCallbacks();
    _bridge = bridge;
  }

  Future<bool> loadGame(LocalGame game) async {
    debugPrint('[GameEngineNotifier] loadGame starting for "${game.title}"...');
    debugPrint('[GameEngineNotifier] Game path: "${game.gameFilePath}"');
    state = state.copyWith(isLoading: true, activeGame: game);

    await _audio.closeAllFiles();
    final gameDir = p.dirname(game.gameFilePath);
    debugPrint('[GameEngineNotifier] Setting audio directory: "$gameDir"');
    _audio.setGameDirectory(gameDir);

    final ffi = _ffi;
    if (ffi == null) {
      debugPrint(
          '[GameEngineNotifier] WARNING: Native QspFfi is null! Using mock state.');
      state = state.copyWith(
        isLoading: false,
        gameState: QspGameState(
          mainDesc:
              '<h3>Loaded ${game.title} (Mock Engine)</h3><p>Native libqsp.so/qsp.dll was not found on this system.</p>',
          varsDesc: '<p>Mock Vars Window</p>',
          actions: [
            const QspAction(index: 0, name: 'Examine room', image: ''),
            const QspAction(index: 1, name: 'Open inventory', image: ''),
          ],
          objects: [
            const QspObject(index: 0, name: 'Mock Key', image: ''),
          ],
        ),
      );
      return true;
    }

    final file = File(game.gameFilePath);
    if (!await file.exists()) {
      debugPrint(
          '[GameEngineNotifier] ERROR: Game file does not exist at "${game.gameFilePath}"!');
      state = state.copyWith(isLoading: false);
      return false;
    }

    final bytes = await file.readAsBytes();
    debugPrint('[GameEngineNotifier] Read ${bytes.length} bytes from file.');

    ffi.init();
    _installCallbacks(ffi);
    _stopTimer();

    debugPrint('[GameEngineNotifier] Calling ffi.loadGameData()...');
    final loaded = ffi.loadGameData(bytes, isNew: true);
    if (!loaded) {
      debugPrint(
          '[GameEngineNotifier] ERROR: ffi.loadGameData() returned false!');
      _checkError();
      state = state.copyWith(isLoading: false);
      return false;
    }

    debugPrint('[GameEngineNotifier] Calling ffi.restartGame()...');
    final restarted = ffi.restartGame(refresh: true);
    if (!restarted) {
      debugPrint(
          '[GameEngineNotifier] WARNING: ffi.restartGame() returned false!');
    }

    debugPrint(
        '[GameEngineNotifier] ffi.loadGameData() succeeded. Refreshing state...');
    _refreshState();
    _checkError();
    state = state.copyWith(isLoading: false);
    debugPrint(
        '[GameEngineNotifier] loadGame complete. activeGame="${state.activeGame?.title}"');
    return true;
  }

  void _refreshState() {
    final ffi = _ffi;
    if (ffi == null) return;

    final mainDesc = ffi.getMainDesc();
    final varsDesc = ffi.getVarsDesc();
    final actions = ffi.getActions();
    final objects = ffi.getObjects();

    final prev = state.gameState;
    final isMainChanged = mainDesc != prev.mainDesc;
    final isVarsChanged = varsDesc != prev.varsDesc;
    final isObjsChanged = objects.length != prev.objects.length ||
        !_areObjectListsEqual(objects, prev.objects);
    final isActionsChanged = actions.length != prev.actions.length ||
        !_areActionListsEqual(actions, prev.actions);

    if (!isMainChanged &&
        !isVarsChanged &&
        !isObjsChanged &&
        !isActionsChanged &&
        state.gameState.mainDesc == mainDesc &&
        state.gameState.varsDesc == varsDesc) {
      return;
    }

    state = state.copyWith(
      gameState: QspGameState(
        mainDesc: mainDesc,
        varsDesc: varsDesc,
        actions: actions,
        objects: objects,
        isMainDescChanged: isMainChanged,
        isVarsDescChanged: isVarsChanged,
        isObjectsChanged: isObjsChanged,
      ),
    );
  }

  bool _areActionListsEqual(List<QspAction> a, List<QspAction> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].index != b[i].index || a[i].name != b[i].name) return false;
    }
    return true;
  }

  bool _areObjectListsEqual(List<QspObject> a, List<QspObject> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].index != b[i].index || a[i].name != b[i].name) return false;
    }
    return true;
  }

  void _checkError() {
    final ffi = _ffi;
    if (ffi == null) return;
    final error = ffi.getLastError();
    if (error.errorNum != 0) {
      debugPrint('[GameEngineNotifier] Engine error detected: $error');
      state = state.copyWith(
        activeDialog: GameDialogType.error,
        errorInfo: error,
      );
    }
  }

  /// Routes one-way engine callback events into UI state, audio and timers.
  void handleEngineEvent(QspEngineEvent event) {
    switch (event) {
      case QspShowMessageEvent(text: final text):
        state = state.copyWith(
          activeDialog: GameDialogType.message,
          messageText: text,
        );
      case QspShowImageEvent(path: final path):
        final cleanPath = path.trim();
        if (cleanPath.isEmpty) {
          state = state.copyWith(
            activeDialog: GameDialogType.none,
            previewImageUrl: '',
          );
        } else {
          final resolved = _resolveGameFile(cleanPath);
          final exists = File(resolved).existsSync() ||
              resolved.toLowerCase().startsWith('http://') ||
              resolved.toLowerCase().startsWith('https://');
          if (exists) {
            state = state.copyWith(
              activeDialog: GameDialogType.imagePreview,
              previewImageUrl: resolved,
            );
          } else {
            debugPrint(
                '[GameEngineNotifier] Image not found for SHOWIMAGE: "$cleanPath" (resolved: "$resolved")');
            state = state.copyWith(
              activeDialog: GameDialogType.none,
              previewImageUrl: '',
            );
          }
        }
      case QspPlayFileEvent(path: final path, volume: final volume):
        _audio.playFile(_resolveGameFile(path), volume);
      case QspCloseFileEvent(path: final path):
        _audio.closeFile(_resolveGameFile(path));
      case QspSetTimerEvent(msecs: final msecs):
        _armTimer(msecs);
      case QspRefreshEvent():
        _refreshState();
      case QspShowWindowEvent():
        // QSP sends 4 window events per counter tick.
        // Ignore duplicate refreshes here to prevent redundant FFI queries.
        break;
      case QspOpenGameStatusEvent(path: final path):
        _openStatusFile(path);
      case QspSaveGameStatusEvent(path: final path):
        _openStatusFile(path);
      case QspInputStrTextEvent(text: final text):
        state = state.copyWith(
          activeDialog: GameDialogType.input,
          inputPrompt: '',
          inputPrefill: text,
        );
      case QspDebugEvent(text: final text):
        debugPrint('[QSP Engine Debug] $text');
      case QspSystemEvent(command: final cmd):
        debugPrint('[QSP Engine System] $cmd');
    }
  }

  String _resolveGameFile(String path) {
    final game = state.activeGame;
    if (game == null) return path;
    final gameDir = Directory(p.dirname(game.gameFilePath));

    var cleanPath = path.trim();
    if (cleanPath.isEmpty) return '';

    if (cleanPath.toLowerCase().startsWith('http://') ||
        cleanPath.toLowerCase().startsWith('https://')) {
      if (cleanPath.startsWith('https://questopia.local/')) {
        cleanPath = cleanPath.substring('https://questopia.local/'.length);
      } else {
        return cleanPath;
      }
    }

    if (cleanPath.startsWith(gameDir.path)) {
      cleanPath = cleanPath.substring(gameDir.path.length);
    }

    while (cleanPath.startsWith('/') ||
        cleanPath.startsWith('\\') ||
        cleanPath.startsWith('./')) {
      if (cleanPath.startsWith('./')) {
        cleanPath = cleanPath.substring(2);
      } else {
        cleanPath = cleanPath.substring(1);
      }
    }
    cleanPath = cleanPath.replaceAll('\\', '/');

    final file = _resolveCaseInsensitiveFile(gameDir, cleanPath);
    if (file != null && file.existsSync()) {
      return file.path;
    }
    return p.join(gameDir.path, cleanPath);
  }

  File? _resolveCaseInsensitiveFile(Directory gameDir, String relativePath) {
    final directFile = File(p.join(gameDir.path, relativePath));
    if (directFile.existsSync()) return directFile;

    final parts = p.split(relativePath);
    FileSystemEntity current = gameDir;

    for (final part in parts) {
      if (part == '.' || part.isEmpty) continue;
      if (part == '..') {
        current = current.parent;
        continue;
      }
      if (current is! Directory) return null;

      List<FileSystemEntity> children;
      try {
        children = current.listSync();
      } catch (_) {
        return null;
      }

      FileSystemEntity? match;
      for (final child in children) {
        final name = p.basename(child.path);
        if (name.toLowerCase() == part.toLowerCase()) {
          match = child;
          break;
        }
      }

      if (match == null) return null;
      current = match;
    }

    if (current is File) return current;
    return null;
  }

  Future<void> _openStatusFile(String path) async {
    final resolved = _resolveGameFile(path);
    debugPrint(
        '[GameEngineNotifier] _openStatusFile("$path") resolved to "$resolved"');
    final file = File(resolved);
    if (!await file.exists()) {
      debugPrint('[GameEngineNotifier] Status file missing at "$resolved"');
      return;
    }
    final ffi = _ffi;
    if (ffi == null) return;
    final bytes = await file.readAsBytes();
    ffi.openSaveData(bytes);
    _refreshState();
  }

  void _armTimer(int msecs) {
    debugPrint('[GameEngineNotifier] Arming game loop timer: ${msecs}ms');
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(timerIntervalMs: msecs);
    if (msecs <= 0) return;
    _timer = Timer.periodic(Duration(milliseconds: msecs), (_) {
      final ffi = _ffi;
      if (ffi == null) return;
      ffi.execCounter();
      _checkError();
    });
  }

  void _stopTimer() {
    debugPrint('[GameEngineNotifier] Stopping game loop timer.');
    _timer?.cancel();
    _timer = null;
    if (state.timerIntervalMs != 0) {
      state = state.copyWith(timerIntervalMs: 0);
    }
  }

  void execAction(int index) {
    debugPrint('[GameEngineNotifier] Executing action #$index...');
    final ffi = _ffi;
    if (ffi != null) {
      ffi.executeAction(index);
      _refreshState();
      _checkError();
    }
  }

  void selectObject(int index) {
    debugPrint('[GameEngineNotifier] Selecting object #$index...');
    final ffi = _ffi;
    if (ffi != null) {
      ffi.selectObject(index);
      _refreshState();
      _checkError();
    }
  }

  void execCode(String code) {
    debugPrint('[GameEngineNotifier] Executing QSP code: "$code"');
    final ffi = _ffi;
    if (ffi != null) {
      ffi.execString(code);
      _refreshState();
      _checkError();
    }
  }

  void runConsole(String code) {
    debugPrint('[GameEngineNotifier] Running console code: "$code"');
    final ffi = _ffi;
    final previous = state.consoleOutput;
    if (ffi != null) {
      final ok = ffi.execString(code);
      _refreshState();
      _checkError();
      state = state.copyWith(
        consoleOutput: '$previous\n> $code\n${ok ? 'OK' : 'Failed'}',
      );
    } else {
      state = state.copyWith(
        consoleOutput: '$previous\n> $code\nNo native engine loaded',
      );
    }
  }

  void answerMenu(int index) {
    debugPrint('[GameEngineNotifier] Answering menu choice #$index');
    if (state.activeDialog != GameDialogType.menu) return;
    state = state.copyWith(activeDialog: GameDialogType.none);
    _pendingMenuAnswer = index;
  }

  int? _pendingMenuAnswer;
  int? takePendingMenuAnswer() {
    final answer = _pendingMenuAnswer;
    _pendingMenuAnswer = null;
    return answer;
  }

  void answerInput(String value) {
    debugPrint('[GameEngineNotifier] Answering input prompt with "$value"');
    if (state.activeDialog != GameDialogType.input) return;
    state = state.copyWith(activeDialog: GameDialogType.none);
    _pendingInputAnswer = value;
  }

  String? _pendingInputAnswer;
  String? takePendingInputAnswer() {
    final answer = _pendingInputAnswer;
    _pendingInputAnswer = null;
    return answer;
  }

  void showInputPrompt([String prefill = '']) {
    state = state.copyWith(
      activeDialog: GameDialogType.input,
      inputPrompt: prefill,
    );
  }

  void showExecutor() {
    state = state.copyWith(activeDialog: GameDialogType.executor);
  }

  void showFileLoad() {
    state = state.copyWith(activeDialog: GameDialogType.fileLoad);
  }

  void showRestartConfirmation() {
    state = state.copyWith(activeDialog: GameDialogType.restartConfirmation);
  }

  Future<bool> importSaveFile(String path) async {
    debugPrint('[GameEngineNotifier] Importing save file from "$path"...');
    final file = File(path.trim());
    if (!await file.exists()) return false;
    final ffi = _ffi;
    if (ffi == null) return false;
    final bytes = await file.readAsBytes();
    final ok = ffi.openSaveData(bytes);
    if (ok) {
      _refreshState();
      state = state.copyWith(activeDialog: GameDialogType.none);
    }
    return ok;
  }

  void closeDialog() {
    state = state.copyWith(activeDialog: GameDialogType.none);
  }

  void saveToSlot(int slotIndex) {
    debugPrint('[GameEngineNotifier] Saving to slot #$slotIndex');
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
    debugPrint('[GameEngineNotifier] Loading from slot #$slotIndex');
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
    debugPrint('[GameEngineNotifier] Restarting active game...');
    final ffi = _ffi;
    if (ffi != null) {
      ffi.restartGame();
      _refreshState();
    }
  }

  void overrideVariable(String varName, String value) {
    debugPrint('[GameEngineNotifier] Overriding variable $varName = $value');
    final ffi = _ffi;
    if (ffi != null) {
      ffi.execString('$varName = $value');
      _refreshState();
    }
  }

  int readVarNum(String name) {
    final ffi = _ffi;
    if (ffi == null) return 0;
    return ffi.getVarNum(name);
  }

  String readVarStr(String name) {
    final ffi = _ffi;
    if (ffi == null) return '';
    return ffi.getVarStr(name);
  }

  bool execCodeBool(String code) {
    final ffi = _ffi;
    if (ffi == null) return false;
    final ok = ffi.execString(code);
    if (ok) {
      _refreshState();
      _checkError();
    }
    return ok;
  }

  Uint8List? takeSaveSnapshot() {
    final ffi = _ffi;
    if (ffi == null) return null;
    return ffi.saveGameData();
  }

  bool restoreSaveSnapshot(Uint8List data) {
    final ffi = _ffi;
    if (ffi == null) return false;
    final ok = ffi.openSaveData(data);
    if (ok) _refreshState();
    return ok;
  }

  List<QspObject> currentObjects() => state.gameState.objects;
}

final gameEngineProvider =
    StateNotifierProvider<GameEngineNotifier, GameEngineState>((ref) {
  return GameEngineNotifier();
});
