import 'dart:convert';

import 'package:http/http.dart' as http;

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
}

