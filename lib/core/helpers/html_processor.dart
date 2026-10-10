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
}
