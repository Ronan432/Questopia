import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/poster_menu_sheet.dart';
import '../../../../core/native/qsp_models.dart';
import '../../providers/game_engine_provider.dart';

class GameDialogsHost extends ConsumerWidget {
  const GameDialogsHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engineState = ref.watch(gameEngineProvider);
    final notifier = ref.read(gameEngineProvider.notifier);

    void dismiss() {
      notifier.closeDialog();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    switch (engineState.activeDialog) {
      case GameDialogType.message:
        return _MessageDialog(
          text: engineState.messageText,
          onClose: dismiss,
        );
      case GameDialogType.input:
        return _InputDialog(
          prompt: engineState.inputPrompt,
          prefill: engineState.inputPrefill,
          onSubmit: (value) {
            if (notifier.takePendingInputAnswer() != null) {
              notifier.answerInput(value);
            } else {
              notifier.execCode(value);
            }
            dismiss();
          },
          onCancel: dismiss,
        );
      case GameDialogType.menu:
        return _MenuDialog(
          items: engineState.menuItems,
          onSelect: (index) {
            notifier.answerMenu(index);
            dismiss();
          },
          onCancel: dismiss,
        );
      case GameDialogType.error:
        return _ErrorDialog(
          error: engineState.errorInfo,
          onClose: dismiss,
        );
      case GameDialogType.imagePreview:
        return _ImagePreviewDialog(
          imageUrl: engineState.previewImageUrl,
          onClose: dismiss,
        );
      case GameDialogType.restartConfirmation:
        return _RestartConfirmationDialog(
          onConfirm: () {
            notifier.restartGame();
            dismiss();
          },
          onCancel: dismiss,
        );
      case GameDialogType.executor:
        return _ExecutorDialog(
          output: engineState.consoleOutput,
          onRun: notifier.runConsole,
          onClose: dismiss,
        );
      case GameDialogType.fileLoad:
        return _FileLoadDialog(
          onPick: (path) async {
            final ok = await notifier.importSaveFile(path);
            dismiss();
            if (context.mounted && !ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open save file')),
              );
            }
          },
          onClose: dismiss,
        );
      case GameDialogType.none:
        return const SizedBox.shrink();
    }
  }
}

class _MessageDialog extends StatelessWidget {
  const _MessageDialog({required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Message'),
      content: SingleChildScrollView(child: Text(text)),
      actions: [
        FilledButton(onPressed: onClose, child: const Text('OK')),
      ],
    );
  }
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
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
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
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
    return AlertDialog(
      title: Text(widget.prompt.isNotEmpty ? widget.prompt : 'Input'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: widget.onSubmit,
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        FilledButton(
          onPressed: () => widget.onSubmit(_controller.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _MenuDialog extends StatelessWidget {
  const _MenuDialog({
    required this.items,
    required this.onSelect,
    required this.onCancel,
  });

  final List<QspMenuItem> items;
  final ValueChanged<int> onSelect;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose'),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Text('No options')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(items[index].name),
                    onTap: () => onSelect(index),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }
}

class _ErrorDialog extends StatelessWidget {
  const _ErrorDialog({required this.error, required this.onClose});

  final QspErrorInfo? error;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (error != null) ...[
        'Error #${error!.errorNum}: ${error!.errorDesc}',
        if (error!.locName.isNotEmpty) 'Location: ${error!.locName}',
        if (error!.lineNum > 0) 'Line: ${error!.lineNum}',
        if (error!.codeLine.isNotEmpty) 'Code: ${error!.codeLine}',
      ] else
        'Unknown engine error',
    ].join('\n');
    return AlertDialog(
      title: const Text('Error'),
      content: SingleChildScrollView(child: Text(details)),
      actions: [
        FilledButton(onPressed: onClose, child: const Text('OK')),
      ],
    );
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog({required this.imageUrl, required this.onClose});

  final String imageUrl;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isFile = imageUrl.isNotEmpty && File(imageUrl).existsSync();
    final isRemote =
        imageUrl.toLowerCase().startsWith('http://') ||
        imageUrl.toLowerCase().startsWith('https://');
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Image'),
            actions: [
              if (imageUrl.isNotEmpty)
                IconButton(
                  tooltip: 'Image options',
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => showPosterMenuSheet(
                    context: context,
                    imageUri: imageUrl,
                  ),
                ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose,
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: isFile
                  ? Image.file(File(imageUrl))
                  : isRemote
                      ? Image.network(imageUrl)
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Image not found: $imageUrl'),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestartConfirmationDialog extends StatelessWidget {
  const _RestartConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restart game?'),
      content: const Text('Unsaved progress will be lost.'),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        FilledButton(onPressed: onConfirm, child: const Text('Restart')),
      ],
    );
  }
}

class _ExecutorDialog extends StatefulWidget {
  const _ExecutorDialog({
    required this.output,
    required this.onRun,
    required this.onClose,
  });

  final String output;
  final ValueChanged<String> onRun;
  final VoidCallback onClose;

  @override
  State<_ExecutorDialog> createState() => _ExecutorDialogState();
}

class _ExecutorDialogState extends State<_ExecutorDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('QSP console'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.output.isEmpty ? 'No output yet' : widget.output,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'QSP code...'),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onRun(value.trim());
                  _controller.clear();
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Close')),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onRun(_controller.text.trim());
              _controller.clear();
            }
          },
          child: const Text('Run'),
        ),
      ],
    );
  }
}

class _FileLoadDialog extends StatelessWidget {
  const _FileLoadDialog({required this.onPick, required this.onClose});

  final ValueChanged<String> onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open save file'),
      content: const Text('Pick an external .sav file to load.'),
      actions: [
        TextButton(onPressed: onClose, child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['sav'],
            );
            final path = result?.files.singleOrNull?.path;
            if (path != null && path.isNotEmpty) onPick(path);
          },
          child: const Text('Pick file'),
        ),
      ],
    );
  }
}
