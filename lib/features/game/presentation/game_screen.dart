import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_segmented_list/material_segmented_list.dart';
import 'package:path/path.dart' as p;

import '../../../core/media/poster_menu_sheet.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/html_processor.dart';
import '../../../core/utils/sheet_helper.dart';
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
  int _activeTab = 0; // 0: Story (Main Desc & Actions), 1: Status (Vars Desc), 2: Inventory (Objects)

  InAppWebViewController? _mainWebViewController;
  InAppWebViewController? _varsWebViewController;

  String _lastMainHtmlLoaded = '';
  String _lastVarsHtmlLoaded = '';

  String _stripTags(String html) {
    if (html.isEmpty) return html;
    return html.replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '').trim();
  }

  GameDialogType _lastDialogShown = GameDialogType.none;

  Future<void> _showOptionsMenu() async {
    debugPrint('[GameScreen] Opening options menu sheet...');
    final colors = Theme.of(context).colorScheme;
    await showQuestopiaSheet<void>(
      context: context,
      builder: (sheetContext) => SingleChildScrollView(
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
                    showQuestopiaSheet<void>(
                      context: context,
                      builder: (_) => const SaveSlotsSheet(),
                    );
                  },
                ),
                SegmentedListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Cheat Engine'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showQuestopiaSheet<void>(
                      context: context,
                      builder: (_) => const CheatModesSheet(),
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
                    ref
                        .read(gameEngineProvider.notifier)
                        .showExecutor();
                  },
                ),
                SegmentedListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: const Text('Open Save File'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref
                        .read(gameEngineProvider.notifier)
                        .showFileLoad();
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
    final fontColor = settings.useGameTextColor
        ? '#${settings.gameTextColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
        : (isDark ? '#E2E2E2' : '#1C1B1F');
    final bgColor = settings.useGameBackgroundColor
        ? '#${settings.gameBackColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
        : (isDark ? '#121212' : '#FFFFFF');
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
      ${HtmlProcessor.ogvBootstrapScript()}
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
        img { max-width: 100%; height: auto; border-radius: 8px; }
        video { max-width: 100%; height: auto; background-color: transparent !important; }
        video canvas { object-fit: fill !important; }
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
    if (!force && rawHtml == _lastMainHtmlLoaded && _mainWebViewController != null) {
      return;
    }
    _lastMainHtmlLoaded = rawHtml;
    final styledHtml = _buildStyledHtml(rawHtml);

    if (_mainWebViewController != null) {
      debugPrint('[GameScreen] Loading data into Main WebView (${styledHtml.length} bytes)');
      _mainWebViewController?.loadData(
        data: styledHtml,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://questopia.local/'),
      );
    } else {
      debugPrint('[GameScreen] Main WebView Controller not initialized yet, content buffered.');
    }
  }

  void _updateVarsWebViewContent(String rawHtml, {bool force = false}) {
    if (!force && rawHtml == _lastVarsHtmlLoaded && _varsWebViewController != null) {
      return;
    }
    _lastVarsHtmlLoaded = rawHtml;
    final styledHtml = _buildStyledHtml(rawHtml);

    if (_varsWebViewController != null) {
      debugPrint('[GameScreen] Loading data into Vars WebView (${styledHtml.length} bytes)');
      _varsWebViewController?.loadData(
        data: styledHtml,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://questopia.local/'),
      );
    } else {
      debugPrint('[GameScreen] Vars WebView Controller not initialized yet, content buffered.');
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

      // Clean the relative path: strip leading slashes, backslashes, or './'
      while (cleanPath.startsWith('/') ||
          cleanPath.startsWith('\\') ||
          cleanPath.startsWith('./')) {
        if (cleanPath.startsWith('./')) {
          cleanPath = cleanPath.substring(2);
        } else {
          cleanPath = cleanPath.substring(1);
        }
      }
      cleanPath = cleanPath.replaceAll('\\', '/');

      final file = _resolveCaseInsensitiveFile(gameDir, cleanPath);
      if (file == null || !await file.exists()) {
        debugPrint('[GameScreen] Media file not found: "$cleanPath" in ${gameDir.path}');
        return null;
      }

      final mime = HtmlProcessor.mimeTypeForPath(cleanPath);
      final bytes = await file.readAsBytes();
      debugPrint('[GameScreen] Serving local media file "$cleanPath" (${bytes.length} bytes, mime: $mime)');
      return WebResourceResponse(
        contentType: mime,
        data: bytes,
        statusCode: 200,
        reasonPhrase: 'OK',
        headers: {
          'Content-Type': mime,
          'Content-Length': '${bytes.length}',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Expose-Headers': 'Content-Range, Content-Length, Accept-Ranges',
        },
      );
    } catch (error) {
      debugPrint('[GameScreen] Error intercepting media: $error');
      return null;
    }
  }

  /// Case-insensitive & slash-tolerant local file resolution in [gameDir].
  File? _resolveCaseInsensitiveFile(Directory gameDir, String relativePath) {
    final directFile = File(p.join(gameDir.path, relativePath));
    if (directFile.existsSync()) return directFile;

    final parts = p.split(relativePath);
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
      for (final child in children) {
        final name = p.basename(child.path);
        if (name.toLowerCase() == part.toLowerCase()) {
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

  Future<void> _onWebViewLongPress(
    InAppWebViewController controller,
    InAppWebViewHitTestResult result,
  ) async {
    final extra = result.extra ?? '';
    debugPrint('[GameScreen] WebView long press: type=${result.type}, extra="$extra"');
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activeTab,
        onDestinationSelected: (index) {
          debugPrint('[GameScreen] Switching tab to $index');
          setState(() {
            _activeTab = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: engineState.gameState.isMainDescChanged && _activeTab != 0,
              child: const Icon(Icons.article_outlined),
            ),
            selectedIcon: const Icon(Icons.article_rounded),
            label: 'Story',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: engineState.gameState.isVarsDescChanged && _activeTab != 1,
              child: const Icon(Icons.tune_rounded),
            ),
            selectedIcon: const Icon(Icons.tune_rounded),
            label: 'Status',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: engineState.gameState.isObjectsChanged && _activeTab != 2,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
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
                  debugPrint('[GameScreen] Main onWebViewCreated fired: $controller');
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
          ),
          if (engineState.gameState.actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: engineState.gameState.actions.map((act) {
                    return FilledButton.tonal(
                      onPressed: () {
                        debugPrint('[GameScreen] Tapped action #${act.index}: "${act.name}"');
                        engineNotifier.execAction(act.index);
                      },
                      child: Text(_stripTags(act.name)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Type command or response...',
              prefixIcon: Icon(Icons.keyboard_alt_outlined),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                debugPrint('[GameScreen] Submitted command text: "${value.trim()}"');
                engineNotifier.execCode(value.trim());
              }
            },
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InAppWebView(
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
    if (objects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.backpack_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Inventory is empty',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: objects.length,
      itemBuilder: (context, index) {
        final obj = objects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.backpack_outlined),
            ),
            title: Text(obj.name),
            onTap: () {
              debugPrint('[GameScreen] Selected object #${obj.index}: "${obj.name}"');
              engineNotifier.selectObject(obj.index);
            },
          ),
        );
      },
    );
  }
}
