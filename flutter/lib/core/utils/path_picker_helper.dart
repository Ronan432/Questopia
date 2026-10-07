import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class PathPickerHelper {
  /// Safely picks a directory path using getDirectoryPath(), file parent path fallback,
  /// or a manual path entry dialog.
  static Future<String?> pickDirectory(BuildContext context, {String currentPath = ''}) async {
    // Strategy 1: Try native getDirectoryPath()
    try {
      final selectedDir = await FilePicker.platform.getDirectoryPath();
      if (selectedDir != null && selectedDir.isNotEmpty) {
        return selectedDir;
      }
    } catch (_) {
      // Fall through to fallback
    }

    // Strategy 2: Pick any file inside the directory and use its parent directory
    try {
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.any,
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
      // Fall through to manual dialog
    }

    // Strategy 3: Direct path input dialog fallback
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
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '/sdcard/Questopia/games',
            prefixIcon: Icon(Icons.folder_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
