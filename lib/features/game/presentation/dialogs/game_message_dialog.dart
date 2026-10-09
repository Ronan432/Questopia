import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../core/helpers/dialog_helper.dart';
import '../../../../core/helpers/html_processor.dart';
import 'game_media_viewer.dart';

/// Engine message modal dialog with image extraction and text decoding.
class GameMessageDialog extends StatelessWidget {
  const GameMessageDialog({
    super.key,
    required this.text,
    required this.onClose,
    this.gameFolderPath,
  });

  final String text;
  final VoidCallback onClose;
  final String? gameFolderPath;

  String _cleanText(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  List<String> _extractImageSources(String input) {
    if (input.isEmpty) return const [];
    final processed = HtmlProcessor.processHtml(input);
    final results = <String>[];
    final regExp = RegExp(
      r'<img[^>]+src=["\x27]?([^"\x27\s>]+)["\x27]?[^>]*>',
      caseSensitive: false,
    );
    for (final match in regExp.allMatches(processed)) {
      final src = match.group(1);
      if (src != null && src.isNotEmpty) {
        results.add(src);
      }
    }
    return results;
  }

  File? _findAssetFile(String src) {
    if (src.isEmpty) return null;
    final direct = File(src);
    if (direct.existsSync()) return direct;

    var clean = src.replaceAll('\\', '/');
    while (clean.startsWith('/') || clean.startsWith('./')) {
      clean = clean.startsWith('./') ? clean.substring(2) : clean.substring(1);
    }

    if (gameFolderPath != null) {
      final joined = File('$gameFolderPath/$clean');
      if (joined.existsSync()) return joined;

      final targetSuffix = clean.toLowerCase();
      final targetBase = targetSuffix.split('/').last;

      try {
        final dir = Directory(gameFolderPath!);
        if (dir.existsSync()) {
          for (final entity
              in dir.listSync(recursive: true, followLinks: false)) {
            if (entity is File) {
              final norm = entity.path.replaceAll('\\', '/').toLowerCase();
              if (norm.endsWith('/$targetSuffix') ||
                  norm.endsWith(targetSuffix) ||
                  norm.endsWith('/$targetBase')) {
                return entity;
              }
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Widget _buildImageWidget(BuildContext context, String src) {
    final file = _findAssetFile(src);
    final resolvedPath = file?.path ?? src;
    return GameMediaViewer(mediaPath: resolvedPath, maxHeight: 240);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final images = _extractImageSources(text);
    final clean = _cleanText(text);

    return QuestopiaDialog(
      title: const Text('Message'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final src in images) _buildImageWidget(context, src),
          if (clean.isNotEmpty)
            Text(
              clean,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 15,
                height: 1.5,
              ),
            ),
        ],
      ),
      actions: [
        M3EButton(
          onPressed: onClose,
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.md,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
