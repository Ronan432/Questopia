import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_segmented_list/material_segmented_list.dart';
import 'package:path/path.dart' as p;

import '../../../core/media/poster_menu_sheet.dart';
import '../../../core/native/qsp_models.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/helpers/html_processor.dart';
import '../../../core/helpers/sheet_helper.dart';
import '../providers/game_engine_provider.dart';
import 'dialogs/game_dialogs_host.dart';
import 'sheets/cheat_modes_sheet.dart';
import 'sheets/save_slots_sheet.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({required this.title, super.key});

  final String title;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int _activeTab =
      0; // 0: Story (Main Desc & Actions), 1: Status (Vars Desc), 2: Inventory (Objects)

  InAppWebViewController? _mainWebViewController;
  InAppWebViewController? _varsWebViewController;

  String _lastMainHtmlLoaded = '';
  String _lastVarsHtmlLoaded = '';
  Map<String, String>? _cachedAssetIndex;

  @override
  void initState() {
    super.initState();
    _buildFastAssetIndex();
    final settings = ref.read(settingsProvider);
    if (settings.isImmersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _buildFastAssetIndex() async {
    final game = ref.read(gameEngineProvider).activeGame;
    if (game == null) return;
    final gameFolder = Directory(p.dirname(game.gameFilePath));
    final rootFolder = Directory(game.folderPath);
    final targetPath =
        gameFolder.existsSync() ? gameFolder.path : rootFolder.path;

    try {
      final index = await Isolate.run(() async {
        final map = <String, String>{};
        try {
          final dir = Directory(targetPath);
          if (dir.existsSync()) {
            await for (final entity
                in dir.list(recursive: true, followLinks: false)) {
              if (entity is File) {
                final rel = p
                    .relative(entity.path, from: targetPath)
                    .replaceAll('\\', '/')
                    .toLowerCase();
                map[rel] = entity.path;
                final base = p.basename(entity.path).toLowerCase();
                map[base] = entity.path;
              }
            }
          }
        } catch (_) {}
        return map;
      });

      if (mounted) {
        _cachedAssetIndex = index;
        debugPrint(
            '[GameScreen] Built pre-cached asset index with ${index.length} entries for "$targetPath"');
      }
    } catch (e) {
      debugPrint('[GameScreen] Error building asset index: $e');
    }
  }

  String _stripTags(String html) {
    if (html.isEmpty) return html;
    return html
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '')
        .trim();
  }

  GameDialogType _lastDialogShown = GameDialogType.none;

  Future<T?> _openGameSheet<T>(WidgetBuilder builder) async {
    _mainWebViewController?.evaluateJavascript(
      source:
          "document.body.style.filter = 'blur(10px)'; document.body.style.transition = 'filter 0.25s ease';",
    );
    _varsWebViewController?.evaluateJavascript(
      source:
          "document.body.style.filter = 'blur(10px)'; document.body.style.transition = 'filter 0.25s ease';",
    );
    try {
      return await showQuestopiaSheet<T>(
        context: context,
        builder: builder,
      );
    } finally {
      _mainWebViewController?.evaluateJavascript(
        source: "document.body.style.filter = 'none';",
      );
      _varsWebViewController?.evaluateJavascript(
        source: "document.body.style.filter = 'none';",
      );
    }
  }

  Future<void> _showOptionsMenu() async {
    debugPrint('[GameScreen] Opening options menu sheet...');
    final colors = Theme.of(context).colorScheme;
    await _openGameSheet<void>(
      (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'Game Options',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
              ),
            ),
            SegmentedListSection(
              children: [
                SegmentedListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: const Text('Save & Load'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openGameSheet<void>(
                      (_) => const SaveSlotsSheet(),
                    );
                  },
                ),
                SegmentedListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Cheat Engine'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openGameSheet<void>(
                      (_) => const CheatModesSheet(),
                    );
                  },
                ),
                SegmentedListTile(
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text('Restart Game'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref
                        .read(gameEngineProvider.notifier)
                        .showRestartConfirmation();
                  },
                ),
                SegmentedListTile(
                  leading: const Icon(Icons.terminal_rounded),
                  title: const Text('QSP Console'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(gameEngineProvider.notifier).showExecutor();
                  },
                ),
                SegmentedListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: const Text('Open Save File'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(gameEngineProvider.notifier).showFileLoad();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildStyledHtml(String rawHtml) {
    final settings = ref.read(settingsProvider);
    var processedHtml = HtmlProcessor.processHtml(rawHtml);
    processedHtml = HtmlProcessor.wrapOgvVideos(processedHtml);
    if (settings.isImageDisabled) {
      processedHtml = HtmlProcessor.stripImageTags(processedHtml);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var fontColor = settings.useGameTextColor
        ? '#${settings.gameTextColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
        : (isDark ? '#FFFFFF' : '#000000');
    var bgColor = settings.useGameBackgroundColor
        ? '#${settings.gameBackColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
        : (isDark ? '#121212' : '#FFFFFF');

    // Prevent invisible content when text and background colors are identical or colliding
    if (fontColor.toUpperCase() == bgColor.toUpperCase()) {
      fontColor = isDark ? '#FFFFFF' : '#000000';
      bgColor = isDark ? '#121212' : '#FFFFFF';
    }

    final linkColor = settings.useGameLinkColor
        ? '#${settings.gameLinkColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
        : '#3B82F6';
    final fontSize = settings.fontSize.clamp(12.0, 28.0).toStringAsFixed(0);

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
      <base href="https://questopia.local/">
      ${HtmlProcessor.videoBootstrapScript()}
      <style>
        body {
          background-color: $bgColor;
          color: $fontColor;
          font-family: "Netflix Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          font-size: ${fontSize}px;
          line-height: 1.6;
          padding: 12px;
          margin: 0;
        }
        img { max-width: 100%; height: auto; display: block; margin: 8px auto; border-radius: 4px; }
        video { max-width: 100%; height: auto; display: block; margin: 8px auto; border-radius: 4px; background-color: transparent !important; object-fit: contain; }
        video canvas { object-fit: contain !important; }
        a { color: $linkColor; text-decoration: underline; }
      </style>
    </head>
    <body>
      $processedHtml
    </body>
    </html>
    ''';
  }

  void _updateMainWebViewContent(String rawHtml, {bool force = false}) {
    if (!force &&
        rawHtml == _lastMainHtmlLoaded &&
        _mainWebViewController != null) {
      return;
    }
    _lastMainHtmlLoaded = rawHtml;
    final styledHtml = _buildStyledHtml(rawHtml);

    if (_mainWebViewController != null) {
      debugPrint(
          '[GameScreen] Loading data into Main WebView (${styledHtml.length} bytes)');
      _mainWebViewController?.loadData(
        data: styledHtml,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://questopia.local/'),
      );
    } else {
      debugPrint(
          '[GameScreen] Main WebView Controller not initialized yet, content buffered.');
    }
  }

  void _updateVarsWebViewContent(String rawHtml, {bool force = false}) {
    if (!force &&
        rawHtml == _lastVarsHtmlLoaded &&
        _varsWebViewController != null) {
      return;
    }
    _lastVarsHtmlLoaded = rawHtml;
    final styledHtml = _buildStyledHtml(rawHtml);

    if (_varsWebViewController != null) {
      debugPrint(
          '[GameScreen] Loading data into Vars WebView (${styledHtml.length} bytes)');
      _varsWebViewController?.loadData(
        data: styledHtml,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://questopia.local/'),
      );
    } else {
      debugPrint(
          '[GameScreen] Vars WebView Controller not initialized yet, content buffered.');
    }
  }

  /// Serves game-folder files and bundled OGV.js assets through the
  /// `https://questopia.local/` origin so media loads without CORS blocks.
  Future<WebResourceResponse?> _interceptMedia(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) async {
    final url = request.url.toString();
    debugPrint('[GameScreen] Intercepting media request: $url');
    const origin = 'https://questopia.local/';
    if (!url.startsWith(origin)) return null;
    final rawPath = Uri.decodeComponent(url.substring(origin.length));

    try {
      if (rawPath.startsWith('ogv/')) {
        debugPrint('[GameScreen] Serving OGV asset: $rawPath');
        final data = await rootBundle.load('assets/${rawPath.trim()}');
        final bytes = data.buffer.asUint8List();
        final mime = HtmlProcessor.mimeTypeForPath(rawPath);
        return WebResourceResponse(
          contentType: mime,
          contentEncoding: 'utf-8',
          data: bytes,
          statusCode: 200,
          reasonPhrase: 'OK',
          headers: {
            'Content-Type': mime,
            'Content-Length': '${bytes.length}',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      final game = ref.read(gameEngineProvider).activeGame;
      if (game == null) {
        debugPrint('[GameScreen] Media intercept failed: activeGame is null');
        return null;
      }

      final gameDir = Directory(p.dirname(game.gameFilePath));
      final rootFolder = Directory(game.folderPath);

      var cleanPath = rawPath.trim();
      if (cleanPath.contains('?')) {
        cleanPath = cleanPath.split('?').first;
      }
      if (cleanPath.contains('#')) {
        cleanPath = cleanPath.split('#').first;
      }
      try {
        cleanPath = Uri.decodeFull(cleanPath);
      } catch (_) {}

      // Clean the relative path: convert all backslashes to forward slashes
      var normalizedRel = cleanPath.replaceAll('\\', '/');
      while (normalizedRel.startsWith('/') || normalizedRel.startsWith('./')) {
        if (normalizedRel.startsWith('./')) {
          normalizedRel = normalizedRel.substring(2);
        } else {
          normalizedRel = normalizedRel.substring(1);
        }
      }

      File? file;
      if (_cachedAssetIndex != null) {
        final cleanLower = normalizedRel.toLowerCase();
        final indexedPath = _cachedAssetIndex![cleanLower] ??
            _cachedAssetIndex![p.basename(cleanLower)];
        if (indexedPath != null) {
          file = File(indexedPath);
        }
      }

      file ??= _resolveCaseInsensitiveFile(gameDir, normalizedRel) ??
          _resolveCaseInsensitiveFile(rootFolder, normalizedRel);

      if (file == null || !await file.exists()) {
        debugPrint(
            '[GameScreen] Media file not found: "$normalizedRel" in ${gameDir.path} or ${rootFolder.path}');
        return null;
      }

      final mime = HtmlProcessor.mimeTypeForPath(normalizedRel);
      final bytes = await file.readAsBytes();
      debugPrint(
          '[GameScreen] Serving local media file "$normalizedRel" (${bytes.length} bytes, mime: $mime)');
      return WebResourceResponse(
        contentType: mime,
        data: bytes,
        statusCode: 200,
        reasonPhrase: 'OK',
        headers: {
          'Content-Type': mime,
          'Content-Length': '${bytes.length}',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Expose-Headers':
              'Content-Range, Content-Length, Accept-Ranges',
          'Cache-Control': 'no-cache',
        },
      );
    } catch (error) {
      debugPrint('[GameScreen] Error intercepting media: $error');
      return null;
    }
  }

  /// Case-insensitive & slash-tolerant local file resolution in [gameDir].
  File? _resolveCaseInsensitiveFile(Directory gameDir, String relativePath) {
    if (!gameDir.existsSync()) return null;

    final cleanRel = relativePath.replaceAll('\\', '/');
    final directFile =
        File(p.join(gameDir.path, cleanRel.replaceAll('/', p.separator)));
    if (directFile.existsSync()) return directFile;

    final normalized = File(p.normalize(
        p.join(gameDir.path, cleanRel.replaceAll('/', p.separator))));
    if (normalized.existsSync()) return normalized;

    final parts = cleanRel.split('/');
    FileSystemEntity current = gameDir;

    for (final part in parts) {
      if (part == '.' || part.isEmpty) continue;
      if (part == '..') {
        current = current.parent;
        continue;
      }
      if (current is! Directory) return null;

      List<FileSystemEntity> children;
      try {
        children = current.listSync();
      } catch (_) {
        return null;
      }

      FileSystemEntity? match;
      final partLower = part.toLowerCase();
      for (final child in children) {
        final name = p.basename(child.path);
        if (name.toLowerCase() == partLower) {
          match = child;
          break;
        }
      }

      if (match == null) return null;
      current = match;
    }

    if (current is File) return current;
    return null;
  }

  /// Locates an asset file within the game directory using the fast index and fallback resolver.
  File? _findGameAssetFile(String relativePath) {
    if (relativePath.trim().isEmpty) return null;
    final game = ref.read(gameEngineProvider).activeGame;
    if (game == null) return null;

    var cleanPath = relativePath.trim();
    if (cleanPath.contains('?')) {
      cleanPath = cleanPath.split('?').first;
    }
    if (cleanPath.contains('#')) {
      cleanPath = cleanPath.split('#').first;
    }
    try {
      cleanPath = Uri.decodeFull(cleanPath);
    } catch (_) {}

    var normalizedRel = cleanPath.replaceAll('\\', '/');
    while (normalizedRel.startsWith('/') || normalizedRel.startsWith('./')) {
      if (normalizedRel.startsWith('./')) {
        normalizedRel = normalizedRel.substring(2);
      } else {
        normalizedRel = normalizedRel.substring(1);
      }
    }

    if (_cachedAssetIndex != null) {
      final cleanLower = normalizedRel.toLowerCase();
      final indexedPath = _cachedAssetIndex![cleanLower] ??
          _cachedAssetIndex![p.basename(cleanLower)];
      if (indexedPath != null) {
        final f = File(indexedPath);
        if (f.existsSync()) return f;
      }
    }

    final gameDir = Directory(p.dirname(game.gameFilePath));
    final rootFolder = Directory(game.folderPath);
    return _resolveCaseInsensitiveFile(gameDir, normalizedRel) ??
        _resolveCaseInsensitiveFile(rootFolder, normalizedRel);
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

  Future<void> _onWebViewLongPress(
    InAppWebViewController controller,
    InAppWebViewHitTestResult result,
  ) async {
    final extra = result.extra ?? '';
    debugPrint(
        '[GameScreen] WebView long press: type=${result.type}, extra="$extra"');
    if (result.type == InAppWebViewHitTestResultType.IMAGE_TYPE &&
        extra.isNotEmpty) {
      await showPosterMenuSheet(context: context, imageUri: extra);
    }
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

    debugPrint('[GameScreen] build() fired: activeTab=$_activeTab, '
        'isLoading=${engineState.isLoading}, '
        'mainDescLen=${mainHtml.length}, '
        'varsDescLen=${varsHtml.length}, '
        'actions=${engineState.gameState.actions.length}, '
        'objects=${engineState.gameState.objects.length}, '
        'activeDialog=${engineState.activeDialog}');

    _updateMainWebViewContent(mainHtml);
    _updateVarsWebViewContent(varsHtml);
    _maybeShowEngineDialog(engineState.activeDialog);

    return Scaffold(
      appBar: AppBar(
        title: Text(engineState.activeGame?.title ?? widget.title),
        actions: [
          IconButton(
            onPressed: _showOptionsMenu,
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Game Options',
          ),
        ],
      ),
      body: SafeArea(
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
                    mainHtml,
                    engineState,
                    engineNotifier,
                    settings,
                  ),
                  // Tab 1: Status / Vars
                  _buildVarsTab(
                    context,
                    varsHtml,
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
                    });
                  },
                  destinations: [
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible:
                            engineState.gameState.isMainDescChanged &&
                                _activeTab != 0,
                        child: const Icon(Icons.article_outlined),
                      ),
                      selectedIcon: const Icon(Icons.article_rounded),
                      label: 'Story',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible:
                            engineState.gameState.isVarsDescChanged &&
                                _activeTab != 1,
                        child: const Icon(Icons.tune_rounded),
                      ),
                      selectedIcon: const Icon(Icons.tune_rounded),
                      label: 'Status',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible:
                            engineState.gameState.isObjectsChanged &&
                                _activeTab != 2,
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
                });
              },
              destinations: [
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: engineState.gameState.isMainDescChanged &&
                        _activeTab != 0,
                    child: const Icon(Icons.article_outlined),
                  ),
                  selectedIcon: const Icon(Icons.article_rounded),
                  label: 'Story',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: engineState.gameState.isVarsDescChanged &&
                        _activeTab != 1,
                    child: const Icon(Icons.tune_rounded),
                  ),
                  selectedIcon: const Icon(Icons.tune_rounded),
                  label: 'Status',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: engineState.gameState.isObjectsChanged &&
                        _activeTab != 2,
                    child: const Icon(Icons.backpack_outlined),
                  ),
                  selectedIcon: const Icon(Icons.backpack_rounded),
                  label: 'Inventory',
                ),
              ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InAppWebView(
            initialData: InAppWebViewInitialData(
              data: _buildStyledHtml(mainHtml),
              mimeType: 'text/html',
              encoding: 'utf-8',
              baseUrl: WebUri('https://questopia.local/'),
            ),
            initialSettings: InAppWebViewSettings(
              supportZoom: settings.isPinchZoomEnabled,
              builtInZoomControls: true,
              displayZoomControls: false,
              mediaPlaybackRequiresUserGesture: false,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              allowContentAccess: true,
              allowFileAccess: true,
            ),
            onWebViewCreated: (controller) {
              debugPrint(
                  '[GameScreen] Main onWebViewCreated fired: $controller');
              _mainWebViewController = controller;
              _updateMainWebViewContent(mainHtml, force: true);
            },
            onLoadStart: (controller, url) {
              debugPrint('[GameScreen] Main onLoadStart: $url');
            },
            onLoadStop: (controller, url) {
              debugPrint('[GameScreen] Main onLoadStop: $url');
            },
            onReceivedError: (controller, request, error) {
              final url = request.url.toString();
              if (url.contains('about:blank')) return;
              debugPrint(
                  '[GameScreen] Main onReceivedError: ${error.description} on $url');
            },
            shouldInterceptRequest: _interceptMedia,
            onLongPressHitTestResult: _onWebViewLongPress,
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url.toString();
              debugPrint('[GameScreen] Main shouldOverrideUrlLoading: $url');
              if (url.startsWith('exec:')) {
                final code = HtmlProcessor.decodeExecUrl(url);
                debugPrint('[GameScreen] Executing link code: "$code"');
                engineNotifier.execCode(code);
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
        ),
        if (engineState.gameState.actions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    QspAction act,
    GameEngineNotifier engineNotifier,
  ) {
    final colors = Theme.of(context).colorScheme;
    final visual = _parseVisualItem(act.name, act.image);
    final file =
        visual.imagePath != null ? _findGameAssetFile(visual.imagePath!) : null;

    Widget? imageWidget;
    if (file != null && file.existsSync()) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ExtendedImage.file(
          file,
          height: 28,
          fit: BoxFit.contain,
          clearMemoryCacheWhenDispose: false,
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

    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _buildStyledHtml(varsHtml),
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://questopia.local/'),
      ),
      initialSettings: InAppWebViewSettings(
        supportZoom: settings.isPinchZoomEnabled,
        builtInZoomControls: true,
        displayZoomControls: false,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (controller) {
        debugPrint('[GameScreen] Vars onWebViewCreated fired: $controller');
        _varsWebViewController = controller;
        _updateVarsWebViewContent(varsHtml, force: true);
      },
      onLoadStart: (controller, url) {
        debugPrint('[GameScreen] Vars onLoadStart: $url');
      },
      onLoadStop: (controller, url) {
        debugPrint('[GameScreen] Vars onLoadStop: $url');
      },
      onReceivedError: (controller, request, error) {
        final url = request.url.toString();
        if (url.contains('about:blank')) return;
        debugPrint(
            '[GameScreen] Vars onReceivedError: ${error.description} on $url');
      },
      shouldInterceptRequest: _interceptMedia,
      onLongPressHitTestResult: _onWebViewLongPress,
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url.toString();
        debugPrint('[GameScreen] Vars shouldOverrideUrlLoading: $url');
        if (url.startsWith('exec:')) {
          final code = HtmlProcessor.decodeExecUrl(url);
          debugPrint('[GameScreen] Executing link code from Vars: "$code"');
          ref.read(gameEngineProvider.notifier).execCode(code);
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
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
      final visual = _parseVisualItem(obj.name, obj.image);
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
                  child: ExtendedImage.file(
                    item.file!,
                    fit: BoxFit.contain,
                    clearMemoryCacheWhenDispose: false,
                    loadStateChanged: (state) {
                      if (state.extendedImageLoadState == LoadState.failed) {
                        return Icon(
                          Icons.inventory_2_outlined,
                          color: colors.outline,
                        );
                      }
                      return null;
                    },
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
                    child: ExtendedImage.file(
                      item.file!,
                      fit: BoxFit.contain,
                      clearMemoryCacheWhenDispose: false,
                      loadStateChanged: (state) {
                        if (state.extendedImageLoadState == LoadState.failed) {
                          return Icon(
                            Icons.inventory_2_outlined,
                            color: colors.outline,
                          );
                        }
                        return null;
                      },
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
