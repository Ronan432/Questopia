import 'package:flutter/material.dart';

import '../helpers/sheet_helper.dart';
import 'game_media.dart';

Future<void> showPosterMenuSheet({
  required BuildContext context,
  required String imageUri,
  MediaService? mediaService,
  String languageCode = 'en',
}) {
  final service = mediaService ?? MediaService();
  return showQuestopiaSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      Future<void> run(
        Future<bool> Function() action,
        String ok,
        String fail,
      ) async {
        Navigator.of(sheetContext).pop();
        final messenger = ScaffoldMessenger.of(context);
        final succeeded = await action();
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(succeeded ? ok : fail)),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: const Text('Copy image'),
              onTap: () => run(
                () => service.copyImage(imageUri),
                'Image reference copied',
                'Could not copy the image',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Save to gallery'),
              onTap: () => run(
                () => service.saveToGallery(imageUri),
                'Image saved to gallery',
                'Could not save the image',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: const Text('Search image on Yandex'),
              onTap: () => run(
                () => service.searchImage(imageUri,
                    languageCode: languageCode),
                'Opening Yandex image search',
                'Could not open Yandex search',
              ),
            ),
          ],
        ),
      );
    },
  );
}
