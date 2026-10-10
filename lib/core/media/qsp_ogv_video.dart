import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
      // Browsers refuse to start unmuted playback without a user gesture, and
      // game media is loaded automatically. Playback therefore begins muted and
      // the sound is enabled once the player reports ready.
      'muted': '1',
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
    try {
      final server = await OgvAssetServer.ensureStarted();
      final url = _playerUrl(server.baseUrl);
      debugPrint('[OgvVideo] baslatiliyor: $url');

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              debugPrint('[OgvVideo] gezinti: ${request.url}');
              // Only the local player page may load. Media is pulled over XHR
              // so no further navigation should ever be requested.
              return request.url.startsWith(server.baseUrl)
                  ? NavigationDecision.navigate
                  : NavigationDecision.prevent;
            },
            onPageFinished: (_) {
              debugPrint('[OgvVideo] sayfa yuklendi');
              if (mounted) setState(() => _ready = true);
            },
            onWebResourceError: (error) {
              debugPrint('[OgvVideo] kaynak hatasi: ${error.description}');
              // A failed subresource must not blank the whole widget, so the
              // error only takes effect when the page itself never loaded.
              if (!_ready && mounted) setState(() => _failed = true);
            },
          ),
        );

      await _allowAutomaticPlayback(controller);
      await controller.loadRequest(Uri.parse(url));

      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (error) {
      debugPrint('[OgvVideo] baslatma hatasi: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _resume() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript(
        'window.__ogvUnmute ? window.__ogvUnmute() : play();',
      );
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

  /// Lets the page start playback on its own.
  ///
  /// The WebView blocks any playback that is not tied to a user gesture, which
  /// would leave game media frozen on its first frame. The decoder only ever
  /// plays local game files, so the restriction buys nothing here.
  Future<void> _allowAutomaticPlayback(WebViewController controller) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final AndroidWebViewController android =
          controller.platform as AndroidWebViewController;
      await android.setMediaPlaybackRequiresUserGesture(false);
    } catch (_) {
      // Older platform implementations simply keep the default behaviour.
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || !_ready || controller == null) {
      return const SizedBox.shrink();
    }

    // The tap overlay only needs to sit above the player, and the stack must
    // fill a box of known size, so the media area is bounded before the stack
    // is built. QSP markup often omits width and height on the image tag, which
    // would otherwise leave the stack with an unbounded height.
    const ratio = 16 / 9;
    final surface = Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: controller),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _resume,
        ),
      ],
    );

    final Widget view;
    if (widget.width != null && widget.height != null) {
      view = SizedBox(width: widget.width, height: widget.height, child: surface);
    } else if (widget.width != null) {
      view = SizedBox(
        width: widget.width,
        child: AspectRatio(aspectRatio: ratio, child: surface),
      );
    } else if (widget.height != null) {
      view = SizedBox(
        height: widget.height,
        child: AspectRatio(aspectRatio: ratio, child: surface),
      );
    } else {
      view = AspectRatio(aspectRatio: ratio, child: surface);
    }

    return ExcludeSemantics(child: view);
  }
}