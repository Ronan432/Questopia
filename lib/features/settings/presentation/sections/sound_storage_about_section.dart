import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_segmented_list/material_segmented_list.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/helpers/path_picker_helper.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../widgets/settings_tile_builders.dart';

/// Sound settings section.
class SoundSection extends StatelessWidget {
  const SoundSection({
    super.key,
    required this.settings,
    required this.notifier,
  });

  final SettingsState settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SettingsSectionHeader(title: l10n.sectionSound),
        SegmentedListSection(
          children: [
            SettingsTiles.switchTile(
              icon: Icons.volume_up_outlined,
              title: l10n.playSound,
              value: settings.isSoundEnabled,
              onChanged: notifier.setSoundEnabled,
            ),
            SettingsTiles.switchTile(
              icon: Icons.volume_off_outlined,
              title: l10n.muteVideoAudio,
              value: settings.isVideoMute,
              onChanged: notifier.setVideoMute,
            ),
          ],
        ),
      ],
    );
  }
}

/// Storage folder settings section.
class StorageSection extends StatelessWidget {
  const StorageSection({
    super.key,
    required this.settings,
    required this.notifier,
  });

  final SettingsState settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SettingsSectionHeader(title: l10n.sectionStorage),
        SegmentedListSection(
          children: [
            SegmentedListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(l10n.gamesFolder),
              subtitle: Text(
                settings.gamesDirectory.isNotEmpty
                    ? settings.gamesDirectory
                    : l10n.defaultInternalFolder,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              minVerticalPadding: 12,
              onTap: () async {
                final selected = await PathPickerHelper.pickDirectory(
                  context,
                  currentPath: settings.gamesDirectory,
                );
                if (selected != null && selected.isNotEmpty) {
                  await notifier.setGamesDirectory(selected);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// About, version and open source licenses section.
class AboutSection extends StatelessWidget {
  const AboutSection({
    super.key,
    required this.settings,
    required this.notifier,
    required this.packageInfo,
  });

  final SettingsState settings;
  final SettingsNotifier notifier;
  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = packageInfo;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SettingsSectionHeader(title: l10n.sectionAbout),
        SegmentedListSection(
          children: [
            SegmentedListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.version),
              trailing: Text(
                info == null ? '...' : '${info.version}+${info.buildNumber}',
              ),
              minVerticalPadding: 12,
            ),
            SegmentedListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.openSourceLicenses),
              trailing: const Icon(Icons.chevron_right),
              minVerticalPadding: 12,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Questopia',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
