import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/core/error/crash_reporter.dart';
import 'package:questopia_re/features/library/data/game_repository.dart';
import 'package:questopia_re/features/library/data/local_game.dart';

void main() {
  test('crash reporter returns null without a stored report', () async {
    expect(await CrashReporter.takePendingReport(), isNull);
  });

  test('toggleFavorite flips and persists the flag', () async {
    final root = await Directory.systemTemp.createTemp('questopia_fav');
    addTearDown(() => root.delete(recursive: true));
    final folder = Directory('${root.path}/game1');
    await folder.create();
    final repository = GameRepository();
    await repository.writeGameInfo(
      folder,
      id: 'game1',
      title: 'Game 1',
      author: 'Author',
    );

    const game = LocalGame(
      id: 'game1',
      title: 'Game 1',
      author: 'Author',
      folderPath: '',
      gameFilePath: '',
    );
    final withFolder = game.copyWith(folderPath: folder.path);

    final fav = await repository.toggleFavorite(withFolder);
    expect(fav.isFavorite, isTrue);

    final unfav = await repository.toggleFavorite(fav);
    expect(unfav.isFavorite, isFalse);
  });
}
