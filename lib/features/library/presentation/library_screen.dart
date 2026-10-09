import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

import '../../../core/error/crash_reporter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/questopia_theme.dart';
import '../../../core/helpers/path_picker_helper.dart';
import '../../../core/helpers/sheet_helper.dart';
import '../../../core/widgets/questopia_scaffold.dart';
import '../../game/presentation/game_screen.dart';
import '../../game/providers/game_engine_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/local_game.dart';
import '../data/remote_game.dart';
import '../providers/library_provider.dart';
import 'widgets/local_game_card.dart';
import 'widgets/remote_game_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';
  bool _isSearchOpen = false;
  bool _showFavoritesOnly = false;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _offerCrashReport();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await PathPickerHelper.ensureStoragePermissions();
      }
      if (mounted) {
        ref.read(libraryProvider.notifier).refreshLocalGames();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_isSearchOpen) return;
    setState(() {
      _isSearchOpen = false;
    });
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<void> _offerCrashReport() async {
    final report = await CrashReporter.takePendingReport();
    if (!mounted || report == null) return;
    final preview =
        report.length > 800 ? '${report.substring(0, 800)}...' : report;
    await showDialog<void>(
      context: context,
      builder: (ctx) => M3ETheme(
        data: M3EThemeData(
          colorScheme: QuestopiaTheme.m3eColorSchemeFrom(Theme.of(context).colorScheme),
        ),
        child: AlertDialog(
          title: const Text('Crash report'),
          content: SingleChildScrollView(child: Text(preview)),
          actions: [
            M3EButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Close'),
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.sm,
              shape: M3EButtonShape.round,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importGameFolder() async {
    debugPrint('[QUESTOPIA_IMPORT] [UI] _importGameFolder invoked from UI');
    final messenger = ScaffoldMessenger.of(context);
    final libraryNotifier = ref.read(libraryProvider.notifier);

    final selected = await PathPickerHelper.pickGame(context);
    debugPrint('[QUESTOPIA_IMPORT] [UI] PathPickerHelper.pickGame returned: "$selected"');
    if (selected == null || selected.isEmpty || !mounted) {
      debugPrint('[QUESTOPIA_IMPORT] [UI] Import aborted: selected path is null/empty or unmounted');
      return;
    }

    // Show Progress Dialog while importing
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => M3ETheme(
        data: M3EThemeData(
          colorScheme:
              QuestopiaTheme.m3eColorSchemeFrom(Theme.of(context).colorScheme),
        ),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Importing game...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      debugPrint('[QUESTOPIA_IMPORT] [UI] Calling libraryNotifier.importGameFolder("$selected")');
      final game = await libraryNotifier.importGameFolder(selected);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _showFavoritesOnly = false;
          _searchQuery = '';
        });
      }
      if (game != null && mounted) {
        debugPrint('[QUESTOPIA_IMPORT] [UI] Import successful! Game: "${game.title}" (file: ${game.gameFilePath})');
        messenger.showSnackBar(
          SnackBar(content: Text('Imported ${game.title}')),
        );
      } else {
        debugPrint('[QUESTOPIA_IMPORT] [UI] Import returned null');
      }
    } catch (error, st) {
      debugPrint('[QUESTOPIA_IMPORT] [UI] Error importing game: $error\n$st');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        messenger.showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final filteredLocal = libraryState.localGames.where((game) {
      if (_showFavoritesOnly && !game.isFavorite) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return game.title.toLowerCase().contains(q) ||
          game.author.toLowerCase().contains(q);
    }).toList();

    debugPrint('[QUESTOPIA_UI] LibraryScreen build: total localGames=${libraryState.localGames.length}, filteredLocal=${filteredLocal.length}, favoritesOnly=$_showFavoritesOnly, query="$_searchQuery"');

    final filteredRemote = libraryState.remoteGames.where((game) {
      if (_searchQuery.isEmpty) return true;
      return game.displayName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    // Builds the library/catalog page content for the given tab index.
    Widget mainContentFor(int tabIndex) {
      return Column(
        children: [
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SearchBar(
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(
                  colors.surfaceContainerHigh,
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                hintText: tabIndex == 0
                    ? l10n.search
                    : 'Search online catalog...',
                hintStyle: WidgetStateProperty.all(
                  TextStyle(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                leading: Icon(Icons.search_rounded, color: colors.primary),
                trailing: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          Expanded(
            child: tabIndex == 0
                ? _buildLocalTab(filteredLocal, libraryState)
                : _buildRemoteTab(filteredRemote, libraryState),
          ),
        ],
      );
    }

    final mainContent = mainContentFor(_selectedTab);

    return M3ETheme(
      data: M3EThemeData(
        colorScheme: QuestopiaTheme.m3eColorSchemeFrom(colors),
      ),
      child: QuestopiaScaffold(
        title: isDesktop
            ? ''
            : (_selectedTab == 0
                ? 'Questopia'
                : (_selectedTab == 1 ? l10n.catalog : l10n.settings)),
        titleWidget: isDesktop
            ? null
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      alignment: Alignment.centerLeft,
                      child: child,
                    ),
                  );
                },
                child: _isSearchOpen
                    ? KeyedSubtree(
                        key: const ValueKey<String>('search_open'),
                        child: SizedBox(
                          height: 44,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                textAlignVertical: TextAlignVertical.center,
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: _selectedTab == 0
                                      ? l10n.search
                                      : 'Search games...',
                                  hintStyle: TextStyle(
                                    color: colors.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: colors.primary,
                                    size: 20,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                      minWidth: 38, minHeight: 38),
                                  suffixIconConstraints: const BoxConstraints(
                                      minWidth: 38, minHeight: 38),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                              minWidth: 38, minHeight: 38),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(
                                                () => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : KeyedSubtree(
                        key: ValueKey<int>(_selectedTab),
                        child: Text(
                          _selectedTab == 0
                              ? 'Questopia'
                              : (_selectedTab == 1
                                  ? l10n.catalog
                                  : l10n.settings),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
        actions: isDesktop || _selectedTab == 2
            ? null
            : (_isSearchOpen
                ? [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close search',
                      onPressed: _closeSearch,
                    ),
                    const SizedBox(width: 8),
                  ]
                : [
                    if (_selectedTab == 0) ...[
                      IconButton(
                        tooltip: l10n.search,
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _openSearch,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: _showFavoritesOnly
                            ? 'Show all games'
                            : 'Show favorites only',
                        icon: Icon(
                          _showFavoritesOnly
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _showFavoritesOnly ? colors.error : null,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFavoritesOnly = !_showFavoritesOnly;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Import game',
                        icon: const Icon(Icons.folder_open_rounded),
                        onPressed: _importGameFolder,
                      ),
                    ] else if (_selectedTab == 1) ...[
                      IconButton(
                        tooltip: l10n.search,
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _openSearch,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Refresh catalog',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => ref
                            .read(libraryProvider.notifier)
                            .refreshRemoteCatalog(force: true),
                      ),
                    ],
                    const SizedBox(width: 8),
                  ]),
        body: isDesktop
            ? SafeArea(
                child: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedTab <= 2 ? _selectedTab : 0,
                      onDestinationSelected: (value) async {
                        _closeSearch();
                        if (value == 3) {
                          await _importGameFolder();
                          return;
                        }
                        setState(() => _selectedTab = value);
                        if (value == 1) {
                          final state = ref.read(libraryProvider);
                          if (!state.hasLoadedRemote && !state.isLoadingRemote) {
                            ref.read(libraryProvider.notifier).refreshRemoteCatalog();
                          }
                        }
                      },
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: colors.surface,
                      indicatorColor: colors.secondaryContainer,
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.library_books_outlined),
                          selectedIcon: const Icon(Icons.library_books),
                          label: Text(l10n.library),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.explore_outlined),
                          selectedIcon: const Icon(Icons.explore),
                          label: Text(l10n.catalog),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.settings_outlined),
                          selectedIcon: const Icon(Icons.settings),
                          label: Text(l10n.settings),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Add Game'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _selectedTab == 2
                          ? const SettingsScreen(isInline: true)
                          : mainContent,
                    ),
                  ],
                ),
              )
            : SafeArea(
                child: _selectedTab == 2
                    ? const SettingsScreen(isInline: true)
                    : mainContent,
              ),
        extendBody: !isDesktop && ref.watch(settingsProvider).isNavBarBlur,
        bottomNavigationBar: isDesktop
            ? null
            : _buildMobileBottomBar(context, l10n, colors),
      ),
    );
  }

  Widget _buildMobileBottomBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colors,
  ) {
    final settings = ref.watch(settingsProvider);
    final isBlur = settings.isNavBarBlur;
    final blurPercent = settings.navBarBlurPercent.clamp(10.0, 100.0);
    final sigma = (blurPercent / 100.0) * 24.0;

    final items = [
      (
        icon: Icons.library_books_outlined,
        selectedIcon: Icons.library_books,
        label: l10n.library,
      ),
      (
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        label: l10n.catalog,
      ),
      (
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
      ),
    ];

    Widget barContent = Container(
      decoration: BoxDecoration(
        color: isBlur ? colors.surface.withValues(alpha: 0.70) : colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: isBlur ? 0.2 : 0.35),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: MediaQuery.paddingOf(context).bottom + 6,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = _selectedTab == index;
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (settings.isEdgeFeedback) {
                HapticFeedback.lightImpact();
              }
              _closeSearch();
              setState(() => _selectedTab = index);
              if (index == 1) {
                final state = ref.read(libraryProvider);
                if (!state.hasLoadedRemote && !state.isLoadingRemote) {
                  ref.read(libraryProvider.notifier).refreshRemoteCatalog();
                }
              }
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 18 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    size: 22,
                    color: isSelected
                        ? colors.onSecondaryContainer
                        : colors.onSurfaceVariant,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );

    if (isBlur) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: barContent,
        ),
      );
    }
    return barContent;
  }

  Widget _buildLocalTab(List<LocalGame> games, LibraryState state) {
    return _buildLocalGrid(games, state.isLoadingLocal);
  }

  Widget _buildRemoteTab(List<RemoteGame> games, LibraryState state) {
    return Column(
      children: [
        _buildCatalogFilterBar(state),
        Expanded(
          child: _buildRemoteGrid(games, state),
        ),
        if (state.totalPages > 1) _buildPaginationBar(state),
      ],
    );
  }

  Widget _buildPaginationBar(LibraryState state) {
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(libraryProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          M3EButton.icon(
            onPressed: state.currentPage > 1
                ? () => notifier.setCatalogPage(state.currentPage - 1)
                : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Prev'),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colors.onSurface,
            ),
          ),
          M3EButton.icon(
            onPressed: state.currentPage < state.totalPages
                ? () => notifier.setCatalogPage(state.currentPage + 1)
                : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Next'),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogFilterBar(LibraryState state) {
    final notifier = ref.read(libraryProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          ChoiceChip(
            showCheckmark: false,
            avatar: const Icon(Icons.sort_rounded, size: 18),
            label: Text(state.catalogSort.label),
            selected: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onSelected: (_) => _showSortPickerSheet(context, state),
          ),
          const SizedBox(width: 8),
          for (final lang in const ['', 'ru', 'en']) ...[
            ChoiceChip(
              showCheckmark: false,
              label: Text(lang.isEmpty ? 'All Languages' : lang.toUpperCase()),
              selected: state.catalogLanguage == lang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    state.catalogLanguage == lang ? 24 : 8),
              ),
              onSelected: (_) {
                notifier.setCatalogFilter(language: lang);
              },
            ),
            const SizedBox(width: 8),
          ],
          ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              state.catalogFeaturedOnly
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 18,
              color: state.catalogFeaturedOnly ? Colors.amber : null,
            ),
            label: const Text('Featured'),
            selected: state.catalogFeaturedOnly,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  state.catalogFeaturedOnly ? 24 : 8),
            ),
            onSelected: (selected) {
              notifier.setCatalogFilter(featuredOnly: selected);
            },
          ),
        ],
      ),
    );
  }

  void _showSortPickerSheet(BuildContext context, LibraryState state) {
    final notifier = ref.read(libraryProvider.notifier);
    showQuestopiaSheet<void>(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'Sort Catalog',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              SegmentedListSection(
                children: [
                  for (final opt in CatalogSortOption.values)
                    SegmentedListTile(
                      leading: Icon(
                        state.catalogSort == opt
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: state.catalogSort == opt
                            ? Theme.of(ctx).colorScheme.primary
                            : null,
                      ),
                      title: Text(opt.label),
                      trailing: state.catalogSort == opt
                          ? Icon(Icons.check_rounded,
                              color: Theme.of(ctx).colorScheme.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        notifier.setCatalogFilter(sort: opt);
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

  Widget _buildLocalGrid(List<LocalGame> games, bool isLoading) {
    if (isLoading && games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              _showFavoritesOnly
                  ? 'No favorite games found.'
                  : 'No games found in local library.',
            ),
          ),
        ],
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        4,
        isCompact ? 12 : 20,
        isCompact ? 20 : 24,
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isCompact ? 200 : 320,
        mainAxisExtent: isCompact ? 208 : 245,
        crossAxisSpacing: isCompact ? 10 : 14,
        mainAxisSpacing: isCompact ? 10 : 14,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return LocalGameCard(
          game: game,
          isCompact: isCompact,
          onPlay: () async {
            final f = File(game.gameFilePath);
            if (!await f.exists()) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Game file not found at ${game.gameFilePath}. Folder may have been moved or storage permission revoked.',
                    ),
                  ),
                );
              }
              return;
            }
            ref.read(gameEngineProvider.notifier).loadGame(game);
            // The game player owns the full screen (it has its own in-game
            // tabs), so it always pushes on the root navigator instead of the
            // active Android shell branch navigator.
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => GameScreen(title: game.title),
                ),
              );
            }
          },
          onToggleFavorite: () {
            ref.read(libraryProvider.notifier).toggleFavorite(game);
          },
          onRemove: () {
            ref.read(libraryProvider.notifier).removeGameFromLibrary(game);
          },
        );
      },
    );
  }

  Widget _buildRemoteGrid(List<RemoteGame> games, LibraryState state) {
    if (state.isLoadingRemote && games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (state.remoteError != null && games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.remoteError!,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () =>
                  ref.read(libraryProvider.notifier).refreshRemoteCatalog(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No catalog items available.')),
        ],
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        4,
        isCompact ? 12 : 20,
        isCompact ? 20 : 24,
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isCompact ? 200 : 320,
        mainAxisExtent: isCompact ? 208 : 245,
        crossAxisSpacing: isCompact ? 10 : 14,
        mainAxisSpacing: isCompact ? 10 : 14,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final remoteGame = games[index];
        final isDownloading = state.downloadingGameId == remoteGame.id;
        final progress = isDownloading ? state.downloadProgress : null;

        return RemoteGameCard(
          game: remoteGame,
          isCompact: isCompact,
          isDownloading: isDownloading,
          progress: progress,
          onDownload: () => _download(remoteGame),
        );
      },
    );
  }

  Future<void> _download(RemoteGame remoteGame) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final downloaded = await ref
          .read(libraryProvider.notifier)
          .downloadGame(remoteGame);
      if (downloaded != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Downloaded ${remoteGame.displayName}')),
        );
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
