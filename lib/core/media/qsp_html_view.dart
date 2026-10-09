import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'qsp_media.dart';
import 'qsp_path_resolver.dart';

class QspHtmlView extends StatelessWidget {
  const QspHtmlView({
    super.key,
    required this.html,
    required this.resolver,
    this.textStyle,
    this.onTapLink,
  });

  final String html;
  final QspPathResolver resolver;
  final TextStyle? textStyle;
  final FutureOr<bool> Function(String url)? onTapLink;

  double? _parseDimension(String? v) {
    if (v == null || v.isEmpty) return null;
    final clean = v.replaceAll('px', '').replaceAll('%', '').trim();
    return double.tryParse(clean);
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: HtmlWidget(
        html,
        textStyle: textStyle,
        onTapUrl: onTapLink != null
            ? (url) async {
                return await onTapLink!(url);
              }
            : null,
        customWidgetBuilder: (element) {
          final tag = element.localName?.toLowerCase();
          if (tag != 'img' && tag != 'video') return null;

          var src = element.attributes['src'];
          if ((src == null || src.isEmpty) && tag == 'video') {
            final source = element.querySelector('source');
            src = source?.attributes['src'];
          }
          if (src == null || src.isEmpty) return null;

          final w = _parseDimension(element.attributes['width']);
          final h = _parseDimension(element.attributes['height']);
          final isVideo = tag == 'video';

          return QspMedia(
            resolver: resolver,
            src: src,
            width: w,
            height: h,
            autoplay: isVideo
                ? (element.attributes.containsKey('autoplay') || true)
                : true,
            loop: element.attributes.containsKey('loop') || isVideo,
            muted: element.attributes.containsKey('muted'),
          );
        },
      ),
    );
  }
}
