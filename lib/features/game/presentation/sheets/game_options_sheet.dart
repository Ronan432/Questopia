import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/helpers/sheet_helper.dart';
import '../../providers/game_engine_provider.dart';
import 'cheat_modes_sheet.dart';
import 'save_slots_sheet.dart';

class GameOptionsSheet extends ConsumerWidget {
  const GameOptionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QuestopiaSheetHeaderPill(title: 'Game Options'),
          const SizedBox(height: 8),
          SegmentedListSection(
            children: [
              SegmentedListTile(
                leading: const Icon(Icons.save_outlined, size: 22),
                title: const Text('Save and Load', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                onTap: () {
                  Navigator.pop(context);
                  showQuestopiaSheet<void>(
                    context: context,
                    builder: (_) => const SaveSlotsSheet(),
                  );
                },
              ),
              SegmentedListTile(
                leading: const Icon(Icons.tune_rounded, size: 22),
                title: const Text('Cheat Engine', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                onTap: () {
                  Navigator.pop(context);
                  showQuestopiaSheet<void>(
                    context: context,
                    builder: (_) => const CheatModesSheet(),
                  );
                },
              ),
              SegmentedListTile(
                leading: const Icon(Icons.restart_alt_rounded, size: 22),
                title: const Text('Restart Game', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(gameEngineProvider.notifier).showRestartConfirmation();
                },
              ),
              SegmentedListTile(
                leading: const Icon(Icons.terminal_rounded, size: 22),
                title: const Text('QSP Console', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(gameEngineProvider.notifier).showExecutor();
                },
              ),
              SegmentedListTile(
                leading: const Icon(Icons.file_open_outlined, size: 22),
                title: const Text('Open Save File', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(gameEngineProvider.notifier).showFileLoad();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
