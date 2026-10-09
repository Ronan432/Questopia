import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

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
      final colors = Theme.of(sheetContext).colorScheme;
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

      Widget buildPreview() {
        if (imageUri.startsWith('http://') || imageUri.startsWith('https://')) {
          return Image.network(imageUri, fit: BoxFit.cover);
        }
        return Image.file(File(imageUri), fit: BoxFit.cover);
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'Image Options',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                color: colors.surfaceContainerHighest,
                child: buildPreview(),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedListSection(
              children: [
                SegmentedListTile(
                  leading: const Icon(Icons.content_copy_rounded),
                  title: const Text('Copy image'),
                  onTap: () => run(
                    () => service.copyImage(imageUri),
                    'Image reference copied',
                    'Could not copy the image',
                  ),
                ),
                SegmentedListTile(
                  leading: const Icon(Icons.file_download_rounded),
                  title: const Text('Save to gallery'),
                  onTap: () => run(
                    () => service.saveToGallery(imageUri),
                    'Image saved to gallery',
                    'Could not save the image',
                  ),
                ),
                SegmentedListTile(
                  leading: const Icon(Icons.search_rounded),
                  title: const Text('Search image on Yandex'),
                  onTap: () => run(
                    () => service.searchImage(imageUri, languageCode: languageCode),
                    'Opening Yandex image search',
                    'Could not open Yandex search',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
