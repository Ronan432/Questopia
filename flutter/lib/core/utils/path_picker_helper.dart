import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PathPickerHelper {
  /// Ensures storage and manage external storage permissions are requested.
  static Future<bool> ensureStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      // Fallback for standard storage permissions
      if (await Permission.storage.isGranted) return true;
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Picks a directory path safely with permission check, getDirectoryPath(),
  /// file selection fallback, and preset/manual path dialog.
  static Future<String?> pickDirectory(BuildContext context, {String currentPath = ''}) async {
    await ensureStoragePermissions();

    // Strategy 1: Native getDirectoryPath()
    try {
      final selectedDir = await FilePicker.platform.getDirectoryPath();
      if (selectedDir != null && selectedDir.trim().isNotEmpty) {
        return selectedDir.trim();
      }
    } catch (_) {
      // Fall through to file pick fallback
    }

    // Strategy 2: Pick a game file inside the target folder
    try {
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['qsp', 'gam', 'zip', 'txt', 'png', 'jpg'],
        allowMultiple: false,
      );
      if (fileResult != null && fileResult.files.isNotEmpty) {
        final filePath = fileResult.files.single.path;
        if (filePath != null) {
          final parentDir = File(filePath).parent.path;
          return parentDir;
        }
      }
    } catch (_) {
      // Fall through to dialog
    }

    // Strategy 3: Preset & Manual Path Entry Dialog
    if (context.mounted) {
      return _showPathSelectionDialog(context, currentPath);
    }

    return null;
  }

  static Future<String?> _showPathSelectionDialog(BuildContext context, String currentPath) async {
    final controller = TextEditingController(text: currentPath);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Game Folder Path'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter path or pick a preset folder:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '/sdcard/Questopia/games',
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
                  onPressed: () => controller.text = '/sdcard/Questopia/games',
                ),
                ActionChip(
                  avatar: const Icon(Icons.download, size: 16),
                  label: const Text('Download Folder'),
                  onPressed: () => controller.text = '/sdcard/Download',
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
