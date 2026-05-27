import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

class ZoomableVideoPage extends StatefulWidget {
  final String url;
  const ZoomableVideoPage({super.key, required this.url});

  @override
  State<ZoomableVideoPage> createState() => _ZoomableVideoPageState();
}

class _ZoomableVideoPageState extends State<ZoomableVideoPage> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cleaned = widget.url.trim();
    if (cleaned.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    final uri = Uri.tryParse(cleaned);
    if (uri == null) {
      setState(() => _failed = true);
      return;
    }
    VideoPlayerController c;
    if (!kIsWeb && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        final file = await DefaultCacheManager().getSingleFile(cleaned);
        c = VideoPlayerController.file(File(file.path));
      } catch (_) {
        c = VideoPlayerController.networkUrl(uri);
      }
    } else {
      c = VideoPlayerController.networkUrl(uri);
    }
    _controller = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(1);
      await c.play();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: _failed
                    ? const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white70,
                        size: 48,
                      )
                    : (c == null || !c.value.isInitialized)
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: c.value.size.width,
                                height: c.value.size.height,
                                child: VideoPlayer(c),
                              ),
                            ),
                          ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: cs.onPrimary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

