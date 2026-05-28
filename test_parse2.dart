import 'dart:io';
import 'dart:convert';

void main() async {
  final uri = Uri.parse('https://propertysearch.visionvivante.in/api/v1/owner/flats/under/fiftylakh');
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    req.headers.set('Accept', 'application/json');
    req.headers.set('Authorization', 'Bearer 117|KSTcawQULB00neG2PEDjE55DFP094gvpaLtAZAAI39d489c8');

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    
    final decoded = jsonDecode(body);
    List items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final outer = decoded['data'] ?? decoded['properties'] ?? decoded['result'];
      if (outer is List) {
        items = outer;
      } else if (outer is Map) {
        final inner = outer['data'];
        items = inner is List ? inner : const [];
      } else {
        items = const [];
      }
    } else {
      items = const [];
    }
    
    print('Raw items count: ' + items.length.toString());
    
    final properties = items
          .whereType<Map>()
          .map((e) => _propertyFromApiJson(e.cast<String, dynamic>()))
          .where((p) => p['id'] != null && p['id'].toString().isNotEmpty)
          .toList(growable: false);
          
    print('Parsed items count: ' + properties.length.toString());
  } catch (e, st) {
    print('Error: ' + e.toString() + '\n' + st.toString());
  } finally {
    client.close();
  }
}

Map<String, dynamic> _propertyFromApiJson(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        final s = v.toString();
        if (s.trim().isNotEmpty) return s;
      }
      return '';
    }

    int pickInt(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is num) return v.toInt();
        if (v is String) {
          final n = int.tryParse(v);
          if (n != null) return n;
        }
      }
      return 0;
    }

    List<String> pickStringList(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is List) return v.map((e) => e.toString()).toList();
      }
      return const [];
    }

    final id = pickString(['id', '_id', 'uuid', 'property_id']);
    final name = pickString(['name', 'title', 'property_name']);

    final city = pickString(['city']);
    final state = pickString(['state']);
    final address = pickString(['address', 'location', 'locality']);
    final location = [
      address,
      city,
      state,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    final type = pickString(['type', 'mode', 'purpose']).toLowerCase();
    final normalizedType = type == 'buy' || type == 'sale' ? 'buy' : 'rent';

    final price = pickInt(['price', 'rent', 'amount', 'budget']);
    List<String> parseAmenities() {
      final v = json['amenities'] ?? json['features'] ?? json['facility'];
      if (v is List) {
        final out = <String>[];
        for (final item in v) {
          if (item is String) {
            final s = item.trim();
            if (s.isNotEmpty) out.add(s);
          } else if (item is Map) {
            final name = (item['name'] ?? item['title'] ?? item['label'] ?? '')
                .toString()
                .trim();
            if (name.isNotEmpty) out.add(name);
          }
        }
        return out;
      }
      return pickStringList(['amenities', 'features', 'facility']);
    }

    List<String> parseImages() {
      final v = json['images'];
      if (v is List) {
        final out = <String>[];
        for (final item in v) {
          if (item is String) {
            out.add(item);
          } else if (item is Map) {
            final path =
                (item['image_path'] ?? item['path'] ?? item['url'] ?? '')
                    .toString();
            if (path.trim().isNotEmpty) out.add(path);
          }
        }
        return out;
      }
      return pickStringList(['image_urls', 'photos']);
    }

    List<String> parseVideos() {
      final v = json['videos'];
      if (v is List) {
        final out = <String>[];
        for (final item in v) {
          if (item is String) {
            out.add(item);
          } else if (item is Map) {
            final path =
                (item['video_path'] ?? item['path'] ?? item['url'] ?? '')
                    .toString();
            if (path.trim().isNotEmpty) out.add(path);
          }
        }
        return out;
      }
      return pickStringList(['video_urls', 'clips']);
    }

    String normalizeImageUrl(String raw) {
      return raw;
    }

    String normalizeVideoUrl(String raw) {
      return raw;
    }

    final images = parseImages()
        .map(normalizeImageUrl)
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final videos = parseVideos()
        .map(normalizeVideoUrl)
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final description = pickString(['description', 'details', 'about']);
    final availabilityRaw = pickString([
      'availability',
      'available_from',
      'availableFrom',
      'created_at',
    ]);
    final availability = DateTime.tryParse(availabilityRaw) ?? DateTime.now();

    return {
      'id': id,
      'name': name.isEmpty ? 'Property' : name,
    };
  }
