import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_segmented_list/material_segmented_list.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/questopia_theme.dart';
import '../../../core/helpers/path_picker_helper.dart';
import '../../../core/widgets/questopia_scaffold.dart';
import 'sheets/settings_picker_sheets.dart';
import 'widgets/setting_tiles.dart';

/// %100 eşitleme modu: tüm platformlarda aynı Material Expressive
/// segmented ayar ekranı. Platform dalı yok.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.isInline = false});

  final bool isInline;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {
      // Platform channel unavailable (e.g. in tests) - keep the placeholder.
    }
  }

  List<String> _sections(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.sectionAppearance,
      l10n.sectionGeneral,
      l10n.sectionTypography,
      l10n.sectionMedia,
      l10n.sectionSound,
      l10n.sectionStorage,
      l10n.sectionAbout,
    ];
  }

  static const _sectionIcons = <IconData>[
    Icons.palette_outlined,
    Icons.settings_outlined,
    Icons.text_fields_outlined,
    Icons.image_outlined,
    Icons.volume_up_outlined,
    Icons.folder_outlined,
    Icons.info_outline,
  ];

  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final allItems = _buildAllItems(context, settings, notifier);
    final sectionedItems = _splitBySections(allItems);

    final content = Column(
      children: [
        _buildCategoryButtons(context),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: sectionedItems.length > _selectedSection
                    ? sectionedItems[_selectedSection]
                    : [],
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isInline) {
      return M3ETheme(
        data: M3EThemeData(
          colorScheme: QuestopiaTheme.m3eColorSchemeFrom(theme.colorScheme),
        ),
        child: content,
      );
    }

    return M3ETheme(
      data: M3EThemeData(
        colorScheme: QuestopiaTheme.m3eColorSchemeFrom(theme.colorScheme),
      ),
      child: QuestopiaScaffold.simple(
        title: l10n.settings,
        body: content,
      ),
    );
  }

  Widget _buildCategoryButtons(BuildContext context) {
    final sections = _sections(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              showCheckmark: false,
              avatar: Icon(_sectionIcons[i], size: 18),
              label: Text(sections[i]),
              selected: _selectedSection == i,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_selectedSection == i ? 24 : 8),
              ),
              onSelected: (_) {
                HapticFeedback.lightImpact();
                setState(() => _selectedSection = i);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Splits a flat list of setting widgets into per-section sub-lists.
  List<List<Widget>> _splitBySections(List<Widget> items) {
    final result = <List<Widget>>[];
    var current = <Widget>[];
    for (final item in items) {
      if (item is _SectionHeaderWidget) {
        if (current.isNotEmpty) {
          result.add(current);
          current = [];
        }
        current.add(item);
      } else {
        current.add(item);
      }
    }
    if (current.isNotEmpty) result.add(current);
    return result;
  }

  List<Widget> _buildAllItems(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final accentLabels = SettingsPickerSheets.accentLabels(context);
    final accentColors = SettingsPickerSheets.accentColors;
    final typefaces = SettingsPickerSheets.typefaceNames(context);

    return [
      _sectionHeader(context, l10n.sectionAppearance),
      SegmentedListSection(
        children: [
          _navTile(
            context,
            icon: Icons.brightness_6_outlined,
            title: l10n.theme,
            value:
                SettingsPickerSheets.themeLabel(context, settings.themeMode),
            onTap: () => SettingsPickerSheets.showThemeModePicker(
                context, notifier, settings),
          ),
          _navTile(
            context,
            icon: Icons.palette_outlined,
            title: l10n.colorAccent,
            value: accentLabels[settings.themeColor] ?? l10n.accentDynamic,
            leadingDot: accentColors[settings.themeColor],
            onTap: () => SettingsPickerSheets.showAccentPicker(
                context, notifier, settings),
          ),
          _navTile(
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
                context, notifier, settings),
          ),
        ],
      ),
      _sectionHeader(context, l10n.sectionGeneral),
      SegmentedListSection(
        children: [
          _switchTile(
            icon: Icons.fullscreen_outlined,
            title: l10n.immersiveMode,
            value: settings.isImmersiveMode,
            onChanged: notifier.setImmersiveMode,
          ),
          _switchTile(
            icon: Icons.vertical_align_bottom_outlined,
            title: l10n.autoscroll,
            value: settings.isUseAutoscroll,
            onChanged: notifier.setAutoscroll,
          ),
          _switchTile(
            icon: Icons.table_rows_outlined,
            title: l10n.separatorLine,
            value: settings.isUseSeparator,
            onChanged: notifier.setSeparator,
          ),
          if (defaultTargetPlatform == TargetPlatform.android) ...[
            _switchTile(
              icon: Icons.blur_on_outlined,
              title: l10n.navBarBlur,
              value: settings.isNavBarBlur,
              onChanged: notifier.setNavBarBlur,
            ),
            if (settings.isNavBarBlur)
              _sliderTile(
                icon: Icons.blur_linear_outlined,
                label: '${l10n.navBarBlur}: ${settings.navBarBlurPercent.round()}%',
                value: settings.navBarBlurPercent,
                min: 10,
                max: 100,
                divisions: 18,
                onChanged: notifier.setNavBarBlurPercent,
              ),
          ],
          _switchTile(
            icon: Icons.save_outlined,
            title: l10n.autoSave,
            value: settings.isAutosaveEnabled,
            onChanged: notifier.setAutosave,
          ),
          if (settings.isAutosaveEnabled)
            _sliderTile(
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
          _switchTile(
            icon: Icons.security_outlined,
            title: l10n.cheatEngine,
            value: settings.isCheatsEnabled,
            onChanged: notifier.setCheatsEnabled,
          ),
          _switchTile(
            icon: Icons.terminal_outlined,
            title: l10n.qspCommandLine,
            value: settings.isExecStringEnabled,
            onChanged: notifier.setExecStringEnabled,
          ),
          _navTile(
            context,
            icon: Icons.height_outlined,
            title: l10n.actionsPanelHeight,
            value: settings.actionsHeightRatio,
            onTap: () => SettingsPickerSheets.showActionsHeightPicker(
                context, notifier, settings),
          ),
          _navTile(
            context,
            icon: Icons.memory_outlined,
            title: l10n.binaryPrefixes,
            value: settings.binaryPrefixes == 1024 ? '1024' : '1000',
            onTap: () => SettingsPickerSheets.showBinaryPrefixesPicker(
                context, notifier, settings),
          ),
        ],
      ),
      _sectionHeader(context, l10n.sectionTypography),
      SegmentedListSection(
        children: [
          _sliderTile(
            icon: Icons.format_size_outlined,
            label:
                '${l10n.fontSize}: ${settings.fontSize.toStringAsFixed(0)} pt',
            value: settings.fontSize,
            min: 12,
            max: 28,
            divisions: 8,
            onChanged: notifier.setFontSize,
          ),
          _navTile(
            context,
            icon: Icons.style_outlined,
            title: l10n.typeface,
            value: typefaces[settings.typefaceIndex
                .clamp(0, typefaces.length - 1)],
            onTap: () => SettingsPickerSheets.showTypefacePicker(
                context, notifier, settings),
          ),
          _switchTile(
            icon: Icons.text_fields_outlined,
            title: l10n.useGameFont,
            value: settings.isUseGameFont,
            onChanged: notifier.setUseGameFont,
          ),
          _switchTile(
            icon: Icons.format_color_text_outlined,
            title: l10n.customTextColor,
            value: settings.useGameTextColor,
            onChanged: notifier.setUseGameTextColor,
          ),
          if (settings.useGameTextColor)
            _customTile(
              child: ColorRow(
                label: l10n.textColor,
                color: Color(settings.gameTextColor),
                onPick: (color) =>
                    notifier.setGameTextColor(color.toARGB32()),
              ),
            ),
          _switchTile(
            icon: Icons.format_color_fill_outlined,
            title: l10n.customBackgroundColor,
            value: settings.useGameBackgroundColor,
            onChanged: notifier.setUseGameBackgroundColor,
          ),
          if (settings.useGameBackgroundColor)
            _customTile(
              child: ColorRow(
                label: l10n.backgroundColor,
                color: Color(settings.gameBackColor),
                onPick: (color) =>
                    notifier.setGameBackColor(color.toARGB32()),
              ),
            ),
          _switchTile(
            icon: Icons.link_outlined,
            title: l10n.customLinkColor,
            value: settings.useGameLinkColor,
            onChanged: notifier.setUseGameLinkColor,
          ),
          if (settings.useGameLinkColor)
            _customTile(
              child: ColorRow(
                label: l10n.linkColor,
                color: Color(settings.gameLinkColor),
                onPick: (color) =>
                    notifier.setGameLinkColor(color.toARGB32()),
              ),
            ),
        ],
      ),
      _sectionHeader(context, l10n.sectionMedia),
      SegmentedListSection(
        children: [
          _switchTile(
            icon: Icons.hide_image_outlined,
            title: l10n.disableImages,
            value: settings.isImageDisabled,
            onChanged: notifier.setImageDisabled,
          ),
          _switchTile(
            icon: Icons.image_outlined,
            title: l10n.showAllImagesDialog,
            value: settings.isImagesInDialogEnabled,
            onChanged: notifier.setImagesInDialog,
          ),
          _switchTile(
            icon: Icons.zoom_in_outlined,
            title: l10n.pinchZoom,
            value: settings.isPinchZoomEnabled,
            onChanged: notifier.setPinchZoom,
          ),
          _switchTile(
            icon: Icons.fullscreen_outlined,
            title: l10n.fullscreenImages,
            value: settings.isFullscreenImages,
            onChanged: notifier.setFullscreenImages,
          ),
          _switchTile(
            icon: Icons.width_full_outlined,
            title: l10n.autoWidth,
            value: settings.isAutoWidth,
            onChanged: notifier.setAutoWidth,
          ),
          if (!settings.isAutoWidth)
            _sliderTile(
              icon: Icons.width_normal_outlined,
              label: '${l10n.imageWidth}: ${settings.customWidthImage} px',
              value: settings.customWidthImage.toDouble(),
              min: 100,
              max: 2000,
              divisions: 19,
              onChanged: (value) =>
                  notifier.setCustomWidthImage(value.round()),
            ),
          _switchTile(
            icon: Icons.height_outlined,
            title: l10n.autoHeight,
            value: settings.isAutoHeight,
            onChanged: notifier.setAutoHeight,
          ),
          if (!settings.isAutoHeight)
            _sliderTile(
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
      _sectionHeader(context, l10n.sectionSound),
      SegmentedListSection(
        children: [
          _switchTile(
            icon: Icons.volume_up_outlined,
            title: l10n.playSound,
            value: settings.isSoundEnabled,
            onChanged: notifier.setSoundEnabled,
          ),
          _switchTile(
            icon: Icons.volume_off_outlined,
            title: l10n.muteVideoAudio,
            value: settings.isVideoMute,
            onChanged: notifier.setVideoMute,
          ),
        ],
      ),
      _sectionHeader(context, l10n.sectionStorage),
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
      _sectionHeader(context, l10n.sectionAbout),
      SegmentedListSection(
        children: [
          SegmentedListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            trailing: Text(
              _packageInfo == null
                  ? '...'
                  : '${_packageInfo!.version}+${_packageInfo!.buildNumber}',
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
    ];
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return _SectionHeaderWidget(title: title);
  }

  SegmentedListTile _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    Color? leadingDot,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SegmentedListTile(
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: leadingDot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
      minVerticalPadding: 18,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  SegmentedListTile _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SegmentedListTile(
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: M3ESwitch(
        value: value,
        selectedIcon: const Icon(Icons.check, size: 16),
        onChanged: (val) {
          HapticFeedback.lightImpact();
          onChanged(val);
        },
      ),
      minVerticalPadding: 18,
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
    );
  }

  SegmentedListTile _sliderTile({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int? divisions,
  }) {
    return SegmentedListTile(
      leading: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icon, size: 24),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackShape: const RoundedRectSliderTrackShape(),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
      minVerticalPadding: 16,
    );
  }

  SegmentedListTile _customTile({required Widget child}) {
    return SegmentedListTile(
      title: child,
      minVerticalPadding: 16,
    );
  }
}

/// A typed sentinel widget used by [_SettingsScreenState._splitBySections]
/// to detect section boundaries, and also renders the section header text.
class _SectionHeaderWidget extends StatelessWidget {
  const _SectionHeaderWidget({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
