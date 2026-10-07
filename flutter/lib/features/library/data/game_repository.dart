import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'local_game.dart';
import 'remote_game.dart';
import '../../../core/native/rust_runtime.dart';

class GameRepository {
  Future<Directory> getGamesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final gamesDir = Directory(p.join(docsDir.path, 'Questopia', 'games'));
    if (!await gamesDir.exists()) {
      await gamesDir.create(recursive: true);
    }
    return gamesDir;
  }

  /// Scans the local games directory for game folders and loose QSP files.
  Future<List<LocalGame>> scanLocalGames() async {
    final dir = await getGamesDirectory();
    final games = <LocalGame>[];

    if (!await dir.exists()) return games;

    final entries = dir.listSync();
    for (final entry in entries) {
      if (entry is Directory) {
        final folderName = p.basename(entry.path);
        // Find main .qsp or .gam file inside
        final subFiles = entry.listSync();
        File? mainGameFile;
        File? posterFile;

        for (final sub in subFiles) {
          if (sub is File) {
            final ext = p.extension(sub.path).toLowerCase();
            if (ext == '.qsp' || ext == '.gam') {
              mainGameFile ??= sub;
            } else if (ext == '.jpg' || ext == '.png' || ext == '.webp') {
              if (p.basenameWithoutExtension(sub.path).toLowerCase().contains('poster') ||
                  p.basenameWithoutExtension(sub.path).toLowerCase().contains('title') ||
                  posterFile == null) {
                posterFile = sub;
              }
            }
          }
        }

        if (mainGameFile != null) {
          games.add(LocalGame(
            id: folderName,
            title: folderName,
            folderPath: entry.path,
            gameFilePath: mainGameFile.path,
            posterPath: posterFile?.path ?? '',
            fileSize: await mainGameFile.length(),
          ));
        }
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

    return games;
  }

  /// Downloads and extracts a remote game ZIP into local games folder.
  Future<LocalGame?> downloadAndExtractGame(RemoteGame remoteGame) async {
    final rootDir = await getGamesDirectory();
    final targetFolder = Directory(p.join(rootDir.path, remoteGame.id.isNotEmpty ? remoteGame.id : remoteGame.title));

    if (!await targetFolder.exists()) {
      await targetFolder.create(recursive: true);
    }

    // Download archive
    final response = await http.get(Uri.parse(remoteGame.fileUrl));
    if (response.statusCode != 200) return null;

    final zipPath = p.join(targetFolder.path, 'download.zip');
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(response.bodyBytes);

    // Try Rust native extract first for speed, fallback to Dart archive
    final rust = RustRuntime.tryLoad();
    var extractedCount = -1;
    if (rust != null) {
      extractedCount = rust.extractArchive(zipPath, targetFolder.path);
    }

    if (extractedCount <= 0) {
      // Dart fallback extraction with Zip Slip protection
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filename = file.name;
        if (filename.contains('..') || filename.startsWith('/') || filename.startsWith('\\')) {
          continue; // Prevent Zip Slip
        }
        final outFile = File(p.join(targetFolder.path, filename));
        if (file.isFile) {
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(outFile.path).create(recursive: true);
        }
      }
    }

    // Clean up temporary zip file
    if (await zipFile.exists()) {
      await zipFile.delete();
    }

    // Rescan local games
    final localGames = await scanLocalGames();
    return localGames.firstWhere(
      (g) => g.folderPath == targetFolder.path || g.title == remoteGame.title,
      orElse: () => LocalGame(
        id: remoteGame.id,
        title: remoteGame.title,
        author: remoteGame.author,
        version: remoteGame.version,
        folderPath: targetFolder.path,
        gameFilePath: p.join(targetFolder.path, '${remoteGame.title}.qsp'),
      ),
    );
  }

  /// Fetches remote stock game catalog XML.
  Future<List<RemoteGame>> fetchRemoteCatalog() async {
    try {
      const catalogUrl = 'https://qsp.org/repository/gamestock.xml';
      final response = await http.get(Uri.parse(catalogUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final rust = RustRuntime.tryLoad();
      if (rust != null) {
        final jsonResult = rust.parseRepositoryXml(response.body);
        if (jsonResult != null && jsonResult.isNotEmpty) {
          final List dynamicList = jsonDecode(jsonResult);
          return dynamicList.map((item) => RemoteGame.fromJson(item)).toList();
        }
      }

      // Basic regex fallback if XML parser native is absent
      return _parseCatalogXmlFallback(response.body);
    } catch (_) {
      return [];
    }
  }

  List<RemoteGame> _parseCatalogXmlFallback(String xml) {
    final games = <RemoteGame>[];
    final gameBlocks = xml.split('</game>');
    for (final block in gameBlocks) {
      if (!block.contains('<game>')) continue;
      final titleMatch = RegExp(r'<game_name>(.*?)</game_name>', dotAll: true).firstMatch(block);
      final authorMatch = RegExp(r'<author>(.*?)</author>', dotAll: true).firstMatch(block);
      final urlMatch = RegExp(r'<file_url>(.*?)</file_url>', dotAll: true).firstMatch(block);

      if (titleMatch != null && urlMatch != null) {
        games.add(RemoteGame(
          id: titleMatch.group(1) ?? '',
          title: titleMatch.group(1) ?? '',
          author: authorMatch?.group(1) ?? '',
          fileUrl: urlMatch.group(1) ?? '',
        ));
      }
    }
    return games;
  }
}
