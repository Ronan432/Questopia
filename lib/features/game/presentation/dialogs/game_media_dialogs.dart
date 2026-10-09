import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../core/helpers/dialog_helper.dart';
import '../../../../core/media/poster_menu_sheet.dart';
import '../../../../core/media/qsp_media_kind.dart';
import 'game_media_viewer.dart';

/// Image and video preview dialog.
class GameImagePreviewDialog extends StatelessWidget {
  const GameImagePreviewDialog({
    super.key,
    required this.imageUrl,
    required this.onClose,
  });

  final String imageUrl;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isVideo = detectMediaKind(imageUrl) == QspMediaKind.video;

    return QuestopiaDialog(
      maxWidth: 540,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isVideo ? 'Video Preview' : 'Image Preview'),
          if (imageUrl.isNotEmpty)
            IconButton(
              tooltip: 'Options',
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => showPosterMenuSheet(
                context: context,
                imageUri: imageUrl,
              ),
            ),
        ],
      ),
      content: GameMediaViewer(
        mediaPath: imageUrl,
        maxHeight: 380,
      ),
      actions: [
        M3EButton(
          onPressed: onClose,
          style: M3EButtonStyle.tonal,
          size: M3EButtonSize.md,
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Restart game confirmation dialog.
class GameRestartConfirmationDialog extends StatelessWidget {
  const GameRestartConfirmationDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return const QuestopiaConfirmationDialog(
      icon: Icons.restart_alt_rounded,
      isDestructive: true,
      title: 'Restart game?',
      message: 'Unsaved progress will be lost.',
      confirmLabel: 'Restart',
      cancelLabel: 'Cancel',
    );
  }
}

/// QSP console executor modal dialog.
class GameExecutorDialog extends StatefulWidget {
  const GameExecutorDialog({
    super.key,
    required this.output,
    required this.onRun,
    required this.onClose,
  });

  final String output;
  final ValueChanged<String> onRun;
  final VoidCallback onClose;

  @override
  State<GameExecutorDialog> createState() => _GameExecutorDialogState();
}

class _GameExecutorDialogState extends State<GameExecutorDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return QuestopiaDialog(
      maxWidth: 520,
      icon: const Icon(Icons.terminal_rounded),
      title: const Text('QSP Console'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
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
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'QSP code...',
                hintStyle: TextStyle(color: colors.onSurfaceVariant),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
        M3EButton(
          onPressed: widget.onClose,
          style: M3EButtonStyle.text,
          size: M3EButtonSize.md,
          child: const Text('Close'),
        ),
        M3EButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onRun(_controller.text.trim());
              _controller.clear();
            }
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.md,
          child: const Text('Run'),
        ),
      ],
    );
  }
}
