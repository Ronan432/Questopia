import 'dart:convert';
import 'package:flutter/foundation.dart';

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

    debugPrint('[HtmlProcessor] processHtml length: ${html.length} chars');

    var result = html;

    // Convert [img] tags
    if (result.contains('[img]') || result.contains('[IMG]')) {
      result = result.replaceAllMapped(_bbcodeImgRegExp, (match) {
        final raw = match.group(1)?.trim() ?? '';
        final clean = raw.replaceAll(r'\', '/');
        debugPrint('[HtmlProcessor] Converted [img] tag: "$raw" -> "$clean"');
        return '<img src="$clean" />';
      });
    }

    // Normalize unquoted src=path to src="path"
    result = result.replaceAllMapped(_imgUnquotedSrcRegExp, (match) {
      final before = match.group(1) ?? '';
      final src = match.group(2) ?? '';
      final after = match.group(3) ?? '';
      final normalized = src.replaceAll(r'\', '/');
      debugPrint('[HtmlProcessor] Normalized unquoted image src: "$src" -> "$normalized"');
      return '<img$before src="$normalized"$after>';
    });

    // Normalize backslashes inside quoted src="..."
    result = result.replaceAllMapped(_imgQuotedSrcRegExp, (match) {
      final before = match.group(1) ?? '';
      final quote = match.group(2) ?? '"';
      final src = match.group(3) ?? '';
      final after = match.group(4) ?? '';
      final normalized = src.replaceAll(r'\', '/');
      if (src != normalized) {
        debugPrint('[HtmlProcessor] Normalized quoted image src backslashes: "$src" -> "$normalized"');
      }
      return '<img$before src=$quote$normalized$quote$after>';
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
    final lower = payload.toLowerCase();
    final execIdx = lower.indexOf('exec:');
    if (execIdx != -1) {
      payload = payload.substring(execIdx + 5);
    } else {
      final execEncodedIdx = lower.indexOf('exec%3a');
      if (execEncodedIdx != -1) {
        payload = payload.substring(execEncodedIdx + 7);
      } else if (lower.startsWith('exec:')) {
        payload = payload.substring(5);
      }
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
    r'<img([^>]*?)\bsrc\s*=\s*["\x27]?([^"\x27\s>]*?\.(?:mp4|webm|ogv|ogg|m4v|mov|avi|mkv|3gp|flv))["\x27]?([^>]*?)>',
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
    var count = 0;
    final wrapped = html.replaceAllMapped(_videoImgRegExp, (match) {
      count++;
      final src = match.group(2) ?? '';
      debugPrint('[HtmlProcessor] Wrapping video file in img tag ($count): source "$src" converted to <video>');
      return '<video src="$src" autoplay loop muted playsinline webkit-playsinline preload="auto" style="max-width:100%;height:auto;display:block;margin:8px auto;border-radius:6px;object-fit:contain;background-color:transparent;pointer-events:auto;"></video>';
    });
    if (count > 0) {
      debugPrint('[HtmlProcessor] Total video tags wrapped: $count');
    }
    return wrapped;
  }

  /// Backward-compatible alias for wrapVideos.
  static String wrapOgvVideos(String html) => wrapVideos(html);

  /// Video bootstrap script: automatically starts playback, enforces looping,
  /// handles webview autoplay policies, and attaches OGV.js fallback for .ogv files.
  static String videoBootstrapScript() {
    return '''
<script src="https://questopia.local/ogv/ogv-support.js"></script>
<script src="https://questopia.local/ogv/ogv.js"></script>
<script>
(function() {
  window.OGVLoader = window.OGVLoader || {};
  window.OGVLoader.base = 'https://questopia.local/ogv';

  function hookVideos() {
    var videos = document.querySelectorAll('video');
    videos.forEach(function(v) {
      if (v.dataset.videoProcessed) return;

      var src = v.getAttribute('src') || v.src || '';
      if (!src && v.querySelector('source')) {
        src = v.querySelector('source').getAttribute('src') || '';
      }

      var isOgv = /\\.og[gv](\\?|#|\$)/i.test(src);

      if (isOgv && typeof OGVPlayer !== 'undefined') {
        try {
          var canPlay = v.canPlayType && (v.canPlayType('video/ogg; codecs="theora"') || v.canPlayType('video/ogg'));
          if (!canPlay || canPlay === '') {
            v.dataset.videoProcessed = '1';
            var player = new OGVPlayer({
              base: 'https://questopia.local/ogv',
              worker: false
            });
            player.src = src;
            player.muted = true;
            player.loop = true;
            player.autoplay = true;

            player.style.maxWidth = '100%';
            player.style.width = '100%';
            player.style.height = 'auto';
            player.style.display = 'block';
            player.style.margin = '8px auto';
            player.style.borderRadius = '6px';
            player.style.objectFit = 'contain';
            player.style.pointerEvents = 'auto';

            if (v.parentNode) {
              v.parentNode.replaceChild(player, v);
            }
            player.play();
            return;
          }
        } catch (e) {
          console.error('[OGV.js] Failed to initialize OGVPlayer for', src, e);
        }
      }

      v.dataset.videoProcessed = '1';
      v.autoplay = true;
      v.loop = true;
      v.muted = true;
      v.playsInline = true;
      v.setAttribute('playsinline', '');
      v.setAttribute('webkit-playsinline', '');
      v.setAttribute('autoplay', '');
      v.setAttribute('loop', '');
      v.setAttribute('muted', '');

      v.onended = function() {
        v.currentTime = 0;
        v.play().catch(function(){});
      };

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
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', hookVideos);
  } else {
    hookVideos();
  }
  window.addEventListener('load', hookVideos);
  setInterval(hookVideos, 250);
})();
</script>''';
  }

  /// Alias for backward compatibility
  static String ogvBootstrapScript() => videoBootstrapScript();

  /// Removes all image tags for text-only mode (`pref_disable_image`).
  static String stripImageTags(String html) {
    if (html.isEmpty) return html;
    debugPrint('[HtmlProcessor] Stripping all image tags for text-only mode');
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
    String mime;
    if (lower.endsWith('.html') || lower.endsWith('.htm')) {
      mime = 'text/html';
    } else if (lower.endsWith('.css')) {
      mime = 'text/css';
    } else if (lower.endsWith('.js')) {
      mime = 'application/javascript';
    } else if (lower.endsWith('.wasm')) {
      mime = 'application/wasm';
    } else if (lower.endsWith('.json')) {
      mime = 'application/json';
    } else if (lower.endsWith('.png')) {
      mime = 'image/png';
    } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      mime = 'image/jpeg';
    } else if (lower.endsWith('.gif')) {
      mime = 'image/gif';
    } else if (lower.endsWith('.webp')) {
      mime = 'image/webp';
    } else if (lower.endsWith('.bmp')) {
      mime = 'image/bmp';
    } else if (lower.endsWith('.svg')) {
      mime = 'image/svg+xml';
    } else if (lower.endsWith('.ogv') || lower.endsWith('.ogg')) {
      mime = 'video/ogg';
    } else if (lower.endsWith('.mp4') || lower.endsWith('.m4v')) {
      mime = 'video/mp4';
    } else if (lower.endsWith('.webm')) {
      mime = 'video/webm';
    } else if (lower.endsWith('.mov')) {
      mime = 'video/quicktime';
    } else if (lower.endsWith('.avi')) {
      mime = 'video/x-msvideo';
    } else if (lower.endsWith('.mkv')) {
      mime = 'video/x-matroska';
    } else if (lower.endsWith('.mp3')) {
      mime = 'audio/mpeg';
    } else if (lower.endsWith('.wav')) {
      mime = 'audio/wav';
    } else if (lower.endsWith('.mid') || lower.endsWith('.midi')) {
      mime = 'audio/midi';
    } else if (lower.endsWith('.qsp') || lower.endsWith('.gam')) {
      mime = 'application/octet-stream';
    } else {
      mime = 'application/octet-stream';
    }

    debugPrint('[HtmlProcessor] mimeTypeForPath("$path") => $mime');
    return mime;
  }
}
