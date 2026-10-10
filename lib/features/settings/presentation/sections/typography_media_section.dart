import 'package:flutter/material.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../sheets/settings_picker_sheets.dart';
import '../widgets/setting_tiles.dart';
import '../widgets/settings_tile_builders.dart';

/// Typography and font personalization settings section.
class TypographySection extends StatelessWidget {
  const TypographySection({
    super.key,
    required this.settings,
    required this.notifier,
  });

  final SettingsState settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typefaces = SettingsPickerSheets.typefaceNames(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SegmentedListSection(
          children: [
            SettingsTiles.sliderTile(
              icon: Icons.format_size_outlined,
              label:
                  '${l10n.fontSize}: ${settings.fontSize.toStringAsFixed(0)} pt',
              value: settings.fontSize,
              min: 12,
              max: 28,
              divisions: 8,
              onChanged: notifier.setFontSize,
            ),
            SettingsTiles.navTile(
              context,
              icon: Icons.style_outlined,
              title: l10n.typeface,
              value: typefaces[
                  settings.typefaceIndex.clamp(0, typefaces.length - 1)],
              onTap: () => SettingsPickerSheets.showTypefacePicker(
                context,
                notifier,
                settings,
              ),
            ),
            SettingsTiles.switchTile(
              icon: Icons.text_fields_outlined,
              title: l10n.useGameFont,
              value: settings.isUseGameFont,
              onChanged: notifier.setUseGameFont,
            ),
            SettingsTiles.switchTile(
              icon: Icons.format_color_text_outlined,
              title: l10n.customTextColor,
              value: settings.useGameTextColor,
              onChanged: notifier.setUseGameTextColor,
            ),
            if (settings.useGameTextColor)
              SegmentedListTile(
                title: ColorRow(
                  label: l10n.textColor,
                  color: Color(settings.gameTextColor),
                  onPick: (color) =>
                      notifier.setGameTextColor(color.toARGB32()),
                ),
                minVerticalPadding: 16,
              ),
            SettingsTiles.switchTile(
              icon: Icons.format_color_fill_outlined,
              title: l10n.customBackgroundColor,
              value: settings.useGameBackgroundColor,
              onChanged: notifier.setUseGameBackgroundColor,
            ),
            if (settings.useGameBackgroundColor)
              SegmentedListTile(
                title: ColorRow(
                  label: l10n.backgroundColor,
                  color: Color(settings.gameBackColor),
                  onPick: (color) =>
                      notifier.setGameBackColor(color.toARGB32()),
                ),
                minVerticalPadding: 16,
              ),
            SettingsTiles.switchTile(
              icon: Icons.link_outlined,
              title: l10n.customLinkColor,
              value: settings.useGameLinkColor,
              onChanged: notifier.setUseGameLinkColor,
            ),
            if (settings.useGameLinkColor)
              SegmentedListTile(
                title: ColorRow(
                  label: l10n.linkColor,
                  color: Color(settings.gameLinkColor),
                  onPick: (color) =>
                      notifier.setGameLinkColor(color.toARGB32()),
                ),
                minVerticalPadding: 16,
              ),
          ],
        ),
      ],
    );
  }
}

/// Media and image display settings section.
class MediaSection extends StatelessWidget {
  const MediaSection({
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
              icon: Icons.hide_image_outlined,
              title: l10n.disableImages,
              value: settings.isImageDisabled,
              onChanged: notifier.setImageDisabled,
            ),
            SettingsTiles.switchTile(
              icon: Icons.image_outlined,
              title: l10n.showAllImagesDialog,
              value: settings.isImagesInDialogEnabled,
              onChanged: notifier.setImagesInDialog,
            ),
            SettingsTiles.switchTile(
              icon: Icons.zoom_in_outlined,
              title: l10n.pinchZoom,
              value: settings.isPinchZoomEnabled,
              onChanged: notifier.setPinchZoom,
            ),
            SettingsTiles.switchTile(
              icon: Icons.fullscreen_outlined,
              title: l10n.fullscreenImages,
              value: settings.isFullscreenImages,
              onChanged: notifier.setFullscreenImages,
            ),
            SettingsTiles.switchTile(
              icon: Icons.width_full_outlined,
              title: l10n.autoWidth,
              value: settings.isAutoWidth,
              onChanged: notifier.setAutoWidth,
            ),
            if (!settings.isAutoWidth)
              SettingsTiles.sliderTile(
                icon: Icons.width_normal_outlined,
                label: '${l10n.imageWidth}: ${settings.customWidthImage} px',
                value: settings.customWidthImage.toDouble(),
                min: 100,
                max: 2000,
                divisions: 19,
                onChanged: (value) =>
                    notifier.setCustomWidthImage(value.round()),
              ),
            SettingsTiles.switchTile(
              icon: Icons.height_outlined,
              title: l10n.autoHeight,
              value: settings.isAutoHeight,
              onChanged: notifier.setAutoHeight,
            ),
            if (!settings.isAutoHeight)
              SettingsTiles.sliderTile(
                icon: Icons.height_outlined,
                label: '${l10n.imageHeight}: ${settings.customHeightImage} px',
                value: settings.customHeightImage.toDouble(),
                min: 100,
                max: 2000,
                divisions: 19,
                onChanged: (value) =>
                    notifier.setCustomHeightImage(value.round()),
              ),
          ],
        ),
      ],
    );
  }
}
