import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'ogv_asset_server.dart';

/// Plays Ogg Theora video through the bundled OGV.js WebAssembly decoder.
///
/// The hardware decoder cannot read Theora, so `.ogv` files fail outright.
/// OGV.js is a WebAssembly port of the Theora and Vorbis decoders that renders
/// into a canvas inside a hidden WebView. Every other container keeps using the
/// hardware decoder, so only Ogg video pays this extra cost.
///
/// Decoder assets and the media itself are served by [OgvAssetServer], because
/// the stream loader needs working byte range requests that neither a bundled
/// asset nor a data URI can provide.
class QspOgvVideo extends StatefulWidget {
  const QspOgvVideo({
    super.key,
    required this.path,
    this.autoplay = true,
    this.loop = true,
    this.muted = true,
    this.width,
    this.height,
  });

  final String path;
  final bool autoplay;
  final bool loop;
  final bool muted;
  final double? width;
  final double? height;

  @override
  State<QspOgvVideo> createState() => _QspOgvVideoState();
}

class _QspOgvVideoState extends State<QspOgvVideo> {
  WebViewController? _controller;
  bool _failed = false;
  bool _ready = false;

  String _playerUrl(String baseUrl) {
    final query = <String, String>{
      'src': widget.path,
      'muted': widget.muted ? '1' : '0',
      'loop': widget.loop ? '1' : '0',
      'autoplay': widget.autoplay ? '1' : '0',
    };
    final encoded = query.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}='
            '${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$baseUrl/player?$encoded';
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final server = await OgvAssetServer.ensureStarted();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Only the local player page may load. Media is pulled over XHR
            // so no further navigation should ever be requested.
            return request.url.startsWith(server.baseUrl)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _failed = true);
          },
        ),
      );

    await controller.loadRequest(Uri.parse(_playerUrl(server.baseUrl)));

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  Future<void> _resume() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript('play();');
    } catch (_) {
      // Autoplay may be refused until the first user interaction, which is
      // acceptable because the surrounding game screen is that gesture.
    }
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || !_ready || controller == null) {
      return const SizedBox.shrink();
    }

    Widget view = Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: controller)),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _resume,
          ),
        ),
      ],
    );

    const ratio = 16 / 9;
    if (widget.width != null && widget.height != null) {
      view = SizedBox(width: widget.width, height: widget.height, child: view);
    } else if (widget.width != null) {
      view = SizedBox(
        width: widget.width,
        child: AspectRatio(aspectRatio: ratio, child: view),
      );
    } else if (widget.height != null) {
      view = SizedBox(
        height: widget.height,
        child: AspectRatio(aspectRatio: ratio, child: view),
      );
    }

    return ExcludeSemantics(child: Center(child: view));
  }
}