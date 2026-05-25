import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheService {
  final CacheManager _cacheManager;

  VideoCacheService({CacheManager? cacheManager})
      : _cacheManager = cacheManager ?? DefaultCacheManager();

  Future<File?> getCachedFile(String url) async {
    if (kIsWeb) return null;
    final u = url.trim();
    if (u.isEmpty) return null;
    final uri = Uri.tryParse(u);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    try {
      return await _cacheManager.getSingleFile(u);
    } catch (_) {
      return null;
    }
  }
}

