import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class QspVideo extends StatefulWidget {
  const QspVideo({
    super.key,
    required this.path,
    this.autoplay = true,
    this.loop = true,
    this.muted = false,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  final String path;
  final bool autoplay;
  final bool loop;
  final bool muted;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<QspVideo> createState() => _QspVideoState();
}

class _QspVideoState extends State<QspVideo> {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  StreamSubscription? _paramsSub;
  double _aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    _paramsSub = _player.stream.videoParams.listen((params) {
      final w = params.w;
      final h = params.h;
      if (w != null && h != null && w > 0 && h > 0) {
        final ratio = w / h;
        if (mounted && (ratio - _aspectRatio).abs() > 0.01) {
          setState(() {
            _aspectRatio = ratio;
          });
        }
      }
    });
    _initAndPlay();
  }

  void _initAndPlay() {
    _player.setPlaylistMode(
      widget.loop ? PlaylistMode.loop : PlaylistMode.none,
    );
    if (widget.muted) {
      _player.setVolume(0);
    }
    _player.open(Media(widget.path), play: widget.autoplay);
  }

  @override
  void didUpdateWidget(covariant QspVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _player.open(Media(widget.path), play: widget.autoplay);
    }
  }

  @override
  void dispose() {
    _paramsSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget videoWidget = Video(
      controller: _controller,
      fit: widget.fit,
      controls: NoVideoControls,
      fill: Colors.transparent,
      alignment: Alignment.center,
    );

    if (widget.width != null && widget.height != null) {
      videoWidget = SizedBox(
        width: widget.width,
        height: widget.height,
        child: videoWidget,
      );
    } else if (widget.width != null) {
      videoWidget = SizedBox(
        width: widget.width,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: videoWidget,
        ),
      );
    } else if (widget.height != null) {
      videoWidget = SizedBox(
        height: widget.height,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: videoWidget,
        ),
      );
    } else {
      videoWidget = AspectRatio(
        aspectRatio: _aspectRatio,
        child: videoWidget,
      );
    }

    return ExcludeSemantics(
      child: Center(
        child: videoWidget,
      ),
    );
  }
}
