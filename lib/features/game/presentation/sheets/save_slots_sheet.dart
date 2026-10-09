import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/theme/questopia_theme.dart';
import '../../providers/game_engine_provider.dart';

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

    return M3ETheme(
      data: M3EThemeData(
        colorScheme: QuestopiaTheme.m3eColorSchemeFrom(themeColors),
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Category Mode Tabs
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saves & Slots',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: themeColors.primary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Top Category Mode Tabs (Save / Load) with M3E Morph Shaping
                Row(
                  children: [
                    Expanded(
                      child: M3EButton.icon(
                        onPressed: () => setState(() => _selectedTab = 0),
                        size: M3EButtonSize.md,
                        style: isSaveMode
                            ? M3EButtonStyle.filled
                            : M3EButtonStyle.outlined,
                        icon: const Icon(Icons.save_outlined, size: 20),
                        label: const Text('Save Game'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: M3EButton.icon(
                        onPressed: () => setState(() => _selectedTab = 1),
                        size: M3EButtonSize.md,
                        style: !isSaveMode
                            ? M3EButtonStyle.filled
                            : M3EButtonStyle.outlined,
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Load Game'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Content Body based on Mode Tab
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auto-Save Card (Load Mode only)
                        if (!isSaveMode) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              'Auto-Save Session',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: themeColors.primary,
                                  ),
                            ),
                          ),
                          SegmentedListSection(
                            children: [
                              SegmentedListTile(
                                leading: Icon(
                                  Icons.autorenew_rounded,
                                  color: themeColors.primary,
                                ),
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
                                        icon: const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 18),
                                        label: const Text('Load'),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Manual Slots Section Header
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            isSaveMode
                                ? 'Select Slot to Save'
                                : 'Select Slot to Load',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: themeColors.primary,
                                ),
                          ),
                        ),

                        // Segmented Card for Manual Slots
                        SegmentedListSection(
                          children: List.generate(6, (index) {
                            final slotIndex = startSlot + index;
                            final hasData =
                                engineState.saveSlots.containsKey(slotIndex);

                            return SegmentedListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasData
                                    ? themeColors.primaryContainer
                                    : themeColors.surfaceContainerHigh,
                                child: Text(
                                  '${slotIndex + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: hasData
                                        ? themeColors.onPrimaryContainer
                                        : themeColors.outline,
                                  ),
                                ),
                              ),
                              title: Text('Slot ${slotIndex + 1}'),
                              subtitle: Text(
                                hasData ? 'Saved Game State' : 'Empty Slot',
                                style: TextStyle(
                                  color: hasData
                                      ? themeColors.onSurface
                                      : themeColors.outline,
                                ),
                              ),
                              trailing: isSaveMode
                                  ? M3EButton.icon(
                                      onPressed: () {
                                        engineNotifier.saveToSlot(slotIndex);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Saved game to Slot ${slotIndex + 1}'),
                                          ),
                                        );
                                      },
                                      size: M3EButtonSize.sm,
                                      style: hasData
                                          ? M3EButtonStyle.outlined
                                          : M3EButtonStyle.filled,
                                      icon: const Icon(Icons.save_outlined,
                                          size: 18),
                                      label:
                                          Text(hasData ? 'Overwrite' : 'Save'),
                                    )
                                  : (hasData
                                      ? M3EButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            engineNotifier
                                                .loadFromSlot(slotIndex);
                                          },
                                          size: M3EButtonSize.sm,
                                          style: M3EButtonStyle.filled,
                                          icon: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 18),
                                          label: const Text('Load'),
                                        )
                                      : null),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Page Navigation Bar
                Row(
                  children: [
                    M3EButton.icon(
                      onPressed:
                          _page == 0 ? null : () => setState(() => _page--),
                      size: M3EButtonSize.sm,
                      style: M3EButtonStyle.outlined,
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      label: const Text('Prev'),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Page ${_page + 1} / 10',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                    M3EButton.icon(
                      onPressed:
                          _page == 9 ? null : () => setState(() => _page++),
                      size: M3EButtonSize.sm,
                      style: M3EButtonStyle.outlined,
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      label: const Text('Next'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // External .sav Import / Export Actions
                Row(
                  children: [
                    Expanded(
                      child: M3EButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['sav'],
                          );
                          final path = result?.files.singleOrNull?.path;
                          if (path != null && path.isNotEmpty) {
                            final ok =
                                await engineNotifier.importSaveFile(path);
                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Save file imported successfully'
                                      : 'Failed to import save file'),
                                ),
                              );
                            }
                          }
                        },
                        size: M3EButtonSize.sm,
                        style: M3EButtonStyle.outlined,
                        icon: const Icon(Icons.file_upload_outlined, size: 18),
                        label: const Text('Import .sav'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: M3EButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final bytes = engineNotifier.takeSaveSnapshot();
                          if (bytes == null || bytes.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('No active save data to export')),
                            );
                            return;
                          }
                          final result = await FilePicker.platform.saveFile(
                            dialogTitle: 'Export Save File',
                            fileName: 'game_save.sav',
                            type: FileType.custom,
                            allowedExtensions: ['sav'],
                          );
                          if (result != null && result.isNotEmpty) {
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Save file exported')),
                              );
                            }
                          }
                        },
                        size: M3EButtonSize.sm,
                        style: M3EButtonStyle.outlined,
                        icon:
                            const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('Export .sav'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
