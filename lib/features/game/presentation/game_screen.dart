import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:path/path.dart' as p;

import '../../../core/media/qsp_html_view.dart';
import '../../../core/media/qsp_path_resolver.dart';
import '../../../core/native/qsp_models.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/helpers/html_processor.dart';
import '../../../core/helpers/sheet_helper.dart';
import '../../../core/widgets/questopia_scaffold.dart';
import '../providers/game_engine_provider.dart';
import 'dialogs/game_dialogs_host.dart';
import 'sheets/game_options_sheet.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({required this.title, super.key});

  final String title;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int _activeTab =
      0; // 0: Story (Main Desc and Actions), 1: Status (Vars Desc), 2: Inventory (Objects)

  QspPathResolver? _resolver;
  String? _resolverKey;

  QspPathResolver _getResolver() {
    final game = ref.read(gameEngineProvider).activeGame;
    final key = '${game?.gameFilePath}|${game?.folderPath}';
    if (_resolver == null || _resolverKey != key) {
      _resolverKey = key;
      final gameDir = game != null ? p.dirname(game.gameFilePath) : '';
      final rootFolder = game?.folderPath ?? '';
      _resolver = QspPathResolver([gameDir, rootFolder]);
    }
    return _resolver!;
  }

  bool _isHeaderVisible = true;
  Timer? _reappearTimer;

  String _translatedMainHtml = '';
  String _translatedVarsHtml = '';
  String _lastTranslatedMainRaw = '';
  String _lastTranslatedVarsRaw = '';
  Map<int, String> _tActs = {}, _tObjs = {};
  bool _isTranslating = false;

  TranslateLanguage _lang(String c) => switch (c.toLowerCase()) {
        'tr' => TranslateLanguage.turkish,
        'ru' => TranslateLanguage.russian,
        'es' => TranslateLanguage.spanish,
        'de' => TranslateLanguage.german,
        'fr' => TranslateLanguage.french,
        'it' => TranslateLanguage.italian,
        'pt' => TranslateLanguage.portuguese,
        'zh' => TranslateLanguage.chinese,
        'ja' => TranslateLanguage.japanese,
        _ => TranslateLanguage.english,
      };

  void _translateContentIfNeeded(String main, String vars, SettingsState s) {
    if (!s.isTranslationEnabled) return;
    if (_lastTranslatedMainRaw == main) {
      if (_lastTranslatedVarsRaw == vars) {
        return;
      }
    }
    _translateAll(main, vars, ref.read(gameEngineProvider).gameState.actions, ref.read(gameEngineProvider).gameState.objects, s);
  }

  void _translateActionsAndObjectsIfNeeded(List<QspAction> acts, List<QspObject> objs, SettingsState s) {
    // Actions and objects are translated in _translateAll
  }

  Future<void> _translateAll(String main, String vars, List<QspAction> acts, List<QspObject> objs, SettingsState s) async {
    if (!s.isTranslationEnabled) return;
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
        return;
      }
    }
    if (_isTranslating) return;
    _isTranslating = true;
    _lastTranslatedMainRaw = main;
    _lastTranslatedVarsRaw = vars;
    try {
      final t = OnDeviceTranslator(sourceLanguage: _lang(s.translationSourceLang), targetLanguage: _lang(s.translationTargetLang));
      final m = OnDeviceTranslatorModelManager();
      await m.downloadModel(_lang(s.translationSourceLang).bcpCode);
      await m.downloadModel(_lang(s.translationTargetLang).bcpCode);

      final tm = HtmlProcessor.stripHtmlTags(main);
      final tv = HtmlProcessor.stripHtmlTags(vars);
      final rMain = tm.isNotEmpty ? await t.translateText(tm) : main;
      final rVars = tv.isNotEmpty ? await t.translateText(tv) : vars;

      final aMap = <int, String>{};
      for (final a in acts) {
        final c = HtmlProcessor.stripHtmlTags(a.name);
        aMap[a.index] = c.isNotEmpty ? a.name.replaceAll(c, await t.translateText(c)) : a.name;
      }
      final oMap = <int, String>{};
      for (final o in objs) {
        final c = HtmlProcessor.stripHtmlTags(o.name);
        oMap[o.index] = c.isNotEmpty ? o.name.replaceAll(c, await t.translateText(c)) : o.name;
      }
      await t.close();
      if (mounted) {
        setState(() {
          _translatedMainHtml = rMain;
          _translatedVarsHtml = rVars;
          _tActs = aMap;
          _tObjs = oMap;
          _isTranslating = false;
        });
      }
    } catch (_) {
      _isTranslating = false;
    }
  }


  void _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        if (_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = false;
          });
        }
        _reappearTimer?.cancel();
        _reappearTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            if (!_isHeaderVisible) {
              setState(() {
                _isHeaderVisible = true;
              });
            }
          }
        });
      } else if (notification.direction == ScrollDirection.forward) {
        if (!_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
        _reappearTimer?.cancel();
      } else if (notification.direction == ScrollDirection.idle) {
        _reappearTimer?.cancel();
        _reappearTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted) {
            if (!_isHeaderVisible) {
              setState(() {
                _isHeaderVisible = true;
              });
            }
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      _reappearTimer?.cancel();
      _reappearTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          if (!_isHeaderVisible) {
            setState(() {
              _isHeaderVisible = true;
            });
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    SystemChrome.setEnabledSystemUIMode(
      settings.isImmersiveMode
          ? SystemUiMode.immersiveSticky
          : SystemUiMode.edgeToEdge,
    );
  }

  @override
  void dispose() {
    _reappearTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _stripTags(String html) {
    if (html.isEmpty) return html;
    return html
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '')
        .trim();
  }

  GameDialogType _lastDialogShown = GameDialogType.none;

  Future<T?> _openGameSheet<T>(WidgetBuilder builder) {
    return showQuestopiaSheet<T>(
      context: context,
      builder: builder,
    );
  }

  Future<void> _showOptionsMenu() async {
    debugPrint('[GameScreen] Opening options menu sheet...');
    await _openGameSheet<void>(
      (_) => const GameOptionsSheet(),
    );
  }



  /// Locates an asset file within the game directory using QspPathResolver.
  File? _findGameAssetFile(String relativePath) {
    if (relativePath.trim().isEmpty) return null;
    final resolved = _getResolver().resolve(relativePath);
    if (resolved != null) {
      final f = File(resolved);
      if (f.existsSync()) return f;
    }
    return null;
  }

  /// Extracts image paths (from image property or embedded <img> tag) and sanitized text.
  ({String? imagePath, String text}) _parseVisualItem(
    String rawName,
    String rawImage,
  ) {
    var imgPath = rawImage.trim();
    if (imgPath.isEmpty) {
      final match = RegExp(
        r'''<img[^>]+src=["']?([^"'>\s]+)["']?''',
        caseSensitive: false,
      ).firstMatch(rawName);
      if (match != null) {
        imgPath = match.group(1) ?? '';
      }
    }

    final cleanText = _stripTags(rawName).trim();
    return (
      imagePath: imgPath.isNotEmpty ? imgPath : null,
      text: cleanText,
    );
  }

  void _maybeShowEngineDialog(GameDialogType dialog) {
    if (dialog == GameDialogType.none || dialog == _lastDialogShown) return;
    debugPrint('[GameScreen] _maybeShowEngineDialog triggering: $dialog');
    _lastDialogShown = dialog;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: dialog != GameDialogType.error,
        builder: (_) => const GameDialogsHost(),
      ).then((_) {
        _lastDialogShown = GameDialogType.none;
        if (mounted) {
          ref.read(gameEngineProvider.notifier).closeDialog();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(gameEngineProvider);
    final engineNotifier = ref.read(gameEngineProvider.notifier);
    final settings = ref.watch(settingsProvider);

    final mainHtml = engineState.gameState.mainDesc.isNotEmpty
        ? engineState.gameState.mainDesc
        : '<p>Loading QSP Story...</p>';

    final varsHtml = engineState.gameState.varsDesc.isNotEmpty
        ? engineState.gameState.varsDesc
        : '<p>No status information available.</p>';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _translateContentIfNeeded(mainHtml, varsHtml, settings);
      _translateActionsAndObjectsIfNeeded(
        engineState.gameState.actions,
        engineState.gameState.objects,
        settings,
      );
    });

    final activeMainHtml = settings.isTranslationEnabled
        ? (_translatedMainHtml.isNotEmpty ? _translatedMainHtml : mainHtml)
        : mainHtml;
    final activeVarsHtml = settings.isTranslationEnabled
        ? (_translatedVarsHtml.isNotEmpty ? _translatedVarsHtml : varsHtml)
        : varsHtml;

    debugPrint('[GameScreen] build() fired: activeTab=$_activeTab, '
        'isLoading=${engineState.isLoading}, '
        'mainDescLen=${activeMainHtml.length}, '
        'varsDescLen=${activeVarsHtml.length}, '
        'actions=${engineState.gameState.actions.length}, '
        'objects=${engineState.gameState.objects.length}, '
        'activeDialog=${engineState.activeDialog}');

    _maybeShowEngineDialog(engineState.activeDialog);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topBarBgColor =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final isTopBarDark =
        ThemeData.estimateBrightnessForColor(topBarBgColor) == Brightness.dark;

    final systemOverlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          isTopBarDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isTopBarDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlay,
      child: QuestopiaScaffold(
        isAppBarVisible: _isHeaderVisible,
        title: engineState.activeGame?.title ?? widget.title,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
        ),
        titleWidget: Text(engineState.activeGame?.title ?? widget.title),
        actions: [
          IconButton(
            onPressed: _showOptionsMenu,
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Game Options',
          ),
        ],
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _onScrollNotification(notification);
            return false;
          },
          child: ExcludeSemantics(
            child: SafeArea(
            child: engineState.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading game world...'),
                      ],
                    ),
                  )
                : IndexedStack(
                    index: _activeTab,
                    children: [
                      // Tab 0: Story (Main Desc + Actions + Input)
                      _buildStoryTab(
                        context,
                        activeMainHtml,
                        engineState,
                        engineNotifier,
                        settings,
                      ),
                      // Tab 1: Status / Vars
                      _buildVarsTab(
                        context,
                        activeVarsHtml,
                        engineState,
                        settings,
                      ),
                      // Tab 2: Inventory / Objects
                      _buildObjectsTab(
                        context,
                        engineState,
                        engineNotifier,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      extendBody: settings.isNavBarBlur,
      bottomNavigationBar: settings.isNavBarBlur
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX:
                      (settings.navBarBlurPercent.clamp(10.0, 100.0) / 100.0) *
                          24.0,
                  sigmaY:
                      (settings.navBarBlurPercent.clamp(10.0, 100.0) / 100.0) *
                          24.0,
                ),
                child: NavigationBar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.70),
                  selectedIndex: _activeTab,
                  onDestinationSelected: (index) {
                    HapticFeedback.lightImpact();
                    debugPrint('[GameScreen] Switching tab to $index');
                    setState(() {
                      _activeTab = index;
                      _isHeaderVisible = true;
                    });
                  },
                  destinations: [
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible:
                            engineState.gameState.isMainDescChanged
                                ? (_activeTab != 0)
                                : false,
                        child: const Icon(Icons.article_outlined),
                      ),
                      selectedIcon: const Icon(Icons.article_rounded),
                      label: 'Story',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible:
                            engineState.gameState.isVarsDescChanged
                                ? (_activeTab != 1)
                                : false,
                        child: const Icon(Icons.tune_rounded),
                      ),
                      selectedIcon: const Icon(Icons.tune_rounded),
                      label: 'Status',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible:
                            engineState.gameState.isObjectsChanged
                                ? (_activeTab != 2)
                                : false,
                        child: const Icon(Icons.backpack_outlined),
                      ),
                      selectedIcon: const Icon(Icons.backpack_rounded),
                      label: 'Inventory',
                    ),
                  ],
                ),
              ),
            )
          : NavigationBar(
              selectedIndex: _activeTab,
              onDestinationSelected: (index) {
                HapticFeedback.lightImpact();
                debugPrint('[GameScreen] Switching tab to $index');
                setState(() {
                  _activeTab = index;
                  _isHeaderVisible = true;
                });
              },
              destinations: [
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: engineState.gameState.isMainDescChanged
                        ? (_activeTab != 0)
                        : false,
                    child: const Icon(Icons.article_outlined),
                  ),
                  selectedIcon: const Icon(Icons.article_rounded),
                  label: 'Story',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: engineState.gameState.isVarsDescChanged
                        ? (_activeTab != 1)
                        : false,
                    child: const Icon(Icons.tune_rounded),
                  ),
                  selectedIcon: const Icon(Icons.tune_rounded),
                  label: 'Status',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: engineState.gameState.isObjectsChanged
                        ? (_activeTab != 2)
                        : false,
                    child: const Icon(Icons.backpack_outlined),
                  ),
                  selectedIcon: const Icon(Icons.backpack_rounded),
                  label: 'Inventory',
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildStoryTab(
    BuildContext context,
    String mainHtml,
    GameEngineState engineState,
    GameEngineNotifier engineNotifier,
    SettingsState settings,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    double maxActionHeight;
    switch (settings.actionsHeightRatio) {
      case '1/5':
        maxActionHeight = screenHeight * 0.20;
        break;
      case '1/4':
        maxActionHeight = screenHeight * 0.25;
        break;
      case '1/3':
        maxActionHeight = screenHeight * 0.33;
        break;
      case '1/2':
        maxActionHeight = screenHeight * 0.50;
        break;
      case '2/3':
        maxActionHeight = screenHeight * 0.66;
        break;
      default:
        maxActionHeight = screenHeight * 0.33;
        break;
    }
    maxActionHeight = maxActionHeight.clamp(80.0, 450.0);

    final resolver = _getResolver();
    final theme = Theme.of(context);
    final isCustomBg = settings.useGameBackgroundColor;
    final bgColor = isCustomBg
        ? Color(settings.gameBackColor)
        : theme.colorScheme.surface;
    final isCustomFontColor = settings.useGameTextColor;
    final fontColor = isCustomFontColor
        ? Color(settings.gameTextColor)
        : theme.colorScheme.onSurface;

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: QspHtmlView(
                html: mainHtml,
                resolver: resolver,
                textStyle: TextStyle(
                  fontSize: settings.fontSize.clamp(12.0, 28.0),
                  color: fontColor,
                  fontFamily: 'Netflix Sans',
                  height: 1.5,
                ),
                onTapLink: (url) {
                  final lower = url.toLowerCase();
                  if (lower.startsWith('exec:') ||
                      lower.contains('/exec:') ||
                      lower.contains('exec%3a')) {
                    final code = HtmlProcessor.decodeExecUrl(url);
                    debugPrint('[GameScreen] Executing link code: "$code"');
                    engineNotifier.execCode(code);
                    return true;
                  }
                  return false;
                },
              ),
            ),
          ),
          if (engineState.gameState.actions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxActionHeight),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: engineState.gameState.actions.map((act) {
                      return _buildActionButton(context, act, engineNotifier);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    QspAction act,
    GameEngineNotifier engineNotifier,
  ) {
    final colors = Theme.of(context).colorScheme;
    final activeName = _tActs[act.index] ?? act.name;
    final visual = _parseVisualItem(activeName, act.image);
    final file =
        visual.imagePath != null ? _findGameAssetFile(visual.imagePath!) : null;

    Widget? imageWidget;
    if (file != null && file.existsSync()) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          file,
          height: 28,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    if (imageWidget != null && visual.text.isEmpty) {
      // Pure image button - custom sleek square/pill tile
      return Material(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        elevation: 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            debugPrint(
                '[GameScreen] Tapped action #${act.index}: "${act.name}"');
            engineNotifier.execAction(act.index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32, maxHeight: 44),
              child: imageWidget,
            ),
          ),
        ),
      );
    }

    return FilledButton.tonal(
      onPressed: () {
        debugPrint('[GameScreen] Tapped action #${act.index}: "${act.name}"');
        engineNotifier.execAction(act.index);
      },
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: imageWidget != null ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageWidget != null) ...[
            imageWidget,
            if (visual.text.isNotEmpty) const SizedBox(width: 8),
          ],
          if (visual.text.isNotEmpty)
            Flexible(
              child: Text(
                visual.text,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVarsTab(
    BuildContext context,
    String varsHtml,
    GameEngineState engineState,
    SettingsState settings,
  ) {
    if (engineState.gameState.varsDesc.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No status information available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    final resolver = _getResolver();
    final theme = Theme.of(context);
    final isCustomBg = settings.useGameBackgroundColor;
    final bgColor = isCustomBg
        ? Color(settings.gameBackColor)
        : theme.colorScheme.surface;
    final isCustomFontColor = settings.useGameTextColor;
    final fontColor = isCustomFontColor
        ? Color(settings.gameTextColor)
        : theme.colorScheme.onSurface;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: QspHtmlView(
          html: varsHtml,
          resolver: resolver,
          textStyle: TextStyle(
            fontSize: settings.fontSize.clamp(12.0, 28.0),
            color: fontColor,
            fontFamily: 'Netflix Sans',
            height: 1.5,
          ),
          onTapLink: (url) {
            final lower = url.toLowerCase();
            if (lower.startsWith('exec:') ||
                lower.contains('/exec:') ||
                lower.contains('exec%3a')) {
              final code = HtmlProcessor.decodeExecUrl(url);
              debugPrint('[GameScreen Vars] Executing link code: "$code"');
              ref.read(gameEngineProvider.notifier).execCode(code);
              return true;
            }
            return false;
          },
        ),
      ),
    );
  }

  Widget _buildObjectsTab(
    BuildContext context,
    GameEngineState engineState,
    GameEngineNotifier engineNotifier,
  ) {
    final objects = engineState.gameState.objects;
    final colors = Theme.of(context).colorScheme;

    if (objects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.backpack_outlined,
              size: 48,
              color: colors.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Inventory is empty',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.outline,
                  ),
            ),
          ],
        ),
      );
    }

    final parsedObjects = objects.map((obj) {
      final activeName = _tObjs[obj.index] ?? obj.name;
      final visual = _parseVisualItem(activeName, obj.image);
      final file = visual.imagePath != null
          ? _findGameAssetFile(visual.imagePath!)
          : null;
      return (obj: obj, visual: visual, file: file);
    }).toList();

    final allPureImages = parsedObjects.every(
      (p) => p.file != null && p.file!.existsSync() && p.visual.text.isEmpty,
    );

    if (allPureImages) {
      // Pure image inventory design: sleek, native square tiles grid
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 84,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: parsedObjects.length,
        itemBuilder: (context, index) {
          final item = parsedObjects[index];
          return Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            color: colors.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                debugPrint(
                    '[GameScreen] Selected object #${item.obj.index}: "${item.obj.name}"');
                engineNotifier.selectObject(item.obj.index);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Image.file(
                    item.file!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      color: colors.outline,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parsedObjects.length,
      itemBuilder: (context, index) {
        final item = parsedObjects[index];
        final hasImage = item.file != null && item.file!.existsSync();

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0.5,
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: hasImage
                ? Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.file(
                      item.file!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        color: colors.outline,
                      ),
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: colors.secondaryContainer,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
            title: Text(
              item.visual.text.isNotEmpty
                  ? item.visual.text
                  : 'Item #${item.obj.index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: colors.onSurface,
              ),
            ),
            onTap: () {
              debugPrint(
                  '[GameScreen] Selected object #${item.obj.index}: "${item.obj.name}"');
              engineNotifier.selectObject(item.obj.index);
            },
          ),
        );
      },
    );
  }
}
