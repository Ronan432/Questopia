import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/core/audio/game_audio.dart';
import 'package:questopia_re/core/native/qsp_callbacks.dart';
import 'package:questopia_re/features/game/providers/game_engine_provider.dart';

final class _NoopBackend implements AudioBackend {
  @override
  Future<void> play(String absolutePath, double volume) async {}

  @override
  Future<void> pause(String absolutePath) async {}

  @override
  Future<void> resume(String absolutePath) async {}

  @override
  Future<void> stop(String absolutePath) async {}

  @override
  Future<void> setVolume(String absolutePath, double volume) async {}

  @override
  Future<void> dispose(String absolutePath) async {}
}

void main() {
  test('callback ids match the native QSP_CALL_* enum order', () {
    expect(QspCallbackId.debug.nativeIndex, 0);
    expect(QspCallbackId.isPlayingFile.nativeIndex, 1);
    expect(QspCallbackId.playFile.nativeIndex, 2);
    expect(QspCallbackId.closeFile.nativeIndex, 3);
    expect(QspCallbackId.showImage.nativeIndex, 4);
    expect(QspCallbackId.showWindow.nativeIndex, 5);
    expect(QspCallbackId.showMenu.nativeIndex, 6);
    expect(QspCallbackId.showMessage.nativeIndex, 7);
    expect(QspCallbackId.refreshInt.nativeIndex, 8);
    expect(QspCallbackId.setTimer.nativeIndex, 9);
    expect(QspCallbackId.setInputStrText.nativeIndex, 10);
    expect(QspCallbackId.system.nativeIndex, 11);
    expect(QspCallbackId.openGame.nativeIndex, 12);
    expect(QspCallbackId.openGameStatus.nativeIndex, 13);
    expect(QspCallbackId.saveGameStatus.nativeIndex, 14);
    expect(QspCallbackId.sleep.nativeIndex, 15);
    expect(QspCallbackId.getMsCount.nativeIndex, 16);
    expect(QspCallbackId.inputBox.nativeIndex, 17);
    expect(QspCallbackId.version.nativeIndex, 18);
  });

  group('GameEngineNotifier.handleEngineEvent', () {
    late ProviderContainer container;
    late GameEngineNotifier notifier;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          gameEngineProvider.overrideWith(
            (ref) => GameEngineNotifier(audio: GameAudio(backend: _NoopBackend())),
          ),
        ],
      );
      addTearDown(container.dispose);
      notifier = container.read(gameEngineProvider.notifier);
    });

    test('show message opens the message dialog', () {
      notifier.handleEngineEvent(const QspShowMessageEvent('Hello'));
      final state = container.read(gameEngineProvider);
      expect(state.activeDialog, GameDialogType.message);
      expect(state.messageText, 'Hello');
    });

    test('show image opens the preview dialog', () {
      notifier.handleEngineEvent(const QspShowImageEvent('pic.jpg'));
      final state = container.read(gameEngineProvider);
      expect(state.activeDialog, GameDialogType.imagePreview);
      expect(state.previewImageUrl, 'pic.jpg');
    });

    test('set timer arms the interval without a native engine', () {
      notifier.handleEngineEvent(const QspSetTimerEvent(500));
      expect(
        container.read(gameEngineProvider).timerIntervalMs,
        500,
      );
      notifier.handleEngineEvent(const QspSetTimerEvent(0));
      expect(
        container.read(gameEngineProvider).timerIntervalMs,
        0,
      );
    });

    test('input prefill opens the input dialog', () {
      notifier.handleEngineEvent(const QspInputStrTextEvent('abc'));
      final state = container.read(gameEngineProvider);
      expect(state.activeDialog, GameDialogType.input);
      expect(state.inputPrefill, 'abc');
    });

    test('answer helpers store pending replies', () {
      notifier.handleEngineEvent(const QspInputStrTextEvent('x'));
      notifier.answerInput('typed');
      expect(notifier.takePendingInputAnswer(), 'typed');
      expect(notifier.takePendingInputAnswer(), isNull);
      expect(
        container.read(gameEngineProvider).activeDialog,
        GameDialogType.none,
      );
    });

    test('debug and system events are ignored safely', () {
      notifier.handleEngineEvent(const QspDebugEvent('d'));
      notifier.handleEngineEvent(const QspSystemEvent('s'));
      expect(
        container.read(gameEngineProvider).activeDialog,
        GameDialogType.none,
      );
    });
  });
}
