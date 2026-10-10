import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/core/helpers/html_processor.dart';

void main() {
  group('decodeExecUrl', () {
    test('decodes base64 payloads', () {
      const code = 'money = 500';
      final b64 = base64Encode(utf8.encode(code));
      expect(
        HtmlProcessor.decodeExecUrl('exec:base64:$b64'),
        code,
      );
    });

    test('normalizes line break tags in plain payloads', () {
      expect(
        HtmlProcessor.decodeExecUrl('exec:a<br>b<p>c'),
        'a\nb\nc',
      );
    });
  });
}