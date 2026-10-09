import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';

const String kYandexFallbackUrl = 'https://yandex.com/images/';
const String kMediaAlbumName = 'Questopia';

String yandexBaseForLocale(String languageCode) {
  final lang = languageCode.toLowerCase();
  if (lang == 'ru' || lang == 'be' || lang == 'kk') {
    return 'https://yandex.ru/images/search';
  }
  return 'https://yandex.com/images/search';
}

String yandexUploadUrl(String languageCode) {
  const request =
      '%7B%22blocks%22%3A%5B%7B%22block%22%3A%22b-page_type_search-by-image__link%22%7D%5D%7D';
  return '${yandexBaseForLocale(languageCode)}?rpt=imageview&format=json&request=$request';
}

String yandexDirectUrl(String remoteUrl) {
  return '${yandexBaseForLocale('en')}?rpt=imageview&url=${Uri.encodeComponent(remoteUrl)}';
}

String yandexResultUrl(Map<String, dynamic> json) {
  try {
    final blocks = json['blocks'];
    if (blocks is List && blocks.isNotEmpty) {
      final first = blocks.first;
      final params = first is Map ? first['params'] : null;
      if (params is Map) {
        final cbirId = params['cbirId']?.toString() ?? '';
        if (cbirId.isNotEmpty) {
          return 'https://yandex.com/images/search?rpt=imageview&cbir_id=${Uri.encodeComponent(cbirId)}';
        }
        final original = params['originalImageUrl']?.toString() ?? '';
        if (original.isNotEmpty) {
          return 'https://yandex.com/images/search?rpt=imageview&url=${Uri.encodeComponent(original)}';
        }
        final query = params['url']?.toString() ?? '';
        if (query.isNotEmpty) {
          if (query.startsWith('http')) return query;
          return 'https://yandex.com/images/search?$query';
        }
      }
    }
  } catch (_) {
    // Fall through to the gallery fallback.
  }
  return kYandexFallbackUrl;
}

bool isRemoteUrl(String value) {
  final lower = value.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

Uint8List prepareUploadBytes(Uint8List rawBytes) {
  return rawBytes;
}

typedef ImageBytesReader = Future<Uint8List?> Function(String imagePathOrUrl);
typedef MultipartUploader = Future<http.Response> Function(
    Uri url, Uint8List bytes);
typedef UrlOpener = Future<void> Function(Uri url);
typedef GallerySaver = Future<void> Function(Uint8List bytes, {String? album});
typedef ClipboardWriter = Future<void> Function(String text);

Future<Uint8List?> defaultImageBytesReader(String imagePathOrUrl) async {
  final value = imagePathOrUrl.trim();
  if (value.isEmpty) return null;
  if (isRemoteUrl(value)) {
    try {
      final response =
          await http.get(Uri.parse(value)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }
  try {
    var path = value;
    if (path.toLowerCase().startsWith('file://')) {
      path = Uri.parse(path).toFilePath();
    }
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}

Future<http.Response> defaultMultipartUploader(
    Uri url, Uint8List bytes) async {
  final request = http.MultipartRequest('POST', url)
    ..headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    ..headers['Accept'] = 'application/json, text/javascript, */*; q=0.01'
    ..headers['X-Requested-With'] = 'XMLHttpRequest'
    ..files.add(http.MultipartFile.fromBytes(
      'upfile',
      bytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
  final streamed = await request.send().timeout(const Duration(seconds: 15));
  return http.Response.fromStream(streamed);
}

Future<void> defaultUrlOpener(Uri url) async {
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<void> defaultGallerySaver(Uint8List bytes, {String? album}) async {
  await Gal.putImageBytes(bytes, album: album ?? kMediaAlbumName);
}

Future<void> defaultClipboardWriter(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

enum MediaAction { copy, save, search }

final class MediaService {
  MediaService({
    ImageBytesReader? imageBytesReader,
    MultipartUploader? uploader,
    UrlOpener? urlOpener,
    GallerySaver? gallerySaver,
    ClipboardWriter? clipboardWriter,
  })  : _imageBytesReader = imageBytesReader ?? defaultImageBytesReader,
        _uploader = uploader ?? defaultMultipartUploader,
        _urlOpener = urlOpener ?? defaultUrlOpener,
        _gallerySaver = gallerySaver ?? defaultGallerySaver,
        _clipboardWriter = clipboardWriter ?? defaultClipboardWriter;

  final ImageBytesReader _imageBytesReader;
  final MultipartUploader _uploader;
  final UrlOpener _urlOpener;
  final GallerySaver _gallerySaver;
  final ClipboardWriter _clipboardWriter;

  Future<bool> copyImage(String imagePathOrUrl) async {
    try {
      await _clipboardWriter(imagePathOrUrl.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveToGallery(String imagePathOrUrl) async {
    try {
      final bytes = await _imageBytesReader(imagePathOrUrl);
      if (bytes == null || bytes.isEmpty) return false;
      await _gallerySaver(bytes, album: kMediaAlbumName);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> resolveSearchUrl(
    String imagePathOrUrl, {
    String languageCode = 'en',
  }) async {
    final value = imagePathOrUrl.trim();
    if (value.isEmpty) return null;
    if (isRemoteUrl(value)) return yandexDirectUrl(value);
    try {
      final rawBytes = await _imageBytesReader(value);
      if (rawBytes == null || rawBytes.isEmpty) return kYandexFallbackUrl;
      final bytes = prepareUploadBytes(rawBytes);
      final response =
          await _uploader(Uri.parse(yandexUploadUrl(languageCode)), bytes);
      if (response.statusCode != 200 || response.body.isEmpty) {
        return kYandexFallbackUrl;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return kYandexFallbackUrl;
      return yandexResultUrl(decoded);
    } catch (_) {
      return kYandexFallbackUrl;
    }
  }

  Future<bool> searchImage(
    String imagePathOrUrl, {
    String languageCode = 'en',
  }) async {
    try {
      final url = await resolveSearchUrl(imagePathOrUrl,
          languageCode: languageCode);
      if (url == null || url.isEmpty) return false;
      await _urlOpener(Uri.parse(url));
      return true;
    } catch (_) {
      return false;
    }
  }
}
