import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            SegmentedButton<ThemeModeOption>(
              segments: const [
                ButtonSegment(
                    value: ThemeModeOption.system, label: Text('System')),
                ButtonSegment(
                    value: ThemeModeOption.light, label: Text('Light')),
                ButtonSegment(
                    value: ThemeModeOption.dark, label: Text('Dark')),
                ButtonSegment(
                    value: ThemeModeOption.amoled, label: Text('AMOLED')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) {
                notifier.setThemeMode(value.first);
              },
            ),
            const SizedBox(height: 16),
            Text('Font Size: ${settings.fontSize.toStringAsFixed(0)} pt'),
            Slider(
              value: settings.fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              onChanged: (value) {
                notifier.setFontSize(value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Game Directory'),
              subtitle: Text(
                settings.gamesDirectory.isNotEmpty
                    ? settings.gamesDirectory
                    : 'Default internal directory',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.drive_file_move_outlined),
                onPressed: () async {
                  final selectedDir =
                      await FilePicker.platform.getDirectoryPath();
                  if (selectedDir != null) {
                    await notifier.setGamesDirectory(selectedDir);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
