import 'dart:convert';

class HtmlProcessor {
  static final RegExp _execRegExp = RegExp(
    'href\\s*=\\s*["\']exec:(.*?)["\']',
    caseSensitive: false,
    dotAll: true,
  );

  /// Pre-processes QSP HTML content by base64-encoding multi-line exec: links
  /// to ensure safe rendering in WebViews and custom handlers.
  static String processHtml(String html) {
    if (html.isEmpty) return html;

    return html.replaceAllMapped(_execRegExp, (match) {
      final code = match.group(1) ?? '';
      if (code.contains('\n') || code.contains('\r') || code.contains('<br')) {
        final cleanCode = code
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n');
        final encoded = base64Encode(utf8.encode(cleanCode));
        return 'href="exec:base64:$encoded"';
      }
      return match.group(0)!;
    });
  }

  /// Decodes exec: URL payloads received from WebView link intercepts.
  static String decodeExecUrl(String rawUrl) {
    var payload = rawUrl;
    if (payload.toLowerCase().startsWith('exec:')) {
      payload = payload.substring(5);
    }

    if (payload.startsWith('base64:')) {
      try {
        final b64 = payload.substring(7);
        return utf8.decode(base64Decode(b64));
      } catch (_) {
        return payload;
      }
    }

    try {
      final decoded = Uri.decodeFull(payload);
      return decoded
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n');
    } catch (_) {
      return payload;
    }
  }

  static final RegExp _ogvImgRegExp = RegExp(
    '<img([^>]*?)src\\s*=\\s*["\']([^"\']*?\\.og[gv])(["\'][^>]*?)>',
    caseSensitive: false,
  );
  static final RegExp _imgRegExp = RegExp(
    r'<img[^>]*?>',
    caseSensitive: false,
  );

  /// Converts `.ogv`/`.ogg` image sources into `<video>` tags backed by the
  /// bundled OGV.js decoder, mirroring the legacy media pipeline.
  static String wrapOgvVideos(String html) {
    if (html.isEmpty) return html;
    return html.replaceAllMapped(_ogvImgRegExp, (match) {
      final src = match.group(2) ?? '';
      final rest = (match.group(1) ?? '') + (match.group(3) ?? '');
      final style = rest.contains('style=')
          ? ''
          : ' style="max-width:100%;height:auto;"';
      return '<video src="$src" controls preload="metadata"$style></video>';
    });
  }

  /// OGV.js bootstrap: when the browser cannot play OGV natively, the
  /// bundled decoder takes over `video[src$=".ogv"]` elements.
  static String ogvBootstrapScript() {
    return '''
<script src="https://questopia.local/ogv/ogv.js"></script>
<script>
(function() {
  function needsOgv(video) {
    var src = video.getAttribute('src') || '';
    if (!/\\.og[gv](\\?|#|\$)/i.test(src)) return false;
    try {
      var t = video.canPlayType('video/ogg; codecs="theora"');
      return !t;
    } catch (e) { return true; }
  }
  function hook() {
    if (typeof OGVPlayer === 'undefined') return;
    document.querySelectorAll('video[src]').forEach(function(video) {
      if (needsOgv(video) && !video.dataset.ogvHooked) {
        video.dataset.ogvHooked = '1';
        try { new OGVPlayer({video: video}); } catch (e) {}
      }
    });
  }
  document.addEventListener('DOMContentLoaded', hook);
  hook();
})();
</script>''';
  }

  /// Removes all image tags for text-only mode (`pref_disable_image`).
  static String stripImageTags(String html) {
    if (html.isEmpty) return html;
    return html.replaceAll(_imgRegExp, '');
  }

  /// Strips all HTML tags to return plain text (useful for action buttons).
  static String stripHtmlTags(String html) {
    if (html.isEmpty) return html;
    return html.replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '').trim();
  }

  /// MIME type lookup for the local media proxy (`questopia.local`).
  static String mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.html') || lower.endsWith('.htm')) return 'text/html';
    if (lower.endsWith('.css')) return 'text/css';
    if (lower.endsWith('.js')) return 'application/javascript';
    if (lower.endsWith('.wasm')) return 'application/wasm';
    if (lower.endsWith('.json')) return 'application/json';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.ogv') || lower.endsWith('.ogg')) return 'video/ogg';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.mid') || lower.endsWith('.midi')) return 'audio/midi';
    if (lower.endsWith('.qsp') || lower.endsWith('.gam')) {
      return 'application/octet-stream';
    }
    return 'application/octet-stream';
  }
}
