import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/property.dart';

class PropertyService {
  static final Uri _baseUri = Uri.parse(
    'https://propertysearch.visionvivante.in',
  );

  Future<List<Property>> fetchProperties() async {
    return _fetchFromApi();
  }

  Future<List<Property>> fetchFiltered({
    int? categoryId,
    String? city,
    int? minPrice,
    int? maxPrice,
    String? type, // rent | buy
    String? sortBy,
  }) async {
    final apiType = type == 'buy' ? 'sale' : type;
    return _fetchFromApi(
      query: <String, String>{
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        if (apiType != null && apiType.trim().isNotEmpty)
          'type': apiType.trim(),
        if (sortBy != null && sortBy.trim().isNotEmpty)
          'sort_by': sortBy.trim(),
      },
    );
  }

  /// Fetches only the images (and videos) for a property by ID.
  /// Much lighter than fetchDetails — used by list cards to lazy-load
  /// the thumbnail when the list endpoint returns images: null.
  Future<List<String>> fetchPropertyImages(String id) async {
    if (kIsWeb) return const [];
    final uri = _baseUri.replace(path: '/api/v1/properties/$id');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/json');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      final Map<String, dynamic>? data = decoded is Map<String, dynamic>
          ? (decoded['data'] ?? decoded) as Map<String, dynamic>?
          : null;

      if (data == null) return const [];
      final raw = data['images'];
      if (raw is! List || raw.isEmpty) return const [];
      final out = <String>[];
      for (final item in raw) {
        if (item is Map) {
          final path = (item['image_path'] ?? item['path'] ?? item['url'] ?? '')
              .toString()
              .trim();
          if (path.isNotEmpty) {
            out.add(
              path.startsWith('http')
                  ? path
                  : _baseUri.resolve('/storage/$path').toString(),
            );
          }
        } else if (item is String && item.trim().isNotEmpty) {
          final path = item.trim();
          out.add(
            path.startsWith('http')
                ? path
                : _baseUri.resolve('/storage/$path').toString(),
          );
        }
      }
      return out;
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  Future<Property> fetchDetails(String id) async {
    if (kIsWeb) {
      throw Exception('Properties API is not supported on web in this build');
    }
    final uri = _baseUri.replace(path: '/api/v1/properties/$id');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/json');

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;
      if (status < 200 || status >= 300) {
        throw Exception('Failed to load property details ($status)');
      }
      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final data =
            decoded['data'] ??
            decoded['property'] ??
            decoded['result'] ??
            decoded;
        if (data is Map) {
          final p = _propertyFromApiJson(data.cast<String, dynamic>());
          if (p.id.isEmpty) {
            throw Exception('Property details response was unexpected');
          }
          return p;
        }
      }
      if (decoded is Map) {
        final p = _propertyFromApiJson(decoded.cast<String, dynamic>());
        if (p.id.isEmpty) {
          throw Exception('Property details response was unexpected');
        }
        return p;
      }
      throw Exception('Property details response was unexpected');
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Property>> fetchPopular() async {
    return _fetchFromApi(path: '/api/v1/properties/popular');
  }

  /// GET /api/v1/owner/all/properties?page=N
  /// Returns paginated properties. Returns a record of (items, hasMore) so
  /// the UI can implement pull-to-refresh + infinite scroll.
  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchAllOwnerPropertiesPaged({
    required String token,
    int page = 1,
  }) async {
    final uri = _baseUri.replace(
      path: '/api/v1/owner/all/properties',
      queryParameters: {
        'page': page.toString(),
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    debugPrint('[PropertyService] GET $uri');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = response.body;
      final status = response.statusCode;
      debugPrint('[PropertyService] fetchAllOwnerProperties → $status');

      if (status == 404) {
        return (items: <Property>[], hasMore: false, currentPage: page);
      }
      if (status < 200 || status >= 300) {
        debugPrint('[PropertyService] fetchAllOwnerProperties ERROR: $body');
        throw Exception('Failed to load all properties ($status)');
      }

      final decoded = body.trim().isEmpty ? null : jsonDecode(body);

      // Parse paginated Laravel response: { data: { current_page, last_page, data: [...] } }
      List rawItems = const [];
      int currentPageRes = page;
      int lastPage = 1;

      if (decoded is Map<String, dynamic>) {
        final outer = decoded['data'] ?? decoded['properties'] ?? decoded;
        if (outer is Map<String, dynamic>) {
          currentPageRes = (outer['current_page'] as num?)?.toInt() ?? page;
          lastPage = (outer['last_page'] as num?)?.toInt() ?? 1;
          final inner = outer['data'];
          rawItems = inner is List ? inner : const [];
        } else if (outer is List) {
          rawItems = outer;
        }
      } else if (decoded is List) {
        rawItems = decoded;
      }

      final items = rawItems
          .whereType<Map>()
          .map((e) => _propertyFromApiJson(e.cast<String, dynamic>()))
          .where((p) => p.id.isNotEmpty)
          .toList(growable: false);

      return (
        items: items,
        hasMore: currentPageRes < lastPage,
        currentPage: currentPageRes,
      );
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  /// Kept for backward compatibility (used by provider/repo without pagination).
  Future<List<Property>> fetchAllOwnerProperties({
    required String token,
  }) async {
    final result = await fetchAllOwnerPropertiesPaged(token: token, page: 1);
    return result.items;
  }

  Future<List<Property>> fetchNearby({
    required double lat,
    required double lng,
    int radius = 100,
  }) async {
    return _fetchFromApi(
      path: '/api/v1/properties/nearby',
      query: <String, String>{
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radius.toString(),
      },
    );
  }

  Future<List<Property>> fetchRecommendations({required String token}) async {
    if (kIsWeb) {
      throw Exception('Properties API is not supported on web in this build');
    }
    final uri = _baseUri.replace(path: '/api/v1/properties/recommendations');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/json');
      req.headers.set('Authorization', 'Bearer $token');

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;
      if (status < 200 || status >= 300) {
        throw Exception('Failed to load recommendations ($status)');
      }
      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      final List items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final outer =
            decoded['data'] ?? decoded['properties'] ?? decoded['result'];
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
      return items
          .whereType<Map>()
          .map((e) => _propertyFromApiJson(e.cast<String, dynamic>()))
          .where((p) => p.id.isNotEmpty)
          .toList(growable: false);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  // ── Shared helper for all specialized filter endpoints ──────────────────
  // Uses the `http` package so every request is visible in Flutter DevTools.
  // Hits the specific backend endpoint path provided.
  Future<List<Property>> _fetchSpecialized({
    required String token,
    required String errorLabel,
    required String path,
    Map<String, String> queryParams = const {},
  }) async {
    final uri = _baseUri.replace(
      path: path,
      queryParameters: {
        ...queryParams,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    debugPrint('[PropertyService] GET $uri');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = response.body;
      final status = response.statusCode;
      debugPrint('[PropertyService] $errorLabel → $status');

      if (status == 404) {
        debugPrint('[PropertyService] $errorLabel: empty (404 no data)');
        return <Property>[];
      }

      if (status < 200 || status >= 300) {
        debugPrint('[PropertyService] $errorLabel ERROR body: $body');
        throw Exception('Failed to load $errorLabel ($status)');
      }

      debugPrint('[PropertyService] $errorLabel response:\n$body');

      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      final List items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final outer =
            decoded['data'] ?? decoded['properties'] ?? decoded['result'];
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
      return items
          .whereType<Map>()
          .map((e) => _propertyFromApiJson(e.cast<String, dynamic>()))
          .where((p) => p.id.isNotEmpty)
          .toList(growable: false);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  // ── Shared helper for all specialized filter endpoints with pagination ──
  Future<({List<Property> items, bool hasMore, int currentPage})>
  _fetchSpecializedPaged({
    required String token,
    required String errorLabel,
    required String path,
    int page = 1,
    Map<String, String> queryParams = const {},
  }) async {
    final uri = _baseUri.replace(
      path: path,
      queryParameters: {
        ...queryParams,
        'page': page.toString(),
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    debugPrint('[PropertyService] GET $uri');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = response.body;
      final status = response.statusCode;
      debugPrint('[PropertyService] $errorLabel → $status');

      if (status == 404) {
        debugPrint('[PropertyService] $errorLabel: empty (404 no data)');
        return (items: <Property>[], hasMore: false, currentPage: page);
      }

      if (status < 200 || status >= 300) {
        debugPrint('[PropertyService] $errorLabel ERROR body: $body');
        throw Exception('Failed to load $errorLabel ($status)');
      }

      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      List rawItems = const [];
      int currentPageRes = page;
      int lastPage = 1;

      if (decoded is Map<String, dynamic>) {
        final outer = decoded['data'] ?? decoded['properties'] ?? decoded;
        if (outer is Map<String, dynamic>) {
          currentPageRes = (outer['current_page'] as num?)?.toInt() ?? page;
          lastPage = (outer['last_page'] as num?)?.toInt() ?? 1;
          final inner = outer['data'];
          rawItems = inner is List ? inner : const [];
        } else if (outer is List) {
          rawItems = outer;
        }
      } else if (decoded is List) {
        rawItems = decoded;
      }

      final items = rawItems
          .whereType<Map>()
          .map((e) => _propertyFromApiJson(e.cast<String, dynamic>()))
          .where((p) => p.id.isNotEmpty)
          .toList(growable: false);

      return (
        items: items,
        hasMore: currentPageRes < lastPage,
        currentPage: currentPageRes,
      );
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  /// 2 BHK — /api/v1/owner/twobhk/properties
  Future<List<Property>> fetchTwoBhkProperties({required String token}) =>
      _fetchSpecialized(
        token: token,
        errorLabel: '2 BHK properties',
        path: '/api/v1/owner/twobhk/properties',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchTwoBhkPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: '2 BHK properties',
        path: '/api/v1/owner/twobhk/properties',
        page: page,
      );

  /// Flats under 50 Lakhs — /api/v1/owner/flats/under/fiftylakh
  Future<List<Property>> fetchFlatsUnderFiftyLakh({
    required String token,
  }) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Flats under 50L',
        path: '/api/v1/owner/flats/under/fiftylakh',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchFlatsUnderFiftyLakhPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Flats under 50L',
        path: '/api/v1/owner/flats/under/fiftylakh',
        page: page,
      );

  /// Ready to Move — /api/v1/owner/availability/readytomove
  Future<List<Property>> fetchReadyToMoveProperties({
    required String token,
  }) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Ready to Move',
        path: '/api/v1/owner/availability/readytomove',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchReadyToMovePropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Ready to Move',
        path: '/api/v1/owner/availability/readytomove',
        page: page,
      );

  /// Furnished — /api/v1/owner/furnishing/furnished
  Future<List<Property>> fetchFurnishedProperties({
    required String token,
  }) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Furnished',
        path: '/api/v1/owner/furnishing/furnished',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchFurnishedPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Furnished',
        path: '/api/v1/owner/furnishing/furnished',
        page: page,
      );

  /// Gated Society — /api/v1/owner/gated/society
  Future<List<Property>> fetchGatedSocietyProperties({
    required String token,
  }) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Gated Society',
        path: '/api/v1/owner/gated/society',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchGatedSocietyPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Gated Society',
        path: '/api/v1/owner/gated/society',
        page: page,
      );

  /// Studio Apartment — /api/v1/owner/studio/apartment
  Future<List<Property>> fetchStudioApartmentProperties({
    required String token,
  }) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Studio Apartment',
        path: '/api/v1/owner/studio/apartment',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchStudioApartmentPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Studio Apartment',
        path: '/api/v1/owner/studio/apartment',
        page: page,
      );

  /// Rent Properties — /api/v1/owner/rent/properties
  Future<List<Property>> fetchRentProperties({required String token}) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Rent Properties',
        path: '/api/v1/owner/rent/properties',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchRentPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Rent Properties',
        path: '/api/v1/owner/rent/properties',
        page: page,
      );

  /// Buy Properties — /api/v1/owner/buy/properties
  Future<List<Property>> fetchBuyProperties({required String token}) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Buy Properties',
        path: '/api/v1/owner/buy/properties',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchBuyPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Buy Properties',
        path: '/api/v1/owner/buy/properties',
        page: page,
      );

  /// PG Properties — /api/v1/owner/pg/properties
  Future<List<Property>> fetchPgProperties({required String token}) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'PG Properties',
        path: '/api/v1/owner/pg/properties',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchPgPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'PG Properties',
        path: '/api/v1/owner/pg/properties',
        page: page,
      );

  /// Co-Living Properties — /api/v1/owner/co/living/properties
  Future<List<Property>> fetchCoLivingProperties({required String token}) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Co-Living Properties',
        path: '/api/v1/owner/co/living/properties',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchCoLivingPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Co-Living Properties',
        path: '/api/v1/owner/co/living/properties',
        page: page,
      );

  /// Commercial Properties — /api/v1/owner/commercial/properties
  Future<List<Property>> fetchCommercialProperties({required String token}) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Commercial Properties',
        path: '/api/v1/owner/commercial/properties',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchCommercialPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Commercial Properties',
        path: '/api/v1/owner/commercial/properties',
        page: page,
      );

  /// Land/Plot Properties — /api/v1/owner/land/plot/properties
  Future<List<Property>> fetchLandPlotProperties({required String token}) =>
      _fetchSpecialized(
        token: token,
        errorLabel: 'Land/Plot Properties',
        path: '/api/v1/owner/land/plot/properties',
      );

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchLandPlotPropertiesPaged({required String token, int page = 1}) =>
      _fetchSpecializedPaged(
        token: token,
        errorLabel: 'Land/Plot Properties',
        path: '/api/v1/owner/land/plot/properties',
        page: page,
      );

  Future<dynamic> fetchHeatmap() async {
    if (kIsWeb) {
      throw Exception('Properties API is not supported on web in this build');
    }
    final uri = _baseUri.replace(path: '/api/v1/properties/heatmap');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/json');

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;
      if (status < 200 || status >= 300) {
        throw Exception('Failed to load heatmap ($status)');
      }
      return body.trim().isEmpty ? null : jsonDecode(body);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  /// Keyword search — passes [keyword] as a `keyword` query param to the
  /// main properties endpoint so the backend can do full-text matching across
  /// name, location, and description.  Falls back to an empty list on error.
  Future<List<Property>> searchByKeyword({
    required String keyword,
    // String? type, // rent | buy — optional extra filter
  }) async {
    final q = keyword.trim();
    return _fetchFromApi(
      query: <String, String>{
        if (q.isNotEmpty) 'keyword': q,
        // if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
      },
    );
  }

  Future<List<Property>> search({
    required String mode, // rent | buy
    required BudgetRange budgetRange,
    String? propertyType,
    List<String> amenities = const [],
    String? locationQuery,
    String? sortBy,
  }) async {
    // Use backend filtering where possible (price, city text, type).
    final all = await fetchFiltered(
      type: mode,
      minPrice: budgetRange.start.toInt(),
      maxPrice: budgetRange.end.toInt(),
      city: locationQuery,
      sortBy: sortBy,
    );

    return all.where((p) {
      // Backend already filtered for type/price/city, keep client-side filters for the rest.
      final amenOk = amenities.isEmpty
          ? true
          : amenities.every((a) => p.amenities.contains(a));
      final propTypeOk = (propertyType == null || propertyType == 'Any')
          ? true
          : p.name.toLowerCase().contains(propertyType.toLowerCase());
      return amenOk && propTypeOk;
    }).toList();
  }

  Future<List<Property>> _fetchFromApi({
    String path = '/api/v1/properties',
    Map<String, String> query = const <String, String>{},
  }) async {
    if (kIsWeb) {
      throw Exception('Properties API is not supported on web in this build');
    }

    final uri = _baseUri.replace(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    );
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/json');

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;

      if (status < 200 || status >= 300) {
        throw Exception('Failed to load properties ($status)');
      }
      final decoded = body.trim().isEmpty ? null : jsonDecode(body);

      final List items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        // Handle both flat and paginated responses:
        //   { "data": [...] }                        — flat list
        //   { "data": { "data": [...], "total": N } } — Laravel paginator
        //   { "status": true, "data": { "data": [...] } }
        final outer =
            decoded['data'] ?? decoded['properties'] ?? decoded['result'];
        if (outer is List) {
          items = outer;
        } else if (outer is Map) {
          // Laravel paginator: the real array is nested under another "data" key
          final inner = outer['data'];
          items = inner is List ? inner : const [];
        } else {
          items = const [];
        }
      } else {
        items = const [];
      }

      return items
          .whereType<Map>()
          .map((e) => _propertyFromApiJson(e.cast<String, dynamic>()))
          .where((p) => p.id.isNotEmpty)
          .toList(growable: false);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Property _propertyFromApiJson(Map<String, dynamic> json) {
    // Support a few common backend field-name variants to avoid breaking
    // if the API schema differs from the mock schema.
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
      final v = raw.trim();
      if (v.isEmpty) return v;
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
      // Backend typically returns storage-relative paths like:
      // "properties/21/images/xxx.webp"
      return _baseUri.resolve('/storage/$v').toString();
    }

    String normalizeVideoUrl(String raw) {
      final v = raw.trim();
      if (v.isEmpty) return v;
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
      return _baseUri.resolve('/storage/$v').toString();
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

    final bhk = json['bhk'] != null ? int.tryParse(json['bhk'].toString()) : null;
    final bedrooms = json['bedrooms'] != null ? int.tryParse(json['bedrooms'].toString()) : null;
    final bathrooms = json['bathrooms'] != null ? int.tryParse(json['bathrooms'].toString()) : null;
    final balconies = json['balconies'] != null ? int.tryParse(json['balconies'].toString()) : null;
    final parking = json['parking'] != null ? int.tryParse(json['parking'].toString()) : null;
    
    final superBuiltUpArea = json['super_built_up_area'] != null 
        ? double.tryParse(json['super_built_up_area'].toString()) 
        : null;
    final carpetArea = json['carpet_area'] != null 
        ? double.tryParse(json['carpet_area'].toString()) 
        : null;
    final builtUpArea = json['built_up_area'] != null 
        ? double.tryParse(json['built_up_area'].toString()) 
        : null;
    final furnishing = json['furnishing']?.toString();
    final categoryName = json['category'] is Map ? (json['category']['name']?.toString()) : null;
    final ownerPhone = json['owner_phone']?.toString();

    return Property(
      id: id,
      name: name.isEmpty ? 'Property' : name,
      location: location,
      price: price,
      type: normalizedType,
      propertyKind: pickString(['property_kind', 'propertyKind', 'category']),
      amenities: parseAmenities(),
      images: images,
      videos: videos,
      description: description,
      availability: availability,
      bhk: bhk,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      balconies: balconies,
      parking: parking,
      superBuiltUpArea: superBuiltUpArea,
      carpetArea: carpetArea,
      builtUpArea: builtUpArea,
      furnishing: furnishing,
      categoryName: categoryName,
      ownerPhone: ownerPhone,
    );
  }
}

class BudgetRange {
  final double start;
  final double end;
  const BudgetRange(this.start, this.end);
}
