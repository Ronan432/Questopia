import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_engine_provider.dart';

class SaveSlotsSheet extends ConsumerStatefulWidget {
  const SaveSlotsSheet({super.key});

  @override
  ConsumerState<SaveSlotsSheet> createState() => _SaveSlotsSheetState();
}

class _SaveSlotsSheetState extends ConsumerState<SaveSlotsSheet> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(gameEngineProvider);
    final engineNotifier = ref.read(gameEngineProvider.notifier);

    final startSlot = _page * 6;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saves & Slots',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.autorenew_rounded),
                  title: const Text('Auto-Save'),
                  subtitle: Text(
                    engineState.autoSaveData != null
                        ? 'Last saved session available'
                        : 'No auto-save available',
                  ),
                  trailing: engineState.autoSaveData != null
                      ? FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(context);
                            engineNotifier.loadFromSlot(-1);
                          },
                          child: const Text('Load'),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final slotIndex = startSlot + index;
                    final hasData = engineState.saveSlots.containsKey(slotIndex);

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${slotIndex + 1}'),
                        ),
                        title: Text('Slot ${slotIndex + 1}'),
                        subtitle: Text(hasData ? 'Saved Game State' : 'Empty Slot'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasData)
                              IconButton(
                                icon: const Icon(Icons.play_arrow_rounded),
                                tooltip: 'Load Slot',
                                onPressed: () {
                                  Navigator.pop(context);
                                  engineNotifier.loadFromSlot(slotIndex);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.save_outlined),
                              tooltip: 'Save Slot',
                              onPressed: () {
                                engineNotifier.saveToSlot(slotIndex);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Saved to Slot ${slotIndex + 1}'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _page == 0 ? null : () => setState(() => _page--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(child: Text('Page ${_page + 1} / 10')),
                  ),
                  IconButton(
                    onPressed: _page == 9 ? null : () => setState(() => _page++),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['sav'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          // Import save file
                        }
                      },
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Import .sav'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Export save file
                      },
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Export .sav'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
