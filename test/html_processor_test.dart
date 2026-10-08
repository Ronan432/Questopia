import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/core/helpers/html_processor.dart';

void main() {
  group('wrapOgvVideos', () {
    test('converts ogv images to video tags', () {
      const html = '<p>Hi</p><img src="cutscene.ogv">';
      final out = HtmlProcessor.wrapOgvVideos(html);
      expect(out, contains('<video src="cutscene.ogv"'));
      expect(out, isNot(contains('<img')));
      expect(out, contains('<p>Hi</p>'));
    });

    test('leaves regular images untouched', () {
      const html = '<img src="poster.jpg">';
      expect(HtmlProcessor.wrapOgvVideos(html), html);
    });

    test('handles empty input', () {
      expect(HtmlProcessor.wrapOgvVideos(''), '');
    });
  });

  test('ogvBootstrapScript references the local decoder', () {
    final script = HtmlProcessor.ogvBootstrapScript();
    expect(script, contains('https://questopia.local/ogv/ogv.js'));
    expect(script, contains('OGVPlayer'));
  });

  group('stripImageTags', () {
    test('removes all image tags', () {
      const html = '<p>A</p><img src="a.png"><IMG SRC="b.jpg">';
      expect(HtmlProcessor.stripImageTags(html), '<p>A</p>');
    });

    test('handles empty input', () {
      expect(HtmlProcessor.stripImageTags(''), '');
    });
  });

  group('mimeTypeForPath', () {
    test('resolves common game media types', () {
      expect(HtmlProcessor.mimeTypeForPath('a.png'), 'image/png');
      expect(HtmlProcessor.mimeTypeForPath('a.JPG'), 'image/jpeg');
      expect(HtmlProcessor.mimeTypeForPath('movie.ogv'), 'video/ogg');
      expect(HtmlProcessor.mimeTypeForPath('song.mp3'), 'audio/mpeg');
      expect(HtmlProcessor.mimeTypeForPath('lib.wasm'), 'application/wasm');
      expect(HtmlProcessor.mimeTypeForPath('code.js'),
          'application/javascript');
      expect(
          HtmlProcessor.mimeTypeForPath('game.qsp'), 'application/octet-stream');
      expect(HtmlProcessor.mimeTypeForPath('mystery.xyz'),
          'application/octet-stream');
    });
  });

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
