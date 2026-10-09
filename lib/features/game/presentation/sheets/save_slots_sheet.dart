import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/helpers/sheet_helper.dart';
import '../../../../core/helpers/sheet_ui_helper.dart';
import '../../providers/game_engine_provider.dart';
import 'helpers/save_sheet_helper.dart';

class SaveSlotsSheet extends ConsumerStatefulWidget {
  const SaveSlotsSheet({super.key});

  @override
  ConsumerState<SaveSlotsSheet> createState() => _SaveSlotsSheetState();
}

class _SaveSlotsSheetState extends ConsumerState<SaveSlotsSheet> {
  int _selectedTab = 0; // 0: Save Mode, 1: Load Mode
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(gameEngineProvider);
    final engineNotifier = ref.read(gameEngineProvider.notifier);
    final themeColors = Theme.of(context).colorScheme;

    final startSlot = _page * 6;
    final isSaveMode = _selectedTab == 0;

    return QuestopiaSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QuestopiaSheetHeaderPill(title: 'Saves and Slots'),

          // Mode Tabs (Save / Load)
          Row(
            children: [
              Expanded(
                child: M3EButton.icon(
                  onPressed: () => setState(() => _selectedTab = 0),
                  size: M3EButtonSize.sm,
                  style: isSaveMode
                      ? M3EButtonStyle.filled
                      : M3EButtonStyle.outlined,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: M3EButton.icon(
                  onPressed: () => setState(() => _selectedTab = 1),
                  size: M3EButtonSize.sm,
                  style: !isSaveMode
                      ? M3EButtonStyle.filled
                      : M3EButtonStyle.outlined,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Load'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Content Body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSaveMode) ...[
                    _buildAutoSaveSection(engineState, engineNotifier, themeColors),
                    const SizedBox(height: 16),
                  ],

                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      isSaveMode ? 'Select Slot to Save' : 'Select Slot to Load',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: themeColors.primary,
                          ),
                    ),
                  ),

                  // Manual Slots
                  SegmentedListSection(
                    children: List.generate(6, (index) {
                      final slotIndex = startSlot + index;
                      final hasData = engineState.saveSlots.containsKey(slotIndex);
                      return _buildSlotTile(
                        slotIndex,
                        hasData,
                        isSaveMode,
                        engineNotifier,
                        themeColors,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Page Navigation Bar
          QuestopiaSheetPageNav(
            currentPage: _page,
            totalPages: 10,
            onPrev: _page == 0 ? null : () => setState(() => _page--),
            onNext: _page == 9 ? null : () => setState(() => _page++),
          ),

          const SizedBox(height: 12),

          // Import / Export Actions
          SaveImportExportRow(engineNotifier: engineNotifier),
        ],
      ),
    );
  }

  Widget _buildAutoSaveSection(
    GameEngineState engineState,
    GameEngineNotifier engineNotifier,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Auto-Save',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
          ),
        ),
        SegmentedListSection(
          children: [
            SegmentedListTile(
              leading: Icon(Icons.autorenew_rounded, color: colors.primary),
              title: const Text('Auto-Save Slot'),
              subtitle: Text(
                engineState.autoSaveData != null
                    ? 'Last saved session available'
                    : 'No auto-save data found',
              ),
              trailing: engineState.autoSaveData != null
                  ? M3EButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        engineNotifier.loadFromSlot(-1);
                      },
                      size: M3EButtonSize.sm,
                      style: M3EButtonStyle.tonal,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Load'),
                    )
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  SegmentedListTile _buildSlotTile(
    int slotIndex,
    bool hasData,
    bool isSaveMode,
    GameEngineNotifier engineNotifier,
    ColorScheme colors,
  ) {
    return SegmentedListTile(
      leading: CircleAvatar(
        backgroundColor:
            hasData ? colors.primaryContainer : colors.surfaceContainerHigh,
        child: Text(
          '${slotIndex + 1}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasData ? colors.onPrimaryContainer : colors.outline,
          ),
        ),
      ),
      title: Text('Slot ${slotIndex + 1}'),
      subtitle: Text(
        hasData ? 'Saved Game State' : 'Empty Slot',
        style: TextStyle(
          color: hasData ? colors.onSurface : colors.outline,
        ),
      ),
      trailing: isSaveMode
          ? M3EButton.icon(
              onPressed: () {
                engineNotifier.saveToSlot(slotIndex);
                showSheetSnackBar(context, 'Saved game to Slot ${slotIndex + 1}');
              },
              size: M3EButtonSize.sm,
              style: hasData ? M3EButtonStyle.outlined : M3EButtonStyle.filled,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(hasData ? 'Overwrite' : 'Save'),
            )
          : (hasData
              ? M3EButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    engineNotifier.loadFromSlot(slotIndex);
                  },
                  size: M3EButtonSize.sm,
                  style: M3EButtonStyle.filled,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Load'),
                )
              : null),
    );
  }
}
