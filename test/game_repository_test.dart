import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/features/library/data/game_repository.dart';
import 'package:questopia_re/features/library/data/remote_game.dart';

void main() {
  final repository = GameRepository();

  group('parseCatalogXml', () {
    test('parses the gamestock payload with CDATA values', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<game_list version="1.0" id="qspsu_maingamelist" title="QSP main game list">
	<game>
		<id><![CDATA[455]]></id>
		<author><![CDATA[Mioirel]]></author>
		<version><![CDATA[1.12]]></version>
		<title><![CDATA[Night Shift]]></title>
		<lang><![CDATA[ru]]></lang>
		<icon><![CDATA[https://qsp.org/images/455_ico.jpg]]></icon>
		<file_url><![CDATA[https://qsp.org/gamestock/index2.php?fid=1325]]></file_url>
		<file_size><![CDATA[3506739]]></file_size>
		<file_ext><![CDATA[zip]]></file_ext>
		<desc_url><![CDATA[https://qsp.org/details/455]]></desc_url>
	</game>
	<game>
		<id><![CDATA[454]]></id>
		<title><![CDATA[]]></title>
		<file_url><![CDATA[https://qsp.org/gamestock/index2.php?fid=1320]]></file_url>
	</game>
</game_list>
''';

      final games = repository.parseCatalogXml(xml);

      expect(games, hasLength(1));
      expect(games.first.id, '455');
      expect(games.first.title, 'Night Shift');
      expect(games.first.author, 'Mioirel');
      expect(games.first.version, '1.12');
      expect(games.first.lang, 'ru');
      expect(games.first.fileUrl, contains('fid=1325'));
      expect(games.first.fileSize, 3506739);
      expect(games.first.fileExt, 'zip');
      expect(games.first.icon, contains('455_ico.jpg'));
      expect(games.first.descUrl, contains('/details/455'));
    });

    test('returns an empty list for empty payloads', () {
      expect(repository.parseCatalogXml(''), isEmpty);
      expect(repository.parseCatalogXml('   '), isEmpty);
    });
  });

  group('resolveDownloadFileName', () {
    test('prefers the RFC 5987 filename* form', () {
      final name = repository.resolveDownloadFileName(
        "attachment; filename*=UTF-8''%D0%98%D0%B3%D1%80%D0%B0.zip",
        'https://qsp.org/gamestock/index2.php?fid=1325',
        '455',
        'zip',
      );
      expect(name, 'Игра.zip');
    });

    test('uses the plain filename form', () {
      final name = repository.resolveDownloadFileName(
        'attachment; filename="my_game.zip"',
        'https://qsp.org/gamestock/index2.php?fid=1325',
        '455',
        'zip',
      );
      expect(name, 'my_game.zip');
    });

    test('falls back to the game id and repository extension', () {
      final name = repository.resolveDownloadFileName(
        null,
        'https://qsp.org/gamestock/index2.php?fid=1325',
        '455',
        'rar',
      );
      expect(name, '455.rar');
    });

    test('strips path separators from the resolved name', () {
      final name = repository.resolveDownloadFileName(
        'attachment; filename="../evil/name.zip"',
        'https://qsp.org/file.zip',
        '455',
        'zip',
      );
      expect(name.contains('/'), isFalse);
      expect(name.contains('\\'), isFalse);
      expect(name.contains('..'), isFalse);
    });
  });

  group('RemoteGame.fromJson', () {
    test('accepts the snake_case rust payload', () {
      final game = RemoteGame.fromJson(const {
        'id': 455,
        'list_id': 1,
        'author': 'Mioirel',
        'title': 'Night Shift',
        'file_url': 'https://example.org/game.zip',
        'file_size': 1024,
        'file_ext': 'zip',
      });

      expect(game.id, '455');
      expect(game.title, 'Night Shift');
      expect(game.fileUrl, 'https://example.org/game.zip');
      expect(game.fileSize, 1024);
      expect(game.fileExt, 'zip');
    });

    test('accepts camelCase keys and string numbers', () {
      final game = RemoteGame.fromJson(const {
        'game_id': 'abc',
        'game_name': 'Some Game',
        'fileUrl': 'https://example.org/g.zip',
        'fileSize': '2048',
      });

      expect(game.id, 'abc');
      expect(game.title, 'Some Game');
      expect(game.fileUrl, 'https://example.org/g.zip');
      expect(game.fileSize, 2048);
    });
  });
}
