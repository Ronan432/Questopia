import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/questopia_theme.dart';
import '../../../core/widgets/questopia_scaffold.dart';
import 'sections/appearance_general_section.dart';
import 'sections/sound_storage_about_section.dart';
import 'sections/typography_media_section.dart';

/// Segmented expressive settings screen with horizontal category tabs and swipeable page views.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.isInline = false});

  final bool isInline;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;
  final PageController _pageController = PageController();
  final ScrollController _categoryScrollController = ScrollController();
  int _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {
      // Platform channel unavailable (e.g. in tests) - keep placeholder.
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

  void _scrollToCategory(int index) {
    if (!_categoryScrollController.hasClients) return;
    final targetOffset = (index * 95.0) - 40.0;
    final maxScroll = _categoryScrollController.position.maxScrollExtent;
    final clamped = targetOffset.clamp(0.0, maxScroll);
    _categoryScrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sections = _sections(context);

    final sectionPages = <Widget>[
      AppearanceSection(settings: settings, notifier: notifier),
      GeneralSection(settings: settings, notifier: notifier),
      TypographySection(settings: settings, notifier: notifier),
      MediaSection(settings: settings, notifier: notifier),
      SoundSection(settings: settings, notifier: notifier),
      StorageSection(settings: settings, notifier: notifier),
      AboutSection(
        settings: settings,
        notifier: notifier,
        packageInfo: _packageInfo,
      ),
    ];

    final content = Column(
      children: [
        _buildCategoryButtons(context, sections),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _selectedSection = index);
                  _scrollToCategory(index);
                },
                children: sectionPages,
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

  Widget _buildCategoryButtons(BuildContext context, List<String> sections) {
    return SingleChildScrollView(
      controller: _categoryScrollController,
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
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) {
                HapticFeedback.lightImpact();
                setState(() => _selectedSection = i);
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
                _scrollToCategory(i);
              },
            ),
          ],
        ],
      ),
    );
  }
}
