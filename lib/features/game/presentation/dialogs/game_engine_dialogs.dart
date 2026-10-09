import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/helpers/dialog_helper.dart';
import '../../../../core/native/qsp_models.dart';

/// Engine input prompt modal dialog.
class GameInputDialog extends StatefulWidget {
  const GameInputDialog({
    super.key,
    required this.prompt,
    required this.prefill,
    required this.onSubmit,
    required this.onCancel,
  });

  final String prompt;
  final String prefill;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  State<GameInputDialog> createState() => _GameInputDialogState();
}

class _GameInputDialogState extends State<GameInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prefill);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cleanPrompt = widget.prompt
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '')
        .trim();

    return QuestopiaDialog(
      title: Text(cleanPrompt.isNotEmpty ? cleanPrompt : 'Input'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: colors.onSurface, fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.outline),
          ),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: widget.onSubmit,
      ),
      actions: [
        OutlinedButton(
          onPressed: widget.onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(64, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => widget.onSubmit(_controller.text),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(64, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Engine choose menu dialog.
class GameMenuDialog extends StatelessWidget {
  const GameMenuDialog({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onCancel,
  });

  final List<QspMenuItem> items;
  final ValueChanged<int> onSelect;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return QuestopiaDialog(
      title: const Text('Choose'),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? Text(
                'No options',
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cleanTitle = items[index]
                      .name
                      .replaceAll(
                        RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true),
                        '',
                      )
                      .trim();
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      cleanTitle.isNotEmpty ? cleanTitle : items[index].name,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () => onSelect(index),
                  );
                },
              ),
      ),
      actions: [
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(64, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Engine error dialog.
class GameErrorDialog extends StatelessWidget {
  const GameErrorDialog({super.key, required this.error, required this.onClose});

  final QspErrorInfo? error;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final details = [
      if (error != null) ...[
        'Error #${error!.errorNum}: ${error!.errorDesc}',
        if (error!.locName.isNotEmpty) 'Location: ${error!.locName}',
        if (error!.lineNum > 0) 'Line: ${error!.lineNum}',
        if (error!.codeLine.isNotEmpty) 'Code: ${error!.codeLine}',
      ] else
        'Unknown engine error',
    ].join('\n');

    return QuestopiaDialog(
      icon: const Icon(Icons.error_outline_rounded),
      title: const Text('Engine Error'),
      content: Text(
        details,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actions: [
        FilledButton(
          onPressed: onClose,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(64, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Save file picker modal dialog.
class GameFileLoadDialog extends StatelessWidget {
  const GameFileLoadDialog({super.key, required this.onPick, required this.onClose});

  final ValueChanged<String> onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return QuestopiaDialog(
      icon: const Icon(Icons.folder_open_rounded),
      title: const Text('Open Save File'),
      content: Text(
        'Pick an external .sav file to load.',
        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
      ),
      actions: [
        OutlinedButton(
          onPressed: onClose,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(64, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['sav'],
            );
            final path = result?.files.singleOrNull?.path;
            if (path != null && path.isNotEmpty) onPick(path);
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(64, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Pick File'),
        ),
      ],
    );
  }
}
