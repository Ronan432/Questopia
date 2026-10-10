import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Plays Ogg Theora video through the bundled OGV.js WebAssembly decoder.
///
/// The platform video decoder cannot play Theora, so `.ogv` files fail with an
/// unsupported container error. OGV.js is a WebAssembly port of the Theora and
/// Vorbis decoders that renders into a canvas inside a small headless WebView.
/// Every other container keeps using the system decoder, so this heavier path
/// only activates for Ogg video.
///
/// The decoder scripts and their WebAssembly binaries are embedded into the
/// generated page as data URIs. That keeps the WebView free of any file or
/// network scheme handling, which the embedded WebView cannot serve.
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

  Future<String> _uriFor(String assetPath, String mime) async {
    final data = await rootBundle.load(assetPath);
    return 'data:$mime;base64,${base64Encode(data.buffer.asUint8List())}';
  }

  /// Builds a loader script that resolves every decoder class from embedded
  /// data URIs instead of the original network or file locations.
  Future<String> _buildLoaderScript() async {
    final classScripts = <String, String>{
      'ogv-demuxer-ogg-wasm.js': await _uriFor(
        'assets/ogv/ogv-demuxer-ogg-wasm.js',
        'text/javascript',
      ),
      'ogv-decoder-video-theora-wasm.js': await _uriFor(
        'assets/ogv/ogv-decoder-video-theora-wasm.js',
        'text/javascript',
      ),
      'ogv-decoder-audio-vorbis-wasm.js': await _uriFor(
        'assets/ogv/ogv-decoder-audio-vorbis-wasm.js',
        'text/javascript',
      ),
    };

    final classWasm = <String, String>{
      'ogv-demuxer-ogg-wasm.wasm': await _uriFor(
        'assets/ogv/ogv-demuxer-ogg-wasm.wasm',
        'application/wasm',
      ),
      'ogv-decoder-video-theora-wasm.wasm': await _uriFor(
        'assets/ogv/ogv-decoder-video-theora-wasm.wasm',
        'application/wasm',
      ),
      'ogv-decoder-audio-vorbis-wasm.wasm': await _uriFor(
        'assets/ogv/ogv-decoder-audio-vorbis-wasm.wasm',
        'application/wasm',
      ),
    };

    // Each loader script declares one WebAssembly module. The Emscripten
    // runtime asks for the binary through `locateFile`, so the global hook
    // hands back the matching embedded payload.
    final resolver = <String, String>{
      ...classScripts,
      ...classWasm,
    };
    final resolverJson = jsonEncode(resolver);

    return '''
(function () {
  var OGV_FILES = $resolverJson;

  OGVLoader.loadScript = function (url, callback) {
    var name = String(url).split('?')[0].split('/').pop();
    var entry = OGV_FILES[name];
    if (!entry) { callback(); return; }
    var script = document.createElement('script');
    var done = function () { callback(); };
    script.addEventListener('load', done);
    script.addEventListener('error', done);
    script.src = entry;
    document.head.appendChild(script);
  };

  OGVLoader.locateFile = function (path) {
    var name = String(path).split('?')[0].split('/').pop();
    return OGV_FILES[name] || path;
  };

  OGVLoader.base = '';
  window.__ogvAssetMap = OGV_FILES;
})();
''';
  }

  Future<String> _buildHtml() async {
    final support = await _uriFor('assets/ogv/ogv-support.js', 'text/javascript');
    final ogv = await _uriFor('assets/ogv/ogv.js', 'text/javascript');
    final loader = await _buildLoaderScript();
    final src = jsonEncode(widget.path);
    final muted = widget.muted;
    final autoplay = widget.autoplay;
    final loop = widget.loop;

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  html, body { margin: 0; padding: 0; background: transparent; overflow: hidden; }
  canvas { display: block; max-width: 100%; height: auto; margin: 0 auto; }
</style>
</head>
<body>
<script src="$support"></script>
<script src="$ogv"></script>
<script>$loader</script>
<script>
(function () {
  var opts = {
    muted: $muted,
    loop: $loop,
    autoplay: false,
    target: document.body
  };
  try {
    var player = new OGVPlayer(opts);
    player.src = $src;
    player.addEventListener('loadeddata', function () {
      $autoplay ? player.play() : null;
    });
  } catch (err) {
    window.__ogvFailed = true;
  }
})();
</script>
</body>
</html>''';
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (_) => NavigationDecision.prevent,
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _failed = true);
          },
        ),
      );

    final html = await _buildHtml();
    await controller.loadHtmlString(html);

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  Future<void> _restart() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript('document.querySelector("video")?.play();');
    } catch (_) {
      // Autoplay can be refused until the first user interaction, which is
      // acceptable here because the surrounding game screen is that gesture.
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
            onTap: _restart,
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