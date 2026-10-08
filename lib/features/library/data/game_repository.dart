import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import '../../../core/native/rust_runtime.dart';
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
  static const String catalogUrl =
      'https://qsp.org/gamestock/gamestock2.php';
  static const String gameInfoFilename = '.gameInfo';
  static const int _maxGameFileDepth = 4;

  Future<Directory> getGamesDirectory([String? customDir]) async {
    if (customDir != null && customDir.trim().isNotEmpty) {
      final custom = Directory(customDir.trim());
      if (await custom.exists()) return custom;
    }

    Directory targetDir;
    if (Platform.isAndroid) {
      targetDir = Directory('/storage/emulated/0/Download/Questopia/games');
      try {
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } catch (_) {
        final extDir = await getExternalStorageDirectory();
        final baseDir = extDir ?? await getApplicationDocumentsDirectory();
        targetDir = Directory(p.join(baseDir.path, 'Questopia', 'games'));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      }
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      targetDir = Directory(p.join(docsDir.path, 'Questopia', 'games'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
    }

    await _migrateGamesToTarget(targetDir);
    return targetDir;
  }

  Future<void> _migrateGamesToTarget(Directory targetDir) async {
    final legacyLocations = <Directory>[];

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      legacyLocations.add(Directory(p.join(docsDir.path, 'Questopia', 'games')));
    } catch (_) {}

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        legacyLocations.add(Directory(p.join(extDir.path, 'Questopia', 'games')));
      }
    } catch (_) {}

    legacyLocations.add(Directory('/storage/emulated/0/Questopia/games'));

    final targetCanonical = p.canonicalize(targetDir.path);

    for (final legacyDir in legacyLocations) {
      try {
        if (!await legacyDir.exists()) continue;
        if (p.canonicalize(legacyDir.path) == targetCanonical) continue;

        final items = legacyDir.listSync(followLinks: false);
        for (final item in items) {
          final name = p.basename(item.path);
          final destPath = p.join(targetDir.path, name);

          if (item is Directory) {
            final destDir = Directory(destPath);
            if (!await destDir.exists()) {
              await _copyDirectory(item, destDir);
            }
          } else if (item is File) {
            final destFile = File(destPath);
            if (!await destFile.exists()) {
              await item.copy(destPath);
            }
          }
        }
      } catch (e) {
        debugPrint('[GameRepository] Migration from ${legacyDir.path} error: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Local library
  // ---------------------------------------------------------------------------

  /// Scans the local games directory for game folders and loose QSP files.
  Future<List<LocalGame>> scanLocalGames([String? customDir]) async {
    final dir = await getGamesDirectory(customDir);
    if (!await dir.exists()) return const [];

    final games = <LocalGame>[];
    final entries = dir.listSync(followLinks: false);

    for (final entry in entries) {
      if (entry is Directory) {
        final game = await _scanGameFolder(entry);
        if (game != null) games.add(game);
      } else if (entry is File) {
        final ext = p.extension(entry.path).toLowerCase();
        if (ext == '.qsp' || ext == '.gam') {
          final fileName = p.basenameWithoutExtension(entry.path);
          games.add(LocalGame(
            id: fileName,
            title: fileName,
            folderPath: dir.path,
            gameFilePath: entry.path,
            fileSize: await entry.length(),
          ));
        }
      }
    }

    games.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return games;
  }

  Future<LocalGame?> _scanGameFolder(Directory folder) async {
    final folderName = p.basename(folder.path);
    final info = await _readGameInfo(folder);
    final isHidden = (info?['isHidden'] as bool?) ?? false;
    if (isHidden) return null;

    final gameFile = _findGameFileDeep(folder, _maxGameFileDepth);
    if (gameFile == null) return null;

    final poster = _findPoster(folder);
    final folderSize = await _dirSize(folder);

    return LocalGame(
      id: info?['id'] as String? ?? folderName,
      title: _nonEmpty(info?['title'] as String?, folderName),
      author: (info?['author'] as String?) ?? '',
      version: (info?['version'] as String?) ?? '',
      folderPath: folder.path,
      gameFilePath: gameFile.path,
      posterPath: poster?.path ?? '',
      fileSize: folderSize > 0 ? folderSize : await gameFile.length(),
      isFavorite: (info?['isFavorite'] as bool?) ?? false,
    );
  }

  static String _nonEmpty(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  File? _findGameFileDeep(Directory root, int maxDepth, [int depth = 0]) {
    if (depth > maxDepth) return null;
    List<FileSystemEntity> children;
    try {
      children = root.listSync(followLinks: false);
    } catch (_) {
      return null;
    }

    for (final child in children) {
      if (child is! File) continue;
      final ext = p.extension(child.path).toLowerCase();
      if (ext == '.qsp' || ext == '.gam') return child;
    }
    for (final child in children) {
      if (child is! Directory) continue;
      final found = _findGameFileDeep(child, maxDepth, depth + 1);
      if (found != null) return found;
    }
    return null;
  }

  File? _findPoster(Directory root) {
    File? fallback;
    List<FileSystemEntity> children;
    try {
      children = root.listSync(followLinks: false);
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

  Future<int> _dirSize(Directory dir) async {
    var total = 0;
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
          if (total > 2 * 1024 * 1024 * 1024) break;
        }
      }
    } catch (_) {
      return total;
    }
    return total;
  }

  Future<Map<String, dynamic>?> _readGameInfo(Directory folder) async {
    final infoFile = File(p.join(folder.path, gameInfoFilename));
    if (!await infoFile.exists()) return null;
    try {
      final content = await infoFile.readAsString();
      if (content.trim().isEmpty) return null;
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Flips the favorite flag of [game], preserving the rest of its
  /// `.gameInfo`, and returns the updated entry.
  Future<LocalGame> toggleFavorite(LocalGame game) async {
    final folder = Directory(game.folderPath);
    final info = await _readGameInfo(folder) ?? <String, dynamic>{};
    final next = !(info['isFavorite'] as bool? ?? game.isFavorite);
    info['isFavorite'] = next;
    final infoFile = File(p.join(folder.path, gameInfoFilename));
    const encoder = JsonEncoder.withIndent('  ');
    try {
      await infoFile.writeAsString(encoder.convert(info));
    } catch (_) {
      await writeGameInfo(
        folder,
        id: game.id,
        title: game.title,
        author: game.author,
        version: game.version,
        isFavorite: next,
      );
    }
    return game.copyWith(isFavorite: next);
  }

  Future<void> hideGame(LocalGame game) async {
    final folder = Directory(game.folderPath);
    final info = await _readGameInfo(folder) ?? <String, dynamic>{};
    info['isHidden'] = true;
    final infoFile = File(p.join(folder.path, gameInfoFilename));
    const encoder = JsonEncoder.withIndent('  ');
    try {
      await infoFile.writeAsString(encoder.convert(info));
    } catch (_) {
      await writeGameInfo(
        folder,
        id: game.id,
        title: game.title,
        author: game.author,
        version: game.version,
        isFavorite: game.isFavorite,
        isHidden: true,
      );
    }
  }

  /// Writes a legacy-compatible `.gameInfo` JSON file into [folder].
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
    bool isFavorite = false,
    bool isHidden = false,
  }) async {
    final infoFile = File(p.join(folder.path, gameInfoFilename));
    const encoder = JsonEncoder.withIndent('  ');
    await infoFile.writeAsString(encoder.convert({
      'id': id,
      'listId': 0,
      'author': author,
      'portedBy': '',
      'version': version,
      'title': title,
      'lang': '',
      'player': '',
      'iconUrl': '',
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'fileExt': fileExt,
      'descUrl': descUrl,
      'pubDate': '',
      'modDate': '',
      'isFavorite': isFavorite,
      'isHidden': isHidden,
    }));
  }

  // ---------------------------------------------------------------------------
  // Import from a user-picked folder
  // ---------------------------------------------------------------------------

  /// Copies an externally picked game [sourcePath] into the games directory.
  ///
  /// A folder containing a `.zip`/`.aqsp` archive is unpacked, any other
  /// folder is copied as-is.
  Future<LocalGame?> importGameFolder(
    String sourcePath, {
    String? customDir,
    void Function(double)? onProgress,
  }) async {
    final source = Directory(sourcePath.trim());
    if (!await source.exists()) {
      throw RepositoryException('Selected folder does not exist.');
    }

    final root = await getGamesDirectory(customDir);
    final folderName = p.basename(p.normalize(source.path));
    var target = Directory(p.join(root.path, folderName));
    var counter = 1;
    while (await target.exists()) {
      target = Directory(p.join(root.path, '$folderName (${counter++})'));
    }

    final archive = _findFirstArchive(source);
    if (archive != null) {
      await target.create(recursive: true);
      await _extractArchiveFile(archive, target, onProgress: onProgress);
    } else {
      await _copyDirectory(source, target);
    }

    final gameFile = _findGameFileDeep(target, _maxGameFileDepth);
    if (gameFile == null) {
      await target.delete(recursive: true);
      throw RepositoryException('No .qsp or .gam file found in the folder.');
    }

    await writeGameInfo(
      target,
      id: p.basename(target.path),
      title: p.basename(target.path),
    );
    await _createMarkerFiles(target);

    onProgress?.call(1);
    return _scanGameFolder(target);
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

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (entity is File) {
        await entity.copy(p.join(target.path, name));
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(p.join(target.path, name)));
      }
    }
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

    final webUri =
        Uri.parse('https://qsp.org/games').replace(queryParameters: queryParams);
    debugPrint('[GameRepository] Fetching web catalog page $page: $webUri');

    try {
      final response = await http
          .get(webUri, headers: {'Accept': 'text/html'})
          .timeout(const Duration(seconds: 15));
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
    return WebCatalogResult(games: fallbackGames, currentPage: 1, totalPages: 1);
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

      final linkMatch =
          RegExp(r'href="(https://qsp\.org/games/(\d+)[^"]*)"').firstMatch(block);
      if (linkMatch == null) continue;
      final gameUrl = linkMatch.group(1)!;
      final gameId = linkMatch.group(2)!;

      final imgMatch = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(block);
      var posterUrl = imgMatch?.group(1)?.trim() ?? '';
      if (posterUrl.startsWith('/')) {
        posterUrl = 'https://qsp.org$posterUrl';
      }

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
          title =
              plainTitleMatch.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
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

      final downloadUrl = '$gameUrl/download';

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
        ));
      }
    }

    return WebCatalogResult(
      games: games,
      currentPage: currentPage,
      totalPages: totalPages,
    );
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
          if (decoded is Map<String, dynamic> &&
              decoded['games'] is List) {
            final games = (decoded['games'] as List)
                .whereType<Map<String, dynamic>>()
                .map(RemoteGame.fromJson)
                .where((game) => game.title.isNotEmpty && game.fileUrl.isNotEmpty)
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
        String tag(String name) => node.getElement(name)?.innerText.trim() ?? '';

        final title = tag('title');
        if (title.isEmpty) continue;

        final idText = tag('id');
        final id = int.tryParse(idText)?.toString() ??
            (idText.isNotEmpty ? idText : '${fallbackId++}');

        games.add(RemoteGame(
          id: id,
          title: title,
          author: tag('author'),
          portedBy: tag('ported_by'),
          version: tag('version'),
          lang: tag('lang'),
          player: tag('player'),
          icon: tag('icon').isNotEmpty ? tag('icon') : tag('image'),
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

  /// Downloads a remote game archive into the games directory and unpacks it.
  ///
  /// Uses the system download pipeline with a progress notification so
  /// large game archives keep downloading outside the app, mirroring the
  /// legacy `DownloadManager` behavior.
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
    final targetFolder = Directory(
        p.join(root.path, folderName.isEmpty ? 'game_${DateTime.now().millisecondsSinceEpoch}' : folderName));
    if (!await targetFolder.exists()) {
      await targetFolder.create(recursive: true);
    }

    final downloadUrl = await resolveDirectDownloadUrl(remoteGame.fileUrl);

    final fileName = resolveDownloadFileName(
      await _probeContentDisposition(downloadUrl),
      downloadUrl,
      remoteGame.id,
      remoteGame.fileExt,
    );

    await _configureDownloadNotifications(remoteGame.title);
    final task = DownloadTask(
      url: downloadUrl,
      filename: fileName,
      baseDirectory: BaseDirectory.root,
      directory: targetFolder.path,
      updates: Updates.statusAndProgress,
      retries: 2,
    );
    final result = await FileDownloader().download(
      task,
      onProgress: (progress) =>
          onProgress?.call((progress * 0.9).clamp(0.0, 0.9)),
    );
    if (result.status != TaskStatus.complete) {
      throw RepositoryException(
          'Download failed with status ${result.status.name}.');
    }

    final archivePath = p.join(targetFolder.path, fileName);
    if (!await File(archivePath).exists()) {
      throw RepositoryException('Download finished but the file is missing.');
    }

    final extracted = await _extractArchiveFile(
      File(archivePath),
      targetFolder,
      onProgress: (value) =>
          onProgress?.call(0.9 + (value.clamp(0.0, 1.0) * 0.1)),
    );
    if (!extracted) {
      await _deleteQuietly(File(archivePath));
      throw RepositoryException(
          'Unsupported archive format: ${p.extension(fileName)}');
    }

    // Only delete archive file if it was a compressed archive (.zip, .rar, .aqsp, .7z)
    final archiveExt = p.extension(archivePath).toLowerCase();
    if (archiveExt != '.qsp' && archiveExt != '.gam') {
      await _deleteQuietly(File(archivePath));
    }

    // Download and cache remote poster image if local folder doesn't have a poster image
    if (_findPoster(targetFolder) == null && remoteGame.posterUrl.isNotEmpty) {
      try {
        debugPrint(
            '[GameRepository] Caching remote poster locally for game #${remoteGame.id}...');
        final imgRes = await http
            .get(Uri.parse(remoteGame.posterUrl))
            .timeout(const Duration(seconds: 10));
        if (imgRes.statusCode == 200 && imgRes.bodyBytes.isNotEmpty) {
          final ext = p.extension(remoteGame.posterUrl).toLowerCase();
          final targetPosterName =
              (ext == '.png' || ext == '.webp') ? 'poster$ext' : 'poster.jpg';
          final cachedPoster = File(p.join(targetFolder.path, targetPosterName));
          await cachedPoster.writeAsBytes(imgRes.bodyBytes);
          debugPrint('[GameRepository] Cached poster to ${cachedPoster.path}');
        }
      } catch (e) {
        debugPrint('[GameRepository] Failed to cache remote poster: $e');
      }
    }

    await writeGameInfo(
      targetFolder,
      id: remoteGame.id,
      title: remoteGame.title,
      author: remoteGame.author,
      version: remoteGame.version,
      fileUrl: remoteGame.fileUrl,
      fileSize: remoteGame.fileSize,
      fileExt: remoteGame.fileExt,
      descUrl: remoteGame.descUrl,
    );
    await _createMarkerFiles(targetFolder);

    onProgress?.call(1);
    final imported = await _scanGameFolder(targetFolder);
    if (imported == null) {
      throw RepositoryException('Download finished but no game file was found.');
    }
    return imported;
  }

  /// Best-effort `HEAD` probe for the server `Content-Disposition` header
  /// so RFC 5987 file names survive the background transfer.
  Future<String?> _probeContentDisposition(String fileUrl) async {
    try {
      final response = await http
          .head(Uri.parse(fileUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return response.headers['content-disposition'];
      }
    } catch (_) {
      // Fall back to URL-based naming.
    }
    return null;
  }

  bool _downloadNotificationsConfigured = false;

  Future<void> _configureDownloadNotifications(String title) async {
    if (_downloadNotificationsConfigured) return;
    _downloadNotificationsConfigured = true;
    try {
      FileDownloader().configureNotification(
        running: TaskNotification('Downloading $title', '{filename}'),
        complete: TaskNotification('Download complete', '{filename}'),
        error: TaskNotification('Download failed', '{filename}'),
        progressBar: true,
        tapOpensFile: false,
      );
    } catch (_) {
      // Notifications are best-effort (e.g. in tests).
    }
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
          fileName = part.substring('filename='.length).replaceAll('"', '').trim();
        }
      }
    }

    if (fileName == null || fileName.isEmpty || fileName == 'downloadfile') {
      final urlName = p.basename(Uri.tryParse(fileUrl)?.path ?? '');
      if (_downloadableExtensions.contains(
          p.extension(urlName).replaceFirst('.', '').toLowerCase())) {
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

    final rust = RustRuntime.tryLoad();
    if (rust != null) {
      try {
        final count = rust.extractArchive(archiveFile.path, target.path);
        if (count > 0) return true;
      } catch (_) {
        // Fall back to the Dart implementation.
      }
    }

    try {
      final bytes = await archiveFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final targetRoot = p.normalize(target.path);
      var index = 0;
      final total = archive.length;
      for (final file in archive) {
        final safePath = _safeArchivePath(targetRoot, file.name);
        if (safePath == null) continue;
        if (file.isFile) {
          final outFile = File(safePath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(safePath).create(recursive: true);
        }
        index++;
        if (total > 0) {
          onProgress?.call(0.5 + 0.5 * (index / total));
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns a normalized absolute path inside [targetRoot] or `null` when the
  /// entry would escape it (Zip Slip).
  String? _safeArchivePath(String targetRoot, String entryName) {
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
