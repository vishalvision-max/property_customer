import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class FavoritesToggleResult {
  /// `null` when backend doesn't explicitly return the new state.
  final bool? isFavorited;
  const FavoritesToggleResult({required this.isFavorited});
}

class FavoritesService {
  static final Uri _baseUri = Uri.parse('https://propertysearch.visionvivante.in');

  Future<void> delete({
    required String token,
    required String id,
  }) async {
    if (kIsWeb) {
      throw Exception('Favorites API is not supported on web in this build');
    }

    final uri = _baseUri.replace(path: '/api/v1/favorites/$id');
    final client = HttpClient();
    try {
      final req = await client.deleteUrl(uri);
      req.headers.set('Accept', 'application/json');
      req.headers.set('Authorization', 'Bearer $token');

      final res = await req.close();
      final status = res.statusCode;
      if (status < 200 || status >= 300) {
        final body = await res.transform(utf8.decoder).join();
        throw Exception('Failed to delete favorite ($status) ${body.trim()}');
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<Set<String>> fetchFavoriteIds({required String token}) async {
    if (kIsWeb) {
      throw Exception('Favorites API is not supported on web in this build');
    }

    final uri = _baseUri.replace(path: '/api/v1/favorites');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/json');
      req.headers.set('Authorization', 'Bearer $token');

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;
      if (status < 200 || status >= 300) {
        throw Exception('Failed to load favorites ($status)');
      }

      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      return _extractIds(decoded);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<FavoritesToggleResult> toggle({
    required String token,
    required String type,
    required String id,
  }) async {
    if (kIsWeb) {
      throw Exception('Favorites API is not supported on web in this build');
    }

    final uri = _baseUri.replace(path: '/api/v1/favorites/toggle');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set('Accept', 'application/json');
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('Authorization', 'Bearer $token');

      req.add(utf8.encode(jsonEncode(<String, dynamic>{'type': type, 'id': int.tryParse(id) ?? id})));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;
      if (status < 200 || status >= 300) {
        throw Exception('Failed to toggle favorite ($status)');
      }

      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      return FavoritesToggleResult(isFavorited: _pickFavorited(decoded));
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  bool? _pickFavorited(dynamic decoded) {
    dynamic unwrap(dynamic v) {
      if (v is Map<String, dynamic>) {
        return v['data'] ?? v['result'] ?? v['favorite'] ?? v;
      }
      return v;
    }

    final root = unwrap(decoded);
    if (root is Map) {
      final map = root.cast<String, dynamic>();
      final candidates = <dynamic>[
        map['is_favorited'],
        map['is_favorite'],
        map['favorited'],
        map['favourite'],
        map['favorite'],
        map['status'],
      ];
      for (final c in candidates) {
        if (c is bool) return c;
        if (c is num) return c != 0;
        if (c is String) {
          final s = c.toLowerCase().trim();
          if (s == 'true' || s == '1' || s == 'yes' || s == 'favorited') return true;
          if (s == 'false' || s == '0' || s == 'no' || s == 'unfavorited') return false;
        }
      }
    }
    return null;
  }

  Set<String> _extractIds(dynamic decoded) {
    dynamic unwrap(dynamic v) {
      if (v is Map<String, dynamic>) {
        return v['data'] ?? v['favorites'] ?? v['result'] ?? v;
      }
      return v;
    }

    final root = unwrap(decoded);
    final items = root is List ? root : (root is Map && root['data'] is List ? root['data'] : const []);
    if (items is! List) return const <String>{};

    String? readIdFromMap(Map<String, dynamic> map) {
      dynamic pickFirst(List<String> keys) {
        for (final k in keys) {
          if (map.containsKey(k) && map[k] != null) return map[k];
        }
        return null;
      }

      final direct = pickFirst([
        'property_id',
        'propertyId',
        'favoritable_id',
        'favoritableId',
        'id',
      ]);
      if (direct != null) return direct.toString();

      final nested = map['property'];
      if (nested is Map) {
        final nid = (nested['id'] ?? nested['property_id'] ?? nested['uuid']);
        if (nid != null) return nid.toString();
      }
      return null;
    }

    final out = <String>{};
    for (final item in items) {
      if (item is Map) {
        final id = readIdFromMap(item.cast<String, dynamic>());
        if (id != null && id.trim().isNotEmpty) out.add(id);
      } else if (item is num || item is String) {
        final s = item.toString().trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
    return out;
  }
}
