import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;

abstract interface class AudioBackend {
  Future<void> play(String absolutePath, double volume);
  Future<void> pause(String absolutePath);
  Future<void> resume(String absolutePath);
  Future<void> stop(String absolutePath);
  Future<void> setVolume(String absolutePath, double volume);
  Future<void> dispose(String absolutePath);
}

final class AudioPlayersBackend implements AudioBackend {
  final Map<String, AudioPlayer> _players = {};

  AudioPlayer _playerFor(String absolutePath) {
    return _players.putIfAbsent(absolutePath, AudioPlayer.new);
  }

  @override
  Future<void> play(String absolutePath, double volume) async {
    final player = _playerFor(absolutePath);
    await player.setVolume(volume);
    await player.play(DeviceFileSource(absolutePath));
  }

  @override
  Future<void> pause(String absolutePath) async {
    await _players[absolutePath]?.pause();
  }

  @override
  Future<void> resume(String absolutePath) async {
    await _players[absolutePath]?.resume();
  }

  @override
  Future<void> stop(String absolutePath) async {
    await _players[absolutePath]?.stop();
  }

  @override
  Future<void> setVolume(String absolutePath, double volume) async {
    await _players[absolutePath]?.setVolume(volume);
  }

  @override
  Future<void> dispose(String absolutePath) async {
    final player = _players.remove(absolutePath);
    if (player != null) await player.dispose();
  }
}

final class _SoundEntry {
  _SoundEntry({required this.path, required this.volume});

  final String path;
  int volume;
}

/// QSP game audio service mirroring the legacy `AudioPlayer` behavior.
///
/// Keeps one cached entry per sound path, resolves relative game paths
/// against the active game directory (case-insensitively), maps the QSP
/// 0-100 volume range onto the player 0.0-1.0 range, and honors the
/// `isSoundEnabled` preference. The engine callback bridge (phase 4)
/// calls [playFile] and [closeFile].
final class GameAudio {
  GameAudio({AudioBackend? backend})
      : _backend = backend ?? AudioPlayersBackend();

  final AudioBackend _backend;
  final Map<String, _SoundEntry> _sounds = {};

  String _gameDirectory = '';
  bool _soundEnabled = true;
  bool _paused = false;

  void setGameDirectory(String directory) {
    _gameDirectory = directory;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      pauseAll();
    }
  }

  /// Resolves [path] against the game directory, falling back to a
  /// case-insensitive lookup like the legacy `MediaUtil`.
  String? resolvePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    final direct = File(trimmed);
    if (direct.isAbsolute && direct.existsSync()) return direct.path;
    if (_gameDirectory.isEmpty) {
      return direct.existsSync() ? direct.path : null;
    }
    final joined = p.join(_gameDirectory, trimmed);
    final parent = Directory(p.dirname(joined));
    if (parent.existsSync()) {
      final wanted = p.basename(joined).toLowerCase();
      try {
        for (final entity in parent.listSync(followLinks: false)) {
          if (entity is File &&
              p.basename(entity.path).toLowerCase() == wanted) {
            return entity.path;
          }
        }
      } catch (_) {
        return null;
      }
    }
    if (File(joined).existsSync()) return joined;
    return null;
  }

  static double volumeToGain(int volume) => (volume.clamp(0, 100)) / 100.0;

  Future<void> playFile(String path, int volume) async {
    final resolved = resolvePath(path);
    if (resolved == null) return;
    final key = resolved.toLowerCase();
    final entry = _sounds.putIfAbsent(
      key,
      () => _SoundEntry(path: resolved, volume: volume),
    );
    entry.volume = volume;
    if (!_soundEnabled || _paused) return;
    await _backend.play(resolved, volumeToGain(volume));
  }

  Future<void> closeFile(String path) async {
    final resolved = resolvePath(path);
    final key = (resolved ?? path).toLowerCase();
    if (_sounds.remove(key) == null) return;
    if (resolved != null) {
      await _backend.stop(resolved);
      await _backend.dispose(resolved);
    }
  }

  Future<void> closeAllFiles() async {
    final entries = _sounds.values.toList();
    _sounds.clear();
    for (final entry in entries) {
      await _backend.stop(entry.path);
      await _backend.dispose(entry.path);
    }
  }

  Future<void> pauseAll() async {
    for (final entry in _sounds.values) {
      await _backend.pause(entry.path);
    }
  }

  Future<void> resumeAll() async {
    if (!_soundEnabled) return;
    for (final entry in _sounds.values) {
      await _backend.resume(entry.path);
    }
  }

  void setPaused(bool paused) {
    _paused = paused;
    if (paused) {
      pauseAll();
    } else {
      resumeAll();
    }
  }

  bool get hasActiveSounds => _sounds.isNotEmpty;
}
