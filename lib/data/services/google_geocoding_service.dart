import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlacePrediction {
  final String description;
  final String placeId;
  const PlacePrediction({required this.description, required this.placeId});
}

class LatLngResult {
  final double lat;
  final double lng;
  const LatLngResult(this.lat, this.lng);
}

class GoogleGeocodingService {
  final String apiKey;

  const GoogleGeocodingService({required this.apiKey});

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    if (!isConfigured) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': apiKey,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final json = jsonDecode(res.body);
    if (json is! Map<String, dynamic>) return null;
    if (json['status'] != 'OK') return null;

    final results = json['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map<String, dynamic>) return null;

    final components = first['address_components'];
    if (components is! List) {
      final formatted = first['formatted_address'];
      return formatted is String ? formatted : null;
    }

    String? locality;
    String? adminArea;
    for (final c in components) {
      if (c is! Map<String, dynamic>) continue;
      final types = c['types'];
      final longName = c['long_name'];
      if (types is! List || longName is! String) continue;
      if (locality == null && types.contains('locality')) locality = longName;
      if (adminArea == null && types.contains('administrative_area_level_1')) {
        adminArea = longName;
      }
    }

    final parts = <String>[
      if (locality != null && locality.trim().isNotEmpty) locality.trim(),
      if (adminArea != null && adminArea.trim().isNotEmpty) adminArea.trim(),
    ];
    if (parts.isEmpty) {
      final formatted = first['formatted_address'];
      return formatted is String ? formatted : null;
    }
    return parts.join(', ');
  }

  Future<List<PlacePrediction>> autocomplete(String query) async {
    if (!isConfigured || query.trim().isEmpty) return [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': query,
        'key': apiKey,
        'components':
            'country:in', // Optional: restrict to India if appropriate
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        debugPrint(
          '[Geocoding] autocomplete HTTP ${res.statusCode}: ${res.body}',
        );
        return [];
      }

      final json = jsonDecode(res.body);
      if (json['status'] != 'OK' && json['status'] != 'ZERO_RESULTS') {
        // e.g. REQUEST_DENIED, OVER_QUERY_LIMIT, INVALID_REQUEST — the real
        // reason suggestions silently stop appearing.
        debugPrint(
          '[Geocoding] autocomplete status=${json['status']} error_message=${json['error_message']}',
        );
        return [];
      }

      final predictions = json['predictions'];
      if (predictions is! List) return [];

      return predictions
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => PlacePrediction(
              description: (p['description'] ?? '').toString(),
              placeId: (p['place_id'] ?? '').toString(),
            ),
          )
          .where((p) => p.description.isNotEmpty && p.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[Geocoding] autocomplete threw: $e');
      return [];
    }
  }

  /// Resolves a place_id (from [autocomplete]) to precise coordinates.
  Future<LatLngResult?> placeDetails(String placeId) async {
    if (!isConfigured || placeId.trim().isEmpty) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {'place_id': placeId, 'fields': 'geometry', 'key': apiKey},
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);
      if (json['status'] != 'OK') return null;

      final location = json['result']?['geometry']?['location'];
      if (location is! Map) return null;
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLngResult(lat, lng);
    } catch (e) {
      return null;
    }
  }

  /// Forward-geocodes a free-typed address string to coordinates — used when
  /// the user submits raw text without picking an autocomplete suggestion.
  Future<LatLngResult?> geocodeAddress(String address) async {
    if (!isConfigured || address.trim().isEmpty) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': address,
      'key': apiKey,
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);
      if (json['status'] != 'OK') return null;

      final results = json['results'];
      if (results is! List || results.isEmpty) return null;
      final location = results.first['geometry']?['location'];
      if (location is! Map) return null;
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLngResult(lat, lng);
    } catch (e) {
      return null;
    }
  }
}
