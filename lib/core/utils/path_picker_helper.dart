import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
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
      if (storageStatus.isGranted) return true;

      // Direct user to app settings if permission is denied
      if (status.isPermanentlyDenied || status.isDenied || storageStatus.isPermanentlyDenied) {
        await openAppSettings();
      }

      return await Permission.manageExternalStorage.isGranted ||
          await Permission.storage.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Picks a **folder** using the in-app FilesystemPicker UI.
  /// Shows both folders and files inside directories for easy identification.
  static Future<String?> pickDirectory(
    BuildContext context, {
    String currentPath = '',
    String title = 'Select folder',
  }) async {
    await ensureStoragePermissions();
    if (!context.mounted) return null;

    final folderColor = Theme.of(context).colorScheme.primary;

    if (Platform.isAndroid) {
      // In-App FilesystemPicker for Android
      Directory rootDir = Directory('/storage/emulated/0');
      if (!await rootDir.exists()) {
        rootDir = await getApplicationDocumentsDirectory();
      }

      try {
        if (!context.mounted) return null;
        final selectedPath = await FilesystemPicker.open(
          title: title,
          context: context,
          rootDirectory: rootDir,
          fsType: FilesystemType.folder,
          pickText: 'Select this folder',
          folderIconColor: folderColor,
        );

        if (selectedPath != null && selectedPath.trim().isNotEmpty) {
          final cleanPath = selectedPath.trim();
          if (File(cleanPath).existsSync()) {
            return p.dirname(cleanPath);
          }
          return cleanPath;
        }
      } catch (e) {
        debugPrint('[PathPickerHelper] FilesystemPicker.open error: $e');
      }
      return null;
    }

    // Windows / Desktop folder picker
    try {
      final nativePath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: title,
        initialDirectory: currentPath.isNotEmpty ? currentPath : null,
      );
      if (nativePath != null && nativePath.trim().isNotEmpty) {
        return nativePath.trim();
      }
    } catch (e) {
      debugPrint('[PathPickerHelper] Native folder picker unavailable: $e');
    }

    // Desktop fallback to FilesystemPicker
    try {
      final rootDir = await getApplicationDocumentsDirectory();
      if (!context.mounted) return null;
      final selectedPath = await FilesystemPicker.open(
        title: title,
        context: context,
        rootDirectory: rootDir,
        fsType: FilesystemType.all,
        pickText: 'Select this folder',
        folderIconColor: folderColor,
      );
      if (selectedPath != null && selectedPath.trim().isNotEmpty) {
        final cleanPath = selectedPath.trim();
        if (File(cleanPath).existsSync()) {
          return p.dirname(cleanPath);
        }
        return cleanPath;
      }
    } catch (_) {}

    return null;
  }
}
