import 'dart:io';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PathPickerHelper {
  /// Ensures storage and manage external storage permissions are requested.
  static Future<bool> ensureStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      if (await Permission.storage.isGranted) return true;
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Picks a directory using 3rd party in-app FilesystemPicker directory browser.
  static Future<String?> pickDirectory(BuildContext context, {String currentPath = ''}) async {
    final folderColor = Theme.of(context).colorScheme.primary;

    await ensureStoragePermissions();
    if (!context.mounted) return null;

    // Determine root directory to start browsing from
    Directory rootDir;
    if (Platform.isAndroid) {
      rootDir = Directory('/storage/emulated/0');
      if (!await rootDir.exists()) {
        rootDir = await getApplicationDocumentsDirectory();
      }
    } else {
      rootDir = await getApplicationDocumentsDirectory();
    }

    try {
      if (!context.mounted) return null;
      final selectedPath = await FilesystemPicker.open(
        title: 'Select Game Folder',
        context: context,
        rootDirectory: rootDir,
        fsType: FilesystemType.folder,
        pickText: 'Select This Folder',
        folderIconColor: folderColor,
      );

      if (selectedPath != null && selectedPath.trim().isNotEmpty) {
        return selectedPath.trim();
      }
    } catch (_) {
      // Fall through to manual path entry dialog if picker is dismissed
    }

    // Direct path entry dialog fallback
    if (context.mounted) {
      return _showManualPathDialog(context, currentPath);
    }

    return null;
  }

  static Future<String?> _showManualPathDialog(BuildContext context, String currentPath) async {
    final controller = TextEditingController(text: currentPath);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Game Folder Path'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter path or tap preset folder:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '/storage/emulated/0/Questopia/games',
                prefixIcon: Icon(Icons.folder_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.folder_special, size: 16),
                  label: const Text('Questopia Games'),
                  onPressed: () => controller.text = '/storage/emulated/0/Questopia/games',
                ),
                ActionChip(
                  avatar: const Icon(Icons.download, size: 16),
                  label: const Text('Download Folder'),
                  onPressed: () => controller.text = '/storage/emulated/0/Download',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final path = controller.text.trim();
              Navigator.pop(ctx, path.isNotEmpty ? path : null);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
