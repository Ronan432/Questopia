import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:questopia_re/core/media/game_media.dart';

void main() {
  group('yandexBaseForLocale', () {
    test('selects the Russian endpoint family', () {
      for (final lang in ['ru', 'be', 'kk']) {
        expect(yandexBaseForLocale(lang), 'https://yandex.ru/images/search');
      }
    });

    test('falls back to the global endpoint', () {
      expect(yandexBaseForLocale('en'), 'https://yandex.com/images/search');
      expect(yandexBaseForLocale('de'), 'https://yandex.com/images/search');
      expect(yandexBaseForLocale('tr'), 'https://yandex.com/images/search');
    });
  });

  test('yandexDirectUrl encodes remote urls', () {
    const remote = 'https://example.com/a b.jpg';
    final url = yandexDirectUrl(remote);
    expect(url, contains('rpt=imageview&url='));
    expect(url, contains(Uri.encodeComponent(remote)));
  });

  group('yandexResultUrl', () {
    test('prefers cbirId', () {
      final url = yandexResultUrl({
        'blocks': [
          {
            'params': {
              'cbirId': 'abc 123',
              'originalImageUrl': 'https://example.com/o.jpg',
              'url': 'https://example.com/q',
            },
          },
        ],
      });
      expect(
        url,
        'https://yandex.com/images/search?rpt=imageview&cbir_id=${Uri.encodeComponent('abc 123')}',
      );
    });

    test('falls back to the original image url', () {
      final url = yandexResultUrl({
        'blocks': [
          {
            'params': {'originalImageUrl': 'https://example.com/o.jpg'},
          },
        ],
      });
      expect(url, contains('url=${Uri.encodeComponent('https://example.com/o.jpg')}'));
    });

    test('accepts absolute query urls as-is', () {
      final url = yandexResultUrl({
        'blocks': [
          {
            'params': {'url': 'https://yandex.com/images/search?x=1'},
          },
        ],
      });
      expect(url, 'https://yandex.com/images/search?x=1');
    });

    test('falls back to the gallery on empty payloads', () {
      expect(yandexResultUrl({}), kYandexFallbackUrl);
      expect(yandexResultUrl({'blocks': []}), kYandexFallbackUrl);
    });
  });

  test('prepareUploadBytes keeps small images untouched', () {
    final small = Uint8List.fromList(List.filled(1000, 7));
    expect(prepareUploadBytes(small), same(small));
  });

  group('MediaService', () {
    test('copyImage writes the reference to the clipboard writer', () async {
      String? written;
      final service = MediaService(
        clipboardWriter: (text) async => written = text,
      );
      expect(await service.copyImage('  /g/poster.jpg '), isTrue);
      expect(written, '/g/poster.jpg');
    });

    test('saveToGallery stores bytes with the Questopia album', () async {
      Uint8List? savedBytes;
      String? savedAlbum;
      final service = MediaService(
        imageBytesReader: (_) async => Uint8List.fromList([1, 2, 3]),
        gallerySaver: (bytes, {album}) async {
          savedBytes = bytes;
          savedAlbum = album;
        },
      );
      expect(await service.saveToGallery('x.jpg'), isTrue);
      expect(savedBytes, [1, 2, 3]);
      expect(savedAlbum, kMediaAlbumName);
    });

    test('saveToGallery fails without bytes', () async {
      final service = MediaService(
        imageBytesReader: (_) async => null,
        gallerySaver: (_, {album}) async => throw StateError('nope'),
      );
      expect(await service.saveToGallery('x.jpg'), isFalse);
    });

    test('resolveSearchUrl handles remote urls directly', () async {
      final service = MediaService(
        urlOpener: (_) async {},
      );
      final url = await service.resolveSearchUrl('https://example.com/a.jpg');
      expect(url, startsWith('https://yandex.com/images/search?rpt=imageview'));
    });

    test('resolveSearchUrl uploads local images and parses cbirId', () async {
      Uri? posted;
      final service = MediaService(
        imageBytesReader: (_) async => Uint8List.fromList([1, 2, 3]),
        uploader: (url, bytes) async {
          posted = url;
          return http.Response(
            jsonEncode({
              'blocks': [
                {'params': {'cbirId': 'cid-9'}},
              ],
            }),
            200,
          );
        },
      );
      final url = await service.resolveSearchUrl('/g/poster.jpg',
          languageCode: 'en');
      expect(posted.toString(), startsWith('https://yandex.com/'));
      expect(url, contains('cbir_id=cid-9'));
    });

    test('resolveSearchUrl falls back when the upload fails', () async {
      final service = MediaService(
        imageBytesReader: (_) async => Uint8List.fromList([1]),
        uploader: (_, __) async => http.Response('err', 500),
      );
      expect(
        await service.resolveSearchUrl('/g/poster.jpg'),
        kYandexFallbackUrl,
      );
    });

    test('searchImage opens the resolved url', () async {
      Uri? opened;
      final service = MediaService(
        urlOpener: (url) async => opened = url,
      );
      expect(
        await service.searchImage('https://example.com/a.jpg'),
        isTrue,
      );
      expect(opened.toString(), contains('yandex.com'));
    });
  });
}
