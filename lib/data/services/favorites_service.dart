import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FavoritesToggleResult {
  /// `null` when backend doesn't explicitly return the new state.
  final bool? isFavorited;
  const FavoritesToggleResult({required this.isFavorited});
}

class FavoritesService {
  static final Uri _baseUri =
      Uri.parse('https://propertysearch.visionvivante.in');

  // ─────────────────────────────────────────────────────────────
  //  GET /api/v1/favorites/index
  //  Returns all favorited property IDs for the logged-in user.
  // ─────────────────────────────────────────────────────────────
  Future<Set<String>> fetchFavoriteIds({required String token}) async {
    if (kIsWeb) return const <String>{};

    final uri = _baseUri.replace(path: '/api/v1/favorites/index');
    debugPrint('[FavoritesService] GET $uri');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('[FavoritesService] fetchFavoriteIds → ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[FavoritesService] fetchFavoriteIds error: ${response.body}');
        return const <String>{};
      }
      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      return _extractIds(decoded);
    } catch (e) {
      debugPrint('[FavoritesService] fetchFavoriteIds exception: $e');
      return const <String>{};
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  POST /api/v1/favorites/toggle
  //  Body: type=property & id=<propertyId>
  //  Adds to favorites if not present, removes if present.
  // ─────────────────────────────────────────────────────────────
  Future<FavoritesToggleResult> toggle({
    required String token,
    required String type,
    required String id,
  }) async {
    if (kIsWeb) return const FavoritesToggleResult(isFavorited: null);

    final uri = _baseUri.replace(path: '/api/v1/favorites/toggle');
    debugPrint('[FavoritesService] POST $uri  type=$type id=$id');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'type': type, 'id': id},
      );
      debugPrint('[FavoritesService] toggle → ${response.statusCode}');
      debugPrint('[FavoritesService] toggle body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to toggle favorite (${response.statusCode})',
        );
      }

      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      return FavoritesToggleResult(isFavorited: _pickFavorited(decoded));
    } catch (e) {
      debugPrint('[FavoritesService] toggle exception: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  POST /api/v1/favorites/remove/{id}
  //  Body: type=property & id=<propertyId>
  //  Explicitly removes a property from favorites.
  // ─────────────────────────────────────────────────────────────
  Future<void> delete({
    required String token,
    required String id,
    String type = 'property',
  }) async {
    if (kIsWeb) return;

    final uri = _baseUri.replace(path: '/api/v1/favorites/remove/$id');
    debugPrint('[FavoritesService] POST $uri  type=$type id=$id');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'type': type, 'id': id},
      );
      debugPrint('[FavoritesService] delete → ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[FavoritesService] delete error: ${response.body}');
        throw Exception(
          'Failed to remove favorite (${response.statusCode}) ${response.body.trim()}',
        );
      }
    } catch (e) {
      debugPrint('[FavoritesService] delete exception: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────
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
          if (s == 'true' || s == '1' || s == 'yes' || s == 'favorited') {
            return true;
          }
          if (s == 'false' || s == '0' || s == 'no' || s == 'unfavorited') {
            return false;
          }
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
    final items = root is List
        ? root
        : (root is Map && root['data'] is List ? root['data'] : const []);
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
