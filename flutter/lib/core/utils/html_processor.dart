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
}
