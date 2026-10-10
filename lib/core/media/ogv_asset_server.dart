import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ogv_player_page.dart';

/// Loopback HTTP server that exposes the bundled OGV.js decoder and game media
/// files to the embedded WebView.
///
/// The WebView cannot open game storage directly: Android blocks `file://`
/// reads from a remote origin, and a data URI cannot answer the byte range
/// requests that the OGV.js stream loader issues. Serving everything from
/// `127.0.0.1` keeps range streaming intact while staying on the device, and
/// the decoder page is served from the same origin so no cross-origin
/// handshake is required.
class OgvAssetServer {
  OgvAssetServer._(this._server);

  final HttpServer _server;

  static OgvAssetServer? _active;

  /// Base URL of the loopback server, without a trailing slash.
  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  /// Returns the shared server, starting it on first use.
  ///
  /// The server lives for the whole session. Reusing one instance avoids port
  /// churn and lets several videos stream at the same time.
  static Future<OgvAssetServer> ensureStarted() async {
    final existing = _active;
    if (existing != null) return existing;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = OgvAssetServer._(server);
    _active = instance;
    instance._listen();
    return instance;
  }

  static const _mimeTypes = <String, String>{
    '.js': 'text/javascript; charset=utf-8',
    '.wasm': 'application/wasm',
    '.ogv': 'video/ogg',
    '.ogg': 'video/ogg',
  };

  static String _mimeFor(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return 'application/octet-stream';
    return _mimeTypes[path.substring(dot).toLowerCase()] ??
        'application/octet-stream';
  }

  void _listen() {
    _server.listen(
      (request) {
        unawaited(_handle(request));
      },
      onError: (Object _) {},
    );
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (path.startsWith('/ogv/')) {
        await _serveAsset(request, path.substring('/ogv/'.length));
      } else if (path == '/media') {
        await _serveMedia(request);
      } else if (path == '/player') {
        await _servePlayer(request);
      } else {
        await _close(request, HttpStatus.notFound);
      }
    } catch (_) {
      await _close(request, HttpStatus.internalServerError);
    }
  }

  Future<void> _close(HttpRequest request, int status) async {
    try {
      final response = request.response
        ..statusCode = status
        ..headers.contentLength = 0;
      await response.close();
    } catch (_) {
      // The client may have disconnected already.
    }
  }

  Future<void> _serveAsset(HttpRequest request, String name) async {
    final safe = name.contains('/') ? name.split('/').last : name;
    try {
      final data = await rootBundle.load('assets/ogv/$safe');
      final bytes = data.buffer.asUint8List();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.parse(_mimeFor(safe))
        ..headers.contentLength = bytes.length
        ..headers.set(HttpHeaders.cacheControlHeader, 'max-age=604800')
        ..add(bytes);
      await request.response.close();
    } catch (_) {
      await _close(request, HttpStatus.notFound);
    }
  }

  Future<void> _servePlayer(HttpRequest request) async {
    final source = request.uri.queryParameters['src'] ?? '';
    if (source.isEmpty) {
      await _close(request, HttpStatus.badRequest);
      return;
    }
    final muted = request.uri.queryParameters['muted'] == '1';
    final loop = request.uri.queryParameters['loop'] == '1';
    final autoplay = request.uri.queryParameters['autoplay'] != '0';

    final html = OgvPlayerPage.build(
      mediaUrl: '/media?path=${Uri.encodeQueryComponent(source)}',
      muted: muted,
      loop: loop,
      autoplay: autoplay,
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..headers.contentLength = html.length
      ..write(html);
    await request.response.close();
  }

  Future<void> _serveMedia(HttpRequest request) async {
    final raw = request.uri.queryParameters['path'] ?? '';
    if (raw.isEmpty) {
      await _close(request, HttpStatus.badRequest);
      return;
    }

    final file = File(raw);
    if (!file.existsSync()) {
      await _close(request, HttpStatus.notFound);
      return;
    }

    final length = await file.length();
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

    if (rangeHeader == null) {
      final response = request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.parse(_mimeFor(raw))
        ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..headers.contentLength = length;
      await response.addStream(file.openRead());
      await response.close();
      return;
    }

    await _serveRange(request, file, length);
  }

  Future<void> _serveRange(
    HttpRequest request,
    File file,
    int length,
  ) async {
    final response = request.response;
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader) ?? '';
    final match = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(rangeHeader);
    if (match == null) {
      final fallback = request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentLength = length;
      await fallback.addStream(file.openRead());
      await fallback.close();
      return;
    }

    final startText = match.group(1) ?? '';
    final endText = match.group(2) ?? '';

    int start;
    int end;
    if (startText.isEmpty) {
      final suffix = int.tryParse(endText) ?? 0;
      if (suffix <= 0) return _rejectRange(response);
      start = length - suffix;
      end = length - 1;
    } else {
      start = int.tryParse(startText) ?? 0;
      end = endText.isEmpty ? length - 1 : (int.tryParse(endText) ?? length - 1);
    }

    if (start < 0 || start >= length) return _rejectRange(response);
    if (end >= length) end = length - 1;
    if (end < start) end = start;

    response
      ..statusCode = HttpStatus.partialContent
      ..headers.contentType = ContentType.parse(_mimeFor(file.path))
      ..headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$length')
      ..headers.contentLength = end - start + 1;

    await response.addStream(file.openRead(start, end + 1));
    await response.close();
  }

  /// Replies with an empty unsatisfiable range.
  ///
  /// The declared full length must be cleared, otherwise the stream client
  /// waits forever for a body that never arrives.
  Future<void> _rejectRange(HttpResponse response) async {
    response
      ..statusCode = HttpStatus.requestedRangeNotSatisfiable
      ..headers.contentLength = 0
      ..headers.removeAll(HttpHeaders.contentTypeHeader);
    await response.close();
  }

  @visibleForTesting
  Future<void> stop() async {
    if (!identical(_active, this)) return;
    _active = null;
    try {
      await _server.close(force: true);
    } catch (_) {
      // Already closed.
    }
  }
}