import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/html_processor.dart';
import '../providers/game_engine_provider.dart';
import 'sheets/cheat_modes_sheet.dart';
import 'sheets/save_slots_sheet.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({required this.title, super.key});

  final String title;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  InAppWebViewController? _webViewController;
  String _lastHtmlLoaded = '';

  Future<void> _showOptionsMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: const Text('Save & Load'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const SaveSlotsSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Cheat Engine'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const CheatModesSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('Restart Game'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(gameEngineProvider.notifier).restartGame();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateWebViewContent(String rawHtml) {
    if (rawHtml == _lastHtmlLoaded) return;
    _lastHtmlLoaded = rawHtml;

    final processedHtml = HtmlProcessor.processHtml(rawHtml);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontColor = isDark ? '#E2E2E2' : '#1C1B1F';
    final bgColor = isDark ? '#121212' : '#FFFFFF';

    final styledHtml = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
      <style>
        body {
          background-color: $bgColor;
          color: $fontColor;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          font-size: 16px;
          line-height: 1.6;
          padding: 12px;
          margin: 0;
        }
        img { max-width: 100%; height: auto; border-radius: 8px; }
        a { color: #3B82F6; text-decoration: underline; }
      </style>
    </head>
    <body>
      $processedHtml
    </body>
    </html>
    ''';

    _webViewController?.loadData(
      data: styledHtml,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://questopia.local/'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(gameEngineProvider);
    final engineNotifier = ref.read(gameEngineProvider.notifier);

    final htmlText = engineState.gameState.mainDesc.isNotEmpty
        ? engineState.gameState.mainDesc
        : '<p>Loading QSP Game...</p>';

    _updateWebViewContent(htmlText);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _showOptionsMenu,
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Game Options',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InAppWebView(
                    initialSettings: InAppWebViewSettings(
                      supportZoom: true,
                      builtInZoomControls: true,
                      displayZoomControls: false,
                      mediaPlaybackRequiresUserGesture: false,
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      _updateWebViewContent(htmlText);
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      final url = navigationAction.request.url.toString();
                      if (url.startsWith('exec:')) {
                        final code = HtmlProcessor.decodeExecUrl(url);
                        engineNotifier.execCode(code);
                        return NavigationActionPolicy.CANCEL;
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (engineState.gameState.actions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: engineState.gameState.actions.map((act) {
                    return FilledButton.tonal(
                      onPressed: () => engineNotifier.execAction(act.index),
                      child: Text(act.name),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 10),
              TextField(
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Type command or response...',
                  prefixIcon: Icon(Icons.keyboard_alt_outlined),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    engineNotifier.execCode(value.trim());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
