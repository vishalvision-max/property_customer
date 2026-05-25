import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/property.dart';
import '../data/repositories/property_repository.dart';
import '../data/services/property_service.dart';
import 'app_providers.dart';

class PropertyState {
  final bool isLoading;
  final List<Property> all;
  final List<Property> featured;
  final List<Property> recommended;
  final List<Property> nearby;
  final Property? selected;
  final String? error;

  const PropertyState({
    required this.isLoading,
    required this.all,
    required this.featured,
    required this.recommended,
    required this.nearby,
    required this.selected,
    required this.error,
  });

  factory PropertyState.initial() => const PropertyState(
    isLoading: false,
    all: [],
    featured: [],
    recommended: [],
    nearby: [],
    selected: null,
    error: null,
  );

  PropertyState copyWith({
    bool? isLoading,
    List<Property>? all,
    List<Property>? featured,
    List<Property>? recommended,
    List<Property>? nearby,
    Object? selected = _unset,
    String? error,
  }) {
    return PropertyState(
      isLoading: isLoading ?? this.isLoading,
      all: all ?? this.all,
      featured: featured ?? this.featured,
      recommended: recommended ?? this.recommended,
      nearby: nearby ?? this.nearby,
      selected: selected == _unset ? this.selected : selected as Property?,
      error: error,
    );
  }

  static const Object _unset = Object();
}

class PropertyNotifier extends StateNotifier<PropertyState> {
  final PropertyRepository _repo;
  PropertyNotifier(this._repo) : super(PropertyState.initial());

  Future<void> loadHome({
    String? token,
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // /nearby is the only endpoint currently returning real data.
      // Fall back to fetchAll if no coordinates.
      List<Property> all;
      if (lat != null && lng != null) {
        all = await _repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      } else {
        all = await _repo.fetchAll();
      }

      List<Property> recommendations = const [];
      if (token != null && token.trim().isNotEmpty) {
        try {
          recommendations = await _repo.fetchRecommendations(
            token: token.trim(),
          );
        } catch (_) {
          recommendations = const [];
        }
      }

      state = state.copyWith(
        isLoading: false,
        all: all,
        featured: all.take(4).toList(growable: false),
        recommended: recommendations.isEmpty
            ? (all.length > 1 ? all.skip(1).toList(growable: false) : all)
            : recommendations,
        nearby: lat != null && lng != null ? all : state.nearby,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reload home data filtered by [type] ('rent' or 'buy').
  /// Called when the user switches the Rent/Buy tab so each section
  /// shows only properties matching the selected mode.
  ///
  /// Strategy: the main /properties endpoint currently returns 0 results
  /// (backend issue). The /nearby endpoint is the only one returning real
  /// data, so we use it as the primary source and filter by type client-side.
  Future<void> loadHomeForMode({
    required String type,
    String? token,
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Use nearby as primary source when coordinates are available,
      // otherwise fall back to the main endpoint.
      List<Property> allProps = const [];

      if (lat != null && lng != null) {
        allProps = await _repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      } else {
        allProps = await _repo.fetchAll();
      }

      // Filter by the selected mode client-side.
      // Backend type field: 'rent' stays 'rent', 'sale' is normalised to 'buy'.
      final filtered = allProps
          .where((p) => p.type == type)
          .toList(growable: false);

      state = state.copyWith(
        isLoading: false,
        all: filtered,
        featured: filtered.take(4).toList(growable: false),
        recommended: filtered.length > 1
            ? filtered.skip(1).toList(growable: false)
            : filtered,
        nearby: lat != null && lng != null ? filtered : state.nearby,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Property? getById(String id) {
    try {
      return state.all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Property>> search({
    required String mode,
    required BudgetRange budgetRange,
    String? propertyType,
    List<String> amenities = const [],
    String? locationQuery,
    String? sortBy,
  }) => _repo.search(
    mode: mode,
    budgetRange: budgetRange,
    propertyType: propertyType,
    amenities: amenities,
    locationQuery: locationQuery,
    sortBy: sortBy,
  );

  /// Fetch properties for a quick-action tab (Rent, Buy, PG, Commercial, etc.).
  /// Uses /nearby (or /properties as fallback) as the data source and filters
  /// client-side, because the backend /properties endpoint returns 0 results
  /// when type/price filters are applied.
  Future<List<Property>> fetchForType({
    required String mode,
    String? propertyType, // optional sub-type filter (client-side)
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    List<Property> all;
    if (lat != null && lng != null) {
      all = await _repo.fetchNearby(lat: lat, lng: lng, radius: radius);
    } else {
      all = await _repo.fetchAll();
    }

    return all
        .where((p) {
          final typeOk = p.type == mode;
          final subTypeOk = (propertyType == null || propertyType == 'Any')
              ? true
              : p.name.toLowerCase().contains(propertyType.toLowerCase());
          return typeOk && subTypeOk;
        })
        .toList(growable: false);
  }

  Future<List<Property>> searchByName({
    required String mode,
    required String query,
  }) async {
    final q = query.trim();
    // Delegate to the backend keyword search so results are not limited
    // to what is already cached locally.
    return _repo.searchByKeyword(keyword: q);
  }

  Future<Property> fetchDetails(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final p = await _repo.fetchDetails(id);
      // Upsert into `all` so other screens can use it too.
      final nextAll = [...state.all];
      final idx = nextAll.indexWhere((e) => e.id == p.id);
      if (idx >= 0) {
        nextAll[idx] = p;
      } else {
        nextAll.add(p);
      }
      state = state.copyWith(
        isLoading: false,
        all: nextAll,
        selected: p,
        error: null,
      );
      return p;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> loadNearby({
    required double lat,
    required double lng,
    int radius = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      state = state.copyWith(isLoading: false, nearby: items, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final propertyProvider = StateNotifierProvider<PropertyNotifier, PropertyState>(
  (ref) => PropertyNotifier(ref.watch(propertyRepositoryProvider)),
);
