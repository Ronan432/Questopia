import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../sheets/settings_picker_sheets.dart';
import '../widgets/settings_tile_builders.dart';

/// Appearance settings section (theme, colors, language).
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    super.key,
    required this.settings,
    required this.notifier,
  });

  final SettingsState settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentLabels = SettingsPickerSheets.accentLabels(context);
    final accentColors = SettingsPickerSheets.accentColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SegmentedListSection(
          children: [
            SettingsTiles.navTile(
              context,
              icon: Icons.brightness_6_outlined,
              title: l10n.theme,
              value: SettingsPickerSheets.themeLabel(context, settings.themeMode),
              onTap: () => SettingsPickerSheets.showThemeModePicker(
                context,
                notifier,
                settings,
              ),
            ),
            SettingsTiles.navTile(
              context,
              icon: Icons.palette_outlined,
              title: l10n.colorAccent,
              value: accentLabels[settings.themeColor] ?? l10n.accentDynamic,
              leadingDot: accentColors[settings.themeColor],
              onTap: () => SettingsPickerSheets.showAccentPicker(
                context,
                notifier,
                settings,
              ),
            ),
            SettingsTiles.navTile(
              context,
              icon: Icons.language_outlined,
              title: l10n.language,
              value: SettingsPickerSheets.languageOptions(context)
                  .firstWhere(
                    (option) => option.$1 == settings.language,
                    orElse: () => ('system', l10n.followSystem),
                  )
                  .$2,
              onTap: () => SettingsPickerSheets.showLanguagePicker(
                context,
                notifier,
                settings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// General behavior and gameplay settings section.
class GeneralSection extends StatelessWidget {
  const GeneralSection({
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SegmentedListSection(
          children: [
            SettingsTiles.switchTile(
              icon: Icons.fullscreen_outlined,
              title: l10n.immersiveMode,
              value: settings.isImmersiveMode,
              onChanged: notifier.setImmersiveMode,
            ),
            SettingsTiles.switchTile(
              icon: Icons.vertical_align_bottom_outlined,
              title: l10n.autoscroll,
              value: settings.isUseAutoscroll,
              onChanged: notifier.setAutoscroll,
            ),
            SettingsTiles.switchTile(
              icon: Icons.table_rows_outlined,
              title: l10n.separatorLine,
              value: settings.isUseSeparator,
              onChanged: notifier.setSeparator,
            ),
            if (defaultTargetPlatform == TargetPlatform.android) ...[
              SettingsTiles.switchTile(
                icon: Icons.blur_on_outlined,
                title: l10n.navBarBlur,
                value: settings.isNavBarBlur,
                onChanged: notifier.setNavBarBlur,
              ),
              if (settings.isNavBarBlur)
                SettingsTiles.sliderTile(
                  icon: Icons.blur_linear_outlined,
                  label:
                      '${l10n.navBarBlur}: ${settings.navBarBlurPercent.round()}%',
                  value: settings.navBarBlurPercent,
                  min: 10,
                  max: 100,
                  divisions: 18,
                  onChanged: notifier.setNavBarBlurPercent,
                ),
            ],
            SettingsTiles.switchTile(
              icon: Icons.save_outlined,
              title: l10n.autoSave,
              value: settings.isAutosaveEnabled,
              onChanged: notifier.setAutosave,
            ),
            if (settings.isAutosaveEnabled)
              SettingsTiles.sliderTile(
                icon: Icons.timer_outlined,
                label:
                    '${l10n.autoSaveInterval}: ${settings.autosaveInterval} ${l10n.clicks}',
                value: settings.autosaveInterval.toDouble(),
                min: 10,
                max: 100,
                divisions: 9,
                onChanged: (value) =>
                    notifier.setAutosaveInterval(value.round()),
              ),
            SettingsTiles.switchTile(
              icon: Icons.security_outlined,
              title: l10n.cheatEngine,
              value: settings.isCheatsEnabled,
              onChanged: notifier.setCheatsEnabled,
            ),
            SettingsTiles.switchTile(
              icon: Icons.terminal_outlined,
              title: l10n.qspCommandLine,
              value: settings.isExecStringEnabled,
              onChanged: notifier.setExecStringEnabled,
            ),
            SettingsTiles.navTile(
              context,
              icon: Icons.height_outlined,
              title: l10n.actionsPanelHeight,
              value: settings.actionsHeightRatio,
              onTap: () => SettingsPickerSheets.showActionsHeightPicker(
                context,
                notifier,
                settings,
              ),
            ),
            SettingsTiles.navTile(
              context,
              icon: Icons.memory_outlined,
              title: l10n.binaryPrefixes,
              value: settings.binaryPrefixes == 1024 ? '1024' : '1000',
              onTap: () => SettingsPickerSheets.showBinaryPrefixesPicker(
                context,
                notifier,
                settings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
