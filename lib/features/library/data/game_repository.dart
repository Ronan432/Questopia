import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import '../../../core/native/rust_runtime.dart';
import 'game_registry.dart';
import 'local_game.dart';
import 'remote_game.dart';

class RepositoryException implements Exception {
  RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WebCatalogResult {
  final List<RemoteGame> games;
  final int currentPage;
  final int totalPages;

  const WebCatalogResult({
    required this.games,
    this.currentPage = 1,
    this.totalPages = 1,
  });
}

class GameRepository {
  static const String catalogUrl = 'https://qsp.org/gamestock/gamestock2.php';
  static const int _maxGameFileDepth = 8;

  Future<Directory> getGamesDirectory([String? customDir]) async {
    if (customDir != null && customDir.trim().isNotEmpty) {
      final custom = Directory(customDir.trim());
      try {
        if (await custom.exists()) return custom;
      } catch (_) {}
    }

    if (Platform.isAndroid) {
      try {
        final downloadDir =
            Directory('/storage/emulated/0/Download/Questopia/games');
        if (await downloadDir.exists()) {
          return downloadDir;
        }
        await downloadDir.create(recursive: true);
        if (await downloadDir.exists()) {
          return downloadDir;
        }
      } catch (_) {
        // Fallback to internal documents directory if external storage is inaccessible
      }
    }

    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(baseDir.path, 'Questopia', 'games'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      return targetDir;
    } catch (_) {
      final temp = Directory.systemTemp;
      final fallback = Directory(p.join(temp.path, 'Questopia', 'games'));
      if (!fallback.existsSync()) {
        fallback.createSync(recursive: true);
      }
      return fallback;
    }
  }

  // ---------------------------------------------------------------------------
  // BFS Game File Finder & Isolate File System Helpers
  // ---------------------------------------------------------------------------

  /// Fast BFS search in isolate to find .qsp or .gam files up to maxDepth.
  static Future<String?> findGameFile(String root, {int maxDepth = 8}) {
    return Isolate.run(() async {
      final queue = Queue<MapEntry<Directory, int>>()
        ..add(MapEntry(Directory(root), 0));
      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        final subdirs = <Directory>[];
        try {
          await for (final entity in current.key.list(followLinks: false)) {
            if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (ext == '.qsp' || ext == '.gam') return entity.path;
            } else if (entity is Directory && current.value < maxDepth) {
              subdirs.add(entity);
            }
          }
        } on FileSystemException {
          continue;
        } catch (_) {
          continue;
        }
        for (final d in subdirs) {
          queue.add(MapEntry(d, current.value + 1));
        }
      }
      return null;
    });
  }

  /// Tests whether a directory is readable by dart:io on the current platform.
  static Future<bool> canReadDirectory(String path) async {
    try {
      await Directory(path)
          .list(followLinks: false)
          .first
          .timeout(const Duration(seconds: 2));
      return true;
    } on StateError {
      // Empty directory still has read permission
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Copies an entire directory in a background isolate without blocking the UI thread.
  static Future<void> copyDirectory(String from, String to) {
    return Isolate.run(() async {
      final source = Directory(from);
      await Directory(to).create(recursive: true);
      await for (final entity
          in source.list(recursive: true, followLinks: false)) {
        final relative = p.relative(entity.path, from: from);
        final target = p.join(to, relative);
        if (entity is Directory) {
          await Directory(target).create(recursive: true);
        } else if (entity is File) {
          await Directory(p.dirname(target)).create(recursive: true);
          await entity.copy(target);
        }
      }
    });
  }

  Future<File?> _findPosterAsync(Directory root) async {
    File? fallback;
    List<FileSystemEntity> children;
    try {
      children = await root.list(followLinks: false).toList();
    } catch (_) {
      return null;
    }
    for (final child in children) {
      if (child is! File) continue;
      final ext = p.extension(child.path).toLowerCase();
      if (ext != '.jpg' && ext != '.png' && ext != '.webp') continue;
      final base = p.basenameWithoutExtension(child.path).toLowerCase();
      if (base.contains('poster') || base.contains('title')) return child;
      fallback ??= child;
    }
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Local Library Scan & State Management (Atomic Game Registry)
  // ---------------------------------------------------------------------------

  /// Scans registered games from the atomic registry and any untracked local game folders.
  Future<List<LocalGame>> scanLocalGames([String? customDir]) async {
    final sw = Stopwatch()..start();
    debugPrint(
        '[QUESTOPIA_REFRESH] [SCAN] scanLocalGames started (customDir: "$customDir")');
    final registry = await GameRegistry.open();
    final entries = await registry.readAll();
    final ignored = await registry.readIgnored();
    final games = <LocalGame>[];
    final seenGameFiles = <String>{};
    final seenSignatures = <String>{};
    final deadRegistryIds = <String>[];
    final toBatchUpsert = <Map<String, dynamic>>[];

    for (final entry in entries) {
      try {
        final game = LocalGame.fromRegistry(entry);
        if (game.gameFilePath.isNotEmpty) {
          final normFile =
              p.normalize(p.absolute(game.gameFilePath)).toLowerCase();
          final normFolder =
              p.normalize(p.absolute(game.folderPath)).toLowerCase();

          if (ignored.contains(game.id) ||
              ignored.contains(game.folderPath) ||
              ignored.contains(normFolder)) {
            continue;
          }

          // Verify that game file actually exists on device. Prune dead entries.
          final file = File(game.gameFilePath);
          if (!await file.exists()) {
            deadRegistryIds.add(game.id);
            continue;
          }

          // Deduplicate by canonical gameFilePath and title+fileSize signature
          final signature = '${game.title.toLowerCase()}_${game.fileSize}';
          if (seenGameFiles.contains(normFile) ||
              seenSignatures.contains(signature)) {
            continue;
          }

          games.add(game);
          seenGameFiles.add(normFile);
          seenSignatures.add(signature);
        }
      } catch (e) {
        debugPrint('[QUESTOPIA_SCAN] Error loading registry entry: $e');
      }
    }

    // Prune dead entries in background
    for (final deadId in deadRegistryIds) {
      await registry.remove(deadId);
    }

    // Also scan root games directory for newly downloaded/dropped files
    try {
      final dir = await getGamesDirectory(customDir);
      if (await dir.exists()) {
        List<FileSystemEntity> dirEntries = [];
        try {
          dirEntries = await dir.list(followLinks: false).toList();
        } catch (_) {}

        for (final entity in dirEntries) {
          try {
            final norm = p.normalize(entity.path).toLowerCase();
            final baseName = p.basename(norm);
            if (ignored.contains(baseName) ||
                ignored.contains(entity.path) ||
                baseName.startsWith('.')) {
              continue;
            }

            if (entity is Directory) {
              final gameFile =
                  await findGameFile(entity.path, maxDepth: _maxGameFileDepth);
              if (gameFile != null) {
                final normFile =
                    p.normalize(p.absolute(gameFile)).toLowerCase();
                final folderName = p.basename(entity.path);
                final len = await File(gameFile).length();
                final signature = '${folderName.toLowerCase()}_$len';

                if (seenGameFiles.contains(normFile) ||
                    seenSignatures.contains(signature)) {
                  continue;
                }

                final poster = await _findPosterAsync(entity);
                final g = LocalGame(
                  id: folderName,
                  title: folderName,
                  folderPath: entity.path,
                  gameFilePath: gameFile,
                  posterPath: poster?.path ?? '',
                  fileSize: len,
                );
                games.add(g);
                seenGameFiles.add(normFile);
                seenSignatures.add(signature);
                toBatchUpsert.add(g.toRegistry());
                debugPrint(
                    '[QUESTOPIA_SCAN] Auto-discovered local folder game: "${g.title}"');
              }
            } else if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (ext == '.qsp' || ext == '.gam') {
                final normFile =
                    p.normalize(p.absolute(entity.path)).toLowerCase();
                final title = p.basenameWithoutExtension(entity.path);
                final len = await entity.length();
                final signature = '${title.toLowerCase()}_$len';

                if (seenGameFiles.contains(normFile) ||
                    seenSignatures.contains(signature)) {
                  continue;
                }

                final g = LocalGame(
                  id: title,
                  title: title,
                  folderPath: dir.path,
                  gameFilePath: entity.path,
                  fileSize: len,
                );
                games.add(g);
                seenGameFiles.add(normFile);
                seenSignatures.add(signature);
                toBatchUpsert.add(g.toRegistry());
                debugPrint(
                    '[QUESTOPIA_SCAN] Auto-discovered loose game file: "${g.title}"');
              }
            }
          } catch (e) {
            debugPrint(
                '[QUESTOPIA_SCAN] Error scanning root entity ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[QUESTOPIA_SCAN] Root games directory scan error: $e');
    }

    if (toBatchUpsert.isNotEmpty) {
      await registry.batchUpsert(toBatchUpsert);
    }

    games
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    sw.stop();
    debugPrint(
        '[QUESTOPIA_REFRESH] [SCAN] scanLocalGames finished: ${games.length} total games loaded (took ${sw.elapsedMilliseconds}ms)');
    return games;
  }

  /// Flips the favorite flag of [game] and updates the internal registry.
  Future<LocalGame> toggleFavorite(LocalGame game) async {
    final updated = game.copyWith(isFavorite: !game.isFavorite);
    final registry = await GameRegistry.open();
    await registry.upsert(updated.toRegistry());
    return updated;
  }

  /// Hides/removes [game] from the internal registry and adds it to the ignored set.
  Future<void> hideGame(LocalGame game) async {
    final registry = await GameRegistry.open();
    await registry.remove(game.id);
    await registry.remove(game.folderPath);
  }

  /// Permanently deletes [game] folder and removes it from registry if it is from repo.
  Future<void> deleteGame(LocalGame game) async {
    final registry = await GameRegistry.open();
    await registry.remove(game.id);
    await registry.remove(game.folderPath);
    if (game.isFromRepo) {
      try {
        final dir = Directory(game.folderPath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('[GameRepository] Error deleting game folder: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Tiered Import Pipeline (Tier A: Zero-Copy, Tier B: Isolate Copy, Tier C: Archive)
  // ---------------------------------------------------------------------------

  /// Imports a user-picked game folder or archive into the library.
  Future<LocalGame?> importGameFolder(
    String sourcePath, {
    String? customDir,
    void Function(double)? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint(
        '[QUESTOPIA_IMPORT] [START] importGameFolder called with sourcePath: "$sourcePath"');
    final cleanPath = sourcePath.trim();
    final sourceFile = File(cleanPath);
    final sourceDir = Directory(cleanPath);
    final isFile = await sourceFile.exists();
    final isDir = await sourceDir.exists();

    if (!isFile && !isDir) {
      debugPrint(
          '[QUESTOPIA_IMPORT] [ERROR] Selected path does not exist: "$cleanPath"');
      throw RepositoryException('Selected file or folder does not exist.');
    }

    final registry = await GameRegistry.open();
    final root = await getGamesDirectory(customDir);

    // 1. Directory Import
    if (isDir) {
      debugPrint(
          '[QUESTOPIA_IMPORT] [DIR] Processing Directory import: "${sourceDir.path}"');
      final archive = _findFirstArchive(sourceDir);
      if (archive != null) {
        // Tier C: Extract Archive within directory
        var target = Directory(
            p.join(root.path, p.basename(p.normalize(sourceDir.path))));
        var counter = 1;
        while (await target.exists()) {
          target = Directory(p.join(root.path,
              '${p.basename(p.normalize(sourceDir.path))} (${counter++})'));
        }
        await target.create(recursive: true);
        final ok =
            await _extractArchiveFile(archive, target, onProgress: onProgress);
        if (!ok) {
          throw RepositoryException('Failed to unpack game archive.');
        }
        final gameFile =
            await findGameFile(target.path, maxDepth: _maxGameFileDepth);
        if (gameFile == null) {
          await target.delete(recursive: true);
          throw RepositoryException(
              'No .qsp or .gam game file found in archive.');
        }
        final poster = await _findPosterAsync(target);
        final len = await File(gameFile).length();
        final game = LocalGame(
          id: p.basename(target.path),
          title: p.basename(target.path),
          folderPath: target.path,
          gameFilePath: gameFile,
          posterPath: poster?.path ?? '',
          fileSize: len,
        );
        await registry.upsert(game.toRegistry());
        await _createMarkerFiles(target);
        onProgress?.call(1);
        sw.stop();
        debugPrint(
            '[QUESTOPIA_IMPORT] [SUCCESS] Archive extracted and registered: "${game.title}" (took ${sw.elapsedMilliseconds}ms)');
        return game;
      }

      // Check Tier A vs Tier B
      final readable = await canReadDirectory(sourceDir.path);
      String workingDirPath = sourceDir.path;
      bool isCopied = false;

      if (!readable) {
        // Tier B: Permission restriction on direct read, copy to app's games directory in isolate
        debugPrint(
            '[QUESTOPIA_IMPORT] [DIR] Tier B: Directory not directly readable, copying to internal storage in isolate...');
        var target = Directory(
            p.join(root.path, p.basename(p.normalize(sourceDir.path))));
        var counter = 1;
        while (await target.exists()) {
          target = Directory(p.join(root.path,
              '${p.basename(p.normalize(sourceDir.path))} (${counter++})'));
        }
        await copyDirectory(sourceDir.path, target.path);
        workingDirPath = target.path;
        isCopied = true;
      }

      final gameFile =
          await findGameFile(workingDirPath, maxDepth: _maxGameFileDepth);
      if (gameFile == null) {
        debugPrint(
            '[QUESTOPIA_IMPORT] [ERROR] No .qsp/.gam found in "$workingDirPath"');
        throw RepositoryException(
            'No .qsp or .gam game file found in the selected folder.');
      }

      final poster = await _findPosterAsync(Directory(workingDirPath));
      final len = await File(gameFile).length();
      final game = LocalGame(
        id: p.basename(workingDirPath),
        title: p.basename(workingDirPath),
        folderPath: workingDirPath,
        gameFilePath: gameFile,
        posterPath: poster?.path ?? '',
        fileSize: len,
      );

      await registry.upsert(game.toRegistry());
      if (isCopied) {
        await _createMarkerFiles(Directory(workingDirPath));
      }
      onProgress?.call(1);
      sw.stop();
      debugPrint(
          '[QUESTOPIA_IMPORT] [SUCCESS] Folder game registered: "${game.title}" (file: ${game.gameFilePath}, zeroCopy: ${!isCopied}, took ${sw.elapsedMilliseconds}ms)');
      return game;
    }

    // 2. File Import
    if (isFile) {
      final ext = p.extension(sourceFile.path).toLowerCase();
      debugPrint(
          '[QUESTOPIA_IMPORT] [FILE] Processing File import: "${sourceFile.path}" (ext: "$ext")');
      if (ext == '.qsp' || ext == '.gam') {
        final title = p.basenameWithoutExtension(sourceFile.path);
        var target = Directory(p.join(root.path, title));
        var counter = 1;
        while (await target.exists()) {
          target = Directory(p.join(root.path, '$title (${counter++})'));
        }
        await target.create(recursive: true);
        final destGameFile =
            File(p.join(target.path, p.basename(sourceFile.path)));
        await sourceFile.copy(destGameFile.path);
        final len = await destGameFile.length();
        final game = LocalGame(
          id: p.basename(target.path),
          title: title,
          folderPath: target.path,
          gameFilePath: destGameFile.path,
          fileSize: len,
        );
        await registry.upsert(game.toRegistry());
        await _createMarkerFiles(target);
        onProgress?.call(1);
        sw.stop();
        debugPrint(
            '[QUESTOPIA_IMPORT] [SUCCESS] Loose file imported and registered: "${game.title}" (took ${sw.elapsedMilliseconds}ms)');
        return game;
      } else if (ext == '.zip' ||
          ext == '.aqsp' ||
          ext == '.rar' ||
          ext == '.7z' ||
          ext == '.tar' ||
          ext == '.gz') {
        final title = p.basenameWithoutExtension(sourceFile.path);
        var target = Directory(p.join(root.path, title));
        var counter = 1;
        while (await target.exists()) {
          target = Directory(p.join(root.path, '$title (${counter++})'));
        }
        await target.create(recursive: true);
        final ok = await _extractArchiveFile(sourceFile, target,
            onProgress: onProgress);
        if (!ok) {
          throw RepositoryException('Failed to unpack game archive.');
        }
        final gameFile =
            await findGameFile(target.path, maxDepth: _maxGameFileDepth);
        if (gameFile == null) {
          await target.delete(recursive: true);
          throw RepositoryException(
              'No .qsp or .gam game file found in archive.');
        }
        final poster = await _findPosterAsync(target);
        final len = await File(gameFile).length();
        final game = LocalGame(
          id: p.basename(target.path),
          title: title,
          folderPath: target.path,
          gameFilePath: gameFile,
          posterPath: poster?.path ?? '',
          fileSize: len,
        );
        await registry.upsert(game.toRegistry());
        await _createMarkerFiles(target);
        onProgress?.call(1);
        sw.stop();
        debugPrint(
            '[QUESTOPIA_IMPORT] [SUCCESS] Archive unpacked and registered: "${game.title}" (took ${sw.elapsedMilliseconds}ms)');
        return game;
      } else {
        throw RepositoryException('Unsupported file format ($ext).');
      }
    }

    return null;
  }

  File? _findFirstArchive(Directory dir) {
    List<FileSystemEntity> children;
    try {
      children = dir.listSync(followLinks: false);
    } catch (_) {
      return null;
    }
    for (final child in children) {
      if (child is! File) continue;
      final ext = p.extension(child.path).toLowerCase();
      if (ext == '.zip' || ext == '.aqsp') return child;
    }
    return null;
  }

  Future<void> _createMarkerFiles(Directory dir) async {
    try {
      await File(p.join(dir.path, '.nomedia')).writeAsString('');
      await File(p.join(dir.path, '.nosearch')).writeAsString('');
    } catch (_) {
      // Marker files are best-effort on restricted file systems.
    }
  }

  Future<void> _deleteQuietly(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) await entity.delete(recursive: true);
    } catch (_) {
      // Cleanup is best-effort.
    }
  }

  // ---------------------------------------------------------------------------
  // Remote catalog
  // ---------------------------------------------------------------------------

  /// Fetches the remote game catalog from the web portal, with fallback to XML.
  Future<WebCatalogResult> fetchRemoteCatalog({
    String sort = 'comments',
    String order = 'desc',
    String language = '',
    bool featured = false,
    String search = '',
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      if (sort.isNotEmpty) 'sort': sort,
      if (order.isNotEmpty) 'order': order,
      if (language.isNotEmpty) 'language': language,
      if (featured) 'featured': '1',
      if (search.isNotEmpty) 'search': search,
      if (page > 1) 'page': '$page',
    };

    final webUri = Uri.parse('https://qsp.org/games')
        .replace(queryParameters: queryParams);
    debugPrint('[GameRepository] Fetching web catalog page $page: $webUri');

    try {
      final response = await http.get(webUri, headers: {
        'Accept': 'text/html'
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final result = parseWebCatalogHtml(response.body);
        if (result.games.isNotEmpty) {
          debugPrint(
              '[GameRepository] Successfully parsed ${result.games.length} games (Page ${result.currentPage}/${result.totalPages})');
          return result;
        }
      }
    } catch (error) {
      debugPrint('[GameRepository] Web catalog fetch failed: $error');
    }

    final fallbackGames = await _fetchGamestockXmlCatalog();
    return WebCatalogResult(
        games: fallbackGames, currentPage: 1, totalPages: 1);
  }

  /// Parses the HTML response from `https://qsp.org/games`.
  WebCatalogResult parseWebCatalogHtml(String html) {
    if (html.trim().isEmpty) {
      return const WebCatalogResult(games: []);
    }

    final pageMatch = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(html);
    var currentPage = 1;
    var totalPages = 1;
    if (pageMatch != null) {
      currentPage = int.tryParse(pageMatch.group(1)!) ?? 1;
      totalPages = int.tryParse(pageMatch.group(2)!) ?? 1;
    }

    final games = <RemoteGame>[];
    final cardRegex = RegExp(
      r'<div class="bg-white dark:bg-gray-800 rounded-lg shadow-md overflow-hidden[\s\S]*?Download\s*</a>',
      caseSensitive: false,
    );

    final matches = cardRegex.allMatches(html);
    for (final m in matches) {
      final block = m.group(0)!;

      final linkMatch = RegExp(
        r'href="((?:https://qsp\.org)?/games/(\d+)[^"]*)"',
        caseSensitive: false,
      ).firstMatch(block);
      if (linkMatch == null) continue;
      var gameUrl = linkMatch.group(1)!;
      if (gameUrl.startsWith('/')) {
        gameUrl = 'https://qsp.org$gameUrl';
      }
      final gameId = linkMatch.group(2)!;

      final imgMatch = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false)
          .firstMatch(block);
      final posterUrl = _cleanPosterUrl(imgMatch?.group(1));

      final titleMatch = RegExp(
        r'<h3[\s\S]*?<a[^>]*>\s*([\s\S]*?)\s*<span[^>]*>\[(.*?)\]</span>',
        caseSensitive: false,
      ).firstMatch(block);

      var title = '';
      var version = '';
      if (titleMatch != null) {
        title = titleMatch.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        version = titleMatch.group(2)!.trim();
      } else {
        final plainTitleMatch = RegExp(
          r'<h3[\s\S]*?<a[^>]*>\s*([\s\S]*?)\s*</a>',
          caseSensitive: false,
        ).firstMatch(block);
        if (plainTitleMatch != null) {
          title = plainTitleMatch
              .group(1)!
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
        }
      }

      final langMatch = RegExp(
        r'bg-(?:blue|purple)-100[^>]*>\s*([A-Z]{2})\s*</span>',
        caseSensitive: false,
      ).firstMatch(block);
      final lang = langMatch?.group(1)?.trim() ?? '';

      final authorMatch = RegExp(
        r'Authors?:\s*([^<]+)',
        caseSensitive: false,
      ).firstMatch(block);
      final author = authorMatch?.group(1)?.trim() ?? '';

      final dlMatch = RegExp(
        r'href="((?:https://qsp\.org)?/games/\d+[^"]*/download)"',
        caseSensitive: false,
      ).firstMatch(block);
      var downloadUrl =
          dlMatch != null ? dlMatch.group(1)! : '$gameUrl/download';
      if (downloadUrl.startsWith('/')) {
        downloadUrl = 'https://qsp.org$downloadUrl';
      }

      final descMatch = RegExp(
        r'<div[^>]*class="[^"]*djot-content[^"]*"[^>]*>([\s\S]*?)</div>',
        caseSensitive: false,
      ).firstMatch(block);
      final desc = descMatch != null
          ? descMatch
              .group(1)!
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .trim()
          : '';

      if (title.isNotEmpty) {
        games.add(RemoteGame(
          id: gameId,
          title: title,
          author: author,
          version: version,
          lang: lang,
          icon: posterUrl,
          fileUrl: downloadUrl,
          descUrl: gameUrl,
          descriptionText: desc,
        ));
      }
    }

    return WebCatalogResult(
      games: games,
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }

  static String _cleanPosterUrl(String? rawUrl) {
    if (rawUrl == null) return '';
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty ||
        trimmed.contains('com_sobi2') ||
        trimmed.contains('default-game-cover')) {
      return '';
    }
    if (trimmed.startsWith('/')) {
      return 'https://qsp.org$trimmed';
    }
    return trimmed;
  }

  Future<List<RemoteGame>> _fetchGamestockXmlCatalog() async {
    String xmlPayload;
    try {
      final response = await http
          .get(Uri.parse(catalogUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw RepositoryException(
            'Repository responded with HTTP ${response.statusCode}.');
      }
      xmlPayload = response.body;
      await _cacheCatalog(xmlPayload);
    } catch (error) {
      final cached = await _readCachedCatalog();
      if (cached == null) {
        if (error is RepositoryException) rethrow;
        throw RepositoryException('Could not reach the repository.');
      }
      xmlPayload = cached;
    }

    final games = parseCatalogXml(xmlPayload);
    if (games.isEmpty) {
      throw RepositoryException('Repository returned no games.');
    }
    return games;
  }

  /// Parses the `gamestock` XML payload, preferring the Rust fast parser.
  List<RemoteGame> parseCatalogXml(String xmlPayload) {
    if (xmlPayload.trim().isEmpty) return const [];

    final rust = RustRuntime.tryLoad();
    if (rust != null) {
      try {
        final jsonResult = rust.parseRepositoryXml(xmlPayload);
        if (jsonResult != null && jsonResult.isNotEmpty) {
          final decoded = jsonDecode(jsonResult);
          if (decoded is Map<String, dynamic> && decoded['games'] is List) {
            final games = (decoded['games'] as List)
                .whereType<Map<String, dynamic>>()
                .map(RemoteGame.fromJson)
                .where(
                    (game) => game.title.isNotEmpty && game.fileUrl.isNotEmpty)
                .toList();
            if (games.isNotEmpty) return games;
          }
        }
      } catch (_) {
        // Fall through to the Dart parser.
      }
    }

    return _parseCatalogXmlDart(xmlPayload);
  }

  List<RemoteGame> _parseCatalogXmlDart(String xmlPayload) {
    final games = <RemoteGame>[];
    try {
      final document = XmlDocument.parse(xmlPayload);
      final nodes = document.findAllElements('game');
      var fallbackId = 1;
      for (final node in nodes) {
        String tag(String name) =>
            node.getElement(name)?.innerText.trim() ?? '';

        final title = tag('title');
        if (title.isEmpty) continue;

        final idText = tag('id');
        final id = int.tryParse(idText)?.toString() ??
            (idText.isNotEmpty ? idText : '${fallbackId++}');

        final rawIcon = tag('icon').isNotEmpty ? tag('icon') : tag('image');

        games.add(RemoteGame(
          id: id,
          title: title,
          author: tag('author'),
          portedBy: tag('ported_by'),
          version: tag('version'),
          lang: tag('lang'),
          player: tag('player'),
          icon: _cleanPosterUrl(rawIcon),
          fileUrl: tag('file_url'),
          fileSize: int.tryParse(tag('file_size')) ?? 0,
          fileExt: tag('file_ext'),
          descUrl: tag('desc_url'),
          pubDate: tag('pub_date'),
          modDate: tag('mod_date'),
        ));
      }
    } catch (_) {
      return const [];
    }
    return games;
  }

  Future<File> _catalogCacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'remote_stock.xml'));
  }

  Future<void> _cacheCatalog(String xmlPayload) async {
    try {
      final file = await _catalogCacheFile();
      await file.writeAsString(xmlPayload);
    } catch (_) {
      // Caching is best-effort.
    }
  }

  Future<String?> _readCachedCatalog() async {
    try {
      final file = await _catalogCacheFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return content.trim().isEmpty ? null : content;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Download & unpack
  // ---------------------------------------------------------------------------

  /// Downloads a remote game archive directly using streaming HTTP and unpacks it.
  Future<LocalGame?> downloadAndExtractGame(
    RemoteGame remoteGame, {
    String? customDir,
    void Function(double)? onProgress,
  }) async {
    if (remoteGame.fileUrl.trim().isEmpty) {
      throw RepositoryException('This game has no download URL.');
    }

    final root = await getGamesDirectory(customDir);
    final folderName = remoteGame.id.isNotEmpty
        ? remoteGame.id
        : remoteGame.title.replaceAll(RegExp(r'[^\w\- ]+'), '').trim();
    final targetFolder = Directory(p.join(
        root.path,
        folderName.isEmpty
            ? 'game_${DateTime.now().millisecondsSinceEpoch}'
            : folderName));
    if (!await targetFolder.exists()) {
      await targetFolder.create(recursive: true);
    }

    final directDownloadUrl =
        await resolveDirectDownloadUrl(remoteGame.fileUrl);

    final fileName = resolveDownloadFileName(
      await _probeContentDisposition(directDownloadUrl),
      directDownloadUrl,
      remoteGame.id,
      remoteGame.fileExt,
    );

    final destinationFile = File(p.join(targetFolder.path, fileName));

    await _downloadFileDirect(
      directDownloadUrl,
      destinationFile,
      onProgress: (progress) =>
          onProgress?.call((progress * 0.85).clamp(0.0, 0.85)),
    );

    if (!await destinationFile.exists() ||
        await destinationFile.length() == 0) {
      throw RepositoryException('Download finished but the file is empty.');
    }

    final extracted = await _extractArchiveFile(
      destinationFile,
      targetFolder,
      onProgress: (value) =>
          onProgress?.call(0.85 + (value.clamp(0.0, 1.0) * 0.15)),
    );
    if (!extracted) {
      final ext = p.extension(fileName).toLowerCase();
      if (ext != '.qsp' && ext != '.gam') {
        await _deleteQuietly(destinationFile);
        throw RepositoryException(
            'Unsupported archive format: ${p.extension(fileName)}');
      }
    }

    // Only delete archive file if it was a compressed archive (.zip, .rar, .aqsp, .7z)
    final archiveExt = p.extension(destinationFile.path).toLowerCase();
    if (archiveExt != '.qsp' && archiveExt != '.gam') {
      await _deleteQuietly(destinationFile);
    }

    // Download and cache remote poster image if local folder doesn't have a poster image
    if (await _findPosterAsync(targetFolder) == null &&
        remoteGame.posterUrl.isNotEmpty) {
      try {
        final imgRes =
            await http.get(Uri.parse(remoteGame.posterUrl), headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://qsp.org/',
        }).timeout(const Duration(seconds: 10));
        if (imgRes.statusCode == 200 && imgRes.bodyBytes.isNotEmpty) {
          final ext = p.extension(remoteGame.posterUrl).toLowerCase();
          final targetPosterName =
              (ext == '.png' || ext == '.webp') ? 'poster$ext' : 'poster.jpg';
          final cachedPoster =
              File(p.join(targetFolder.path, targetPosterName));
          await cachedPoster.writeAsBytes(imgRes.bodyBytes);
        }
      } catch (_) {}
    }

    final gameFile =
        await findGameFile(targetFolder.path, maxDepth: _maxGameFileDepth);
    if (gameFile == null) {
      throw RepositoryException(
          'Download finished but no game file was found.');
    }

    final poster = await _findPosterAsync(targetFolder);
    final fileSize = await File(gameFile).length();

    final game = LocalGame(
      id: remoteGame.id,
      title: remoteGame.title,
      author: remoteGame.author,
      version: remoteGame.version,
      folderPath: targetFolder.path,
      gameFilePath: gameFile,
      posterPath: poster?.path ?? '',
      fileSize: fileSize,
      isFromRepo: true,
    );

    final registry = await GameRegistry.open();
    await registry.upsert(game.toRegistry());
    await _createMarkerFiles(targetFolder);

    onProgress?.call(1.0);
    return game;
  }

  /// Legacy compatibility helper for writing metadata.
  Future<void> writeGameInfo(
    Directory folder, {
    required String id,
    required String title,
    String author = '',
    String version = '',
    String fileUrl = '',
    int fileSize = 0,
    String fileExt = '',
    String descUrl = '',
    String gameFilePath = '',
    String posterPath = '',
    bool isFavorite = false,
    bool isHidden = false,
  }) async {
    try {
      final infoFile = File(p.join(folder.path, '.gameInfo'));
      const encoder = JsonEncoder.withIndent('  ');
      await infoFile.writeAsString(encoder.convert({
        'id': id,
        'listId': 0,
        'author': author,
        'version': version,
        'title': title,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'fileExt': fileExt,
        'descUrl': descUrl,
        'gameFilePath': gameFilePath,
        'posterPath': posterPath,
        'isFavorite': isFavorite,
        'isHidden': isHidden,
      }));
    } catch (_) {}
  }

  Future<void> _downloadFileDirect(
    String url,
    File destinationFile, {
    void Function(double)? onProgress,
  }) async {
    final client = http.Client();
    try {
      var currentUrl = url;
      var redirects = 0;
      http.StreamedResponse? finalResponse;

      while (redirects < 6) {
        final uri = Uri.tryParse(currentUrl);
        if (uri == null) {
          throw RepositoryException('Invalid download URI: $currentUrl');
        }

        final request = http.Request('GET', uri)
          ..headers['User-Agent'] =
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          ..headers['Referer'] = 'https://qsp.org/';

        final response =
            await client.send(request).timeout(const Duration(seconds: 45));

        if (response.isRedirect && response.headers.containsKey('location')) {
          var redirectUrl = response.headers['location']!.trim();
          if (redirectUrl.startsWith('/')) {
            redirectUrl = '${uri.scheme}://${uri.host}$redirectUrl';
          }
          currentUrl = redirectUrl;
          redirects++;
          continue;
        }

        finalResponse = response;
        break;
      }

      if (finalResponse == null || finalResponse.statusCode != 200) {
        throw RepositoryException(
            'Server returned HTTP ${finalResponse?.statusCode ?? 500}');
      }

      final totalBytes = finalResponse.contentLength ?? 0;
      var receivedBytes = 0;

      final sink = destinationFile.openWrite();
      await finalResponse.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
        }
      }).asFuture();

      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Best-effort `HEAD` probe for the server `Content-Disposition` header
  /// so RFC 5987 file names survive the transfer.
  Future<String?> _probeContentDisposition(String fileUrl) async {
    try {
      final response = await http.head(Uri.parse(fileUrl), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://qsp.org/',
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return response.headers['content-disposition'];
      }
    } catch (_) {
      // Fall back to URL-based naming.
    }
    return null;
  }

  /// Resolves the on-disk file name for a download, honouring the RFC 5987
  /// `filename*` form of `Content-Disposition` first.
  String resolveDownloadFileName(
    String? contentDisposition,
    String fileUrl,
    String gameId,
    String fileExt,
  ) {
    String? fileName;
    if (contentDisposition != null && contentDisposition.trim().isNotEmpty) {
      for (final rawPart in contentDisposition.split(';')) {
        final part = rawPart.trim();
        final lower = part.toLowerCase();
        if (lower.startsWith('filename*=')) {
          var value = part.substring('filename*='.length).trim();
          if (value.toLowerCase().startsWith("utf-8''")) {
            value = value.substring(7);
          }
          value = value.replaceAll('"', '');
          try {
            fileName = Uri.decodeFull(value);
          } catch (_) {
            fileName = value;
          }
          break;
        } else if (lower.startsWith('filename=')) {
          fileName =
              part.substring('filename='.length).replaceAll('"', '').trim();
        }
      }
    }

    if (fileName == null || fileName.isEmpty || fileName == 'downloadfile') {
      final urlName = p.basename(Uri.tryParse(fileUrl)?.path ?? '');
      if (_downloadableExtensions
          .contains(p.extension(urlName).replaceFirst('.', '').toLowerCase())) {
        fileName = urlName;
      }
    }

    if (fileName == null || fileName.isEmpty || fileName == 'downloadfile') {
      final ext = fileExt.isNotEmpty ? fileExt : 'zip';
      fileName = gameId.isNotEmpty ? '$gameId.$ext' : 'game.$ext';
    }

    // Drop any directory components a hostile header could smuggle in.
    fileName = fileName.replaceAll('\\', '/');
    if (fileName.contains('/')) {
      fileName = fileName.split('/').last;
    }
    fileName = fileName.replaceAll(RegExp(r'[:*?"<>|]'), '_').trim();
    if (fileName.isEmpty || fileName == '.' || fileName == '..') {
      fileName = 'game.zip';
    }
    return fileName;
  }

  /// Resolves direct file URLs by following HTTP 301/302 redirects and parsing
  /// HTML redirect meta refresh tags or download anchor links when given an
  /// intermediary endpoint (such as `qsp.org/games/<id>/download`).
  Future<String> resolveDirectDownloadUrl(String rawUrl) async {
    var url = rawUrl.trim();
    if (url.isEmpty) return url;
    if (url.startsWith('/')) {
      url = 'https://qsp.org$url';
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      final client = http.Client();
      var currentUrl = url;
      var redirects = 0;

      while (redirects < 5) {
        final uri = Uri.tryParse(currentUrl);
        if (uri == null) break;

        final request = http.Request('GET', uri)
          ..followRedirects = false
          ..headers['User-Agent'] =
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

        final streamedResponse =
            await client.send(request).timeout(const Duration(seconds: 10));

        if (streamedResponse.isRedirect &&
            streamedResponse.headers.containsKey('location')) {
          var location = streamedResponse.headers['location']!.trim();
          if (location.startsWith('/')) {
            location = '${uri.scheme}://${uri.host}$location';
          }
          currentUrl = location;
          redirects++;
          continue;
        }

        if (streamedResponse.statusCode == 200) {
          final contentType =
              streamedResponse.headers['content-type']?.toLowerCase() ?? '';
          if (contentType.contains('text/html')) {
            final body = await streamedResponse.stream.bytesToString();
            // Meta refresh redirect tag
            final metaMatch = RegExp(
                    r'''content=["'].*?url=['"]?([^'"\s>]+)['"]?''',
                    caseSensitive: false)
                .firstMatch(body);
            if (metaMatch != null) {
              var metaUrl = metaMatch.group(1)!.trim();
              if (metaUrl.startsWith('/')) {
                metaUrl = '${uri.scheme}://${uri.host}$metaUrl';
              }
              if (metaUrl.isNotEmpty && metaUrl != currentUrl) {
                currentUrl = metaUrl;
                redirects++;
                continue;
              }
            }
            // Direct downloadable extension link check
            final hrefMatch = RegExp(
                    r'''href=['"]([^'"]+\.(?:qsp|zip|rar|gam|aqsp|7z))['"]''',
                    caseSensitive: false)
                .firstMatch(body);
            if (hrefMatch != null) {
              var hrefUrl = hrefMatch.group(1)!.trim();
              if (hrefUrl.startsWith('/')) {
                hrefUrl = '${uri.scheme}://${uri.host}$hrefUrl';
              }
              if (hrefUrl.isNotEmpty) {
                currentUrl = hrefUrl;
              }
            }
          }
        }
        break;
      }
      client.close();
      return currentUrl;
    } catch (_) {
      return url;
    }
  }

  static const Set<String> _downloadableExtensions = {
    'zip',
    'rar',
    'aqsp',
    '7z',
    'qsp',
    'gam',
    'tar',
    'gz',
  };

  Future<bool> _extractArchiveFile(
    File archiveFile,
    Directory target, {
    void Function(double)? onProgress,
  }) async {
    if (!await archiveFile.exists()) return false;

    final ext = p.extension(archiveFile.path).toLowerCase();
    if (ext == '.qsp' || ext == '.gam') {
      return true;
    }

    await target.create(recursive: true);

    final rust = RustRuntime.tryLoad();
    if (rust != null) {
      try {
        final count = rust.extractArchive(archiveFile.path, target.path);
        if (count > 0) return true;
      } catch (_) {
        // Fall back to system or Dart extraction.
      }
    }

    final archiveFilePath = archiveFile.path;
    final targetPath = target.path;

    // On Desktop (Windows, macOS, Linux), bsdtar (tar) supports RAR, 7z, ZIP, TAR, GZ, etc.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        final result = await Process.run(
          'tar',
          ['-xf', archiveFilePath, '-C', targetPath],
        );
        if (result.exitCode == 0) {
          final entries = await target.list(followLinks: false).toList();
          if (entries.isNotEmpty) return true;
        }
      } catch (e) {
        debugPrint('[GameRepository] System tar extraction error: $e');
      }
    }

    try {
      final success = await Isolate.run(() {
        final file = File(archiveFilePath);
        final bytes = file.readAsBytesSync();
        final targetRoot = p.normalize(targetPath);

        Archive? archive;
        try {
          archive = ZipDecoder().decodeBytes(bytes);
        } catch (_) {
          try {
            archive = TarDecoder().decodeBytes(bytes);
          } catch (_) {
            archive = null;
          }
        }

        if (archive == null) return false;

        for (final entry in archive) {
          final safePath = _safeArchivePath(targetRoot, entry.name);
          if (safePath == null) continue;
          if (entry.isFile) {
            final outFile = File(safePath);
            outFile.parent.createSync(recursive: true);
            outFile.writeAsBytesSync(entry.content as List<int>);
          } else {
            Directory(safePath).createSync(recursive: true);
          }
        }
        return true;
      });
      return success;
    } catch (e) {
      debugPrint('[GameRepository] Extraction error: $e');
      return false;
    }
  }

  /// Returns a normalized absolute path inside [targetRoot] or `null` when the
  /// entry would escape it (Zip Slip).
  static String? _safeArchivePath(String targetRoot, String entryName) {
    if (entryName.trim().isEmpty) return null;
    var name = entryName.replaceAll('\\', '/');
    if (name.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(name)) {
      return null;
    }
    if (name.split('/').contains('..')) return null;
    final resolved = p.normalize(p.join(targetRoot, name));
    final rootWithSep = targetRoot.endsWith(p.separator)
        ? targetRoot
        : '$targetRoot${p.separator}';
    if (!resolved.startsWith(rootWithSep)) return null;
    return resolved;
  }
}
