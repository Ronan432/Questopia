import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/helpers/path_picker_helper.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/questopia_theme.dart';
import '../../../core/widgets/questopia_frosted_overlay.dart';
import '../../../core/widgets/questopia_scaffold.dart';
import '../../../core/widgets/window_title_bar.dart';
import '../../settings/presentation/settings_screen.dart';
import '../providers/library_provider.dart';
import 'helpers/crash_dialog_helper.dart';
import 'views/catalog_games_view.dart';
import 'views/local_games_view.dart';
import 'widgets/catalog_pagination_bar.dart';
import 'widgets/library_desktop_view.dart';
import 'widgets/library_mobile_app_bar.dart';
import 'widgets/library_mobile_bottom_bar.dart';

/// Main hub containing the local game library, remote catalog, and inline settings.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedTab = 0;
  final PageController _libraryPageController = PageController();
  String _searchQuery = '';
  bool _isSearchOpen = false;
  bool _showFavoritesOnly = false;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _desktopSearchFocusNode = FocusNode();
  bool _isDesktopSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _desktopSearchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isDesktopSearchFocused = _desktopSearchFocusNode.hasFocus;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      CrashDialogHelper.offerCrashReport(context);
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
    _libraryPageController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _desktopSearchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_isSearchOpen) return;
    setState(() => _isSearchOpen = false);
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<void> _importGameFolder() async {
    final path = await PathPickerHelper.pickGame(context);
    if (!mounted || path == null || path.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final game =
          await ref.read(libraryProvider.notifier).importGameFolder(path);
      if (game != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.importedGame(game.title))),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importFailed(e.toString()))),
      );
    }
  }

  void _onTabChanged(int index) {
    if (_selectedTab == index) return;
    _closeSearch();
    setState(() => _selectedTab = index);
    if (_libraryPageController.hasClients) {
      _libraryPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    if (index == 1) {
      final state = ref.read(libraryProvider);
      if (!state.hasLoadedRemote && !state.isLoadingRemote) {
        ref.read(libraryProvider.notifier).refreshRemoteCatalog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    final filteredLocalGames = state.localGames.where((game) {
      final matchesSearch = _searchQuery.isEmpty ||
          game.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFav = !_showFavoritesOnly || game.isFavorite;
      return matchesSearch && matchesFav;
    }).toList();

    final filteredRemoteGames = state.remoteGames.where((game) {
      if (_searchQuery.isEmpty) return true;
      return game.displayName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    Widget mainContentFor(int tabIndex) {
      switch (tabIndex) {
        case 0:
          return LocalGamesView(
            games: filteredLocalGames,
            onImportFolder: _importGameFolder,
            allGames: state.localGames,
            showFavoritesOnly: _showFavoritesOnly,
            onToggleFavoritesOnly: () => setState(
              () => _showFavoritesOnly = !_showFavoritesOnly,
            ),
          );
        case 1:
          return CatalogGamesView(games: filteredRemoteGames);
        case 2:
          return const SettingsScreen(isInline: true);
        default:
          return const SizedBox.shrink();
      }
    }

    final pageViews = PageView(
      controller: _libraryPageController,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (value) {
        _closeSearch();
        setState(() => _selectedTab = value);
        if (value == 1) {
          final s = ref.read(libraryProvider);
          if (!s.hasLoadedRemote && !s.isLoadingRemote) {
            ref.read(libraryProvider.notifier).refreshRemoteCatalog();
          }
        }
      },
      children: [
        mainContentFor(0),
        mainContentFor(1),
        mainContentFor(2),
      ],
    );

    return M3ETheme(
      data: M3EThemeData(
        colorScheme: QuestopiaTheme.m3eColorSchemeFrom(colors),
      ),
      child: PopScope(
        canPop: !_isSearchOpen && _selectedTab == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isSearchOpen) {
            _closeSearch();
            return;
          }
          if (_selectedTab != 0) {
            _onTabChanged(0);
          }
        },
        child: QuestopiaScaffold(
          title: 'Questopia',
          leading: isDesktop
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: QuestopiaLogoIcon(size: 24),
                )
              : null,
          actions: isDesktop
              ? [
                  if (_selectedTab == 0)
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
                      onPressed: () => setState(
                          () => _showFavoritesOnly = !_showFavoritesOnly),
                    ),
                  if (_selectedTab == 1)
                    IconButton(
                      tooltip: 'Refresh catalog',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => ref
                          .read(libraryProvider.notifier)
                          .refreshRemoteCatalog(force: true),
                    ),
                  const SizedBox(width: 8),
                ]
              : null,
          customAppBar: isDesktop
              ? null
              : LibraryMobileAppBar(
                  selectedTab: _selectedTab,
                  isSearchOpen: _isSearchOpen,
                  showFavoritesOnly: _showFavoritesOnly,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSearchChanged: (value) =>
                      setState(() => _searchQuery = value),
                  onOpenSearch: _openSearch,
                  onCloseSearch: _closeSearch,
                  onToggleFavorites: () => setState(
                      () => _showFavoritesOnly = !_showFavoritesOnly),
                  onImportGame: _importGameFolder,
                ),
          body: isDesktop
              ? LibraryDesktopView(
                  selectedTab: _selectedTab,
                  searchQuery: _searchQuery,
                  isSearchFocused: _isDesktopSearchFocused,
                  searchFocusNode: _desktopSearchFocusNode,
                  onTabChanged: _onTabChanged,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  onImportGame: _importGameFolder,
                  child: mainContentFor(_selectedTab),
                )
              : SafeArea(
                  bottom: !ref.watch(settingsProvider).isNavBarBlur,
                  child: pageViews,
                ),
          extendBody: !isDesktop && ref.watch(settingsProvider).isNavBarBlur,
          bottomNavigationBar: isDesktop
              ? null
              : QuestopiaFrostedOverlay(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedTab == 1 && state.totalPages > 1)
                        const CatalogPaginationBar(isInsideOverlay: true),
                      LibraryMobileBottomBar(
                        selectedTab: _selectedTab,
                        onTabSelected: _onTabChanged,
                        isInsideOverlay: true,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
