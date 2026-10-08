import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Thread-safe and process-safe game registry in the app's internal storage.
class GameRegistry {
  GameRegistry._(this._file);

  final File _file;
  Future<void> _tail = Future.value();

  static Future<GameRegistry> open() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return GameRegistry._(File(p.join(dir.path, 'questopia_games.json')));
    } catch (_) {
      final dir = await getApplicationDocumentsDirectory();
      return GameRegistry._(File(p.join(dir.path, 'questopia_games.json')));
    }
  }

  Future<T> _locked<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.catchError((_) {}).then((_) async {
      try {
        completer.complete(await action());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  Future<Map<String, dynamic>> _readFull() async {
    if (!await _file.exists()) {
      return {'games': <Map<String, dynamic>>[], 'ignored': <String>[]};
    }
    try {
      final content = await _file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final games = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return {'games': games, 'ignored': <String>[]};
      }
      if (decoded is Map) {
        final rawGames = decoded['games'] as List? ?? [];
        final rawIgnored = decoded['ignored'] as List? ?? [];
        return {
          'games': rawGames
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          'ignored': rawIgnored.map((e) => e.toString()).toList(),
        };
      }
      return {'games': <Map<String, dynamic>>[], 'ignored': <String>[]};
    } catch (e) {
      debugPrint('[QUESTOPIA_REGISTRY] Read error: $e');
      return {'games': <Map<String, dynamic>>[], 'ignored': <String>[]};
    }
  }

  Future<List<Map<String, dynamic>>> readAll() => _locked(() async {
        final full = await _readFull();
        return (full['games'] as List).cast<Map<String, dynamic>>();
      });

  Future<Set<String>> readIgnored() => _locked(() async {
        final full = await _readFull();
        return (full['ignored'] as List).map((e) => e.toString()).toSet();
      });

  Future<void> upsert(Map<String, dynamic> entry) => _locked(() async {
        final full = await _readFull();
        final games = (full['games'] as List).cast<Map<String, dynamic>>();
        final ignored = (full['ignored'] as List).cast<String>();
        final id = entry['id'] ?? entry['path'] ?? entry['folderPath'];

        games.removeWhere((e) =>
            (e['id'] != null && e['id'] == id) ||
            (e['path'] != null && e['path'] == entry['path']) ||
            (e['folderPath'] != null && e['folderPath'] == entry['folderPath']));
        ignored.removeWhere((x) =>
            x == id || x == entry['path'] || x == entry['folderPath']);

        games.insert(0, entry);

        if (!await _file.parent.exists()) {
          await _file.parent.create(recursive: true);
        }
        final tmp = File('${_file.path}.tmp');
        await tmp.writeAsString(
            jsonEncode({'games': games, 'ignored': ignored}),
            flush: true);
        await tmp.rename(_file.path);
        debugPrint(
            '[QUESTOPIA_REGISTRY] Upserted entry "$id" (Total entries: ${games.length})');
      });

  Future<void> batchUpsert(List<Map<String, dynamic>> entries) =>
      _locked(() async {
        if (entries.isEmpty) return;
        final full = await _readFull();
        final games = (full['games'] as List).cast<Map<String, dynamic>>();
        final ignored = (full['ignored'] as List).cast<String>();

        for (final entry in entries) {
          final id = entry['id'] ?? entry['path'] ?? entry['folderPath'];
          games.removeWhere((e) =>
              (e['id'] != null && e['id'] == id) ||
              (e['path'] != null && e['path'] == entry['path']) ||
              (e['folderPath'] != null &&
                  e['folderPath'] == entry['folderPath']));
          ignored.removeWhere((x) =>
              x == id || x == entry['path'] || x == entry['folderPath']);
          games.add(entry);
        }

        if (!await _file.parent.exists()) {
          await _file.parent.create(recursive: true);
        }
        final tmp = File('${_file.path}.tmp');
        await tmp.writeAsString(
            jsonEncode({'games': games, 'ignored': ignored}),
            flush: true);
        await tmp.rename(_file.path);
        debugPrint(
            '[QUESTOPIA_REGISTRY] Batch upserted ${entries.length} entries (Total: ${games.length})');
      });

  Future<void> remove(String id) => _locked(() async {
        final full = await _readFull();
        final games = (full['games'] as List).cast<Map<String, dynamic>>();
        final ignored = (full['ignored'] as List).cast<String>();

        games.removeWhere((e) =>
            e['id'] == id || e['path'] == id || e['folderPath'] == id);
        if (!ignored.contains(id)) {
          ignored.add(id);
        }

        if (!await _file.parent.exists()) {
          await _file.parent.create(recursive: true);
        }
        final tmp = File('${_file.path}.tmp');
        await tmp.writeAsString(
            jsonEncode({'games': games, 'ignored': ignored}),
            flush: true);
        await tmp.rename(_file.path);
        debugPrint(
            '[QUESTOPIA_REGISTRY] Removed & ignored entry "$id" (Total entries: ${games.length})');
      });
}
