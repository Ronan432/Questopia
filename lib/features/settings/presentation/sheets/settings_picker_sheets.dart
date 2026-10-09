import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/helpers/sheet_helper.dart';

abstract final class SettingsPickerSheets {
  static List<String> typefaceNames(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.fontDefaultSystem,
      l10n.fontSansSerif,
      l10n.fontSerif,
      l10n.fontMonospace,
      l10n.fontMedium,
      l10n.fontCursive,
      l10n.fontLight,
      l10n.fontCondensed,
      l10n.fontBlack,
      l10n.fontThin,
      l10n.fontCasual,
      l10n.fontSerifMonospace,
    ];
  }

  static const actionsHeightRatios = ['1/5', '1/4', '1/3', '1/2', '2/3'];

  static List<(String, String)> languageOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      ('system', l10n.followSystem),
      ('en', 'English'),
      ('ru', 'Русский'),
    ];
  }

  static Map<String, String> accentLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return {
      'dynamic': l10n.accentDynamic,
      'blue': l10n.accentBlue,
      'green': l10n.accentGreen,
      'orange': l10n.accentOrange,
      'purple': l10n.accentPurple,
      'pink': l10n.accentPink,
      'teal': l10n.accentTeal,
      'amber': l10n.accentAmber,
      'monochrome': l10n.accentMonochrome,
    };
  }

  static const accentColors = <String, Color>{
    'dynamic': Color(0xFF4D5F9F),
    'blue': Color(0xFF0061A4),
    'green': Color(0xFF2E6C38),
    'orange': Color(0xFF924C00),
    'purple': Color(0xFF77539D),
    'pink': Color(0xFF9B4061),
    'teal': Color(0xFF006A6A),
    'amber': Color(0xFFFBBD00),
    'monochrome': Color(0xFF757575),
  };

  static String themeLabel(BuildContext context, ThemeModeOption mode) {
    final l10n = AppLocalizations.of(context)!;
    return switch (mode) {
      ThemeModeOption.system => l10n.systemTheme,
      ThemeModeOption.light => l10n.lightTheme,
      ThemeModeOption.dark => l10n.darkTheme,
      ThemeModeOption.amoled => l10n.amoledTheme,
    };
  }

  static Future<void> showThemeModePicker(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsState settings,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    await showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  l10n.themeModeTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                ),
              ),
              SegmentedListSection(
                children: [
                  for (final mode in ThemeModeOption.values)
                    SegmentedListTile(
                      leading: Icon(
                        mode == settings.themeMode
                            ? Icons.brightness_auto_rounded
                            : Icons.brightness_4_outlined,
                        color:
                            mode == settings.themeMode ? colors.primary : null,
                      ),
                      title: Text(
                        themeLabel(context, mode),
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: mode == settings.themeMode
                          ? Icon(Icons.check_circle_rounded,
                              color: colors.primary)
                          : null,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await notifier.setThemeMode(mode);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showAccentPicker(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsState settings,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final labels = accentLabels(context);

    await showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  l10n.colorAccentTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                ),
              ),
              SegmentedListSection(
                children: [
                  for (final entry in labels.entries)
                    SegmentedListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColors[entry.key] ?? colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: entry.key == settings.themeColor
                                ? colors.primary
                                : colors.outlineVariant,
                            width: entry.key == settings.themeColor ? 3 : 1,
                          ),
                        ),
                      ),
                      title: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: entry.key == settings.themeColor
                          ? Icon(Icons.check_circle_rounded,
                              color: colors.primary)
                          : null,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await notifier.setThemeColor(entry.key);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showLanguagePicker(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsState settings,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final options = languageOptions(context);

    await showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  l10n.languageTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                ),
              ),
              SegmentedListSection(
                children: [
                  for (final option in options)
                    SegmentedListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: option.$1 == settings.language
                              ? colors.primaryContainer
                              : colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          option.$1.isEmpty ? 'AUTO' : option.$1.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: option.$1 == settings.language
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      title: Text(
                        option.$2,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: option.$1 == settings.language
                          ? Icon(Icons.check_circle_rounded,
                              color: colors.primary)
                          : null,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await notifier.setLanguage(option.$1);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showTypefacePicker(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsState settings,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final fonts = typefaceNames(context);

    await showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final activeIndex =
                settings.typefaceIndex.clamp(0, fonts.length - 1);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      l10n.typeface,
                      style: Theme.of(sheetCtx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                    ),
                  ),

                  // Live Text Preview Card
                  Card(
                    elevation: 0,
                    color: colors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.livePreview} (${fonts[activeIndex]})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.livePreviewText,
                            style: TextStyle(
                              fontSize: settings.fontSize,
                              fontFamily:
                                  activeIndex == 0 ? 'Netflix Sans' : null,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SegmentedListSection(
                    children: [
                      for (var i = 0; i < fonts.length; i++)
                        SegmentedListTile(
                          leading: Icon(
                            Icons.font_download_outlined,
                            color: i == activeIndex ? colors.primary : null,
                          ),
                          title: Text(
                            fonts[i],
                            style: TextStyle(
                              fontSize: 16,
                              color: i == activeIndex ? colors.primary : null,
                            ),
                          ),
                          trailing: i == activeIndex
                              ? Icon(Icons.check_circle_rounded,
                                  color: colors.primary)
                              : null,
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            setSheetState(() {});
                            await notifier.setTypefaceIndex(i);
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> showActionsHeightPicker(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsState settings,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    await showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  l10n.actionsHeightTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                ),
              ),
              SegmentedListSection(
                children: [
                  for (final ratio in actionsHeightRatios)
                    SegmentedListTile(
                      leading: const Icon(Icons.height_outlined),
                      title: Text(
                        ratio,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: ratio == settings.actionsHeightRatio
                          ? Icon(Icons.check_circle_rounded,
                              color: colors.primary)
                          : null,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await notifier.setActionsHeightRatio(ratio);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showBinaryPrefixesPicker(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsState settings,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    await showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  l10n.binaryPrefixesTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                ),
              ),
              SegmentedListSection(
                children: [
                  for (final value in const [1000, 1024])
                    SegmentedListTile(
                      leading: const Icon(Icons.memory_outlined),
                      title: Text(
                        '$value (${value == 1024 ? l10n.binaryKiB : l10n.decimalKB})',
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: value == settings.binaryPrefixes
                          ? Icon(Icons.check_circle_rounded,
                              color: colors.primary)
                          : null,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await notifier.setBinaryPrefixes(value);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
