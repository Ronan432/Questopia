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

class GameMorphButton extends StatefulWidget {
  const GameMorphButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool filled;

  @override
  State<GameMorphButton> createState() => _GameMorphButtonState();
}

class _GameMorphButtonState extends State<GameMorphButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = _isPressed
        ? BorderRadius.circular(8)
        : BorderRadius.circular(24);

    final bg = widget.filled
        ? theme.colorScheme.primary
        : Colors.transparent;
    final fg = widget.filled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onHighlightChanged: (highlighted) {
            setState(() {
              _isPressed = highlighted;
            });
          },
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: DefaultTextStyle(
              style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
              child: IconTheme(
                data: IconThemeData(color: fg, size: 18),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageDialog extends StatelessWidget {
  const _MessageDialog({required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  String _cleanText(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clean = _cleanText(text);

    return AlertDialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Message',
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          clean.isNotEmpty ? clean : text,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
      actions: [
        GameMorphButton(onPressed: onClose, child: const Text('OK')),
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
    final colors = Theme.of(context).colorScheme;
    final cleanPrompt = widget.prompt
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '')
        .trim();

    return AlertDialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        cleanPrompt.isNotEmpty ? cleanPrompt : 'Input',
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: colors.onSurface, fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.outline),
          ),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: widget.onSubmit,
      ),
      actions: [
        GameMorphButton(
            filled: false, onPressed: widget.onCancel, child: const Text('Cancel')),
        GameMorphButton(
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
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Choose',
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
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
                  final cleanTitle = items[index].name
                      .replaceAll(
                          RegExp(r'<[^>]*>',
                              caseSensitive: false, dotAll: true),
                          '')
                      .trim();
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
        GameMorphButton(
            filled: false, onPressed: onCancel, child: const Text('Cancel')),
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

    return AlertDialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Error',
        style: TextStyle(
          color: colors.error,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          details,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        GameMorphButton(onPressed: onClose, child: const Text('OK')),
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
    final colors = Theme.of(context).colorScheme;
    final isFile = imageUrl.isNotEmpty && File(imageUrl).existsSync();
    final isRemote =
        imageUrl.toLowerCase().startsWith('http://') ||
        imageUrl.toLowerCase().startsWith('https://');

    return Dialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title: Text('Image', style: TextStyle(color: colors.onSurface)),
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
                          child: Text(
                            'Image not found: $imageUrl',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
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
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Restart game?',
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(
        'Unsaved progress will be lost.',
        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
      ),
      actions: [
        GameMorphButton(
            filled: false, onPressed: onCancel, child: const Text('Cancel')),
        GameMorphButton(onPressed: onConfirm, child: const Text('Restart')),
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
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'QSP console',
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
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
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'QSP code...',
                hintStyle: TextStyle(color: colors.onSurfaceVariant),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
        GameMorphButton(
            filled: false, onPressed: widget.onClose, child: const Text('Close')),
        GameMorphButton(
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
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Open save file',
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(
        'Pick an external .sav file to load.',
        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
      ),
      actions: [
        GameMorphButton(
            filled: false, onPressed: onClose, child: const Text('Cancel')),
        GameMorphButton(
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
