import 'dart:ffi';

import 'qsp_utf16.dart';

/// Callback indices matching the native `QSP_CALL_*` enum in `qsp.h`.
enum QspCallbackId {
  debug(0),
  isPlayingFile(1),
  playFile(2),
  closeFile(3),
  showImage(4),
  showWindow(5),
  showMenu(6),
  showMessage(7),
  refreshInt(8),
  setTimer(9),
  setInputStrText(10),
  system(11),
  openGame(12),
  openGameStatus(13),
  saveGameStatus(14),
  sleep(15),
  getMsCount(16),
  inputBox(17),
  version(18);

  const QspCallbackId(this.nativeIndex);

  final int nativeIndex;
}

sealed class QspEngineEvent {
  const QspEngineEvent();
}

final class QspShowMessageEvent extends QspEngineEvent {
  const QspShowMessageEvent(this.text);

  final String text;

  @override
  String toString() => 'QspShowMessageEvent("$text")';
}

final class QspShowImageEvent extends QspEngineEvent {
  const QspShowImageEvent(this.path);

  final String path;

  @override
  String toString() => 'QspShowImageEvent("$path")';
}

final class QspPlayFileEvent extends QspEngineEvent {
  const QspPlayFileEvent(this.path, this.volume);

  final String path;
  final int volume;

  @override
  String toString() => 'QspPlayFileEvent("$path", vol: $volume)';
}

final class QspCloseFileEvent extends QspEngineEvent {
  const QspCloseFileEvent(this.path);

  final String path;

  @override
  String toString() => 'QspCloseFileEvent("$path")';
}

final class QspSetTimerEvent extends QspEngineEvent {
  const QspSetTimerEvent(this.msecs);

  final int msecs;

  @override
  String toString() => 'QspSetTimerEvent(${msecs}ms)';
}

final class QspRefreshEvent extends QspEngineEvent {
  const QspRefreshEvent(this.isForced);

  final bool isForced;

  @override
  String toString() => 'QspRefreshEvent(isForced: $isForced)';
}

final class QspShowWindowEvent extends QspEngineEvent {
  const QspShowWindowEvent(this.windowType, this.show);

  final int windowType;
  final bool show;

  @override
  String toString() => 'QspShowWindowEvent(type: $windowType, show: $show)';
}

final class QspOpenGameStatusEvent extends QspEngineEvent {
  const QspOpenGameStatusEvent(this.path);

  final String path;

  @override
  String toString() => 'QspOpenGameStatusEvent("$path")';
}

final class QspSaveGameStatusEvent extends QspEngineEvent {
  const QspSaveGameStatusEvent(this.path);

  final String path;

  @override
  String toString() => 'QspSaveGameStatusEvent("$path")';
}

final class QspDebugEvent extends QspEngineEvent {
  const QspDebugEvent(this.text);

  final String text;

  @override
  String toString() => 'QspDebugEvent("$text")';
}

final class QspSystemEvent extends QspEngineEvent {
  const QspSystemEvent(this.command);

  final String command;

  @override
  String toString() => 'QspSystemEvent("$command")';
}

final class QspInputStrTextEvent extends QspEngineEvent {
  const QspInputStrTextEvent(this.text);

  final String text;

  @override
  String toString() => 'QspInputStrTextEvent("$text")';
}

typedef NativeStrCallback = Void Function(QSPStringStruct);
typedef NativeStrIntCallback = Void Function(QSPStringStruct, Int32);
typedef NativeIntCallback = Void Function(Int32);
typedef NativeIntBoolCallback = Void Function(Int32, Int8);
typedef NativeBoolCallback = Void Function(Int8);
typedef NativeSetCallback = Void Function(
    Int32, Pointer<NativeFunction<Int64 Function()>>);

typedef DartStrCallback = void Function(QSPStringStruct);
typedef DartStrIntCallback = void Function(QSPStringStruct, int);
typedef DartIntCallback = void Function(int);
typedef DartIntBoolCallback = void Function(int, int);
typedef DartBoolCallback = void Function(int);
typedef DartSetCallback = void Function(
    int, Pointer<NativeFunction<Int64 Function()>>);

void _onShowMessage(QSPStringStruct text) {
  final msg = QspUtf16.fromStruct(text);
  QspCallbackBridge._dispatch(QspShowMessageEvent(msg));
}

void _onShowImage(QSPStringStruct file) {
  final path = QspUtf16.fromStruct(file);
  QspCallbackBridge._dispatch(QspShowImageEvent(path));
}

void _onPlayFile(QSPStringStruct file, int volume) {
  final path = QspUtf16.fromStruct(file);
  QspCallbackBridge._dispatch(QspPlayFileEvent(path, volume));
}

void _onCloseFile(QSPStringStruct file) {
  final path = QspUtf16.fromStruct(file);
  QspCallbackBridge._dispatch(QspCloseFileEvent(path));
}

void _onDebug(QSPStringStruct text) {
  final msg = QspUtf16.fromStruct(text);
  QspCallbackBridge._dispatch(QspDebugEvent(msg));
}

void _onSystem(QSPStringStruct cmd) {
  final command = QspUtf16.fromStruct(cmd);
  QspCallbackBridge._dispatch(QspSystemEvent(command));
}

void _onSetInputStrText(QSPStringStruct text) {
  final str = QspUtf16.fromStruct(text);
  QspCallbackBridge._dispatch(QspInputStrTextEvent(str));
}

void _onOpenGame(QSPStringStruct file, int isNewGame) {
  final path = QspUtf16.fromStruct(file);
  QspCallbackBridge._dispatch(QspOpenGameStatusEvent(path));
}

void _onOpenGameStatus(QSPStringStruct file) {
  final path = QspUtf16.fromStruct(file);
  QspCallbackBridge._dispatch(QspOpenGameStatusEvent(path));
}

void _onSaveGameStatus(QSPStringStruct file) {
  final path = QspUtf16.fromStruct(file);
  QspCallbackBridge._dispatch(QspSaveGameStatusEvent(path));
}

void _onSetTimer(int msecs) {
  QspCallbackBridge._dispatch(QspSetTimerEvent(msecs));
}

void _onRefreshInt(int isForced) {
  QspCallbackBridge._dispatch(QspRefreshEvent(isForced != 0));
}

void _onShowWindow(int type, int toShow) {
  QspCallbackBridge._dispatch(QspShowWindowEvent(type, toShow != 0));
}

void _onSleep(int msecs) {
  QspCallbackBridge._dispatch(QspSetTimerEvent(msecs));
}

/// Installs one-way QSP engine callbacks and forwards them as
/// [QspEngineEvent]s.
final class QspCallbackBridge {
  QspCallbackBridge({
    required DynamicLibrary library,
    required void Function(QspEngineEvent) onEvent,
  })  : _library = library,
        _onEvent = onEvent;

  final DynamicLibrary _library;
  final void Function(QspEngineEvent) _onEvent;
  final List<NativeCallable<Function>> _callables = [];

  static void Function(QspEngineEvent)? _handler;

  static void _dispatch(QspEngineEvent event) {
    try {
      _handler?.call(event);
    } catch (_) {}
  }

  bool _installed = false;
  bool get isInstalled => _installed;

  void installOneWayCallbacks() {
    if (_installed) return;
    _handler = _onEvent;
    final setCallback = _library
        .lookupFunction<NativeSetCallback, DartSetCallback>('QSPSetCallback');

    void installStr(QspCallbackId id, DartStrCallback fn) {
      final callable = NativeCallable<NativeStrCallback>.listener(fn);
      _callables.add(callable);
      setCallback(id.nativeIndex, callable.nativeFunction.cast());
    }

    void installStrInt(QspCallbackId id, DartStrIntCallback fn) {
      final callable = NativeCallable<NativeStrIntCallback>.listener(fn);
      _callables.add(callable);
      setCallback(id.nativeIndex, callable.nativeFunction.cast());
    }

    void installInt(QspCallbackId id, DartIntCallback fn) {
      final callable = NativeCallable<NativeIntCallback>.listener(fn);
      _callables.add(callable);
      setCallback(id.nativeIndex, callable.nativeFunction.cast());
    }

    void installIntBool(QspCallbackId id, DartIntBoolCallback fn) {
      final callable = NativeCallable<NativeIntBoolCallback>.listener(fn);
      _callables.add(callable);
      setCallback(id.nativeIndex, callable.nativeFunction.cast());
    }

    installStr(QspCallbackId.showMessage, _onShowMessage);
    installStr(QspCallbackId.showImage, _onShowImage);
    installStrInt(QspCallbackId.playFile, _onPlayFile);
    installStr(QspCallbackId.closeFile, _onCloseFile);
    installStr(QspCallbackId.debug, _onDebug);
    installStr(QspCallbackId.system, _onSystem);
    installStr(QspCallbackId.setInputStrText, _onSetInputStrText);
    installStrInt(QspCallbackId.openGame, _onOpenGame);
    installStr(QspCallbackId.openGameStatus, _onOpenGameStatus);
    installStr(QspCallbackId.saveGameStatus, _onSaveGameStatus);
    installInt(QspCallbackId.setTimer, _onSetTimer);
    installInt(QspCallbackId.refreshInt, _onRefreshInt);
    installIntBool(QspCallbackId.showWindow, _onShowWindow);
    installInt(QspCallbackId.sleep, _onSleep);

    _installed = true;
  }

  void dispose() {
    for (final callable in _callables) {
      callable.close();
    }
    _callables.clear();
    _handler = null;
    _installed = false;
  }
}
