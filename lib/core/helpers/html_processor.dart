import 'dart:convert';

class HtmlProcessor {
  static final RegExp _execRegExp = RegExp(
    r'href\s*=\s*["\x27]exec:(.*?)["\x27]',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _imgQuotedSrcRegExp = RegExp(
    r'<img([^>]*?)\bsrc\s*=\s*(["\x27])([^"\x27]*?)\2([^>]*?)>',
    caseSensitive: false,
  );
  static final RegExp _imgUnquotedSrcRegExp = RegExp(
    r'<img([^>]*?)\bsrc\s*=\s*([^\s"\x27><]+)([^>]*?)>',
    caseSensitive: false,
  );
  static final RegExp _bbcodeImgRegExp = RegExp(
    r'\[img\](.*?)\[/img\]',
    caseSensitive: false,
  );

  /// Pre-processes QSP HTML content:
  /// - Base64-encodes multi-line exec: links for safe WebView dispatch
  /// - Normalizes Windows backslashes in image src paths
  /// - Enforces valid quotes on unquoted src attributes
  /// - Converts [img]...[/img] BBCode to standard <img> tags
  static String processHtml(String html) {
    if (html.isEmpty) return html;

    var result = html;

    // Convert [img] tags
    if (result.contains('[img]') || result.contains('[IMG]')) {
      result = result.replaceAllMapped(_bbcodeImgRegExp, (match) {
        final raw = match.group(1)?.trim() ?? '';
        final clean = raw.replaceAll(r'\', '/');
        return '<img src="$clean" />';
      });
    }

    // Normalize unquoted src=path to src="path"
    result = result.replaceAllMapped(_imgUnquotedSrcRegExp, (match) {
      final before = match.group(1) ?? '';
      final src = match.group(2) ?? '';
      final after = match.group(3) ?? '';
      return '<img$before src="${src.replaceAll(r'\', '/')}"$after>';
    });

    // Normalize backslashes inside quoted src="..."
    result = result.replaceAllMapped(_imgQuotedSrcRegExp, (match) {
      final before = match.group(1) ?? '';
      final quote = match.group(2) ?? '"';
      final src = match.group(3) ?? '';
      final after = match.group(4) ?? '';
      return '<img$before src=$quote${src.replaceAll(r'\', '/')}$quote$after>';
    });

    // Base64-encode multi-line exec links
    result = result.replaceAllMapped(_execRegExp, (match) {
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

    return result;
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

  static final RegExp _videoImgRegExp = RegExp(
    r'<img([^>]*?)\bsrc\s*=\s*["\x27]?([^"\x27\s>]*?\.(?:mp4|webm|ogv|ogg|m4v|mov))["\x27]?([^>]*?)>',
    caseSensitive: false,
  );
  static final RegExp _imgRegExp = RegExp(
    r'<img[^>]*?>',
    caseSensitive: false,
  );

  /// Converts all video files in `<img>` tags (`.mp4`, `.webm`, `.ogv`, `.ogg`, etc.)
  /// into looping, muted, autoplaying `<video>` elements.
  static String wrapVideos(String html) {
    if (html.isEmpty) return html;
    return html.replaceAllMapped(_videoImgRegExp, (match) {
      final src = match.group(2) ?? '';
      return '<video src="$src" autoplay loop muted playsinline webkit-playsinline preload="auto" style="max-width:100%;height:auto;display:block;margin:8px auto;border-radius:6px;object-fit:contain;background-color:transparent;"></video>';
    });
  }

  /// Backward-compatible alias for wrapVideos.
  static String wrapOgvVideos(String html) => wrapVideos(html);

  /// Video bootstrap script: automatically starts playback, enforces looping,
  /// handles webview autoplay policies, and attaches OGV.js fallback for .ogv files.
  static String videoBootstrapScript() {
    return '''
<script src="https://questopia.local/ogv/ogv.js"></script>
<script>
(function() {
  function setupVideos() {
    var videos = document.querySelectorAll('video');
    videos.forEach(function(v) {
      v.autoplay = true;
      v.loop = true;
      v.muted = true;
      v.playsInline = true;
      v.setAttribute('playsinline', '');
      v.setAttribute('webkit-playsinline', '');
      v.setAttribute('autoplay', '');
      v.setAttribute('loop', '');
      v.setAttribute('muted', '');
      
      // Enforce loop restart
      v.onended = function() {
        v.currentTime = 0;
        v.play().catch(function(){});
      };
      
      // Auto play attempt
      var playPromise = v.play();
      if (playPromise !== undefined) {
        playPromise.catch(function() {
          var resumeOnTouch = function() {
            v.play().catch(function(){});
            document.removeEventListener('touchstart', resumeOnTouch);
          };
          document.addEventListener('touchstart', resumeOnTouch, {once: true});
        });
      }

      // OGV fallback
      var src = v.getAttribute('src') || '';
      if (/\\.og[gv](\\?|#|\$)/i.test(src) && !v.dataset.ogvHooked && typeof OGVPlayer !== 'undefined') {
        try {
          var canPlay = v.canPlayType('video/ogg; codecs="theora"');
          if (!canPlay) {
            v.dataset.ogvHooked = '1';
            var player = new OGVPlayer({video: v});
            player.loop = true;
            player.muted = true;
            player.play();
          }
        } catch (e) {}
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupVideos);
  } else {
    setupVideos();
  }
  window.addEventListener('load', setupVideos);
  setTimeout(setupVideos, 200);
  setTimeout(setupVideos, 600);
})();
</script>''';
  }

  /// Alias for backward compatibility
  static String ogvBootstrapScript() => videoBootstrapScript();

  /// Removes all image tags for text-only mode (`pref_disable_image`).
  static String stripImageTags(String html) {
    if (html.isEmpty) return html;
    return html.replaceAll(_imgRegExp, '');
  }

  /// Strips all HTML tags to return plain text (useful for action buttons).
  static String stripHtmlTags(String html) {
    if (html.isEmpty) return html;
    return html
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false, dotAll: true), '')
        .trim();
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
