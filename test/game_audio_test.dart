import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/core/audio/game_audio.dart';

final class FakeBackend implements AudioBackend {
  final List<(String, String)> calls = [];
  final Map<String, double> volumes = {};

  @override
  Future<void> play(String absolutePath, double volume) async {
    calls.add(('play', absolutePath));
    volumes[absolutePath] = volume;
  }

  @override
  Future<void> pause(String absolutePath) async {
    calls.add(('pause', absolutePath));
  }

  @override
  Future<void> resume(String absolutePath) async {
    calls.add(('resume', absolutePath));
  }

  @override
  Future<void> stop(String absolutePath) async {
    calls.add(('stop', absolutePath));
  }

  @override
  Future<void> setVolume(String absolutePath, double volume) async {
    volumes[absolutePath] = volume;
  }

  @override
  Future<void> dispose(String absolutePath) async {
    calls.add(('dispose', absolutePath));
  }
}

void main() {
  late Directory gameDir;
  late File soundFile;

  setUp(() async {
    gameDir = await Directory.systemTemp.createTemp('questopia_audio');
    soundFile = File('${gameDir.path}${Platform.pathSeparator}Music.MP3');
    await soundFile.writeAsBytes(const [1, 2, 3]);
  });

  tearDown(() async {
    await gameDir.delete(recursive: true);
  });

  test('volume mapping clamps the QSP 0-100 range', () {
    expect(GameAudio.volumeToGain(0), 0.0);
    expect(GameAudio.volumeToGain(100), 1.0);
    expect(GameAudio.volumeToGain(50), 0.5);
    expect(GameAudio.volumeToGain(-5), 0.0);
    expect(GameAudio.volumeToGain(150), 1.0);
  });

  test('relative paths resolve case-insensitively', () {
    final audio = GameAudio(backend: FakeBackend());
    audio.setGameDirectory(gameDir.path);
    expect(audio.resolvePath('music.mp3'), soundFile.path);
    expect(audio.resolvePath('MUSIC.MP3'), soundFile.path);
    expect(audio.resolvePath('missing.mp3'), isNull);
    expect(audio.resolvePath(''), isNull);
  });

  test('playFile caches the entry and plays once enabled', () async {
    final backend = FakeBackend();
    final audio = GameAudio(backend: backend);
    audio.setGameDirectory(gameDir.path);

    await audio.playFile('music.mp3', 80);
    expect(backend.calls.where((c) => c.$1 == 'play'), hasLength(1));
    expect(backend.volumes[soundFile.path], 0.8);
    expect(audio.hasActiveSounds, isTrue);

    await audio.playFile('MUSIC.MP3', 60);
    expect(backend.calls.where((c) => c.$1 == 'play'), hasLength(2));
    expect(backend.volumes[soundFile.path], 0.6);
  });

  test('disabled sound suppresses playback until re-enabled', () async {
    final backend = FakeBackend();
    final audio = GameAudio(backend: backend);
    audio.setGameDirectory(gameDir.path);
    audio.setSoundEnabled(false);

    await audio.playFile('music.mp3', 80);
    expect(backend.calls.where((c) => c.$1 == 'play'), isEmpty);
    expect(audio.hasActiveSounds, isTrue);

    audio.setSoundEnabled(true);
    await audio.playFile('music.mp3', 80);
    expect(backend.calls.where((c) => c.$1 == 'play'), hasLength(1));
  });

  test('closeFile stops and disposes the player', () async {
    final backend = FakeBackend();
    final audio = GameAudio(backend: backend);
    audio.setGameDirectory(gameDir.path);

    await audio.playFile('music.mp3', 80);
    await audio.closeFile('music.mp3');
    expect(audio.hasActiveSounds, isFalse);
    expect(backend.calls.any((c) => c.$1 == 'stop'), isTrue);
    expect(backend.calls.any((c) => c.$1 == 'dispose'), isTrue);
  });

  test('pause suppresses playback, resume restores it', () async {
    final backend = FakeBackend();
    final audio = GameAudio(backend: backend);
    audio.setGameDirectory(gameDir.path);

    await audio.playFile('music.mp3', 80);
    audio.setPaused(true);
    final playsAfterPause = backend.calls.where((c) => c.$1 == 'play').length;
    await audio.playFile('music.mp3', 80);
    expect(backend.calls.where((c) => c.$1 == 'play').length, playsAfterPause);

    audio.setPaused(false);
    await audio.playFile('music.mp3', 80);
    expect(
      backend.calls.where((c) => c.$1 == 'play').length,
      playsAfterPause + 1,
    );
  });
}
