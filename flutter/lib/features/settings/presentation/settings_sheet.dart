import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/path_picker_helper.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static const _typefaceNames = [
    'Default System',
    'Sans-Serif',
    'Serif',
    'Monospace',
    'Medium',
    'Cursive',
    'Condensed',
  ];

  static const _actionsHeightRatios = ['1/5', '1/4', '1/3', '1/2', '2/3'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Settings & Preferences',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    // Section 1: Appearance & Theme
                    _sectionHeader(context, 'Appearance & Theme'),
                    SegmentedButton<ThemeModeOption>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeModeOption.system,
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeModeOption.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeModeOption.dark,
                          label: Text('Dark'),
                        ),
                        ButtonSegment(
                          value: ThemeModeOption.amoled,
                          label: Text('AMOLED'),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (value) {
                        notifier.setThemeMode(value.first);
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Square Poster Cards'),
                      subtitle: const Text('Use square aspect ratio for library game cards'),
                      value: settings.isSquarePosters,
                      onChanged: (val) => notifier.setSquarePosters(val),
                    ),

                    const Divider(height: 24),

                    // Section 2: Typography & Text
                    _sectionHeader(context, 'Typography & Font'),
                    ListTile(
                      title: Text('Font Size: ${settings.fontSize.toStringAsFixed(0)} pt'),
                      subtitle: Slider(
                        value: settings.fontSize,
                        min: 12.0,
                        max: 28.0,
                        divisions: 8,
                        onChanged: (val) => notifier.setFontSize(val),
                      ),
                    ),
                    ListTile(
                      title: const Text('Typeface Style'),
                      subtitle: Text(_typefaceNames[settings.typefaceIndex.clamp(0, _typefaceNames.length - 1)]),
                      trailing: DropdownButton<int>(
                        value: settings.typefaceIndex.clamp(0, _typefaceNames.length - 1),
                        items: List.generate(
                          _typefaceNames.length,
                          (i) => DropdownMenuItem(value: i, child: Text(_typefaceNames[i])),
                        ),
                        onChanged: (val) {
                          if (val != null) notifier.setTypefaceIndex(val);
                        },
                      ),
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Use Game Font'),
                      subtitle: const Text('Allow QSP game code to specify custom fonts'),
                      value: settings.isUseGameFont,
                      onChanged: (val) => notifier.setUseGameFont(val),
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Auto-Scroll'),
                      subtitle: const Text('Automatically scroll to new text in game view'),
                      value: settings.isUseAutoscroll,
                      onChanged: (val) => notifier.setAutoscroll(val),
                    ),

                    const Divider(height: 24),

                    // Section 3: Media & Graphics
                    _sectionHeader(context, 'Media & Images'),
                    SwitchListTile.adaptive(
                      title: const Text('Pinch Zoom in Game View'),
                      subtitle: const Text('Allow zooming in game description'),
                      value: settings.isPinchZoomEnabled,
                      onChanged: (val) => notifier.setPinchZoom(val),
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Disable Image Rendering'),
                      subtitle: const Text('Hide image tags for text-only mode'),
                      value: settings.isImageDisabled,
                      onChanged: (val) => notifier.setImageDisabled(val),
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Fullscreen Image Viewer'),
                      subtitle: const Text('Tap image to view in fullscreen dialog'),
                      value: settings.isFullscreenImages,
                      onChanged: (val) => notifier.setFullscreenImages(val),
                    ),

                    const Divider(height: 24),

                    // Section 4: Sound & Audio
                    _sectionHeader(context, 'Sound & Audio'),
                    SwitchListTile.adaptive(
                      title: const Text('Enable Sound'),
                      subtitle: const Text('Play background music and QSP audio effects'),
                      value: settings.isSoundEnabled,
                      onChanged: (val) => notifier.setSoundEnabled(val),
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Mute Video Audio'),
                      subtitle: const Text('Mute audio track during video playback'),
                      value: settings.isVideoMute,
                      onChanged: (val) => notifier.setVideoMute(val),
                    ),

                    const Divider(height: 24),

                    // Section 5: Engine & Game Layout
                    _sectionHeader(context, 'Engine & Game Layout'),
                    ListTile(
                      title: const Text('Actions Panel Height Ratio'),
                      subtitle: Text(settings.actionsHeightRatio),
                      trailing: DropdownButton<String>(
                        value: settings.actionsHeightRatio,
                        items: _actionsHeightRatios
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) notifier.setActionsHeightRatio(val);
                        },
                      ),
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Auto-Save Game State'),
                      subtitle: const Text('Save session automatically'),
                      value: settings.isAutosaveEnabled,
                      onChanged: (val) => notifier.setAutosave(val),
                    ),
                    if (settings.isAutosaveEnabled)
                      ListTile(
                        title: Text('Auto-Save Click Interval: ${settings.autosaveInterval} clicks'),
                        subtitle: Slider(
                          value: settings.autosaveInterval.toDouble(),
                          min: 10,
                          max: 100,
                          divisions: 9,
                          onChanged: (val) => notifier.setAutosaveInterval(val.toInt()),
                        ),
                      ),
                    SwitchListTile.adaptive(
                      title: const Text('Enable Cheat Engine'),
                      subtitle: const Text('Allow variable modification in options drawer'),
                      value: settings.isCheatsEnabled,
                      onChanged: (val) => notifier.setCheatsEnabled(val),
                    ),

                    const Divider(height: 24),

                    // Section 6: Games Directory
                    _sectionHeader(context, 'Games Directory'),
                    ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: const Text('Games Folder'),
                      subtitle: Text(
                        settings.gamesDirectory.isNotEmpty
                            ? settings.gamesDirectory
                            : 'Default internal app folder (/Questopia/games)',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.drive_file_move_outlined),
                        tooltip: 'Select Directory',
                        onPressed: () async {
                          final selected = await PathPickerHelper.pickDirectory(
                            context,
                            currentPath: settings.gamesDirectory,
                          );
                          if (selected != null && selected.isNotEmpty) {
                            await notifier.setGamesDirectory(selected);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
