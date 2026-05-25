import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AutoplayVideoPreview extends StatefulWidget {
  final String url;
  final bool muted;
  final bool loop;
  final bool autoplay;
  final bool gateByVisibility;
  final double visibleFractionToPlay;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? loading;
  final Widget? error;

  const AutoplayVideoPreview({
    super.key,
    required this.url,
    this.muted = true,
    this.loop = true,
    this.autoplay = true,
    this.gateByVisibility = true,
    this.visibleFractionToPlay = 0.60,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.loading,
    this.error,
  });

  @override
  State<AutoplayVideoPreview> createState() => _AutoplayVideoPreviewState();
}

class _AutoplayVideoPreviewState extends State<AutoplayVideoPreview> {
  VideoPlayerController? _controller;
  bool _visible = true;
  bool _initFailed = false;
  bool _initializing = false;
  bool _completed = false;
  Timer? _disposeTimer;

  @override
  void initState() {
    super.initState();
    if (widget.autoplay) _init();
  }

  @override
  void didUpdateWidget(covariant AutoplayVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeTimer?.cancel();
      _disposeController();
      _initFailed = false;
      _completed = false;
      if (widget.autoplay) _init();
      return;
    }
    final c = _controller;
    if (oldWidget.autoplay != widget.autoplay) {
      if (widget.autoplay) {
        _disposeTimer?.cancel();
        if (_controller == null && !_initFailed) _init();
      } else {
        // Avoid rapid create/dispose cycles (can crash on some Android devices).
        // Pause immediately, and dispose after a short delay if still not needed.
        if (c?.value.isPlaying ?? false) {
          c?.pause();
        }
        _disposeTimer?.cancel();
        _disposeTimer = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          if (!widget.autoplay) _disposeController();
        });
      }
      return;
    }

    if (c != null && c.value.isInitialized) {
      if (oldWidget.loop != widget.loop) {
        c.setLooping(widget.loop);
      }
      if (oldWidget.muted != widget.muted) {
        c.setVolume(widget.muted ? 0 : 1);
      }
      _syncPlayback();
    }
  }

  Future<void> _init() async {
    if (_initializing) return;
    final cleaned = widget.url.trim();
    if (cleaned.isEmpty) {
      setState(() => _initFailed = true);
      return;
    }

    final uri = Uri.tryParse(cleaned);
    if (uri == null) {
      setState(() => _initFailed = true);
      return;
    }

    VideoPlayerController controller;
    if (!kIsWeb && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        final file = await DefaultCacheManager().getSingleFile(cleaned);
        controller = VideoPlayerController.file(File(file.path));
      } catch (_) {
        controller = VideoPlayerController.networkUrl(uri);
      }
    } else {
      controller = VideoPlayerController.networkUrl(uri);
    }
    _controller = controller;
    _initializing = true;
    try {
      await controller.initialize();
      await controller.setLooping(widget.loop);
      if (widget.muted) await controller.setVolume(0);
      controller.addListener(_handleProgress);
      if (!mounted) return;
      setState(() {});
      _syncPlayback();
    } catch (_) {
      if (!mounted) return;
      setState(() => _initFailed = true);
      _disposeController();
    } finally {
      _initializing = false;
    }
  }

  void _handleProgress() {
    final c = _controller;
    if (c == null) return;
    if (!c.value.isInitialized) return;
    if (widget.loop) return;
    final d = c.value.duration;
    final p = c.value.position;
    if (d == Duration.zero) return;
    if (p >= d && !_completed) {
      _completed = true;
      c.pause();
    }
  }

  void _syncPlayback() {
    final c = _controller;
    if (c == null) return;
    if (!c.value.isInitialized) return;
    if (_completed && !widget.loop) return;
    final shouldPlay = widget.autoplay && (widget.gateByVisibility ? _visible : true);
    if (shouldPlay) {
      if (!c.value.isPlaying) c.play();
    } else {
      if (c.value.isPlaying) c.pause();
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.removeListener(_handleProgress);
    c?.dispose();
  }

  @override
  void dispose() {
    _disposeTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget child;
    final c = _controller;
    if (_initFailed) {
      child =
          widget.error ??
          Container(
            color: cs.surfaceContainerHighest,
            child: const Icon(Icons.play_circle_outline, size: 32),
          );
    } else if (c == null || !c.value.isInitialized) {
      child =
          widget.loading ??
          Container(color: cs.surfaceContainerHighest, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    } else {
      child = SizedBox.expand(
        child: ClipRect(
          child: FittedBox(
            fit: widget.fit,
            alignment: Alignment.center,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
        ),
      );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }

    if (!widget.gateByVisibility) {
      return child;
    }

    return VisibilityDetector(
      key: ValueKey('autoplay_video_${widget.url}'),
      onVisibilityChanged: (info) {
        final nextVisible = info.visibleFraction >= widget.visibleFractionToPlay;
        if (nextVisible == _visible) return;
        _visible = nextVisible;
        if (_visible && widget.autoplay && _controller == null && !_initFailed) {
          _disposeTimer?.cancel();
          _init();
          return;
        }
        _syncPlayback();
      },
      child: child,
    );
  }
}
