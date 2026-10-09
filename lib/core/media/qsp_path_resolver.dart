import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class QspPathResolver {
  QspPathResolver(this.basePaths) {
    _startAsyncIndex();
  }

  final List<String> basePaths;
  final Map<String, String> _relMap = {};
  final Map<String, String> _basenameMap = {};
  bool _indexing = false;
  bool _indexed = false;

  void updatePreloadedIndex(Map<String, String> preloaded) {
    _relMap.addAll(preloaded);
    for (final entry in preloaded.entries) {
      final base = p.basename(entry.key).toLowerCase();
      _basenameMap.putIfAbsent(base, () => entry.value);
    }
    _indexed = true;
  }

  Future<void> _startAsyncIndex() async {
    if (_indexing || _indexed) return;
    _indexing = true;
    try {
      final validPaths = basePaths
          .where((b) => b.isNotEmpty && Directory(b).existsSync())
          .toList();
      if (validPaths.isEmpty) {
        _indexing = false;
        return;
      }

      final result = await Isolate.run(() {
        final rels = <String, String>{};
        final bases = <String, String>{};

        for (final basePath in validPaths) {
          try {
            final dir = Directory(basePath);
            if (!dir.existsSync()) continue;
            for (final entity
                in dir.listSync(recursive: true, followLinks: false)) {
              if (entity is File) {
                final rel = p
                    .relative(entity.path, from: basePath)
                    .replaceAll('\\', '/')
                    .toLowerCase();
                rels[rel] = entity.path;

                final parts = rel.split('/');
                for (var i = 1; i < parts.length; i++) {
                  final sub = parts.sublist(i).join('/');
                  rels.putIfAbsent(sub, () => entity.path);
                }

                final base = p.basename(entity.path).toLowerCase();
                bases.putIfAbsent(base, () => entity.path);
              }
            }
          } catch (_) {}
        }
        return (rels: rels, bases: bases);
      });

      _relMap.addAll(result.rels);
      _basenameMap.addAll(result.bases);
      _indexed = true;
    } catch (e) {
      debugPrint('[QspPathResolver] Error during async indexing: $e');
    } finally {
      _indexing = false;
    }
  }

  String? resolve(String raw) {
    if (raw.trim().isEmpty) return null;
    var clean = raw.trim();
    if (clean.contains('?')) clean = clean.split('?').first;
    if (clean.contains('#')) clean = clean.split('#').first;
    if (clean.startsWith('file://')) {
      try {
        clean = Uri.parse(clean).toFilePath();
      } catch (_) {}
    }
    clean = clean.replaceAll('\\', '/');
    while (clean.startsWith('/') || clean.startsWith('./')) {
      if (clean.startsWith('./')) {
        clean = clean.substring(2);
      } else {
        clean = clean.substring(1);
      }
    }

    if (p.isAbsolute(clean)) {
      if (File(clean).existsSync()) return clean;
    }

    for (final basePath in basePaths) {
      if (basePath.isEmpty) continue;
      final direct = p.join(basePath, clean.replaceAll('/', p.separator));
      if (File(direct).existsSync()) return direct;
    }

    final key = clean.toLowerCase();
    final fromRel = _relMap[key];
    if (fromRel != null && File(fromRel).existsSync()) return fromRel;

    final baseKey = p.basename(clean).toLowerCase();
    final fromBase = _basenameMap[baseKey];
    if (fromBase != null && File(fromBase).existsSync()) return fromBase;

    return null;
  }
}
