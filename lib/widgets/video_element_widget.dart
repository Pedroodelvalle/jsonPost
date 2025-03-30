import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoElementWidget extends StatefulWidget {
  final String url;
  final Offset offset;
  final double width;
  final double height;
  final String playback; // 'loop', 'once' ou 'pause'
  final BoxFit fit;
  final double alignmentX;
  final double alignmentY;
  final double offsetX;
  final double offsetY;
  final bool grayscale;
  final double opacity;
  final double borderRadius;
  final double? blur;
  final bool muted; // nova propriedade para controle de áudio

  const VideoElementWidget({
    super.key,
    required this.url,
    required this.offset,
    required this.width,
    required this.height,
    this.playback = 'loop', // 'loop', 'once' ou 'pause'
    this.fit = BoxFit.cover,
    this.alignmentX = 0.0,
    this.alignmentY = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.grayscale = false,
    this.opacity = 1.0,
    this.borderRadius = 0.0,
    this.blur,
    this.muted = false, // valor padrão é false (com som)
  });

  @override
  State<VideoElementWidget> createState() => _VideoElementWidgetState();
}

class _VideoElementWidgetState extends State<VideoElementWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        _setupPlayback();
        _controller.setVolume(widget.muted ? 0.0 : 1.0);
        setState(() => _initialized = true);
      });

    // Adiciona listener para quando o vídeo terminar
    _controller.addListener(_onVideoUpdate);
  }

  void _setupPlayback() {
    switch (widget.playback) {
      case 'pause':
        _controller.setLooping(false);
        _controller.pause();
        break;
      case 'once':
        _controller.setLooping(false);
        _controller.play();
        break;
      default: // 'loop'
        _controller.setLooping(true);
        _controller.play();
    }
  }

  void _onVideoUpdate() {
    if (!_controller.value.isPlaying && 
        _controller.value.position >= _controller.value.duration && 
        widget.playback == 'once') {
      _controller.pause();
      _controller.seekTo(Duration.zero);
    }
  }

  @override
  void didUpdateWidget(VideoElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback != widget.playback && _initialized) {
      _setupPlayback();
    }
    if (oldWidget.muted != widget.muted && _initialized) {
      _controller.setVolume(widget.muted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(widget.alignmentX, widget.alignmentY);

    Widget video = _initialized
        ? FittedBox(
            fit: widget.fit,
            alignment: alignment,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          )
        : const Center(child: CircularProgressIndicator());

    if (widget.grayscale) {
      video = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: video,
      );
    }

    if (widget.blur != null) {
      video = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: widget.blur!,
          sigmaY: widget.blur!,
        ),
        child: video,
      );
    }

    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: Opacity(
        opacity: widget.opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(widget.offsetX, widget.offsetY),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: video,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
