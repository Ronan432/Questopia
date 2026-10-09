import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../../core/helpers/sheet_ui_helper.dart';
import '../../../providers/game_engine_provider.dart';

/// Helper for importing and exporting .sav files in save slots sheet.
class SaveImportExportRow extends StatelessWidget {
  const SaveImportExportRow({super.key, required this.engineNotifier});

  final GameEngineNotifier engineNotifier;

  Future<void> _handleImport(BuildContext context) async {
    final navigator = Navigator.of(context);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sav'],
        withData: true,
      );
    } catch (_) {
      result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    }

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.single;
      bool ok = false;
      if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
        ok = engineNotifier.restoreSaveSnapshot(pickedFile.bytes!);
      } else if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
        ok = await engineNotifier.importSaveFile(pickedFile.path!);
      }

      if (context.mounted) {
        if (ok) navigator.pop();
        showSheetSnackBar(
          context,
          ok ? 'Save file imported successfully' : 'Failed to import save file',
        );
      }
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    final bytes = engineNotifier.takeSaveSnapshot();
    if (bytes == null || bytes.isEmpty) {
      showSheetSnackBar(context, 'No active save data to export');
      return;
    }
    String? result;
    try {
      result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Save File',
        fileName: 'game_save.sav',
        type: FileType.custom,
        allowedExtensions: ['sav'],
        bytes: bytes,
      );
    } catch (_) {
      result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Save File',
        fileName: 'game_save.sav',
        type: FileType.any,
        bytes: bytes,
      );
    }

    if (result != null && result.isNotEmpty) {
      if (!kIsWeb) {
        try {
          final file = File(result);
          await file.writeAsBytes(bytes, flush: true);
        } catch (_) {}
      }
      if (context.mounted) showSheetSnackBar(context, 'Save file exported');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: M3EButton.icon(
            onPressed: () => _handleImport(context),
            size: M3EButtonSize.sm,
            style: M3EButtonStyle.outlined,
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Import .sav'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: M3EButton.icon(
            onPressed: () => _handleExport(context),
            size: M3EButtonSize.sm,
            style: M3EButtonStyle.outlined,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export .sav'),
          ),
        ),
      ],
    );
  }
}
