import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_engine_provider.dart';
import 'game_engine_dialogs.dart';
import 'game_media_dialogs.dart';
import 'game_message_dialog.dart';

/// Central host dispatcher that resolves and renders the active game engine modal dialog.
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
        return GameMessageDialog(
          text: engineState.messageText,
          gameFolderPath: engineState.activeGame?.folderPath,
          onClose: dismiss,
        );
      case GameDialogType.input:
        return GameInputDialog(
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
        return GameMenuDialog(
          items: engineState.menuItems,
          onSelect: (index) {
            notifier.answerMenu(index);
            dismiss();
          },
          onCancel: dismiss,
        );
      case GameDialogType.error:
        return GameErrorDialog(
          error: engineState.errorInfo,
          onClose: dismiss,
        );
      case GameDialogType.imagePreview:
        return GameImagePreviewDialog(
          imageUrl: engineState.previewImageUrl,
          onClose: dismiss,
        );
      case GameDialogType.restartConfirmation:
        return GameRestartConfirmationDialog(
          onConfirm: () {
            notifier.restartGame();
            dismiss();
          },
          onCancel: dismiss,
        );
      case GameDialogType.executor:
        return GameExecutorDialog(
          output: engineState.consoleOutput,
          onRun: notifier.runConsole,
          onClose: dismiss,
        );
      case GameDialogType.fileLoad:
        return GameFileLoadDialog(
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
