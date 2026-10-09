import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A high-performance, GPU-cached poster image widget using ExtendedImage and flutter_svg.
///
/// Features:
/// - Hardware-accelerated memory/disk caching via [ExtendedImage].
/// - Native vector rendering for SVGs via [SvgPicture].
/// - Downsamples decoded raster bitmaps using [cacheWidth] to prevent memory thrashing.
/// - Avoids cascading recursive network storms on missing posters (preventing ANRs).
class GamePoster extends StatelessWidget {
  const GamePoster({
    super.key,
    this.localPath,
    this.remoteUrl,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius,
    this.isLocal = false,
  });

  final String? localPath;
  final String? remoteUrl;
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  final bool isLocal;

  bool _isSvg(String uri) {
    final lower = uri.toLowerCase().trim();
    return lower.endsWith('.svg') || lower.contains('.svg?');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget content;

    if (isLocal) {
      final path = localPath ?? '';
      final file = path.isNotEmpty ? File(path) : null;
      if (file != null && file.existsSync()) {
        if (_isSvg(path)) {
          content = SvgPicture.file(
            file,
            height: height,
            width: width,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => _buildPlaceholder(colors),
          );
        } else {
          content = ExtendedImage.file(
            file,
            height: height,
            width: width,
            fit: BoxFit.cover,
            cacheWidth: 400,
            cacheHeight: 400,
            clearMemoryCacheWhenDispose: true,
            loadStateChanged: (state) {
              switch (state.extendedImageLoadState) {
                case LoadState.loading:
                  return _buildLoading(colors);
                case LoadState.failed:
                  return _buildPlaceholder(colors);
                case LoadState.completed:
                  return null;
              }
            },
          );
        }
      } else {
        content = _buildPlaceholder(colors);
      }
    } else {
      final url = (remoteUrl ?? '').trim();
      final uri = Uri.tryParse(url);
      final isValidHttp = uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;

      if (!isValidHttp || url.isEmpty) {
        content = _buildPlaceholder(colors);
      } else if (_isSvg(url)) {
        content = SvgPicture.network(
          url,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://qsp.org/',
          },
          height: height,
          width: width,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _buildPlaceholder(colors),
        );
      } else {
        content = ExtendedImage.network(
          url,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://qsp.org/',
          },
          height: height,
          width: width,
          fit: BoxFit.cover,
          cache: true,
          cacheWidth: 400,
          cacheHeight: 400,
          printError: false,
          clearMemoryCacheWhenDispose: true,
          loadStateChanged: (state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                return _buildLoading(colors);
              case LoadState.failed:
                return _buildPlaceholder(colors);
              case LoadState.completed:
                return null;
            }
          },
        );
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(height: height, width: width, child: content),
      );
    }

    return SizedBox(height: height, width: width, child: content);
  }

  Widget _buildLoading(ColorScheme colors) {
    return Container(
      height: height,
      width: width,
      color: colors.surfaceContainerHigh,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colors) {
    return Container(
      height: height,
      width: width,
      color: isLocal ? colors.secondaryContainer : colors.tertiaryContainer,
      child: Center(
        child: Icon(
          isLocal ? Icons.auto_stories_rounded : Icons.cloud_download_rounded,
          size: 36,
          color: isLocal
              ? colors.onSecondaryContainer
              : colors.onTertiaryContainer,
        ),
      ),
    );
  }
}
